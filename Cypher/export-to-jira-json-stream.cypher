// EXPORT TO JIRA – JSON (STREAMED)
// -----------------------------------------------------------------------------
// Generates a single JSON document compatible with JIRA Cloud/Server bulk
// import.  Instead of writing to disk with apoc.export.* it streams the JSON
// in the query result, making it work even when `apoc.export.file.enabled`
// is false or the DB runs in a restricted environment (e.g. Aura, Docker).
// -----------------------------------------------------------------------------
// How to use in Neo4j Browser:
//   :load export-to-jira-json-stream.cypher
//   (Run)
//   Click the cell in the `jiraJson` column → copy-paste to a file.
// -----------------------------------------------------------------------------

// 0. PROJECT CONFIG
WITH {
  projectKey:  'MuleFlowA',
  projectName: 'Mule Flow Complexity Analysis',
  projectDescription: 'Mule Flow Complexity Analysis – Balanced Sprint Planning',
  projectType: 'software',
  epicIssueType:  'Epic',
  storyIssueType: 'Story',
  sprintPrefix:   'MuleFlowA Sprint'
} AS cfg

// 1. Derive dynamic team precedence (EXPERT → SENIOR → others)
CALL {
  MATCH (t:AgileTeam)
  WITH CASE t.skillLevel WHEN 'EXPERT' THEN 1 WHEN 'SENIOR' THEN 2 ELSE 3 END AS lvl, t.teamName AS nm
  ORDER BY lvl
  RETURN collect(nm) AS teamOrder
}
WITH cfg, teamOrder

// 2. Build EPICS  (one per application)
CALL {
  WITH cfg
  MATCH (app:MuleApp)-[:HAS_FLOW]->(f:Flow)-[:STORY_ASSIGNED_TO]->(team:AgileTeam)
  WITH cfg, app.name AS appName,
       head(collect(DISTINCT team.teamName)) AS assignedTeam,
       count(f) AS totalFlows,
       sum(f.finalStoryPoints) AS totalSP
  RETURN collect({
    key: cfg.projectKey + '-EPIC-' + replace(appName,' ','') ,
    summary: 'Epic: ' + appName + ' Migration',
    description: 'Migrate ' + appName + ' (' + toString(totalFlows) + ' flows, ' + toString(totalSP) + ' SP)\nAssigned Team: ' + assignedTeam,
    issueType: cfg.epicIssueType,
    labels: ['mule-migration','camel-integration'],
    custom: {application: appName, assignedTeam: assignedTeam, totalSP: totalSP}
  }) AS epList
}
WITH cfg, epList AS epics

// 3. Build STORIES  (one per SprintBacklog entry)
CALL {
  WITH cfg
  MATCH (sb:SprintBacklog)
  OPTIONAL MATCH (t:AgileTeam {teamName: sb.teamName})
  WITH cfg, sb,
       CASE t.skillLevel WHEN 'EXPERT' THEN 1 WHEN 'SENIOR' THEN 2 ELSE 3 END AS teamPos,
       'MuleFlowA-' + toString(sb.sprintNumber) + '-' + replace(replace(sb.uniqueId,'::','-'),' ','') AS issueKey
  ORDER BY sb.sprintNumber, teamPos
  RETURN collect({
    key: issueKey,
    summary: 'Migrate ' + sb.flowName + ' from ' + sb.appName,
    description: 'Story Points: ' + toString(sb.storyPoints) + '\nRisk: ' + sb.riskLevel + '\nComplexity: ' + sb.complexityLevel,
    issueType: cfg.storyIssueType,
    parentEpic: cfg.projectKey + '-EPIC-' + replace(sb.appName,' ','') ,
    sprint: cfg.sprintPrefix + ' ' + toString(sb.sprintNumber),
    labels: [ 'sprint-' + toString(sb.sprintNumber), 'team-' + replace(lower(sb.teamName),' ','-') ]
  }) AS stList
}
WITH cfg, epics, stList AS stories

// 4. Build SPRINTS  (one per sprint)
CALL {
  WITH cfg
  MATCH (sb:SprintBacklog)
  WITH cfg, sb.sprintNumber AS sp,
       count(*) AS totalStories,
       sum(sb.storyPoints) AS totalSP
  RETURN collect({
    id: sp,
    name: cfg.sprintPrefix + ' ' + toString(sp),
    goal: 'Deliver ' + toString(totalStories) + ' stories ('+ toString(totalSP) +' SP)',
    state: 'FUTURE'
  }) AS spList
}
WITH cfg, epics, stories, spList AS sprints

// 5. Assemble final structure & stream JSON
WITH epics, stories, sprints, {
  meta: {exportType:'JIRA_IMPORT', generated: toString(datetime())},
  project: {key: cfg.projectKey, name: cfg.projectName, type: cfg.projectType},
  epics:   epics,
  stories: stories,
  sprints: sprints
} AS jiraExport
RETURN apoc.convert.toJson(jiraExport) AS jiraJson,
       size(epics)   AS totalEpics,
       size(stories) AS totalStories,
       size(sprints) AS totalSprints; 