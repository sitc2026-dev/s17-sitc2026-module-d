# Project Review: SITC2026 S17 — Module D (SwapLoop Rider SPA)

## Summary

Review findings from 14 Aug 2026 were applied: OpenAPI and QR emulator assets are in `assets/`, Station Service hosts match Module C (`.sitc.skillsit.eu`), the QR tester path is `/qr-code-emulator`, seed/409 fixtures are in `project-description.md` under Hosts, seed accounts, and fixtures, and the marking scheme still totals **17** (S1=1, S2=1.5, S3=2.5, S4=12).

## Remaining notes

- The QR file in `assets/qr-code-emulator/` must stay the **IIFE bundle** (`dist-component/swaploop-qr-emulator.js`), not the unbundled source that `import`s `qrcode`.
- WSOS Section 5 is omitted on purpose (client-only SPA).
- Fleet priority, `429`, Idempotency-Key, and screen-reader announcements stay out of this 3-hour brief.

## Compliance Checklist

- [x] README.md structure
- [x] project-description.md header hierarchy
- [x] All required sections present
- [x] metadata.json valid and complete
- [x] marking-scheme.json valid (17 points)
- [x] Assets properly organized
- [x] Station Service / QR tester URLs aligned with Module C
- [x] Seed and 409 fixtures documented in this repo
- [x] Clear and grammatically correct language
