// STANDALONE RISK ANALYSIS
// Independent script for comprehensive risk assessment and analysis of Mule flows

// =============================================================================
// SECTION 1: RISK ASSESSMENT SETUP
// =============================================================================

// 1.1 - Clean any existing risk data
MATCH (flow:Flow) 
REMOVE flow.riskLevel, flow.riskScore, flow.riskFactors, flow.riskAnalyzedAt, flow.migrationRisk, flow.technicalRisk, flow.businessRisk;

// 1.2 - Calculate comprehensive risk scores
MATCH (flow:Flow)
WHERE flow.finalStoryPoints IS NOT NULL

WITH flow,
     // Technical complexity risk
     CASE 
         WHEN flow.finalStoryPoints >= 13 THEN 4  // Very high complexity
         WHEN flow.finalStoryPoints >= 8 THEN 3   // High complexity
         WHEN flow.finalStoryPoints >= 5 THEN 2   // Medium complexity
         ELSE 1                                   // Low complexity
     END as complexityRisk,
     
     // Connector count risk
     CASE 
         WHEN flow.connectorCount >= 5 THEN 4     // Very high integration
         WHEN flow.connectorCount >= 3 THEN 3     // High integration
         WHEN flow.connectorCount >= 2 THEN 2     // Medium integration
         ELSE 1                                   // Low integration
     END as integrationRisk,
     
     // DataWeave transformation risk
     CASE 
         WHEN flow.dwScriptCount >= 4 THEN 4      // Very high transformation
         WHEN flow.dwScriptCount >= 3 THEN 3      // High transformation
         WHEN flow.dwScriptCount >= 2 THEN 2      // Medium transformation
         ELSE 1                                   // Low transformation
     END as transformationRisk,
     
     // API exposure risk
     CASE 
         WHEN flow.isApiExposed = true THEN 3     // Public interface risk
         ELSE 1                                   // Internal flow
     END as exposureRisk,
     
     // Business criticality risk (inferred from story points and API exposure)
     CASE 
         WHEN flow.isApiExposed = true AND flow.finalStoryPoints >= 8 THEN 4  // Critical API
         WHEN flow.isApiExposed = true AND flow.finalStoryPoints >= 5 THEN 3  // Important API
         WHEN flow.finalStoryPoints >= 13 THEN 3                              // Complex internal
         WHEN flow.finalStoryPoints >= 8 THEN 2                               // Medium internal
         ELSE 1                                                               // Simple flow
     END as businessRisk

WITH flow, complexityRisk, integrationRisk, transformationRisk, exposureRisk, businessRisk,
     // Calculate overall risk score (1-20 scale)
     complexityRisk + integrationRisk + transformationRisk + exposureRisk + businessRisk as totalRiskScore

WITH flow, complexityRisk, integrationRisk, transformationRisk, exposureRisk, businessRisk, totalRiskScore,
     // Determine risk level based on total score
     CASE 
         WHEN totalRiskScore >= 16 THEN 'CRITICAL_RISK'    // 16-20: Critical
         WHEN totalRiskScore >= 13 THEN 'HIGH_RISK'        // 13-15: High
         WHEN totalRiskScore >= 10 THEN 'MEDIUM_RISK'      // 10-12: Medium
         WHEN totalRiskScore >= 7 THEN 'LOW_RISK'          // 7-9: Low
         ELSE 'MINIMAL_RISK'                               // 5-6: Minimal
     END as riskLevel,
     
     // Create risk factors array
     [
         CASE WHEN complexityRisk >= 3 THEN 'HIGH_COMPLEXITY' ELSE null END,
         CASE WHEN integrationRisk >= 3 THEN 'HIGH_INTEGRATION' ELSE null END,
         CASE WHEN transformationRisk >= 3 THEN 'HIGH_TRANSFORMATION' ELSE null END,
         CASE WHEN exposureRisk >= 3 THEN 'API_EXPOSURE' ELSE null END,
         CASE WHEN businessRisk >= 3 THEN 'BUSINESS_CRITICAL' ELSE null END
     ] as riskFactorsList

