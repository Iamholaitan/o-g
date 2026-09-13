# 1.0.13.1 deployment retry — verification

Date: 2026-09-11. Same App ID, AL/RDLC source and schema as **1.0.13.0**.

- Microsoft AL Compiler **16.2.28.57946** against BC **26.0.30643.50520** symbols.
- Main application compile: **0 errors / 0 warnings**.
- Static checks: **69/69 pass**.
- All **86 AL files** and the RDLC match the 1.0.13.0 release byte-for-byte.
- One table 70000 definition in source/compiled source.
- Compiled manifest App ID: **b3f0a1e2-4c5d-4e6f-8a9b-0c1d2e3f4a5b**.
- Compiled manifest version: **1.0.13.1**.
- Launch retry: ARD2, Synchronize, dependencyPublishingOption Ignore.
- App size: **151,672 bytes**.
- App SHA-256: `dd733291c6b59b376aa7a640ebd6aaad8eff280921d02e71f35386600fe08721`.

**Not verified:** successful publication in ARD2 or the exact cause of the duplicate
server-side app registration. A new version/isolated dependency publish is a controlled
retry, NOT proof of resolution. Do not delete data or uninstall registrations blindly.
The original runtime validation boundary remains unchanged; the AL server tests were
not run against BC here. Historical feature verification is under `v1.0.13`.

Instructions: `docs/DEPLOYMENT_RETRY_1.0.13.1.md`.
