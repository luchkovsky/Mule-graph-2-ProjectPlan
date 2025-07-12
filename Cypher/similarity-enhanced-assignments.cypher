// SIMILARITY-ENHANCED TEAM ASSIGNMENTS
// Replaces risk-based-assignments.cypher when you want to consider flow similarity

// Remove existing assignments and similarity groups
MATCH ()-[r:STORY_ASSIGNED_TO]->()
DELETE r;

MATCH (sg:SimilarityGroup)
DETACH DELETE sg;

// =============================================================================
// STEP 1: CREATE SIMILARITY GROUPS
// =============================================================================

// Create similarity groups based on connector patterns and complexity
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
// STEP 2: SIMILARITY-AWARE TEAM ASSIGNMENTS
// =============================================================================

// Assign flows with similarity group consideration
MATCH (flow:Flow)
MATCH (team:AgileTeam)
WHERE flow.finalStoryPoints IS NOT NULL

// Get similarity group if exists
OPTIONAL MATCH (flow)-[:BELONGS_TO_SIMILARITY_GROUP]->(sg:SimilarityGroup)

WITH flow, team, sg,
     // Enhanced risk scoring with similarity consideration
     CASE 
         // HIGH RISK - Custom code heavy flows or high-risk groups
         WHEN sg IS NOT NULL AND sg.riskLevel = 'HIGH_RISK_GROUP' THEN 'HIGH_RISK'
         WHEN flow.connectorCount >= 3 AND flow.dwScriptCount >= 3 THEN 'HIGH_RISK'
         WHEN flow.finalStoryPoints >= 10 THEN 'HIGH_RISK'
         
         // MEDIUM RISK - Moderate complexity or medium-risk groups
         WHEN sg IS NOT NULL AND sg.riskLevel = 'MEDIUM_RISK_GROUP' THEN 'MEDIUM_RISK'
         WHEN flow.connectorCount >= 2 OR flow.dwScriptCount >= 2 THEN 'MEDIUM_RISK'
         WHEN flow.finalStoryPoints >= 8 THEN 'MEDIUM_RISK'
         WHEN flow.isApiExposed = true AND flow.finalStoryPoints >= 5 THEN 'MEDIUM_RISK'
         
         // LOW RISK - Simple flows or low-risk groups
         WHEN sg IS NOT NULL AND sg.riskLevel = 'LOW_RISK_GROUP' THEN 'LOW_RISK'
         WHEN flow.finalStoryPoints >= 5 THEN 'LOW_RISK'
         ELSE 'MINIMAL_RISK'
     END as riskLevel,
     
     // Team suitability scoring with similarity group bonuses
     CASE 
         // Expert team - handles HIGH_RISK and complex APIs + similarity groups
         WHEN team.skillLevel = 'EXPERT' AND sg IS NOT NULL AND sg.riskLevel = 'HIGH_RISK_GROUP' THEN 22  // Bonus for similarity group
         WHEN team.skillLevel = 'EXPERT' AND flow.connectorCount >= 3 AND flow.dwScriptCount >= 3 THEN 20
         WHEN team.skillLevel = 'EXPERT' AND flow.finalStoryPoints >= 10 THEN 18
         WHEN team.skillLevel = 'EXPERT' AND flow.isApiExposed = true AND flow.finalStoryPoints >= 8 THEN 16
         WHEN team.skillLevel = 'EXPERT' AND flow.finalStoryPoints >= 8 THEN 15
         
         // Senior team - handles MEDIUM_RISK and standard complexity + similarity groups
         WHEN team.skillLevel = 'SENIOR' AND sg IS NOT NULL AND sg.riskLevel = 'MEDIUM_RISK_GROUP' THEN 20  // Bonus for similarity group
         WHEN team.skillLevel = 'SENIOR' AND flow.connectorCount >= 2 AND flow.finalStoryPoints <= 12 THEN 18
         WHEN team.skillLevel = 'SENIOR' AND flow.finalStoryPoints >= 8 AND flow.finalStoryPoints <= 12 THEN 16
         WHEN team.skillLevel = 'SENIOR' AND flow.isApiExposed = true AND flow.finalStoryPoints <= 8 THEN 15
         WHEN team.skillLevel = 'SENIOR' AND flow.finalStoryPoints >= 5 AND flow.finalStoryPoints <= 7 THEN 14
         
         // Standard team - handles LOW_RISK and simple flows + similarity groups
         WHEN team.skillLevel = 'INTERMEDIATE' AND sg IS NOT NULL AND sg.riskLevel = 'LOW_RISK_GROUP' THEN 20  // Bonus for similarity group
         WHEN team.skillLevel = 'INTERMEDIATE' AND flow.connectorCount <= 1 AND flow.finalStoryPoints <= 7 THEN 18
         WHEN team.skillLevel = 'INTERMEDIATE' AND flow.finalStoryPoints >= 1 AND flow.finalStoryPoints <= 5 THEN 16
         WHEN team.skillLevel = 'INTERMEDIATE' AND flow.finalStoryPoints >= 6 AND flow.finalStoryPoints <= 9 THEN 12
         WHEN team.skillLevel = 'INTERMEDIATE' AND flow.finalStoryPoints >= 10 THEN 5
         
         ELSE 3
     END as baseSuitabilityScore,
     
     // Additional bonus for similarity group assignment strategies
     CASE 
         WHEN sg IS NOT NULL AND sg.assignmentStrategy = 'SAME_TEAM' THEN 5
         WHEN sg IS NOT NULL AND sg.assignmentStrategy = 'SAME_TEAM_SEQUENTIAL' THEN 3
         WHEN sg IS NOT NULL AND sg.assignmentStrategy = 'DISTRIBUTED_WITH_LEAD' AND team.skillLevel = 'EXPERT' THEN 2
         ELSE 0
     END as similarityBonus

