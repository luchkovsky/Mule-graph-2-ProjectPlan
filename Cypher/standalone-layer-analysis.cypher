// STANDALONE LAYER ANALYSIS
// Independent script for detecting and analyzing Mule 3-layer architecture (Experience, Process, System)

// =============================================================================
// SECTION 1: LAYER DETECTION SETUP
// =============================================================================

// 1.1 - Clean any existing layer data
MATCH (flow:Flow) 
REMOVE flow.muleLayer, flow.layerConfidence, flow.layerSpecificRisk, flow.layerClassifiedAt, flow.manuallyClassified, flow.manualClassificationReason;

// 1.2 - Layer detection and classification
MATCH (app:MuleApp)-[:HAS_FLOW]->(flow:Flow)
WHERE flow.finalStoryPoints IS NOT NULL

WITH flow, app,
     // Layer detection based on flow characteristics
     CASE 
         // EXPERIENCE LAYER - External-facing APIs, user interfaces
         WHEN flow.isApiExposed = true AND flow.connectorCount <= 2 AND flow.dwScriptCount <= 2 THEN 'EXPERIENCE'
         WHEN flow.flow CONTAINS 'api' AND flow.isApiExposed = true THEN 'EXPERIENCE'
         WHEN flow.flow CONTAINS 'web' OR flow.flow CONTAINS 'mobile' OR flow.flow CONTAINS 'ui' THEN 'EXPERIENCE'
         WHEN app.name CONTAINS 'api' AND flow.isApiExposed = true AND flow.connectorCount <= 3 THEN 'EXPERIENCE'
         
         // SYSTEM LAYER - Direct system access, databases, legacy systems
         WHEN flow.connectorCount >= 4 AND flow.dwScriptCount <= 2 THEN 'SYSTEM'
         WHEN flow.flow CONTAINS 'db' OR flow.flow CONTAINS 'database' OR flow.flow CONTAINS 'sql' THEN 'SYSTEM'
         WHEN flow.flow CONTAINS 'sap' OR flow.flow CONTAINS 'legacy' OR flow.flow CONTAINS 'mainframe' THEN 'SYSTEM'
         WHEN flow.flow CONTAINS 'file' OR flow.flow CONTAINS 'ftp' OR flow.flow CONTAINS 'sftp' THEN 'SYSTEM'
         WHEN app.name CONTAINS 'system' OR app.name CONTAINS 'backend' THEN 'SYSTEM'
         
         // PROCESS LAYER - Orchestration, business logic, multiple system coordination
         WHEN flow.connectorCount >= 3 AND flow.dwScriptCount >= 3 THEN 'PROCESS'
         WHEN flow.flow CONTAINS 'orchestrat' OR flow.flow CONTAINS 'workflow' OR flow.flow CONTAINS 'process' THEN 'PROCESS'
         WHEN flow.flow CONTAINS 'business' OR flow.flow CONTAINS 'logic' OR flow.flow CONTAINS 'rule' THEN 'PROCESS'
         WHEN flow.isApiExposed = true AND flow.connectorCount >= 3 THEN 'PROCESS'
         WHEN app.name CONTAINS 'process' OR app.name CONTAINS 'orchestrat' THEN 'PROCESS'
         
         // DEFAULT CLASSIFICATION based on complexity
         WHEN flow.isApiExposed = true AND flow.finalStoryPoints <= 5 THEN 'EXPERIENCE'
         WHEN flow.connectorCount >= 3 THEN 'PROCESS'
         ELSE 'SYSTEM'
     END as detectedLayer,
     
     // Layer confidence score
     CASE 
         // High confidence indicators
         WHEN flow.flow CONTAINS 'api' AND flow.isApiExposed = true THEN 90
         WHEN flow.flow CONTAINS 'db' OR flow.flow CONTAINS 'database' THEN 85
         WHEN flow.flow CONTAINS 'orchestrat' OR flow.flow CONTAINS 'process' THEN 85
         WHEN app.name CONTAINS 'system' OR app.name CONTAINS 'backend' THEN 80
         WHEN app.name CONTAINS 'api' AND flow.isApiExposed = true THEN 80
         
         // Medium confidence indicators
         WHEN flow.isApiExposed = true AND flow.connectorCount <= 2 THEN 70
         WHEN flow.connectorCount >= 4 THEN 70
         WHEN flow.connectorCount >= 3 AND flow.dwScriptCount >= 3 THEN 75
         
         // Lower confidence - based on defaults
         ELSE 60
     END as layerConfidence

