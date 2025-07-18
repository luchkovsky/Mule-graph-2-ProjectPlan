// ==============================================================
// STORY POINTS COMPLEXITY ANALYSIS FOR MULEAPPS AND FLOWS
// ==============================================================
// Enhanced complexity analysis specifically designed for story point estimation
// Uses configurable coefficients and thresholds for accurate story point calculation
// Prerequisites: Run this BEFORE story-points-project-planning.cypher
// ==============================================================

// ==============================================================
// CONFIGURABLE COEFFICIENTS AND THRESHOLDS
// ==============================================================
// These values can be tuned based on your team's experience and project requirements
// See story-points-coefficients.md for detailed tuning guidelines
// ==============================================================

WITH {
    // Structural Complexity Coefficients
    nestedStepWeight: 4,           // Base: 4, Conservative: 6, Experienced: 3

    
    // DataWeave Complexity Coefficients
    dwScriptCountWeight: 3,        // Base: 3, DW experts: 2, DW beginners: 5
    dwAvgComplexityWeight: 2,      // Base: 2, Complex transforms: 3-5
    dwMaxComplexityWeight: 1,      // Base: 1, Complex transforms: 3-5
    
    // Integration Complexity Coefficients
    connectorWeight: 3,            // Base: 3, Simple (HTTP): 2, Complex (SAP): 5-8
    errorHandlerWeight: 1,         // Base: 1, Critical systems: 2-3
    
    // Diversity Complexity Coefficients
    stepTypeWeight: 1,             // Base: 1
    stepCategoryWeight: 1,         // Base: 1
    
    // API Complexity Coefficients
    apiKitRouteWeight: 2,          // Base: 2
    apiKitWeight: 3,               // Base: 3
    apiKitResourceWeight: 1,       // Base: 1
    apiKitSchemaWeight: 4,         // Base: 4, API experts: 3, Beginners: 6-8
    apiKitActionWeight: 1,         // Base: 1
    
    // Batch / Asynchrony Complexity Coefficients
    batchJobWeight: 5,            // Extra weight for each batch:job step
    asyncFlowWeight: 8,           // Extra weight if the flow executes asynchronously
    asyncIndicatorWeight: 3,      // Per async-related step (VM/JMS publish, until-successful, etc.)
    
    // Risk Multipliers
    highRiskMultiplier: 1.5,       // Base: 1.5, Risk-averse: 1.8, Experienced: 1.3
    mediumRiskMultiplier: 1.3,     // Base: 1.3, Risk-averse: 1.5, Experienced: 1.2
    lowRiskMultiplier: 1.2,        // Base: 1.2, Risk-averse: 1.3, Experienced: 1.1
    
    // Story Point Thresholds
    epicThreshold: 200,            // 200+ complexity = 144 points (Epic)
    criticalThreshold: 150,        // 150+ complexity = 89 points (Epic)
    veryHighThreshold: 120,        // 120+ complexity = 55 points (Very Large)
    highUpperThreshold: 100,       // 100+ complexity = 34 points (Large)
    highLowerThreshold: 80,        // 80+ complexity = 21 points (Medium-Large)
    mediumUpperThreshold: 60,      // 60+ complexity = 13 points (Medium)
    mediumLowerThreshold: 40,      // 40+ complexity = 8 points (Small-Medium)
    lowUpperThreshold: 30,         // 30+ complexity = 5 points (Small)
    lowLowerThreshold: 20,         // 20+ complexity = 3 points (Very Small)
    veryLowThreshold: 10,          // 10+ complexity = 2 points (Tiny)
    trivialThreshold: 1            // 1+ complexity = 1 point (Trivial)
} as coefficients

// ==============================================================
// 1. ENHANCED FLOW COMPLEXITY WITH STORY POINT ESTIMATION
// ==============================================================

MATCH (app:MuleApp)-[:HAS_FLOW]->(flow:Flow)
MATCH (flow)-[:HAS_STEP]->(step:Step)
MATCH (flow)-[:HAS_STEP *]->(anyStep:Step)
OPTIONAL MATCH (flow)-[:HAS_ERROR_HANDLER]->(eh:ErrorHandler)
OPTIONAL MATCH (flow)-[:REFS_ON]->(apikit:ApiKit)

