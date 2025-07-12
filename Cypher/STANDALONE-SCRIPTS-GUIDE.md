# STANDALONE SCRIPTS GUIDE
## Independent Analysis Tools for Mule Application Complexity Analysis and project planning

This guide provides information about **standalone scripts** that can be used independently for specific analysis tasks. Each script is self-contained and doesn't require the full workflow.

---

##  STANDALONE SCRIPTS OVERVIEW

### **1.  COSINE SIMILARITY ANALYSIS**
**File:** `standalone-similarity-analysis.cypher`

**Purpose:** Advanced similarity analysis using cosine similarity for flow structures and applications
**Use When:** You want sophisticated pattern detection and application-level similarity analysis
**Requires:** Flows with `finalStoryPoints` and flow steps data

**What it does:**
-  Creates 15-dimensional flow structure vectors
-  Calculates cosine similarity between flows (0.7+ threshold)
-  Performs application-level cosine similarity (0.8+ threshold)
-  Analyzes flow patterns: HTTP, database, transform, validation, choice, foreach, async, error, log, set steps
-  Provides template-based migration strategies
-  Estimates up to 50%+ efficiency gains for near-identical patterns
-  Exports comprehensive similarity data for Excel

### **2.  LAYER ANALYSIS**
**File:** `standalone-layer-analysis.cypher`

**Purpose:** Detect and analyze Mule 3-layer architecture (Experience, Process, System)
**Use When:** You want to understand architectural layers and optimize team assignments
**Requires:** Flows with `finalStoryPoints` property

**What it does:**
-  Detects Experience, Process, and System layer flows
-  Calculates layer confidence scores
-  Performs layer-specific risk assessment
-  Provides team and sprint recommendations
-  Exports layer data for Excel

### **3.  RISK ANALYSIS**
**File:** `standalone-risk-analysis.cypher`

**Purpose:** Comprehensive risk assessment and mitigation planning
**Use When:** You want to identify high-risk flows and plan mitigation strategies
**Requires:** Flows with `finalStoryPoints` property

**What it does:**
-  Calculates comprehensive risk scores (1-20 scale)
-  Identifies risk factors and mitigation strategies
-  Provides team and sprint priority recommendations
-  Analyzes project-level risk profile
-  Exports risk data for Excel

---

##  HOW TO USE STANDALONE SCRIPTS

### **Prerequisites**
Before running any standalone script:
1. **Neo4j database** with Mule application data loaded
2. **Story points calculated** (run `story-points-complexity-analysis.cypher` first if needed)
3. **Flow data** with basic properties (connectorCount, dwScriptCount, isApiExposed)

### **Running Individual Scripts**

#### **Option A: Neo4j Browser**
```bash
# Copy and paste script content into Neo4j Browser
# Execute all sections to get complete analysis
```

#### **Option B: Neo4j Shell**
```bash
# Run from command line
neo4j-shell -c "$(cat standalone-similarity-analysis.cypher)"
neo4j-shell -c "$(cat standalone-layer-analysis.cypher)"
neo4j-shell -c "$(cat standalone-risk-analysis.cypher)"
```

#### **Option C: Cypher-shell**
```bash
# For newer Neo4j versions
cypher-shell -f standalone-similarity-analysis.cypher
cypher-shell -f standalone-layer-analysis.cypher
cypher-shell -f standalone-risk-analysis.cypher
```

---

##  SCRIPT DETAILS

### ** COSINE SIMILARITY ANALYSIS SCRIPT**

**Sections:**
1. **Flow Structure Vectors** - Creates 15-dimensional flow vectors
2. **Application Vectors** - Aggregates flow vectors for application-level analysis
3. **Cosine Similarity** - Calculates mathematical similarity between flows and applications
4. **Enhanced Groups** - Creates cosine similarity groups with advanced strategies
5. **Comprehensive Analysis** - Application and flow-level similarity results
6. **Excel Export** - Detailed similarity data with implementation guidance

**Key Outputs:**
- **Application Cosine Similarity**: Applications with 0.8+ similarity, migration strategies
- **Flow Cosine Similarity**: Flows with 0.7+ similarity, pattern analysis
- **Similarity Strategies**: SAME_TEAM_COSINE, SAME_TEAM_SEQUENTIAL_COSINE, DISTRIBUTED_WITH_LEAD_COSINE
- **Efficiency Analysis**: Up to 50%+ efficiency gains for near-identical patterns
- **Migration Recommendations**: IDENTICAL_PATTERN, VERY_SIMILAR, SIMILAR, MODERATELY_SIMILAR

