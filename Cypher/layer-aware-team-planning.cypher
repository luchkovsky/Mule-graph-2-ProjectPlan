// LAYER-AWARE TEAM ASSIGNMENTS
// Assigns flows to teams based on Mule architectural layer specialization

// =============================================================================
// SECTION 1: LAYER-AWARE TEAM DEFINITIONS
// =============================================================================

// -----------------------------------------------------------------------------
// 1.1 - Load planning configuration & ensure canonical teams exist
// -----------------------------------------------------------------------------
MATCH (cfg:PlanningConfig {id:'DEFAULT'})
WITH cfg

// Ensure that the three canonical AgileTeam nodes exist (created by
// initialize-agile-teams.cypher). Fail fast if any are missing.
MATCH (expertTeam:AgileTeam {teamName:'Expert Team'})
MATCH (seniorTeam:AgileTeam {teamName:'Senior Team'})
MATCH (standardTeam:AgileTeam {teamName:'Standard Team'})
// Continue with assignment logic

// =============================================================================
// SECTION 2: LAYER-AWARE ASSIGNMENT LOGIC
// =============================================================================

// 2.1 - Clear existing assignments
MATCH (team:AgileTeam)-[r:STORY_ASSIGNED_TO]-(flow:Flow)
DELETE r;

// 2.2 - Layer-aware team assignment with enhanced scoring
// CONSTRAINT: All flows within the same application must be assigned to the same team
MATCH (app:MuleApp)-[:HAS_FLOW]->(flow:Flow)
WHERE flow.muleLayer IS NOT NULL AND flow.finalStoryPoints IS NOT NULL

// First, determine the best team for each application based on aggregated flow characteristics
WITH app, collect(flow) as appFlows,
     count(flow) as totalFlows,
     sum(flow.finalStoryPoints) as totalStoryPoints,
     round(avg(flow.finalStoryPoints), 1) as avgStoryPoints,
     count(CASE WHEN flow.layerSpecificRisk = 'HIGH_RISK' THEN 1 END) as highRiskFlows,
     count(CASE WHEN flow.muleLayer = 'EXPERIENCE' THEN 1 END) as experienceFlows,
     count(CASE WHEN flow.muleLayer = 'PROCESS' THEN 1 END) as processFlows,
     count(CASE WHEN flow.muleLayer = 'SYSTEM' THEN 1 END) as systemFlows,
     head(collect(DISTINCT flow.muleLayer)) as primaryLayer

// Calculate application-level team assignment score
WITH app, appFlows, totalFlows, totalStoryPoints, avgStoryPoints, highRiskFlows,
     experienceFlows, processFlows, systemFlows, primaryLayer,
     
     // Application-level scoring for Expert team
     CASE 
         WHEN avgStoryPoints >= 8 OR highRiskFlows > 0 OR processFlows > (totalFlows * 0.4) THEN 15
         WHEN totalStoryPoints >= 40 THEN 14
         WHEN processFlows > 0 THEN 13
         ELSE 10
     END as appExpertScore,
     
     // Application-level scoring for Senior team  
     CASE 
         WHEN experienceFlows > (totalFlows * 0.5) AND avgStoryPoints >= 5 AND avgStoryPoints <= 8 THEN 15
         WHEN avgStoryPoints >= 5 AND avgStoryPoints <= 10 THEN 14
         WHEN experienceFlows > 0 THEN 13
         ELSE 11
     END as appSeniorScore,
     
     // Application-level scoring for Standard team
     CASE 
         WHEN avgStoryPoints <= 5 AND highRiskFlows = 0 THEN 15
         WHEN systemFlows > (totalFlows * 0.6) AND avgStoryPoints <= 6 THEN 14
         WHEN avgStoryPoints <= 6 THEN 13
         ELSE 10
     END as appStandardScore

// Determine the best team for each application
WITH app, appFlows, 
     CASE 
         WHEN appExpertScore >= appSeniorScore AND appExpertScore >= appStandardScore THEN 'EXPERT'
         WHEN appSeniorScore >= appStandardScore THEN 'SENIOR'
         ELSE 'STANDARD'
     END as assignedTeamLevel,
     appExpertScore, appSeniorScore, appStandardScore

// Now assign all flows in the application to the selected team
UNWIND appFlows as flow

WITH flow, assignedTeamLevel, appExpertScore, appSeniorScore, appStandardScore,
     // Individual flow scoring for documentation purposes
     CASE flow.muleLayer
         WHEN 'EXPERIENCE' THEN
             CASE 
                 WHEN flow.finalStoryPoints >= 8 THEN 15
                 WHEN flow.isApiExposed = true AND flow.finalStoryPoints >= 5 THEN 14
                 WHEN flow.finalStoryPoints <= 4 THEN 13
                 ELSE 12
             END
         WHEN 'PROCESS' THEN
             CASE 
                 WHEN flow.finalStoryPoints >= 8 THEN 15
                 WHEN flow.connectorCount >= 4 AND flow.dwScriptCount >= 3 THEN 14
                 WHEN flow.finalStoryPoints >= 5 THEN 13
                 ELSE 11
             END
         WHEN 'SYSTEM' THEN
             CASE 
                 WHEN flow.connectorCount >= 5 THEN 15
                 WHEN flow.finalStoryPoints >= 8 THEN 14
                 WHEN flow.finalStoryPoints >= 5 THEN 12
                 ELSE 13
             END
         ELSE 10
     END as individualScore

