// CHECK APPLICATION-AWARE PLANNING RESULTS
// Simple query to see what was created by the application-aware sprint planning

// Check if any SprintBacklog entries were created
MATCH (sb:SprintBacklog)
RETURN " SPRINT BACKLOG SUMMARY" as Section,
       toString(count(sb)) as Col1,
       toString(count(DISTINCT sb.sprintNumber)) as Col2,
       toString(count(DISTINCT sb.appName)) as Col3,
       toString(count(DISTINCT sb.teamName)) as Col4,
       toString(sum(sb.storyPoints)) as Col5,
       coalesce(collect(DISTINCT sb.assignmentMethod)[0], 'N/A') as Col6

UNION ALL

// Show sample results if they exist
MATCH (sb:SprintBacklog)
WITH sb
ORDER BY sb.sprintNumber, sb.appName, sb.flowName
LIMIT 10
RETURN " SAMPLE TASKS (Sprint|App|Flow|Points|Team|Method)" as Section,
       toString(sb.sprintNumber) as Col1,
       sb.appName as Col2,
       sb.flowName as Col3,
       toString(sb.storyPoints) as Col4,
       sb.teamName as Col5,
       coalesce(sb.assignmentMethod, 'N/A') as Col6

ORDER BY Section DESC; 