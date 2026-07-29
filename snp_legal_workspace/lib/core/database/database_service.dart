import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// JSON persistence gateway. Isar is the optional migration target.
class DatabaseService {
  DatabaseService();

  Future<Directory> get _root async {
    final dir = await getApplicationDocumentsDirectory();
    final root = Directory('${dir.path}/snp_data');
    if (!await root.exists()) await root.create(recursive: true);
    return root;
  }

  Future<File> _file(String name) async {
    final root = await _root;
    return File('${root.path}/$name');
  }

  Future<List<Map<String, dynamic>>> readList(String store) async {
    try {
      final f = await _file('$store.json');
      if (!await f.exists()) return [];
      final list = jsonDecode(await f.readAsString()) as List;
      return list
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> writeList(String store, List<Map<String, dynamic>> items) async {
    final f = await _file('$store.json');
    await f.writeAsString(jsonEncode(items));
  }

  Future<void> clearStore(String store) async {
    final f = await _file('$store.json');
    if (await f.exists()) await f.delete();
  }

  Future<void> migrateLegacyJsonIfNeeded() async {
    final dir = await getApplicationDocumentsDirectory();
    final mapping = {
      'snp_cases.json': 'cases',
      'snp_clients.json': 'clients',
      'snp_documents.json': 'documents',
      'snp_invoices.json': 'invoices',
      'snp_time_entries.json': 'time_entries',
    };
    for (final e in mapping.entries) {
      final legacy = File('${dir.path}/${e.key}');
      final target = await _file('${e.value}.json');
      if (await legacy.exists() && !await target.exists()) {
        await legacy.copy(target.path);
      }
    }
  }
}
