// MULE LAYER DETECTION AND CLASSIFICATION
// Analyzes flows to determine their architectural layer: Experience, Process, or System

// =============================================================================
// SECTION 1: LAYER DETECTION LOGIC
// =============================================================================

// 1.1 - Load planning configuration for threshold flexibility
MATCH (cfg:PlanningConfig {id:'DEFAULT'})
WITH cfg

// 1.2 - Analyze and classify flows by Mule architectural layer using a weighted scoring model
MATCH (app:MuleApp)-[:HAS_FLOW]->(flow:Flow)
WHERE flow.finalStoryPoints IS NOT NULL

// Optional steps linked to the flow for deeper signal extraction
OPTIONAL MATCH (flow)-[:HAS_STEP]->(st:Step)
WITH flow, app, collect(st) AS steps, cfg

// -------------------------------------------------------------------------
// APPLICATION-LEVEL LAYER HINT (derived from app name / description / property)
// -------------------------------------------------------------------------
OPTIONAL MATCH (app)-[:HAS_PROPERTY]->(prop:Property {key:'layerHint'})
WITH flow, app, steps,
     coalesce(prop.value,'')                                                AS layerHintProp,
     apoc.text.join([x IN [app.name, app.description] WHERE x IS NOT NULL], ' ') AS appText

WITH flow, app, steps,
     CASE
       WHEN layerHintProp =~ '(?i)experience' THEN 'EXPERIENCE'
       WHEN layerHintProp =~ '(?i)process'    THEN 'PROCESS'
       WHEN layerHintProp =~ '(?i)system'     THEN 'SYSTEM'
       WHEN appText   =~ '(?i).*\\b(api|ui|mobile)\\b.*'                THEN 'EXPERIENCE'
       WHEN appText   =~ '(?i).*\\b(orchestrat|workflow|process)\\b.*' THEN 'PROCESS'
       WHEN appText   =~ '(?i).*\\b(system|backend|db)\\b.*'           THEN 'SYSTEM'
       ELSE NULL
     END AS appLayerHint

// -------------------------------------------------------------------------
// STEP-TYPE WEIGHTS
// -------------------------------------------------------------------------
WITH flow, app, appLayerHint,
     reduce(e = 0, s IN steps | e + CASE WHEN s.type IN ['HTTP', 'APIKIT', 'REST_LISTENER'] THEN 2 ELSE 0 END) AS expStepPts,
     reduce(p = 0, s IN steps | p + CASE WHEN s.type IN ['CHOICE', 'SCATTER_GATHER', 'FLOW_REF', 'VM'] THEN 2 ELSE 0 END) AS procStepPts,
     reduce(y = 0, s IN steps | y + CASE WHEN s.type IN ['DB', 'SAP', 'FILE', 'FTP', 'JMS', 'SFTP'] THEN 2 ELSE 0 END) AS sysStepPts

// Continue with scoring model
WITH flow, app, appLayerHint,
     expStepPts, procStepPts, sysStepPts,
     
     // EXPERIENCE SCORE
     (
       (CASE WHEN flow.isApiExposed THEN 3 ELSE 0 END) +
       (CASE WHEN flow.connectorCount <= 2 THEN 2 ELSE 0 END) +
       (CASE WHEN flow.dwScriptCount <= 2 THEN 1 ELSE 0 END) +
       (CASE WHEN flow.flow =~ '(?i).*\\b(api|web|mobile|ui)\\b.*' THEN 2 ELSE 0 END) +
       expStepPts +
       (CASE WHEN appLayerHint = 'EXPERIENCE' THEN 3 ELSE 0 END)
     ) AS expScore,
     
     // PROCESS SCORE
     (
       (CASE WHEN flow.connectorCount >= 3 THEN 2 ELSE 0 END) +
       (CASE WHEN flow.dwScriptCount >= 3 THEN 2 ELSE 0 END) +
       (CASE WHEN flow.flow =~ '(?i).*\\b(orchestrat|workflow|process|business|logic|rule)\\b.*' THEN 2 ELSE 0 END) +
       procStepPts +
       (CASE WHEN appLayerHint = 'PROCESS' THEN 3 ELSE 0 END)
     ) AS procScore,
     
     // SYSTEM SCORE
     (
       (CASE WHEN flow.connectorCount >= 4 THEN 3 ELSE 0 END) +
       (CASE WHEN flow.flow =~ '(?i).*\\b(db|database|sql|file|ftp|sftp|sap|legacy|mainframe)\\b.*' THEN 2 ELSE 0 END) +
       (CASE WHEN app.name =~ '(?i).*\\b(system|backend)\\b.*' THEN 2 ELSE 0 END) +
       sysStepPts +
       (CASE WHEN appLayerHint = 'SYSTEM' THEN 3 ELSE 0 END)
     ) AS sysScore,
     
     flow, app

WITH flow, app, expScore, procScore, sysScore,
     // Resolve ties by story point heuristic
     CASE
        WHEN expScore = procScore AND expScore = sysScore THEN
             CASE 
                WHEN flow.finalStoryPoints <= 5 THEN 'EXPERIENCE'
                WHEN flow.finalStoryPoints <= 8 THEN 'PROCESS'
                ELSE 'SYSTEM'
             END
        ELSE
             CASE 
                WHEN expScore >= procScore AND expScore >= sysScore THEN 'EXPERIENCE'
                WHEN procScore >= sysScore THEN 'PROCESS'
                ELSE 'SYSTEM'
             END
     END AS detectedLayer,
     
     // Layer confidence score
     50 + ( (expScore + procScore + sysScore) * 5 ) as layerConfidence  // simple derived confidence

// Set layer properties on flows
SET flow.muleLayer = detectedLayer,
    flow.layerConfidence = layerConfidence,
    flow.layerClassifiedAt = datetime();

