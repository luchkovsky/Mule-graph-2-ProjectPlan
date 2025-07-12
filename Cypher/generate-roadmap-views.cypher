// STEP 5: GENERATE ROADMAP VIEWS
// Creates comprehensive project views for management and tracking

// VIEW 1: Sprint Timeline Overview
MATCH (sb:SprintBacklog)
WITH sb.sprintNumber as Sprint,
     sb.projectPhase as Phase,
     sb.startWeek as StartWeek,
     sb.endWeek as EndWeek,
     count(sb) as TotalStories,
     sum(sb.storyPoints) as TotalStoryPoints,
     collect(DISTINCT sb.teamName) as Teams,
     count(CASE WHEN sb.riskLevel = 'HIGH_RISK' THEN 1 END) as HighRisk,
     count(CASE WHEN sb.riskLevel = 'MEDIUM_RISK' THEN 1 END) as MediumRisk,
     count(CASE WHEN sb.riskLevel = 'LOW_RISK' THEN 1 END) as LowRisk,
     count(CASE WHEN sb.isApiExposed = true THEN 1 END) as ApiStories,
     count(CASE WHEN sb.isCustomHeavy = true THEN 1 END) as CustomHeavyStories

RETURN Sprint, Phase, StartWeek, EndWeek, TotalStories, TotalStoryPoints, Teams,
       HighRisk, MediumRisk, LowRisk, ApiStories, CustomHeavyStories,
       
       // Risk percentage for visualization
       round(toFloat(HighRisk) / TotalStories * 100, 1) as HighRiskPct,
       
       // Workload indicator
       CASE 
           WHEN TotalStoryPoints >= 50 THEN 'HIGH_WORKLOAD'
           WHEN TotalStoryPoints >= 30 THEN 'MEDIUM_WORKLOAD'
           ELSE 'LOW_WORKLOAD'
       END as WorkloadLevel

ORDER BY Sprint;

// VIEW 2: Team Workload Distribution
MATCH (sb:SprintBacklog)
WITH sb.teamName as Team,
     count(sb) as TotalStories,
     sum(sb.storyPoints) as TotalStoryPoints,
     count(DISTINCT sb.sprintNumber) as SprintsWorked,
     count(CASE WHEN sb.riskLevel = 'HIGH_RISK' THEN 1 END) as HighRiskStories,
     count(CASE WHEN sb.riskLevel = 'MEDIUM_RISK' THEN 1 END) as MediumRiskStories,
     count(CASE WHEN sb.riskLevel = 'LOW_RISK' THEN 1 END) as LowRiskStories,
     round(avg(sb.storyPoints), 1) as AvgStoryPoints,
     min(sb.storyPoints) as MinStoryPoints,
     max(sb.storyPoints) as MaxStoryPoints,
     
     // Calculate workload spread
     collect(DISTINCT sb.sprintNumber) as SprintNumbers,
     count(CASE WHEN sb.isApiExposed = true THEN 1 END) as ApiStories,
     count(CASE WHEN sb.isCustomHeavy = true THEN 1 END) as CustomHeavyStories

RETURN Team, TotalStories, TotalStoryPoints, SprintsWorked,
       HighRiskStories, MediumRiskStories, LowRiskStories,
       AvgStoryPoints, MinStoryPoints, MaxStoryPoints,
       ApiStories, CustomHeavyStories,
       
       // Workload distribution
       round(toFloat(TotalStoryPoints) / SprintsWorked, 1) as AvgStoryPointsPerSprint,
       
       // Risk distribution percentages
       round(toFloat(HighRiskStories) / TotalStories * 100, 1) as HighRiskPct,
       round(toFloat(MediumRiskStories) / TotalStories * 100, 1) as MediumRiskPct,
       round(toFloat(LowRiskStories) / TotalStories * 100, 1) as LowRiskPct

ORDER BY CASE Team 
    WHEN 'Expert Team' THEN 1 
    WHEN 'Senior Team' THEN 2 
    ELSE 3 
END;

// VIEW 3: Risk Analysis by Phase
MATCH (sb:SprintBacklog)
WITH sb.projectPhase as Phase,
     min(sb.sprintNumber) as FirstSprint,
     max(sb.sprintNumber) as LastSprint,
     min(sb.startWeek) as PhaseStartWeek,
     max(sb.endWeek) as PhaseEndWeek,
     count(sb) as TotalStories,
     sum(sb.storyPoints) as TotalStoryPoints,
     count(CASE WHEN sb.riskLevel = 'HIGH_RISK' THEN 1 END) as HighRiskStories,
     count(CASE WHEN sb.riskLevel = 'MEDIUM_RISK' THEN 1 END) as MediumRiskStories,
     count(CASE WHEN sb.riskLevel = 'LOW_RISK' THEN 1 END) as LowRiskStories,
     count(CASE WHEN sb.isApiExposed = true THEN 1 END) as ApiStories,
     count(CASE WHEN sb.isCustomHeavy = true THEN 1 END) as CustomHeavyStories,
     count(DISTINCT sb.teamName) as TeamsInPhase

