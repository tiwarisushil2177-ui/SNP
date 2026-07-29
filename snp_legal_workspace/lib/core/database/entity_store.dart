import 'database_service.dart';

/// JSON-backed entity store. Isar is the offline upgrade after build_runner.
class EntityStore {
  EntityStore(this._db, this.storeName);

  final DatabaseService _db;
  final String storeName;

  Future<List<Map<String, dynamic>>> all() => _db.readList(storeName);

  Future<void> saveAll(List<Map<String, dynamic>> items) =>
      _db.writeList(storeName, items);

  Future<Map<String, dynamic>?> byId(String id, {String idKey = 'id'}) async {
    final items = await all();
    try {
      return items.firstWhere((e) => e[idKey]?.toString() == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> upsert(Map<String, dynamic> item, {String idKey = 'id'}) async {
    final items = await all();
    final id = item[idKey]?.toString();
    final idx = items.indexWhere((e) => e[idKey]?.toString() == id);
    if (idx >= 0) {
      items[idx] = item;
    } else {
      items.add(item);
    }
    await saveAll(items);
  }

  Future<void> delete(String id, {String idKey = 'id'}) async {
    final items = await all();
    await saveAll(items.where((e) => e[idKey]?.toString() != id).toList());
  }
}