// DataWeave analysis using Script depth and lambdas
OPTIONAL MATCH (anyStep)-[:HAS_DW]->(dw:Script)

// ApiKit analysis for API complexity
OPTIONAL MATCH (app)-[:HAS_APIKIT]->(ak:ApiKit)
OPTIONAL MATCH (ak)-[:HAS_ROUTE]->(route:ApiKitRoute)
OPTIONAL MATCH (ak)-[:REFS_ON]->(resource:Resource)
OPTIONAL MATCH (ak)-[:HAS_RAML|:HAS_OAS]->(schema)

// Connectors for integration complexity
OPTIONAL MATCH (app)-[:HAS_CONNECTOR]->(connector:Connector)

// Calculate flow complexity metrics with story point focus
WITH app, flow, coefficients,
     // Step hierarchy complexity
     count(DISTINCT anyStep) as nestedStepCount,
     
     // Step diversity
     count(DISTINCT anyStep.type) as uniqueStepTypes,
     count(DISTINCT anyStep.category) as uniqueStepCategories,
     
     // Error handling
     count(DISTINCT eh) as errorHandlerCount,
     
     // DataWeave complexity using Script depth and lambdas
     count(DISTINCT dw) as dwScriptCount,
     CASE WHEN count(dw) > 0 THEN avg(dw.depth) ELSE 0.0 END as avgDwDepth,
     CASE WHEN count(dw) > 0 THEN max(dw.depth) ELSE 0 END as maxDwDepth,
     CASE WHEN count(dw) > 0 THEN sum(CASE WHEN dw.lambdas THEN 1 ELSE 0 END) ELSE 0 END as totalDwLambdas,
     
     // ApiKit complexity
     count(DISTINCT route) as apiKitRouteCount,
     count(DISTINCT ak) as apiKitCount,
     count(DISTINCT resource) as apiKitResourceCount,
     count(DISTINCT schema) as apiKitSchemaCount,
     count(DISTINCT route.action) as apiKitActionCount,
     
     // Connector complexity (explicit Connector nodes + steps whose category = 'connector')
     count(DISTINCT connector) + count(DISTINCT CASE WHEN anyStep.category = 'connector' THEN anyStep END) as connectorCount,

     // Batch processing complexity (Batch Module)
     count(DISTINCT CASE WHEN anyStep.type = 'batch:job' OR anyStep.category = 'batch' THEN anyStep END) as batchJobCount,

     // Async indicators: VM/JMS/AMQP publish-style steps or until-successful scopes
     count(DISTINCT CASE WHEN anyStep.type IN ['vm:publish','vm:publish-consume','jms:publish','jms:publish-consume','amqp:publish','async:until-successful'] THEN anyStep END) as asyncIndicatorCount,

     // Asynchronous flow flag (derive from property or detected indicators)
     CASE WHEN coalesce(flow.isAsync, flow.async, false) OR count(DISTINCT CASE WHEN anyStep.type IN ['vm:publish','vm:publish-consume','jms:publish','jms:publish-consume','amqp:publish','async:until-successful'] THEN anyStep END) > 0 THEN true ELSE false END as isAsyncFlow,
     
     // API exposure detection
     CASE WHEN count(DISTINCT ak) > 0 THEN true ELSE false END as isApiExposed

// -----------------------------------------------------------------------------
//  ADDITION: Fine-grained DataWeave metrics anchored to the CURRENT FLOW
//  (the previous version lost the "dw" variable after the first WITH, causing
//   all counts to default to zero if scripts were not re-matched).  We now
//   re-match DataWeave scripts starting from the current `flow` so every count
//   is calculated **per-flow**.
// -----------------------------------------------------------------------------

// Re-match DataWeave scripts that belong to this flow
OPTIONAL MATCH (flow)-[:HAS_STEP*]->(:Step)-[:HAS_DW]->(dwScript:Script)

