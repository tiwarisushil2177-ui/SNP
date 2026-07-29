# Database layer

## Active path
- `DatabaseService` + `EntityStore` — JSON under Documents/snp_data/
- Migrate feature repos to EntityStore incrementally

## Isar
1. Uncomment part file in isar_collections.dart
2. `dart run build_runner build --delete-conflicting-outputs`
3. Wire openSnpIsar into repositories

JSON remains runtime store until codegen succeeds locally. CI unit tests do not need Isar natives.
