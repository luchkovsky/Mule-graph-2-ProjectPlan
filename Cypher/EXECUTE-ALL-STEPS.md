# EXECUTE ALL STEPS - Layer-Aware Roadmap Workflow

## Quick Start Workflow

** STANDARD WORKFLOW** (Basic layer-aware planning)
```bash
# Step 1: Clean database and setup teams
neo4j-shell -c "$(cat nuclear-cleanup.cypher)"

# Step 1b: Initialize canonical Agile teams
neo4j-shell -c "$(cat initialize-agile-teams.cypher)"

# Step 2: Calculate story points
neo4j-shell -c "$(cat story-points-complexity-analysis.cypher)"

# Step 2b: (Optional) Auto-rebalance team workloads
neo4j-shell -c "$(cat rebalance-team-assignments.cypher)"

# Step 3: Detect Mule architectural layers
neo4j-shell -c "$(cat mule-layer-detection.cypher)"

# Step 3b: Build sprint backlog (team-balanced)
neo4j-shell -c "$(cat application-team-balanced-sprint-planning.cypher)"

# Step 3c: Rebalance team workloads after backlog creation
neo4j-shell -c "$(cat rebalance-team-assignments.cypher)"

# Step 4: Layer-aware team assignments
neo4j-shell -c "$(cat layer-aware-team-assignments.cypher)"

# Step 5: Layer-aware sprint planning with capacity balancing
neo4j-shell -c "$(cat layer-aware-sprint-planning.cypher)"

# Step 6: Generate comprehensive views
neo4j-shell -c "$(cat generate-roadmap-views.cypher)"

# Step 7: Export Options (choose one or run all)
# Option A: Traditional Excel/OpenOffice export
neo4j-shell -c "$(cat export-to-excel.cypher)"

# Option B: Microsoft Project XML export (team-sequenced)
neo4j-shell -c "$(cat export-to-msproject-xml.cypher)"

# Option D: JIRA JSON export for issue import
neo4j-shell -c "$(cat export-to-jira-table.cypher)"
```

** SIMPLIFIED WORKFLOW** (Risk-based planning with capacity balancing)
```bash
# Step 1: Clean database and setup teams
neo4j-shell -c "$(cat nuclear-cleanup.cypher)"

# Step 1b: Initialize canonical Agile teams
neo4j-shell -c "$(cat initialize-agile-teams.cypher)"

# Step 2: Calculate story points
neo4j-shell -c "$(cat story-points-complexity-analysis.cypher)"

# Step 2b: (Optional) Auto-rebalance team workloads
neo4j-shell -c "$(cat rebalance-team-assignments.cypher)"

# Step 3: Risk-based team assignments
neo4j-shell -c "$(cat risk-based-assignments.cypher)"

# Step 4: Improved sprint planning with capacity balancing
neo4j-shell -c "$(cat improved-sprint-planning.cypher)"

# Step 5: Generate comprehensive views
neo4j-shell -c "$(cat generate-roadmap-views.cypher)"

# Step 6: Export Options (choose one or run all)
# Option A: Traditional Excel/OpenOffice export
neo4j-shell -c "$(cat export-to-excel.cypher)"

# Option B: Microsoft Project XML export (team-sequenced)
neo4j-shell -c "$(cat export-to-msproject-xml.cypher)"

# Option D: JIRA JSON export for issue import
neo4j-shell -c "$(cat export-to-jira-table.cypher)"
```

** SIMILARITY-ENHANCED WORKFLOW** (Advanced with similarity management)
```bash
# Steps 1-3: Same as standard workflow
neo4j-shell -c "$(cat nuclear-cleanup.cypher)"

neo4j-shell -c "$(cat initialize-agile-teams.cypher)"

neo4j-shell -c "$(cat story-points-complexity-analysis.cypher)"

# Step 4: Flow similarity detection
neo4j-shell -c "$(cat flow-similarity-detection.cypher)"

# Step 5: Similarity-enhanced assignments
neo4j-shell -c "$(cat similarity-enhanced-assignments.cypher)"

# Step 6: Layer-aware sprint planning with capacity balancing
neo4j-shell -c "$(cat layer-aware-sprint-planning.cypher)"

# Step 7: Generate comprehensive views
neo4j-shell -c "$(cat generate-roadmap-views.cypher)"

# Step 8: Export to Excel/OpenOffice
neo4j-shell -c "$(cat export-to-excel.cypher)"
```

