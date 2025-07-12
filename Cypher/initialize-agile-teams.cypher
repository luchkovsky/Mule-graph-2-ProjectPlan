// INITIALIZE PROJECT-PLANNING CONFIGURATION AND CANONICAL AGILE TEAMS
// -------------------------------------------------------------------
// Run once after loading flows, before any assignment or rebalancing.
// 1) Creates / reuses a single PlanningConfig node containing global
//    project-level parameters (update here if you change sprint cadence).
// 2) Creates exactly three canonical AgileTeam nodes with detailed
//    capacity and specialization metadata used by all planning scripts.
// -------------------------------------------------------------------

// -------------------------------------------------------------------
// SECTION 1 – PLANNING CONFIGURATION (edit values as needed)
// -------------------------------------------------------------------
MERGE (cfg:PlanningConfig {id: 'DEFAULT'})
SET cfg.projectName          = 'Mule Flow Complexity Analysis',
    cfg.totalSprints         = 12,          // Number of planned sprints
    cfg.sprintLengthWeeks    = 2,           // Sprint duration (weeks)
    cfg.projectDurationWeeks = cfg.totalSprints * cfg.sprintLengthWeeks,
    cfg.storyPointsPerDay    = 4,           // Assumed velocity reference
    cfg.initializedAt        = datetime();

// -------------------------------------------------------------------
// SECTION 2 – AGILE TEAM INITIALIZATION
// -------------------------------------------------------------------
UNWIND [
  {
    name:               'Expert Team',
    skillLevel:         'EXPERT',
    teamSize:           3,
    sprintVelocity:     15,               // Story points per sprint
    riskTolerance:      'HIGH',
    complexityRange:    '8-21'
  },
  {
    name:               'Senior Team',
    skillLevel:         'SENIOR',
    teamSize:           4,
    sprintVelocity:     20,
    riskTolerance:      'MEDIUM',
    complexityRange:    '5-13'
  },
  {
    name:               'Standard Team',
    skillLevel:         'STANDARD',
    teamSize:           5,
    sprintVelocity:     25,
    riskTolerance:      'LOW',
    complexityRange:    '1-8'
  }
] AS teamDef

MERGE (t:AgileTeam {teamName: teamDef.name})
SET t.skillLevel             = teamDef.skillLevel,
    t.teamSize               = teamDef.teamSize,
    t.sprintVelocity         = teamDef.sprintVelocity,
    t.riskTolerance          = teamDef.riskTolerance,
    t.complexityRange        = teamDef.complexityRange,
    t.initializedAt          = datetime(); 