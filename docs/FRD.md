# OIL & GAS PRODUCTION ACCOUNTING EXTENSION

## Functional & Technical Requirements Specification

**Product:** Microsoft Dynamics 365 Business Central — Custom AL Extension
**Prepared by:** FMATecH Consulting
**Document Type:** Functional & Technical Requirements Document (FRD/TRD)
**Version:** 2.0
**Date:** September 2026

> This document is the source specification implemented by the AL project in this
> repository. Implementation traceability (FR → object) is in `IMPLEMENTATION_NOTES.md`.

---

## 1. Introduction

### 1.1 Purpose

This document specifies the functional and technical requirements for a custom AL extension to Microsoft Dynamics 365 Business Central that supports upstream oil & gas production accounting: daily production capture, Item Journal integration, Unit-of-Production depletion, royalty accounting, and related reporting.

### 1.2 Background

Business Central has no native oil & gas production module. Standard fixed-asset depreciation methods do not support Unit-of-Production depletion, and there is no native concept of a reservoir or reserve base. This extension closes those gaps using standard BC building blocks — Items, Item Units of Measure, Locations, Item Journals, Fixed Assets, and Dimensions — supplemented by a small number of custom tables, pages, and codeunits.

### 1.3 Scope

**In scope:**

- Master data for reservoirs, wells, permitted produced items per reservoir, and BOE conversion via standard Item Units of Measure
- Internally-estimated (non-certified) reserve figures with a full preparer/method/date audit trail and revision history
- Daily production capture and validation for a configurable, variable mix of produced items (gross, net, BS&W, BOE)
- Automated generation (not automated posting) of Item Journal lines from production data
- Unit-of-Production depletion calculation and posting on a BOE basis, supporting both Successful Efforts and Full Cost accounting policies
- Royalty calculation and posting, supporting both cash and in-kind settlement
- Joint Venture cost allocation and partner billing
- Dedicated Role Centers for Field Operator and O&G Accountant users
- Standard production, reserve, inventory, and lifting-cost reports

**Out of scope:**

- Production Sharing Contract (PSC) cost-recovery and profit-oil-split accounting
- Asset Retirement Obligation (ARO) accretion accounting
- Regulatory submission formats (e.g. DPR/NUPRC, SEC reserve reporting) beyond the standard reports
- Mobile/offline field data capture — field operators use Business Central directly

### 1.4 Assumptions & Dependencies

- Reserve estimates are prepared internally by FMATecH as consulting advisor (not third-party audited); the extension captures preparer, method, and date with every figure and revision.
- Standard BC Fixed Assets and Depreciation Books are licensed and configured.
- Object ID range confirmed: 70000–75000. Naming prefix: none — RESOLVED, all objects named functionally.
- Daily transaction volume to be confirmed during Phase 1 discovery.
- Field operators access Business Central directly.

### 1.5 Glossary

| Term | Definition |
|---|---|
| Reservoir | Underground rock formation containing recoverable crude oil, gas, and/or condensate. |
| Internal Reserve Estimate | A reserve figure (1P/2P/3P) prepared by FMATecH as consulting advisor rather than by an independent auditor; requires a stronger internal audit trail. |
| Depletion | The natural-resource equivalent of depreciation. |
| Unit of Production (UOP) | Depletion method expensing capitalised cost in proportion to volume produced relative to total recoverable reserves. |
| BOE | Barrels of Oil Equivalent — common unit converting gas, condensate and other items to an oil-equivalent basis. |
| BS&W | Basic Sediment & Water — non-hydrocarbon content of gross wellhead fluid. |
| Working Interest (WI) | The company's percentage ownership share of production and costs. |
| Net Revenue Interest (NRI) | Working interest net of royalty obligations. |
| Royalty | Payment to a government or landowner, typically a % of gross production or revenue, settled in cash or in-kind. |
| JV Cash Call | Request for funds from JV partners to cover their share of joint costs. |
| Successful Efforts | Policy under which only costs of successful wells are capitalised; dry holes are expensed immediately. |
| Full Cost | Policy under which all exploration costs in a cost centre are capitalised and amortised over that cost centre's total reserves. |

## 2. Business Process Overview

1. Field operator records daily well-level readings (items permitted for that reservoir).
2. The system calculates Net Quantity (after BS&W) and BOE per line; totals BOE at the header.
3. On explicit posting action, the system generates Item Journal lines (positive adjustments for product volumes, negative adjustment for BS&W loss) and updates the reservoir's cumulative production.
4. The accountant reviews and posts the Item Journal the normal BC way.
5. At period end the accountant runs the Depletion Calculation Worksheet, reviews rate/amount per reservoir, and posts depletion via the standard FA G/L Journal.
6. Royalty (cash or in-kind, per field) and JV cost-sharing are calculated and posted on the same cadence.
7. Standard reports give production, reserve, inventory, cost and reserve-estimate-history visibility.

Every financial posting stays inside standard, auditable Business Central mechanisms (Item Journals, FA G/L Journals).

## 3. Functional Requirements

### 3.1 Master Data Setup