---

## Layer-Aware Roadmap System

###  Mule 3-Layer Architecture Support

The system now automatically detects and leverages Mule's 3-layer architecture:

** EXPERIENCE LAYER**
- External-facing APIs
- User interfaces
- Mobile and web endpoints
- Simple integration points

** PROCESS LAYER**
- Business logic orchestration
- Multiple system coordination
- Complex workflows
- Data transformation

** SYSTEM LAYER**
- Direct system access
- Database operations
- Legacy system integration
- File and message processing

###  Layer-Aware Features

**Team Specialization:**
- **Expert Team**: Process & System layer specialists
- **Senior Team**: Experience & Process layer specialists  
- **Standard Team**: System & Experience layer specialists

**Sprint Planning:**
- **Phase 1 (Sprints 1-4)**: System layer foundation
- **Phase 2 (Sprints 5-8)**: Process layer orchestration
- **Phase 3 (Sprints 9-12)**: Experience layer APIs

**Dependency Management:**
- System → Process → Experience progression
- Risk-based prioritization per layer
- Layer-specific complexity scoring

**Capacity Balancing:**
- Target: 45-65 SP per sprint (±10 SP variance)
- Automatic load balancing across all sprints
- Prevents overloaded sprints (>65 SP) and underloaded sprints (<45 SP)
- Maintains risk prioritization within capacity constraints

**Application Team Constraint:**
- All flows within the same application are assigned to the same team
- Ensures knowledge consistency and reduces coordination overhead
- Application-level team assignment scoring considers aggregated characteristics

**Export Options:**
- **CSV Export**: Automatic export using APOC with 5 detailed reports
- **MS Project XML**: Full timeline with Gantt chart visualization
- **JIRA JSON**: Complete project setup with epics, stories, and sprints
- **Traditional Export**: Excel/OpenOffice compatible format

---

## Detailed Step-by-Step Guide

### Step 1: Nuclear Cleanup
```cypher
// Clean database
CALL { :load nuclear-cleanup.cypher }
```
**Creates:**
- Clean database state

### Step 1b: Initialize Agile Teams
```cypher
CALL { :load initialize-agile-teams.cypher }
```
**Creates / ensures:**
- 3 canonical AgileTeam nodes (Expert, Senior, Standard)
- Skill-level property on each team

### Step 2: Story Points Analysis
```cypher
// Calculate complexity-based story points
CALL { :load story-points-complexity-analysis.cypher }
```
**Calculates:**
- Connector-based complexity
- DataWeave transformation complexity
- API exposure complexity
- Risk-adjusted story points

### Step 3: Layer Detection
```cypher
// Detect Mule architectural layers
CALL { :load mule-layer-detection.cypher }
```
**Detects:**
- Experience layer flows (APIs, UIs)
- Process layer flows (orchestration, business logic)
- System layer flows (databases, legacy systems)
- Layer confidence scores

### Step 4: Layer-Aware Assignments
```cypher
// Assign flows to teams based on layer specialization
CALL { :load layer-aware-team-assignments.cypher }
```
**Assigns:**
- Flows to teams based on layer expertise
- Risk-adjusted assignments
- Specialization alignment scoring

### Step 5: Layer-Aware Sprint Planning with Capacity Balancing
```cypher
// Create sprints with layer dependencies and balanced capacity
CALL { :load layer-aware-sprint-planning.cypher }
```
**Creates:**
- 12 sprints with layer focus and balanced capacity (45-65 SP per sprint)
- Dependency-aware scheduling with capacity constraints
- Enhanced capacity-balanced assignments
- Automatic load balancing across sprints

### Step 6: Generate Views
```cypher
// Create comprehensive project views
CALL { :load generate-roadmap-views.cypher }
```
**Generates:**
- Executive summary
- Team workload analysis
- Risk assessment
- Layer progression tracking

### Step 7: Export Data (Multiple Format Options)

**Option A: Traditional Excel/OpenOffice Export**
```cypher
// Export to Excel/OpenOffice format
CALL { :load export-to-excel.cypher }
```

