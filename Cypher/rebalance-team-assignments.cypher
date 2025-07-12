// REBALANCE TEAM ASSIGNMENTS (v5 improved version)
// ---------------------------------------------------------------------
// This script rebalances story-point allocation across Agile Teams.
// Steps:
//   1. Determine total story points (SP) per team.
//   2. If the most-loaded team has >25 % more SP than the least-loaded
//      team, transfer up to `moveLimit` medium-sized, non-high-risk
//      flows from the most-loaded team to the least-loaded team.
//   3. Report final team totals.
//
// ---------------------------------------------------------------------

// Tunable parameters
WITH 1.25 AS maxRatio,        // stop when SrcSP <= DstSP * maxRatio (25 % spread)
     400   AS moveLimit       // maximum flows to move in one run

// ---------------------------------------------------------------------
// STEP 0a – Merge duplicate AgileTeam nodes having the same teamName
// ---------------------------------------------------------------------
CALL {
  WITH maxRatio, moveLimit
  // Find names with more than one AgileTeam node
  MATCH (t:AgileTeam)
  WITH t.teamName AS name, collect(t) AS nodes, maxRatio, moveLimit
  WHERE size(nodes) > 1
  WITH head(nodes) AS keep, nodes[1..] AS dupes, maxRatio, moveLimit
  UNWIND dupes AS d
    // Re-attach any STORY_ASSIGNED_TO relationships to the canonical node
    OPTIONAL MATCH (flow)-[r:STORY_ASSIGNED_TO]->(d)
    DELETE r
    WITH keep, flow, d, maxRatio, moveLimit
    WHERE flow IS NOT NULL
    MERGE (flow)-[:STORY_ASSIGNED_TO]->(keep)
    WITH keep, d, maxRatio, moveLimit
    DETACH DELETE d
  RETURN count(*) AS merged
}
// Re-establish tuning variables after subquery
WITH 1.25 AS maxRatio, 400 AS moveLimit

// ---------------------------------------------------------------------
// STEP 0 – Clean up duplicate STORY_ASSIGNED_TO relationships
//          (keeps exactly one per Flow, regardless of team)
// ---------------------------------------------------------------------
MATCH (dupF)-[dupRel:STORY_ASSIGNED_TO]->(dupT:AgileTeam)
WITH dupF, collect(dupRel) AS rels, maxRatio, moveLimit
WHERE size(rels) > 1
UNWIND rels[1..] AS redundantRel
DELETE redundantRel;

// Keep tuning variables for the balancing steps
WITH 1.25 AS maxRatio, 400 AS moveLimit

// ---------------------------------------------------------------------
// STEP 1 – Identify most- and least-loaded teams
// ---------------------------------------------------------------------
MATCH (f)-[:STORY_ASSIGNED_TO]->(t:AgileTeam)
// (No WHERE clause; include flows even if story points are NULL)
WITH t, sum(coalesce(f.finalStoryPoints,0)) AS totalSP, maxRatio, moveLimit
ORDER BY totalSP DESC
WITH collect({teamNode:t, sp:totalSP}) AS teams, maxRatio, moveLimit
// Ensure we have at least two teams before proceeding
WHERE size(teams) >= 2
WITH teams[0] AS src,   // highest total SP
     teams[-1] AS dst,  // lowest total SP
     maxRatio, moveLimit
WITH src.teamNode AS srcTeam,
     src.sp       AS srcSP,
     dst.teamNode AS dstTeam,
     dst.sp       AS dstSP,
     maxRatio,
     moveLimit

// ---------------------------------------------------------------------
// STEP 2 – Iteratively move flows until balance achieved or limit reached
// ---------------------------------------------------------------------
// We iterate up to `moveLimit` times; each iteration moves **one** flow (the
// largest eligible story) from the most-loaded to the least-loaded team if the
// spread is still above `maxRatio`.

