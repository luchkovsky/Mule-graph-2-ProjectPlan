// STEP 6: EXPORT TO EXCEL/CSV
// Generates CSV files for Excel/OpenOffice project management

// Team precedence (used for ordered output)
WITH ['Expert Team','Senior Team','Standard Team'] AS teamOrder

// EXPORT 1: Complete Sprint Timeline
MATCH (sb:SprintBacklog)
WITH sb, teamOrder
WITH sb.sprintNumber as Sprint,
     sb.projectPhase as Phase,
     sb.startWeek as StartWeek,
     sb.endWeek as EndWeek,
     sb.teamName as Team,
     sb.appName as Application,
     sb.flowName as Flow,
     sb.uniqueId as UniqueId,
     sb.storyPoints as StoryPoints,
     sb.riskLevel as RiskLevel,
     sb.priority as Priority,
     sb.category as Category,
     sb.isApiExposed as IsAPI,
     sb.isCustomHeavy as IsCustomHeavy,
     sb.connectorCount as ConnectorCount,
     sb.dwScriptCount as DwScriptCount,
     sb.complexityLevel as ComplexityLevel,
     sb.sprintGoal as SprintGoal,
     apoc.coll.indexOf(teamOrder, sb.teamName) AS teamPos

RETURN Sprint, Phase, StartWeek, EndWeek, Team, Application, Flow, UniqueId,
       StoryPoints, RiskLevel, Priority, Category, IsAPI, IsCustomHeavy,
       ConnectorCount, DwScriptCount, ComplexityLevel, SprintGoal,
       
       // Additional calculated fields for Excel
       CASE RiskLevel
           WHEN 'HIGH_RISK' THEN ' HIGH'
           WHEN 'MEDIUM_RISK' THEN ' MEDIUM'
           WHEN 'LOW_RISK' THEN ' LOW'
           ELSE ' MINIMAL'
       END as RiskIndicator,
       
       CASE ComplexityLevel
           WHEN 'HIGH' THEN ' HIGH'
           WHEN 'MEDIUM_HIGH' THEN ' MEDIUM-HIGH'
           WHEN 'MEDIUM' THEN ' MEDIUM'
           WHEN 'LOW' THEN ' LOW'
           ELSE ' MINIMAL'
       END as ComplexityIndicator,
       
       CASE WHEN IsAPI = true THEN ' API' ELSE '' END as APIIndicator,
       CASE WHEN IsCustomHeavy = true THEN ' CUSTOM' ELSE '' END as CustomIndicator,
       
       // Sprint dates (assuming project starts on Monday of week 1)
       'Week ' + toString(StartWeek) + ' - Week ' + toString(EndWeek) as SprintDuration,
       
       // Team workload indicator
       CASE Team
           WHEN 'Expert Team' THEN ' Expert'
           WHEN 'Senior Team' THEN ' Senior'
           ELSE ' Standard'
       END as TeamLevel

ORDER BY Sprint, teamPos, Priority, StoryPoints DESC;

// EXPORT 2: Team Workload Summary
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
     count(CASE WHEN sb.isApiExposed = true THEN 1 END) as ApiStories,
     count(CASE WHEN sb.isCustomHeavy = true THEN 1 END) as CustomHeavyStories,
     collect(DISTINCT sb.sprintNumber) as SprintNumbers

RETURN Team, TotalStories, TotalStoryPoints, SprintsWorked,
       HighRiskStories, MediumRiskStories, LowRiskStories,
       AvgStoryPoints, MinStoryPoints, MaxStoryPoints,
       ApiStories, CustomHeavyStories,
       
       // Calculated fields for Excel
       round(toFloat(TotalStoryPoints) / SprintsWorked, 1) as AvgStoryPointsPerSprint,
       round(toFloat(HighRiskStories) / TotalStories * 100, 1) as HighRiskPercentage,
       round(toFloat(MediumRiskStories) / TotalStories * 100, 1) as MediumRiskPercentage,
       round(toFloat(LowRiskStories) / TotalStories * 100, 1) as LowRiskPercentage,
       
       // Workload assessment
       CASE 
           WHEN TotalStoryPoints >= 150 THEN ' HIGH WORKLOAD'
           WHEN TotalStoryPoints >= 100 THEN ' MEDIUM WORKLOAD'
           ELSE ' MANAGEABLE WORKLOAD'
       END as WorkloadAssessment,
       
       // Risk profile
       CASE 
           WHEN toFloat(HighRiskStories) / TotalStories > 0.3 THEN ' HIGH RISK TEAM'
           WHEN toFloat(HighRiskStories) / TotalStories > 0.1 THEN ' MEDIUM RISK TEAM'
           ELSE ' LOW RISK TEAM'
       END as RiskProfile,
       
       // Sprint spread
       size(SprintNumbers) as SprintsActive,
       toString(SprintNumbers[0]) + ' - ' + toString(SprintNumbers[-1]) as SprintRange