// Assign flows to best teams with similarity consideration
WITH flow, riskLevel, sg,
     collect({team: team, score: baseSuitabilityScore + similarityBonus, teamLevel: team.skillLevel}) as teamOptions

WITH flow, riskLevel, sg,
     reduce(best = null, option IN teamOptions | 
         CASE 
             WHEN best IS NULL OR option.score > best.score 
             THEN option
             ELSE best
         END
     ) as bestTeam

// Create assignment with similarity metadata
MATCH (team:AgileTeam)
WHERE team = bestTeam.team
CREATE (flow)-[a:STORY_ASSIGNED_TO]->(team)
SET a.riskLevel = riskLevel,
    a.assignmentScore = bestTeam.score,
    a.assignmentReason = 
        CASE 
            WHEN bestTeam.score >= 20 THEN 'OPTIMAL_MATCH_WITH_SIMILARITY'
            WHEN bestTeam.score >= 18 THEN 'GOOD_MATCH_WITH_SIMILARITY'
            WHEN bestTeam.score >= 15 THEN 'GOOD_MATCH'
            WHEN bestTeam.score >= 12 THEN 'ACCEPTABLE_MATCH'
            ELSE 'FALLBACK_ASSIGNMENT'
        END,
    a.similarityGroupId = CASE WHEN sg IS NOT NULL THEN sg.groupId ELSE null END,
    a.assignmentStrategy = CASE WHEN sg IS NOT NULL THEN sg.assignmentStrategy ELSE 'INDIVIDUAL' END;

// =============================================================================
// STEP 3: VERIFY SIMILARITY-ENHANCED ASSIGNMENTS
// =============================================================================

// Show team assignments with similarity group analysis
MATCH (flow:Flow)-[a:STORY_ASSIGNED_TO]->(team:AgileTeam)
OPTIONAL MATCH (flow)-[:BELONGS_TO_SIMILARITY_GROUP]->(sg:SimilarityGroup)

RETURN team.teamName as Team,
       count(flow) as TotalFlows,
       count(CASE WHEN sg IS NOT NULL THEN 1 END) as FlowsInSimilarityGroups,
       count(DISTINCT sg.groupId) as SimilarityGroupsAssigned,
       
       // Risk distribution
       count(CASE WHEN a.riskLevel = 'HIGH_RISK' THEN 1 END) as HighRiskStories,
       count(CASE WHEN a.riskLevel = 'MEDIUM_RISK' THEN 1 END) as MediumRiskStories,
       count(CASE WHEN a.riskLevel = 'LOW_RISK' THEN 1 END) as LowRiskStories,
       
       // Assignment quality
       count(CASE WHEN a.assignmentReason CONTAINS 'SIMILARITY' THEN 1 END) as SimilarityEnhancedAssignments,
       round(avg(a.assignmentScore), 1) as AvgAssignmentScore,
       
       // Story points
       sum(flow.finalStoryPoints) as TotalStoryPoints,
       round(avg(flow.finalStoryPoints), 1) as AvgStoryPoints

ORDER BY CASE team.skillLevel 
    WHEN 'EXPERT' THEN 1 
    WHEN 'SENIOR' THEN 2 
    ELSE 3 
END;

// Show similarity group assignments summary
MATCH (sg:SimilarityGroup)<-[:BELONGS_TO_SIMILARITY_GROUP]-(flow:Flow)-[a:STORY_ASSIGNED_TO]->(team:AgileTeam)

RETURN sg.groupId as SimilarityGroup,
       sg.assignmentStrategy as Strategy,
       sg.flowCount as FlowsInGroup,
       count(DISTINCT team.teamName) as TeamsAssigned,
       collect(DISTINCT team.teamName) as AssignedTeams,
       sg.riskLevel as GroupRiskLevel,
       round(sg.avgStoryPoints, 1) as AvgStoryPoints,
       
       // Strategy assessment
       CASE 
           WHEN sg.assignmentStrategy = 'SAME_TEAM' AND count(DISTINCT team.teamName) = 1 THEN ' STRATEGY_FOLLOWED'
           WHEN sg.assignmentStrategy = 'SAME_TEAM_SEQUENTIAL' AND count(DISTINCT team.teamName) = 1 THEN ' STRATEGY_FOLLOWED'
           WHEN sg.assignmentStrategy = 'DISTRIBUTED_WITH_LEAD' AND count(DISTINCT team.teamName) > 1 THEN ' STRATEGY_FOLLOWED'
           ELSE ' STRATEGY_DEVIATION'
       END as StrategyAdherence

ORDER BY sg.flowCount DESC, sg.avgStoryPoints DESC; 