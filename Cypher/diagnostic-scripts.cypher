// DIAGNOSTIC SCRIPTS - Troubleshooting and Data Analysis Tools
// Use these scripts to understand your data, find issues, and optimize assignments

// =============================================================================
// SECTION 1: DATABASE HEALTH CHECK
// =============================================================================

// 1.1 - Node Count Overview
MATCH (n)
RETURN labels(n)[0] as NodeType, 
       count(n) as Count,
       CASE 
           WHEN labels(n)[0] = 'MuleApp' THEN '📱 Applications'
           WHEN labels(n)[0] = 'Flow' THEN ' Flows'
           WHEN labels(n)[0] = 'AgileTeam' THEN ' Teams'
           WHEN labels(n)[0] = 'SprintBacklog' THEN ' Sprint Items'
           WHEN labels(n)[0] = 'SimilarityGroup' THEN ' Similarity Groups'
           ELSE ' Other'
       END as Description
ORDER BY Count DESC;

// 1.2 - Relationship Count Overview
MATCH ()-[r]->()
RETURN type(r) as RelationshipType, 
       count(r) as Count,
       CASE 
           WHEN type(r) = 'HAS_FLOW' THEN '📱 App to Flow'
           WHEN type(r) = 'STORY_ASSIGNED_TO' THEN ' Flow to Team'
           WHEN type(r) = 'BELONGS_TO_SIMILARITY_GROUP' THEN ' Flow to Similarity Group'
           ELSE ' Other'
       END as Description
ORDER BY Count DESC;

// 1.3 - Ghost Nodes Detection (nodes without proper labels)
MATCH (n)
WHERE size(labels(n)) = 0
RETURN count(n) as GhostNodes,
       CASE WHEN count(n) = 0 THEN ' No ghost nodes' ELSE ' Ghost nodes detected' END as Status;

// 1.4 - Orphaned Flows (flows without apps)
MATCH (f:Flow)
WHERE NOT (f)<-[:HAS_FLOW]-()
RETURN count(f) as OrphanedFlows,
       CASE WHEN count(f) = 0 THEN ' All flows have apps' ELSE ' Orphaned flows detected' END as Status;

// =============================================================================
// SECTION 2: STORY POINTS ANALYSIS
// =============================================================================

// 2.1 - Story Points Distribution
MATCH (f:Flow)
WHERE f.finalStoryPoints IS NOT NULL
WITH f.finalStoryPoints as Points
RETURN Points, 
       count(*) as FlowCount,
       round(count(*) * 100.0 / (SELECT count(*) FROM (MATCH (f:Flow) WHERE f.finalStoryPoints IS NOT NULL RETURN f)), 1) as Percentage
ORDER BY Points;

// 2.2 - Story Points by Category
MATCH (f:Flow)
WHERE f.finalStoryPoints IS NOT NULL
RETURN f.storyPointCategory as Category,
       count(f) as FlowCount,
       min(f.finalStoryPoints) as MinPoints,
       max(f.finalStoryPoints) as MaxPoints,
       round(avg(f.finalStoryPoints), 1) as AvgPoints,
       sum(f.finalStoryPoints) as TotalPoints
ORDER BY AvgPoints DESC;

// 2.3 - Missing Story Points
MATCH (f:Flow)
WHERE f.finalStoryPoints IS NULL
RETURN count(f) as FlowsWithoutStoryPoints,
       CASE WHEN count(f) = 0 THEN ' All flows have story points' ELSE ' Missing story points' END as Status;

// 2.4 - Story Points Outliers (extremely high or low)
MATCH (f:Flow)
WHERE f.finalStoryPoints IS NOT NULL
WITH f, 
     percentileCont(f.finalStoryPoints, 0.95) as p95,
     percentileCont(f.finalStoryPoints, 0.05) as p5
MATCH (app:MuleApp)-[:HAS_FLOW]->(f)
WHERE f.finalStoryPoints > p95 OR f.finalStoryPoints < p5
RETURN app.name as Application,
       f.flow as Flow,
       f.finalStoryPoints as StoryPoints,
       CASE 
           WHEN f.finalStoryPoints > p95 THEN ' HIGH OUTLIER'
           ELSE ' LOW OUTLIER'
       END as OutlierType,
       f.storyPointCategory as Category
