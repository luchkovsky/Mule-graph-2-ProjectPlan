// VERIFICATION SCRIPT - Check Results After Running All Steps
// Run this script to verify everything is working correctly

// Node labels and their properties
CALL apoc.meta.nodeTypeProperties()
YIELD nodeType, propertyName, propertyTypes
RETURN nodeType              AS Label,
       collect(propertyName + ' : ' + apoc.text.join(propertyTypes, ',')) AS Properties
ORDER BY Label;

// Relationship types and their properties
CALL apoc.meta.relTypeProperties()
YIELD relType, propertyName, propertyTypes
RETURN relType               AS Relationship,
       collect(propertyName + ' : ' + apoc.text.join(propertyTypes, ',')) AS Properties
ORDER BY Relationship;


// 1. BASIC COUNTS VERIFICATION
MATCH (app:MuleApp)
MATCH (flow:Flow)
MATCH (team:AgileTeam)
MATCH (sb:SprintBacklog)
RETURN '=== BASIC COUNTS ===' as Section,
       count(DISTINCT app) as MuleApps,
       count(DISTINCT flow) as TotalFlows,
       count(DISTINCT team) as Teams,
       count(DISTINCT sb) as SprintBacklogItems;

// 2. TEAM CREATION VERIFICATION
MATCH (team:AgileTeam)
RETURN '=== TEAM VERIFICATION ===' as Section,
       team.teamName as TeamName,
       team.skillLevel as SkillLevel,
       team.capacity as Capacity,
       team.sprintCapacity as SprintCapacity
ORDER BY CASE team.skillLevel 
    WHEN 'EXPERT' THEN 1 
    WHEN 'SENIOR' THEN 2 
    ELSE 3 
END;

// 3. STORY POINTS VERIFICATION
MATCH (flow:Flow)
WHERE flow.finalStoryPoints IS NOT NULL
RETURN '=== STORY POINTS VERIFICATION ===' as Section,
       count(flow) as FlowsWithStoryPoints,
       min(flow.finalStoryPoints) as MinStoryPoints,
       max(flow.finalStoryPoints) as MaxStoryPoints,
       round(avg(flow.finalStoryPoints), 1) as AvgStoryPoints,
       sum(flow.finalStoryPoints) as TotalStoryPoints,
       count(CASE WHEN flow.finalStoryPoints >= 10 THEN 1 END) as HighComplexityFlows,
       count(CASE WHEN flow.finalStoryPoints >= 5 AND flow.finalStoryPoints < 10 THEN 1 END) as MediumComplexityFlows,
       count(CASE WHEN flow.finalStoryPoints < 5 THEN 1 END) as LowComplexityFlows;

// 4. TEAM ASSIGNMENTS VERIFICATION
MATCH (flow:Flow)-[a:STORY_ASSIGNED_TO]->(team:AgileTeam)
RETURN '=== TEAM ASSIGNMENTS VERIFICATION ===' as Section,
       team.teamName as Team,
       team.skillLevel as SkillLevel,
       count(flow) as AssignedFlows,
       sum(flow.finalStoryPoints) as TotalStoryPoints,
       round(avg(flow.finalStoryPoints), 1) as AvgStoryPoints,
       count(CASE WHEN a.riskLevel = 'HIGH_RISK' THEN 1 END) as HighRiskAssignments,
       count(CASE WHEN a.riskLevel = 'MEDIUM_RISK' THEN 1 END) as MediumRiskAssignments,
       count(CASE WHEN a.riskLevel = 'LOW_RISK' THEN 1 END) as LowRiskAssignments,
       count(CASE WHEN a.assignmentReason = 'OPTIMAL_MATCH' THEN 1 END) as OptimalMatches,
       count(CASE WHEN a.assignmentReason = 'GOOD_MATCH' THEN 1 END) as GoodMatches
ORDER BY CASE team.skillLevel 
    WHEN 'EXPERT' THEN 1 
    WHEN 'SENIOR' THEN 2 
    ELSE 3 
END;

// 5. SPRINT PLANNING VERIFICATION
MATCH (sb:SprintBacklog)
RETURN '=== SPRINT PLANNING VERIFICATION ===' as Section,
       count(sb) as TotalSprintItems,
       count(DISTINCT sb.uniqueId) as UniqueFlows,
       count(DISTINCT sb.sprintNumber) as TotalSprints,
       count(DISTINCT sb.teamName) as TeamsInSprints,
       count(DISTINCT sb.appName) as AppsInSprints,
       min(sb.sprintNumber) as FirstSprint,
       max(sb.sprintNumber) as LastSprint,
       min(sb.startWeek) as ProjectStartWeek,
       max(sb.endWeek) as ProjectEndWeek,
       (max(sb.endWeek) - min(sb.startWeek) + 1) as ProjectDurationWeeks;

