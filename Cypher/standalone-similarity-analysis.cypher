// STANDALONE SIMILARITY ANALYSIS WITH COSINE SIMILARITY
// Independent script for detecting and analyzing similar flows and applications using cosine similarity

// =============================================================================
// SECTION 1: FLOW STRUCTURE VECTOR CREATION
// =============================================================================

// 1.1 - Clean any existing similarity data
MATCH (sg:SimilarityGroup) DETACH DELETE sg;
MATCH (app:Application) REMOVE app.similarityVector, app.cosineGroups;
MATCH (flow:Flow) REMOVE flow.similarityGroupId, flow.similarityScore, flow.similarityStrategy, flow.structureVector, flow.cosineScore;

// 1.2 - Create comprehensive flow structure vectors
MATCH (flow:Flow)
WHERE flow.finalStoryPoints IS NOT NULL

// Get all flow steps and their types
OPTIONAL MATCH (flow)-[:CONTAINS_STEP]->(step)
WITH flow, collect(step.type) as stepTypes

// Create flow structure vector with comprehensive metrics
WITH flow, stepTypes,
     // Basic metrics
     flow.connectorCount as connectorCount,
     flow.dwScriptCount as dwScriptCount,
     flow.isApiExposed as isApiExposed,
     flow.finalStoryPoints as storyPoints,
     
     // Step type analysis
     size([s IN stepTypes WHERE s CONTAINS 'http']) as httpSteps,
     size([s IN stepTypes WHERE s CONTAINS 'database']) as dbSteps,
     size([s IN stepTypes WHERE s CONTAINS 'transform']) as transformSteps,
     size([s IN stepTypes WHERE s CONTAINS 'validate']) as validateSteps,
     size([s IN stepTypes WHERE s CONTAINS 'choice']) as choiceSteps,
     size([s IN stepTypes WHERE s CONTAINS 'foreach']) as foreachSteps,
     size([s IN stepTypes WHERE s CONTAINS 'async']) as asyncSteps,
     size([s IN stepTypes WHERE s CONTAINS 'error']) as errorSteps,
     size([s IN stepTypes WHERE s CONTAINS 'log']) as logSteps,
     size([s IN stepTypes WHERE s CONTAINS 'set']) as setSteps,
     size(stepTypes) as totalSteps

SET flow.structureVector = [
    connectorCount,
    dwScriptCount,
    CASE WHEN isApiExposed THEN 1 ELSE 0 END,
    storyPoints,
    httpSteps,
    dbSteps,
    transformSteps,
    validateSteps,
    choiceSteps,
    foreachSteps,
    asyncSteps,
    errorSteps,
    logSteps,
    setSteps,
    totalSteps
],
flow.vectorDimensions = [
    'connectorCount', 'dwScriptCount', 'isApiExposed', 'storyPoints',
    'httpSteps', 'dbSteps', 'transformSteps', 'validateSteps',
    'choiceSteps', 'foreachSteps', 'asyncSteps', 'errorSteps',
    'logSteps', 'setSteps', 'totalSteps'
];

// =============================================================================
// SECTION 2: APPLICATION-LEVEL SIMILARITY VECTORS
// =============================================================================

// 2.1 - Create application similarity vectors
MATCH (app:Application)
OPTIONAL MATCH (app)<-[:BELONGS_TO]-(flow:Flow)
WHERE flow.structureVector IS NOT NULL

WITH app, collect(flow.structureVector) as flowVectors, count(flow) as flowCount

// Calculate application-level aggregated vector
WITH app, flowVectors, flowCount,
     // Average all flow vectors to create application signature
     [i IN range(0, 14) | 
      round(avg([v IN flowVectors | v[i]]), 2)
     ] as appVector

