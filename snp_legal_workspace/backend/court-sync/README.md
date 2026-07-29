# Court Sync gateway

## Live credentials (after legal / ToS review)

```bash
export ECOURTS_TOS_ACK=true
export ECOURTS_BASE_URL=https://…
export ECOURTS_API_KEY=…
node server.mjs
```

Without TOS ack + credentials, live adapters stay inactive; Delhi fixture + mock fallback apply.
Mobile never receives upstream keys.
