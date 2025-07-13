# Curated Prompt Library for Anypoint Example Project Automation

These carefully-crafted prompts reproduce, with improved clarity and structure, the requests we used during this session.  
Feel free to copy-paste or adapt them in future conversations with generative tools.

---

## 1. Repository-wide Flow & App Analysis
```
You are given a root folder containing multiple MuleSoft example applications.
1. Parse every XML config file, extract each <flow> / <sub-flow> name.
2. For each flow, count the Mule component tags inside its body and classify complexity:
   • Low  = ≤5 components  • Medium = 6-12  • High = >12
3. For each application aggregate the counts (Low / Medium / High).
4. For each application build the set of unique component tag names and compute the
   Jaccard similarity between every pair of apps.
Return two machine-readable JSON blocks:
  A) flow-level complexity objects {app, flow, file, tagCount, complexity}
  B) top-N app-to-app similarity tuples {appA, appB, jaccard}.
```

---

## 2. Markdown Report with Two Tables
```
Create a markdown file `ANALISYS.md` with:
1. A **Similarity Analysis** table showing the top-20 application pairs sorted by
   descending Jaccard score.
2. A **Complexity Analysis** table listing every application with counts of
   Low / Medium / High complexity flows (highlight apps that contain High flows).
Add a short “Methodology” call-out below each table.
```

---

## 3. High-Level Project Plan for Three Teams
```
Act as a Project Manager. Based on the analysis in ANALISYS.md, craft a plan for
three delivery teams so that:
• Team Alpha handles High complexity refactors,
• Team Bravo upgrades Medium complexity flows and shared libraries,
• Team Charlie executes Low complexity quick-wins and doc upgrades.
Produce a markdown document `PLANNING.md` that includes:
  • Goals
  • Team structure and skills
  • Work-package allocation tables per team
  • 14-week timeline (2-week sprints)
  • Milestones, risks and communication plan.
```

---

## 4. Sprint Plan Aligned with Cypher Agile-Team Config
```
Read `Cypher/initialize-agile-teams.cypher` to obtain the canonical three Agile
teams (Expert, Senior, Standard) and their velocity.
Create `PLANNING_SP.md` with:
• Reference configuration table (teams, velocity, complexity range)
• Backlog sizing buckets (H / M / L) with story-point factors
• Capacity calculation across 12 sprints
• Sprint-by-sprint allocation table keeping work balanced to velocity
• Milestones and key risks.
```

---

## 5. Application-Focused Collaboration Add-On
```
Append to `PLANNING_SP.md` a subsection that demonstrates how, in each sprint,
all three teams can collaborate on the **same target application** while keeping
their individual loads proportional. Provide a 12-row table with sprint, target
application, flow bundle examples, and the story-point allocation per team.
Include a short explanatory note below the table.
```

---

## 6. House-Keeping & File Management
```
• Rename files as needed to use the spelling "ANALISYS" consistently.
• Create a folder `AI-analysys` at project root and move ANALISYS.md and
  planning documents into it.
```

---

> **Tip:** When running these prompts via an automated pipeline, execute them
> sequentially in the order above, because each step builds on artefacts created
> by the previous one. 