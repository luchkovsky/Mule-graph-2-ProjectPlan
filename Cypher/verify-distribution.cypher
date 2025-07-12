// VERIFY SPRINT DISTRIBUTION - UNIFIED RESULTS
// Shows current sprint distribution, summary, and sample data in one query using UNION

// Part 1: Sprint Distribution
MATCH (sb:SprintBacklog)
WITH sb.sprintNumber as Sprint,
     count(sb) as TaskCount,
     sum(sb.storyPoints) as TotalStoryPoints,
     collect(sb.appName + '::' + sb.flowName)[0..3] as SampleTasks
RETURN 
    'SPRINT_DISTRIBUTION' as Section,
    'Sprint ' + toString(Sprint) as Label,
    toString(TaskCount) as TaskCount,
    toString(TotalStoryPoints) as StoryPoints,
    reduce(s = '', task IN SampleTasks | s + CASE WHEN s = '' THEN task ELSE ', ' + task END) as Details
ORDER BY Sprint

UNION ALL

// Part 2: Overall Summary
MATCH (sb:SprintBacklog)
RETURN 
    'SUMMARY' as Section,
    ' TOTAL SUMMARY' as Label,
    toString(count(sb)) as TaskCount,
    toString(sum(sb.storyPoints)) as StoryPoints,
    toString(count(DISTINCT sb.sprintNumber)) + ' sprints, ' + 
    toString(count(DISTINCT sb.appName)) + ' apps, ' + 
    toString(count(DISTINCT sb.teamName)) + ' teams' as Details

UNION ALL

// Part 3: Sample Real Data (first 10 tasks)
MATCH (sb:SprintBacklog)
WITH sb
ORDER BY sb.sprintNumber, sb.appName, sb.flowName
LIMIT 10
RETURN 
    'SAMPLE_DATA' as Section,
    sb.appName + '::' + sb.flowName as Label,
    toString(sb.storyPoints) as TaskCount,
    sb.riskLevel + '/' + sb.complexityLevel as StoryPoints,
    'Sprint ' + toString(sb.sprintNumber) + ', Team: ' + sb.teamName as Details

ORDER BY 
    CASE Section 
        WHEN 'SUMMARY' THEN 1 
        WHEN 'SPRINT_DISTRIBUTION' THEN 2 
        WHEN 'SAMPLE_DATA' THEN 3 
    END,
    Label; 