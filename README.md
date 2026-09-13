# Oil & Gas Production Accounting — Business Central Extension

Custom **AL extension** for Microsoft Dynamics 365 Business Central implementing the
**O&G Production Accounting FRD/TRD v2.0 (September 2026)** — daily production capture,
BOE conversion, Item Journal integration, Unit-of-Production depletion (Successful
Efforts / Full Cost), royalty accounting (cash & in-kind), JV cost allocation,
dedicated Role Centers and standard O&G reports.

**Publisher:** FMATecH Consulting · **Object range:** 70000–75000 · **Prefix:** none (all objects named functionally)

---

## 1. Project structure

```
OilGas-Extension/
├── app.json                       # Extension manifest
├── .vscode/
│   ├── launch.json                # Sandbox / OnPrem launch configs
│   └── settings.json
├── docs/
│   └── FRD.md                     # Functional & Technical Requirements Specification v2.0
├── src/
│   ├── Tables/                    # 14 custom tables (70000–70016)
│   ├── Codeunits/                 # 10 codeunits (70070–70079)
│   ├── Pages/                     # 24 pages (70030–70053)
│   ├── Reports/                   # 5 reports (70090–70094)
│   ├── PermissionSets/            # FIELD OPERATOR / O&G ACCOUNTANT
│   └── Profiles/                  # Field Operator / O&G Accountant profiles
└── IMPLEMENTATION_NOTES.md        # FR-to-object mapping, UAT guide, open items
```

## 2. Opening this in VS Code

1. **Extract** the zip to a folder (e.g. `C:\dev\OilGas-Extension` or `~/dev/OilGas-Extension`).
2. Install the **AL Language** extension from the VS Code marketplace (Microsoft).
3. **File → Open Folder** → select the `OilGas-Extension` folder (the one containing `app.json`).
4. Press **F5** (or `Ctrl+Shift+B` → Build) to compile/publish.

### First-time setup options

| Scenario | What to do |
|---|---|
| **Microsoft cloud sandbox** | `launch.json` already points at `environmentType: Sandbox`. Sign in to Business Central in the browser when prompted, then F5. |
| **Your own environment (cloud)** | Edit `.vscode/launch.json`: replace `environmentName` with your sandbox/production environment name (or set `"environmentType": "Production"` with your auth context). |
| **On-premises** | Use the `On-premises (Business Central)` configuration — update `serverInstance` and auth to match your deployment. |

> **Note on `app.json`:** `"application": "24.0.0.0"` declares a minimum application version.
> If your environment runs a different major version, either leave it (publishing still works
> and the compiler only warns) or align the value with your environment's version.

> **Troubleshooting — "Table 'Item' is missing" (AL0185):** the Base Application
> symbols are not downloaded in this project. In VS Code: `Ctrl+Shift+P` → **AL: Download
> Symbols** → select **Microsoft cloud sandbox (default)** → wait for *"Successfully
> downloaded symbols."*, then `Ctrl+Shift+P` → **AL: Clean** and rebuild. `.alpackages/`
> must contain `Microsoft_Base Application.app`. All errors of the form
> `Table 'X' is missing` / `Codeunit 'X' is missing` (and the AL0132
> `'None' does not contain a definition for...`, AL0429 *repeater control*, and AL0118
> `Rec` errors that follow them) are cascades of this one environment issue — not code bugs.

## 3. Solution overview

| Capability | FR | Main objects |
|---|---|---|
| O&G Setup (royalty/tax rate, BOE UOM, accounting method, dimensions, posting accounts) | FR-01, FR-09 | `O&G Setup` (70000, 70030) |
| Reservoir master with internally-estimated reserves + automatic revision audit trail | FR-04, FR-05 | `Reservoir` (70001, 70031/70032), `Reserve Revision History` (70003, 70034), `Reserve Revision Logger` (70074) |
| Configurable produced items per reservoir | FR-03, FR-06 | `Reservoir Product Setup` (70002, 70033) |
| BOE conversion via standard Item Units of Measure | FR-02, FR-13 | `O&G BOE Conversion` (70071) |
| Daily production entry (header/lines, BS&W, BOE, post actions) | FR-11–FR-15 | `Production Entry` (70004/70005, 70035/70036/70037) |
| Item Journal generation (no auto-posting) + reservoir update | FR-16–FR-19 | `Post Daily Production` (70070) |
| UOP depletion worksheet + Gen. Journal posting (accounts from O&G Setup) | FR-20–FR-23 | `Depletion Worksheet` (70006, 70038), `Depletion Calculation` (70072) |
| Method-aware exploration write-off | FR-24 | `Exploration Write-off` (70016, 70050/70051, 70073) |
| Royalty — cash & in-kind per field | FR-25, FR-26 | `Royalty Term` (70007), `Royalty Worksheet` (70008, 70041), `Royalty Calculation` (70075) |
| JV cost allocation / partner billing | FR-27 | `JV Partner` (70009), `JV Cost Allocation` (70010/70011, 70044/70045/70046, 70076) |
| Role Centers | FR-10 | `Field Operator Role Center` (70047), `O&G Accountant Role Center` (70048) + profiles |
| Reports | FR-28–FR-32 | `Production Summary` (70090), `Reserve Depletion Status` (70091), `Product Inventory Position` (70092), `Lifting Cost per BOE` (70093), `Reserve Estimate Revision History` (70094) |
| Security | §4.9 | `FIELD OPERATOR` (70140), `O&G ACCOUNTANT` (70141) |

