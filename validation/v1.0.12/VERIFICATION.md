# v1.0.12 verification record

Date: 2026-09-10. Main extension version **1.0.12.0**, target **BC 26 / runtime 16.0**.

## Actually executed

| Check | Result |
|---|---|
| Main extension, Microsoft AL Compiler | **0 errors / 0 warnings** |
| Separate sandbox-test extension, AL Compiler | **0 errors / 0 warnings** |
| Static source/schema checks | **64/64 passed** |
| Main AL source files / numeric objects | **66 / 64** (plus 2 profiles) |
| Existing v1.0.11 table/field ID/name/type/class preservation | Passed; only additive fields/table |
| Compiled source versus delivered source | **66/66 AL files match byte-for-byte** |
| Compiled RDLC versus delivered RDLC | Byte-for-byte match |
| Microsoft RDL 2008 XML schema | Valid |
| Compatible local RDLC renderer — HTML5 and CSV | Successful with mock data |
| Full sample BOE totals | 1,272 + 1,000 = **2,272** |
| Gas-only rendered total | **1,000 BOE**, not full-dataset total |
| Empty dataset | Correct no-rows message, no processing failure |

Compiler **16.2.28.57946**, Microsoft BC symbols **26.0.30643.50520** (Application,
Base Application, System Application, Business Foundation, platform System).
NoImplicitWith remains enabled. Source/schema results are in `source-checks.json`;
compiler diagnostic files contain empty `issues` arrays. Re-run static checks with
`python validation/check_source.py` (requires lxml for RDLC checks).

RDLC processing used **ReportViewerCore.NETCore 15.1.33** on .NET 8, a compatible
local renderer, not a connected Business Central server. The tested file is the
actual packaged RDLC. During development, runtime checks caught a merged-cell
placeholder problem not caught by XML schema validation; that was corrected and
all final HTML/CSV cases passed. Date and quantity formatting were also verified.

Official schema URL:
`https://schemas.microsoft.com/sqlserver/reporting/2008/01/reportdefinition/ReportDefinition.xsd`

## Still requires the user's sandbox

- **No BC tenant/database was accessed and no BC UI session was available here.**
- The separate test app contains **24 AL test methods**, compiled **but not executed**
  against BC. Do not count them as 24 passing server tests.
- Estimated By default/lookup, method selection, non-SUPER permissions/audit logging,
  actual Item Journal routing/column visibility, user personalization and preserved
  production-source locks require the focused UAT guide.
- Native BC PDF/print output and physical pagination are **not verified here**. The
  local Linux PDF engine cannot load Windows Uniscribe (`usp10.dll`). HTML/CSV
  processing is not a substitute for the final BC print check.
- No User/Employee accounts were changed/deleted, and no inventory/G/L entries were posted.
- Other report layouts/financial algorithms/new drilling-materials scope are not certified
  by this release. Earlier verification records are retained under `validation/v1.0.11`.

UAT: `docs/RESERVOIR_JOURNAL_REPORT_UAT.md`.
Mock-data preview: `docs/ProductionSummary_SAMPLE.html`.
Detailed renderer results: `rdlc-validation.json`, `rdlc-render-output.md`.

## Main application integrity

File: `OilGas_BC_Extension_v1.0.12.app`  
Size: **113,273 bytes**  
SHA-256: `74fe74b55c8d296587ad2c65502cbbde0deb4df7ba11070cf986eff4ddaa3e2c`

The compiled app includes `layout/src/Reports/Layouts/ProductionSummary.rdlc` and
selects **ProductionSummaryRDLC** as report 70090's default rendering layout.
Use normal Synchronize from installed 1.0.11.0; no uninstall/data deletion is needed.
