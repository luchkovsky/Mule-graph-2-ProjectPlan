// VALIDATE TEAM STORY-POINT BALANCE
// -----------------------------------
// Run this script after ‘rebalance-team-assignments.cypher’ to confirm
// that no Agile Team exceeds the allowed variance (default 25 %).
//
// It computes per-team totals, the spread between max and min, and a
// PASS/FAIL flag you can use in CI pipelines or notebook workflows.
//
// Usage:
//   :param maxRatio => 1.25        // Optional: override 25 % threshold
//   :run
// -----------------------------------

// MATCH (sb:SprintBacklog)
// WITH sb.sprintNumber AS Sprint,
//      sb.teamName     AS Team,
//      sum(coalesce(sb.storyPoints,0)) AS TeamSP
// WITH Sprint, collect({Team: Team, SP: TeamSP}) AS Teams
// RETURN Sprint, Teams
// ORDER BY Sprint;

WITH 1.25 AS maxRatio

MATCH (f)-[:STORY_ASSIGNED_TO]->(t:AgileTeam)
WITH t.teamName AS Team,
     sum(coalesce(f.finalStoryPoints,0)) AS StoryPoints,
     maxRatio AS maxRatio
// Gather team totals in a list for global min/max calc later
WITH collect({Team:Team, SP:StoryPoints}) AS teamTotals, maxRatio
WITH teamTotals,
     reduce(sMin = 1e9, row IN teamTotals | CASE WHEN row.SP < sMin THEN row.SP ELSE sMin END) AS minSP,
     reduce(sMax = 0,    row IN teamTotals | CASE WHEN row.SP > sMax THEN row.SP ELSE sMax END) AS maxSP,
     maxRatio
WITH teamTotals, minSP, maxSP, maxSP / toFloat(minSP) AS ratio, maxRatio,
     CASE WHEN maxSP <= minSP * maxRatio THEN 'PASS' ELSE 'FAIL' END AS status
RETURN status            AS ValidationStatus,
       ratio             AS ActualRatio,
       maxRatio          AS AllowedRatio,
       teamTotals        AS PerTeamTotals
ORDER BY ratio DESC; 