| ID | Requirement |
|---|---|
| FR-01 | Single-record O&G Setup: Default Royalty Rate %, Default Production Tax Rate %, Default BOE Unit of Measure Code, elected Accounting Method (Successful Efforts or Full Cost). |
| FR-02 | Standard Item Units of Measure convert each produced item to a common BOE basis (alternate UOM matching the Default BOE UOM, factor maintained by the client on the standard Item Card). E.g. Gas: 1 BOE = 6 MCF; Crude/Condensate: 1 BOE = 1 BBL. |
| FR-03 | Reservoir Product Setup links each Reservoir to one or more permitted Items (configurable per reservoir, not fixed to crude/gas/condensate). |
| FR-04 | Reservoir Master records: OOIP, 1P/2P/3P reserves (BOE), cumulative production, remaining reserves, recovery factor, linked Fixed Asset, capitalised cost, current depletion rate, Estimated By, Estimation Method/Basis, Reserve Estimate Date. |
| FR-05 | Reserve Revision History logs every change to reserve figures (previous value, revised value, date, prepared-by, estimation basis); revisions apply prospectively. |
| FR-06 | Item card extended for each producible product; no fixed three-product list. |
| FR-07 | Dimensions for Field/Block, Well, Reservoir, Cost Center, JV Partner, defaulted on relevant G/L accounts and propagated onto every transaction. |
| FR-08 | Locations for each physical stage: Wellhead, Flow Station, Tank Farm, Pipeline/Transit, Export Terminal, FSO Vessel (as applicable). |
| FR-09 | Accounting Method election in O&G Setup: Successful Efforts (dry holes expensed) or Full Cost (dry holes capitalised into the UOP pool). |
| FR-10 | Dedicated Field Operator Role Center (daily entry, open-entry count) and O&G Accountant Role Center (pending journal postings, Depletion Worksheet, royalty/JV actions, four standard reports). |

### 3.2 Daily Production Capture

| ID | Requirement |
|---|---|
| FR-11 | Daily Production Entry document (header + lines) per production date/reservoir; line-based, not fixed columns. |
| FR-12 | BS&W items: Net Quantity = Gross × (1 − BS&W%) on validation; liquids only. |
| FR-13 | BOE Quantity per line via the item's standard UOM conversion; header-level BOE total. |
| FR-14 | Posted production documents cannot be edited or deleted. |
| FR-15 | Single-document posting and batch posting of all open documents in a date range. |

### 3.3 Item Journal Integration

| ID | Requirement |
|---|---|
| FR-16 | On posting: Positive Adjustment lines per production item (net quantity) and a Negative Adjustment line for BS&W volume. One batch per calendar month: `PROD-<MM><YYYY>` convention. |
| FR-17 | Journal lines carry a Document No. linking back to the Daily Production Entry and inherit Field/Block and Well dimensions. |
| FR-18 | The system does NOT auto-post generated journal lines to the G/L. |
| FR-19 | Posting updates Reservoir Cumulative Production and Remaining Reserves (BOE). |

### 3.4 Depletion Accounting

| ID | Requirement |
|---|---|
| FR-20 | UOP on a BOE basis: Rate = Remaining NBV ÷ Remaining Reserves (BOE); Period Depletion = Period Production (BOE) × Rate. |
| FR-21 | Depletion Calculation Worksheet (per reservoir, per period) before posting. |
| FR-22 | Posting via the Fixed Asset G/L Journal against the linked FA and Depreciation Book: Dr Depletion Expense / Cr Accumulated Depletion with Field and Cost Center dimensions. |
| FR-23 | Reserve revisions applied prospectively only — no restatement. |
| FR-24 | Exploration write-off action whose behaviour depends on the elected Accounting Method. |

### 3.5 Royalty & Joint Venture Accounting

| ID | Requirement |
|---|---|
| FR-25 | Royalty as a configurable % of gross production volume or gross revenue, per field/contract (default from O&G Setup, overridable per field). |
| FR-26 | Both settlement methods: Cash → Royalty Payable liability; In-Kind → negative volume adjustment of the produced item. |
| FR-27 | Joint operations cost allocation: operator share expensed, partner shares to JV Receivable per partner, tagged with the JV Partner dimension. |

### 3.6 Reporting

| ID | Requirement |
|---|---|
| FR-28 | Production Summary Report: gross, net, BOE by field/well/period, any items, with computed lifting cost per barrel/BOE. |
| FR-29 | Reserve Depletion Status Report: original reserves, cumulative production, remaining reserves, depletion %, NBV by reservoir. |
| FR-30 | Product Inventory Position Report: quantity/value on hand by location and item. |
| FR-31 | Lifting Cost per Barrel/BOE Report: total lifting cost ÷ net production, by field and period. |
| FR-32 | Reserve Estimate & Revision History Report: every estimate/revision with preparer, method/basis, date. |

## 4. Data Model & Technical Object Requirements