// Set layer properties on flows
SET flow.muleLayer = detectedLayer,
    flow.layerConfidence = layerConfidence,
    flow.layerClassifiedAt = datetime();

// =============================================================================
// SECTION 2: LAYER-SPECIFIC RISK ASSESSMENT
// =============================================================================

// 2.1 - Enhanced risk assessment considering layer characteristics
MATCH (flow:Flow)
WHERE flow.muleLayer IS NOT NULL AND flow.finalStoryPoints IS NOT NULL

WITH flow,
     // Layer-specific risk factors
     CASE flow.muleLayer
         // Experience layer risks
         WHEN 'EXPERIENCE' THEN 
             CASE 
                 WHEN flow.finalStoryPoints > 8 THEN 'HIGH_RISK'  // Too complex for experience layer
                 WHEN flow.connectorCount > 3 THEN 'MEDIUM_RISK'  // Too many connections for experience
                 WHEN flow.finalStoryPoints >= 5 THEN 'MEDIUM_RISK'
                 ELSE 'LOW_RISK'
             END
             
         // Process layer risks  
         WHEN 'PROCESS' THEN
             CASE 
                 WHEN flow.finalStoryPoints > 12 THEN 'HIGH_RISK'  // Very complex orchestration
                 WHEN flow.connectorCount >= 5 AND flow.dwScriptCount >= 4 THEN 'HIGH_RISK'  // Complex integration
                 WHEN flow.finalStoryPoints >= 8 THEN 'MEDIUM_RISK'
                 WHEN flow.finalStoryPoints < 5 THEN 'LOW_RISK'    // Simple process
                 ELSE 'MEDIUM_RISK'
             END
             
         // System layer risks
         WHEN 'SYSTEM' THEN
             CASE 
                 WHEN flow.connectorCount >= 5 THEN 'HIGH_RISK'    // Many system connections
                 WHEN flow.finalStoryPoints > 10 THEN 'HIGH_RISK'  // Complex system integration
                 WHEN flow.finalStoryPoints >= 6 THEN 'MEDIUM_RISK'
                 ELSE 'LOW_RISK'
             END
             
         ELSE 'MEDIUM_RISK'
     END as layerSpecificRisk

SET flow.layerSpecificRisk = layerSpecificRisk;

// =============================================================================
// SECTION 3: LAYER ANALYSIS RESULTS
// =============================================================================

// 3.1 - Layer distribution summary
MATCH (app:MuleApp)-[:HAS_FLOW]->(flow:Flow)
WHERE flow.muleLayer IS NOT NULL

RETURN flow.muleLayer as Layer,
       count(flow) as FlowCount,
       round(count(flow) * 100.0 / (SELECT count(*) FROM (MATCH (f:Flow) WHERE f.muleLayer IS NOT NULL RETURN f)), 1) as Percentage,
       round(avg(flow.layerConfidence), 1) as AvgConfidence,
       round(avg(flow.finalStoryPoints), 1) as AvgStoryPoints,
       sum(flow.finalStoryPoints) as TotalStoryPoints,
       min(flow.finalStoryPoints) as MinStoryPoints,
       max(flow.finalStoryPoints) as MaxStoryPoints,
       count(CASE WHEN flow.isApiExposed = true THEN 1 END) as ApiFlows,
       round(avg(flow.connectorCount), 1) as AvgConnectorCount,
       round(avg(flow.dwScriptCount), 1) as AvgDwScriptCount,
       
       // Layer characteristics
       CASE Layer
           WHEN 'EXPERIENCE' THEN 'External APIs, user interfaces, mobile endpoints'
           WHEN 'PROCESS' THEN 'Business orchestration, workflow coordination, complex logic'
           WHEN 'SYSTEM' THEN 'Database access, legacy systems, file processing'
           ELSE 'Unclassified layer'
       END as LayerDescription

ORDER BY CASE Layer 
    WHEN 'EXPERIENCE' THEN 1 
    WHEN 'PROCESS' THEN 2 
    WHEN 'SYSTEM' THEN 3 
    ELSE 4 
END;

// 3.2 - Application layer distribution
MATCH (app:MuleApp)-[:HAS_FLOW]->(flow:Flow)
WHERE flow.muleLayer IS NOT NULL

WITH app.name as Application,
     count(flow) as TotalFlows,
     count(CASE WHEN flow.muleLayer = 'EXPERIENCE' THEN 1 END) as ExperienceFlows,
     count(CASE WHEN flow.muleLayer = 'PROCESS' THEN 1 END) as ProcessFlows,
     count(CASE WHEN flow.muleLayer = 'SYSTEM' THEN 1 END) as SystemFlows,
     round(avg(flow.layerConfidence), 1) as AvgLayerConfidence