ORDER BY CASE Team 
    WHEN 'Expert Team' THEN 1 
    WHEN 'Senior Team' THEN 2 
    ELSE 3 
END;

// EXPORT 3: Application Migration Schedule
MATCH (sb:SprintBacklog)
WITH sb.appName as Application,
     min(sb.sprintNumber) as FirstSprint,
     max(sb.sprintNumber) as LastSprint,
     min(sb.startWeek) as AppStartWeek,
     max(sb.endWeek) as AppEndWeek,
     count(sb) as TotalFlows,
     sum(sb.storyPoints) as TotalStoryPoints,
     count(CASE WHEN sb.riskLevel = 'HIGH_RISK' THEN 1 END) as HighRiskFlows,
     count(CASE WHEN sb.riskLevel = 'MEDIUM_RISK' THEN 1 END) as MediumRiskFlows,
     count(CASE WHEN sb.riskLevel = 'LOW_RISK' THEN 1 END) as LowRiskFlows,
     count(CASE WHEN sb.isApiExposed = true THEN 1 END) as ApiFlows,
     count(CASE WHEN sb.isCustomHeavy = true THEN 1 END) as CustomHeavyFlows,
     collect(DISTINCT sb.teamName) as AssignedTeams,
     collect(DISTINCT sb.projectPhase) as ProjectPhases

RETURN Application, FirstSprint, LastSprint,
       AppStartWeek, AppEndWeek,
       (AppEndWeek - AppStartWeek + 1) as MigrationDurationWeeks,
       TotalFlows, TotalStoryPoints, 
       HighRiskFlows, MediumRiskFlows, LowRiskFlows,
       ApiFlows, CustomHeavyFlows,
       size(AssignedTeams) as TeamCount, AssignedTeams,
       
       // Migration timeline
       'Week ' + toString(AppStartWeek) + ' - Week ' + toString(AppEndWeek) as MigrationTimeline,
       'Sprint ' + toString(FirstSprint) + ' - Sprint ' + toString(LastSprint) as SprintRange,
       
       // Migration complexity indicators
       round(toFloat(TotalStoryPoints) / TotalFlows, 1) as AvgComplexityPerFlow,
       round(toFloat(HighRiskFlows) / TotalFlows * 100, 1) as RiskPercentage,
       
       // Migration priority and indicators
       CASE 
           WHEN HighRiskFlows > 0 AND TotalStoryPoints >= 20 THEN ' CRITICAL'
           WHEN HighRiskFlows > 0 OR TotalStoryPoints >= 30 THEN ' HIGH'
           WHEN TotalStoryPoints >= 15 THEN ' MEDIUM'
           ELSE ' LOW'
       END as MigrationPriority,
       
       CASE WHEN ApiFlows > 0 THEN ' HAS APIs' ELSE '' END as APIIndicator,
       CASE WHEN CustomHeavyFlows > 0 THEN ' CUSTOM CODE' ELSE '' END as CustomIndicator,
       
       // Project phases
       CASE 
           WHEN size(ProjectPhases) > 1 THEN ' MULTI-PHASE'
           ELSE ProjectPhases[0]
       END as PhaseInfo

ORDER BY CASE 
    WHEN HighRiskFlows > 0 AND TotalStoryPoints >= 20 THEN 1
    WHEN HighRiskFlows > 0 OR TotalStoryPoints >= 30 THEN 2
    WHEN TotalStoryPoints >= 15 THEN 3
    ELSE 4
END, TotalStoryPoints DESC;

// EXPORT 4: Weekly Project Timeline
MATCH (sb:SprintBacklog)
WITH sb.startWeek as Week,
     sb.endWeek as WeekEnd,
     count(sb) as StoriesInWeek,
     sum(sb.storyPoints) as StoryPointsInWeek,
     collect(DISTINCT sb.teamName) as TeamsWorking,
     count(CASE WHEN sb.riskLevel = 'HIGH_RISK' THEN 1 END) as HighRiskInWeek,
     count(CASE WHEN sb.riskLevel = 'MEDIUM_RISK' THEN 1 END) as MediumRiskInWeek,
     count(CASE WHEN sb.riskLevel = 'LOW_RISK' THEN 1 END) as LowRiskInWeek,
     count(CASE WHEN sb.isApiExposed = true THEN 1 END) as ApiWorkInWeek,
     count(CASE WHEN sb.isCustomHeavy = true THEN 1 END) as CustomWorkInWeek,
     collect(DISTINCT sb.sprintNumber) as SprintsInWeek,
     collect(DISTINCT sb.projectPhase) as PhasesInWeek