**Option B: Microsoft Project XML Export (team-sequenced)**
```cypher
// Export to MS Project XML format
CALL { :load export-to-msproject-xml.cypher }
```

**Option D: JIRA JSON Export**
```cypher
// Export to JIRA-compatible JSON
CALL { :load export-to-jira-table.cypher }
```

**Export Formats:**
- **CSV Files**: Sprint backlog, team assignments, layer analysis, risk assessment
- **MS Project XML**: Complete project timeline with Gantt chart support
- **JIRA JSON**: Epics, stories, and sprints for JIRA import

---

## Optional: Similarity Management

### When to Use Similarity Detection

Use similarity-enhanced workflow when:
-  Many flows have similar patterns
-  You want to leverage knowledge reuse
-  You need consistent implementation across similar flows
-  You want to optimize team efficiency

### Similarity Strategies

**SAME_TEAM (2-3 similar flows):**
- All flows assigned to one team
- Consecutive sprint scheduling
- Maximum knowledge reuse

**SAME_TEAM_SEQUENTIAL (4-6 similar flows):**
- Same team, spaced scheduling
- Pattern development over time
- Balanced workload distribution

**DISTRIBUTED_WITH_LEAD (7+ similar flows):**
- Expert team creates patterns
- Knowledge sharing across teams
- Scalable implementation

---

## New Export Features

<!-- Removed automatic CSV export section as script deprecated -->

### Microsoft Project XML Export (`export-to-msproject-xml.cypher`)
Generates MS Project compatible XML with:
- Project hierarchy (Phases → Sprints → Stories)
- Task duration calculations (8 hours per story point)
- Risk-based priority assignments
- Custom fields for metadata
- Calendar definitions for standard work schedule

### JIRA Table Export (`export-to-jira-table.cypher`)
Creates JIRA-compatible CSV structure with:
- **Epics**: One per application with team constraints
- **Stories**: One per flow with detailed descriptions
- **Sprints**: Complete sprint definitions with capacity status
- **Metadata**: Project configuration and import instructions
- **Labels**: Comprehensive tagging for filtering and reporting

#### How to import into JIRA

1. **Run the exporter & download CSV**
   ```cypher
   CALL { :load export-to-jira-table.cypher }
   ```
   In Neo4j Browser click the download icon  on the result grid → *Download CSV* (creates `jira_import.csv`).

2. **Jira Cloud / Server:** Admin ▶ *System* ▶ *External System Import* ▶ **CSV**.

3. **Upload `jira_import.csv`.** On the *Field Mapping* screen Jira auto-maps columns:
   | CSV Column       | Recommended Jira Field / Action                                      |
   | ---------------- | --------------------------------------------------------------------- |
   | IssueType        | Issue Type (required)                                                |
   | Summary          | Summary (required)                                                   |
   | EpicName         | Epic Name  *(only rows where IssueType = Epic)*                      |
   | EpicLink         | Epic Link **or** Parent  *(rows where IssueType = Story)*            |
   | Sprint           | Sprint Name  *(Jira Software projects)*                              |
   | Team             | Component/s **or** Labels (creates a component per team)             |
   | Application      | Labels  **or** Custom field (e.g. Application)                       |
   | Flow             | Labels  **or** Description append                                    |
   | StoryPoints      | Story Points (Number)                                                |
   | Name             | *Ignore*  (informational only)                                       |
   | Id               | *Ignore*  – Jira generates its own keys                              |
   | TotalStories     | *Ignore*  (aggregated metric)                                        |
   | TotalStoryPoints | *Ignore*  (aggregated metric)                                        |

   Leave `Id`, `Name`, `TotalStories`, `TotalStoryPoints` unmapped.

4. **Finish the wizard** – Jira confirms import counts; Epics create first, Stories link automatically, Sprints appear in *Backlog* → *Manage Sprints*.

💡 If you prefer JSON + REST API instead, run `export-to-jira-json-stream.cypher` and POST the `jiraJson` payload to `/rest/api/2/issue/bulk`.

##### cURL example (JSON import via REST API)