**Flow Structure Vector (15 dimensions):**
```cypher
[connectorCount, dwScriptCount, isApiExposed, storyPoints,
 httpSteps, dbSteps, transformSteps, validateSteps,
 choiceSteps, foreachSteps, asyncSteps, errorSteps,
 logSteps, setSteps, totalSteps]
```

**Example Usage:**
```cypher
// Quick cosine similarity check
MATCH (app1:Application)-[r:COSINE_SIMILAR]->(app2:Application)
RETURN app1.name, app2.name, r.similarity
ORDER BY r.similarity DESC;

// Flow similarity groups
MATCH (sg:SimilarityGroup)<-[:BELONGS_TO_COSINE_GROUP]-(flow:Flow)
RETURN sg.id, sg.similarity, sg.strategy, count(flow)
ORDER BY sg.similarity DESC;
```

### ** LAYER ANALYSIS SCRIPT**

**Sections:**
1. **Setup** - Cleans existing data, detects layers
2. **Risk Assessment** - Layer-specific risk calculation
3. **Analysis Results** - Layer distribution and characteristics
4. **Validation** - Quality assessment and manual review flags
5. **Export Data** - Excel-ready results
6. **Summary** - Overall layer analysis summary

**Key Outputs:**
- **Layer Classification**: EXPERIENCE, PROCESS, SYSTEM
- **Confidence Scores**: 60-90% confidence in classification
- **Risk Assessment**: Layer-specific risk levels
- **Team Recommendations**: Which team should handle each layer
- **Sprint Recommendations**: Which sprint phase for each layer

**Example Usage:**
```cypher
// Quick layer overview
MATCH (flow:Flow) WHERE flow.muleLayer IS NOT NULL
RETURN flow.muleLayer, count(flow), round(avg(flow.layerConfidence), 1)
ORDER BY flow.muleLayer;
```

### ** RISK ANALYSIS SCRIPT**

**Sections:**
1. **Setup** - Cleans existing data, calculates risk scores
2. **Distribution Analysis** - Risk level distribution
3. **Detailed Breakdown** - High-risk flows analysis
4. **Mitigation Strategies** - Risk-specific recommendations
5. **Export Data** - Excel-ready results
6. **Summary** - Overall project risk assessment

**Key Outputs:**
- **Risk Levels**: CRITICAL, HIGH, MEDIUM, LOW, MINIMAL
- **Risk Scores**: 1-20 scale based on complexity, integration, transformation
- **Risk Factors**: HIGH_COMPLEXITY, HIGH_INTEGRATION, API_EXPOSURE, etc.
- **Mitigation Strategies**: Specific actions for each risk level
- **Team Assignments**: Based on risk tolerance

**Example Usage:**
```cypher
// Quick risk overview
MATCH (flow:Flow) WHERE flow.riskLevel IS NOT NULL
RETURN flow.riskLevel, count(flow), round(avg(flow.riskScore), 1)
ORDER BY flow.riskLevel;
```

---

##  WHEN TO USE EACH SCRIPT

### **USE COSINE SIMILARITY ANALYSIS WHEN:**
-  You want sophisticated pattern detection beyond basic metrics
-  You need to find similar applications for coordinated migration
-  You want to analyze complex flow structure similarities
-  You're planning template-based migration approaches
-  You need mathematical similarity measurements (0.7+ threshold)
-  You want to identify near-identical patterns (0.95+ similarity)
-  You're investigating reuse potential across entire applications

### **USE LAYER ANALYSIS WHEN:**
-  You want to understand architectural layers
-  You need layer-specialized team assignments
-  You're planning layer-dependent sprint sequencing
-  You want to optimize migration dependencies
-  You need layer-specific risk assessment

### **USE RISK ANALYSIS WHEN:**
-  You want to identify high-risk flows
-  You need to plan mitigation strategies
-  You're assigning teams based on risk tolerance
-  You want to prioritize sprint assignments
-  You need comprehensive project risk assessment

---

##  EXPECTED RESULTS

### **Cosine Similarity Analysis Results:**

**Application Cosine Similarity:**
```
Application1 | Application2 | CosineSimilarity | MigrationStrategy    | EffortSavings
uhub-sapi    | orders-api   | 0.923           | VERY_SIMILAR         | 25-40%
payment-api  | billing-api  | 0.876           | SIMILAR             | 15-25%
```

**Flow Cosine Similarity:**
```
GroupId      | CosineSimilarity | Strategy                    | PatternAnalysis  | FlowCount
CSG_app1_app2| 0.956           | SAME_TEAM_COSINE           | NEAR_IDENTICAL   | 4
CSG_app3_app4| 0.887           | SAME_TEAM_SEQUENTIAL_COSINE| VERY_SIMILAR     | 6
```

