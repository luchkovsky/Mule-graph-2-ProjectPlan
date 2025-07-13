# Sprint Plan – Mule Flow Modernisation  
*Aligned with the canonical Agile teams defined in `Cypher/initialize-agile-teams.cypher`*

## 0. Reference Configuration (from Cypher)
| Team (Node) | Skill Level | Sprint Velocity (pts) | Team Size | Complexity Range |
|-------------|-------------|----------------------:|-----------|------------------|
| **Expert Team** | EXPERT   | **15** | 3 | 8 - 21 |
| **Senior Team** | SENIOR   | **20** | 4 | 5 - 13 |
| **Standard Team** | STANDARD | **25** | 5 | 1 - 8 |

Global parameters: **12 sprints**, **2-week cadence** (≙ 24 weeks total).

---

## 1. Backlog Buckets
| Bucket | Complexity Band | Typical Work Items | Story-Pt Factor |
|--------|-----------------|--------------------|-----------------|
| **H** | 14–21 components | Break down monolithic flow, heavy refactor, performance tuning | 13 pts |
| **M** | 6–13 components  | Modularise medium flow, add tests, improve error handling | 8 pts |
| **L** | ≤ 5 components   | Docs, CI setup, cosmetic refactor | 3 pts |

Mapping of our analysed flows:  
• **H** = 16 flows  • **M** ≈ 110 flows • **L** ≈ 150 flows

Total *rough* backlog ≈ 16×13 + 110×8 + 150×3 = 208 + 880 + 450 = **1 538 pts**

---

## 2. Capacity Overview (12 sprints)
| Team | Velocity / Sprint | Total Capacity (12 sprints) |
|------|------------------:|-----------------------------:|
| Expert Team | 15 | **180 pts** |
| Senior Team | 20 | **240 pts** |
| Standard Team | 25 | **300 pts** |
| **All Teams** | — | **720 pts** |

At 720 pts the three teams cover ~47 % of the total backlog.  
Therefore we plan **Phase 1** (first 12 sprints) to finish High-priority work and part of Medium, then re-baseline.

---

## 3. Sprint-by-Sprint Allocation (Phase 1)
### Key
• H-xx = High-complexity flow ID • M-xx = Medium • L-xx = Low   
(*IDs correspond to index numbers in `ANALISYS.md` top-complex flows list or flow table*)

| Sprint | Expert Team (15 pts) | Senior Team (20 pts) | Standard Team (25 pts) |
|-------:|----------------------|----------------------|-------------------------|
| 1 | H-01 (13) + L backlog (2) | M-01, M-02 (16) + L (4) | L bulk (25) |
| 2 | H-02 (13) + L (2) | M-03, M-04 (16) + L (4) | L bulk (25) |
| 3 | H-03 (13) + L (2) | M-05, M-06 (16) + L (4) | L bulk (25) |
| 4 | H-04 (13) + L (2) | M-07, M-08 (16) + L (4) | L bulk (25) |
| 5 | H-05 (13) + L (2) | M-09, M-10 (16) + L (4) | L bulk (25) |
| 6 | Buffer / spillover | M-11, M-12 (16) + L (4) | L bulk (25) |
| 7 | Perf hardening (15) | M-13, M-14 (16) + L (4) | L bulk (25) |
| 8 | H-06 (13) + L (2) | M-15, M-16 (16) + L (4) | L bulk (25) |
| 9 | H-07 (13) + L (2) | M-17, M-18 (16) + L (4) | Regression fix (25) |
|10 | H-08 (13) + L (2) | M-19, M-20 (16) + L (4) | Regression fix (25) |
|11 | Security review (15) | Medium spillover (20) | Docs & CI (25) |
|12 | Final RC polish (15) | Final RC polish (20) | Final RC polish (25) |

---

## 3b. Application-Focused Collaboration Plan  
_To illustrate how the three teams can collaborate on the **same application** each sprint while keeping their individual load approximately proportional to their velocities._

| Sprint | Target Application | Flow Bundle (examples) | Expert Team  *(≈15 pts)* | Senior Team *(≈20 pts)* | Standard Team *(≈25 pts)* |
|-------:|-------------------|------------------------|--------------------------|--------------------------|----------------------------|
| 1 | service-orchestration-and-choice-routing | H-inhouseOrder, M-orderService, L-auditService | H-inhouseOrder (13 pts) + small L (2) | M-orderService (8) + 3×M sub-flows (12) | Remaining L flows (≈25) |
| 2 | **same app** | Remaining medium / low flows | Perf & error-handler refactor (15) | Choice router patterns (20) | Bulk unit tests & docs (25) |
| 3 | soap-webservice-security | H-SecurityClients, M-UsernameToken*, L-unsecure | H-SecurityClients (13) + L (2) | 2×M token sub-flows (16) + L fixes (4) | Remaining L flows + docs (25) |
| 4 | **same app** | Finish medium flows, hardening | WS-Sec perf tuning (15) | Add WS-Policy examples (20) | Regression automation (25) |
| 5 | netsuite-data-retrieval | H-createCustomer, M-get:/customers, L-api-main | H-createCustomer (13) + L patch (2) | 2×M endpoints (16) + L (4) | Remaining L flows + env scripts (25) |
| 6 | **same app** | Finish tests & perf | Bulk-sync optimisation (15) | Error mapping & retry logic (20) | MUnit coverage (25) |
| 7 | sap-data-retrieval | H-deleteSAPCustomer, M-get:/salesOrders | H-deleteSAPCustomer (13) + L (2) | 2×M endpoints (16) + L (4) | Remaining L flows (25) |
| 8 | **same app** | Finish medium & low | Batch-API tuning (15) | WS-Adapter configs (20) | Docs + CI (25) |
| 9 | proxying-a-rest-api | M-rest-api-proxy, many L | 2×M routes (15) | 1×M + L mix (20) | Remaining L flows (25) |
|10 | proxying-a-soap-api | M-soap-api-proxy, L | 2×M routes (15) | 1×M + L mix (20) | Remaining L flows (25) |
|11 | scatter-gather-flow-control | M/H scatter-gatherFlow, L | H-scatter-gatherFlow (13) + L (2) | 2×M helpers (16) + L | Regression docs/tests (25) |
|12 | buffer & polish | – | Security / perf review (15) | Remaining M spillover (20) | Docs, CI, release notes (25) |

> Each “Flow Bundle” column lists representative flows—refer to `ANALISYS.md` for the full ID mapping.  
> Loads are approximate; Product Owner may reshuffle between teams to keep point totals balanced when grooming the sprint backlog.

---

## 4. Milestones
| Code | Milestone | Target Sprint |
|------|-----------|--------------:|
| M1 | All **H** bucket flows refactored & tested | 6 |
| M2 | 40 % of **M** bucket completed | 8 |
| M3 | Security & performance review accepted | 11 |
| M4 | Release Candidate ready | 12 |

---

## 5. Risk & Mitigation Highlights
* **Under-allocation risk:** backlog > capacity. → Phase-2 planning after Sprint 12.  
* **Expert team over-specialisation:** share knowledge via pair-programming with Senior team.  
* **Regression churn:** dedicate Standard team Sprint 9-10 to regression fixes.

---

**Prepared by:** _Sprint Planner_ • Date: {{ today }} 