SET flow.riskLevel = riskLevel,
    flow.riskScore = totalRiskScore,
    flow.riskFactors = [f IN riskFactorsList WHERE f IS NOT NULL],
    flow.riskAnalyzedAt = datetime(),
    flow.technicalRisk = complexityRisk + integrationRisk + transformationRisk,
    flow.businessRisk = businessRisk + exposureRisk,
    flow.migrationRisk = CASE 
        WHEN totalRiskScore >= 16 THEN 'VERY_HIGH_RISK'
        WHEN totalRiskScore >= 13 THEN 'HIGH_RISK'
        WHEN totalRiskScore >= 10 THEN 'MEDIUM_RISK'
        ELSE 'LOW_RISK'
    END;

// =============================================================================
// SECTION 2: RISK DISTRIBUTION ANALYSIS
// =============================================================================

// 2.1 - Overall risk distribution summary
MATCH (flow:Flow)
WHERE flow.riskLevel IS NOT NULL

RETURN flow.riskLevel as RiskLevel,
       count(flow) as FlowCount,
       round(count(flow) * 100.0 / (SELECT count(*) FROM (MATCH (f:Flow) WHERE f.riskLevel IS NOT NULL RETURN f)), 1) as Percentage,
       round(avg(flow.riskScore), 1) as AvgRiskScore,
       round(avg(flow.finalStoryPoints), 1) as AvgStoryPoints,
       round(avg(flow.connectorCount), 1) as AvgConnectorCount,
       round(avg(flow.dwScriptCount), 1) as AvgDwScriptCount,
       count(CASE WHEN flow.isApiExposed = true THEN 1 END) as ApiFlows,
       sum(flow.finalStoryPoints) as TotalStoryPoints,
       
       // Risk characteristics
       CASE flow.riskLevel
           WHEN 'CRITICAL_RISK' THEN 'Highest priority, expert team required, extensive testing'
           WHEN 'HIGH_RISK' THEN 'High priority, senior team recommended, thorough testing'
           WHEN 'MEDIUM_RISK' THEN 'Standard priority, regular team assignment, normal testing'
           WHEN 'LOW_RISK' THEN 'Lower priority, junior team capable, basic testing'
           WHEN 'MINIMAL_RISK' THEN 'Lowest priority, straightforward migration'
           ELSE 'Risk level not assessed'
       END as RiskDescription,
       
       // Migration recommendations
       CASE flow.riskLevel
           WHEN 'CRITICAL_RISK' THEN 'Early sprint assignment, dedicated expert resources'
           WHEN 'HIGH_RISK' THEN 'Early to mid sprint assignment, senior developer'
           WHEN 'MEDIUM_RISK' THEN 'Flexible sprint assignment, standard developer'
           WHEN 'LOW_RISK' THEN 'Later sprint assignment, junior developer possible'
           WHEN 'MINIMAL_RISK' THEN 'Final sprints, junior developer suitable'
           ELSE 'Review risk assessment'
       END as MigrationRecommendation

ORDER BY CASE flow.riskLevel
    WHEN 'CRITICAL_RISK' THEN 1
    WHEN 'HIGH_RISK' THEN 2
    WHEN 'MEDIUM_RISK' THEN 3
    WHEN 'LOW_RISK' THEN 4
    WHEN 'MINIMAL_RISK' THEN 5
    ELSE 6
END;

// 2.2 - Application-level risk analysis
MATCH (app:MuleApp)-[:HAS_FLOW]->(flow:Flow)
WHERE flow.riskLevel IS NOT NULL

WITH app.name as Application,
     count(flow) as TotalFlows,
     count(CASE WHEN flow.riskLevel IN ['CRITICAL_RISK', 'HIGH_RISK'] THEN 1 END) as HighRiskFlows,
     count(CASE WHEN flow.riskLevel = 'MEDIUM_RISK' THEN 1 END) as MediumRiskFlows,
     count(CASE WHEN flow.riskLevel IN ['LOW_RISK', 'MINIMAL_RISK'] THEN 1 END) as LowRiskFlows,
     round(avg(flow.riskScore), 1) as AvgRiskScore,
     sum(flow.finalStoryPoints) as TotalStoryPoints,
     max(flow.riskScore) as MaxRiskScore

