# v1.0.13 — verification and deployment boundary

Date: 2026-09-11. Target: **BC 26 / runtime 16.0**. Main application **1.0.13.0**.

## Executed here

| Check | Result |
|---|---|
| Microsoft AL Compiler, main extension | **0 errors / 0 warnings** |
| Microsoft AL Compiler, separate test extension | **0 errors / 0 warnings** |
| Source/schema/logic checks | **69/69 pass** |
| Main AL source files | **86** |
| Existing v1.0.12 table/field ID/name/type/class preservation | Pass — additive schema |
| Packaged source versus delivered AL source | **86/86 byte-for-byte matches** |
| Packaged RDLC versus delivered RDLC | Byte-for-byte match |
| Updated RDLC XML / Microsoft RDL 2008 XSD | Valid |

Compiler: **16.2.28.57946** with Microsoft BC **26.0.30643.50520** Application,
Base Application, System Application, Business Foundation and platform System symbols.
NoImplicitWith enabled. Current compiler diagnostic JSON files contain empty `issues` arrays.
Source checks: `python validation/check_source.py` (requires lxml). Source/logic checks
are NOT simulations of the BC posting engine. Independent arithmetic checks cover
signed BOE, the split own-BS&W reversal quantities, and zero-operator allocation rounding.

The updated RDLC contains Entity grouping, signed reversal BOE and cancelled-source
filtering. The old v1.0.12 HTML example is explicitly historical. No new v1.0.13 native
BC PDF/HTML rendering is claimed by schema validation.

## Not executed / mandatory before production use

- **No BC tenant, inventory ledger or live UI session was accessed here.**
- The separate test app contains **32 AL test methods**, compiled but NOT executed
  against a BC server. They must not be counted as 32 passing server tests.
- Full native Item Journal posting, linked ledger callbacks, exact-cost application
  behaviour, own-BS&W split reversals, cancelled/reversed operational totals, partial
  posting and concurrent-session behaviour require isolated sandbox UAT.
- Non-SUPER permission checks, automatic No. Series allocation, modal dialog behaviour,
  Entity/ownership selection and financial journal Preview Posting require BC testing.
- Native BC report PDF/print rendering and physical pagination remain unverified here.
- The bulk reversal deliberately stops at unsupported tracked/warehouse/variant/
  reserved/downstream-used/ambiguous cases. It does not bypass standard inventory controls.
- Production corrections do not silently reverse royalty, depletion, JV, management-fee
  or other financial journals. Accountants must review those separately.
- Historical source links/Entity values are not guessed from today's setup. Legacy
  posting needs explicit reviewed evidence before automated reversal.

**Treat this as a sandbox validation build.** Use the full checklist in
`docs/PRODUCTION_CORRECTIONS_ENTITY_UAT.md` before deploying reversal functions to live data.

## Main app integrity

File: `OilGas_BC_Extension_v1.0.13.app`  
Size: **151,690 bytes**  
SHA-256: `d59b75ca7c7b46f868b50f15217f87d4d99832678fab6879f5203625012b3ae1`

Upgrade from installed 1.0.12.0 with **Synchronize**. No uninstall, data deletion or
ForceSync is required by these additive changes. Earlier pre-v1.0.6 breaking changes
remain a separate upgrade issue. Historical verification evidence is version-labelled.
