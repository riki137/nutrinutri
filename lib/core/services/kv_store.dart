import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class KVStore {
  static const String _dbName = 'nutrinutri.db';
  static const String _tableName = 'kv_store';

  Database? _db;

  Future<void> init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            key TEXT PRIMARY KEY,
            value TEXT
          )
        ''');
      },
    );
  }

  /// Saves a JSON-encodable value to the store
  Future<void> put(String key, Map<String, dynamic> value) async {
    if (_db == null) await init();
    try {
      await _db!.insert(_tableName, {
        'key': key,
        'value': jsonEncode(value),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      print('KVStore Put Error: $e');
      rethrow;
    }
  }

  /// Retrieves a value by key
  Future<Map<String, dynamic>?> get(String key) async {
    if (_db == null) await init();
    try {
      final List<Map<String, dynamic>> maps = await _db!.query(
        _tableName,
        where: 'key = ?',
        whereArgs: [key],
      );

      if (maps.isNotEmpty) {
        final val = maps.first['value'] as String;
        return jsonDecode(val) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('KVStore Get Error: $e');
      return null;
    }
  }

  /// Get all keys
  Future<List<String>> getAllKeys() async {
    if (_db == null) await init();
    final List<Map<String, dynamic>> maps = await _db!.query(
      _tableName,
      columns: ['key'],
    );
    return maps.map((e) => e['key'] as String).toList();
  }

  /// Deletes a value by key
  Future<void> delete(String key) async {
    if (_db == null) await init();
    await _db!.delete(_tableName, where: 'key = ?', whereArgs: [key]);
  }

  /// Clear all data
  Future<void> clear() async {
    if (_db == null) await init();
    await _db!.delete(_tableName);
  }
}