RETURN Application,
       TotalFlows,
       HighRiskFlows,
       MediumRiskFlows,
       LowRiskFlows,
       AvgRiskScore,
       TotalStoryPoints,
       MaxRiskScore,
       
       // Risk percentages
       round(HighRiskFlows * 100.0 / TotalFlows, 1) as HighRiskPercentage,
       round(MediumRiskFlows * 100.0 / TotalFlows, 1) as MediumRiskPercentage,
       round(LowRiskFlows * 100.0 / TotalFlows, 1) as LowRiskPercentage,
       
       // Application risk profile
       CASE 
           WHEN HighRiskFlows * 100.0 / TotalFlows >= 40 THEN 'HIGH_RISK_APPLICATION'
           WHEN HighRiskFlows * 100.0 / TotalFlows >= 20 THEN 'MEDIUM_RISK_APPLICATION'
           ELSE 'LOW_RISK_APPLICATION'
       END as ApplicationRiskProfile,
       
       // Migration complexity
       CASE 
           WHEN HighRiskFlows >= 5 OR MaxRiskScore >= 16 THEN 'COMPLEX_MIGRATION'
           WHEN HighRiskFlows >= 2 OR MaxRiskScore >= 13 THEN 'MODERATE_MIGRATION'
           ELSE 'SIMPLE_MIGRATION'
       END as MigrationComplexity,
       
       // Resource recommendations
       CASE 
           WHEN HighRiskFlows * 100.0 / TotalFlows >= 40 THEN 'Requires expert team, early sprints'
           WHEN HighRiskFlows * 100.0 / TotalFlows >= 20 THEN 'Requires senior developers, mixed sprints'
           ELSE 'Standard team sufficient, flexible scheduling'
       END as ResourceRecommendation

ORDER BY HighRiskPercentage DESC, TotalStoryPoints DESC;

// 2.3 - Risk factor analysis
MATCH (flow:Flow)
WHERE flow.riskFactors IS NOT NULL AND size(flow.riskFactors) > 0

UNWIND flow.riskFactors as riskFactor
WITH riskFactor, count(flow) as flowCount, 
     round(avg(flow.riskScore), 1) as avgRiskScore,
     round(avg(flow.finalStoryPoints), 1) as avgStoryPoints

RETURN riskFactor as RiskFactor,
       flowCount as FlowCount,
       avgRiskScore as AvgRiskScore,
       avgStoryPoints as AvgStoryPoints,
       
       // Risk factor description
       CASE riskFactor
           WHEN 'HIGH_COMPLEXITY' THEN 'Complex flows requiring expert knowledge'
           WHEN 'HIGH_INTEGRATION' THEN 'Multiple system connections to manage'
           WHEN 'HIGH_TRANSFORMATION' THEN 'Complex data transformation logic'
           WHEN 'API_EXPOSURE' THEN 'Public APIs requiring careful testing'
           WHEN 'BUSINESS_CRITICAL' THEN 'Critical business functionality'
           ELSE 'Unknown risk factor'
       END as RiskFactorDescription,
       
       // Mitigation strategies
       CASE riskFactor
           WHEN 'HIGH_COMPLEXITY' THEN 'Assign to expert team, create detailed design'
           WHEN 'HIGH_INTEGRATION' THEN 'Plan integration testing, map dependencies'
           WHEN 'HIGH_TRANSFORMATION' THEN 'Review DataWeave logic, unit test thoroughly'
           WHEN 'API_EXPOSURE' THEN 'Contract testing, backward compatibility checks'
           WHEN 'BUSINESS_CRITICAL' THEN 'Business stakeholder involvement, UAT'
           ELSE 'Standard mitigation approach'
       END as MitigationStrategy

ORDER BY flowCount DESC;

// =============================================================================
// SECTION 3: DETAILED RISK BREAKDOWN
// =============================================================================

// 3.1 - High-risk flows detailed analysis
MATCH (app:MuleApp)-[:HAS_FLOW]->(flow:Flow)
WHERE flow.riskLevel IN ['CRITICAL_RISK', 'HIGH_RISK']

