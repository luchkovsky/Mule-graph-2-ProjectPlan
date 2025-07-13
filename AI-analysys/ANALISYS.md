# Anypoint Examples – Analysis

This document summarizes two aspects of the Mule example projects contained in this repository:

1. **App–to–app functional similarity** – based on the Jaccard coefficient of unique Mule component tags used in each application.
2. **Flow complexity distribution** – based on the number of Mule components inside every `<flow>` / `<sub-flow>` definition.

---

## 1. Similarity Analysis (top 20 pairs)

| App A | App B | Jaccard Similarity |
|-------|-------|-------------------|
| processing-orders-with-dataweave-and-APIkit | processing-orders-with-dataweave-and-APIkit (2) | **1.00** |
| importing-an-email-attachment-using-the-IMAP-connector | importing-an-email-attachment-using-the-POP3-connector | 0.88 |
| content-based-routing | munit-short-tutorial | 0.75 |
| importing-an-email-attachment-using-the-POP3-connector | sending-a-csv-file-through-email-using-smtp | 0.75 |
| sending-json-data-to-a-amqp-queue | sending-json-data-to-a-jms-queue | 0.75 |
| proxying-a-rest-api | proxying-a-soap-api | 0.71 |
| dataweave-with-flowreflookup | import-contacts-into-salesforce | 0.67 |
| hello-world | http-request-response-with-logger | 0.67 |
| rest-api-with-apikit | testing-apikit-with-munit | 0.67 |
| importing-an-email-attachment-using-the-IMAP-connector | sending-a-csv-file-through-email-using-smtp | 0.63 |
| munit-short-tutorial | xml-only-soap-webservice | 0.60 |
| sending-a-csv-file-through-email-using-smtp | upload-to-ftp-after-converting-json-to-xml | 0.57 |
| upload-to-ftp-after-converting-json-to-xml | web-service-consumer | 0.57 |
| legacy-modernization | upload-to-ftp-after-converting-json-to-xml | 0.56 |
| get-customer-list-from-netsuite | salesforce-data-retrieval | 0.54 |
| addition-using-javascript-transformer | http-request-response-with-logger | 0.50 |
| authenticating-salesforce-using-oauth2 | http-request-response-with-logger | 0.50 |
| cache-scope-with-fibonacci | content-based-routing | 0.50 |
| content-based-routing | mule-expression-language-basics | 0.50 |
| content-based-routing | xml-only-soap-webservice | 0.50 |

> **Methodology**  For every application we collected the set of tag names (ignoring XML namespaces) that appear inside its flows. Similarity between two apps is `|intersection| / |union|` of those sets.

---

## 2. Flow Complexity Analysis (per application)

| Application | Low (≤ 5) | Medium (6-12) | High (> 12) |
|-------------|----------:|--------------:|-------------:|
| service-orchestration-and-choice-routing | 9 | 3 | **4** |
| soap-webservice-security | 2 | 14 | **3** |
| netsuite-data-retrieval | 3 | 3 | **2** |
| foreach-processing-and-choice-routing | 9 | 5 | 1 |
| sap-data-retrieval | 2 | 5 | 1 |
| implementing-a-choice-exception-strategy | 0 | 0 | 1 |
| jms-message-rollback-and-redelivery | 0 | 0 | 1 |
| importing-a-CSV-file-into-Mongo-DB | 0 | 0 | 1 |
| **(all remaining apps)** | *(see below)* | |

<details>
<summary>Full distribution for every application</summary>