UNWIND range(1, moveLimit) AS iter
CALL {
  WITH maxRatio

  // -- Heaviest team --
  MATCH (f1)-[:STORY_ASSIGNED_TO]->(tHeavy:AgileTeam)
  WITH tHeavy, sum(coalesce(f1.finalStoryPoints,0)) AS heavySP, maxRatio
  ORDER BY heavySP DESC LIMIT 1
  WITH tHeavy AS srcTeamNode, heavySP AS srcSP, maxRatio

  // -- Lightest team, excluding the heaviest one --
  MATCH (f2)-[:STORY_ASSIGNED_TO]->(tLight:AgileTeam)
  WHERE tLight <> srcTeamNode
  WITH srcTeamNode, srcSP, tLight, sum(coalesce(f2.finalStoryPoints,0)) AS dstSP, maxRatio
  ORDER BY dstSP ASC LIMIT 1
  WITH srcTeamNode, srcSP, tLight AS dstTeamNode, dstSP, maxRatio

  WHERE srcSP > dstSP * maxRatio        // still imbalanced?

  // 2b – pick ONE candidate flow from the source team
  MATCH (cand)-[a:STORY_ASSIGNED_TO]->(srcTeamNode)
  WITH cand, dstTeamNode
  ORDER BY coalesce(cand.finalStoryPoints,0) DESC   // largest first
  LIMIT 1

  // 2c – move it to dst team
  OPTIONAL MATCH (cand)-[oldRel:STORY_ASSIGNED_TO]->()
  DELETE oldRel
  MERGE (cand)-[:STORY_ASSIGNED_TO]->(dstTeamNode)
  RETURN count(cand) AS moved
}

// Pass-through to allow subsequent MATCH clause
WITH 1 AS _, maxRatio, moveLimit

// ---------------------------------------------------------------------
// STEP 2B – Per-Sprint Team Rebalance (Optional)
// ---------------------------------------------------------------------
// Within each sprint, move flows between teams until the heaviest team’s
// load is no more than `maxRatio` times the lightest team’s load.
// Keeps the move-limit budget so the entire script still moves at most
// `moveLimit` flows per sprint. Uses only pure Cypher.
// ---------------------------------------------------------------------

// Gather sprint numbers first (keeps `maxRatio`/`moveLimit` in scope)
MATCH (sbAll:SprintBacklog)
WITH collect(DISTINCT sbAll.sprintNumber) AS sprints, maxRatio, moveLimit
UNWIND sprints AS sprintNum

// Iterate up to `moveLimit` moves per sprint
UNWIND range(1, moveLimit) AS iter
CALL {
  WITH sprintNum, maxRatio
  // Identify heaviest team inside the sprint
  MATCH (sb1:SprintBacklog {sprintNumber: sprintNum})
  WITH sb1.teamName AS team, sum(coalesce(sb1.storyPoints,0)) AS teamSP, sprintNum, maxRatio
  ORDER BY teamSP DESC LIMIT 1
  WITH team AS srcTeam, teamSP AS srcSP, sprintNum, maxRatio

  // Identify lightest team inside the sprint (excluding src)
  MATCH (sb2:SprintBacklog {sprintNumber: sprintNum})
  WHERE sb2.teamName <> srcTeam
  WITH srcTeam, srcSP, sb2.teamName AS dstTeam, sum(coalesce(sb2.storyPoints,0)) AS dstSP, sprintNum, maxRatio
  ORDER BY dstSP ASC LIMIT 1

  // Exit early if balanced
  WHERE srcSP > dstSP * maxRatio

  // Choose one largest candidate backlog entry to move
  MATCH (candSB:SprintBacklog {sprintNumber: sprintNum, teamName: srcTeam})
  WITH candSB, dstTeam
  ORDER BY coalesce(candSB.storyPoints,0) DESC
  LIMIT 1

  // Move: update SprintBacklog.teamName
  SET candSB.teamName = dstTeam

  // Update underlying Flow assignment to new AgileTeam
  WITH candSB, dstTeam
  OPTIONAL MATCH (app:MuleApp {name: candSB.appName})-[:HAS_FLOW]->(flow:Flow {flow: candSB.flowName})
  OPTIONAL MATCH (flow)-[oldRel:STORY_ASSIGNED_TO]->(:AgileTeam)
  DELETE oldRel
  WITH candSB, dstTeam, flow
  OPTIONAL MATCH (newTeam:AgileTeam {teamName: dstTeam})
  MERGE (flow)-[:STORY_ASSIGNED_TO]->(newTeam)
  RETURN count(candSB) AS moved
}
// pass-through
WITH 1 AS _

// ---------------------------------------------------------------------
// STEP 3 – Final report
// ---------------------------------------------------------------------
MATCH (f2)-[:STORY_ASSIGNED_TO]->(t2:AgileTeam)
WITH t2.teamName AS Team,
     sum(f2.finalStoryPoints) AS StoryPoints
ORDER BY StoryPoints DESC
RETURN 'Rebalance complete' AS Status,
       collect({Team:Team, StoryPoints:StoryPoints}) AS TeamTotals; 