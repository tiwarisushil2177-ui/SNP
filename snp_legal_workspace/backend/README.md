# SNP Legal Workspace — Backend API

OpenAPI 3.1 specification for the mobile client.

## Spec

- [`openapi.yaml`](./openapi.yaml) — full API (generate with `python3 gen_openapi.py`)
- [`openapi-court-sync.yaml`](./openapi-court-sync.yaml) — Court Sync subset
- [`gen_openapi.py`](./gen_openapi.py) — regenerates full `openapi.yaml`

## Court Sync service

Reference gateway (Node 18+, zero npm dependencies):

```bash
cd court-sync
node server.mjs
# listens on :8080
```

Endpoints:

| Method | Path | Purpose |
|--------|------|---------|
| `GET` | `/court-sync/cnr/{cnr}` | CNR lookup |
| `POST` | `/court-sync/refresh` | Fresh snapshot for discrepancy review |
| `GET` | `/court-sync/supported-courts` | Onboarded courts (partial rollout) |
| `GET` | `/health` | Liveness |

Auth: `Authorization: Bearer <token>` (JWT verification is a production TODO).

Demo behaviour: CNRs starting with `DL` or `MH` return a mock case; others return **422 unsupported_court**.

Mobile clients must never scrape eCourts — only this gateway.

## Principles

1. Single advocate per account
2. Privacy by design / RLS
3. No public lawyer directory (Rule 36)
4. Court traffic server-side only
5. AI is advisory only

## Mobile wire-up

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8080
```
