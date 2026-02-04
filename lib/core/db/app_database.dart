import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

int _nowMs() => DateTime.now().millisecondsSinceEpoch;

mixin AuditColumns on Table {
  IntColumn get updatedAt => integer().clientDefault(_nowMs)();
  TextColumn get updatedBy => text().withDefault(const Constant(''))();
  IntColumn get deletedAt => integer().nullable()();
}

@DataClassName('DiaryEntryRow')
class DiaryEntries extends Table with AuditColumns {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get type => integer()(); // EntryType.index
  IntColumn get calories => integer()();
  RealColumn get protein => real().withDefault(const Constant(0))();
  RealColumn get carbs => real().withDefault(const Constant(0))();
  RealColumn get fats => real().withDefault(const Constant(0))();
  IntColumn get timestamp => integer()(); // ms since epoch
  TextColumn get normalizedName => text()();
  TextColumn get imagePath => text().nullable()();
  TextColumn get icon => text().nullable()();
  IntColumn get status =>
      integer().withDefault(const Constant(0))(); // FoodEntryStatus.index
  TextColumn get description => text().nullable()();
  IntColumn get durationMinutes => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('UserProfileRow')
class UserProfiles extends Table with AuditColumns {
  IntColumn get id => integer()(); // always 1
  IntColumn get age => integer()();
  RealColumn get weightKg => real()();
  RealColumn get heightCm => real()();
  TextColumn get gender => text()();
  TextColumn get activityLevel => text()();
  IntColumn get goalCalories => integer()();
  IntColumn get goalProtein => integer().nullable()();
  IntColumn get goalCarbs => integer().nullable()();
  IntColumn get goalFat => integer().nullable()();
  BoolColumn get isConfigured => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AppSettingsRow')
class AppSettings extends Table with AuditColumns {
  IntColumn get id => integer()(); // always 1
  TextColumn get apiKey => text().nullable()();
  TextColumn get aiModel =>
      text().withDefault(const Constant('google/gemini-3-flash-preview'))();
  TextColumn get fallbackModel => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('LocalPrefRow')
class LocalPrefs extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [DiaryEntries, UserProfiles, AppSettings, LocalPrefs])
class AppDatabase extends _$AppDatabase {
  AppDatabase()
    : super(
        driftDatabase(
          name: 'nutrinutri',
          web: DriftWebOptions(
            sqlite3Wasm: Uri.parse('sqlite3.wasm'),
            driftWorker: Uri.parse('drift_worker.js'),
          ),
        ),
      );

  @override
  int get schemaVersion => 1;
}
