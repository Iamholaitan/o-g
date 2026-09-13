# Royalty Terms and Postings — executable UAT script (v1.0.16)

**Run only in an isolated BC 26 test company.** These cases are instructions and
expected outcomes, not a claim that tenant tests have been executed.

## Why royalty does not wait for sales here

The chosen Nigerian upstream approach is production-based. NUPRC's model concession
contract, clause 8, addresses production subject to royalty and monthly chargeable
volumes/value rules. [9](https://br2025.nuprc.gov.ng/media/dm3o1oqs/concession-contract-ppls.pdf)
The applicable rates/regime/fiscal prices must be confirmed for the licence and period;
this configurable app is not a complete statutory NUPRC royalty calculator.

## Controlled sample assumptions

- Test oil item OIL-TEST, production UOM BBL, BOE conversion 1 BBL = 1 BOE.
- Gross 1,000 BBL; BS&W 2%; net/chargeable test quantity 980 BBL.
- **10% and LCY 100,000 per BBL are illustrative test inputs, NOT Nigerian statutory defaults.**
- Expected royalty volume 98 BBL; reference value LCY 9,800,000.
- Use actual existing Entity codes classified as Joint Operation/Operator. For the current
  business model, operator equity is 0%; management fees remain separate.
- FIELD-CASH/RES-CASH and FIELD-KIND/RES-KIND are test identifiers only. Select valid
  dimension values and use automatic production document numbers from your No. Series.
- In the in-kind comparison, set item cost = reference price only for the controlled test.
  Real BC inventory costing can produce G/L amounts different from royalty reference value.
- The FA example uses approved cost 9,020,000, 1P 10,000 and current production 980 BOE,
  giving rate 1,000/BOE and depletion 980,000. Do not apply these assumptions to live data.

## Pre-run checklist

1. Complete dimensions, Entity classification, items/UOMs, locations and base posting groups.
2. Configure the existing templates/accounts in O&G Setup. No account numbers are hardcoded.
3. For FA, configure the asset/book/acquisition and FA Posting Group; enable G/L integration.
4. Start with no earlier royalty/depletion for the test sources/period. Do not bypass duplicate
   checks by deleting posted worksheet history.
5. Review the produced-water and mixed-price policy gates before statutory/live sign-off.
6. Use a non-SUPER authorised Accountant for a separate permission test after the functional cases.

## Cases

### RT-01 — Field/Block lookup

**Area:** Setup

**Steps:** Create FIELD-CASH and FIELD-KIND as valid unblocked values of the Field/Block dimension configured in O&G Setup. Open Royalty Terms and use the lookup.

**Expected:** Both values appear. Invalid/unrelated-dimension/blocked values are rejected. No arbitrary free-text field is saved.

**Evidence:** Royalty Term Card/List and source dimension code

**Actual / result / tester / date:** ____________________

### RT-02 — Reservoir selection aid

**Area:** Setup

**Steps:** Map RES-CASH to FIELD-CASH. On a new Royalty Term Card choose Field from Reservoir and select RES-CASH.

**Expected:** Field/Block becomes FIELD-CASH. The term applies to the field, not only that reservoir or its 1P/2P/3P estimates.

**Evidence:** Royalty Term field code; Reservoir master

**Actual / result / tester / date:** ____________________

### RT-03 — Reference inputs

**Area:** Setup

**Steps:** Set FIELD-CASH: Production Volume, Cash, rate 10%, reference Unit Price 100000 LCY. Enter test agreement/price references and chosen royalty expense/payable accounts.

**Expected:** Saved rate/price/references are visible. These are test assumptions, NOT prescribed Nigerian statutory inputs.

**Evidence:** Royalty Term Card

**Actual / result / tester / date:** ____________________

### RT-04 — Native posting configuration

**Area:** Setup

**Steps:** Configure item/UOM/location/Inventory Posting Setup/General Posting Setup. Use Joint Operation Entity. Create valid Item and General Journal templates selected in O&G Setup.

**Expected:** No hardcoded accounts/templates required; Entity is Global Dimension 1.

**Evidence:** O&G Setup; posting setups; native templates

**Actual / result / tester / date:** ____________________

### RC-01 — Accrue before any sale

**Area:** Cash royalty

**Steps:** Create a new auto-numbered production document for RES-CASH. OIL-TEST gross 1000 BBL, BS&W 2%, net 980, BOE factor 1. Send/review/post production. Do not create a sales invoice yet.

**Expected:** Production: +1000 gross and -20 BS&W inventory effect = +980. Source total 980 BOE.

**Evidence:** Production Entries; Item Journal/Item Ledger Entries

**Actual / result / tester / date:** ____________________

### RC-02 — Suggest royalty with no sales

**Area:** Cash royalty

**Steps:** Royalty Worksheet > Suggest Royalty. Select From/To containing the source Production Date.

**Expected:** OIL-TEST net basis 980; rate 10%; royalty quantity 98 BBL; reference price 100000; amount 9800000 LCY. No sales invoice is needed.

**Evidence:** Royalty Worksheet source document/line, Entity, quantity/amount

**Actual / result / tester / date:** ____________________

### RC-03 — Generate accrual journal

**Area:** Cash royalty

**Steps:** Send the selected cash royalty worksheet row. Inspect its General Journal.

**Expected:** Dr configured royalty expense/cost 9800000; Cr royalty payable 9800000; correct Entity/Field/Reservoir dimensions. No bank payment or automatic G/L posting.

**Evidence:** General Journal lines; Royalty History

**Actual / result / tester / date:** ____________________

### RC-04 — Post accrual

**Area:** Cash royalty

**Steps:** Preview Posting, reconcile accounts/dimensions, then Post the General Journal.

**Expected:** G/L accrual is recorded once. Royalty payable increases by 9800000; bank unchanged.

**Evidence:** G/L Entries and royalty payable account

**Actual / result / tester / date:** ____________________

### RC-05 — Sale is not a second trigger

**Area:** Cash royalty

**Steps:** Optionally post a normal sale of 500 BBL from the test stock using approved test sales/VAT setup. Re-run royalty suggestion for the already processed production window.

**Expected:** Normal sales revenue/COGS occur. The same production source does NOT create another royalty charge.

**Evidence:** Sales/Item/G/L entries; no duplicate royalty worksheet source

**Actual / result / tester / date:** ____________________

### RC-06 — Settle payable separately

**Area:** Cash royalty

**Steps:** Use a standard payment/general journal: debit the royalty payable G/L account 9800000, credit a test bank account 9800000. Review and post.

**Expected:** Royalty payable is cleared for the test accrual. No second debit to royalty expense.

**Evidence:** Payment/General Journal and G/L/Bank Ledger Entries

**Actual / result / tester / date:** ____________________

### RK-01 — Separate test source

**Area:** In-kind royalty

**Steps:** Use FIELD-KIND / RES-KIND or a fresh isolated test company. Set term: Production Volume, In-Kind, 10%. Produce/post 1000 gross less 2% BS&W = 980 BBL. Do not reuse the cash source.

**Expected:** New source is eligible once; prior cash royalty is not duplicated or changed.

**Evidence:** Production Entries; Royalty Term

**Actual / result / tester / date:** ____________________

### RK-02 — Expense-group setup

**Area:** In-kind royalty

**Steps:** Select Royalty Gen. Bus. Posting Group in O&G Setup. In General Posting Setup combine it with the item product group; set Inventory Adjmt. Account to the approved royalty expense/cost account.

**Expected:** In-kind royalty has an explicit configurable expense route.

**Evidence:** O&G Setup; General Posting Setup

**Actual / result / tester / date:** ____________________

### RK-03 — Create inventory royalty

**Area:** In-kind royalty

**Steps:** Suggest then send the in-kind royalty row.

**Expected:** Standard Item Journal: Entry Type Negative Adjmt., Quantity POSITIVE 98 BBL. Entity and source dimensions correct. Do not enter -98 in the Quantity field.

**Evidence:** Item Journal

**Actual / result / tester / date:** ____________________

### RK-04 — Post delivery

**Area:** In-kind royalty

**Steps:** Preview and post the in-kind Item Journal. In this example set item cost equal to reference price, 100000, solely for an easy test comparison.

**Expected:** Stock falls from 980 to 882 BBL. At the specified test cost, Dr royalty cost 9800000 / Cr inventory 9800000. Real costing can differ from reference/fiscal valuation.

**Evidence:** Item Ledger and G/L entries; posting preview

**Actual / result / tester / date:** ____________________

### RK-05 — Avoid duplicate cash settlement

**Area:** In-kind royalty

**Steps:** Inspect journals and payable account after the in-kind test.

**Expected:** No automatic cash royalty payable/payment is created for the same source. Any mixed settlement must be separately agreed/reconciled.

**Evidence:** Royalty History; General/Item Journals

**Actual / result / tester / date:** ____________________

### RV-01 — Production-value basis

**Area:** Controls

**Steps:** On a fresh field/source, choose Production Reference Value, rate 10%, reference price 100000 and eligible quantity 980.

**Expected:** Royalty value = 980 x 100000 x 10% = 9800000. This is production reference value, NOT a query of posted sales invoices.

**Evidence:** Worksheet basis, price and amount

**Actual / result / tester / date:** ____________________

### RV-02 — Reference-value price required

**Area:** Controls

**Steps:** Choose Production Reference Value with positive production/rate but price zero.

**Expected:** Clear error before a positive value-based royalty is suggested. No arbitrary price is substituted.

**Evidence:** Error and unchanged persisted result

**Actual / result / tester / date:** ____________________

### RV-03 — Zero rate means fallback

**Area:** Controls

**Steps:** On a fresh eligible source set term rate 0 and O&G Setup default rate 10%. Then repeat in isolated data with both rates 0.

**Expected:** First case uses 10% as documented; second creates no positive royalty and explains why. Term 0 is NOT an exemption flag.

**Evidence:** Worksheet/rate diagnostics

**Actual / result / tester / date:** ____________________

### RV-04 — Wrong date or field

**Area:** Controls

**Steps:** Use a range excluding the source Production Date, or a term whose Field/Block does not match the source.

**Expected:** No matching royalty; diagnostics identify the mismatch. Cumulative BOE or a matching Entity alone is insufficient.

**Evidence:** Suggestion diagnostic

**Actual / result / tester / date:** ____________________

### RV-05 — Reserves not royalty base

**Area:** Controls

**Steps:** Before journalising a fresh royalty source, vary 1P reserves without changing production, rate or price; re-suggest the same unposted window.

**Expected:** Royalty quantity/value stays the same. Reserve estimates do not replace produced quantity.

**Evidence:** Royalty Worksheet versus Reservoir Card

**Actual / result / tester / date:** ____________________

### RV-06 — Produced-water policy gate

**Area:** Controls

**Steps:** Review the earlier project choice to include every net production item, including produced water. If water is present, compare software output to approved chargeable-petroleum rules.

**Expected:** Do NOT sign off Nigerian statutory compliance merely because the software creates a water royalty. Explicit tax/business approval or a separately approved change is required.

**Evidence:** Policy sign-off; this case is a DESIGN REVIEW gate

**Actual / result / tester / date:** ____________________

### RV-07 — Mixed product pricing gate

**Area:** Controls

**Steps:** If a field produces different products/UOMs, review whether a single term price is valid for all of them.

**Expected:** Do not run a statutory calculation with one unapproved price across unlike oil/gas/NGL UOMs. Per-product/fiscal pricing needs separate confirmed configuration/scope.

**Evidence:** Approved pricing basis

**Actual / result / tester / date:** ____________________

### FA-01 — Asset/book setup

**Area:** FA depletion

**Steps:** Use RES-CASH with linked FA-UOP and book FIN. Post FA acquisition cost 9020000 LCY; set Reservoir Total Capitalised Cost 9020000 and 1P 10000 BOE. Set FA Posting Group accounts and G/L Integration - Depreciation.

**Expected:** Asset/book acquired and active; accumulated depreciation initially zero; approved Reservoir and FA bases reconciled.

**Evidence:** Fixed Asset Card/FA Depreciation Book/FA Ledger

**Actual / result / tester / date:** ____________________

### FA-02 — FA journal template

**Area:** FA depletion

**Steps:** Create a non-recurring Gen. Journal Template of Type Assets opening Page 5628. Select it in O&G Setup > FA G/L Journal Template.

**Expected:** Source uses the standard FA G/L Journal, not the general or non-integrated FA Journal.

**Evidence:** Template setup

**Actual / result / tester / date:** ____________________

### FA-03 — Calculate UOP

**Area:** FA depletion

**Steps:** With only the 980 BOE test production for RES-CASH in the test period, suggest depletion.

**Expected:** Remaining reserves = 10000 - 980 = 9020. Rate = 9020000 / 9020 = 1000 per BOE. Depletion = 980000 LCY.

**Evidence:** Depletion Worksheet

**Actual / result / tester / date:** ____________________

### FA-04 — Send, do not ledger-post yet

**Area:** FA depletion

**Steps:** Select the row and Send to FA G/L Journal.

**Expected:** Main FA line: Account Type Fixed Asset; Account FA-UOP; Book FIN; FA Posting Type Depreciation; Amount -980000. Native balancing expense lines total +980000. No legacy duplicate pair.

**Evidence:** FA G/L Journal

**Actual / result / tester / date:** ____________________

### FA-05 — History before posting

**Area:** FA depletion

**Steps:** Open Depletion History immediately after sending.

**Expected:** Row is retained, read-only, Ready in FA G/L Journal. Actual FA book value is still 9020000 before ledger posting.

**Evidence:** History and FA book

**Actual / result / tester / date:** ____________________

### FA-06 — Post to FA and G/L

**Area:** FA depletion

**Steps:** Preview native FA journal, verify Entity/accounts/book, and post the full balanced document.

**Expected:** FA Ledger depreciation -980000; G/L Dr depletion expense/cost +980000 and Cr accumulated depreciation +980000. FA book value becomes 8040000.

**Evidence:** FA Ledger Entries; G/L Entries; FA book

**Actual / result / tester / date:** ____________________

### FA-07 — History after posting

**Area:** FA depletion

**Steps:** Reopen Depletion History and use FA Ledger Entries.

**Expected:** Status Posted to FA and G/L; linked FA entry/book/date/amount/dimensions can be reviewed. Worksheet row was not deleted.

**Evidence:** Depletion History and native FA Ledger

**Actual / result / tester / date:** ____________________

### FA-08 — Missing mapping/integration

**Area:** FA depletion

**Steps:** Try a new isolated worksheet with no asset/book, no acquisition, blocked asset or G/L Integration - Depreciation disabled.

**Expected:** Clear validation error; no partial journal is committed.

**Evidence:** Error and native journal row count

**Actual / result / tester / date:** ____________________

### FA-09 — Changed calculation mapping

**Area:** FA depletion

**Steps:** Change the Reservoir asset/book after suggesting but before sending.

**Expected:** Sending is stopped; re-suggest the worksheet so it carries the intended asset/book.

**Evidence:** Validation error

**Actual / result / tester / date:** ____________________

### FA-10 — Legacy direct G/L history

**Area:** FA depletion

**Steps:** Open a pre-v1.0.16 sent depletion row.

**Expected:** It remains Legacy G/L - review original journal. It is not automatically reposted to FA or charged to G/L again.

**Evidence:** Depletion History

**Actual / result / tester / date:** ____________________

### FA-11 — Repeat/availability controls

**Area:** FA depletion

**Steps:** Try to send the same row twice or send depletion exceeding available FA book value after pending source depletion.

**Expected:** Duplicate/source or book-value checks stop the operation. No double depreciation.

**Evidence:** Error, FA journal and ledger totals

**Actual / result / tester / date:** ____________________

## Acceptance sign-off

- All relevant functional cases passed with saved journal/ledger evidence.
- Native FA and G/L amounts/book values reconcile; the source is not charged twice.
- Royalty accrued before sale, sale did not duplicate it, and cash settlement cleared the liability.
- Applicable Nigerian licence/rate/price/chargeable-volume basis confirmed separately.
- Water inclusion and mixed-product price limitations explicitly reviewed.
- Accountant/tax owner approval: ____________________  Date: ____________________
