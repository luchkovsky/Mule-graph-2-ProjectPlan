// ANALYZE ROADMAP, RISKS, AND COMPLEXITY DISTRIBUTION
// Let's see how well our algorithm handles complexity and risks

// ============================================
// 1. BACKLOG vs ROADMAP ANALYSIS
// ============================================

// Current state: We have sprint backlog, but do we have a roadmap?
MATCH (s:SprintBacklog)
WITH s.sprintNumber as Sprint,
     collect(DISTINCT s.appName) as AppsInSprint,
     sum(s.storyPoints) as SprintPoints,
     count(CASE WHEN s.storyPoints >= 8 THEN 1 END) as ComplexStories,
     count(CASE WHEN s.isApiExposed THEN 1 END) as ApiStories
RETURN Sprint,
       size(AppsInSprint) as ApplicationsWorked,
       SprintPoints,
       ComplexStories,
       ApiStories,
       CASE 
           WHEN Sprint <= 3 THEN 'PHASE 1: Foundation'
           WHEN Sprint <= 6 THEN 'PHASE 2: Core Migration' 
           WHEN Sprint <= 9 THEN 'PHASE 3: Integration'
           ELSE 'PHASE 4: Finalization'
       END as ProjectPhase
ORDER BY Sprint;

// ============================================
// 2. RISK ANALYSIS - ARE RISKY FLOWS HANDLED PROPERLY?
// ============================================

// Identify risky flows and how they're distributed
MATCH (s:SprintBacklog)
WITH s,
     CASE 
         WHEN s.storyPoints >= 10 THEN 'HIGH_RISK'
         WHEN s.storyPoints >= 8 THEN 'MEDIUM_RISK'
         WHEN s.storyPoints >= 5 THEN 'LOW_RISK'
         ELSE 'MINIMAL_RISK'
     END as RiskLevel

RETURN RiskLevel,
       count(s) as StoryCount,
       round(avg(s.sprintNumber), 1) as AvgSprintNumber,
       collect(DISTINCT s.teamName) as TeamsHandling,
       min(s.sprintNumber) as EarliestSprint,
       max(s.sprintNumber) as LatestSprint
ORDER BY 
    CASE RiskLevel 
        WHEN 'HIGH_RISK' THEN 1
        WHEN 'MEDIUM_RISK' THEN 2 
        WHEN 'LOW_RISK' THEN 3
        ELSE 4
    END;

// ============================================
// 3. COMPLEXITY DISTRIBUTION ACROSS SPRINTS
// ============================================

// Are we balancing complexity properly?
MATCH (s:SprintBacklog)
WITH s.sprintNumber as Sprint,
     avg(s.storyPoints) as AvgComplexity,
     sum(s.storyPoints) as TotalComplexity,
     count(s) as StoryCount,
     count(CASE WHEN s.storyPoints >= 10 THEN 1 END) as HighComplexityCount
RETURN Sprint,
       round(AvgComplexity, 1) as AvgComplexity,
       TotalComplexity,
       StoryCount,
       HighComplexityCount,
       CASE 
           WHEN AvgComplexity >= 7 THEN 'COMPLEX_SPRINT'
           WHEN AvgComplexity >= 5 THEN 'MODERATE_SPRINT'
           ELSE 'SIMPLE_SPRINT'
       END as SprintComplexity
ORDER BY Sprint;

// ============================================
// 4. TEAM RISK ASSIGNMENT - ARE EXPERTS GETTING RISKY WORK?
// ============================================

MATCH (s:SprintBacklog)
WITH s.teamName as Team,
     count(CASE WHEN s.storyPoints >= 10 THEN 1 END) as HighRiskStories,
     count(CASE WHEN s.storyPoints >= 8 THEN 1 END) as MediumRiskStories,
     count(CASE WHEN s.storyPoints <= 3 THEN 1 END) as LowRiskStories,
     count(s) as TotalStories,
     round(avg(s.storyPoints), 1) as AvgComplexity
RETURN Team,
       TotalStories,
       HighRiskStories,
       MediumRiskStories,
       LowRiskStories,
       AvgComplexity,
       round(HighRiskStories * 100.0 / TotalStories, 1) as HighRiskPercentage
ORDER BY AvgComplexity DESC;

// ============================================
// 5. MISSING: CUSTOM CODE AND CONNECTORS ANALYSIS
// ============================================

// Let's see if we're considering custom code complexity
MATCH (app:MuleApp)-[:HAS_FLOW]->(flow:Flow)-[:STORY_ASSIGNED_TO]->(team:AgileTeam)
OPTIONAL MATCH (s:SprintBacklog {flowName: flow.flow, teamName: team.teamName})
RETURN flow.flow as FlowName,
       flow.connectorCount as Connectors,
       flow.dwScriptCount as DataWeaveScripts,
       flow.stepCount as Steps,
       flow.finalStoryPoints as StoryPoints,
       team.teamName as AssignedTeam,
       s.sprintNumber as Sprint,
       CASE 
           WHEN flow.connectorCount >= 3 AND flow.dwScriptCount >= 3 THEN 'CUSTOM_HEAVY'
           WHEN flow.connectorCount >= 2 OR flow.dwScriptCount >= 2 THEN 'CUSTOM_MODERATE'
           ELSE 'STANDARD'
       END as CustomCodeRisk
ORDER BY CustomCodeRisk, flow.finalStoryPoints DESC
LIMIT 15; 