// Fine-grained DW components
OPTIONAL MATCH (dwScript)-[:HAS_FUNCTION]->(dwFunc:Function)
OPTIONAL MATCH (dwScript)-[:HAS_FILTER|HAS_MAP|HAS_DISTINCTBY]->(dwFilter)
OPTIONAL MATCH (dwScript)-[:HAS_IMPORT]->(dwImport:Import)
OPTIONAL MATCH (dwScript)-[:HAS_CALL]->(dwCall:Call)
OPTIONAL MATCH (dwScript)-[:HAS_FIELD]->(dwField:Field)

// Calculate counts (default 0 when null)
WITH app, flow, coefficients,
     nestedStepCount,
     uniqueStepTypes, uniqueStepCategories, errorHandlerCount,
     dwScriptCount, avgDwDepth, maxDwDepth, totalDwLambdas,
     apiKitRouteCount, apiKitCount, apiKitResourceCount, apiKitSchemaCount, apiKitActionCount,
     connectorCount, batchJobCount, asyncIndicatorCount, isAsyncFlow, isApiExposed,
     count(DISTINCT dwFunc)   AS dwFunctionCount,
     count(DISTINCT dwFilter) AS dwFilterCount,
     count(DISTINCT dwImport) AS dwImportCount,
     count(DISTINCT dwField)  AS dwFieldCount,
     count(DISTINCT dwCall)   AS dwCallCount

// -----------------------------------------------------------------------------
// Compute base complexity, categories, and risk flags now that all counts exist
// -----------------------------------------------------------------------------
WITH app, flow, coefficients,
     nestedStepCount,
     uniqueStepTypes, uniqueStepCategories, errorHandlerCount,
     dwScriptCount, avgDwDepth, maxDwDepth, totalDwLambdas,
     apiKitRouteCount, apiKitCount, apiKitResourceCount, apiKitSchemaCount, apiKitActionCount,
     connectorCount, batchJobCount, asyncIndicatorCount, isAsyncFlow, isApiExposed,
     dwFunctionCount, dwFilterCount, dwImportCount, dwCallCount, dwFieldCount

// Enhanced complexity calculation
WITH app, flow, coefficients, nestedStepCount,
     uniqueStepTypes, uniqueStepCategories, errorHandlerCount, dwScriptCount, avgDwDepth,
     maxDwDepth, totalDwLambdas, apiKitRouteCount, apiKitCount, apiKitResourceCount,
     apiKitSchemaCount, apiKitActionCount, connectorCount, asyncIndicatorCount, isAsyncFlow, isApiExposed,
     dwFunctionCount, dwFilterCount, dwImportCount, dwCallCount, dwFieldCount,
     (
      nestedStepCount * coefficients.nestedStepWeight +
      dwScriptCount * coefficients.dwScriptCountWeight +
      avgDwDepth * coefficients.dwAvgComplexityWeight +
      maxDwDepth * coefficients.dwMaxComplexityWeight +
      connectorCount * coefficients.connectorWeight +
      errorHandlerCount * coefficients.errorHandlerWeight +
      uniqueStepTypes * coefficients.stepTypeWeight +
      uniqueStepCategories * coefficients.stepCategoryWeight +
      apiKitRouteCount * coefficients.apiKitRouteWeight +
      apiKitCount * coefficients.apiKitWeight +
      apiKitResourceCount * coefficients.apiKitResourceWeight +
      apiKitSchemaCount * coefficients.apiKitSchemaWeight +
      apiKitActionCount * coefficients.apiKitActionWeight +
      dwFunctionCount * 2 +
      dwFilterCount   * 2 +
      dwImportCount   * 1 +
      dwFieldCount    * 1 +
      dwCallCount     * 3 +
      batchJobCount   * coefficients.batchJobWeight +
      asyncIndicatorCount * coefficients.asyncIndicatorWeight +
      (CASE WHEN isAsyncFlow THEN coefficients.asyncFlowWeight ELSE 0 END)
      ) AS baseComplexityScore

