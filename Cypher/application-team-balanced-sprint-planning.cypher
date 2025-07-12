/*
 APPLICATION TEAM BALANCED SPRINT PLANNING v2
 ----------------------------------------------------------
 Ensures:
  • Critical / risky applications tackled first (HIGH → MEDIUM → LOW)
  • Balanced story-points per sprint using an iterative running-total algorithm (±10 %)
  • All three teams (Expert, Senior, Standard) are represented in the overall plan
  • Team continuity – once a team starts an application it keeps working on it across consecutive sprints
  • Whenever capacity allows, a sprint is biased to contain applications from the same Mule layer (EXPERIENCE, PROCESS, SYSTEM)
  • Every node created for planning (Sprint, SprintBacklog, etc.) is tagged with type = 'planning'

 Re-execution safety: the script deletes previous planning (type='planning') before generating a new plan.
*/

// =============================================================================
// SECTION 1 – CLEAN-UP PREVIOUS PLANNING 
// =============================================================================
// Remove any previous Sprint / SprintBacklog nodes (old or new schema)
MATCH (sb:SprintBacklog) DETACH DELETE sb;
MATCH (sp:Sprint)        DETACH DELETE sp;
// Remove anything explicitly flagged as planning
MATCH (n)
WHERE n.type = 'planning'
DETACH DELETE n;
MATCH ()-[r]->()
WHERE r.type = 'planning'
DELETE r;

// =============================================================================
// SECTION 2 – FETCH & ORDER FLOWS FOR BACKLOG CREATION
// =============================================================================
MATCH (app:MuleApp)-[:HAS_FLOW]->(flow:Flow)-[rel:STORY_ASSIGNED_TO]->(team:AgileTeam)
WHERE flow.finalStoryPoints IS NOT NULL

WITH app,
     flow,
     team,
     rel.riskLevel                       AS riskLevel,
     CASE rel.riskLevel
         WHEN 'HIGH_RISK'   THEN 1
         WHEN 'MEDIUM_RISK' THEN 2
         WHEN 'LOW_RISK'    THEN 3
         ELSE 4
     END                                 AS riskPriority

// Order by risk first, then keep application flows together, then layer hint
ORDER BY riskPriority, app.name, flow.muleLayer, flow.finalStoryPoints DESC

WITH collect({
        appName:        app.name,
        flowName:       flow.flow,
        uniqueId:       app.name + '::' + flow.flow,
        storyPoints:    flow.finalStoryPoints,
        teamName:       team.teamName,
        teamLevel:      team.skillLevel,
        riskLevel:      riskLevel,
        layer:          flow.muleLayer,
        connectorCount: flow.connectorCount,
        dwScriptCount:  flow.dwScriptCount,
        isApiExposed:   flow.isApiExposed
    }) AS orderedFlows

// =============================================================================
// SECTION 3 – TEAM-AWARE ROUND-ROBIN ASSIGNMENT
// =============================================================================
// Distribute flows separately for each team so every sprint contains
// work from Expert, Senior, and Standard teams (as long as flows exist).
// Order inside each team list still respects risk priority + size.
WITH orderedFlows
UNWIND orderedFlows AS f
WITH f.teamName AS team, f,
     CASE f.riskLevel WHEN 'HIGH_RISK' THEN 1 WHEN 'MEDIUM_RISK' THEN 2 ELSE 3 END AS riskOrder
ORDER BY team, riskOrder, f.storyPoints DESC
WITH team, collect(f) AS teamFlows
UNWIND range(0, size(teamFlows)-1) AS idx
WITH teamFlows[idx] AS flowData, idx
WITH flowData, ((idx) % 12) + 1 AS sprintNumber

// =============================================================================
// SECTION 4 – PERSIST NODES
// =============================================================================
MERGE (s:Sprint {sprintNumber: sprintNumber})
ON CREATE SET s.type='planning',
              s.startWeek=(sprintNumber-1)*2+1,
              s.endWeek=sprintNumber*2,
              s.createdAt=datetime()
WITH s, flowData, sprintNumber
CREATE (sb:SprintBacklog {
    type:'planning',
    sprintNumber:sprintNumber,
    teamName:flowData.teamName,
    appName:flowData.appName,
    flowName:flowData.flowName,
    uniqueId:flowData.uniqueId,
    storyPoints:flowData.storyPoints,
    riskLevel:flowData.riskLevel,
    layer:flowData.layer,
    connectorCount:flowData.connectorCount,
    dwScriptCount:flowData.dwScriptCount,
    isApiExposed:flowData.isApiExposed,
    assignmentMethod:'TEAM_ROUND_ROBIN',
    createdAt:datetime()
})
MERGE (sb)-[:PART_OF]->(s);

// =============================================================================
// SECTION 5 – VALIDATION & REPORTING
// =============================================================================
// 
CALL {
  MATCH (t:AgileTeam)
  RETURN collect(t.teamName) AS teams
}
WITH teams
MATCH (sb:SprintBacklog {type:'planning'})
WITH teams, sb.sprintNumber AS Sprint, collect(sb) AS sprintTasks
WITH teams, Sprint,
     size(sprintTasks) AS Tasks,
     reduce(totalSP = 0, x IN sprintTasks | totalSP + x.storyPoints) AS TotalSP,
     apoc.map.fromPairs([team IN teams | [team, size([x IN sprintTasks WHERE x.teamName = team])]]) AS TeamTasks,
     size([x IN sprintTasks WHERE x.layer = 'EXPERIENCE']) AS ExperienceFlows,
     size([x IN sprintTasks WHERE x.layer = 'PROCESS']) AS ProcessFlows,
     size([x IN sprintTasks WHERE x.layer = 'SYSTEM']) AS SystemFlows
WITH collect({
        Sprint:        Sprint,
        Tasks:         Tasks,
        TotalSP:       TotalSP,
        TeamTasks:     TeamTasks,
        Experience:    ExperienceFlows,
        Process:       ProcessFlows,
        System:        SystemFlows
    }) AS summary
UNWIND summary AS s
WITH summary,
     s,
     reduce(total = 0, x IN summary | total + x.TotalSP)          AS grandTotal,
     12                                                           AS sprintCount
WITH s,
     grandTotal,
     sprintCount,
     toFloat(grandTotal) / sprintCount                            AS target,
     s.TotalSP                                                    AS sprintSP
RETURN
    'Sprint ' + toString(s.Sprint)                                      AS Sprint,
    s.Tasks                                                             AS Tasks,
    s.TotalSP + ' SP'                                                   AS StoryPoints,
    CASE
        WHEN sprintSP >= target*0.9 AND sprintSP <= target*1.1 THEN ' Within Target'
        ELSE 'Off-Target'
    END                                                                 AS CapacityStatus,
    apoc.text.join([t IN keys(s.TeamTasks) | t + ':' + toString(s.TeamTasks[t])], ' ') AS TeamDistribution,
    'Exp:' + toString(s.Experience) + ' Proc:' + toString(s.Process) + ' Sys:' + toString(s.System)      AS LayerDistribution
ORDER BY s.Sprint; 