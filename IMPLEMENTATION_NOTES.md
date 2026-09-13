# O&G Extension — Implementation Notes

Companion to the FRD/TRD v2.0 (September 2026). Mapping, technical decisions,
UAT scripts and open items for the build/implementation team.

---

## 0h. v1.0.9 — compiler errors AL0926 + AL0223 fixed (v1.0.6 regressions)

Reported from the client's VS Code build (these masked behind / survived the
v1.0.8 relation fix):

1. **AL0926** (`ReservoirCard.Page.al`): the `OnAfterGetRecord` trigger added
   in v1.0.6 sat between `layout` and `actions`. Page sections must run
   layout → actions → triggers, so the trigger moved to after the `actions`
   block. Swept all 24 pages — no other trigger-before-actions case.
2. **AL0223 ×2** (`Reservoir.Table.al`, fields 13 & 19): `DataClassification`
   is illegal on `FieldClass = FlowField` fields — removed from both
   FlowFields (kept on all Normal fields). Swept all tables — zero
   FlowFields still carry it.

Also bumped `app.json` to 1.0.9.0.

---

## 0g. v1.0.8 — TableRelation self-filter defect fixed (v1.0.6 regression)

**Defect:** the 10 TableRelations added in v1.0.6 each filtered the related
table on the field itself, e.g.
`"Dimension Value" where("Dimension Code" = const('FIELD'), "Code" = field("Field/Block Code"))`
on the `"Field/Block Code"` field itself (same pattern on the 4 journal-batch
relations). A field must not filter its own relation on itself: it trips the
compiler / breaks the lookup (the dropdown is pre-filtered to the field's own
current value, so it opens empty on a new record).