| Application | Low | Medium | High |
|-------------|----:|-------:|-----:|
| adding-a-new-customer-to-workday-revenue-management | 3 | 3 | 0 |
| addition-using-javascript-transformer | 0 | 1 | 0 |
| authenticating-salesforce-using-oauth2 | 0 | 1 | 0 |
| cache-scope-with-fibonacci | 2 | 1 | 0 |
| content-based-routing | 2 | 1 | 0 |
| dataweave-with-flowreflookup | 4 | 0 | 0 |
| document-integration-using-the-cmis-connector | 1 | 0 | 0 |
| exposing-a-restful-resource-using-the-HTTP-connector | 1 | 2 | 0 |
| extracting-data-from-LDAP-directory | 0 | 1 | 0 |
| filtering-a-message | 0 | 1 | 0 |
| foreach-processing-and-choice-routing | 9 | 5 | 1 |
| get-customer-list-from-netsuite | 0 | 1 | 0 |
| hello-world | 1 | 0 | 0 |
| http-multipart-request | 1 | 1 | 0 |
| http-oauth-provider | 2 | 0 | 0 |
| http-request-response-with-logger | 1 | 0 | 0 |
| implementing-a-choice-exception-strategy | 0 | 0 | 1 |
| import-contacts-into-ms-dynamics | 2 | 1 | 0 |
| import-contacts-into-salesforce | 2 | 1 | 0 |
| import-leads-into-salesforce | 2 | 0 | 0 |
| importing-a-CSV-file-into-Mongo-DB | 0 | 0 | 1 |
| importing-a-csv-file-into-ms-sharepoint | 3 | 0 | 0 |
| importing-an-email-attachment-using-the-IMAP-connector | 0 | 1 | 0 |
| importing-an-email-attachment-using-the-POP3-connector | 0 | 1 | 0 |
| jms-message-rollback-and-redelivery | 0 | 0 | 1 |
| legacy-modernization | 0 | 1 | 0 |
| login-form-using-the-http-connector | 2 | 1 | 0 |
| mule-component-bindings | 2 | 1 | 0 |
| mule-expression-language-basics | 3 | 3 | 0 |
| munit-short-tutorial | 6 | 1 | 0 |
| netsuite-data-retrieval | 3 | 3 | 2 |
| oauth2-authorization-code-using-the-HTTP-connector | 1 | 1 | 0 |
| oauth2-client-credentials-using-the-HTTP-connector | 2 | 0 | 0 |
| processing-orders-with-dataweave-and-APIkit | 2 | 1 | 0 |
| processing-orders-with-dataweave-and-APIkit (2) | 2 | 1 | 0 |
| proxying-a-rest-api | 2 | 2 | 0 |
| proxying-a-soap-api | 2 | 2 | 0 |
| querying-a-db-and-attaching-results-to-an-email | 0 | 1 | 0 |
| querying-a-mysql-database | 1 | 0 | 0 |
| rest-api-with-apikit | 10 | 0 | 0 |
| salesforce-data-retrieval | 0 | 2 | 0 |
| salesforce-data-synchronization-using-watermarking-and-batch-processing | 1 | 0 | 0 |
| salesforce-to-MySQL-DB-using-Batch-Processing | 4 | 1 | 0 |
| sap-data-retrieval | 2 | 5 | 1 |
| scatter-gather-flow-control | 2 | 1 | 0 |
| sending-a-csv-file-through-email-using-smtp | 0 | 1 | 0 |
| sending-json-data-to-a-amqp-queue | 1 | 0 | 0 |
| sending-json-data-to-a-jms-queue | 1 | 0 | 0 |
| service-orchestration-and-choice-routing | 9 | 3 | 4 |
| soap-webservice-security | 2 | 14 | 3 |
| testing-apikit-with-munit | 5 | 0 | 0 |
| track-a-custom-business-event | 0 | 1 | 0 |
| upload-to-ftp-after-converting-json-to-xml | 1 | 0 | 0 |
| using-transactional-scope-in-jms-to-database | 1 | 1 | 0 |
| web-service-consumer | 0 | 2 | 0 |
| websphere-mq | 3 | 0 | 0 |
| xml-only-soap-webservice | 8 | 3 | 0 |

</details>

> **Methodology**  Each flow was classified by counting opening XML tags in its body.

---

*This file was renamed from `ANALYS.md` to `ANALISYS.md` to correct spelling.* 