RETURN Application,
       TotalFlows,
       ExperienceFlows,
       ProcessFlows,
       SystemFlows,
       AvgLayerConfidence,
       
       // Calculate percentages
       round(ExperienceFlows * 100.0 / TotalFlows, 1) as ExperiencePercentage,
       round(ProcessFlows * 100.0 / TotalFlows, 1) as ProcessPercentage,
       round(SystemFlows * 100.0 / TotalFlows, 1) as SystemPercentage,
       
       // Determine primary application layer
       CASE 
           WHEN ExperienceFlows > ProcessFlows AND ExperienceFlows > SystemFlows THEN 'EXPERIENCE_APP'
           WHEN ProcessFlows > ExperienceFlows AND ProcessFlows > SystemFlows THEN 'PROCESS_APP'
           WHEN SystemFlows > ExperienceFlows AND SystemFlows > ProcessFlows THEN 'SYSTEM_APP'
           ELSE 'MIXED_LAYER_APP'
       END as PrimaryLayer,
       
       // Layer diversity index
       CASE 
           WHEN (ExperienceFlows > 0 AND ProcessFlows > 0 AND SystemFlows > 0) THEN 'HIGH_DIVERSITY'
           WHEN ((ExperienceFlows > 0 AND ProcessFlows > 0) OR 
                 (ProcessFlows > 0 AND SystemFlows > 0) OR 
                 (ExperienceFlows > 0 AND SystemFlows > 0)) THEN 'MEDIUM_DIVERSITY'
           ELSE 'LOW_DIVERSITY'
       END as LayerDiversity,
       
       // Migration recommendations
       CASE 
           WHEN ExperienceFlows > ProcessFlows AND ExperienceFlows > SystemFlows THEN 'Focus on API migration expertise'
           WHEN ProcessFlows > ExperienceFlows AND ProcessFlows > SystemFlows THEN 'Focus on orchestration and business logic'
           WHEN SystemFlows > ExperienceFlows AND SystemFlows > ProcessFlows THEN 'Focus on system integration and databases'
           ELSE 'Balanced approach across all layers'
       END as MigrationRecommendation

ORDER BY TotalFlows DESC;

// 3.3 - Layer-specific complexity analysis
MATCH (flow:Flow)
WHERE flow.muleLayer IS NOT NULL AND flow.finalStoryPoints IS NOT NULL

WITH flow.muleLayer as Layer,
     flow.finalStoryPoints as StoryPoints,
     flow.storyPointCategory as Category,
     flow.layerSpecificRisk as RiskLevel

RETURN Layer,
       Category,
       RiskLevel,
       count(*) as FlowCount,
       round(avg(StoryPoints), 1) as AvgStoryPoints,
       min(StoryPoints) as MinStoryPoints,
       max(StoryPoints) as MaxStoryPoints,
       
       // Layer-specific complexity expectations
       CASE 
           WHEN Layer = 'EXPERIENCE' AND StoryPoints > 8 THEN ' HIGH_FOR_EXPERIENCE'
           WHEN Layer = 'SYSTEM' AND StoryPoints < 3 THEN ' LOW_FOR_SYSTEM'
           WHEN Layer = 'PROCESS' AND StoryPoints < 5 THEN ' LOW_FOR_PROCESS'
           WHEN Layer = 'PROCESS' AND StoryPoints > 15 THEN ' VERY_HIGH_FOR_PROCESS'
           ELSE ' NORMAL_FOR_LAYER'
       END as ComplexityAlignment,
       
       // Risk expectations
       CASE 
           WHEN Layer = 'EXPERIENCE' AND RiskLevel = 'HIGH_RISK' THEN 'Review - Experience should be simpler'
           WHEN Layer = 'PROCESS' AND RiskLevel = 'LOW_RISK' THEN 'Review - Process usually more complex'
           WHEN Layer = 'SYSTEM' AND RiskLevel = 'HIGH_RISK' THEN 'Review - System complexity'
           ELSE 'Risk level appropriate'
       END as RiskAlignment

ORDER BY Layer, StoryPoints DESC;

// =============================================================================
// SECTION 4: LAYER VALIDATION AND QUALITY ASSESSMENT
// =============================================================================

// 4.1 - Layer detection quality assessment
MATCH (flow:Flow)
WHERE flow.muleLayer IS NOT NULL