// Create assignment relationships - all flows in app assigned to same team
MATCH (team:AgileTeam)
WHERE team.skillLevel = assignedTeamLevel

CREATE (flow)-[:STORY_ASSIGNED_TO]->(team)
SET flow.assignedTeamLevel = assignedTeamLevel,
    flow.assignmentReason = 'Application-level layer-aware assignment: all flows in ' + flow.app + ' assigned to ' + assignedTeamLevel + ' team',
    flow.appExpertScore = appExpertScore,
    flow.appSeniorScore = appSeniorScore,
    flow.appStandardScore = appStandardScore,
    flow.individualScore = individualScore,
    flow.assignedAt = datetime(),
    flow.applicationTeamConstraint = true;

// =============================================================================
// SECTION 3: LAYER-BASED ASSIGNMENT ANALYSIS
// =============================================================================

// 3.1 - Team assignment summary by layer
MATCH (team:AgileTeam)<-[:STORY_ASSIGNED_TO]-(flow:Flow)
WHERE flow.muleLayer IS NOT NULL

WITH team.teamName as Team,
     team.primaryLayer as TeamSpecialization,
     collect(DISTINCT flow.muleLayer) as AssignedLayers,
     count(flow) as TotalFlows,
     count(CASE WHEN flow.muleLayer = 'EXPERIENCE' THEN 1 END) as ExperienceFlows,
     count(CASE WHEN flow.muleLayer = 'PROCESS' THEN 1 END) as ProcessFlows,
     count(CASE WHEN flow.muleLayer = 'SYSTEM' THEN 1 END) as SystemFlows,
     sum(flow.finalStoryPoints) as TotalStoryPoints,
     round(avg(flow.finalStoryPoints), 1) as AvgStoryPoints,
     count(CASE WHEN flow.layerSpecificRisk = 'HIGH_RISK' THEN 1 END) as HighRiskFlows,
     count(CASE WHEN flow.layerSpecificRisk = 'MEDIUM_RISK' THEN 1 END) as MediumRiskFlows,
     count(CASE WHEN flow.layerSpecificRisk = 'LOW_RISK' THEN 1 END) as LowRiskFlows

RETURN Team,
       TeamSpecialization,
       TotalFlows,
       ExperienceFlows,
       ProcessFlows,
       SystemFlows,
       TotalStoryPoints,
       AvgStoryPoints,
       HighRiskFlows,
       MediumRiskFlows,
       LowRiskFlows,
       
       // Layer alignment score
       CASE TeamSpecialization
           WHEN 'PROCESS' THEN round((ProcessFlows * 1.0 / TotalFlows) * 100, 1)
           WHEN 'EXPERIENCE' THEN round((ExperienceFlows * 1.0 / TotalFlows) * 100, 1)
           WHEN 'SYSTEM' THEN round((SystemFlows * 1.0 / TotalFlows) * 100, 1)
           ELSE 0
       END as LayerAlignmentPercentage,
       
       // Risk distribution
       CASE 
           WHEN HighRiskFlows > (TotalFlows * 0.3) THEN ' HIGH_RISK_LOAD'
           WHEN MediumRiskFlows > (TotalFlows * 0.5) THEN ' MEDIUM_RISK_LOAD'
           ELSE ' BALANCED_RISK'
       END as RiskLoadStatus

ORDER BY TotalStoryPoints DESC;

// 3.2 - Layer distribution across teams
MATCH (flow:Flow)
WHERE flow.muleLayer IS NOT NULL AND flow.assignedTeamLevel IS NOT NULL

WITH flow.muleLayer as Layer,
     count(flow) as TotalFlows,
     count(CASE WHEN flow.assignedTeamLevel = 'EXPERT' THEN 1 END) as ExpertAssigned,
     count(CASE WHEN flow.assignedTeamLevel = 'SENIOR' THEN 1 END) as SeniorAssigned,
     count(CASE WHEN flow.assignedTeamLevel = 'STANDARD' THEN 1 END) as StandardAssigned,
     sum(flow.finalStoryPoints) as TotalStoryPoints,
     round(avg(flow.finalStoryPoints), 1) as AvgStoryPoints

RETURN Layer,
       TotalFlows,
       ExpertAssigned,
       SeniorAssigned,
       StandardAssigned,
       TotalStoryPoints,
       AvgStoryPoints,
       
       // Layer assignment distribution
       round((ExpertAssigned * 100.0 / TotalFlows), 1) as ExpertPercentage,
       round((SeniorAssigned * 100.0 / TotalFlows), 1) as SeniorPercentage,
       round((StandardAssigned * 100.0 / TotalFlows), 1) as StandardPercentage,
       
       // Optimal team for this layer
       CASE 
           WHEN ExpertAssigned >= SeniorAssigned AND ExpertAssigned >= StandardAssigned THEN 'EXPERT_PREFERRED'
           WHEN SeniorAssigned >= StandardAssigned THEN 'SENIOR_PREFERRED'
           ELSE 'STANDARD_PREFERRED'
       END as PreferredTeam

