// FLOW SIMILARITY DETECTION AND GROUPING
// Identifies similar flows for better team assignment and sprint planning

// =============================================================================
// SECTION 1: SIMILARITY DETECTION BASED ON MULTIPLE CRITERIA
// =============================================================================

// 1.1 - Detect flows with similar connector patterns
MATCH (app:MuleApp)-[:HAS_FLOW]->(flow:Flow)
WHERE flow.finalStoryPoints IS NOT NULL
WITH flow.connectorCount as ConnectorCount,
     flow.dwScriptCount as DwScriptCount,
     flow.isApiExposed as IsApiExposed,
     flow.finalStoryPoints as StoryPoints,
     collect({
         app: app.name,
         flow: flow.flow,
         uniqueId: app.name + '::' + flow.flow,
         storyPoints: flow.finalStoryPoints,
         category: flow.storyPointCategory
     }) as SimilarFlows
WHERE size(SimilarFlows) > 1  // Only groups with multiple flows

RETURN 'CONNECTOR_PATTERN_GROUPS' as GroupType,
       ConnectorCount,
       DwScriptCount,
       IsApiExposed,
       size(SimilarFlows) as FlowCount,
       round(avg(StoryPoints), 1) as AvgStoryPoints,
       SimilarFlows[0..5] as SampleFlows  // Show first 5 flows
ORDER BY FlowCount DESC, AvgStoryPoints DESC;

// 1.2 - Detect flows with similar complexity patterns
MATCH (app:MuleApp)-[:HAS_FLOW]->(flow:Flow)
WHERE flow.finalStoryPoints IS NOT NULL
WITH flow.storyPointCategory as Category,
     flow.finalStoryPoints as StoryPoints,
     collect({
         app: app.name,
         flow: flow.flow,
         uniqueId: app.name + '::' + flow.flow,
         connectorCount: flow.connectorCount,
         dwScriptCount: flow.dwScriptCount,
         isApiExposed: flow.isApiExposed
     }) as SimilarFlows
WHERE size(SimilarFlows) > 1

RETURN 'COMPLEXITY_GROUPS' as GroupType,
       Category,
       size(SimilarFlows) as FlowCount,
       StoryPoints,
       SimilarFlows[0..5] as SampleFlows
ORDER BY FlowCount DESC, StoryPoints DESC;

// 1.3 - Detect flows with identical story points (exact complexity matches)
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

RETURN 'EXACT_COMPLEXITY_MATCHES' as GroupType,
       StoryPoints,
       size(ExactMatches) as FlowCount,
       ExactMatches
ORDER BY FlowCount DESC, StoryPoints DESC;

// =============================================================================
// SECTION 2: CREATE SIMILARITY GROUPS FOR MANAGEMENT
// =============================================================================

// 2.1 - Create similarity group nodes for tracking
MATCH (app:MuleApp)-[:HAS_FLOW]->(flow:Flow)
WHERE flow.finalStoryPoints IS NOT NULL

// Group by similarity criteria
WITH flow.connectorCount as ConnectorCount,
     flow.dwScriptCount as DwScriptCount,
     flow.isApiExposed as IsApiExposed,
     flow.storyPointCategory as Category,
     collect(flow) as SimilarFlows
WHERE size(SimilarFlows) > 1