// Continue with original logic
WITH app, flow, coefficients, nestedStepCount, 
     uniqueStepTypes, uniqueStepCategories, errorHandlerCount, dwScriptCount, avgDwDepth,
     maxDwDepth, totalDwLambdas, apiKitRouteCount, apiKitCount, apiKitResourceCount,
     apiKitSchemaCount, apiKitActionCount, connectorCount, asyncIndicatorCount, isAsyncFlow, isApiExposed,
     dwFunctionCount, dwFilterCount, dwImportCount, dwCallCount, dwFieldCount, baseComplexityScore

// API complexity categorization
WITH app, flow, coefficients, nestedStepCount, 
     uniqueStepTypes, uniqueStepCategories, errorHandlerCount, dwScriptCount, avgDwDepth,
     maxDwDepth, totalDwLambdas, apiKitRouteCount, apiKitCount, apiKitResourceCount,
     apiKitSchemaCount, apiKitActionCount, connectorCount, asyncIndicatorCount, isAsyncFlow, isApiExposed, 
     dwFunctionCount, dwFilterCount, dwFieldCount, dwImportCount, dwCallCount, baseComplexityScore,
     CASE 
         WHEN apiKitRouteCount >= 5 AND apiKitSchemaCount >= 2 THEN 'COMPLEX_API'
         WHEN apiKitRouteCount >= 3 OR apiKitSchemaCount >= 1 THEN 'MODERATE_API'
         WHEN apiKitRouteCount >= 1 THEN 'SIMPLE_API'
         ELSE 'NO_API'
     END AS apiComplexityCategory,
     CASE 
         WHEN totalDwLambdas >= 3 OR maxDwDepth >= 5 OR connectorCount >= 3 THEN 3
         WHEN totalDwLambdas >= 1 OR maxDwDepth >= 3 OR connectorCount >= 2 THEN 2
         WHEN dwScriptCount >= 3 OR errorHandlerCount >= 2 THEN 1
         ELSE 0
     END AS riskFlags

// Apply risk multipliers and calculate final complexity
WITH app, flow, coefficients,
      nestedStepCount, 
     uniqueStepTypes, uniqueStepCategories, errorHandlerCount,
     dwScriptCount, avgDwDepth, maxDwDepth, totalDwLambdas,
     apiKitRouteCount, apiKitCount, apiKitResourceCount, apiKitSchemaCount,
     connectorCount, asyncIndicatorCount, isAsyncFlow, isApiExposed, apiComplexityCategory, riskFlags,
     baseComplexityScore,
     dwFunctionCount, dwFilterCount, dwImportCount, dwCallCount, dwFieldCount
// Compute enhanced complexity first
WITH app, flow, coefficients,
     nestedStepCount, 
     uniqueStepTypes, uniqueStepCategories, errorHandlerCount,
     dwScriptCount, avgDwDepth, maxDwDepth, totalDwLambdas,
     apiKitRouteCount, apiKitCount, apiKitResourceCount, apiKitSchemaCount,
     connectorCount, asyncIndicatorCount, isAsyncFlow, isApiExposed, apiComplexityCategory, riskFlags,
     baseComplexityScore,
     dwFunctionCount, dwFilterCount, dwImportCount, dwCallCount, dwFieldCount,
     (baseComplexityScore * CASE 
         WHEN riskFlags >= 3 THEN coefficients.highRiskMultiplier
         WHEN riskFlags = 2 THEN coefficients.mediumRiskMultiplier
         WHEN riskFlags = 1 THEN coefficients.lowRiskMultiplier
         ELSE 1.0
     END) AS enhancedComplexityScore
// Now derive simplicityFlag
WITH app, flow, coefficients,
     nestedStepCount, 
     uniqueStepTypes, uniqueStepCategories, errorHandlerCount,
     dwScriptCount, avgDwDepth, maxDwDepth, totalDwLambdas,
     apiKitRouteCount, apiKitCount, apiKitResourceCount, apiKitSchemaCount,
     connectorCount, asyncIndicatorCount, isAsyncFlow, isApiExposed, apiComplexityCategory, riskFlags,
     baseComplexityScore, enhancedComplexityScore,
     dwFunctionCount, dwFilterCount, dwImportCount, dwCallCount, dwFieldCount,
     CASE WHEN enhancedComplexityScore <= coefficients.trivialThreshold * 2 THEN 1 ELSE 0 END AS simplicityFlag