ORDER BY f.finalStoryPoints DESC;

// =============================================================================
// SECTION 3: TEAM ASSIGNMENT DIAGNOSTICS
// =============================================================================

// 3.1 - Team Assignment Balance
MATCH (f:Flow)-[a:STORY_ASSIGNED_TO]->(t:AgileTeam)
RETURN t.teamName as Team,
       t.skillLevel as SkillLevel,
       count(f) as AssignedFlows,
       sum(f.finalStoryPoints) as TotalStoryPoints,
       round(avg(f.finalStoryPoints), 1) as AvgStoryPoints,
       min(f.finalStoryPoints) as MinStoryPoints,
       max(f.finalStoryPoints) as MaxStoryPoints,
       round(stdDev(f.finalStoryPoints), 1) as StoryPointsStdDev,
       
       // Workload assessment
       CASE 
           WHEN sum(f.finalStoryPoints) > 200 THEN ' OVERLOADED'
           WHEN sum(f.finalStoryPoints) > 150 THEN ' HIGH LOAD'
           WHEN sum(f.finalStoryPoints) > 100 THEN ' BALANCED'
           ELSE ' LIGHT LOAD'
       END as WorkloadStatus
ORDER BY TotalStoryPoints DESC;

// 3.2 - Assignment Quality Analysis
MATCH (f:Flow)-[a:STORY_ASSIGNED_TO]->(t:AgileTeam)
RETURN t.teamName as Team,
       a.assignmentReason as AssignmentReason,
       count(f) as FlowCount,
       round(avg(a.assignmentScore), 1) as AvgAssignmentScore,
       round(avg(f.finalStoryPoints), 1) as AvgStoryPoints
ORDER BY t.teamName, a.assignmentReason;

// 3.3 - Risk Distribution by Team
MATCH (f:Flow)-[a:STORY_ASSIGNED_TO]->(t:AgileTeam)
RETURN t.teamName as Team,
       a.riskLevel as RiskLevel,
       count(f) as FlowCount,
       round(count(f) * 100.0 / (SELECT count(*) FROM (MATCH (f:Flow)-[:STORY_ASSIGNED_TO]->(t2:AgileTeam) WHERE t2.teamName = t.teamName RETURN f)), 1) as Percentage
ORDER BY t.teamName, 
         CASE a.riskLevel 
             WHEN 'HIGH_RISK' THEN 1 
             WHEN 'MEDIUM_RISK' THEN 2 
             WHEN 'LOW_RISK' THEN 3 
             ELSE 4 
         END;

// 3.4 - Unassigned Flows
MATCH (f:Flow)
WHERE NOT (f)-[:STORY_ASSIGNED_TO]->()
RETURN count(f) as UnassignedFlows,
       CASE WHEN count(f) = 0 THEN ' All flows assigned' ELSE ' Unassigned flows detected' END as Status;

// =============================================================================
// SECTION 4: SPRINT PLANNING DIAGNOSTICS
// =============================================================================

// 4.1 - Sprint Workload Distribution
MATCH (sb:SprintBacklog)
RETURN sb.sprintNumber as Sprint,
       count(sb) as TotalStories,
       sum(sb.storyPoints) as TotalStoryPoints,
       round(avg(sb.storyPoints), 1) as AvgStoryPoints,
       count(DISTINCT sb.teamName) as TeamsInSprint,
       count(DISTINCT sb.appName) as AppsInSprint,
       
       // Workload indicator
       CASE 
           WHEN sum(sb.storyPoints) > 60 THEN ' OVERLOADED'
           WHEN sum(sb.storyPoints) > 40 THEN ' HIGH LOAD'
           WHEN sum(sb.storyPoints) > 20 THEN ' BALANCED'
           ELSE ' LIGHT LOAD'
       END as WorkloadStatus,
       
       // Risk indicator
       count(CASE WHEN sb.riskLevel = 'HIGH_RISK' THEN 1 END) as HighRiskStories,
       count(CASE WHEN sb.riskLevel = 'MEDIUM_RISK' THEN 1 END) as MediumRiskStories
ORDER BY Sprint;