WITH flow.muleLayer as Layer,
     count(flow) as TotalFlows,
     count(CASE WHEN flow.layerConfidence >= 80 THEN 1 END) as HighConfidenceFlows,
     count(CASE WHEN flow.layerConfidence >= 70 THEN 1 END) as MediumConfidenceFlows,
     count(CASE WHEN flow.layerConfidence < 70 THEN 1 END) as LowConfidenceFlows,
     round(avg(flow.layerConfidence), 1) as AvgConfidence

RETURN Layer,
       TotalFlows,
       HighConfidenceFlows,
       MediumConfidenceFlows,
       LowConfidenceFlows,
       AvgConfidence,
       
       // Quality percentages
       round(HighConfidenceFlows * 100.0 / TotalFlows, 1) as HighConfidencePercentage,
       round(MediumConfidenceFlows * 100.0 / TotalFlows, 1) as MediumConfidencePercentage,
       round(LowConfidenceFlows * 100.0 / TotalFlows, 1) as LowConfidencePercentage,
       
       // Quality assessment
       CASE 
           WHEN HighConfidenceFlows * 100.0 / TotalFlows >= 80 THEN ' EXCELLENT_DETECTION'
           WHEN MediumConfidenceFlows * 100.0 / TotalFlows >= 70 THEN '👍 GOOD_DETECTION'
           WHEN LowConfidenceFlows * 100.0 / TotalFlows <= 30 THEN ' FAIR_DETECTION'
           ELSE ' POOR_DETECTION'
       END as DetectionQuality

ORDER BY CASE Layer 
    WHEN 'EXPERIENCE' THEN 1 
    WHEN 'PROCESS' THEN 2 
    WHEN 'SYSTEM' THEN 3 
    ELSE 4 
END;

// 4.2 - Identify flows requiring manual review
MATCH (app:MuleApp)-[:HAS_FLOW]->(flow:Flow)
WHERE flow.muleLayer IS NOT NULL

WITH flow, app,
     // Manual review indicators
     CASE 
         WHEN flow.muleLayer = 'EXPERIENCE' AND flow.connectorCount >= 4 THEN 'REVIEW_EXP_HIGH_CONNECTORS'
         WHEN flow.muleLayer = 'EXPERIENCE' AND flow.finalStoryPoints > 8 THEN 'REVIEW_EXP_HIGH_COMPLEXITY'
         WHEN flow.muleLayer = 'SYSTEM' AND flow.isApiExposed = true AND flow.connectorCount <= 1 THEN 'REVIEW_SYS_SIMPLE_API'
         WHEN flow.muleLayer = 'PROCESS' AND flow.connectorCount <= 1 THEN 'REVIEW_PROC_LOW_INTEGRATION'
         WHEN flow.layerConfidence < 70 THEN 'REVIEW_LOW_CONFIDENCE'
         ELSE null
     END as reviewFlag

WHERE reviewFlag IS NOT NULL

RETURN app.name as Application,
       flow.flow as Flow,
       flow.muleLayer as DetectedLayer,
       flow.layerConfidence as Confidence,
       flow.finalStoryPoints as StoryPoints,
       flow.connectorCount as ConnectorCount,
       flow.dwScriptCount as DwScriptCount,
       flow.isApiExposed as IsAPI,
       flow.layerSpecificRisk as RiskLevel,
       reviewFlag as ReviewReason,
       
       // Layer suggestions
       CASE reviewFlag
           WHEN 'REVIEW_EXP_HIGH_CONNECTORS' THEN 'Consider PROCESS layer'
           WHEN 'REVIEW_EXP_HIGH_COMPLEXITY' THEN 'Consider PROCESS layer'
           WHEN 'REVIEW_SYS_SIMPLE_API' THEN 'Consider EXPERIENCE layer'
           WHEN 'REVIEW_PROC_LOW_INTEGRATION' THEN 'Consider SYSTEM or EXPERIENCE layer'
           WHEN 'REVIEW_LOW_CONFIDENCE' THEN 'Manual classification needed'
           ELSE 'Review classification'
       END as Suggestion

ORDER BY flow.layerConfidence ASC, flow.finalStoryPoints DESC;

// =============================================================================
// SECTION 5: LAYER EXPORT DATA
// =============================================================================

// 5.1 - Export layer analysis for Excel
MATCH (app:MuleApp)-[:HAS_FLOW]->(flow:Flow)
WHERE flow.muleLayer IS NOT NULL