**Efficiency Analysis:**
```
TotalCosineGroups | AvgCosineSimilarity | HighEfficiencyFlows | EstimatedEffortSavings
12                | 0.864              | 15                  | 127.3
```

### **Layer Analysis Results:**
```
Layer      | FlowCount | Percentage | AvgConfidence | TeamRecommendation
SYSTEM     | 52        | 41.6%      | 74.2         | Standard Team
PROCESS    | 38        | 30.4%      | 78.5         | Expert Team
EXPERIENCE | 35        | 28.0%      | 82.1         | Senior Team
```

### **Risk Analysis Results:**
```
RiskLevel     | FlowCount | Percentage | TeamRecommendation    | SprintPriority
CRITICAL_RISK | 8         | 6.4%       | Expert Team Required  | Sprint 1-2
HIGH_RISK     | 15        | 12.0%      | Senior Team Recommended| Sprint 1-4
MEDIUM_RISK   | 42        | 33.6%      | Standard Team         | Sprint 3-8
LOW_RISK      | 35        | 28.0%      | Junior Team Possible  | Sprint 6-10
MINIMAL_RISK  | 25        | 20.0%      | Junior Team Suitable  | Sprint 9-12
```

---

##  INTEGRATION WITH MAIN WORKFLOW

These standalone scripts can be used:

### **INDEPENDENTLY**
```bash
# Run any script independently for specific analysis
neo4j-shell -c "$(cat standalone-risk-analysis.cypher)"
```

### **BEFORE MAIN WORKFLOW**
```bash
# Use for preliminary analysis before full workflow
neo4j-shell -c "$(cat standalone-layer-analysis.cypher)"
# Review results, then run main workflow
```

### **AFTER MAIN WORKFLOW**
```bash
# Use for additional analysis after workflow completion
neo4j-shell -c "$(cat standalone-similarity-analysis.cypher)"
```

### **COMBINED WITH MAIN WORKFLOW**
```bash
# Replace specific steps in main workflow
# Instead of: layer-aware-team-assignments.cypher
# Use: standalone-layer-analysis.cypher + manual assignments
```

---

##  CUSTOMIZATION OPTIONS

### **Modify Similarity Criteria:**
Edit `standalone-similarity-analysis.cypher` Section 1:
```cypher
// Change similarity signature calculation
toString(flow.connectorCount) + '_' + 
toString(flow.dwScriptCount) + '_' + 
toString(flow.isApiExposed) + '_' + 
flow.storyPointCategory as similaritySignature
```

### **Adjust Layer Detection Rules:**
Edit `standalone-layer-analysis.cypher` Section 1:
```cypher
// Modify layer detection criteria
WHEN flow.isApiExposed = true AND flow.connectorCount <= 2 THEN 'EXPERIENCE'
WHEN flow.connectorCount >= 3 AND flow.dwScriptCount >= 3 THEN 'PROCESS'
```

### **Change Risk Scoring:**
Edit `standalone-risk-analysis.cypher` Section 1:
```cypher
// Adjust risk factor weights
WHEN flow.finalStoryPoints >= 13 THEN 4  // Very high complexity
WHEN flow.connectorCount >= 5 THEN 4     // Very high integration
```

---

##  EXPORT AND REPORTING

Each script includes **Section 5: Export Data** with Excel-ready queries:

### **Copy Results to Excel:**
1. Run the script in Neo4j Browser
2. Navigate to Section 5 export queries
3. Copy results and paste into Excel/OpenOffice
4. Use for stakeholder reporting and planning

### **Automated Export:**
```bash
# Export to CSV files
neo4j-shell -c "$(cat standalone-similarity-analysis.cypher)" > similarity-results.csv
neo4j-shell -c "$(cat standalone-layer-analysis.cypher)" > layer-results.csv  
neo4j-shell -c "$(cat standalone-risk-analysis.cypher)" > risk-results.csv
```

---

##  QUICK REFERENCE

| **Script** | **Purpose** | **Key Output** | **Use Case** |
|------------|-------------|----------------|--------------|
| **Similarity** | Pattern detection | Similarity groups | Knowledge reuse |
| **Layer** | Architecture analysis | Layer classification | Team specialization |
| **Risk** | Risk assessment | Risk levels | Mitigation planning |

** These standalone scripts give you complete flexibility to analyze specific aspects of your Mule Application Complexity Analysis and project planning independently!** 