// 4.2 - Sprint Planning Gaps
MATCH (sb:SprintBacklog)
WITH max(sb.sprintNumber) as MaxSprint
UNWIND range(1, MaxSprint) as SprintNumber
OPTIONAL MATCH (sb:SprintBacklog {sprintNumber: SprintNumber})
RETURN SprintNumber,
       count(sb) as StoryCount,
       coalesce(sum(sb.storyPoints), 0) as StoryPoints,
       CASE WHEN count(sb) = 0 THEN ' EMPTY SPRINT' ELSE ' HAS STORIES' END as Status
ORDER BY SprintNumber;

// 4.3 - Duplicate Sprint Items
MATCH (sb:SprintBacklog)
WITH sb.uniqueId as UniqueId, collect(sb) as DuplicateItems
WHERE size(DuplicateItems) > 1
RETURN UniqueId,
       size(DuplicateItems) as DuplicateCount,
       [item IN DuplicateItems | item.sprintNumber] as SprintNumbers
ORDER BY DuplicateCount DESC;

// 4.4 - Sprint Items Without Source Flow
MATCH (sb:SprintBacklog)
OPTIONAL MATCH (app:MuleApp)-[:HAS_FLOW]->(f:Flow)
WHERE app.name = sb.appName AND f.flow = sb.flowName
RETURN sb.uniqueId as UniqueId,
       sb.sprintNumber as Sprint,
       sb.appName as Application,
       sb.flowName as Flow,
       CASE WHEN f IS NULL THEN ' NO SOURCE FLOW' ELSE ' HAS SOURCE FLOW' END as Status
ORDER BY Status DESC, Sprint;

// =============================================================================
// SECTION 5: APPLICATION ANALYSIS
// =============================================================================

// 5.1 - Application Complexity Overview
MATCH (app:MuleApp)-[:HAS_FLOW]->(f:Flow)
WHERE f.finalStoryPoints IS NOT NULL
RETURN app.name as Application,
       count(f) as TotalFlows,
       sum(f.finalStoryPoints) as TotalStoryPoints,
       round(avg(f.finalStoryPoints), 1) as AvgStoryPoints,
       min(f.finalStoryPoints) as MinStoryPoints,
       max(f.finalStoryPoints) as MaxStoryPoints,
       count(CASE WHEN f.finalStoryPoints >= 10 THEN 1 END) as HighComplexityFlows,
       count(CASE WHEN f.isApiExposed = true THEN 1 END) as ApiFlows,
       count(CASE WHEN f.connectorCount >= 3 THEN 1 END) as ConnectorHeavyFlows,
       count(CASE WHEN f.dwScriptCount >= 3 THEN 1 END) as ScriptHeavyFlows,
       
       // Risk assessment
       CASE 
           WHEN count(CASE WHEN f.finalStoryPoints >= 10 THEN 1 END) > count(f) * 0.3 THEN ' HIGH RISK APP'
           WHEN count(CASE WHEN f.finalStoryPoints >= 8 THEN 1 END) > count(f) * 0.5 THEN ' MEDIUM RISK APP'
           ELSE ' LOW RISK APP'
       END as RiskLevel
ORDER BY TotalStoryPoints DESC;

// 5.2 - Application Migration Timeline
MATCH (sb:SprintBacklog)
WITH sb.appName as Application,
     min(sb.sprintNumber) as FirstSprint,
     max(sb.sprintNumber) as LastSprint,
     min(sb.startWeek) as StartWeek,
     max(sb.endWeek) as EndWeek,
     count(sb) as TotalFlows,
     sum(sb.storyPoints) as TotalStoryPoints
RETURN Application,
       FirstSprint,
       LastSprint,
       (LastSprint - FirstSprint + 1) as SprintSpan,
       StartWeek,
       EndWeek,
       (EndWeek - StartWeek + 1) as WeekSpan,
       TotalFlows,
       TotalStoryPoints,
       round(TotalStoryPoints / (EndWeek - StartWeek + 1), 1) as StoryPointsPerWeek,
       
       // Migration complexity
       CASE 
           WHEN (EndWeek - StartWeek + 1) > 20 THEN ' LONG MIGRATION'
           WHEN (EndWeek - StartWeek + 1) > 10 THEN ' MEDIUM MIGRATION'
           ELSE ' SHORT MIGRATION'
       END as MigrationLength