RETURN app.name as Application,
       flow.flow as FlowName,
       flow.muleLayer as Layer,
       flow.layerConfidence as Confidence,
       flow.layerSpecificRisk as RiskLevel,
       flow.finalStoryPoints as StoryPoints,
       flow.storyPointCategory as Category,
       flow.connectorCount as ConnectorCount,
       flow.dwScriptCount as DwScriptCount,
       flow.isApiExposed as IsApiExposed,
       flow.layerClassifiedAt as ClassifiedAt,
       
       // Layer characteristics
       CASE flow.muleLayer
           WHEN 'EXPERIENCE' THEN 'External APIs, user interfaces, mobile endpoints'
           WHEN 'PROCESS' THEN 'Business orchestration, workflow coordination, complex logic'
           WHEN 'SYSTEM' THEN 'Database access, legacy systems, file processing'
           ELSE 'Unclassified layer'
       END as LayerDescription,
       
       // Team recommendations
       CASE flow.muleLayer
           WHEN 'EXPERIENCE' THEN 'Senior Team - API design expertise'
           WHEN 'PROCESS' THEN 'Expert Team - orchestration expertise'
           WHEN 'SYSTEM' THEN 'Standard Team - system integration'
           ELSE 'Review team assignment'
       END as RecommendedTeam,
       
       // Sprint phase recommendations
       CASE flow.muleLayer
           WHEN 'EXPERIENCE' THEN 'Phase 3 - API Delivery (Sprints 9-12)'
           WHEN 'PROCESS' THEN 'Phase 2 - Orchestration (Sprints 5-8)'
           WHEN 'SYSTEM' THEN 'Phase 1 - Foundation (Sprints 1-4)'
           ELSE 'Review sprint assignment'
       END as RecommendedPhase

ORDER BY flow.muleLayer, flow.layerConfidence DESC, flow.finalStoryPoints DESC;

// =============================================================================
// SECTION 6: LAYER ANALYSIS SUMMARY
// =============================================================================

// 6.1 - Overall layer analysis summary
MATCH (flow:Flow)
WHERE flow.muleLayer IS NOT NULL

WITH count(flow) as totalFlows,
     count(CASE WHEN flow.muleLayer = 'EXPERIENCE' THEN 1 END) as experienceFlows,
     count(CASE WHEN flow.muleLayer = 'PROCESS' THEN 1 END) as processFlows,
     count(CASE WHEN flow.muleLayer = 'SYSTEM' THEN 1 END) as systemFlows,
     count(CASE WHEN flow.layerConfidence >= 80 THEN 1 END) as highConfidenceFlows,
     count(CASE WHEN flow.layerConfidence < 70 THEN 1 END) as lowConfidenceFlows,
     count(CASE WHEN flow.layerSpecificRisk = 'HIGH_RISK' THEN 1 END) as highRiskFlows,
     round(avg(flow.layerConfidence), 1) as avgConfidence

RETURN 'LAYER_ANALYSIS_SUMMARY' as AnalysisType,
       totalFlows as TotalFlows,
       experienceFlows as ExperienceFlows,
       processFlows as ProcessFlows,
       systemFlows as SystemFlows,
       highConfidenceFlows as HighConfidenceFlows,
       lowConfidenceFlows as LowConfidenceFlows,
       highRiskFlows as HighRiskFlows,
       avgConfidence as AvgConfidence,
       
       // Layer distribution
       round(experienceFlows * 100.0 / totalFlows, 1) as ExperiencePercentage,
       round(processFlows * 100.0 / totalFlows, 1) as ProcessPercentage,
       round(systemFlows * 100.0 / totalFlows, 1) as SystemPercentage,
       
       // Quality metrics
       round(highConfidenceFlows * 100.0 / totalFlows, 1) as HighConfidencePercentage,
       round(lowConfidenceFlows * 100.0 / totalFlows, 1) as LowConfidencePercentage,
       round(highRiskFlows * 100.0 / totalFlows, 1) as HighRiskPercentage,
       
       // Overall assessment
       CASE 
           WHEN highConfidenceFlows * 100.0 / totalFlows >= 80 THEN ' EXCELLENT_LAYER_DETECTION'
           WHEN highConfidenceFlows * 100.0 / totalFlows >= 70 THEN '👍 GOOD_LAYER_DETECTION'
           WHEN lowConfidenceFlows * 100.0 / totalFlows <= 30 THEN ' FAIR_LAYER_DETECTION'
           ELSE ' POOR_LAYER_DETECTION'
       END as OverallQuality,
       
       // Recommendations
       CASE 
           WHEN lowConfidenceFlows * 100.0 / totalFlows > 30 THEN 'Review low confidence flows manually'
           WHEN highRiskFlows * 100.0 / totalFlows > 20 THEN 'Focus on high risk flows in planning'
           ELSE 'Layer detection quality is good - proceed with layer-aware assignments'
       END as Recommendation; 