SET app.similarityVector = appVector,
    app.flowCount = flowCount,
    app.vectorDimensions = [
        'avgConnectorCount', 'avgDwScriptCount', 'apiExposureRate', 'avgStoryPoints',
        'avgHttpSteps', 'avgDbSteps', 'avgTransformSteps', 'avgValidateSteps',
        'avgChoiceSteps', 'avgForeachSteps', 'avgAsyncSteps', 'avgErrorSteps',
        'avgLogSteps', 'avgSetSteps', 'avgTotalSteps'
    ];

// =============================================================================
// SECTION 3: COSINE SIMILARITY CALCULATIONS
// =============================================================================

// 3.1 - Calculate cosine similarity between all flow pairs
MATCH (f1:Flow), (f2:Flow)
WHERE f1.structureVector IS NOT NULL 
  AND f2.structureVector IS NOT NULL
  AND f1 <> f2
  AND f1.app <= f2.app  // Avoid duplicate pairs

WITH f1, f2,
     f1.structureVector as v1,
     f2.structureVector as v2,
     
     // Calculate dot product
     reduce(sum = 0, i IN range(0, 14) | sum + v1[i] * v2[i]) as dotProduct,
     
     // Calculate magnitudes
     sqrt(reduce(sum = 0, i IN range(0, 14) | sum + v1[i] * v1[i])) as magnitude1,
     sqrt(reduce(sum = 0, i IN range(0, 14) | sum + v2[i] * v2[i])) as magnitude2

WITH f1, f2, dotProduct, magnitude1, magnitude2,
     // Calculate cosine similarity
     CASE 
         WHEN magnitude1 > 0 AND magnitude2 > 0 
         THEN dotProduct / (magnitude1 * magnitude2)
         ELSE 0
     END as cosineSimilarity

// Only keep high similarity pairs (threshold 0.7)
WHERE cosineSimilarity >= 0.7

SET f1.cosineScore = cosineSimilarity,
    f2.cosineScore = cosineSimilarity;

// 3.2 - Calculate cosine similarity between applications
MATCH (app1:Application), (app2:Application)
WHERE app1.similarityVector IS NOT NULL 
  AND app2.similarityVector IS NOT NULL
  AND app1 <> app2
  AND app1.name <= app2.name  // Avoid duplicate pairs

WITH app1, app2,
     app1.similarityVector as v1,
     app2.similarityVector as v2,
     
     // Calculate dot product
     reduce(sum = 0, i IN range(0, 14) | sum + v1[i] * v2[i]) as dotProduct,
     
     // Calculate magnitudes
     sqrt(reduce(sum = 0, i IN range(0, 14) | sum + v1[i] * v1[i])) as magnitude1,
     sqrt(reduce(sum = 0, i IN range(0, 14) | sum + v2[i] * v2[i])) as magnitude2

WITH app1, app2, dotProduct, magnitude1, magnitude2,
     // Calculate cosine similarity
     CASE 
         WHEN magnitude1 > 0 AND magnitude2 > 0 
         THEN dotProduct / (magnitude1 * magnitude2)
         ELSE 0
     END as cosineSimilarity

// Only keep high similarity pairs (threshold 0.8 for applications)
WHERE cosineSimilarity >= 0.8

CREATE (app1)-[:COSINE_SIMILAR {
    similarity: round(cosineSimilarity, 3),
    type: 'APPLICATION_COSINE_SIMILARITY',
    threshold: 0.8,
    createdAt: datetime()
}]->(app2);

// =============================================================================
// SECTION 4: ENHANCED SIMILARITY GROUP CREATION
// =============================================================================

// 4.1 - Create cosine similarity groups for flows
MATCH (f1:Flow)-[r:COSINE_SIMILAR]-(f2:Flow)
WHERE r.similarity >= 0.85  // High similarity threshold

WITH f1, f2, r.similarity as similarity
ORDER BY similarity DESC

// Create flow similarity groups
WITH collect({f1: f1, f2: f2, similarity: similarity}) as pairs