ORDER BY TotalStoryPoints DESC;

// =============================================================================
// SECTION 6: SIMILARITY ANALYSIS
// =============================================================================

// 6.1 - Flow Similarity Groups Detection
MATCH (app:MuleApp)-[:HAS_FLOW]->(flow:Flow)
WHERE flow.finalStoryPoints IS NOT NULL
WITH flow.connectorCount as ConnectorCount,
     flow.dwScriptCount as DwScriptCount,
     flow.isApiExposed as IsApiExposed,
     flow.storyPointCategory as Category,
     collect({
         app: app.name,
         flow: flow.flow,
         uniqueId: app.name + '::' + flow.flow,
         storyPoints: flow.finalStoryPoints
     }) as SimilarFlows
WHERE size(SimilarFlows) > 1

RETURN 'POTENTIAL_SIMILARITY_GROUPS' as Analysis,
       ConnectorCount,
       DwScriptCount,
       IsApiExposed,
       Category,
       size(SimilarFlows) as FlowCount,
       round(avg([f IN SimilarFlows | f.storyPoints]), 1) as AvgStoryPoints,
       SimilarFlows[0..3] as SampleFlows,
       
       // Similarity management recommendation
       CASE 
           WHEN size(SimilarFlows) <= 3 THEN ' SAME_TEAM - Assign to one team for knowledge reuse'
           WHEN size(SimilarFlows) <= 6 THEN ' SAME_TEAM_SEQUENTIAL - Same team, sequential sprints'
           ELSE ' DISTRIBUTED_WITH_LEAD - Expert team leads, shares knowledge'
       END as RecommendedStrategy
ORDER BY FlowCount DESC, AvgStoryPoints DESC;

// 6.2 - Exact Complexity Matches
MATCH (app:MuleApp)-[:HAS_FLOW]->(flow:Flow)
WHERE flow.finalStoryPoints IS NOT NULL
WITH flow.finalStoryPoints as StoryPoints,
     collect({
         app: app.name,
         flow: flow.flow,
         uniqueId: app.name + '::' + flow.flow,
         category: flow.storyPointCategory,
         connectorCount: flow.connectorCount,
         dwScriptCount: flow.dwScriptCount,
         isApiExposed: flow.isApiExposed
     }) as ExactMatches
WHERE size(ExactMatches) > 1

RETURN 'EXACT_COMPLEXITY_MATCHES' as Analysis,
       StoryPoints,
       size(ExactMatches) as FlowCount,
       ExactMatches,
       ' HIGH_SIMILARITY - Consider grouping these flows' as Recommendation
ORDER BY FlowCount DESC, StoryPoints DESC;

// 6.3 - Active Similarity Groups Analysis (if similarity groups exist)
MATCH (sg:SimilarityGroup)
OPTIONAL MATCH (sg)<-[:BELONGS_TO_SIMILARITY_GROUP]-(flow:Flow)-[a:STORY_ASSIGNED_TO]->(team:AgileTeam)

RETURN sg.groupId as SimilarityGroup,
       sg.assignmentStrategy as Strategy,
       sg.flowCount as ExpectedFlows,
       count(flow) as ActualFlows,
       sg.riskLevel as RiskLevel,
       round(sg.avgStoryPoints, 1) as AvgStoryPoints,
       count(DISTINCT team.teamName) as TeamsAssigned,
       collect(DISTINCT team.teamName) as AssignedTeams,
       
       // Strategy compliance
       CASE 
           WHEN sg.assignmentStrategy = 'SAME_TEAM' AND count(DISTINCT team.teamName) = 1 THEN ' STRATEGY_FOLLOWED'
           WHEN sg.assignmentStrategy = 'SAME_TEAM_SEQUENTIAL' AND count(DISTINCT team.teamName) = 1 THEN ' STRATEGY_FOLLOWED'
           WHEN sg.assignmentStrategy = 'DISTRIBUTED_WITH_LEAD' THEN ' STRATEGY_FOLLOWED'
           ELSE ' STRATEGY_DEVIATION'
       END as StrategyAdherence
ORDER BY sg.flowCount DESC;

// =============================================================================
// SECTION 7: PERFORMANCE METRICS
// =============================================================================