// Create similarity group
CREATE (sg:SimilarityGroup {
    groupId: 'SG_' + toString(ConnectorCount) + '_' + toString(DwScriptCount) + '_' + toString(IsApiExposed) + '_' + Category,
    connectorCount: ConnectorCount,
    dwScriptCount: DwScriptCount,
    isApiExposed: IsApiExposed,
    category: Category,
    flowCount: size(SimilarFlows),
    avgStoryPoints: reduce(total = 0, f IN SimilarFlows | total + f.finalStoryPoints) / size(SimilarFlows),
    
    // Management properties
    assignmentStrategy: CASE 
        WHEN size(SimilarFlows) <= 3 THEN 'SAME_TEAM'
        WHEN size(SimilarFlows) <= 6 THEN 'SAME_TEAM_SEQUENTIAL'
        ELSE 'DISTRIBUTED_WITH_LEAD'
    END,
    
    riskLevel: CASE 
        WHEN reduce(total = 0, f IN SimilarFlows | total + f.finalStoryPoints) / size(SimilarFlows) >= 10 THEN 'HIGH_RISK_GROUP'
        WHEN reduce(total = 0, f IN SimilarFlows | total + f.finalStoryPoints) / size(SimilarFlows) >= 8 THEN 'MEDIUM_RISK_GROUP'
        ELSE 'LOW_RISK_GROUP'
    END,
    
    createdAt: datetime()
})

// Link flows to similarity groups
WITH sg, SimilarFlows
UNWIND SimilarFlows as flow
CREATE (flow)-[:BELONGS_TO_SIMILARITY_GROUP]->(sg);

// =============================================================================
// SECTION 3: SIMILARITY-AWARE TEAM ASSIGNMENTS
// =============================================================================

// 3.1 - Enhanced team assignment considering similarity groups
MATCH (flow:Flow)-[:BELONGS_TO_SIMILARITY_GROUP]->(sg:SimilarityGroup)
MATCH (team:AgileTeam)

WITH sg, flow, team,
     // Enhanced scoring that considers similarity groups
     CASE 
         // Expert team - handles high-risk similarity groups
         WHEN team.skillLevel = 'EXPERT' AND sg.riskLevel = 'HIGH_RISK_GROUP' THEN 20
         WHEN team.skillLevel = 'EXPERT' AND flow.finalStoryPoints >= 10 THEN 18
         WHEN team.skillLevel = 'EXPERT' AND sg.category IN ['EPIC', 'VERY_LARGE'] THEN 16
         
         // Senior team - handles medium complexity groups
         WHEN team.skillLevel = 'SENIOR' AND sg.riskLevel = 'MEDIUM_RISK_GROUP' THEN 18
         WHEN team.skillLevel = 'SENIOR' AND flow.finalStoryPoints >= 8 AND flow.finalStoryPoints <= 12 THEN 16
         WHEN team.skillLevel = 'SENIOR' AND sg.category IN ['LARGE', 'MEDIUM'] THEN 14
         
         // Standard team - handles low-risk groups
         WHEN team.skillLevel = 'INTERMEDIATE' AND sg.riskLevel = 'LOW_RISK_GROUP' THEN 18
         WHEN team.skillLevel = 'INTERMEDIATE' AND flow.finalStoryPoints <= 7 THEN 16
         WHEN team.skillLevel = 'INTERMEDIATE' AND sg.category IN ['SMALL', 'TINY'] THEN 14
         
         ELSE 5
     END as similarityAwareScore,
     
     // Bonus for keeping similar flows together
     CASE sg.assignmentStrategy
         WHEN 'SAME_TEAM' THEN 5
         WHEN 'SAME_TEAM_SEQUENTIAL' THEN 3
         ELSE 0
     END as groupingBonus

RETURN sg.groupId as SimilarityGroup,
       sg.assignmentStrategy as Strategy,
       sg.flowCount as FlowsInGroup,
       team.teamName as RecommendedTeam,
       team.skillLevel as TeamSkill,
       (similarityAwareScore + groupingBonus) as TotalScore,
       sg.riskLevel as GroupRiskLevel
ORDER BY SimilarityGroup, TotalScore DESC;

// =============================================================================
// SECTION 4: SIMILARITY-AWARE SPRINT PLANNING
// =============================================================================

// 4.1 - Sequential sprint planning for similar flows
MATCH (sg:SimilarityGroup)<-[:BELONGS_TO_SIMILARITY_GROUP]-(flow:Flow)-[a:STORY_ASSIGNED_TO]->(team:AgileTeam)
MATCH (app:MuleApp)-[:HAS_FLOW]->(flow)

