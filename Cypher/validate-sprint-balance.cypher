// VALIDATE SPRINT STORY-POINT BALANCE + TEAM BALANCE (v2)
// ---------------------------------------------------------------------
// 1. Sprint-level capacity check: each sprint’s total SP must be between
//    :minSP and :maxSP (defaults 45-65).
// 2. Team-level balance check *inside* each sprint: the most-loaded team’s
//    SP must not exceed :maxRatio times the least-loaded team’s SP
//    (defaults 1.25 = 25 % spread).
//
// Results are UNION-ed so you get two rows (one per validation type) with
// consistent columns:  Validation | Status | Details | Param1 | Param2
// ---------------------------------------------------------------------

// === QUERY A : Sprint total story-points ====================================
WITH 45 AS minSP,
     65 AS maxSP
MATCH (sb:SprintBacklog)
WITH sb.sprintNumber               AS Sprint,
     sum(coalesce(sb.storyPoints,0)) AS SprintSP,
     minSP, maxSP
ORDER BY Sprint
WITH collect({Sprint:Sprint, SP:SprintSP, Status: CASE WHEN SprintSP < minSP OR SprintSP > maxSP THEN 'OUT_OF_RANGE' ELSE 'OK' END}) AS rows,
     minSP, maxSP,
     any(x IN collect(CASE WHEN SprintSP < minSP OR SprintSP > maxSP THEN 1 END) WHERE x = 1) AS hasViolation
RETURN
    'SPRINT_TOTAL_SP'                                                   AS Validation,
    CASE WHEN hasViolation THEN 'FAIL' ELSE 'PASS' END                  AS Status,
    rows                                                                AS Details,
    minSP                                                               AS Param1,
    maxSP                                                               AS Param2

UNION

// === QUERY B : Team balance within each sprint ==============================
WITH 1.25 AS maxRatio   // heaviest team ≤ lightest team * maxRatio
MATCH (sb:SprintBacklog)
WITH sb.sprintNumber AS Sprint,
     sb.teamName     AS Team,
     sum(coalesce(sb.storyPoints,0)) AS TeamSP,
     maxRatio
WITH Sprint,
     collect({Team:Team, SP:TeamSP}) AS teamRowsRaw,
     maxRatio
// Filter out zero-SP teams to avoid division by zero / skewed ratio
WITH Sprint,
     [t IN teamRowsRaw WHERE t.SP > 0] AS teamRows,
     maxRatio
UNWIND teamRows AS t
WITH Sprint,
     teamRows,
     maxRatio,
     max(t.SP)   AS heavy,
     min(t.SP)   AS light
RETURN
    'SPRINT_TEAM_RATIO'                                                 AS Validation,
    CASE WHEN heavy > light * maxRatio THEN 'FAIL' ELSE 'PASS' END      AS Status,
    {Sprint:Sprint, Teams: teamRows}                                     AS Details,
    maxRatio                                                            AS Param1,
    null;                                                                AS Param2; 


