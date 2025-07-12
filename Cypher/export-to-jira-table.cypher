// EXPORT TO JIRA – TABLE FORMAT (TEAM-SEQUENCED)
// -----------------------------------------------------------------------------
// Produces plain rows (one per EPIC, STORY, or SPRINT) that you can copy or
// export as CSV from Neo4j Browser or any driver. Follows the same ordering
// logic as `export-to-jira-table.cypher` (Expert → Senior → Standard).
// -----------------------------------------------------------------------------
// Column layout (all UNION branches share the same columns):
// IssueType | Id | Name | Summary | EpicName | EpicLink | Sprint | Team | Application |
// Flow | StoryPoints | TotalStories | TotalStoryPoints
// Unused columns in a row are NULL.
// -----------------------------------------------------------------------------

// 1. Dynamic team precedence list (for ordering)
CALL {
  MATCH (t:AgileTeam)
  WITH CASE t.skillLevel WHEN 'EXPERT' THEN 1 WHEN 'SENIOR' THEN 2 ELSE 3 END AS lvl, t.teamName AS name
  ORDER BY lvl
  RETURN collect(name) AS teamOrder
}
WITH teamOrder

// 2. Build EPIC dataset with numeric IDs
CALL {
  MATCH (app:MuleApp)-[:HAS_FLOW]->(f:Flow)-[:STORY_ASSIGNED_TO]->(team:AgileTeam)
  WITH app.name AS appName,
       head(collect(DISTINCT team.teamName)) AS assignedTeam,
       count(f) AS totalFlows,
       sum(f.finalStoryPoints) AS totalSP
  ORDER BY appName
  WITH collect({app:appName, team:assignedTeam, flows:totalFlows, sp:totalSP}) AS raw
  WITH [i IN range(0,size(raw)-1) | raw[i] + {epicId:i+1}] AS epics
  RETURN epics
}
WITH teamOrder, epics,
     apoc.map.fromPairs([e IN epics | [e.app, e.epicId]]) AS epicMap,
     size(epics) AS epicCount

UNWIND epics AS e
RETURN 'Epic'               AS IssueType,
       e.epicId             AS Id,
       e.app                AS Name,
       'Epic: ' + e.app + ' Migration' AS Summary,
       e.app                AS EpicName,
       NULL                 AS EpicLink,
       NULL                 AS Sprint,
       e.team               AS Team,
       e.app                AS Application,
       NULL                 AS Flow,
       NULL                 AS StoryPoints,
       e.flows              AS TotalStories,
       e.sp                 AS TotalStoryPoints

UNION ALL

// 3. Story rows with numeric IDs referencing epicId
CALL {
  WITH epicMap, epicCount, teamOrder
  MATCH (sb:SprintBacklog)
  OPTIONAL MATCH (t:AgileTeam {teamName: sb.teamName})
  WITH epicMap, epicCount, teamOrder, sb,
       CASE t.skillLevel WHEN 'EXPERT' THEN 1 WHEN 'SENIOR' THEN 2 ELSE 3 END AS teamPos
  ORDER BY sb.sprintNumber, teamPos
  WITH epicMap, epicCount, collect(sb) AS rows
  WITH epicMap, [i IN range(0,size(rows)-1) | rows[i] + {storyId: epicCount + i + 1}] AS stories
  RETURN stories
}
UNWIND stories AS s
RETURN 'Story'              AS IssueType,
       s.storyId            AS Id,
       s.flowName           AS Name,
       'Migrate ' + s.flowName + ' from ' + s.appName AS Summary,
       NULL                 AS EpicName,
       epicMap[s.appName]   AS EpicLink,
       s.sprintNumber       AS Sprint,
       s.teamName           AS Team,
       s.appName            AS Application,
       s.flowName           AS Flow,
       s.storyPoints        AS StoryPoints,
       NULL                 AS TotalStories,
       NULL                 AS TotalStoryPoints

UNION ALL

// 4. Sprint metric rows (optional)
MATCH (sb:SprintBacklog)
WITH sb.sprintNumber AS Sprint,
     count(*) AS totalStories,
     sum(sb.storyPoints) AS totalSP
RETURN NULL                AS IssueType,
       10000 + Sprint      AS Id,
       'Sprint ' + toString(Sprint) AS Name,
       'Sprint ' + toString(Sprint) AS Summary,
       NULL                 AS EpicName,
       NULL                 AS EpicLink,
       Sprint               AS Sprint,
       NULL                 AS Team,
       NULL                 AS Application,
       NULL                 AS Flow,
       NULL                 AS StoryPoints,
       totalStories         AS TotalStories,
       totalSP              AS TotalStoryPoints
ORDER BY Sprint; 