UNWIND pairs as pair
WITH pair.f1 as f1, pair.f2 as f2, pair.similarity as similarity

MERGE (sg:SimilarityGroup {
    id: 'CSG_' + f1.app + '_' + f2.app,
    type: 'COSINE_SIMILARITY_GROUP',
    similarity: similarity,
    createdAt: datetime()
})

CREATE (f1)-[:BELONGS_TO_COSINE_GROUP {similarity: similarity}]->(sg)
CREATE (f2)-[:BELONGS_TO_COSINE_GROUP {similarity: similarity}]->(sg);

// 4.2 - Enhanced similarity groups with strategy assignment
MATCH (sg:SimilarityGroup)
WHERE sg.type = 'COSINE_SIMILARITY_GROUP'
OPTIONAL MATCH (sg)<-[:BELONGS_TO_COSINE_GROUP]-(flow:Flow)

WITH sg, collect(flow) as flows, count(flow) as flowCount, avg(flow.finalStoryPoints) as avgStoryPoints

SET sg.flowCount = flowCount,
    sg.avgStoryPoints = round(avgStoryPoints, 1),
    sg.strategy = CASE 
        WHEN flowCount <= 3 THEN 'SAME_TEAM_COSINE'
        WHEN flowCount <= 6 THEN 'SAME_TEAM_SEQUENTIAL_COSINE'
        ELSE 'DISTRIBUTED_WITH_LEAD_COSINE'
    END,
    sg.description = CASE 
        WHEN flowCount <= 3 THEN 'High cosine similarity - assign to same team for maximum pattern reuse'
        WHEN flowCount <= 6 THEN 'Medium cosine similarity - same team with sequential scheduling'
        ELSE 'Large cosine similarity group - expert team creates patterns'
    END;

// =============================================================================
// SECTION 5: COMPREHENSIVE SIMILARITY ANALYSIS RESULTS
// =============================================================================

// 5.1 - Application-level cosine similarity analysis
MATCH (app1:Application)-[r:COSINE_SIMILAR]->(app2:Application)

RETURN 'APPLICATION_COSINE_SIMILARITY' as AnalysisType,
       app1.name as Application1,
       app2.name as Application2,
       r.similarity as CosineSimilarity,
       app1.flowCount as App1FlowCount,
       app2.flowCount as App2FlowCount,
       app1.similarityVector as App1Vector,
       app2.similarityVector as App2Vector,
       
       // Migration recommendations
       CASE 
           WHEN r.similarity >= 0.95 THEN 'IDENTICAL_PATTERN - Migrate together, shared components'
           WHEN r.similarity >= 0.90 THEN 'VERY_SIMILAR - Migrate consecutively, reuse patterns'
           WHEN r.similarity >= 0.85 THEN 'SIMILAR - Same team, leverage common patterns'
           ELSE 'MODERATELY_SIMILAR - Consider pattern reuse'
       END as MigrationStrategy,
       
       // Effort savings potential
       CASE 
           WHEN r.similarity >= 0.95 THEN '40-60% effort reduction'
           WHEN r.similarity >= 0.90 THEN '25-40% effort reduction'
           WHEN r.similarity >= 0.85 THEN '15-25% effort reduction'
           ELSE '10-15% effort reduction'
       END as EffortSavings

ORDER BY r.similarity DESC;

// 5.2 - Flow-level cosine similarity analysis
MATCH (sg:SimilarityGroup)<-[:BELONGS_TO_COSINE_GROUP]-(flow:Flow)
WHERE sg.type = 'COSINE_SIMILARITY_GROUP'

WITH sg, flow
ORDER BY sg.similarity DESC, flow.finalStoryPoints DESC