// =============================================================================
// SECTION 2: LAYER ANALYSIS AND VERIFICATION
// =============================================================================

// 2.1 - Layer distribution summary
MATCH (app:MuleApp)-[:HAS_FLOW]->(flow:Flow)
WHERE flow.muleLayer IS NOT NULL

WITH flow.muleLayer as Layer,
     count(flow) as FlowCount,
     round(avg(flow.layerConfidence), 1) as AvgConfidence,
     round(avg(flow.finalStoryPoints), 1) as AvgStoryPoints,
     sum(flow.finalStoryPoints) as TotalStoryPoints,
     min(flow.finalStoryPoints) as MinStoryPoints,
     max(flow.finalStoryPoints) as MaxStoryPoints,
     count(CASE WHEN flow.isApiExposed = true THEN 1 END) as ApiFlows,
     round(avg(flow.connectorCount), 1) as AvgConnectorCount,
     round(avg(flow.dwScriptCount), 1) as AvgDwScriptCount

// Calculate total flows for percentage calculation
CALL {
    MATCH (f:Flow) WHERE f.muleLayer IS NOT NULL
    RETURN count(f) as totalFlows
}

RETURN Layer,
       FlowCount,
       round(FlowCount * 100.0 / totalFlows, 1) as Percentage,
       AvgConfidence,
       AvgStoryPoints,
       TotalStoryPoints,
       MinStoryPoints,
       MaxStoryPoints,
       ApiFlows,
       AvgConnectorCount,
       AvgDwScriptCount

ORDER BY CASE Layer 
    WHEN 'EXPERIENCE' THEN 1 
    WHEN 'PROCESS' THEN 2 
    WHEN 'SYSTEM' THEN 3 
    ELSE 4 
END;

// 2.2 - Application layer distribution
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
       END as LayerDiversity

ORDER BY TotalFlows DESC;

// 2.3 - Layer-specific complexity analysis
MATCH (flow:Flow)
WHERE flow.muleLayer IS NOT NULL AND flow.finalStoryPoints IS NOT NULL

WITH flow.muleLayer as Layer,
     flow.finalStoryPoints as StoryPoints,
     flow.storyPointCategory as Category

RETURN Layer,
       Category,
       count(*) as FlowCount,
       StoryPoints,
       
       // Layer-specific complexity expectations
       CASE 
           WHEN Layer = 'EXPERIENCE' AND StoryPoints > 8 THEN ' HIGH_FOR_EXPERIENCE'
           WHEN Layer = 'SYSTEM' AND StoryPoints < 3 THEN ' LOW_FOR_SYSTEM'
           WHEN Layer = 'PROCESS' AND StoryPoints < 5 THEN ' LOW_FOR_PROCESS'
           WHEN Layer = 'PROCESS' AND StoryPoints > 15 THEN ' VERY_HIGH_FOR_PROCESS'
           ELSE ' NORMAL_FOR_LAYER'
       END as ComplexityAlignment

ORDER BY Layer, StoryPoints DESC;

// =============================================================================
// SECTION 3: LAYER-SPECIFIC RISK ASSESSMENT
// =============================================================================

// 3.1 - Enhanced risk assessment considering layer characteristics
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

// Show layer-specific risk distribution
MATCH (flow:Flow)
WHERE flow.layerSpecificRisk IS NOT NULL

WITH flow.muleLayer as Layer,
     flow.layerSpecificRisk as RiskLevel,
     count(flow) as FlowCount,
     round(avg(flow.finalStoryPoints), 1) as AvgStoryPoints,
     round(avg(flow.connectorCount), 1) as AvgConnectorCount,
     round(avg(flow.dwScriptCount), 1) as AvgDwScriptCount

// Calculate total flows per layer for percentage calculation
CALL {
    WITH Layer
    MATCH (f:Flow) WHERE f.muleLayer = Layer
    RETURN count(f) as layerTotal
}

RETURN Layer,
       RiskLevel,
       FlowCount,
       AvgStoryPoints,
       AvgConnectorCount,
       AvgDwScriptCount,
       round(FlowCount * 100.0 / layerTotal, 1) as PercentageInLayer

ORDER BY CASE Layer 
    WHEN 'EXPERIENCE' THEN 1 
    WHEN 'PROCESS' THEN 2 
    WHEN 'SYSTEM' THEN 3 
    ELSE 4 
END,
CASE RiskLevel 
    WHEN 'HIGH_RISK' THEN 1 
    WHEN 'MEDIUM_RISK' THEN 2 
    WHEN 'LOW_RISK' THEN 3 
    ELSE 4 
END;

// =============================================================================
// SECTION 4: LAYER VALIDATION AND MANUAL OVERRIDE
// =============================================================================

// 4.1 - Identify flows that might be misclassified
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
// SECTION 5: MANUAL LAYER OVERRIDE TEMPLATE
// =============================================================================

// 5.1 - Template for manual layer corrections
// Use this pattern to manually correct layer classifications

/*
// Manual layer correction example:
MATCH (app:MuleApp {name: 'YourAppName'})-[:HAS_FLOW]->(flow:Flow {flow: 'YourFlowName'})
SET flow.muleLayer = 'CORRECT_LAYER',  // EXPERIENCE, PROCESS, or SYSTEM
    flow.layerConfidence = 95,          // High confidence for manual classification
    flow.manuallyClassified = true,
    flow.manualClassificationReason = 'Business requirement/Architecture decision/etc';
*/

// 5.2 - Verify manual classifications
MATCH (flow:Flow)
WHERE flow.manuallyClassified = true

RETURN count(flow) as ManuallyClassifiedFlows,
       collect(DISTINCT flow.muleLayer) as ManualLayers,
       'Manual classifications completed' as Status; 