// Calculate story points using configurable thresholds
WITH app, flow, coefficients,
     nestedStepCount, 
     uniqueStepTypes, uniqueStepCategories, errorHandlerCount,
     dwScriptCount, avgDwDepth, maxDwDepth, totalDwLambdas,
     apiKitRouteCount, apiKitCount, connectorCount,
     isApiExposed, apiComplexityCategory, riskFlags,
     baseComplexityScore, enhancedComplexityScore,
     dwFunctionCount, dwFilterCount, dwImportCount, dwCallCount, dwFieldCount,
     simplicityFlag,
     asyncIndicatorCount,
     isAsyncFlow,
     
     // Base story points from complexity score
     CASE 
         WHEN enhancedComplexityScore >= coefficients.epicThreshold THEN 144
         WHEN enhancedComplexityScore >= coefficients.criticalThreshold THEN 89
         WHEN enhancedComplexityScore >= coefficients.veryHighThreshold THEN 55
         WHEN enhancedComplexityScore >= coefficients.highUpperThreshold THEN 34
         WHEN enhancedComplexityScore >= coefficients.highLowerThreshold THEN 21
         WHEN enhancedComplexityScore >= coefficients.mediumUpperThreshold THEN 13
         WHEN enhancedComplexityScore >= coefficients.mediumLowerThreshold THEN 8
         WHEN enhancedComplexityScore >= coefficients.lowUpperThreshold THEN 5
         WHEN enhancedComplexityScore >= coefficients.lowLowerThreshold THEN 3
         WHEN enhancedComplexityScore >= coefficients.veryLowThreshold THEN 2
         ELSE 1
     END as baseStoryPoints,
     
     // Additional story points for API complexity
     CASE 
         WHEN apiComplexityCategory = 'COMPLEX_API' THEN 8
         WHEN apiComplexityCategory = 'MODERATE_API' THEN 5
         WHEN apiComplexityCategory = 'SIMPLE_API' THEN 3
         ELSE 0
     END as apiStoryPoints,
     
     // Additional story points for DataWeave complexity
     CASE 
         WHEN dwScriptCount >= 10 THEN 8
         WHEN dwScriptCount >= 5 THEN 5
         WHEN dwScriptCount >= 3 THEN 3
         WHEN dwScriptCount >= 1 THEN 2
         ELSE 0
     END as dwStoryPoints