All custom objects use explicit IDs in 70000–75000 under the confirmed naming prefix, built as a per-tenant extension using AL guidelines (event subscribers over base-object modification, dimensions propagated via standard APIs, no hardcoded IDs outside the range). See `IMPLEMENTATION_NOTES.md` §1 for the complete object inventory; the extension additionally implements the FR-25/26/27/24 supporting tables (Royalty Term, Royalty Worksheet, JV Partner, JV Cost Allocation Header/Line, Exploration Write-off) and the FR-07/FR-22/FR-24/FR-26/FR-27 configuration fields (dimension codes, posting accounts) on O&G Setup, which the FRD's setup table does not enumerate but which the listed requirements make necessary.

## 5. Integration Requirements

- **Item Journals:** standard BC posting routines unmodified; the extension only creates journal lines.
- **Fixed Assets / Depreciation Books:** Reservoir links to a Fixed Asset (User-Defined depreciation method) so period depletion posts through the standard FA G/L Journal.
- **Standard Item Units of Measure:** reused as the BOE conversion mechanism (FR-02).
- **Dimensions:** set up before go-live and defaulted on the relevant G/L accounts.
- No external mobile/offline front end or Power Platform integration in this phase.

## 6. Non-Functional Requirements

| Category | Requirement |
|---|---|
| Segregation of duties | Field operators cannot post; enforced via BC permission sets. |
| Audit trail | Every journal line/depletion traceable to source document; every reserve figure traceable to preparer/method/date. |
| No silent automation | Nothing posts to the G/L without an explicit, logged user action. |
| Data volume | Provisional until Phase 1 discovery; SIFT keys on Field and Reservoir filters. |
| Configurability | Royalty rate, tax rate, BOE UOM, Accounting Method, item BOE factors — all client-maintainable without code change. |
| Extensibility | Per-tenant extension, explicit IDs 70000–75000, no base-app modification. |
| Role-based landing experience | Default Role Centers per permission set. |

## 7. Acceptance Criteria / UAT Scenarios

UAT-01 Restricted item list per reservoir; new producible item = setup change only. ·
UAT-02 BOE quantity = quantity × item UOM factor (liquid and gas items). ·
UAT-03 Posting creates correct Positive/Negative Adjustment lines with dimensions, incl. >3 products. ·
UAT-04 Re-posting blocked; no duplicate lines. ·
UAT-05 Cumulative/Remaining Reserves reflect total BOE across all items. ·
UAT-06 Reserve edit creates revision record; report reflects it. ·
UAT-07 Worksheet matches independent spreadsheet; mid-year revision changes only subsequent periods. ·
UAT-08 Depletion posts via FA G/L Journal with Field dimension. ·
UAT-09 Dry-hole write-off: Successful Efforts expenses; Full Cost leaves capitalised. ·
UAT-10 Royalty: cash → payable; in-kind → inventory adjustment. ·
UAT-11 Non-accountant cannot post but can enter/calculate; lands on Field Operator Role Center. ·
UAT-12 All five reports correct and filterable for >1 item per reservoir.

## 8. Implementation Phasing

| Phase | Duration | Deliverables |
|---|---|---|
| 1 — Foundation & Discovery | Weeks 1–4 | CoA, dimensions, items (+BOE UOM), locations, O&G Setup, Reservoir + Product Setup, Revision History, FA/Dep. Book config; volume discovery. |
| 2 — Production Capture | Weeks 5–8 | Daily Production Entry, Post codeunit, BOE conversion, Item Journal integration, product movement. |
| 3 — Financial Accounting | Weeks 9–12 | Depletion Worksheet + posting, method-aware write-off, royalty (both methods), JV allocation, sales integration. |
| 4 — Reporting, Role Centers & Go-Live | Weeks 13–16 | Five reports, Role Centers, permission sets, UAT, migration, parallel run, go-live. |

## 9. Open Items Requiring Client Input

1. **Naming prefix** — RESOLVED: no prefix; objects named functionally (range 70000–75000 confirmed).
2. **Daily transaction volume** — Phase 1 discovery data.
3. **Initial item list and BOE UOM factors** — required to configure FR-02/FR-03 for go-live.
4. **Royalty settlement terms per field** — to set up FR-25/FR-26 correctly.

## Appendix A — Standard Journal Entry Reference

For reviewer orientation only; actual G/L numbers are set during Chart of Accounts configuration.

| Event | Debit | Credit |
|---|---|---|
| Capitalise well cost | Development Costs | Accounts Payable / Bank |
| Daily production posted (any item) | Product Inventory (per item) | Inventory Adjustment (automatic) |
| Product movement between locations | In-Transit / next-stage location | Prior-stage location |
| Process loss (BS&W removal) | Process Loss expense | Product Inventory |
| Product sale | Accounts Receivable | Product Revenue |
| Cost of goods sold on sale | Cost of Goods Sold | Product Inventory |
| Monthly depletion | Depletion Expense | Accumulated Depletion |
| Government royalty — cash settled | Royalty Expense | Royalty Payable |
| Government royalty — in-kind settled | Royalty Expense | Product Inventory (volume deduction) |
| Dry-hole write-off (Successful Efforts only) | Exploration Expense | Exploration Costs (asset) |
| JV partner cost share | JV Receivable | Lifting Costs |
