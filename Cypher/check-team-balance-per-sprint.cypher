// TEAM BALANCE VALIDATION PER SPRINT
// Check if all teams have work assigned in each sprint

// =============================================================================
// DETAILED TEAM DISTRIBUTION PER SPRINT  (dynamic teams)
// =============================================================================

// build team list
CALL {
  MATCH (t:AgileTeam)
  RETURN collect(t.teamName) AS teams
}
WITH teams
CALL apoc.util.validate(size(teams)=0,'ERROR: No AgileTeam nodes found. Team configuration required.',[])

MATCH (sb:SprintBacklog)
WITH teams, sb.sprintNumber AS sprintNumber, collect(sb) AS sprintTasks,
     size(collect(sb)) AS totalTasks,
     sum(sb.storyPoints) AS totalStoryPoints
WITH teams, sprintNumber, totalTasks, totalStoryPoints,
     [team IN teams | {name: team,
                       tasks: size([t IN sprintTasks WHERE t.teamName = team]),
                       sp:    reduce(val=0, x IN [t IN sprintTasks WHERE t.teamName = team] | val + x.storyPoints)}] AS stats
ORDER BY sprintNumber

RETURN 'TEAM DISTRIBUTION PER SPRINT' AS Section,
       'Sprint ' + toString(sprintNumber) AS Sprint,
       toString(totalTasks) + ' tasks, ' + toString(totalStoryPoints) + ' SP' AS Total,
       apoc.convert.toJson(stats) AS TeamBreakdown,
       CASE WHEN all(x IN stats WHERE x.tasks > 0) THEN 'ALL_TEAMS_ACTIVE'
            ELSE 'MISSING_TEAMS' END AS Status

UNION ALL

// =============================================================================
// TEAM BALANCE SUMMARY
// =============================================================================

MATCH (sb:SprintBacklog)
WITH collect(DISTINCT sb.sprintNumber) as allSprints

UNWIND allSprints as sprintNum
MATCH (sb:SprintBacklog {sprintNumber: sprintNum})
WITH sprintNum,
     size([task IN collect(sb) WHERE task.teamName = 'Expert Team']) as expertTasks,
     size([task IN collect(sb) WHERE task.teamName = 'Senior Team']) as seniorTasks,
     size([task IN collect(sb) WHERE task.teamName = 'Standard Team']) as standardTasks

WITH collect({
    sprint: sprintNum,
    hasExpert: expertTasks > 0,
    hasSenior: seniorTasks > 0,
    hasStandard: standardTasks > 0,
    teamCount: (CASE WHEN expertTasks > 0 THEN 1 ELSE 0 END) + 
               (CASE WHEN seniorTasks > 0 THEN 1 ELSE 0 END) + 
               (CASE WHEN standardTasks > 0 THEN 1 ELSE 0 END)
}) as sprintAnalysis

WITH sprintAnalysis,
     size([s IN sprintAnalysis WHERE s.teamCount = 3]) as sprintsWithAllTeams,
     size([s IN sprintAnalysis WHERE s.teamCount = 2]) as sprintsWithTwoTeams,
     size([s IN sprintAnalysis WHERE s.teamCount = 1]) as sprintsWithOneTeam,
     size([s IN sprintAnalysis WHERE s.teamCount = 0]) as sprintsWithNoTeams,
     size(sprintAnalysis) as totalSprints

RETURN 
    ' TEAM BALANCE SUMMARY' as Section,
    toString(totalSprints) + ' total sprints' as Sprint,
    toString(sprintsWithAllTeams) + ' sprints have all 3 teams' as Total,
    toString(sprintsWithTwoTeams) + ' sprints have 2 teams' as Expert,
    toString(sprintsWithOneTeam) + ' sprints have 1 team only' as Senior,
    toString(sprintsWithNoTeams) + ' sprints have no teams' as Standard,
    CASE 
        WHEN sprintsWithAllTeams = totalSprints THEN ' PERFECT_BALANCE'
        WHEN sprintsWithAllTeams >= (totalSprints * 0.7) THEN ' GOOD_BALANCE'
        WHEN sprintsWithOneTeam > (totalSprints * 0.3) THEN ' POOR_BALANCE'
        ELSE ' NEEDS_IMPROVEMENT'
    END as Status

UNION ALL

// =============================================================================
// PROBLEM IDENTIFICATION
// =============================================================================

MATCH (sb:SprintBacklog)
WITH sb.sprintNumber as sprintNumber,
     size([task IN collect(sb) WHERE task.teamName = 'Expert Team']) as expertTasks,
     size([task IN collect(sb) WHERE task.teamName = 'Senior Team']) as seniorTasks,
     size([task IN collect(sb) WHERE task.teamName = 'Standard Team']) as standardTasks

WHERE expertTasks = 0 OR seniorTasks = 0 OR standardTasks = 0

RETURN 
    ' SPRINTS WITH MISSING TEAMS' as Section,
    'Sprint ' + toString(sprintNumber) as Sprint,
    CASE WHEN expertTasks = 0 THEN ' NO EXPERT' ELSE ' Has Expert' END as Total,
    CASE WHEN seniorTasks = 0 THEN ' NO SENIOR' ELSE ' Has Senior' END as Expert,  
    CASE WHEN standardTasks = 0 THEN ' NO STANDARD' ELSE ' Has Standard' END as Senior,
    toString(expertTasks + seniorTasks + standardTasks) + ' total tasks' as Standard,
    ' MISSING_TEAMS' as Status

UNION ALL

// =============================================================================
// TEAM WORKLOAD DISTRIBUTION
// =============================================================================

MATCH (sb:SprintBacklog)
WITH sb.teamName as teamName,
     count(sb) as totalTasks,
     sum(sb.storyPoints) as totalStoryPoints,
     collect(DISTINCT sb.sprintNumber) as sprintsWorking,
     count(DISTINCT sb.appName) as appsWorking

ORDER BY totalStoryPoints DESC

RETURN 
    '💼 OVERALL TEAM WORKLOAD' as Section,
    teamName as Sprint,
    toString(totalTasks) + ' tasks' as Total,
    toString(totalStoryPoints) + ' story points' as Expert,
    toString(size(sprintsWorking)) + ' sprints active' as Senior,
    toString(appsWorking) + ' applications' as Standard,
    CASE 
        WHEN size(sprintsWorking) >= 10 THEN ' WELL_DISTRIBUTED'
        WHEN size(sprintsWorking) >= 7 THEN ' MODERATELY_DISTRIBUTED'
        ELSE ' POORLY_DISTRIBUTED'
    END as Status

ORDER BY Section DESC; 