# v1.0.11 verification record

Date: 2026-09-10. Main application version: **1.0.11.0**.

## Actually executed in this workspace

| Check | Result |
|---|---|
| Microsoft AL compiler, main production extension | **0 errors, 0 warnings** |
| Microsoft AL compiler, separate sandbox-test extension | **0 errors, 0 warnings** |
| Static source/schema checks | **43/43 passed** |
| Production AL files / numeric objects | **60 / 58** (plus 2 profiles) |
| Existing field ID/name/type/class comparison to v1.0.10 | Preserved |
| Existing stored Total BOE | Still Normal; a separate new live FlowField is added |
| Packaged compiled source compared byte-for-byte to delivered AL source | **60/60 matched** |

Compiler: **Microsoft AL Compiler 16.2.28.57946**, run on .NET 8.
Symbol set: Microsoft BC **26.0.30643.50520** Application, Base Application,
System Application and Business Foundation, plus the BC 26 platform System symbols.
Application/platform target: **26.0.0.0**; AL runtime: **16.0**; NoImplicitWith enabled.

Official build inputs (not bundled as dependencies/source in this delivery):
- Microsoft.Dynamics.BusinessCentral.Development.Tools NuGet **16.2.28.57946**.
- BC artifact: `https://bcartifacts-exdbf9fwegejdqak.b02.azurefd.net/sandbox/26.0.30643.50520/platform`

Compiler output: `compiler-output.md`, `test-compiler-output.md`.
Compiler diagnostic JSON files contain empty `issues` arrays. Static details:
`source-checks.json`. Re-run static checks using `python validation/check_source.py`.
The saved v1.0.10 schema snapshot contains field metadata, not company data.

## Not executed / still required

- **No BC server or browser session was available for runtime UAT.**
- The **12 AL regression tests are compiled, NOT run**. Their source is in the
  optional sibling `OilGas-Validation` test project.
- Role Center navigation, actual selector behaviour, live refresh, non-SUPER
  permissions, concurrent edits, standard journal validation and Preview Posting
  must be verified in the user's sandbox using `docs/PRODUCTION_STEP1_UAT.md`.
- No inventory/G/L entries were posted here. No tenant or company data was accessed.
- No blanket approval of other financial modules, earlier history or report layouts
  is implied by this production-entry patch or by a clean compilation.

## Compiled main application integrity

File: `OilGas_BC_Extension_v1.0.11.app`  
Size: **97,305 bytes**  
SHA-256: `63c1bbddfb90a65c25032edbe3154c1f4ecd55102659b236fa4676afd71a637c`

From an installed v1.0.10.0, this is an additive-schema update intended for normal
Synchronize. Do not uninstall/delete company data for this patch. Test the upgrade
in a sandbox and confirm the installed version before running the input test.
