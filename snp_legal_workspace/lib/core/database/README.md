# Database layer

## Current (v1)
- JSON file stores via feature repositories + `DatabaseService`
- Path: app documents / `snp_data/*.json`
- `migrateLegacyJsonIfNeeded()` copies older flat files

## Isar migration
1. Schemas live in `isar_collections.dart`
2. Run: `dart run build_runner build --delete-conflicting-outputs`
3. Uncomment `part` + `openSnpIsar` and inject Isar into repositories

Until generated code exists, JSON remains source of truth.