## 4. Configuration before use (go-live checklist)

1. **Dimensions**: create the Field/Block, Well, Reservoir, Cost Center and JV Partner
   dimensions (BC *Dimensions* page, with values) and enter the dimension **codes** in
   `O&G Setup` (FR-07). Optionally default them on the relevant G/L accounts via the
   standard Default Dimensions.
2. **Items + UOM**: create items for every producible product (crude grades, gas,
   condensate, etc.). On each Item Card, add an **alternate Unit of Measure** matching
   the Default BOE UOM code (e.g. `BOE`), e.g. Gas: 1 BOE = 6 MCF; Crude: 1 BOE = 1 BBL.
   In **Reservoir Product Setup**, tick **BS&W Applicable** for the items that need BS&W treatment.
3. **Locations**: create Wellhead, Flow Station, Tank Farm, Pipeline/Transit, Export
   Terminal, FSO Vessel (as applicable) (FR-08).
4. **Fixed Assets & Depreciation Book**: create a Fixed Asset per reservoir using the
   **User-Defined** depreciation method (or manual) with a Depreciation Book, and link
   it on the Reservoir Card (FR-22).
5. **O&G Setup**: default royalty %, production tax %, Default BOE UOM code, Accounting
   Method, dimension codes and posting accounts.
6. **Reservoirs** → Reservoir Product Setup: which items each reservoir produces, with
   default UOM and location; enter 1P/2P/3P estimates, preparer, method and date.
7. **Royalty Terms** per field (rate, basis, settlement method) and **JV Partners**
   (working interests).
8. **Users**: assign the `FIELD OPERATOR` or `O&G ACCOUNTANT` permission set
   (plus the base BC permission sets for Item Journals and Fixed Assets that are
   already in use), and assign the matching **Profile**.

## 5. Day-to-day flow

```
Field operator            Accountant
─────────────────         ───────────────────────────────────────────
Daily Production Entry →  Review & Post Item Journal batch
 (Calculate Net Volumes)   (PROD<YYYYMM>)
 (Post to Item Journal)
                          Period end:
                           Depletion Worksheet → Post Depletion → post Gen. Journal (DEPL<YYYYMM>)
                           Royalty Worksheet   → Post Royalty   → post journal (ROY<YYYYMM>)
                           JV Cost Allocation  → Post Allocation → post journal (JV<YYYYMM>)
                          Reports (FR-28–FR-32)
```

Generated journal batches are **never auto-posted** (FR-18) — the accountant reviews and
posts them in the standard BC Item Journal / Gen. Journal pages.

## 6. Known implementation notes / constraints

- The reports ship with a **dataset only** (no `*.rdl`/`.rdx` layout files). They render
  as Word/Excel-exportable datasets; build the visual layouts (RDLC) in Report Builder
  or use the built-in "Export to Excel" on the request page. See `IMPLEMENTATION_NOTES.md`.
- **Lifting Cost per BOE (70093)** reports the period totals and a running cost-per-BOE
  ratio; filter the G/L Entry data item to your lifting costs (account range and/or
  Cost Center dimension) for a meaningful ratio.
- Batch name convention is `PROD`/`DEPL`/`ROY`/`JV`/`GEN` + `YYYYMM` (Code[10] limit),
  e.g. `PROD202609`.
- Journal **templates are never created by the extension.** You create the Item Journal and
  Gen. Journal templates in Business Central and select them in **O&G Setup**
  (Item Journal Template Name / Gen. Journal Template Name). The extension only creates the
  monthly batches (`PROD`/`DEPL`/`ROY`/`JV`/`GEN` + `YYYYMM`) inside your template.
- No mobile/offline front end, PSC or ARO accounting is included (out of scope per §1.4).

## 7. UAT quick reference

See `IMPLEMENTATION_NOTES.md` §3 for the UAT-01…UAT-12 test scripts mapped to the
acceptance criteria in the FRD. A sample master-data dataset
(ExampleData → O&G Setup, Reservoir, Product Setup, Item setups) is described there
to run UAT-01…UAT-12 quickly.

## 8. License / purpose

This repository is a build-ready starter implementation delivered by FMATecH Consulting
for client implementation. Adapt (within the confirmed 70000–75000 ID range) to the
client's Chart of Accounts, dimensions, and conversions during Phase 1.

## 9. How it works — step-by-step (for the client & end users)

### 9.1 Master data — create once, in this order

1. **Dimensions (Business Central → Dimensions):** create the dimensions and
   their values: `FIELD`, `WELL`, `RESERVOIR`, `COST CENTER`, `JV PARTNER`.
   *These ARE your field/well/reservoir master data* — the extension looks
   up and links to them everywhere (Reservoir Card, Production Entry Card),
   so a field/well/reservoir is just a dimension value. The O&G Setup
   dimension-code fields must contain exactly these codes.
