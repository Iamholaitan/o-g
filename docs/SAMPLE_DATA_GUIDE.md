# Sample Data & Test Guide (v1.0.7)

Everything you need to run a complete end-to-end test of the O&G extension in
about **30 minutes**, using only master data you create yourself (the
extension creates nothing). Files:

- `SampleData/OG_SampleData.xlsx` — same data as an Excel workbook (best for
  copy/paste into Business Central list pages).
- `SampleData/*.csv` — the same rows in CSV, one file per table.

> **How to load:** open the relevant BC list page and **paste** the rows
> (Excel → copy → click first cell → Ctrl+V works on editable list pages).
> O&G Setup is a *Card*, so its values are entered manually from sheet `06`.
> Base records (Items, UOMs, Locations, Dimensions) are created via their
> own BC pages (Items, Item Units of Measure, Locations, Dimensions) —
> the sample values tell you exactly what to enter.

---

## 1. What you must create first (Business Central, not the extension)

| Step | BC page | What to create |
|---|---|---|
| 1 | **Dimensions** | `FIELD`, `WELL`, `RESERVOIR`, `COST CENTER`, `JV PARTNER` (see `01/02`) |
| 2 | **Locations** | `LOC-01`, `LOC-02`, `LOC-03` (see `05`) |
| 3 | **Items** | `CRUDE-OIL`, `NATURAL-GAS`, `NGL`, `CONDENSATE`, `PROD-WATER` (see `03`) |
| 4 | **Item Units of Measure** (Item Card) | the UOMs + BOE factors (see `04`) |
| 5 | **Item Journal Templates** | `ITEM` |
| 6 | **General Journal Templates** | `GENERAL` |
| 7 | **Chart of Accounts** | the G/L accounts used in `06` (or your own codes — then edit O&G Setup) |

**BOE factors (the only place conversion lives — your Item UOMs):**

| Item | UOM | Qty. per UOM | Means |
|---|---|---|---|
| CRUDE-OIL | BBL | 1 | base UOM |
| CRUDE-OIL | BOE | 1 | **1 BBL oil = 1 BOE** |
| NATURAL-GAS | MCF | 1 | base UOM |
| NATURAL-GAS | BOE | 6 | **6 MCF gas = 1 BOE** |
| NGL | BBL | 1 | base UOM |
| NGL | BOE | 1 | 1 BBL NGL = 1 BOE |
| CONDENSATE | BBL | 1 | base UOM |
| CONDENSATE | BOE | 1 | 1 BBL condensate = 1 BOE |
| PROD-WATER | BBL | 1 | **no BOE UOM** → contributes 0 BOE (by design) |

## 2. O&G Setup (single record `DEFAULT` — enter on the page)

Values from `06_OGSetup.csv`. The two journal templates you created in step 1
are referenced here — they are **never created by the extension**.

## 3. Extension tables (paste into these pages)

| Page | CSV | Notes |
|---|---|---|
| Reservoir List / Card | `07` | Field/Block, Well, Reservoir, Cost Center are **dimension values** — pick from the lookups. Cumulative/Remaining/Accumulated Depletion are **read-only automatic**. |
| Reservoir Product Setup | `08` | BS&W Applicable only on CRUDE-OIL (realistic). |
| Royalty Term | `09` | FIELD-01 = Cash @10%, price 70; FIELD-02 = In-Kind @8%, price 3.50. |
| JV Partner | `10` | **Non-operator partners only** (30% + 25%). The operator's share (45%) stays on the cost account — see §6. |

## 4. Test 1 — Daily production (Field Operator)

1. **Production Entry List → New.**
   - Doc `PROD-260915-01`, date `15-09-2026`, Reservoir `RES-01`
     → Field/Block `FIELD-01` and Well `W-001` fill in **and lock**.
2. Add the 4 lines from `12_ProductionLinesSample.csv` (first 4 rows —
   CRUDE-OIL 1,200 BBL **BS&W 4%**, NGL 80, CONDENSATE 40, WATER 350).
3. **Calculate Net Volumes** → see:
   - CRUDE-OIL: Net = 1,200 × (1 − 0.04) = **1,152 BBL**, BOE = 1,152
   - NGL 80 → 80 BOE · CONDENSATE 40 → 40 BOE · WATER 350 → **0 BOE**
   - Header **Total BOE = 1,272**
4. **Post to Item Journal.** Message shows batch **`PROD202609`**. Document
   becomes *Posted*, the batch name is on the header (click it → jumps to the
   Item Journal batch). Batch contains: CRUDE +1,152 · NGL +80 · CONDENSATE
   +40 · WATER +350 · CRUDE **−48** (BS&W removal = 1,200 − 1,152).