WITH sg, team, 
     collect({
         app: app.name,
         flow: flow.flow,
         uniqueId: app.name + '::' + flow.flow,
         storyPoints: flow.finalStoryPoints,
         riskLevel: a.riskLevel
     }) as GroupFlows
ORDER BY sg.avgStoryPoints DESC  // Process complex groups first

WITH sg, team, GroupFlows,
     // Determine sprint sequencing strategy
     CASE sg.assignmentStrategy
         WHEN 'SAME_TEAM' THEN 'CONSECUTIVE_SPRINTS'
         WHEN 'SAME_TEAM_SEQUENTIAL' THEN 'SPACED_SPRINTS'
         ELSE 'DISTRIBUTED'
     END as sprintStrategy

RETURN sg.groupId as SimilarityGroup,
       sg.flowCount as FlowCount,
       team.teamName as AssignedTeam,
       sprintStrategy as SprintStrategy,
       GroupFlows[0..3] as SampleFlows,
       
       // Sprint planning recommendations
       CASE sprintStrategy
           WHEN 'CONSECUTIVE_SPRINTS' THEN 'Schedule all flows in 2-3 consecutive sprints for maximum learning'
           WHEN 'SPACED_SPRINTS' THEN 'Schedule with 1 sprint gap between groups for knowledge consolidation'
           ELSE 'Distribute across multiple teams with lead team guidance'
       END as SprintRecommendation
ORDER BY sg.avgStoryPoints DESC;

// =============================================================================
// SECTION 5: SIMILARITY GROUP MANAGEMENT RECOMMENDATIONS
// =============================================================================

// 5.1 - Management strategy recommendations
MATCH (sg:SimilarityGroup)
RETURN sg.groupId as SimilarityGroup,
       sg.flowCount as FlowCount,
       sg.avgStoryPoints as AvgComplexity,
       sg.riskLevel as RiskLevel,
       sg.assignmentStrategy as AssignmentStrategy,
       
       // Detailed recommendations
       CASE sg.assignmentStrategy
           WHEN 'SAME_TEAM' THEN 'Assign all flows to one team. First flow is learning experience, others benefit from patterns.'
           WHEN 'SAME_TEAM_SEQUENTIAL' THEN 'Assign to one team but schedule sequentially. Allow learning between similar flows.'
           WHEN 'DISTRIBUTED_WITH_LEAD' THEN 'One expert team handles first flow, shares patterns with other teams.'
           ELSE 'Standard assignment'
       END as ManagementRecommendation,
       
       // Risk mitigation
       CASE sg.riskLevel
           WHEN 'HIGH_RISK_GROUP' THEN 'Create detailed documentation from first flow. Expert team should handle all or provide guidance.'
           WHEN 'MEDIUM_RISK_GROUP' THEN 'Document patterns and best practices. Senior team can handle with oversight.'
           ELSE 'Standard processes apply. Document any reusable patterns.'
       END as RiskMitigation,
       
       // Knowledge sharing
       'Schedule demo/knowledge sharing session after first flow completion' as KnowledgeSharing

ORDER BY sg.flowCount DESC, sg.avgStoryPoints DESC;

// =============================================================================
// SECTION 6: SIMILARITY VERIFICATION AND CLEANUP
// =============================================================================

// 6.1 - Verify similarity group assignments
MATCH (sg:SimilarityGroup)<-[:BELONGS_TO_SIMILARITY_GROUP]-(flow:Flow)
RETURN sg.groupId as SimilarityGroup,
       count(flow) as ActualFlowCount,
       sg.flowCount as ExpectedFlowCount,
       CASE WHEN count(flow) = sg.flowCount THEN ' CORRECT' ELSE ' MISMATCH' END as Status
ORDER BY ActualFlowCount DESC;

// 6.2 - Clean up existing similarity groups (run before creating new ones)
MATCH (sg:SimilarityGroup)
DETACH DELETE sg; 