RETURN Phase, FirstSprint, LastSprint, 
       PhaseStartWeek, PhaseEndWeek, 
       (PhaseEndWeek - PhaseStartWeek + 1) as PhaseDurationWeeks,
       TotalStories, TotalStoryPoints, TeamsInPhase,
       HighRiskStories, MediumRiskStories, LowRiskStories,
       ApiStories, CustomHeavyStories,
       
       // Risk concentration analysis
       round(toFloat(HighRiskStories) / TotalStories * 100, 1) as HighRiskConcentration,
       round(toFloat(TotalStoryPoints) / (PhaseEndWeek - PhaseStartWeek + 1), 1) as StoryPointsPerWeek,
       
       // Phase risk level
       CASE 
           WHEN toFloat(HighRiskStories) / TotalStories > 0.4 THEN 'HIGH_RISK_PHASE'
           WHEN toFloat(HighRiskStories) / TotalStories > 0.2 THEN 'MEDIUM_RISK_PHASE'
           ELSE 'LOW_RISK_PHASE'
       END as PhaseRiskLevel

ORDER BY FirstSprint;

// VIEW 4: Application Migration Timeline
MATCH (sb:SprintBacklog)
WITH sb.appName as Application,
     min(sb.sprintNumber) as FirstSprint,
     max(sb.sprintNumber) as LastSprint,
     min(sb.startWeek) as AppStartWeek,
     max(sb.endWeek) as AppEndWeek,
     count(sb) as TotalFlows,
     sum(sb.storyPoints) as TotalStoryPoints,
     count(CASE WHEN sb.riskLevel = 'HIGH_RISK' THEN 1 END) as HighRiskFlows,
     count(CASE WHEN sb.isApiExposed = true THEN 1 END) as ApiFlows,
     count(CASE WHEN sb.isCustomHeavy = true THEN 1 END) as CustomHeavyFlows,
     collect(DISTINCT sb.teamName) as AssignedTeams

RETURN Application, FirstSprint, LastSprint,
       AppStartWeek, AppEndWeek,
       (AppEndWeek - AppStartWeek + 1) as MigrationDurationWeeks,
       TotalFlows, TotalStoryPoints, 
       HighRiskFlows, ApiFlows, CustomHeavyFlows,
       size(AssignedTeams) as TeamCount, AssignedTeams,
       
       // Migration complexity
       round(toFloat(TotalStoryPoints) / TotalFlows, 1) as AvgComplexityPerFlow,
       round(toFloat(HighRiskFlows) / TotalFlows * 100, 1) as RiskPercentage,
       
       // Migration priority (based on risk and size)
       CASE 
           WHEN HighRiskFlows > 0 AND TotalStoryPoints >= 20 THEN 'CRITICAL'
           WHEN HighRiskFlows > 0 OR TotalStoryPoints >= 30 THEN 'HIGH'
           WHEN TotalStoryPoints >= 15 THEN 'MEDIUM'
           ELSE 'LOW'
       END as MigrationPriority

ORDER BY MigrationPriority DESC, TotalStoryPoints DESC;

// VIEW 5: Weekly Workload Projection
MATCH (sb:SprintBacklog)
WITH sb.startWeek as Week,
     sb.endWeek as WeekEnd,
     count(sb) as StoriesInWeek,
     sum(sb.storyPoints) as StoryPointsInWeek,
     collect(DISTINCT sb.teamName) as TeamsWorking,
     count(CASE WHEN sb.riskLevel = 'HIGH_RISK' THEN 1 END) as HighRiskInWeek,
     count(CASE WHEN sb.isApiExposed = true THEN 1 END) as ApiWorkInWeek

// Generate week-by-week view
UNWIND range(1, 24) as WeekNumber
WITH WeekNumber,
     collect(CASE WHEN WeekNumber >= Week AND WeekNumber <= WeekEnd THEN StoriesInWeek END) as weekStories,
     collect(CASE WHEN WeekNumber >= Week AND WeekNumber <= WeekEnd THEN StoryPointsInWeek END) as weekPoints,
     collect(CASE WHEN WeekNumber >= Week AND WeekNumber <= WeekEnd THEN TeamsWorking END) as weekTeams,
     collect(CASE WHEN WeekNumber >= Week AND WeekNumber <= WeekEnd THEN HighRiskInWeek END) as weekHighRisk,
     collect(CASE WHEN WeekNumber >= Week AND WeekNumber <= WeekEnd THEN ApiWorkInWeek END) as weekApiWork

RETURN WeekNumber,
       CASE WHEN size([x IN weekStories WHERE x IS NOT NULL]) > 0 
            THEN reduce(total = 0, x IN weekStories | total + coalesce(x, 0)) 
            ELSE 0 END as TotalStories,
       CASE WHEN size([x IN weekPoints WHERE x IS NOT NULL]) > 0 
            THEN reduce(total = 0, x IN weekPoints | total + coalesce(x, 0)) 
            ELSE 0 END as TotalStoryPoints,
       CASE WHEN size([x IN weekHighRisk WHERE x IS NOT NULL]) > 0 
            THEN reduce(total = 0, x IN weekHighRisk | total + coalesce(x, 0)) 
            ELSE 0 END as HighRiskStories,
       CASE WHEN size([x IN weekApiWork WHERE x IS NOT NULL]) > 0 
            THEN reduce(total = 0, x IN weekApiWork | total + coalesce(x, 0)) 
            ELSE 0 END as ApiStories,
       
       // Project milestone markers
       CASE WeekNumber
           WHEN 6 THEN 'END_PHASE_1'
           WHEN 12 THEN 'END_PHASE_2'
           WHEN 18 THEN 'END_PHASE_3'
           WHEN 24 THEN 'PROJECT_COMPLETE'
           ELSE null
       END as Milestone

ORDER BY WeekNumber
LIMIT 24; 