# v1.0.16 — FA G/L depletion, history and royalty setup

## Apply to the working app — preserve its identity

This is a source patch, not a new extension. Back up the working source/test company,
merge ALL supplied `src` files at their existing paths, and change only the version in
your working app.json to **1.0.16.0**. Keep its current App ID, name/publisher and working
launch.json. Build, publish with **Synchronize**, confirm the installed version and refresh
permissions/session. No ForceSync, uninstall or company-data deletion is required.

## 1. What happens to depletion now

The existing UOP calculation is retained. Sending a worksheet row creates:

- a standard **FA G/L Journal** line;
- **Account Type = Fixed Asset**;
- **Account No. = the linked Fixed Asset**;
- **Depreciation Book Code = the selected linked book**;
- **FA Posting Type = Depreciation**;
- a **negative FA amount**, reducing the asset/book value;
- native FA balancing expense lines, using the **FA Posting Group** and its allocation
  setup rather than a second hardcoded/direct-G/L expense pair.

BC supports manual depreciation through the FA G/L Journal and its Insert FA Bal. Account
function. [1](https://learn.microsoft.com/en-us/dynamics365/business-central/fa-how-depreciate-amortize)
G/L Integration - Depreciation must be enabled for this route.
[2](https://learn.microsoft.com/en-us/dynamics365/business-central/fa-setup)

The action is labelled **Send to FA G/L Journal**. It does NOT automatically post the
journal. The accountant reviews/Preview Posts and then posts in the native FA G/L Journal.
Only that final step updates the FA Ledger and G/L. Standard item/entity/source calculation
and fixed-asset accounting permissions still apply.

### Required FA setup

1. Reservoir Card: correct **Fixed Asset No.** and **Depreciation Book Code**.
2. Fixed Asset: active, not blocked/budgeted; assign that depreciation book.
3. Depreciation Book: enable **G/L Integration - Depreciation**.
4. FA Depreciation Book: configure the **FA Posting Group**.
5. FA Posting Group:
   - **Accum. Depreciation Account** → the approved accumulated-depletion account.
   - **Depreciation Expense Acc.** → the approved depletion expense/cost account.
   - Review any depreciation allocations. Native allocation dimensions remain in use;
     the source Entity is retained on the expense side.
6. Post the asset's acquisition/opening cost before depreciation.
7. Create a non-recurring **Gen. Journal Template with Type = Assets / Page 5628**.
   Select it in **O&G Setup → FA G/L Journal Template**.
8. Review posting periods, native FA ledger checks, ending book value and currency/book
   policies. The new routine reserves pending FA depletion when checking available book
   value; it does not override native FA checks.
9. Do NOT additionally run standard automatic depreciation for the same UOP amount/period.
   Use an approved manual/UOP process for this book; otherwise the asset may be depreciated twice.

The Reservoir's Total Capitalised Cost remains the approved calculation input; this patch
does not silently replace the working UOP formula with a different FA valuation formula.
Reconcile that basis and accumulated depletion with the asset/book before posting. The new
post route checks the assigned/acquired asset, positive available book value, mapping changes,
positive amount and recorded dimensions. An old worksheet with no asset/book must be re-suggested.

## 2. Where the line went — Depletion History

The line was not deleted: the working page filtered out rows marked sent/journalised.
Use **Depletion History** from the worksheet or Accountant Role Center. It is read-only and
shows the period, Entity, Reservoir, asset/book, calculated amount, document and status.

- **Ready in FA G/L Journal** — generated, not yet ledger-posted.
- **Posted to FA and G/L** — actual FA Ledger Entry evidence captured.
- **Legacy G/L - review original journal** — sent using the older direct G/L route.
- **FA posting cancelled/reversed / needs review** — do not count it as an active new FA posting.

Use **Open Journal**, **FA Ledger Entries**, **Fixed Asset** and **Dimensions** to review.
The durable link retains the original FA entry reference even if standard FA correction
changes the original entry's active state. A cancelled/reversed linked FA entry blocks new
UOP suggestions until source history is reconciled; it is not silently treated as unchanged.

### Existing depletion rows

Existing direct-G/L rows are NOT converted/reposted automatically. If their G/L journal is
already posted, simply posting the amount again through FA G/L would double the G/L charge.
Reconcile any FA opening/legacy difference through an approved accounting migration/adjustment.
If the old journal is still pending, review/cancel that legacy journal through a controlled
process before recreating it—this patch does not blindly delete older journals.

The old O&G Setup depletion expense/accumulated accounts remain stored for legacy reference.
New FA G/L depletion uses FA Posting Group accounts.

## 3. Royalty timing — Nigerian upstream approach

For the selected approach, do **not wait for a sales invoice merely because no product has
been sold yet**. NUPRC's 2025 model concession contract states that production from a field,
including test production, is subject to royalty and sets out monthly chargeable-production
and price-based provisions. Its clause 8.4 refers volume/price determination to the PIA and
regulations. [9](https://br2025.nuprc.gov.ng/media/dm3o1oqs/concession-contract-ppls.pdf)
The 2026 Nigeria legal guide likewise describes royalties on petroleum produced, with rates
varying by resource, location and, where relevant, volume/price.
[8](https://iclg.com/practice-areas/oil-and-gas-laws-and-regulations/nigeria/)

Distinguish:

1. **Production/measurement** — establishes the chargeable production basis under the
   applicable licence/regime; confirm that the app's net quantities represent that basis.
2. **Valuation/assessment** — apply the applicable effective rate and approved fiscal/reference
   price. That is not automatically the price on an individual customer invoice.
3. **Accrual** — recognise the royalty liability/cost for the relevant period.
4. **Settlement** — pay cash or deliver royalty product when due/authorised. This is not a
   second royalty charge.
5. **Sale** — record product revenue/COGS normally. Do not charge the same production royalty
   again just because the sale now occurs.

### Typical cash workflow in this extension

- Capture production → send/review/post its Item Journal.
- Confirm the period's eligible quantities, rate and reference-price inputs.
- Royalty Worksheet → Suggest Royalty → review quantities, Entity, price and amount.
- Send selected royalty rows to General Journals.
- Accountant posts the accrual: **Dr configured royalty cost/expense; Cr royalty payable**.
  Account classification/capitalisation policy must be approved by the accountant.
- Settle separately: **Dr royalty payable; Cr bank** through the appropriate standard BC payment/journal process.

The extension calculates and generates journals; it does not automatically pay NUPRC, submit
statutory returns, or determine legal ownership liability.

### In-kind workflow

Where authorised, send the royalty quantity to the Item Journal as **Negative Adjmt. with a
POSITIVE quantity**. This reduces stock once. Configure **Royalty Gen. Bus. Posting Group**
so the appropriate General Posting Setup Inventory Adjmt. Account is the royalty cost account.
Review and post the journal. Do not also create/pay an equivalent cash liability unless an
approved assessment/settlement process requires a separate adjustment.

The worksheet's reference value and the Item Journal's G/L valuation may differ: native
inventory posting uses BC item costing. The test script fixes item cost equal to reference
price only to make the example easy to reconcile, not as a general accounting rule.

### Important Nigerian configuration limits

This remains a **configurable production-based accounting workflow**, NOT a complete statutory
NUPRC royalty engine. It does not automatically compute terrain/volume tiers, additional
price components, escalated benchmarks, licence-conversion/legacy regimes, exemptions,
regulatory currency conversion, official fiscal prices or statutory filings. Obtain the
applicable calculation/rate for the licence and period and record its reference.

- If the approved fiscal price is in USD but the company books are in NGN/another LCY,
  use the approved currency-converted LCY input and document the FX basis. This price
  field does not automatically fetch prices or perform a statutory FX conversion.
- A single field-level price must not be applied blindly to unlike products/UOMs with different
  fiscal prices. This patch does not add per-product pricing tables.
- No universal Nigerian royalty rate is hardcoded. All test rates/prices are illustrative.
- Earlier project instructions retained royalty on all net production items, including produced
  water. That software choice is NOT evidence that water is chargeable petroleum under Nigerian
  law. Review it explicitly before a statutory/live run; this patch does not silently change it.
- With 0% operator ownership and a management fee, do not treat the fee as a working-interest
  share or automatically as the operator's petroleum royalty. The model concession allocates
  royalty responsibility to holders' participating interests; confirm the actual agreement/agency
  arrangements. [9](https://br2025.nuprc.gov.ng/media/dm3o1oqs/concession-contract-ppls.pdf)

## 4. Field/Block versus Reservoir versus reserves

- **Field/Block** is now a proper, validated dimension-value lookup using O&G Setup's
  Field/Block Dimension Code. Invalid/blocked values are not accepted.
- One term covers the field, including all its production reservoirs. This is the confirmed scope.
- **Choose Field from Reservoir** helps select the right field; **Reservoirs in this Field**
  shows related reservoirs. It does not create a reservoir-specific royalty rate.
- **1P/2P/3P reserve estimates are not the royalty base**. They are relevant to reserves/UOP;
  royalty uses chargeable production/value for the period, not estimated underground reserves.

The old stored Royalty Basis options remain compatible but display as **Production Volume**
and **Production Reference Value**. Neither reads sales invoices. Value basis uses production
value × rate directly and requires a positive reference price. Record the Rate/Agreement and
Price references for review. Source quantities/royalty rounding and duplicate-source protections
remain visible in the worksheet/history.

## 5. Testing / deployment boundary

Use **ROYALTY_TERMS_POSTINGS_TEST_SCRIPT.md** and the accompanying workbook in an isolated
BC 26 test company. Compiler/static checks do not prove native FA posting, asset book values,
G/L accounts, settlement, tax treatment or statutory compliance. Those require BC UAT and
accountant/tax approval. Confirm FA/GL integration and royalty basis before live use.
