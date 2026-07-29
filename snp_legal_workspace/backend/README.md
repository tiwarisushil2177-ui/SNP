# SNP Legal Workspace — Backend API

OpenAPI 3.1 specification for the mobile client.

## Spec

- [`openapi.yaml`](./openapi.yaml) — source of truth for HTTP contracts

## Principles

1. **Single advocate per account** — no multi-tenant firm seats in v1.
2. **Privacy by design** — RLS / account isolation; minimize content in logs and push payloads.
3. **No solicitation surfaces** — no public directory, ratings, or client discovery.
4. **Court traffic is server-side only** — eCourts / NJDG / High Courts are reached by the gateway, not the app.
5. **AI is advisory** — responses flag or suggest; the client must require human approval before any insert/file/send.

## Court Sync endpoints

| Method | Path | Purpose |
|--------|------|---------|
| `GET` | `/court-sync/cnr/{cnr}` | CNR lookup |
| `POST` | `/court-sync/refresh` | Fresh snapshot for discrepancy review |
| `GET` | `/court-sync/supported-courts` | Onboarded courts (partial rollout) |

Unsupported courts: return **422** or **501** with a clear message so the advocate enters hearing dates manually.

## Auth responses expected by the mobile client

Login / register success body:

```json
{
  "access_token": "...",
  "refresh_token": "...",
  "user_id": "uuid",
  "advocate_name": "..."
}
```

## Generating clients

```bash
# Example: openapi-generator
openapi-generator generate -i openapi.yaml -g openapi -o /tmp/snp-api-docs
```

Wire the mobile app with:

```bash
flutter run --dart-define=API_BASE_URL=https://your-api.example.com
```
