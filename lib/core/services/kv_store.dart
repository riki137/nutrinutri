import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class KVStore {
  static const String _dbName = 'nutrinutri.db';
  static const String _tableName = 'kv_store';
  static const String _webKeyPrefix = 'kv_store_';

  Database? _db;
  SharedPreferences? _prefs;

  Future<void> init() async {
    if (kIsWeb) {
      _prefs = await SharedPreferences.getInstance();
      await _migrateWeb();
      return;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    _db = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            key TEXT PRIMARY KEY,
            value TEXT,
            updated_at INTEGER,
            deleted_at INTEGER
          )
        ''');
      },
    );
  }

  Future<void> _migrateWeb() async {
    const versionKey = 'kv_store_version';
    final currentVersion = _prefs!.getInt(versionKey) ?? 0;

    if (currentVersion < 1) {
      // Migrate legacy raw JSON to wrapper format {v: value, u: updated, d: deleted}
      final now = DateTime.now().millisecondsSinceEpoch;
      final keys = _prefs!.getKeys();

      for (final key in keys) {
        if (!key.startsWith(_webKeyPrefix)) continue;
        if (key == versionKey) continue;

        final rawVal = _prefs!.getString(key);
        if (rawVal != null) {
          // Wrap it
          final record = {
            'v': jsonDecode(rawVal),
            'u': now,
            'd': null, // not deleted
          };
          await _prefs!.setString(key, jsonEncode(record));
        }
      }
      await _prefs!.setInt(versionKey, 1);
    }
  }

  /// Saves a value (updates updatedAt, clears deletedAt)
  Future<void> put(String key, Map<String, dynamic> value) async {
    await putSync(key, value, DateTime.now().millisecondsSinceEpoch, null);
  }

  /// Low-level put for Sync (allows setting explicit timestamps/deleted state)
  Future<void> putSync(
    String key,
    Map<String, dynamic>? value,
    int updatedAt,
    int? deletedAt,
  ) async {
    if (_db == null && _prefs == null) await init();

    if (kIsWeb) {
      final record = {'v': value, 'u': updatedAt, 'd': deletedAt};
      await _prefs!.setString('$_webKeyPrefix$key', jsonEncode(record));
      return;
    }

    await _db!.insert(_tableName, {
      'key': key,
      'value': value != null ? jsonEncode(value) : null,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Retrieves a value by key (returns null if deleted)
  Future<Map<String, dynamic>?> get(String key) async {
    if (_db == null && _prefs == null) await init();

    try {
      if (kIsWeb) {
        final raw = _prefs!.getString('$_webKeyPrefix$key');
        if (raw == null) return null;

        // Attempt to decode as wrapper
        try {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          // Check if it's a wrapper or legacy (though migration handles legacy, safety check)
          if (map.containsKey('v') || map.containsKey('u')) {
            if (map['d'] != null) return null; // Deleted
            return map['v'] as Map<String, dynamic>?;
          }
          // Fallback for non-migrated (shouldn't happen if init ran)
          return map;
        } catch (_) {
          return null;
        }
      }

      final List<Map<String, dynamic>> maps = await _db!.query(
        _tableName,
        where: 'key = ? AND deleted_at IS NULL',
        whereArgs: [key],
      );

      if (maps.isNotEmpty) {
        final val = maps.first['value'] as String?;
        if (val == null) return null;
        return jsonDecode(val) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get all non-deleted keys
  Future<List<String>> getAllKeys() async {
    if (_db == null && _prefs == null) await init();

    if (kIsWeb) {
      final keys = _prefs!.getKeys();
      final validKeys = <String>[];
      for (final k in keys) {
        if (!k.startsWith(_webKeyPrefix)) continue;
        final raw = _prefs!.getString(k);
        if (raw != null) {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          if (map['d'] == null) {
            validKeys.add(k.substring(_webKeyPrefix.length));
          }
        }
      }
      return validKeys;
    }

    final List<Map<String, dynamic>> maps = await _db!.query(
      _tableName,
      columns: ['key'],
      where: 'deleted_at IS NULL',
    );
    return maps.map((e) => e['key'] as String).toList();
  }

  /// Get ALL records (including deleted) for Sync
  /// Returns list of {key, value, updatedAt, deletedAt}
  Future<List<Map<String, dynamic>>> getAllSync() async {
    if (_db == null && _prefs == null) await init();

    if (kIsWeb) {
      final keys = _prefs!.getKeys();
      final results = <Map<String, dynamic>>[];
      for (final k in keys) {
        if (!k.startsWith(_webKeyPrefix)) continue;
        final raw = _prefs!.getString(k);
        if (raw != null) {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          // map is {v, u, d}
          results.add({
            'key': k.substring(_webKeyPrefix.length),
            'value': map['v'],
            'updated_at': map['u'],
            'deleted_at': map['d'],
          });
        }
      }
      return results;
    }

    // Native: decode JSON value for consistency with Sync logic expectations
    final rows = await _db!.query(_tableName);
    return rows.map((row) {
      final valStr = row['value'] as String?;
      return {
        'key': row['key'],
        'value': valStr != null ? jsonDecode(valStr) : null,
        'updated_at': row['updated_at'],
        'deleted_at': row['deleted_at'],
      };
    }).toList();
  }

  /// Delete (Soft Delete)
  Future<void> delete(String key) async {
    // Soft delete: set deletedAt, update updatedAt, clear value (optional, saves space)
    await putSync(
      key,
      null,
      DateTime.now().millisecondsSinceEpoch,
      DateTime.now().millisecondsSinceEpoch,
    );
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