// 6. RISK DISTRIBUTION VERIFICATION
MATCH (sb:SprintBacklog)
RETURN '=== RISK DISTRIBUTION VERIFICATION ===' as Section,
       count(CASE WHEN sb.riskLevel = 'HIGH_RISK' THEN 1 END) as HighRiskStories,
       count(CASE WHEN sb.riskLevel = 'MEDIUM_RISK' THEN 1 END) as MediumRiskStories,
       count(CASE WHEN sb.riskLevel = 'LOW_RISK' THEN 1 END) as LowRiskStories,
       count(CASE WHEN sb.riskLevel = 'MINIMAL_RISK' THEN 1 END) as MinimalRiskStories,
       round(avg(CASE WHEN sb.riskLevel = 'HIGH_RISK' THEN sb.sprintNumber END), 1) as AvgHighRiskSprintNumber,
       round(avg(CASE WHEN sb.riskLevel = 'MEDIUM_RISK' THEN sb.sprintNumber END), 1) as AvgMediumRiskSprintNumber,
       round(avg(CASE WHEN sb.riskLevel = 'LOW_RISK' THEN sb.sprintNumber END), 1) as AvgLowRiskSprintNumber;

// 7. SPRINT WORKLOAD VERIFICATION
MATCH (sb:SprintBacklog)
WITH sb.sprintNumber as Sprint,
     count(sb) as StoriesInSprint,
     sum(sb.storyPoints) as StoryPointsInSprint,
     collect(DISTINCT sb.teamName) as TeamsInSprint,
     count(CASE WHEN sb.riskLevel = 'HIGH_RISK' THEN 1 END) as HighRiskInSprint
RETURN '=== SPRINT WORKLOAD VERIFICATION ===' as Section,
       Sprint,
       StoriesInSprint,
       StoryPointsInSprint,
       size(TeamsInSprint) as TeamCount,
       HighRiskInSprint,
       CASE 
           WHEN StoryPointsInSprint >= 50 THEN ' HIGH WORKLOAD'
           WHEN StoryPointsInSprint >= 30 THEN ' MEDIUM WORKLOAD'
           ELSE ' MANAGEABLE WORKLOAD'
       END as WorkloadLevel,
       CASE 
           WHEN HighRiskInSprint > 0 THEN ' HIGH RISK'
           ELSE ' LOW RISK'
       END as SprintRiskLevel
ORDER BY Sprint;

// 8. PHASE DISTRIBUTION VERIFICATION
MATCH (sb:SprintBacklog)
WITH sb.projectPhase as Phase,
     count(sb) as StoriesInPhase,
     sum(sb.storyPoints) as StoryPointsInPhase,
     count(CASE WHEN sb.riskLevel = 'HIGH_RISK' THEN 1 END) as HighRiskInPhase,
     min(sb.sprintNumber) as FirstSprint,
     max(sb.sprintNumber) as LastSprint,
     min(sb.startWeek) as PhaseStartWeek,
     max(sb.endWeek) as PhaseEndWeek
RETURN '=== PHASE DISTRIBUTION VERIFICATION ===' as Section,
       Phase,
       StoriesInPhase,
       StoryPointsInPhase,
       HighRiskInPhase,
       FirstSprint,
       LastSprint,
       PhaseStartWeek,
       PhaseEndWeek,
       (PhaseEndWeek - PhaseStartWeek + 1) as PhaseDurationWeeks,
       round(toFloat(HighRiskInPhase) / StoriesInPhase * 100, 1) as HighRiskPercentage
ORDER BY FirstSprint;

// 9. DUPLICATE CHECK VERIFICATION
MATCH (sb:SprintBacklog)
WITH sb.uniqueId as UniqueId, count(sb) as DuplicateCount
WHERE DuplicateCount > 1
RETURN '=== DUPLICATE CHECK VERIFICATION ===' as Section,
       count(*) as DuplicateUniqueIds,
       CASE WHEN count(*) = 0 THEN ' NO DUPLICATES FOUND' ELSE ' DUPLICATES DETECTED' END as DuplicateStatus;

// 10. FINAL SUCCESS VERIFICATION
MATCH (flow:Flow)
MATCH (team:AgileTeam)
MATCH (sb:SprintBacklog)
MATCH (flow)-[a:STORY_ASSIGNED_TO]->(team)
RETURN '=== FINAL SUCCESS VERIFICATION ===' as Section,
       CASE 
           WHEN count(DISTINCT flow) = 125 
           AND count(DISTINCT team) = 3 
           AND count(DISTINCT sb) = 125 
           AND count(DISTINCT sb.uniqueId) = 125 
           AND count(DISTINCT a) = 125 
           THEN ' ALL SYSTEMS GO - ROADMAP COMPLETE!'
           ELSE ' ISSUES DETECTED - CHECK ABOVE RESULTS'
       END as OverallStatus,
       count(DISTINCT flow) as FlowCount,
       count(DISTINCT team) as TeamCount,
       count(DISTINCT sb) as SprintBacklogCount,
       count(DISTINCT sb.uniqueId) as UniqueFlowCount,
       count(DISTINCT a) as AssignmentCount; 