// Calculate final story points and normalize to Fibonacci scale
WITH app, flow, 
     nestedStepCount, 
     uniqueStepTypes, uniqueStepCategories, errorHandlerCount,
     dwScriptCount, avgDwDepth, maxDwDepth, totalDwLambdas,
     apiKitRouteCount, apiKitCount, connectorCount,
     isApiExposed, apiComplexityCategory, riskFlags,
     baseComplexityScore, enhancedComplexityScore,
     baseStoryPoints, apiStoryPoints, dwStoryPoints,
     dwFunctionCount, dwFilterCount, dwImportCount, dwCallCount, dwFieldCount,
     simplicityFlag,
     asyncIndicatorCount,
     isAsyncFlow,
     (baseStoryPoints + apiStoryPoints + dwStoryPoints) as rawStoryPoints,
     
     // Normalize to Fibonacci scale (1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144)
     CASE 
         WHEN (baseStoryPoints + apiStoryPoints + dwStoryPoints) >= 144 THEN 144
         WHEN (baseStoryPoints + apiStoryPoints + dwStoryPoints) >= 89 THEN 89
         WHEN (baseStoryPoints + apiStoryPoints + dwStoryPoints) >= 55 THEN 55
         WHEN (baseStoryPoints + apiStoryPoints + dwStoryPoints) >= 34 THEN 34
         WHEN (baseStoryPoints + apiStoryPoints + dwStoryPoints) >= 21 THEN 21
         WHEN (baseStoryPoints + apiStoryPoints + dwStoryPoints) >= 13 THEN 13
         WHEN (baseStoryPoints + apiStoryPoints + dwStoryPoints) >= 8 THEN 8
         WHEN (baseStoryPoints + apiStoryPoints + dwStoryPoints) >= 5 THEN 5
         WHEN (baseStoryPoints + apiStoryPoints + dwStoryPoints) >= 3 THEN 3
         WHEN (baseStoryPoints + apiStoryPoints + dwStoryPoints) >= 2 THEN 2
         ELSE 1
     END as finalStoryPoints,
     
     // Story point category for planning
     CASE 
         WHEN (baseStoryPoints + apiStoryPoints + dwStoryPoints) >= 144 THEN 'EPIC'
         WHEN (baseStoryPoints + apiStoryPoints + dwStoryPoints) >= 89 THEN 'EPIC'
         WHEN (baseStoryPoints + apiStoryPoints + dwStoryPoints) >= 55 THEN 'VERY_LARGE'
         WHEN (baseStoryPoints + apiStoryPoints + dwStoryPoints) >= 34 THEN 'LARGE'
         WHEN (baseStoryPoints + apiStoryPoints + dwStoryPoints) >= 21 THEN 'MEDIUM_LARGE'
         WHEN (baseStoryPoints + apiStoryPoints + dwStoryPoints) >= 13 THEN 'MEDIUM'
         WHEN (baseStoryPoints + apiStoryPoints + dwStoryPoints) >= 8 THEN 'SMALL_MEDIUM'
         WHEN (baseStoryPoints + apiStoryPoints + dwStoryPoints) >= 5 THEN 'SMALL'
         WHEN (baseStoryPoints + apiStoryPoints + dwStoryPoints) >= 3 THEN 'VERY_SMALL'
         WHEN (baseStoryPoints + apiStoryPoints + dwStoryPoints) >= 2 THEN 'TINY'
         ELSE 'TRIVIAL'
     END as storyPointCategory

// Set flow properties for story point planning
SET flow.baseComplexityScore = baseComplexityScore,
    flow.enhancedComplexityScore = enhancedComplexityScore,
    flow.baseStoryPoints = baseStoryPoints,
    flow.apiStoryPoints = apiStoryPoints,
    flow.dwStoryPoints = dwStoryPoints,
    flow.rawStoryPoints = rawStoryPoints,
    flow.finalStoryPoints = finalStoryPoints,
    flow.storyPointCategory = storyPointCategory,
    flow.apiComplexityCategory = apiComplexityCategory,
    flow.isApiExposed = isApiExposed,
    flow.riskFlags = riskFlags,
    flow.dwScriptCount = dwScriptCount,
    flow.connectorCount = connectorCount,
    flow.simplicityFlag = simplicityFlag,
    flow.dwFunctionCount = dwFunctionCount,
    flow.dwFilterCount = dwFilterCount,
    flow.dwImportCount  = dwImportCount,
    flow.dwCallCount    = dwCallCount,
    flow.dwFieldCount   = dwFieldCount,
    flow.asyncIndicatorCount = asyncIndicatorCount,
    flow.isAsyncFlow = isAsyncFlow,
    // Persist step diversity & hierarchy metrics for validation
    flow.nestedStepCount       = nestedStepCount,
    flow.uniqueStepTypes       = uniqueStepTypes,
    flow.uniqueStepCategories  = uniqueStepCategories,
    flow.errorHandlerCount     = errorHandlerCount,
    flow.apiKitRouteCount      = apiKitRouteCount,
    flow.apiKitCount           = apiKitCount,
    flow.avgDwDepth            = avgDwDepth,
    flow.maxDwDepth            = maxDwDepth,
    flow.totalDwLambdas        = totalDwLambdas,
    flow.dwFieldCount          = dwFieldCount