**Fix (canonical Base Application pattern, as on "Global Dimension 1 Code"):**
relate to the *field*, filtered only by the fixed dimension — e.g.
`TableRelation = "Dimension Value".Code where("Dimension Code" = const('FIELD'), Blocked = const(false));`
Journal-batch relations are now plain field relations with no self-filter:
`"Item Journal Batch".Name` / `"Gen. Journal Batch".Name` (the template is
client data in O&G Setup, so it is deliberately not const'd).
All 10 relations rewritten (6 dimension + 4 journal batch); zero `field()`
self-filters remain. Also bumped `app.json` to 1.0.8.0 so the app publishes
over any previously installed 1.0.0.0 build.

---

## 0f. v1.0.7 — sample/test data pack + non-convertible item handling

1. **Sample data pack added** — `docs/SAMPLE_DATA_GUIDE.md` +
   `docs/SampleData/` (CSVs + `OG_SampleData.xlsx`): a complete, coherent
   test dataset (2 reservoirs, 5 items, UOM/BOE factors, royalty terms, JV
   partners, 2 production documents) with exact expected results for
   production, depletion, royalty and JV tests. Data is *entered by the
   client* (paste into list pages / enter on cards); the extension still
   creates nothing.
2. **`O&G BOE Conversion`**: an item without a BOE Unit of Measure (e.g.
   produced water) now contributes **0 BOE** instead of raising an error and
   blocking the posting (documented; factor still configured per item UOM).
3. Documented design clarifications (for client sessions):
   - **BS&W** = Basic Sediments & Water: the water/emulsion content of crude
     measured at the measuring point; net = gross × (1 − BS&W%); royalty and
     production volumes are on **net** barrels; the extension creates a
     negative-adjustment line for the removed water volume. Configurable per
     reservoir/item ("BS&W Applicable").
   - **Transit** (field → terminal movement, losses, master metering) is
     NOT in FRD v2.0: production is booked at the location set on Reservoir
     Product Setup; inter-location movement uses standard BC Item Transfers
     (a TRANSIT location can model in-transit stock). A dedicated
     transit/LACT module is a scope decision (see §8 of the guide).
   - **JV Partner table holds non-operator partners only** — the operator's
     working interest share remains on the cost account; per-partner
     receivable lines are created for the other partners.
4. **Decisions confirmed with the client team (2026-09-09):**
   - **Transit** is handled with **standard BC Item Transfers** (no module);
     transit losses / LACT master-meter differences are documented as a
     Phase-2 option, out of scope of FRD v2.0.
   - **Royalty on produced water stays**: royalty applies to every net
     production line of the field; an "Exclude from Royalty" flag is a
     documented future option if concession terms exempt water.

---

## 0e. v1.0.6 — dimension relations, automated reservoir figures, setup-page fix

Client review round:

1. **Dimension master-data relations.** Field/Block, Well, Reservoir and Cost
   Center codes are now values of the standard Business Central **Dimension
   Value** table (the extension uses BC dimensions as master data instead of
   custom Field/Well tables). Relations added on:
   - `Reservoir` → Reservoir Code (RESERVOIR dim), Field/Block (FIELD dim),
     Well (WELL dim), Cost Center (COST CENTER dim)
   - `Production Entry Header` → Field/Block, Well (same dims)
   - **Convention (documented in README §9):** the dimension codes used in
     these relations are `FIELD`, `WELL`, `RESERVOIR`, `COST CENTER` — enter
     the same names in O&G Setup (they are read at posting time to build the
     dimension sets). If you prefer different codes, tell us and we adjust
     the `const('...')` in the relations.
2. **Journal batch traceability.** `Production Entry Header` → Item Journal
   Batch relation; Depletion Worksheet / JV Cost Allocation Header /
   Exploration Write-off → Gen. Journal Batch relation — one click from the
   document to the batch that must still be posted by the accountant.
3. **Reservoir figures are now AUTOMATIC (no manual entry)** — `Cumulative
   Production BOE` and `Accumulated Depletion` are **FlowFields** summed from
   posted documents (Production Entry Header / Depletion Worksheet). All
   manual accumulation code removed. `Remaining Reserves BOE` remains
   computed (1P − cumulative, kept in sync in code). Values show read-only
   on the Reservation Card; deletion of a posted document is the only way to
   "reverse" them (or reverse the journaling), so figures always derive from
   actual postings.
4. **O&G Setup "record already exists" bug fixed.** The `OnInit` trigger
   checked existence with a blank key, so the 2nd open always tried to insert
   `Primary Key='DEFAULT'` again. The key is now set before `Get()`.
5. **IDs changed by client:** `Date Range` 70012→**70015**, `Exploration
   Write-off` 70013→**70016** (conflict with existing extensions) — updated
   in this package.

---

## 0d. v1.0.5 — BC 26 base-object name corrections

Fourth compiler round feedback (BC 26 sandbox, symbols now downloaded):

1. **`Codeunit "Dimension Management"` → `Codeunit "DimensionManagement"`** —
   in current Business Central the base application codeunit (formerly NAV 408)
   is named **`DimensionManagement`** (no space). The earlier `"Dimension
   Management"` fix was based on the legacy NAV-era name and is not valid on
   BC 26; this is now aligned with the official reference
   (*Codeunit DimensionManagement* — `microsoft.finance.dimension.
   dimensionmanagement`).
2. **`G/L Entry."Account No."` → `G/L Entry."G/L Account No."`** — the G/L
   Entry table field is named `G/L Account No.` in current Business Central;
   this affected the *Lifting Cost per BOE* report column.

---

## 0c. v1.0.4 — no hardcoded setup; base codeunit name fix

Third compiler round feedback (BC 26 sandbox):

1. **`Codeunit "DimensionManagement"` → `"Dimension Management"`** — the base
   application codeunit 408 is named `Dimension Management` (with a space);
   the old name was a genuine AL0185 bug in `Dimension Helper`.
2. **The extension never creates journal templates anymore.** Previously
   `Journal Helper` auto-created the `ITEM` template (and defaulted missing
   G/L template names to `GENERAL`). Per client requirement, you now create
   the templates yourself:
   - **Item Journal template** (production + in-kind royalty postings) —
     create it in Business Central (*Item Journal Templates*) and select it
     under *O&G Setup → Journaling → **Item Journal Template Name*** (new
     O&G Setup field 70000, field 19).
   - **Gen. Journal template** (depletion / royalty cash / JV / write-off) —
     create it in Business Central (*General Journal Templates*) and select it
     under *O&G Setup → **Gen. Journal Template Name***.
   - If a template is missing or not selected, posting stops with a clear
     message naming the template and where to set it. The extension only
     creates the monthly *batches* inside your template.
3. **Items, UOMs, dimensions, G/L accounts** — already 100% client setup:
   the extension reads the BOE UOM from O&G Setup and the item's Item Units
   of Measure; dimensions are read from O&G Setup dimension codes and
   resolved via `Dimension Management`.

### If you see "Table 'Item' is missing" / "Codeunit ... is missing" (AL0185)

These errors mean the compiler cannot see the **Base Application symbols**
in the current VS Code project (they are not part of the zip — each machine
downloads them once). They are NOT code errors; nearly all other errors in
that dump (AL0132 `'None' does not contain a definition...`, AL0429
"repeater control", AL0118 `Rec`) are cascades of the same missing symbols.
Fix in VS Code:

1. `Ctrl+Shift+P` → **AL: Download Symbols** → select
   **"Microsoft cloud sandbox (default)"** → wait for *"Successfully
   downloaded symbols."*
2. Check `.alpackages/` contains `Microsoft_Base Application.app`
   (and `Microsoft_System Application.app`).
3. `Ctrl+Shift+P` → **AL: Clean** (clears stale diagnostics), then rebuild
   (`Ctrl+Shift+B` or Publish).
4. If you publish to On-Premises instead, the launch config
   `serverInstance: BC` must be your reachable BC service — the
   "Microsoft cloud sandbox" config is the recommended one.

---

## 0b. v1.0.2 / v1.0.3 — second compiler round (& FMA removal)

Fixes applied after the second full VS Code diagnostic dump (BC 26 sandbox):

1. **`FMA` prefix removed from every object** — objects, identifiers, file
   names, captions and all cross-references renamed functionally
   (e.g. `FMA Production Entry Header` → `Production Entry Header`).
   Publisher and extension display name stay FMATecH branded.
2. **app.json**: deleted `showMyCode` (conflicts with `resourceExposurePolicy`).
3. **Multi-field table keys use comma syntax**: `key(Name; Field1, Field2)`.
4. **`Page.RunModal(...)` returns `Action`** → calls compare `= Action::OK`.
5. **Role Center actions use `RunObject = page/report "Name"`** (no `RunPage`);
   all empty report run-object references filled; action areas are flat
   (Embedding = actions only, no AL code).
6. **Permission sets**: non-table objects use execute-only `= x`;
   data access via `tabledata ... = rimd/r`.
7. **`Year()`/`Month()` replaced** with `Date2DMY(...)`-based helpers
   (`PeriodStartByMonth`/`PeriodEndByMonth` in Production Entry Helper),
   and all four call sites in Depletion/Royalty calculation were aligned to
   those names (fixes AL0132).
8. **AL0118 (NoImplicitWith)**: with `"NoImplicitWith"` in app.json features,
   implicit-with is an error, so **every page layout field binding is now
   explicitly `Rec."Field"`** and **every report column is
   `<DataItemVar>."Field"`**; the O&G Setup page was also missing its
   `SourceTable = "O&G Setup";` (restored).
9. Duplicate `ProductionLines` control name on Production Entry Card renamed
   (`ProductionLinesGroup`); Lifting Cost per BOE report rebuilt with
   columns before triggers.

---

## 0. v1.0.1 — BC 26 compatibility fixes (compile-clean)

This revision fixes every compile error reported against the v1.0.0 build and
removes all hardcoded process decisions:

1. **Depletion posting now uses the Gen. Journal** (not the FA G/L Journal —
   the classic `FA G/L Journal Template/Batch/Line` tables no longer exist in
   current Business Central). Accounts are selected in **O&G Setup**
   (`Depletion Expense Account`, `Accumulated Depletion Account`), and the
   **journal template** used for depletion/royalty/JV/write-off lines is
   selected in **O&G Setup → Gen. Journal Template Name** (defaults to
   `GENERAL`). Nothing is hardcoded.
2. **BS&W flag moved to Reservoir Product Setup** (`BS&W Applicable` per
   reservoir/item) — the Item Card/table extensions were removed entirely
   (they fragmented across BC versions); the flag is now a client setup choice.
3. **Role Centers contain no AL code** (BC forbids triggers on Role Center
   pages) — all actions are property-based (`RunPage` / `RunObject`).
4. **Renamed objects** (names > 30 chars are rejected):
   - Report `70094` → `Reserve Revision History`
   - Page `70053` → `Pending Item Jnl Batches`
   - Field `Default BOE Unit of Measure Code` → `Default BOE UOM Code`
5. Language fixes: no `Caption` on codeunits / no `DataCaption`/`LookupPage`/
   `DrillDownPage` on tables; `FindSet()` called with `SetRange` first; page
   `OnNewRecord(BelowxRec: Boolean)`; `Page.RunModal` used for prompts;
   profile object names are identifier-safe; `Message()` used instead of
   `Info()` (correct signature).
6. Worksheet "suggest" runs delete **only unposted** rows — posted history and
   audit trail are never removed.

---

## 1. Object inventory (ID range 70000–75000)

| ID | Type | Name | Purpose |
|---|---|---|---|
| 70000 | Table | O&G Setup | Single-record setup (FR-01, FR-09) |
| 70001 | Table | Reservoir | Reservoir master + internally-estimated reserves (FR-04/05) |
| 70002 | Table | Reservoir Product Setup | Permitted items per reservoir (FR-03/06) |
| 70003 | Table | Reserve Revision History | Reserve change audit trail (FR-05/32) |
| 70004 | Table | Production Entry Header | Daily production document (FR-11) |
| 70005 | Table | Production Entry Line | Production lines, BS&W, BOE (FR-11/12/13) |
| 70006 | Table | Depletion Worksheet | UOP calculation (FR-20/21/22) |
| 70007 | Table | Royalty Term | Per-field royalty terms (FR-25/26) |
| 70008 | Table | Royalty Worksheet | Royalty calculation (FR-25/26) |
| 70009 | Table | JV Partner | Partners + working interest (FR-27) |
| 70010 | Table | JV Cost Allocation Header | Allocation document (FR-27) |
| 70011 | Table | JV Cost Allocation Line | Cost lines (FR-27) |
| 70015 | Table | Date Range | Prompt record for batch actions |
| 70016 | Table | Exploration Write-off | Dry-hole write-off doc (FR-24) |
| 70030 | Page | O&G Setup | Setup (admin only) |
| 70031 | Page | Reservoir List | |
| 70032 | Page | Reservoir Card | + product setup subpage, revision drill-down |
| 70033 | Page | Reservoir Product Setup | Subpage (ListPart) |
| 70034 | Page | Reserve Revision History | Read-only list |
| 70035 | Page | Production Entry List | + Post All Open Entries (FR-15) |
| 70036 | Page | Production Entry Card | Header + lines + actions (FR-11/15) |
| 70037 | Page | Production Entry Line | ListPart with validation (FR-03/12/13) |
| 70038 | Page | Depletion Worksheet | + Suggest Lines / Post Depletion |
| 70039–70040 | Pages | Royalty Term List / Card | |
| 70041 | Page | Royalty Worksheet | + Suggest Royalty / Post Royalty |
| 70042–70043 | Pages | JV Partner List / Card | |
| 70044–70046 | Pages | JV Cost Allocation List / Card / Line | |
| 70047 | Page | Field Operator Role Center | FR-10 |
| 70048 | Page | O&G Accountant Role Center | FR-10 |
| 70049 | Page | Date Range | Prompt |
| 70050–70051 | Pages | Exploration Write-off List / Card | |
| 70052 | Page | Open Production Entries | Role center cue part |
| 70053 | Page | Pending Item Jnl Batches | Role center cue part |
| 70070 | Codeunit | Post Daily Production | FR-15…19 |
| 70071 | Codeunit | O&G BOE Conversion | FR-02/13 |
| 70072 | Codeunit | Depletion Calculation | FR-20…23 |
| 70073 | Codeunit | Exploration Write-off | FR-24 |
| 70074 | Codeunit | Reserve Revision Logger | FR-05 |
| 70075 | Codeunit | Royalty Calculation | FR-25/26 |
| 70076 | Codeunit | JV Cost Allocation | FR-27 |
| 70077 | Codeunit | Dimension Helper | FR-07 |
| 70078 | Codeunit | Production Entry Helper | FR-11/12/13/19 |
| 70079 | Codeunit | Journal Helper | Batch/line creation for Item/Gen./FA journals |
| 70090–70094 | Reports | FR-28…FR-32 (70094 = "Reserve Revision History") | Datasets only (see §4 below) |
| 70140/70141 | PermissionSets | Field Operator / O&G Accountant | §4.9 |
| 70150/70151 | Profiles | Field Operator / O&G Accountant | FR-10 |

## 2. Key technical decisions

1. **BOE conversion reuses the standard Item Units of Measure** (FR-02). Each producible
   item carries an alternate UOM matching the Default BOE UOM code with the client-owned
   factor (e.g. Gas: 1 BOE = 6 MCF; crude: 1 BOE = 1 BBL). `O&G BOE Conversion`
   (70071) uses `Item Unit of Measure` — no custom conversion table. If the alternate UOM
   is missing, posting/calculation raises a clear configuration error (fail fast, no
   silent zeros except for zero quantities, which return 0 BOE).
2. **No silent automation** (NFR §6): every generated batch (`PROD*`, `DEPL*`, `ROY*`,
   `JV*`, `GEN*`) is created but **not posted**. Posting remains a deliberate accountant
   action in the standard Item Journal / Gen. Journal pages (FR-18, FR-22).
3. **Dimensions** (FR-07) are applied through the standard `DimensionManagement`
   codeunit (`GetDimensionSetID`) using the dimension codes configured in O&G Setup.
   Dimension values come from the document (Field/Block, Well, Reservoir, Cost Center,
   JV Partner). No dimension hardcoding.
4. **Reserve revisions** (FR-05/23): the `Reservoir` table `OnModify` trigger detects
   changes to 1P/2P/3P figures or estimation metadata, logs a `Reserve Revision
   History` record (previous/revised value, date, preparer, basis), and keeps
   `Remaining Reserves BOE` in sync (1P − cumulative). A guarded re-Modify terminates
   the recursion. Depletion uses the current (possibly revised) reserves prospectively;
   posted periods are never restated.
5. **Accounting method** (FR-09/24): the write-off action branches on `O&G Setup →
   Accounting Method`. Successful Efforts → immediate Dr Exploration Expense /
   Cr Exploration Costs in a `GEN<YYYYMM>` batch; Full Cost → document marked posted
   with **no journal lines** (cost stays in the pool). Both methods are built — the
   client elects via setup (UAT-09).
6. **Royalty** (FR-25/26): one calculation engine; posting branches per field on
   Settlement Method: Cash → Dr Royalty Expense / Cr Royalty Payable (Gen. Journal);
   In-Kind → Negative Adjustment Item Journal line reducing inventory. Account overrides
   come from the Royalty Term, falling back to O&G Setup.
7. **Journal names**: `PROD`/`DEPL`/`ROY`/`JV`/`GEN` + `YYYYMM` (≤10 chars). Monthly
   batches: `PROD202609` etc. Document numbers on generated lines link back to the
   source document (FR-17, FR-22 traceability).
8. **Permission-based segregation of duties** (NFR): even though the *Post* actions exist
   on the user-visible pages, only the `O&G ACCOUNTANT` permission set grants
   execute rights on the posting codeunits — a field operator clicking them gets a
   permission error (UAT-11).
9. **Idempotency**: `Post Daily Production` raises a controlled error on an already
   posted document (FR-14/UAT-04); all worksheet "suggest" actions delete only the
   unposted lines and regenerate.
10. **Standard journal templates** (`ITEM`, `GENERAL`, `FA`) are auto-created only if
    missing; existing client templates are reused (no modification).

## 3. UAT scripts (mapped to FRD §7)

| UAT | How to execute against this build |
|---|---|
| UAT-01 | Reservoir Card → Permitted Produced Items: add/block items; start a Production Entry and confirm the Item lookup/validation only allows permitted items; adding a new product = one setup row, no code change. |
| UAT-02 | Items: alternate UOM BOE (e.g. gas 6 MCF = 1 BOE; crude 1 BBL = 1 BOE). Enter 12 MCF → BOE = 2; enter 500 BBL → BOE = 500. |
| UAT-03 | Production Entry with 4+ items (crude, condensate, gas, e.g. NGL) → Post to Item Journal → open Item Journal `PROD<YYYYMM>`: Positive Adjustment per item, Negative Adjustment for the BS&W volume, correct dimensions, Document No. = production document. |
| UAT-04 | Re-run Post on the same document → error, no duplicate lines. |
| UAT-05 | After posting, `Reservoir → Cumulative Production BOE / Remaining Reserves BOE` = summed BOE of all items. |
| UAT-06 | Change 1P on Reservoir Card → new `Reserve Revision History` row (preparer/date/basis) and report 70094 shows it. |
| UAT-07 | Depletion Worksheet vs. an independent spreadsheet for two periods; change 1P mid-year → only subsequent periods change (FR-23). |
| UAT-08 | Post Depletion → Gen. Journal batch `DEPL<YYYYMM>`: Dr Depletion Expense / Cr Accumulated Depletion (accounts from O&G Setup), Field dimension populated. |
| UAT-09 | Toggle O&G Setup Accounting Method between runs: Successful Efforts → GEN batch created; Full Cost → no lines, document marked posted. |
| UAT-10 | Field A Settlement Method = Cash → Royalty Payable; Field B = In-Kind → negative inventory adjustment; same Suggest logic. |
| UAT-11 | User with only `FIELD OPERATOR`: enters/calculates production, cannot run Post (permission error), lands on Field Operator Role Center. Accountant set does all of the above. |
| UAT-12 | Run all five reports against test data with 2+ items per reservoir; verify filters (field, well, item, date). |

## 4. Reports — important note

Reports 70090–70094 are delivered with **dataset-only definitions** (AL `dataset`), which
is deliberate: RDLC layouts are binary artefacts best created against the target
environment (Report Builder / drag-and-drop) and are excluded here. To use:

- Open any report from the request page and use **Export → Excel/Word** (the dataset is
  exportable), or
- Right-click add a Word/Excel layout, or
- Design the RDLC in Report Builder using the published report dataset.

Production Summary (70090), Reserve Depletion Status (70091) and Reserve History (70094)
include computed columns (Net Book Value, etc.); Inventory Position (70092) reads
standard Item Ledger Entries (filter by date for the as-of position); Lifting Cost
(70093) reads G/L Entries (filter to lifting cost accounts / Cost Center dimension) and
shows the period total cost, total production BOE and running cost per BOE.

## 5. Open items carried from FRD §9

1. **Naming prefix** — RESOLVED: no prefix; all objects named functionally (e.g. "Production Entry Header"), range 70000–75000.
2. **Daily transaction volume**: to be confirmed in Phase 1 discovery — the design uses
   SIFT-enabled keys on `Production Date`/`Reservoir Code` filters; no further change
   expected.
3. **Initial item list + BOE UOM factors**: needs the client's actual produced-item list
   (open item 3) for Item + Item Units of Measure setup.
4. **Royalty settlement method per field**: needs the client's contract terms to
   complete `Royalty Term` setup.
5. *This build adds*: O&G Setup dimension-code + posting-account fields (not in the FRD
   table §4.1) — required to make FR-07/FR-22/FR-24/FR-26/FR-27 work without
   hardcoding. Confirm the chart-of-accounts mapping during Phase 1.

## 6. Build/publish checklist

- [ ] `app.json` application version matches target environment (or accept warning).
- [ ] AL Language extension installed; **F5** builds and publishes (Cloud sandbox default).
- [ ] Code analysis can be enabled (`al.enableCodeAnalysis: true`) for extra checks.
- [ ] After first deploy: `O&G Setup` (page 70030) → default values; create dimensions,
  items (with BOE alternate UOM), locations, FA + depreciation book, reservoirs +
  product setups, royalty terms, JV partners; assign permission sets + profiles.
- [ ] Sign-off the UAT-01…UAT-12 script before go-live (Phase 4).