RETURN app.name as Application,
       flow.flow as FlowName,
       flow.riskLevel as RiskLevel,
       flow.riskScore as RiskScore,
       flow.finalStoryPoints as StoryPoints,
       flow.connectorCount as ConnectorCount,
       flow.dwScriptCount as DwScriptCount,
       flow.isApiExposed as IsApiExposed,
       flow.riskFactors as RiskFactors,
       flow.technicalRisk as TechnicalRisk,
       flow.businessRisk as BusinessRisk,
       
       // Specific risk analysis
       CASE 
           WHEN 'HIGH_COMPLEXITY' IN flow.riskFactors AND 'HIGH_INTEGRATION' IN flow.riskFactors THEN 'Complex integration requiring expert team'
           WHEN 'API_EXPOSURE' IN flow.riskFactors AND 'BUSINESS_CRITICAL' IN flow.riskFactors THEN 'Critical API requiring careful migration'
           WHEN 'HIGH_TRANSFORMATION' IN flow.riskFactors THEN 'Complex data transformation requiring review'
           WHEN flow.riskScore >= 16 THEN 'Maximum risk - requires special attention'
           ELSE 'High risk flow requiring senior expertise'
       END as RiskAnalysis,
       
       // Priority recommendations
       CASE flow.riskLevel
           WHEN 'CRITICAL_RISK' THEN 'Sprint 1-2: Immediate priority'
           WHEN 'HIGH_RISK' THEN 'Sprint 1-4: Early priority'
           ELSE 'Sprint 1-6: Medium priority'
       END as SprintPriority,
       
       // Team recommendations
       CASE 
           WHEN flow.riskScore >= 16 THEN 'Expert Team: Mandatory assignment'
           WHEN 'API_EXPOSURE' IN flow.riskFactors THEN 'Senior Team: API expertise required'
           WHEN 'HIGH_COMPLEXITY' IN flow.riskFactors THEN 'Expert Team: Complex logic handling'
           ELSE 'Senior Team: High-risk flow management'
       END as TeamRecommendation

ORDER BY flow.riskScore DESC, flow.finalStoryPoints DESC;

// 3.2 - Risk distribution by story point category
MATCH (flow:Flow)
WHERE flow.riskLevel IS NOT NULL AND flow.storyPointCategory IS NOT NULL

WITH flow.storyPointCategory as Category,
     flow.riskLevel as RiskLevel,
     count(flow) as FlowCount,
     round(avg(flow.riskScore), 1) as AvgRiskScore

RETURN Category,
       RiskLevel,
       FlowCount,
       AvgRiskScore,
       
       // Risk expectation alignment
       CASE 
           WHEN Category = 'EPIC' AND RiskLevel NOT IN ['CRITICAL_RISK', 'HIGH_RISK'] THEN ' EPIC_LOW_RISK'
           WHEN Category = 'TINY' AND RiskLevel IN ['CRITICAL_RISK', 'HIGH_RISK'] THEN ' TINY_HIGH_RISK'
           WHEN Category = 'SMALL' AND RiskLevel = 'CRITICAL_RISK' THEN ' SMALL_CRITICAL_RISK'
           WHEN Category = 'VERY_LARGE' AND RiskLevel = 'MINIMAL_RISK' THEN ' LARGE_MINIMAL_RISK'
           ELSE ' RISK_ALIGNED'
       END as RiskAlignment,
       
       // Recommendations for misaligned cases
       CASE 
           WHEN Category = 'EPIC' AND RiskLevel NOT IN ['CRITICAL_RISK', 'HIGH_RISK'] THEN 'Review: Epic should be high risk'
           WHEN Category = 'TINY' AND RiskLevel IN ['CRITICAL_RISK', 'HIGH_RISK'] THEN 'Review: Tiny flow high risk unusual'
           ELSE 'Risk level appropriate for story size'
       END as Recommendation

ORDER BY CASE Category 
    WHEN 'EPIC' THEN 1 
    WHEN 'VERY_LARGE' THEN 2 
    WHEN 'LARGE' THEN 3 
    WHEN 'MEDIUM' THEN 4 
    WHEN 'SMALL' THEN 5 
    WHEN 'TINY' THEN 6 
    ELSE 7 
END,
CASE RiskLevel
    WHEN 'CRITICAL_RISK' THEN 1
    WHEN 'HIGH_RISK' THEN 2
    WHEN 'MEDIUM_RISK' THEN 3
    WHEN 'LOW_RISK' THEN 4
    WHEN 'MINIMAL_RISK' THEN 5
    ELSE 6
END;

// =============================================================================
// SECTION 4: RISK MITIGATION STRATEGIES
// =============================================================================

// 4.1 - Risk mitigation recommendations by risk level
MATCH (flow:Flow)
WHERE flow.riskLevel IS NOT NULL

WITH flow.riskLevel as RiskLevel, 
     count(flow) as FlowCount,
     collect(flow.riskFactors) as allRiskFactors

UNWIND allRiskFactors as riskFactorList
UNWIND riskFactorList as riskFactor
WITH RiskLevel, FlowCount, riskFactor, count(*) as factorCount
WHERE riskFactor IS NOT NULL

