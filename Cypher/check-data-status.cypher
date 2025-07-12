// CHECK DATA STATUS - Diagnostic Script
// Checks what data exists in the database before running workflows

// Check if we have basic flow data
MATCH (app:MuleApp)-[:HAS_FLOW]->(flow:Flow)
WITH count(app) as appCount, count(flow) as flowCount

// Check if flows have story points
MATCH (flow:Flow)
WHERE flow.finalStoryPoints IS NOT NULL
WITH appCount, flowCount, count(flow) as flowsWithStoryPoints

// Check if we have team assignments
MATCH (flow:Flow)-[a:STORY_ASSIGNED_TO]->(team:AgileTeam)
WITH appCount, flowCount, flowsWithStoryPoints, count(flow) as flowsWithTeams

// Check if we have sprint backlog
MATCH (sb:SprintBacklog)
WITH appCount, flowCount, flowsWithStoryPoints, flowsWithTeams, count(sb) as sprintBacklogCount

RETURN " DATABASE STATUS CHECK" as Status,
       appCount as MuleApps,
       flowCount as TotalFlows,
       flowsWithStoryPoints as FlowsWithStoryPoints,
       flowsWithTeams as FlowsWithTeamAssignments,
       sprintBacklogCount as SprintBacklogEntries,
       
       // Workflow readiness
       CASE 
           WHEN appCount = 0 THEN " NO_DATA_FOUND - Run data import first"
           WHEN flowsWithStoryPoints = 0 THEN " NO_STORY_POINTS - Run story point calculation"
           WHEN flowsWithTeams = 0 THEN " NO_TEAM_ASSIGNMENTS - Run team assignment"
           WHEN sprintBacklogCount = 0 THEN " READY_FOR_SPRINT_PLANNING - Run improved-sprint-planning.cypher"
           ELSE " READY_FOR_EXPORT - Run export scripts"
       END as NextStep; 