RETURN sg.id as GroupId,
       sg.similarity as CosineSimilarity,
       sg.strategy as RecommendedStrategy,
       sg.flowCount as FlowCount,
       sg.avgStoryPoints as AvgStoryPoints,
       flow.app as Application,
       flow.flow as FlowName,
       flow.structureVector as FlowVector,
       
       // Pattern analysis
       CASE 
           WHEN sg.similarity >= 0.95 THEN 'NEAR_IDENTICAL - Template reuse, 50%+ efficiency'
           WHEN sg.similarity >= 0.90 THEN 'VERY_SIMILAR - Pattern reuse, 30-50% efficiency'
           WHEN sg.similarity >= 0.85 THEN 'SIMILAR - Common approach, 20-30% efficiency'
           ELSE 'MODERATELY_SIMILAR - Some reuse possible'
       END as PatternAnalysis,
       
       // Implementation guidance
       CASE 
           WHEN sg.strategy = 'SAME_TEAM_COSINE' THEN 'Assign all to same team, create template from first'
           WHEN sg.strategy = 'SAME_TEAM_SEQUENTIAL_COSINE' THEN 'Same team, implement first as template'
           WHEN sg.strategy = 'DISTRIBUTED_WITH_LEAD_COSINE' THEN 'Expert team creates pattern, others implement'
           ELSE 'Custom approach needed'
       END as ImplementationGuidance

ORDER BY sg.similarity DESC, sg.flowCount DESC;

// 5.3 - Cosine similarity impact assessment
MATCH (app:Application)
OPTIONAL MATCH (app)-[r:COSINE_SIMILAR]-()
OPTIONAL MATCH (app)<-[:BELONGS_TO]-(flow:Flow)
OPTIONAL MATCH (flow)-[:BELONGS_TO_COSINE_GROUP]->(sg:SimilarityGroup)

WITH app, 
     count(DISTINCT r) as appSimilarityCount,
     avg(r.similarity) as avgAppSimilarity,
     count(DISTINCT flow) as totalFlows,
     count(DISTINCT sg) as flowSimilarityGroups

RETURN 'COSINE_SIMILARITY_IMPACT' as AnalysisType,
       app.name as Application,
       appSimilarityCount as SimilarApplications,
       round(avgAppSimilarity, 3) as AvgAppSimilarity,
       totalFlows as TotalFlows,
       flowSimilarityGroups as FlowSimilarityGroups,
       
       // Overall similarity rating
       CASE 
           WHEN appSimilarityCount >= 3 AND avgAppSimilarity >= 0.85 THEN 'HIGH_SIMILARITY_CANDIDATE'
           WHEN appSimilarityCount >= 2 AND avgAppSimilarity >= 0.80 THEN 'MEDIUM_SIMILARITY_CANDIDATE'
           WHEN appSimilarityCount >= 1 AND avgAppSimilarity >= 0.75 THEN 'LOW_SIMILARITY_CANDIDATE'
           ELSE 'UNIQUE_APPLICATION'
       END as SimilarityRating,
       
       // Migration priority
       CASE 
           WHEN appSimilarityCount >= 3 THEN 'HIGH_PRIORITY - Migrate with similar apps'
           WHEN appSimilarityCount >= 2 THEN 'MEDIUM_PRIORITY - Consider grouping'
           WHEN appSimilarityCount >= 1 THEN 'LOW_PRIORITY - Optional grouping'
           ELSE 'INDEPENDENT - Migrate separately'
       END as MigrationPriority

ORDER BY appSimilarityCount DESC, avgAppSimilarity DESC;

// 5.4 - Comprehensive efficiency analysis
MATCH (sg:SimilarityGroup)
WHERE sg.type = 'COSINE_SIMILARITY_GROUP'

WITH sg, sg.flowCount as flowCount, sg.avgStoryPoints as avgStoryPoints, sg.similarity as similarity