WITH RiskLevel, FlowCount, collect({factor: riskFactor, count: factorCount}) as riskFactorSummary

RETURN RiskLevel,
       FlowCount,
       riskFactorSummary as CommonRiskFactors,
       
       // Risk level specific strategies
       CASE RiskLevel
           WHEN 'CRITICAL_RISK' THEN [
               'Assign to Expert Team only',
               'Schedule in first 2 sprints',
               'Create detailed technical design',
               'Implement comprehensive testing strategy',
               'Business stakeholder involvement required',
               'Consider proof of concept first'
           ]
           WHEN 'HIGH_RISK' THEN [
               'Assign to Senior or Expert Team',
               'Schedule in first 4 sprints',
               'Create technical design document',
               'Implement thorough testing',
               'Regular progress reviews'
           ]
           WHEN 'MEDIUM_RISK' THEN [
               'Standard team assignment acceptable',
               'Flexible sprint scheduling',
               'Standard testing approach',
               'Regular code reviews'
           ]
           WHEN 'LOW_RISK' THEN [
               'Junior team members can participate',
               'Later sprint assignment possible',
               'Basic testing sufficient',
               'Pair programming recommended'
           ]
           WHEN 'MINIMAL_RISK' THEN [
               'Junior team assignment suitable',
               'Final sprint assignment acceptable',
               'Standard testing approach',
               'Good candidate for learning'
           ]
           ELSE ['Review risk assessment']
       END as MitigationStrategies,
       
       // Testing recommendations
       CASE RiskLevel
           WHEN 'CRITICAL_RISK' THEN 'Unit + Integration + System + UAT + Performance'
           WHEN 'HIGH_RISK' THEN 'Unit + Integration + System + UAT'
           WHEN 'MEDIUM_RISK' THEN 'Unit + Integration + System'
           WHEN 'LOW_RISK' THEN 'Unit + Integration'
           WHEN 'MINIMAL_RISK' THEN 'Unit Testing'
           ELSE 'Standard Testing'
       END as TestingStrategy

ORDER BY CASE RiskLevel
    WHEN 'CRITICAL_RISK' THEN 1
    WHEN 'HIGH_RISK' THEN 2
    WHEN 'MEDIUM_RISK' THEN 3
    WHEN 'LOW_RISK' THEN 4
    WHEN 'MINIMAL_RISK' THEN 5
    ELSE 6
END;

// =============================================================================
// SECTION 5: RISK EXPORT DATA
// =============================================================================

// 5.1 - Export comprehensive risk analysis for Excel
MATCH (app:MuleApp)-[:HAS_FLOW]->(flow:Flow)
WHERE flow.riskLevel IS NOT NULL

RETURN app.name as Application,
       flow.flow as FlowName,
       flow.riskLevel as RiskLevel,
       flow.riskScore as RiskScore,
       flow.finalStoryPoints as StoryPoints,
       flow.storyPointCategory as Category,
       flow.connectorCount as ConnectorCount,
       flow.dwScriptCount as DwScriptCount,
       flow.isApiExposed as IsApiExposed,
       flow.technicalRisk as TechnicalRisk,
       flow.businessRisk as BusinessRisk,
       flow.riskFactors as RiskFactors,
       flow.riskAnalyzedAt as AnalyzedAt,
       
       // Risk descriptions
       CASE flow.riskLevel
           WHEN 'CRITICAL_RISK' THEN 'Maximum risk requiring expert team and early sprint'
           WHEN 'HIGH_RISK' THEN 'High risk requiring senior team and early assignment'
           WHEN 'MEDIUM_RISK' THEN 'Medium risk with standard team and flexible timing'
           WHEN 'LOW_RISK' THEN 'Low risk suitable for junior team and later sprints'
           WHEN 'MINIMAL_RISK' THEN 'Minimal risk suitable for learning and final sprints'
           ELSE 'Risk level not determined'
       END as RiskDescription,
       
       // Team recommendations
       CASE 
           WHEN flow.riskScore >= 16 THEN 'Expert Team Required'
           WHEN flow.riskScore >= 13 THEN 'Senior Team Recommended'
           WHEN flow.riskScore >= 10 THEN 'Standard Team Acceptable'
           ELSE 'Junior Team Suitable'
       END as TeamRecommendation,
       
       // Sprint priority
       CASE flow.riskLevel
           WHEN 'CRITICAL_RISK' THEN 'Sprint 1-2'
           WHEN 'HIGH_RISK' THEN 'Sprint 1-4'
           WHEN 'MEDIUM_RISK' THEN 'Sprint 3-8'
           WHEN 'LOW_RISK' THEN 'Sprint 6-10'
           WHEN 'MINIMAL_RISK' THEN 'Sprint 9-12'
           ELSE 'Review Priority'
       END as SprintPriority,
       
       // Testing requirements
       CASE flow.riskLevel
           WHEN 'CRITICAL_RISK' THEN 'Comprehensive testing required'
           WHEN 'HIGH_RISK' THEN 'Thorough testing required'
           WHEN 'MEDIUM_RISK' THEN 'Standard testing sufficient'
           WHEN 'LOW_RISK' THEN 'Basic testing sufficient'
           WHEN 'MINIMAL_RISK' THEN 'Minimal testing required'
           ELSE 'Standard testing'
       END as TestingRequirements

