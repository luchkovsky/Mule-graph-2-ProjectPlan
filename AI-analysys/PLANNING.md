# Project Plan – Anypoint Examples Modernisation

_As drafted by the Project Manager, based on the **Similarity** and **Complexity** analysis in `ANALISYS.md`_

## 0. Goals
* Bring all example projects to a consistent quality level (tests, docs, CI).
* Reduce technical debt in flows classified **High** complexity.
* Eliminate duplicates / near-duplicates surfaced by similarity analysis.

## 1. Teams
| Team | Primary Focus | Head-count | Skill Set |
|------|---------------|-----------:|-----------|
| **Team Alpha** | High-complexity flows & critical refactors | 5 devs | Senior MuleSoft, Java, Unit-testing, Performance |
| **Team Bravo** | Medium-complexity feature upgrades & API proxies | 4 devs | MuleSoft, API Kit, CI/CD |
| **Team Charlie** | Low-complexity quick-wins & duplicate consolidation | 3 devs | MuleSoft, Documentation, QA |

## 2. Work-package Allocation
### 2.1 High-priority (Team Alpha)
| App | Complexity (H/M/L) | Key Tasks |
|-----|-------------------|-----------|
| service-orchestration-and-choice-routing | 4 H / 3 M / 9 L | • Break down monolithic flows<br>• Add unit & perf tests<br>• Introduce error-handling patterns |
| soap-webservice-security | 3 H / 14 M / 2 L | • Modularise security clients<br>• Externalise WS-Sec policies<br>• Improve test coverage |
| netsuite-data-retrieval | 2 H / 3 M / 3 L | • Optimise bulk operations<br>• Refactor duplicate test flows<br>• Document NetSuite config |

### 2.2 Medium-priority (Team Bravo)
| Similarity Cluster | Representative Apps | Common Tasks |
|-------------------|---------------------|--------------|
| REST/SOAP Proxy | proxying-a-rest-api, proxying-a-soap-api | Unify header-copy sub-flows, extract shared policy lib |
| Email Attach | importing-email-(IMAP/POP3), sending-csv-via-smtp | Merge common mail utils, add attachment size validation |
| Messaging | send-JSON-to-AMQP, send-JSON-to-JMS | Centralise serialization logic, parameterise destinations |
| SAP / Salesforce retrieval | sap-data-retrieval, salesforce-data-retrieval | Align pagination, standardise error mapping |

### 2.3 Quick-wins & Duplicates (Team Charlie)
| Target | Rationale | Action |
|--------|-----------|--------|
| processing-orders-with-dataweave-and-APIkit _(duplicate folder)_ | Similarity = 1.0 | Keep one canonical copy, delete/redirect duplicate |
| rest-api-with-apikit vs testing-apikit-with-munit | Similarity 0.67 | Extract reusable RAML fragments |
| Low-complexity apps (< 3 flows) | Fast improvement | Add README & CI, ensure runs on latest Mule 4.x |

## 3. Timeline (14-week outline)
| Week | Team Alpha | Team Bravo | Team Charlie |
|------|-----------|-----------|--------------|
| 1 | Project kick-off, env setup | Kick-off | Kick-off |
| 2 | Deep-dive audit (3 apps) | Audit similarity clusters | Quick-win backlog grooming |
| 3 | Refactor design | Cluster design spec | README / CI templates |
| 4 | Sprint 1 dev | Sprint 1 dev | Sprint 1 dev |
| 5 | Sprint 1 testing | Sprint 1 testing | Sprint 1 testing |
| 6 | Sprint 2 dev | Sprint 2 dev | Sprint 2 dev |
| 7 | Sprint 2 testing | Sprint 2 testing | Sprint 2 testing |
| 8 | Perf & security hardening | Integrate shared libs | Consolidate duplicates |
| 9 | Sprint 3 dev | Sprint 3 dev | Final docs / QA |
|10 | Sprint 3 testing | Sprint 3 testing | Regression tests |
|11 | UAT support | UAT support | UAT support |
|12 | Release Candidate | Release Candidate | Release notes |
|13 | Buffer / spillover | Buffer / spillover | Buffer / spillover |
|14 | Final release & retrospective | Final release & retrospective | Final release & retrospective |

## 4. Milestones & Deliverables
1. **M1 – Audit Complete (Week 2)**  All teams have documented findings and refined backlogs.
2. **M2 – Shared Libraries Ready (Week 8)**  Common utilities published to internal Nexus.
3. **M3 – Release Candidate (Week 12)**  All apps build & tests pass in CI.
4. **M4 – Production-ready Release (Week 14)**  Documentation, tagging, and retrospectives done.

## 5. Risks & Mitigations
| Risk | Impact | Mitigation |
|------|--------|-----------|
| Under-estimation of high-complexity refactors | Schedule slip | Weekly demos, scope guardrails |
| Environment parity issues | Defects in UAT | Early CI pipeline with containerised Mule runtimes |
| Cross-team dependency on shared libs | Blocked sprints | Appoint library owner in Team Bravo, publish alpha versions early |

## 6. Communication Plan
* **Daily stand-up** per team – 15 min.
* **Cross-team sync** – Tuesdays 30 min.
* **Demo / retro** – End of each 2-week sprint.
* Stakeholder report sent every Friday by the PM.

---
**Prepared by:** _Project Manager_  •  Date: {{ today }} 