RETURN 'COSINE_EFFICIENCY_ANALYSIS' as AnalysisType,
       count(sg) as TotalCosineGroups,
       sum(sg.flowCount) as FlowsInCosineGroups,
       round(avg(sg.flowCount), 1) as AvgCosineGroupSize,
       round(avg(sg.similarity), 3) as AvgCosineSimilarity,
       max(sg.flowCount) as LargestCosineGroup,
       max(sg.similarity) as HighestCosineSimilarity,
       
       // Efficiency calculations
       sum(CASE WHEN sg.similarity >= 0.95 THEN sg.flowCount * 0.5 ELSE 0 END) as HighEfficiencyFlows,
       sum(CASE WHEN sg.similarity >= 0.90 THEN sg.flowCount * 0.3 ELSE 0 END) as MediumEfficiencyFlows,
       sum(CASE WHEN sg.similarity >= 0.85 THEN sg.flowCount * 0.2 ELSE 0 END) as LowEfficiencyFlows,
       
       // Total effort savings
       round(sum(sg.flowCount * sg.avgStoryPoints * sg.similarity * 0.3), 1) as EstimatedEffortSavings,
       
       // Overall recommendation
       CASE 
           WHEN count(sg) >= 10 AND avg(sg.similarity) >= 0.90 THEN 'EXTREMELY_HIGH similarity - mandatory cosine-enhanced workflow'
           WHEN count(sg) >= 5 AND avg(sg.similarity) >= 0.85 THEN 'HIGH similarity - strongly recommend cosine-enhanced workflow'
           WHEN count(sg) >= 3 AND avg(sg.similarity) >= 0.80 THEN 'MEDIUM similarity - consider cosine-enhanced workflow'
           WHEN count(sg) >= 1 THEN 'LOW similarity - optional cosine analysis'
           ELSE 'NO significant cosine similarity - use standard workflow'
       END as Recommendation;

// =============================================================================
// SECTION 6: COSINE SIMILARITY EXPORT FOR EXCEL
// =============================================================================

// 6.1 - Export flow cosine similarity data
MATCH (f1:Flow)-[r:COSINE_SIMILAR]->(f2:Flow)

RETURN f1.app as Application1,
       f1.flow as Flow1,
       f2.app as Application2,
       f2.flow as Flow2,
       round(r.similarity, 4) as CosineSimilarity,
       f1.finalStoryPoints as Flow1StoryPoints,
       f2.finalStoryPoints as Flow2StoryPoints,
       
       // Vector comparison
       toString(f1.structureVector) as Flow1Vector,
       toString(f2.structureVector) as Flow2Vector,
       
       // Efficiency potential
       CASE 
           WHEN r.similarity >= 0.95 THEN 'Very High (50%+)'
           WHEN r.similarity >= 0.90 THEN 'High (30-50%)'
           WHEN r.similarity >= 0.85 THEN 'Medium (20-30%)'
           ELSE 'Low (10-20%)'
       END as EfficiencyPotential

ORDER BY r.similarity DESC;

// 6.2 - Export application cosine similarity data
MATCH (app1:Application)-[r:COSINE_SIMILAR]->(app2:Application)

RETURN app1.name as Application1,
       app2.name as Application2,
       round(r.similarity, 4) as CosineSimilarity,
       app1.flowCount as App1FlowCount,
       app2.flowCount as App2FlowCount,
       toString(app1.similarityVector) as App1Vector,
       toString(app2.similarityVector) as App2Vector,
       
       // Migration recommendations
       CASE 
           WHEN r.similarity >= 0.95 THEN 'Migrate Together'
           WHEN r.similarity >= 0.90 THEN 'Migrate Consecutively'
           WHEN r.similarity >= 0.85 THEN 'Same Team'
           ELSE 'Consider Grouping'
       END as MigrationRecommendation,
       
       // Estimated savings
       CASE 
           WHEN r.similarity >= 0.95 THEN '40-60%'
           WHEN r.similarity >= 0.90 THEN '25-40%'
           WHEN r.similarity >= 0.85 THEN '15-25%'
           ELSE '10-15%'
       END as EstimatedSavings

ORDER BY r.similarity DESC; 