If you use `export-to-jira-json-stream.cypher`, copy the `jiraJson` column to a file (e.g. `jira_bulk.json`) and call:

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -u "YOUR_EMAIL@example.com:YOUR_JIRA_API_TOKEN" \
  --data @jira_bulk.json \
  "https://<your-domain>.atlassian.net/rest/api/3/issue/bulk"
```

Replace `<your-domain>` with your site, and supply your Atlassian email + API token (generated under *Account Settings → Security → API Token*).  Jira will respond with the IDs/keys of the created issues.

### Application Team Constraint Enhancement
All sprint planning scripts now enforce:
- Single team per application assignment
- Application-level team scoring
- Reduced coordination complexity
- Knowledge consistency within applications

---

## Verification Commands

### Quick Health Check
```cypher
// Run basic verification
CALL { :load verification-script.cypher }
```

### Detailed Diagnostics
```cypher
// Run comprehensive diagnostics
CALL { :load diagnostic-scripts.cypher }
```

### Layer Analysis
```cypher
// Analyze layer detection results
MATCH (flow:Flow) WHERE flow.muleLayer IS NOT NULL
RETURN flow.muleLayer as Layer, count(flow) as Count
ORDER BY Count DESC;
```

### Team Alignment Check
```cypher
// Check team-layer alignment
MATCH (team:AgileTeam)<-[:STORY_ASSIGNED_TO]-(flow:Flow)
WHERE flow.muleLayer IS NOT NULL
RETURN team.teamName, team.primaryLayer, 
       count(CASE WHEN flow.muleLayer = team.primaryLayer THEN 1 END) as MatchingFlows,
       count(flow) as TotalFlows
ORDER BY team.teamName;
```

---

## Results Overview

### Expected Outcomes

** Team Distribution:**
- Expert Team: 10-20 flows (high complexity, process/system)
- Senior Team: 20-40 flows (medium complexity, experience/process)
- Standard Team: 60-90 flows (low complexity, system/experience)

** Sprint Distribution:**
- Foundation Phase: System layer priority
- Orchestration Phase: Process layer priority
- API Delivery Phase: Experience layer priority

** Layer Alignment:**
- 60%+ flows aligned with team specialization
- Progressive layer dependency satisfaction
- Risk-balanced sprint distribution

### Success Metrics

** Layer Focus Quality:**
- Excellent Focus: 60%+ layer alignment per sprint
- Good Focus: 40-60% layer alignment per sprint
- Mixed Focus: <40% layer alignment per sprint

** Team Efficiency:**
- High Efficiency: 70%+ specialization utilization
- Good Efficiency: 50-70% specialization utilization
- Medium Efficiency: 30-50% specialization utilization

** Sprint Readiness:**
- Ready: Balanced capacity, focused scope, managed risk
- Overcapacity: >100% capacity utilization
- Undercapacity: <50% capacity utilization

---

## Troubleshooting

### Common Issues

** Low Layer Confidence:**
```cypher
// Review flows with low confidence
MATCH (flow:Flow) WHERE flow.layerConfidence < 70
RETURN flow.app, flow.flow, flow.muleLayer, flow.layerConfidence
ORDER BY flow.layerConfidence ASC;
```

** Poor Team Alignment:**
```cypher
// Find misaligned assignments
MATCH (team:AgileTeam)<-[:STORY_ASSIGNED_TO]-(flow:Flow)
WHERE flow.muleLayer != team.primaryLayer
RETURN team.teamName, team.primaryLayer, flow.muleLayer, count(flow) as MisalignedFlows
ORDER BY MisalignedFlows DESC;
```

** Dependency Violations:**
```cypher
// Check for layer dependency issues
MATCH (sprint:Sprint)-[:INCLUDES_STORY]->(item:SprintItem)
WHERE sprint.sprintPhase = 'FOUNDATION' AND item.layer = 'EXPERIENCE'
RETURN sprint.sprintNumber, count(item) as ExperienceInFoundation
ORDER BY ExperienceInFoundation DESC;
```

### Manual Corrections

** Fix Layer Classification:**
```cypher
// Manually correct layer classification
MATCH (app:MuleApp {name: 'YourApp'})-[:HAS_FLOW]->(flow:Flow {flow: 'YourFlow'})
SET flow.muleLayer = 'CORRECT_LAYER',
    flow.layerConfidence = 95,
    flow.manuallyClassified = true;
```