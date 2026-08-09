# Test Project Outline – Module D – SwapLoop Rider SPA

## Competition time

Competitors will have **3 hours** to complete this module.

## Introduction

SwapLoop is a fictional Shanghai community pilot that offers safer alternatives to charging e-bike batteries indoors. Compatible delivery and private e-bikes exchange removable batteries at swap stations; e-bikes with integrated batteries use monitored **E-bike Charging Bays**.

This module builds the **mobile-first rider SPA** that replaces a native mobile client. The SPA consumes the provided **Module C Main Backend** REST API. Business rules, eligibility, reservation integrity, last-charge quarantine, charging simulation, and price snapshots remain authoritative in Module C. Module D owns presentation, client state, validation, loading and error handling, navigation, and QR-emulator integration.

## General Description of Project and Tasks

Implement an independently runnable **single-page application (SPA)** that lets riders register, sign in, find stations, reserve services, complete swap or charging journeys, and view pay-as-you-go receipts.

High-level capabilities (details in [Requirements](#requirements)):

- **Auth and profile:** register (two steps: vehicle profile + simulated Alipay link), login with bearer token, view and edit profile
- **Stations:** list, filter (type / nearby / compatible availability), station detail hub, reserve swap or charging hold
- **Station QR:** integrate the provided QR emulator web component; parse station deep links; open the station hub
- **Activity:** active service lifecycle (countdown, start / confirm / cancel for swap; start / live poll / collect / cancel for charging) and recent services with receipts
- **Safety UX:** handle Module C last-charge `409` without inventing availability or quarantine rules in the client
- **Errors and accessibility:** distinct handling for common HTTP statuses; keyboard-operable flows; colour-independent status

### Environment and stack

- Build a **JavaScript SPA** with a modern framework (e.g. React, Vue, or Angular) and **client-side routing**. Reloading a deep-linked URL must restore the same view after auth state is read from storage (except unsaved form input).
- Consume the **Module C Main Backend** under `/api/v1`. Follow the OpenAPI / handout supplied in [`assets/`](./assets/) for base URL, paths, and schemas (typically `http://localhost:5000/api/v1` or the assessor-provided URL).
- Persist the opaque bearer token in `localStorage` (or equivalent) and send `Authorization: Bearer <token>` on protected calls.
- Embed the competition **QR emulator** web component from [`assets/qr-code-emulator/`](./assets/qr-code-emulator/). It talks to the **Station Service** for the current station QR payload. The SPA must **not** require a device camera.
- Do **not** call Station Service directly for last-charge telemetry or live bike-bay charging sessions. Module C proxies those concerns. The only Station Service traffic from the rider UI is through the QR emulator component (as configured by its `service-url`).
- Prefer native `fetch` (or the framework’s HTTP client). Do not invent prices, quarantine decisions, or availability the API did not return.

Until individual asset files are present in this repository, treat the paths under [`assets/`](./assets/) as the required layout assessors will use (see [Assets](#assets)).

### Technical constraints

- Display API timestamps as returned (ISO 8601 with offset). Do not invent or recompute times client-side.
- For the **nearby** station filter, use the browser Geolocation API. During development and assessment, set the browser location to **Shanghai** in DevTools (Sensors / Location), because the seeded stations are in Shanghai.
- Real Alipay Open Platform integration, real payments, real hardware, OAuth / token refresh / email verification / password reset are **out of scope**.
- Only **pay-as-you-go** payment is in scope. Other payment methods (for example monthly plans) will be provided later.

### Physical vocabulary

Use this vocabulary consistently in the UI:

| Term                               | Meaning                                                                                      |
| ---------------------------------- | -------------------------------------------------------------------------------------------- |
| **SwapLoop Station**               | Full service location (`SWAP`, `CHARGING`, or `HYBRID`). **Only stations have a poster QR.** |
| **Battery Swap Cabinet**           | Equipment that stores and charges swappable batteries (no QR in this competition)            |
| **Battery Slot** (Swap Bay)        | One compartment that holds at most one battery (API unit often `SWAP_BAY`)                   |
| **E-bike Charging Bay** (Bike Bay) | Bay that charges a whole e-bike with an integrated battery (`BIKE_BAY`)                      |

Compatibility catalog (do not invent parallel codes):

- Swappable: `batteryMode` `SWAPPABLE` + `batteryType` `SL-48` \| `SL-60` (derived `voltageClass` `48V` / `60V`)
- Integrated: `batteryMode` `INTEGRATED` + `connectorType` `GB-AC-48` \| `GB-AC-60`

### Roles in scope

| Role                          | Module D behaviour                                                                             |
| ----------------------------- | ---------------------------------------------------------------------------------------------- |
| Registered rider (swappable)  | Register/login, reserve swap, start + confirm, receipt                                         |
| Registered rider (integrated) | Register/login, reserve charging bay, start + poll + collect, receipt                          |
| Unauthenticated visitor       | May browse stations via public Module C list/detail APIs; cannot reserve or complete a service |

### Assets

Expected layout (populate before assessment if empty):

```text
assets/
  api/                    # Module C OpenAPI (or link handout)
  handouts/               # base URLs, seed accounts, Station Service URL for QR emulator
  qr-code-emulator/       # bundled <swaploop-qr-emulator> web component + README
```

Seed accounts and reset behaviour are described in the Module C / handout materials (example rider: `lin.xiaoyu@swaploop.test` / `password123`).

## Requirements

The SwapLoop rider SPA shall implement the behaviours below.

### Authentication and profile

1. **Register — step 1:** collect email, password, display name, and a mode-driven vehicle profile:
   - `SWAPPABLE` → require `batteryType` `SL-48` \| `SL-60`; omit `connectorType`
   - `INTEGRATED` → require `connectorType` `GB-AC-48` \| `GB-AC-60`; omit `batteryType`
   - Do **not** send `voltageClass` on register (Module C derives it on `GET /me`)
2. **Register — step 2 (simulated Alipay link):** show a simulated Alipay QR / linking step; after a short delay show success and enable **Create account**. Product story: Alipay is linked for pay-as-you-go; real Alipay is TBD — do not call a real payment API.
3. On successful register (`POST /auth/register` → `{ token }`), store the token and enter the authenticated app.
4. **Login** with email + password (`POST /auth/login` → `{ token }`). Suspended accounts must surface Module C’s `403` message.
5. **Profile:** load `GET /me`; show display name, email, role, status, battery mode, battery type **or** connector type, derived voltage class, and `currentBatteryId` when present for swappable riders.
6. Allow editing display name and vehicle profile via `PATCH /me` with the same mode-driven rules.
7. Sign out clears the stored token and returns to login.
8. Complex OAuth, refresh tokens, email verification, and password reset are out of scope.

### Stations list and filters

1. List stations with `GET /stations` (bearer preferred so `riderAvailability` is included).
2. Support filters:
   - station type: all / `SWAP` / `CHARGING` / `HYBRID`
   - compatible availability only (using rider profile → `service=SWAP` + `batteryType` or `service=BIKE_BAY` + `connectorType`)
   - nearby (~1.5 km) using browser geolocation (`lat`, `lng`, `radiusMeters`)
3. Each card shows name, type, lifecycle status, address/hours as available, distance when nearby, and a clear ready-battery / charging-bay indication vs the rider profile.
4. Distinguish empty results: nothing available now, station closed / suspended, and no station nearby.
5. Card navigation opens station detail `/stations/{stationId}`.
6. **Competition target:** unauthenticated visitors can browse public station list/detail without reserving. If the UI uses protected routing for other screens, still provide a clear browse path for visitors (or document how stations are reachable before login).

### Station detail hub

1. Load `GET /stations/{id}` (with bearer when signed in for `riderAvailability`).
2. Show station identity, address, status, hours, compatibility (services, battery types, connector types, voltage classes), and rider availability guidance.
3. When the rider is eligible and the station is `ACTIVE`, offer **Reserve battery** (swap) or **Reserve charging bay** (integrated).
4. Create a hold with `POST /services` `{ type: "SWAP"|"CHARGING", stationId }`. Hold duration comes from Module C `expiresAt` (**10 seconds** in the competition API so expiry is easy to mark; a production hold would typically be 15–30 minutes).
5. On success, show the active hold summary and a clear path to **Activity**.
6. If the rider already has an **active service at this station**, show the hold / in-progress state and a primary control to open Activity. Do **not** show a misleading “No ready battery / bay” chip for that hold.
7. If the rider already has an **active service at another station**, block a new reserve and link to Activity.
8. **Last-charge safety UX (swap):** Module C may return `409 CONFLICT` after quarantine or missing telemetry. The SPA must:
   - show rider-facing copy such as “The selected battery is not available anymore” (for charging: “…charging bay…”);
   - refresh `GET /stations/{id}` so `riderAvailability` is current;
   - hide or disable reserve when nothing compatible remains;
   - **not** re-implement spike / sustained rules and **not** silently pick another station.
9. Handle `404` for unknown station ids (including bad QR parses that still navigate here).

### Station QR scan

1. Provide a Scan screen that embeds `<swaploop-qr-emulator>` (or the bundled equivalent from assets).
2. Canonical poster payload:

```text
https://app.swaploop.test/stations/{stationId}
```

3. On `qr-scan`, parse the deep link (tolerant of a bare `station-…` id). Reject other shapes with a clear mismatch message.
4. Navigate to `/stations/{stationId}`. Treat the payload as untrusted until Module C `GET /stations/{id}` succeeds.
5. Do not use a device camera. Cabinet / bay / battery QR flows are out of scope.

### Activity hub

1. Load `GET /me/activity` → `{ active, recent }`.
2. **Active — swap (`SWAP`):**
   - While `RESERVED`: show a countdown from `expiresAt` (competition holds last **10 seconds**); actions **Start swapping** (`POST /services/{id}/start` → `STARTED`) and **Cancel** (`/cancel`)
   - While `STARTED`: **Confirm swap** (`POST /services/{id}/confirm` → `CONFIRMED`) and **Cancel**
   - No further QR scans for the physical handoff
3. **Active — charging (`CHARGING`):**
   - While `RESERVED`: countdown; **Start charging** (`/start`) and **Cancel** (cancel only while `RESERVED`)
   - While `CHARGING`: poll `GET /services/{id}/charging-status` about once per second; show live SOC / power / temperature and any `endsAt` countdown; stop when Module C reports complete / `READY_FOR_COLLECTION`
   - When ready: **Collect bike** (`POST /services/{id}/collect` → `COLLECTED`)
   - Do **not** require a **Mark ready** control on the happy path; Module C advances to ready via the status poll
4. After confirm or collect, show a **receipt** from `priceYuan` / `priceCode` (CNY). Never invent amounts.
5. **Recent:** list recent terminal services; allow viewing receipt fields when present.
6. Empty state: clear message and link to Stations.
7. Reflect safety-stop / error states returned by Module C (e.g. `SAFETY_CUTOFF`) with plain language.

### Client state and API usage

Expected Module C capability groups (exact paths in OpenAPI):

```text
POST /auth/login, POST /auth/register
GET  /me, PATCH /me
GET  /me/activity
GET  /stations, GET /stations/{id}
POST /services, GET /services/{id}
POST /services/{id}/start
GET  /services/{id}/charging-status
POST /services/{id}/confirm
POST /services/{id}/collect
POST /services/{id}/cancel
```

1. Handle common API errors (`401`, `403`, `404`, `409`, `422`, and `5xx`) with actionable, accessible messages (no internal stack traces).
2. On `401`/`403` for protected rider actions, clear session and return to login when appropriate.
3. Prevent double-submit while a mutation is pending.
4. Keep server state separate from transient UI state; show loading / stale indicators rather than presenting cached availability as current.

### Responsive design and accessibility

1. Mobile-first layout suitable for riders on phones; usable on desktop widths as well.
2. Keyboard-operable reserve, start, confirm, collect, and cancel flows.
3. Status must not rely on colour alone (text and/or icons). Clear visible feedback for countdown expiry, major state changes, and errors.

## Assessment

Assessment is by expert judgement against the marking scheme, using the Module C reference API (reset seed), Station Service for the QR emulator, and a modern browser. Automated tests may be used where provided; manual walkthrough of register → find → reserve → Activity complete → receipt is required.

## Mark distribution

Draft distribution (finalize with `mits-marking-scheme-creator`):

| WSOS SECTION | Description                            | Points  |
| ------------ | -------------------------------------- | ------- |
| 1            | Work organization and self-management  | 5       |
| 2            | Communication and interpersonal skills | 5       |
| 3            | Design Implementation                  | 15      |
| 4            | Front-End Development                  | 75      |
| **Total**    |                                        | **100** |