RETURN 
    app.name as ApplicationName,
    flow.flow as FlowName,
    
    // Complexity metrics
    round(baseComplexityScore, 1) as BaseComplexityScore,
    round(enhancedComplexityScore, 1) as EnhancedComplexityScore,
    
    // Story point breakdown
    baseStoryPoints as BaseStoryPoints,
    apiStoryPoints as ApiStoryPoints,
    dwStoryPoints as DataWeaveStoryPoints,
    rawStoryPoints as RawStoryPoints,
    finalStoryPoints as FinalStoryPoints,
    storyPointCategory as StoryPointCategory,
    
    // Component metrics
    nestedStepCount as NestedSteps,
    uniqueStepTypes as UniqueStepTypes,
    uniqueStepCategories as UniqueStepCategories,
    
    // DataWeave metrics
    dwScriptCount as DataWeaveScripts,
    round(avgDwDepth, 1) as AvgDataWeaveDepth,
    maxDwDepth as MaxDataWeaveDepth,
    totalDwLambdas as TotalDataWeaveLambdas,
    
    // Integration metrics
    connectorCount as Connectors,
    errorHandlerCount as ErrorHandlers,
    
    // API metrics
    isApiExposed as IsApiExposed,
    apiComplexityCategory as ApiComplexityCategory,
    apiKitRouteCount as ApiKitRoutes,
    apiKitCount as ApiKits,
    
    // Risk indicators
    riskFlags as RiskFlags,
    CASE 
        WHEN riskFlags >= 3 THEN 'HIGH_RISK'
        WHEN riskFlags = 2 THEN 'MEDIUM_RISK'
        WHEN riskFlags = 1 THEN 'LOW_RISK'
        ELSE 'MINIMAL_RISK'
    END as RiskLevel,
    
    // Migration guidance
    CASE 
        WHEN finalStoryPoints >= 89 THEN 'Epic - requires breakdown into smaller stories'
        WHEN finalStoryPoints >= 55 THEN 'Very Large - expert team recommended'
        WHEN finalStoryPoints >= 34 THEN 'Large - senior team recommended'
        WHEN finalStoryPoints >= 21 THEN 'Medium-Large - standard team capable'
        WHEN finalStoryPoints >= 13 THEN 'Medium - standard team'
        WHEN finalStoryPoints >= 8 THEN 'Small-Medium - any team'
        WHEN finalStoryPoints >= 5 THEN 'Small - any team'
        ELSE 'Very Small - quick migration'
    END as MigrationGuidance

ORDER BY finalStoryPoints DESC, enhancedComplexityScore DESC;

// ==============================================================
// 2. APP-LEVEL STORY POINT SUMMARY
// ==============================================================

MATCH (app:MuleApp)-[:HAS_FLOW]->(flow:Flow)
WHERE flow.finalStoryPoints IS NOT NULL

WITH app,
     collect(flow) as flows,
     sum(flow.finalStoryPoints) as totalAppStoryPoints,
     avg(flow.finalStoryPoints) as avgFlowStoryPoints,
     count(flow) as totalFlows,
     count(CASE WHEN flow.storyPointCategory IN ['EPIC'] THEN 1 END) as epicsCount,
     count(CASE WHEN flow.storyPointCategory IN ['VERY_LARGE', 'LARGE'] THEN 1 END) as largeStoriesCount,
     count(CASE WHEN flow.storyPointCategory IN ['MEDIUM_LARGE', 'MEDIUM'] THEN 1 END) as mediumStoriesCount,
     count(CASE WHEN flow.storyPointCategory IN ['SMALL_MEDIUM', 'SMALL', 'VERY_SMALL', 'TINY', 'TRIVIAL'] THEN 1 END) as smallStoriesCount,
     count(CASE WHEN flow.isApiExposed THEN 1 END) as apiFlowsCount,
     count(CASE WHEN flow.riskFlags >= 2 THEN 1 END) as riskFlowsCount