5. Repeat for `PROD-260915-02` / `RES-02`: GAS 6,000 MCF → BOE **1,000**.
6. **Accountant:** Item Journals → open `ITEM / PROD202609` → **Post** (this
   is the only step that touches G/L, and it is always a human action).

**Check on Reservoir Card RES-01:** Cumulative Production BOE = **1,272**
(auto), Remaining Reserves BOE = 1,800,000 − 1,272 = **1,798,728** (auto),
Accumulated Depletion = 0 (nothing posted yet).

## 5. Test 2 — Depletion (period end, Accountant)

1. **Depletion Worksheet → Suggest Lines**, posting date `30-09-2026`.
2. Lines (calculated, not typed):
   - RES-01: NBV 25,000,000 − 0 = 25,000,000 · Remaining 1,798,728
     · Rate = 25,000,000 / 1,798,728 = **13.898711/BOE** · Period prod 1,272
     · **Amount = 17,679.16**
   - RES-02: NBV 12,000,000 · Remaining 2,399,000 · Rate **5.002084/BOE**
     · Period prod 1,000 · **Amount = 5,002.08**
3. **Post** → Gen. Journal batch `DEPL202609` created (Dr 61100 / Cr 29100,
   dimensions set automatically). Accountant posts the batch.
4. Reservoir Card: **Accumulated Depletion = 17,679.16** (auto),
   Depletion Rate per BOE = 13.898711 (last calculated).

## 6. Test 3 — Royalty (per field)

1. **Royalty Worksheet → Suggest Lines**, posting date `30-09-2026`.
2. FIELD-01 (Cash, 10%, price 70) — on **net** quantities:

   | Item | Net | Royalty Vol | Royalty Amount |
   |---|---|---|---|
   | CRUDE-OIL | 1,152 | 115.2 | **8,064.00** |
   | NGL | 80 | 8.0 | **560.00** |
   | CONDENSATE | 40 | 4.0 | **280.00** |
   | PROD-WATER | 350 | 35.0 | **2,450.00** |

   → Post → Gen. Journal batch `ROY202609` (Dr 62100 / Cr 29901). Total
   **11,354.00**. *(Water currently bears royalty too — see §8.)*
3. FIELD-02 (In-Kind): **Post** → Item Journal batch `ROY202609` with
   negative adjustments for 8% of the gas volume (600 MCF negative).

## 7. Test 4 — JV Cost Allocation

1. **JV Cost Allocation List → New**: `JV-2609001`, FIELD-01, date
   `30-09-2026`. Lines: 61900 Well Workover **6,000** · 61200 Lifting Costs
   **4,000** (total 10,000).
2. **Allocate/Post** → Gen. Journal batch `JV202609`:
   - PTN-02 (30%): Dr 13100 **3,000** / Cr cost **3,000** (per line)
   - PTN-03 (25%): Dr 13100 **2,500** / Cr cost **2,500**
   - **Operator's own 45% (= 4,500) stays on the cost account** — that is why
     the JV Partner table holds only the *non-operator* partners.
3. Accountant posts the batch. Each line carries the JV Partner dimension.

## 8. Decisions & how to demo them

**(Decided with the client team, 2026-09-09)**

1. **Transit — use standard Business Central Item Transfers.** No new module.
   - Production is booked into the location set on Reservoir Product Setup
     (`LOC-01` field storage / `LOC-02` gas plant).
   - To move volumes field → terminal: standard **Item Transfer Orders**
     (or post a transfer journal) to `LOC-03` / a `TRANSIT` location; the
     standard **Item Transfers** page shows in-transit quantities.
   - Recommended demo: create `LOC-03` (Terminal) and a `TRANSIT` location;
     post a transfer `LOC-01 → TRANSIT → LOC-03` for part of the crude and
     show the Item Ledger Entries. Open item: if the client later needs
     shrinkage/loss % or LACT master-meter differences, that is a Phase 2
     module (documented as out of scope of FRD v2.0).
2. **Royalty on produced water — stays as designed.** Royalty applies to
   every net production line of the field under the Royalty Term. Flag for
   the client: if their concession/PPA terms exempt water, we add an
   "Exclude from Royalty" flag on Reservoir Product Setup later (one small
   change).
3. **BOE for non-convertible items** (water): contributes 0 BOE instead of
   stopping the posting (v1.0.7) — keep a BOE UOM factor only on the items
   you want counted in BOE totals.