// Generate comprehensive weekly view
UNWIND range(1, 24) as WeekNumber
WITH WeekNumber,
     collect(CASE WHEN WeekNumber >= Week AND WeekNumber <= WeekEnd THEN StoriesInWeek END) as weekStories,
     collect(CASE WHEN WeekNumber >= Week AND WeekNumber <= WeekEnd THEN StoryPointsInWeek END) as weekPoints,
     collect(CASE WHEN WeekNumber >= Week AND WeekNumber <= WeekEnd THEN TeamsWorking END) as weekTeams,
     collect(CASE WHEN WeekNumber >= Week AND WeekNumber <= WeekEnd THEN HighRiskInWeek END) as weekHighRisk,
     collect(CASE WHEN WeekNumber >= Week AND WeekNumber <= WeekEnd THEN MediumRiskInWeek END) as weekMediumRisk,
     collect(CASE WHEN WeekNumber >= Week AND WeekNumber <= WeekEnd THEN LowRiskInWeek END) as weekLowRisk,
     collect(CASE WHEN WeekNumber >= Week AND WeekNumber <= WeekEnd THEN ApiWorkInWeek END) as weekApiWork,
     collect(CASE WHEN WeekNumber >= Week AND WeekNumber <= WeekEnd THEN CustomWorkInWeek END) as weekCustomWork,
     collect(CASE WHEN WeekNumber >= Week AND WeekNumber <= WeekEnd THEN SprintsInWeek END) as weekSprints,
     collect(CASE WHEN WeekNumber >= Week AND WeekNumber <= WeekEnd THEN PhasesInWeek END) as weekPhases

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
       CASE WHEN size([x IN weekMediumRisk WHERE x IS NOT NULL]) > 0 
            THEN reduce(total = 0, x IN weekMediumRisk | total + coalesce(x, 0)) 
            ELSE 0 END as MediumRiskStories,
       CASE WHEN size([x IN weekLowRisk WHERE x IS NOT NULL]) > 0 
            THEN reduce(total = 0, x IN weekLowRisk | total + coalesce(x, 0)) 
            ELSE 0 END as LowRiskStories,
       CASE WHEN size([x IN weekApiWork WHERE x IS NOT NULL]) > 0 
            THEN reduce(total = 0, x IN weekApiWork | total + coalesce(x, 0)) 
            ELSE 0 END as ApiStories,
       CASE WHEN size([x IN weekCustomWork WHERE x IS NOT NULL]) > 0 
            THEN reduce(total = 0, x IN weekCustomWork | total + coalesce(x, 0)) 
            ELSE 0 END as CustomStories,
            
       // Project milestone markers
       CASE WeekNumber
           WHEN 6 THEN ' END PHASE 1'
           WHEN 12 THEN ' END PHASE 2'
           WHEN 18 THEN ' END PHASE 3'
           WHEN 24 THEN ' PROJECT COMPLETE'
           ELSE null
       END as Milestone,
       
       // Workload indicator
       CASE 
           WHEN (CASE WHEN size([x IN weekPoints WHERE x IS NOT NULL]) > 0 
                      THEN reduce(total = 0, x IN weekPoints | total + coalesce(x, 0)) 
                      ELSE 0 END) >= 50 THEN ' HIGH WORKLOAD'
           WHEN (CASE WHEN size([x IN weekPoints WHERE x IS NOT NULL]) > 0 
                      THEN reduce(total = 0, x IN weekPoints | total + coalesce(x, 0)) 
                      ELSE 0 END) >= 25 THEN ' MEDIUM WORKLOAD'
           WHEN (CASE WHEN size([x IN weekPoints WHERE x IS NOT NULL]) > 0 
                      THEN reduce(total = 0, x IN weekPoints | total + coalesce(x, 0)) 
                      ELSE 0 END) > 0 THEN ' ACTIVE WORK'
           ELSE ' NO WORK'
       END as WorkloadLevel,
       
       // Risk indicator
       CASE 
           WHEN (CASE WHEN size([x IN weekHighRisk WHERE x IS NOT NULL]) > 0 
                      THEN reduce(total = 0, x IN weekHighRisk | total + coalesce(x, 0)) 
                      ELSE 0 END) > 0 THEN ' HIGH RISK WEEK'
           WHEN (CASE WHEN size([x IN weekMediumRisk WHERE x IS NOT NULL]) > 0 
                      THEN reduce(total = 0, x IN weekMediumRisk | total + coalesce(x, 0)) 
                      ELSE 0 END) > 0 THEN ' MEDIUM RISK WEEK'
           WHEN (CASE WHEN size([x IN weekLowRisk WHERE x IS NOT NULL]) > 0 
                      THEN reduce(total = 0, x IN weekLowRisk | total + coalesce(x, 0)) 
                      ELSE 0 END) > 0 THEN ' LOW RISK WEEK'
           ELSE ' NO RISK'
       END as RiskLevel

ORDER BY WeekNumber
LIMIT 24; 