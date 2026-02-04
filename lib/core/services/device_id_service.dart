import 'package:drift/drift.dart';
import 'package:nutrinutri/core/db/app_database.dart';
import 'package:uuid/uuid.dart';

class DeviceIdService {
  DeviceIdService(this._db);
  final AppDatabase _db;

  static const _key = 'device_id';
  String? _cached;

  Future<String> getOrCreate() async {
    final cached = _cached;
    if (cached != null) return cached;

    final existing = await (_db.select(
      _db.localPrefs,
    )..where((t) => t.key.equals(_key))).getSingleOrNull();
    if (existing != null && existing.value.isNotEmpty) {
      _cached = existing.value;
      return existing.value;
    }

    final id = const Uuid().v4();
    await _db
        .into(_db.localPrefs)
        .insert(
          LocalPrefsCompanion.insert(key: _key, value: id),
          mode: InsertMode.insertOrReplace,
        );
    _cached = id;
    return id;
  }
}