ORDER BY flow.riskScore DESC, flow.finalStoryPoints DESC;

// =============================================================================
// SECTION 6: RISK ANALYSIS SUMMARY
// =============================================================================

// 6.1 - Overall risk analysis summary
MATCH (flow:Flow)
WHERE flow.riskLevel IS NOT NULL

WITH count(flow) as totalFlows,
     count(CASE WHEN flow.riskLevel IN ['CRITICAL_RISK', 'HIGH_RISK'] THEN 1 END) as highRiskFlows,
     count(CASE WHEN flow.riskLevel = 'MEDIUM_RISK' THEN 1 END) as mediumRiskFlows,
     count(CASE WHEN flow.riskLevel IN ['LOW_RISK', 'MINIMAL_RISK'] THEN 1 END) as lowRiskFlows,
     round(avg(flow.riskScore), 1) as avgRiskScore,
     max(flow.riskScore) as maxRiskScore,
     min(flow.riskScore) as minRiskScore,
     sum(flow.finalStoryPoints) as totalStoryPoints

RETURN 'RISK_ANALYSIS_SUMMARY' as AnalysisType,
       totalFlows as TotalFlows,
       highRiskFlows as HighRiskFlows,
       mediumRiskFlows as MediumRiskFlows,
       lowRiskFlows as LowRiskFlows,
       avgRiskScore as AvgRiskScore,
       maxRiskScore as MaxRiskScore,
       minRiskScore as MinRiskScore,
       totalStoryPoints as TotalStoryPoints,
       
       // Risk distribution percentages
       round(highRiskFlows * 100.0 / totalFlows, 1) as HighRiskPercentage,
       round(mediumRiskFlows * 100.0 / totalFlows, 1) as MediumRiskPercentage,
       round(lowRiskFlows * 100.0 / totalFlows, 1) as LowRiskPercentage,
       
       // Project risk assessment
       CASE 
           WHEN highRiskFlows * 100.0 / totalFlows >= 30 THEN 'HIGH_RISK_PROJECT'
           WHEN highRiskFlows * 100.0 / totalFlows >= 15 THEN 'MEDIUM_RISK_PROJECT'
           ELSE 'LOW_RISK_PROJECT'
       END as ProjectRiskLevel,
       
       // Resource requirements
       CASE 
           WHEN highRiskFlows >= 10 THEN 'Requires expert team for extended period'
           WHEN highRiskFlows >= 5 THEN 'Requires senior developers and careful planning'
           WHEN highRiskFlows >= 2 THEN 'Standard team with senior oversight'
           ELSE 'Standard team sufficient'
       END as ResourceRequirements,
       
       // Timeline recommendations
       CASE 
           WHEN highRiskFlows * 100.0 / totalFlows >= 30 THEN 'Consider extending timeline by 20-30%'
           WHEN highRiskFlows * 100.0 / totalFlows >= 15 THEN 'Consider extending timeline by 10-20%'
           ELSE 'Standard timeline appropriate'
       END as TimelineRecommendation,
       
       // Overall recommendations
       CASE 
           WHEN highRiskFlows * 100.0 / totalFlows >= 30 THEN 'High-risk project requiring expert team, extended timeline, and comprehensive risk mitigation'
           WHEN highRiskFlows * 100.0 / totalFlows >= 15 THEN 'Medium-risk project requiring senior expertise and careful planning'
           ELSE 'Low-risk project suitable for standard approach with normal timeline'
       END as OverallRecommendation; 