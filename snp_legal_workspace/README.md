# SNP Legal Workspace

Practice-management application for individual (solo) Indian advocates.

**Privacy by design.** No one — not even platform operators — can casually access an advocate’s case files.

## Product name

**SNP Legal Workspace**

## Stack

| Layer | Choice | Rationale |
|-------|--------|-----------|
| Mobile | **Flutter** (iOS + Android) | Single codebase, native performance, excellent custom UI control for the login illustration and legal UX |
| State | Riverpod | Compile-safe, testable, scalable |
| Navigation | go_router | Declarative, deep-link ready |
| Secure storage | flutter_secure_storage | Encrypted tokens (Keychain / EncryptedSharedPreferences) |
| HTTP | Dio | Interceptors for auth, clear error mapping |
| Local DB | Isar | Fast offline-first storage with account isolation |
| Backend (target) | Supabase / custom Node API with RLS | Row-level security for attorney-client privilege & DPDP compliance |

## Design system

- Deep Navy `#102A43`
- Dark Navy `#0B1F33`
- Saffron `#E87524` (restrained)
- Ivory `#F8F7F3`
- Text `#172B3A` / Secondary `#627486`

**Login screen** uses the exact visual reference (navy background, gold legal line-art, central white card). Gold is **not** used in the main application chrome.

## Getting started

```bash
cd snp_legal_workspace
flutter pub get
flutter run
```

Configure the API base URL at build time:

```bash
flutter run --dart-define=API_BASE_URL=https://your-api.example.com
```

## Project structure

```
lib/
  core/           # theme, constants, services, security, router
  features/
    auth/         # login, create workspace, session
    dashboard/
    cases/
    calendar/
    documents/
    clients/
    billing/
    court_sync/   # (Phase 6)
    ai_tools/     # (Phase 6)
  shared/
```

## v1 scope

- One advocate per account (no firms / team seats)
- Invite-only client access (Bar Council Rule 36)
- Modules: Dashboard, Cases, Calendar, Documents, Clients, Billing
- Court sync & AI tools as automation layers
- AI only suggests / flags — never auto-inserts or auto-files

## Security

- Tokens stored only in platform secure storage
- No secrets in the client binary
- Account isolation enforced server-side (RLS)
- Biometric app lock (Phase 7)
- Expiring document share links

## License

Proprietary. All rights reserved.