ORDER BY CASE Layer 
    WHEN 'EXPERIENCE' THEN 1 
    WHEN 'PROCESS' THEN 2 
    WHEN 'SYSTEM' THEN 3 
    ELSE 4 
END;

// =============================================================================
// SECTION 4: LAYER-SPECIFIC TEAM RECOMMENDATIONS
// =============================================================================

// 4.1 - Assignment quality analysis
MATCH (team:AgileTeam)<-[:STORY_ASSIGNED_TO]-(flow:Flow)
WHERE flow.muleLayer IS NOT NULL

WITH team,
     count(flow) as assignedFlows,
     count(CASE WHEN flow.muleLayer = team.primaryLayer THEN 1 END) as matchingLayerFlows,
     count(CASE WHEN flow.layerSpecificRisk = 'HIGH_RISK' THEN 1 END) as highRiskFlows,
     collect(DISTINCT flow.muleLayer) as assignedLayers

RETURN team.teamName as Team,
       team.primaryLayer as Specialization,
       assignedFlows as TotalAssigned,
       matchingLayerFlows as MatchingSpecialization,
       highRiskFlows as HighRiskAssigned,
       assignedLayers as LayersAssigned,
       
       // Specialization alignment
       round((matchingLayerFlows * 100.0 / assignedFlows), 1) as SpecializationAlignment,
       
       // Assignment quality score
       CASE 
           WHEN (matchingLayerFlows * 100.0 / assignedFlows) >= 60 THEN ' EXCELLENT_ALIGNMENT'
           WHEN (matchingLayerFlows * 100.0 / assignedFlows) >= 40 THEN '👍 GOOD_ALIGNMENT'
           WHEN (matchingLayerFlows * 100.0 / assignedFlows) >= 20 THEN ' FAIR_ALIGNMENT'
           ELSE ' POOR_ALIGNMENT'
       END as AlignmentQuality,
       
       // Risk balance
       CASE 
           WHEN highRiskFlows > (assignedFlows * 0.4) THEN ' HIGH_RISK_OVERLOAD'
           WHEN highRiskFlows > (assignedFlows * 0.2) THEN ' MEDIUM_RISK_LOAD'
           ELSE ' BALANCED_RISK'
       END as RiskBalance

ORDER BY SpecializationAlignment DESC;

// 4.2 - Layer-specific recommendations
MATCH (flow:Flow)
WHERE flow.muleLayer IS NOT NULL AND flow.assignedTeamLevel IS NOT NULL

WITH flow.muleLayer as Layer,
     flow.assignedTeamLevel as AssignedTeam,
     count(flow) as FlowCount,
     collect(CASE WHEN flow.layerSpecificRisk = 'HIGH_RISK' THEN flow.flow END) as HighRiskFlows

WHERE FlowCount > 0

RETURN Layer,
       AssignedTeam,
       FlowCount,
       
       // Layer-specific recommendations
       CASE Layer
           WHEN 'EXPERIENCE' THEN
               CASE AssignedTeam
                   WHEN 'EXPERT' THEN 'Consider if these are truly complex experience flows or should be reassigned to Senior team'
                   WHEN 'SENIOR' THEN 'Ideal assignment for experience layer - good API design skills'
                   ELSE 'Good for simple experience flows, but watch for API complexity'
               END
           WHEN 'PROCESS' THEN
               CASE AssignedTeam
                   WHEN 'EXPERT' THEN 'Perfect assignment for complex business process orchestration'
                   WHEN 'SENIOR' THEN 'Good for medium complexity processes, may need Expert team guidance'
                   ELSE 'Risky for complex processes - consider reassignment'
               END
           WHEN 'SYSTEM' THEN
               CASE AssignedTeam
                   WHEN 'EXPERT' THEN 'May be overkill unless very complex system integration'
                   WHEN 'SENIOR' THEN 'Good for medium complexity system integration'
                   ELSE 'Ideal for simple system access and basic database operations'
               END
           ELSE 'Review layer classification'
       END as Recommendation,
       
       // Risk considerations
       CASE 
           WHEN size(HighRiskFlows) > 0 THEN 'High risk flows: ' + reduce(s = '', x IN HighRiskFlows[0..3] | s + CASE WHEN s = '' THEN x ELSE ', ' + x END)
           ELSE 'No high risk flows'
       END as RiskConsiderations

ORDER BY CASE Layer 
    WHEN 'EXPERIENCE' THEN 1 
    WHEN 'PROCESS' THEN 2 
    WHEN 'SYSTEM' THEN 3 
    ELSE 4 
END,
CASE AssignedTeam 
    WHEN 'EXPERT' THEN 1 
    WHEN 'SENIOR' THEN 2 
    WHEN 'STANDARD' THEN 3 
    ELSE 4 
END; 