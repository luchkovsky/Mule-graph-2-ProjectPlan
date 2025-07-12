// EXPORT TO MS PROJECT XML (TEAM-SEQUENCED, DYNAMIC TEAMS)
// ------------------------------------------------------------
// This supersedes the previous generic exporter. Within each sprint,
// tasks are ordered by team precedence derived from AgileTeam.skillLevel
// (EXPERT → SENIOR → others) so the Gantt view groups work by team.
// Task <Name>:  "<Team> | <App>::<Flow> (X SP)".
// ------------------------------------------------------------

// 0. Build dynamic team precedence list
CALL {
  MATCH (t:AgileTeam)
  WITH CASE t.skillLevel WHEN 'EXPERT' THEN 1 WHEN 'SENIOR' THEN 2 ELSE 3 END AS lvl,
       t.teamName AS name
  ORDER BY lvl
  RETURN collect(name) AS teamOrder
}
WITH teamOrder

// 1. XML HEADER & ROOT
WITH teamOrder,
     '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\n' +
     '<Project xmlns="http://schemas.microsoft.com/project">\n' +
     '  <Name>Mule Flow Complexity Analysis – Team-Sequenced Plan</Name>\n' +
     '  <Title>Mule Flow Complexity Analysis – Team-Sequenced Plan</Title>\n' +
     '  <Subject>Sprint backlog grouped by team</Subject>\n' +
     '  <Manager>Migration PM</Manager>\n' +
     '  <Company>Your Org</Company>\n' +
     '  <StartDate>2024-01-01T08:00:00</StartDate>\n' +
     '  <CurrencyCode>USD</CurrencyCode>\n' +
     '  <Calendars>\n' +
     '    <Calendar><UID>1</UID><Name>Standard</Name><IsBaseCalendar>1</IsBaseCalendar></Calendar>\n' +
     '  </Calendars>\n' +
     '  <Tasks>\n' AS xmlHeader

WITH teamOrder, xmlHeader +
     '    <Task><UID>1</UID><ID>0</ID><Name>Mule Flow Complexity Analysis</Name><Summary>1</Summary></Task>\n' AS xmlRoot

// 2. Collect backlog & enrich with UID / team precedence
MATCH (sb:SprintBacklog)
WITH teamOrder, xmlRoot, collect(sb) AS backlog
WITH teamOrder, xmlRoot,
     [i IN range(0, size(backlog)-1) | {
        sb: backlog[i],
        uid: i + 50,
        taskId: i + 50,
        teamPos: apoc.coll.indexOf(teamOrder, backlog[i].teamName)
     }] AS tasks

// 3. Build XML – sprint → team → flow
WITH teamOrder, xmlRoot,
     reduce(allXML = '', sprintNum IN range(1,12) |
         allXML +
         '    <Task><UID>' + toString(10 + sprintNum) + '</UID><ID>' + toString(10 + sprintNum) + '</ID>' +
         '<Name>Sprint ' + toString(sprintNum) + '</Name><Summary>1</Summary></Task>\n' +
         reduce(teamXML = '', idx IN range(0, size(teamOrder)-1) |
             teamXML +
             reduce(flowXML = '', t IN [x IN tasks WHERE x.sb.sprintNumber = sprintNum AND apoc.coll.indexOf(teamOrder, x.sb.teamName) = idx] |
                 flowXML +
                 '    <Task>\n' +
                 '      <UID>' + toString(t.uid) + '</UID>\n' +
                 '      <ID>'  + toString(t.taskId) + '</ID>\n' +
                 '      <Name>' + coalesce(t.sb.teamName,'Team') + ' | ' + coalesce(t.sb.appName,'App') + '::' + coalesce(t.sb.flowName,'Flow') + ' (' + toString(coalesce(t.sb.storyPoints,5)) + ' SP)</Name>\n' +
                 '      <Summary>0</Summary>\n' +
                 '      <OutlineLevel>2</OutlineLevel>\n' +
                 '      <Work>PT' + toString(coalesce(t.sb.storyPoints,5)*8) + 'H0M0S</Work>\n' +
                 '      <Duration>PT' + toString(coalesce(t.sb.storyPoints,5)*8) + 'H0M0S</Duration>\n' +
                 '      <Notes>' + coalesce(t.sb.description,'') + '\nStory Points: ' + toString(coalesce(t.sb.storyPoints,5)) + '\nTeam: ' + coalesce(t.sb.teamName,'') + '\nApplication: ' + coalesce(t.sb.appName,'') + '\nFlow: ' + coalesce(t.sb.flowName,'') + '</Notes>\n' +
                 '    </Task>\n'
             )
         )
     ) AS bodyXML

// 4. Final return
WITH xmlRoot + bodyXML + '  </Tasks>\n</Project>\n' AS completeXML
RETURN 'MS-Project XML generated (team-sequenced)' AS Status,
       'Copy below XML into a .xml file and open with MS Project' AS Instructions,
       completeXML AS MicrosoftProjectXML; 