// 7.1 - Team Velocity Analysis
MATCH (sb:SprintBacklog)
WITH sb.teamName as Team,
     sb.sprintNumber as Sprint,
     sum(sb.storyPoints) as SprintStoryPoints
RETURN Team,
       count(Sprint) as ActiveSprints,
       sum(SprintStoryPoints) as TotalStoryPoints,
       round(avg(SprintStoryPoints), 1) as AvgVelocity,
       min(SprintStoryPoints) as MinVelocity,
       max(SprintStoryPoints) as MaxVelocity,
       round(stdDev(SprintStoryPoints), 1) as VelocityStdDev,
       
       // Consistency indicator
       CASE 
           WHEN round(stdDev(SprintStoryPoints), 1) <= 5 THEN ' CONSISTENT'
           WHEN round(stdDev(SprintStoryPoints), 1) <= 10 THEN ' MODERATE'
           ELSE ' INCONSISTENT'
       END as ConsistencyLevel
ORDER BY AvgVelocity DESC;

// 7.2 - Risk Trend Analysis
MATCH (sb:SprintBacklog)
WITH sb.sprintNumber as Sprint,
     count(CASE WHEN sb.riskLevel = 'HIGH_RISK' THEN 1 END) as HighRiskCount,
     count(CASE WHEN sb.riskLevel = 'MEDIUM_RISK' THEN 1 END) as MediumRiskCount,
     count(CASE WHEN sb.riskLevel = 'LOW_RISK' THEN 1 END) as LowRiskCount,
     count(sb) as TotalStories
RETURN Sprint,
       HighRiskCount,
       MediumRiskCount,
       LowRiskCount,
       TotalStories,
       round(HighRiskCount * 100.0 / TotalStories, 1) as HighRiskPercentage,
       
       // Risk trend assessment
       CASE 
           WHEN Sprint <= 4 AND HighRiskCount > 0 THEN ' GOOD - Early Risk Handling'
           WHEN Sprint > 8 AND HighRiskCount > 0 THEN ' CONCERN - Late Risk Handling'
           ELSE ' NORMAL'
       END as RiskTrendAssessment
ORDER BY Sprint;

// =============================================================================
// SECTION 8: TROUBLESHOOTING QUERIES
// =============================================================================

// 8.1 - Find Flows with Extreme Values
MATCH (app:MuleApp)-[:HAS_FLOW]->(f:Flow)
WHERE f.finalStoryPoints IS NOT NULL
AND (f.finalStoryPoints > 15 OR f.connectorCount > 5 OR f.dwScriptCount > 5)
RETURN app.name as Application,
       f.flow as Flow,
       f.finalStoryPoints as StoryPoints,
       f.connectorCount as ConnectorCount,
       f.dwScriptCount as DwScriptCount,
       f.storyPointCategory as Category,
       ' INVESTIGATE' as Flag
ORDER BY f.finalStoryPoints DESC;

// 8.2 - Team Assignment Conflicts
MATCH (f:Flow)-[a:STORY_ASSIGNED_TO]->(t:AgileTeam)
WHERE (t.skillLevel = 'EXPERT' AND f.finalStoryPoints <= 3) OR
      (t.skillLevel = 'INTERMEDIATE' AND f.finalStoryPoints >= 12)
RETURN t.teamName as Team,
       t.skillLevel as SkillLevel,
       count(f) as ConflictingAssignments,
       collect(f.finalStoryPoints)[0..5] as SampleStoryPoints,
       ' ASSIGNMENT CONFLICT' as Issue
ORDER BY ConflictingAssignments DESC;

// 8.3 - Sprint Capacity Issues
MATCH (sb:SprintBacklog)
WITH sb.sprintNumber as Sprint,
     sb.teamName as Team,
     sum(sb.storyPoints) as TeamSprintLoad
MATCH (t:AgileTeam {teamName: Team})
WHERE TeamSprintLoad > t.sprintCapacity
RETURN Sprint,
       Team,
       TeamSprintLoad,
       t.sprintCapacity as TeamCapacity,
       (TeamSprintLoad - t.sprintCapacity) as Overload,
       '🚨 CAPACITY EXCEEDED' as Issue
ORDER BY Overload DESC; 