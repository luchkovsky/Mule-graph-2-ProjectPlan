// NUCLEAR CLEANUP v2 – lean version
// -----------------------------------------------------------
// Instead of wiping every assignment and team, we now remove
// ONLY the artefacts created by planning / reporting scripts.
// Those artefacts are consistently tagged with type = 'planning'.
// -----------------------------------------------------------

// 1. Delete any node (Sprint, SprintBacklog, etc.) flagged as planning
MATCH (n)
WHERE n.type = 'planning'
DETACH DELETE n;

// 2. Remove transient relationships that may have type flag on rels
MATCH ()-[r]->()
WHERE r.type = 'planning'
DELETE r;

// 3. Summary – how many artefacts remain?
RETURN ' Planning artefacts removed. Database ready for fresh planning run.' AS Status,
       coalesce(size([()-->(sb:SprintBacklog) | sb]),0) AS RemainingBacklogRows; 