# SNP Core API

```bash
export JWT_SECRET=long-random-production-secret
export API_PORT=8090
node server.mjs
```

Per-user isolation under `data/users/<user_id>/`.

## Auth
- `POST /auth/register`
- `POST /auth/login`
- `GET /auth/me`
- `POST /auth/logout`

## Compliance (DPDP-oriented technical controls)
Requires `Authorization: Bearer <token>`.

| Method | Path | Purpose |
|--------|------|--------|
| GET | `/compliance/export` | Full data subject export package |
| POST | `/compliance/erase` | Erase account data (`{ "confirm": "ERASE_MY_DATA" }`) |
| GET | `/compliance/consents` | Consent version history |
| POST | `/compliance/consent` | Record consent |
| GET | `/compliance/audit` | Audit trail |
| POST | `/compliance/breach-report` | Log incident |
| GET | `/compliance/retention` | Retention policy |
| PUT | `/compliance/retention` | Update retention days / auto_purge |
| POST | `/compliance/retention/purge` | Purge expired records if auto_purge |

Handlers live in `compliance_handlers.mjs` (also mirrored inline in `server.mjs` where present).

Flutter default: `API_BASE_URL=http://127.0.0.1:8090`.

These endpoints support a compliance *programme*; they are not a legal certification.
