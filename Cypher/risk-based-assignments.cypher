// STEP 3: RISK-BASED TEAM ASSIGNMENTS
// Improved algorithm that considers risk, complexity, and custom code

// Remove existing assignments
MATCH ()-[r:STORY_ASSIGNED_TO]->()
DELETE r;

// Enhanced team assignment with risk prioritization
MATCH (flow:Flow)
MATCH (team:AgileTeam)
WHERE flow.finalStoryPoints IS NOT NULL

WITH flow, team,
     // Enhanced risk scoring
     CASE 
         // HIGH RISK - Custom code heavy flows
         WHEN flow.connectorCount >= 3 AND flow.dwScriptCount >= 3 THEN 'HIGH_RISK'
         WHEN flow.finalStoryPoints >= 10 THEN 'HIGH_RISK'
         
         // MEDIUM RISK - Moderate complexity
         WHEN flow.connectorCount >= 2 OR flow.dwScriptCount >= 2 THEN 'MEDIUM_RISK'
         WHEN flow.finalStoryPoints >= 8 THEN 'MEDIUM_RISK'
         WHEN flow.isApiExposed = true AND flow.finalStoryPoints >= 5 THEN 'MEDIUM_RISK'
         
         // LOW RISK - Simple flows
         WHEN flow.finalStoryPoints >= 5 THEN 'LOW_RISK'
         ELSE 'MINIMAL_RISK'
     END as riskLevel,
     
     // Team suitability scoring with risk consideration
     CASE 
         // Expert team - handles HIGH_RISK and complex APIs
         WHEN team.skillLevel = 'EXPERT' AND flow.connectorCount >= 3 AND flow.dwScriptCount >= 3 THEN 20  // Custom heavy
         WHEN team.skillLevel = 'EXPERT' AND flow.finalStoryPoints >= 10 THEN 18                           // High complexity
         WHEN team.skillLevel = 'EXPERT' AND flow.isApiExposed = true AND flow.finalStoryPoints >= 8 THEN 16  // Complex APIs
         WHEN team.skillLevel = 'EXPERT' AND flow.finalStoryPoints >= 8 THEN 15                           // Medium-high complexity
         
         // Senior team - handles MEDIUM_RISK and standard complexity
         WHEN team.skillLevel = 'SENIOR' AND flow.connectorCount >= 2 AND flow.finalStoryPoints <= 12 THEN 18  // Moderate custom code
         WHEN team.skillLevel = 'SENIOR' AND flow.finalStoryPoints >= 8 AND flow.finalStoryPoints <= 12 THEN 16  // Medium complexity
         WHEN team.skillLevel = 'SENIOR' AND flow.isApiExposed = true AND flow.finalStoryPoints <= 8 THEN 15     // Simple APIs
         WHEN team.skillLevel = 'SENIOR' AND flow.finalStoryPoints >= 5 AND flow.finalStoryPoints <= 7 THEN 14   // Small-medium
         
         // Standard team - handles LOW_RISK and simple flows
         WHEN team.skillLevel = 'INTERMEDIATE' AND flow.connectorCount <= 1 AND flow.finalStoryPoints <= 7 THEN 18  // Simple flows
         WHEN team.skillLevel = 'INTERMEDIATE' AND flow.finalStoryPoints >= 1 AND flow.finalStoryPoints <= 5 THEN 16  // Small flows
         WHEN team.skillLevel = 'INTERMEDIATE' AND flow.finalStoryPoints >= 6 AND flow.finalStoryPoints <= 9 THEN 12  // Can handle medium
         WHEN team.skillLevel = 'INTERMEDIATE' AND flow.finalStoryPoints >= 10 THEN 5                              // Avoid high complexity
         
         ELSE 3
     END as suitabilityScore

// Assign flows to best teams
WITH flow, riskLevel,
     collect({team: team, score: suitabilityScore, teamLevel: team.skillLevel}) as teamOptions

WITH flow, riskLevel,
     reduce(best = null, option IN teamOptions | 
         CASE 
             WHEN best IS NULL OR option.score > best.score 
             THEN option
             ELSE best
         END
     ) as bestTeam

// Create assignment with risk metadata
MATCH (team:AgileTeam)
WHERE team = bestTeam.team
CREATE (flow)-[a:STORY_ASSIGNED_TO]->(team)
SET a.riskLevel = riskLevel,
    a.assignmentScore = bestTeam.score,
    a.assignmentReason = 
        CASE 
            WHEN bestTeam.score >= 18 THEN 'OPTIMAL_MATCH'
            WHEN bestTeam.score >= 15 THEN 'GOOD_MATCH'
            WHEN bestTeam.score >= 12 THEN 'ACCEPTABLE_MATCH'
            ELSE 'FALLBACK_ASSIGNMENT'
        END;

// Verify risk-based assignments
MATCH (flow:Flow)-[a:STORY_ASSIGNED_TO]->(team:AgileTeam)
WITH team.teamName as Team,
     team.skillLevel as TeamSkillLevel,
     a.riskLevel as RiskLevel,
     count(flow) as StoryCount,
     round(avg(flow.finalStoryPoints), 1) as AvgStoryPoints,
     sum(flow.finalStoryPoints) as TotalStoryPoints,
     collect(DISTINCT a.assignmentReason)[0..3] as AssignmentReasons

RETURN Team,
       RiskLevel,
       StoryCount,
       AvgStoryPoints,
       TotalStoryPoints,
       AssignmentReasons
ORDER BY 
    CASE TeamSkillLevel 
        WHEN 'EXPERT' THEN 1 
        WHEN 'SENIOR' THEN 2 
        ELSE 3 
    END, 
    CASE RiskLevel 
        WHEN 'HIGH_RISK' THEN 1 
        WHEN 'MEDIUM_RISK' THEN 2 
        WHEN 'LOW_RISK' THEN 3 
        ELSE 4 
    END; 