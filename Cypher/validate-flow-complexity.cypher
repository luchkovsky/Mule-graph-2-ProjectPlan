// ==============================================================
// VALIDATE FLOW COMPLEXITY – SUMMARY TABLE (with Connector details)
// ==============================================================
// This read-only query lists every Flow that already has story-point
// properties set by story-points-complexity-analysis.cypher.
// It returns one row per flow with the full set of calculated
// complexity and story-point fields for easy validation / export.
// ==============================================================

MATCH (app:MuleApp)-[:HAS_FLOW]->(flow:Flow)
WHERE flow.finalStoryPoints IS NOT NULL   // only flows that have been analysed

// Bring in connector nodes attached to the same application
OPTIONAL MATCH (app)-[:HAS_CONNECTOR]->(con:Connector)

// Detect DB-related steps for this flow (category='Database' or type prefix 'db:')
OPTIONAL MATCH (flow)-[:HAS_STEP*]->(dbStep:Step)
WHERE dbStep.category = 'connector'
  AND (
        dbStep.properties CONTAINS 'select'
     OR dbStep.properties CONTAINS 'insert'
     OR dbStep.properties CONTAINS 'update'
      )
OPTIONAL MATCH (dbStep)-[:REFS_ON]->(cfg:Configuration)

// Detect batch processing steps
OPTIONAL MATCH (flow)-[:HAS_STEP*]->(batchStep:Step)
WHERE batchStep.type = 'batch:job' OR batchStep.category = 'batch'

// Detect connector-type steps inside the flow
OPTIONAL MATCH (flow)-[:HAS_STEP*]->(stepConn:Step)
WHERE stepConn.category = 'connector'

WITH app, flow,
     // Collect connector names and their full property maps (only when present)
     collect(DISTINCT con)       AS connectorNodes,
     collect(DISTINCT dbStep)    AS dbNodes,
     collect(DISTINCT cfg)       AS configNodes,
     collect(DISTINCT batchStep) AS batchNodes,
     collect(DISTINCT stepConn)  AS stepConnNodes

WITH app, flow,
     [c IN connectorNodes | c.name]          AS connectorNames,
     [c IN connectorNodes | c.properties]    AS connectorProperties,
     // DB connector/source names & operations
     [d IN dbNodes | coalesce(d.connectorName, d.name, d.type)]      AS dbConnectors,
     [d IN dbNodes | coalesce(d.properties)]                         AS dbConnectorsDetails,
     [c IN configNodes | coalesce(c.configName, c.name)]             AS dbConnectorsConfig,
     [d IN dbNodes |
        (
          // Derive SQL verb via regex match
          CASE
            WHEN d.properties =~ '(?is).*\\bselect\\b.*' THEN 'SELECT'
            WHEN d.properties =~ '(?is).*\\binsert\\b.*' THEN 'INSERT'
            WHEN d.properties =~ '(?is).*\\bupdate\\b.*' THEN 'UPDATE'
            WHEN d.properties =~ '(?is).*\\bdelete\\b.*' THEN 'DELETE'
            ELSE 'OTHER'
          END
        )
     ]                                            AS dbOperations,
     // Batch & step-level connector info
     (size(batchNodes) > 0)                           AS hasBatch,
     [s IN stepConnNodes | s.type + ':' + s.name]     AS stepConnectorNames,
     size(stepConnNodes)                              AS stepConnectorCount,
     [d IN dbNodes |
        coalesce(
            // Try to fetch JSON value whose key starts with the SQL verb
            head([
                k IN keys(apoc.convert.fromJsonMap(apoc.text.replace(d.properties, '"', '\\"')))
                WHERE toLower(k) STARTS WITH 
                    CASE
                        WHEN d.properties =~ '(?is).*\\bselect\\b.*' THEN 'db:select'
                        WHEN d.properties =~ '(?is).*\\binsert\\b.*' THEN 'db:insert'
                        WHEN d.properties =~ '(?is).*\\bupdate\\b.*' THEN 'db:update'
                        WHEN d.properties =~ '(?is).*\\bdelete\\b.*' THEN 'db:delete'
                        ELSE ''
                    END
                | apoc.convert.fromJsonMap(d.properties)[k]
            ]),
            // Final fallback: raw properties string
            d.properties
        )
    ]                                            AS dbQueriesRaw