RETURN 
    app.name as ApplicationName,
    totalAppStoryPoints as TotalStoryPoints,
    round(avgFlowStoryPoints, 1) as AvgStoryPointsPerFlow,
    totalFlows as TotalFlows,
    
    // Story distribution
    epicsCount as EpicsNeedingBreakdown,
    largeStoriesCount as LargeStories_34plus,
    mediumStoriesCount as MediumStories_13to34,
    smallStoriesCount as SmallStories_1to13,
    
    // Special characteristics
    apiFlowsCount as ApiFlows,
    riskFlowsCount as HighRiskFlows,
    
    // Planning estimates
    CASE 
        WHEN totalAppStoryPoints >= 500 THEN 'Large App - 3+ teams needed'
        WHEN totalAppStoryPoints >= 200 THEN 'Medium App - 2 teams recommended'
        WHEN totalAppStoryPoints >= 100 THEN 'Small App - 1 team sufficient'
        ELSE 'Tiny App - part of team capacity'
    END as AppSizeEstimate,
    
    // Sprint estimates (assuming 30-40 points per team per sprint)
    round(totalAppStoryPoints / 35.0, 1) as EstimatedSprints,
    
    // Risk assessment
    CASE 
        WHEN riskFlowsCount > totalFlows * 0.5 THEN 'HIGH_RISK_APP'
        WHEN riskFlowsCount > totalFlows * 0.25 THEN 'MEDIUM_RISK_APP'
        WHEN riskFlowsCount > 0 THEN 'LOW_RISK_APP'
        ELSE 'MINIMAL_RISK_APP'
    END as AppRiskLevel

ORDER BY totalAppStoryPoints DESC;

// ==============================================================
// 3. STORY POINT VALIDATION AND QUALITY METRICS
// ==============================================================

MATCH (app:MuleApp)-[:HAS_FLOW]->(flow:Flow)
WHERE flow.finalStoryPoints IS NOT NULL

WITH 
    count(flow) as totalStories,
    count(CASE WHEN flow.finalStoryPoints >= 34 THEN 1 END) as storiesNeedingBreakdown,
    avg(flow.finalStoryPoints) as avgStorySize,
    min(flow.finalStoryPoints) as minStoryPoints,
    max(flow.finalStoryPoints) as maxStoryPoints,
    count(CASE WHEN flow.isApiExposed THEN 1 END) as apiStories,
    count(CASE WHEN flow.riskFlags >= 2 THEN 1 END) as riskStories

RETURN 
    'Story Points Quality Report' as ReportType,
    totalStories as TotalStories,
    storiesNeedingBreakdown as StoriesNeedingBreakdown,
    round(avgStorySize, 1) as AvgStorySize,
    minStoryPoints as MinStoryPoints,
    maxStoryPoints as MaxStoryPoints,
    apiStories as ApiStories,
    riskStories as RiskStories,
    
    // Quality indicators
    CASE 
        WHEN avgStorySize > 20 THEN 'STORIES_TOO_LARGE'
        WHEN avgStorySize < 5 THEN 'STORIES_TOO_GRANULAR'
        ELSE 'GOOD_STORY_SIZING'
    END as StorySizingQuality,
    
    CASE 
        WHEN storiesNeedingBreakdown > totalStories * 0.3 THEN 'TOO_MANY_EPICS'
        WHEN storiesNeedingBreakdown = 0 THEN 'NO_EPICS_FOUND'
        ELSE 'BALANCED_EPIC_RATIO'
    END as EpicRatio,
    
    CASE 
        WHEN riskStories > totalStories * 0.4 THEN 'HIGH_RISK_PROJECT'
        WHEN riskStories > totalStories * 0.2 THEN 'MEDIUM_RISK_PROJECT'
        ELSE 'LOW_RISK_PROJECT'
    END as ProjectRiskLevel,
    
    // Recommendations
    CASE 
        WHEN avgStorySize > 20 THEN 'Break down large stories into smaller pieces'
        WHEN storiesNeedingBreakdown > totalStories * 0.3 THEN 'Too many epics - consider breaking down further'
        WHEN riskStories > totalStories * 0.4 THEN 'High risk project - assign expert teams'
        ELSE 'Story sizing looks good for agile planning'
    END as Recommendations; 

// ** NEW SECTION 4 – SIMPLICITY ANALYSIS **
// --------------------------------------------------------------
MATCH (flow:Flow)
WHERE flow.simplicityFlag = 1
WITH count(flow) AS simpleFlows, collect(flow) AS simpleFlowList
RETURN 'Simplicity Analysis'      AS ReportType,
       simpleFlows                AS TotalSimpleFlows,
       [f IN simpleFlowList | f.app + '::' + f.flow][..20] AS SampleSimpleFlows; 