2. **O&G Setup (new page, auto-creates one record `DEFAULT`):** enter the
   journal templates you created (`Item Journal Template Name`,
   `Gen. Journal Template Name`), the 7 posting accounts, the default BOE
   unit of measure, accounting method, royalty/tax rates and the dimension
   codes. *The extension never creates templates, items, dimensions or
   accounts — everything is yours.*
3. **Items + Units of Measure:** create the produced items (crude, gas, NGL,
   condensate, water…) and, on each item's **Item Units of Measure**, define
   the alternate UOM that represents one BOE (e.g. 1 BOE = 1 BBL oil,
   1 BOE = 6 MCF gas). That is the only BOE logic — no custom factor table.
4. **Reservoir Card:** new reservoir = pick a RESERVOIR dimension value, plus
   its FIELD/WELL/COST CENTER dimension values (looked up from dimensions),
   status, reserve estimates (1P/2P/3P, prepared by, method, date — every
   change is logged in Reserve Revision History) and the capitalised cost.
   **Cumulative Production BOE, Remaining Reserves BOE, Accumulated
   Depletion are NOT entered — they are calculated automatically** from the
   postings (see 9.3).
5. **Reservoir Product Setup:** which items this reservoir may produce, their
   default UOM, location, and whether BS&W applies.
6. **Royalty Term** per field/block (rate, basis, cash or in-kind, accounts)
   and **JV Partner** (working interest %, JV receivable account).

### 9.2 Daily — field operator

1. **Production Entry (Field Operator role):** new document → choose the
   Reservoir — the Field/Block and Well are filled and locked from the
   reservoir (they are dimension values). Enter the line items, quantities
   and BS&W %.
2. **Calculate Net Volumes** → net quantity (gross × (1 − BS&W)) and BOE
   quantity (via the item's UOMs) are calculated for every line.
3. **Post to Item Journal** → an **Item Journal batch** is created (one per
   month, e.g. `PROD202609`) containing the positive adjustment + BS&W
   removal lines, with dimensions (Field/Well/Reservoir/Cost Center) already
   set. **Nothing is posted to G/L by the extension.** The document shows the
   batch name — click it to jump to the batch.
4. **Accountant:** review the Item Journal batch → **Post** it (standard BC
   Item Journal posting, using the client's own posting groups/accounts).

### 9.3 Period-end — depletion, royalty, JV

- **Depletion Worksheet → Suggest Lines:** for each producing reservoir the
  extension computes the UOP rate `(Capitalised Cost − Accumulated
  Depletion) / Remaining Reserves` and the period amount; **Post** creates
  Dr Depletion Expense / Cr Accumulated Depletion lines in the Gen. Journal
  batch; the accountant posts the batch. Because **Accumulated Depletion**
  and **Cumulative Production BOE** are FlowFields (sums of posted
  documents), the Reservoir Card shows live figures — no one types them.
- **Royalty Worksheet:** same pattern — cash royalty → Gen. Journal
  (Expense/Payable), in-kind → Item Journal negative adjustment.
- **JV Cost Allocation:** see 9.4.
- **Reserve revisions:** editing 1P/2P/3P on the Reservoir Card writes a
  Reserve Revision History record (preparer, method, basis, date).
- **Reports:** Production Summary, Reserve Depletion Status, Product
  Inventory Position, Lifting Cost per BOE, Reserve Revision History.

### 9.4 Why a JV Cost Allocation card — and why not the standard Allocation?

The standard Business Central **Allocation** (Gen. Journal lines with
allocation % / keys) distributes a journal amount across **dimensions
(mostly cost centers) inside your own company** for management-accounting
purposes. It cannot do Joint Venture accounting because it:

- has no **partner master** (no working interest % per partner),
- cannot create a **per-partner receivable/payable** entry (a receivable
  from the other working-interest owners),
- cannot use **partner-specific accounts and dimensions** per line,
- is not driven by an **operator cost document** you can review/approve
  before posting, and
- cannot bill each partner exactly its share with full audit traceability.

The **JV Cost Allocation Card** therefore captures the operator's cost
document (header: field/block, date, total, document no.), the **lines** are
the cost breakdown, and the **Allocate/Post** action splits the total across
partners by their working interest % and generates, per partner, a Gen.
Journal line (Dr partner receivable / Cr JV cost) using the JV Partner's
account and the JV Partner dimension. The accountant then posts the batch.
Under the hood it uses the same standard journaling as everything else —
only the allocation logic is purpose-built (FR-27).

### 9.5 O&G Setup — the single setup record

O&G Setup is a one-record page (key `DEFAULT`). It is created automatically
the first time you open it. From v1.0.6 the existence check sets the key
before reading, so the page opens cleanly every time. If you ever saw
*“The record in table O&G Setup already exists. Primary Key='DEFAULT'”*, it
was the old bug (page tried to create the record again on every open) — the
v1.0.6 package fixes it; you do not need to clean up anything, the single
`DEFAULT` row is the one and only record.