RETURN
    app.name                           AS Application,
    flow.flow                          AS FlowName,
    // Complexity scores
    //round(flow.baseComplexityScore,1)      AS BaseComplexityScore,
    //round(flow.enhancedComplexityScore,1)  AS EnhancedComplexityScore,
    // Story point breakdown
    //flow.baseStoryPoints                AS BaseStoryPoints,
    //flow.apiStoryPoints                 AS ApiStoryPoints,
    //flow.dwStoryPoints                  AS DataWeaveStoryPoints,
    //flow.rawStoryPoints                 AS RawStoryPoints,
    //flow.finalStoryPoints               AS FinalStoryPoints,
    //flow.storyPointCategory             AS StoryPointCategory,
    // Component metrics (saved as properties by previous script)
    flow.nestedStepCount                AS NestedSteps,
    flow.uniqueStepTypes                AS UniqueStepTypes,
    flow.uniqueStepCategories           AS UniqueStepCategories,
    // DataWeave metrics
    flow.dwScriptCount                  AS DataWeaveScripts,
    flow.avgDwDepth                     AS AvgDataWeaveDepth,
    flow.maxDwDepth                     AS MaxDataWeaveDepth,
    flow.totalDwLambdas                 AS TotalDataWeaveLambdas,
    // Integration metrics
    flow.connectorCount                 AS Connectors,
    flow.asyncIndicatorCount            AS AsyncIndicators,
    flow.isAsyncFlow                    AS IsAsyncFlow,
    CASE WHEN flow.isAsyncFlow THEN 'ASYNC' ELSE 'SYNC' END AS SyncAsync,
    hasBatch                           AS HasBatch,
    stepConnectorCount                 AS StepConnectorCount,
    stepConnectorNames                 AS StepConnectorNames,
    dbConnectors                       AS DbConnectors,
    dbQueriesRaw                       AS DbQueries,
    dbConnectorsDetails                AS DbConnectorsDetails,
    dbConnectorsConfig                 AS dbConnectorsConfig,
    dbOperations                       AS DbOperations, // SQL ops (SELECT/UPDATE/...)
    // Detailed connector metadata (if any)
    CASE WHEN flow.connectorCount > 0 THEN connectorNames ELSE [] END       AS ConnectorNames,
    CASE WHEN flow.connectorCount > 0 THEN connectorProperties ELSE [] END  AS ConnectorProperties,
    flow.errorHandlerCount              AS ErrorHandlers,
    // API metrics
    flow.isApiExposed                   AS IsApiExposed,
    flow.apiComplexityCategory          AS ApiComplexityCategory,
    flow.apiKitRouteCount               AS ApiKitRoutes,
    flow.apiKitCount                    AS ApiKits,
    // Risk indicators
    // flow.riskFlags                      AS RiskFlags,
    //CASE 
      //  WHEN flow.riskFlags >= 3 THEN 'HIGH_RISK'
      //  WHEN flow.riskFlags = 2 THEN 'MEDIUM_RISK'
      //  WHEN flow.riskFlags = 1 THEN 'LOW_RISK'
      //  ELSE 'MINIMAL_RISK'
    //END                                  AS RiskLevel,
    // Simplicity flag
    // flow.simplicityFlag                 AS SimplicityFlag,
    // Additional DW fine-grained counts
    flow.dwFunctionCount                AS DwFunctionCount,
    flow.dwFilterCount                  AS DwFilterCount,
    flow.dwImportCount                  AS DwImportCount,
    flow.dwCallCount                    AS DwCallCount,
    flow.dwFieldCount                   AS DwFieldCount
ORDER BY Application, FlowName; 