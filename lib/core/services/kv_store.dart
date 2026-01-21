import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KVStore {
  static const String _dbName = 'nutrinutri.db';
  static const String _tableName = 'kv_store';
  static const String _webKeyPrefix = 'kv_store_';

  Database? _db;
  SharedPreferences? _prefs;

  Future<void> init() async {
    if (kIsWeb) {
      _prefs = await SharedPreferences.getInstance();
      return;
    }

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
    if (_db == null && _prefs == null) await init();

    final jsonValue = jsonEncode(value);

    if (kIsWeb) {
      await _prefs!.setString('$_webKeyPrefix$key', jsonValue);
      return;
    }

    try {
      await _db!.insert(_tableName, {
        'key': key,
        'value': jsonValue,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      print('KVStore Put Error: $e');
      rethrow;
    }
  }

  /// Retrieves a value by key
  Future<Map<String, dynamic>?> get(String key) async {
    if (_db == null && _prefs == null) await init();

    try {
      if (kIsWeb) {
        final val = _prefs!.getString('$_webKeyPrefix$key');
        if (val != null) {
          return jsonDecode(val) as Map<String, dynamic>;
        }
        return null;
      }

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
    if (_db == null && _prefs == null) await init();

    if (kIsWeb) {
      final keys = _prefs!.getKeys();
      return keys
          .where((k) => k.startsWith(_webKeyPrefix))
          .map((k) => k.substring(_webKeyPrefix.length))
          .toList();
    }

    final List<Map<String, dynamic>> maps = await _db!.query(
      _tableName,
      columns: ['key'],
    );
    return maps.map((e) => e['key'] as String).toList();
  }

  /// Deletes a value by key
  Future<void> delete(String key) async {
    if (_db == null && _prefs == null) await init();

    if (kIsWeb) {
      await _prefs!.remove('$_webKeyPrefix$key');
      return;
    }

    await _db!.delete(_tableName, where: 'key = ?', whereArgs: [key]);
  }

  /// Clear all data
  Future<void> clear() async {
    if (_db == null && _prefs == null) await init();

    if (kIsWeb) {
      final keys = _prefs!.getKeys();
      for (final key in keys) {
        if (key.startsWith(_webKeyPrefix)) {
          await _prefs!.remove(key);
        }
      }
      return;
    }
    await _db!.delete(_tableName);
  }
}
