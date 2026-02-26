import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

int _nowMs() => DateTime.now().millisecondsSinceEpoch;
const _defaultHomeMetricTypes = 'carbs,fats,protein,fiber,caffeine,water';

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

@DataClassName('EntryMetricRow')
class EntryMetrics extends Table {
  TextColumn get entryId => text()();
  IntColumn get type => integer()(); // NutritionMetricType.index
  RealColumn get value => real()();

  @override
  Set<Column> get primaryKey => {entryId, type};
}

@DataClassName('UserProfileRow')
class UserProfiles extends Table with AuditColumns {
  IntColumn get id => integer()(); // always 1
  IntColumn get age => integer()();
  RealColumn get weightKg => real()();
  RealColumn get heightCm => real()();
  TextColumn get gender => text()();
  TextColumn get activityLevel => text()();
  TextColumn get homeMetricTypes =>
      text().withDefault(const Constant(_defaultHomeMetricTypes))();
  BoolColumn get isConfigured => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MetricGoalRow')
class MetricGoals extends Table {
  IntColumn get profileId => integer()(); // always 1
  IntColumn get type => integer()(); // NutritionMetricType.index
  RealColumn get value => real()();

  @override
  Set<Column> get primaryKey => {profileId, type};
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

@DriftDatabase(
  tables: [
    DiaryEntries,
    EntryMetrics,
    UserProfiles,
    MetricGoals,
    AppSettings,
    LocalPrefs,
  ],
)
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
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await _migrateFromV1();
      }
    },
  );

  Future<void> _migrateFromV1() async {
    await customStatement('''
CREATE TABLE diary_entries_new (
  id TEXT NOT NULL PRIMARY KEY,
  name TEXT NOT NULL,
  type INTEGER NOT NULL,
  timestamp INTEGER NOT NULL,
  normalized_name TEXT NOT NULL,
  image_path TEXT,
  icon TEXT,
  status INTEGER NOT NULL DEFAULT 0,
  description TEXT,
  duration_minutes INTEGER,
  updated_at INTEGER NOT NULL,
  updated_by TEXT NOT NULL DEFAULT '',
  deleted_at INTEGER
);
''');

    await customStatement('''
INSERT INTO diary_entries_new (
  id,
  name,
  type,
  timestamp,
  normalized_name,
  image_path,
  icon,
  status,
  description,
  duration_minutes,
  updated_at,
  updated_by,
  deleted_at
)
SELECT
  id,
  name,
  type,
  timestamp,
  normalized_name,
  image_path,
  icon,
  status,
  description,
  duration_minutes,
  updated_at,
  updated_by,
  deleted_at
FROM diary_entries;
''');

    await customStatement('''
CREATE TABLE entry_metrics (
  entry_id TEXT NOT NULL,
  type INTEGER NOT NULL,
  value REAL NOT NULL,
  PRIMARY KEY (entry_id, type)
);
''');

    await customStatement('''
INSERT OR REPLACE INTO entry_metrics (entry_id, type, value)
SELECT id, 0, ROUND(calories * 10) / 10.0
FROM diary_entries;
''');

    await customStatement('''
INSERT OR REPLACE INTO entry_metrics (entry_id, type, value)
SELECT id, 1, ROUND(carbs * 10) / 10.0
FROM diary_entries
WHERE type = 0;
''');

    await customStatement('''
INSERT OR REPLACE INTO entry_metrics (entry_id, type, value)
SELECT id, 3, ROUND(fats * 10) / 10.0
FROM diary_entries
WHERE type = 0;
''');

    await customStatement('''
INSERT OR REPLACE INTO entry_metrics (entry_id, type, value)
SELECT id, 5, ROUND(protein * 10) / 10.0
FROM diary_entries
WHERE type = 0;
''');

    await customStatement('DROP TABLE diary_entries;');
    await customStatement(
      'ALTER TABLE diary_entries_new RENAME TO diary_entries;',
    );

    await customStatement('''
CREATE TABLE user_profiles_new (
  id INTEGER NOT NULL PRIMARY KEY,
  age INTEGER NOT NULL,
  weight_kg REAL NOT NULL,
  height_cm REAL NOT NULL,
  gender TEXT NOT NULL,
  activity_level TEXT NOT NULL,
  home_metric_types TEXT NOT NULL DEFAULT '$_defaultHomeMetricTypes',
  is_configured INTEGER NOT NULL DEFAULT 0,
  updated_at INTEGER NOT NULL,
  updated_by TEXT NOT NULL DEFAULT '',
  deleted_at INTEGER
);
''');

    await customStatement('''
INSERT INTO user_profiles_new (
  id,
  age,
  weight_kg,
  height_cm,
  gender,
  activity_level,
  home_metric_types,
  is_configured,
  updated_at,
  updated_by,
  deleted_at
)
SELECT
  id,
  age,
  weight_kg,
  height_cm,
  gender,
  activity_level,
  '$_defaultHomeMetricTypes',
  is_configured,
  updated_at,
  updated_by,
  deleted_at
FROM user_profiles;
''');

    await customStatement('''
CREATE TABLE metric_goals (
  profile_id INTEGER NOT NULL,
  type INTEGER NOT NULL,
  value REAL NOT NULL,
  PRIMARY KEY (profile_id, type)
);
''');

    await customStatement('''
INSERT OR REPLACE INTO metric_goals (profile_id, type, value)
SELECT id, 0, ROUND(goal_calories * 10) / 10.0
FROM user_profiles;
''');

    await customStatement('''
INSERT OR REPLACE INTO metric_goals (profile_id, type, value)
SELECT id, 1, ROUND(goal_carbs * 10) / 10.0
FROM user_profiles
WHERE goal_carbs IS NOT NULL;
''');

    await customStatement('''
INSERT OR REPLACE INTO metric_goals (profile_id, type, value)
SELECT id, 3, ROUND(goal_fat * 10) / 10.0
FROM user_profiles
WHERE goal_fat IS NOT NULL;
''');

    await customStatement('''
INSERT OR REPLACE INTO metric_goals (profile_id, type, value)
SELECT id, 5, ROUND(goal_protein * 10) / 10.0
FROM user_profiles
WHERE goal_protein IS NOT NULL;
''');

    await customStatement('DROP TABLE user_profiles;');
    await customStatement(
      'ALTER TABLE user_profiles_new RENAME TO user_profiles;',
    );
  }
}
