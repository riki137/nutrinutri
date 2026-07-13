import 'package:nutrinutri/core/db/app_database.dart';
import 'package:nutrinutri/core/domain/user_profile.dart';
import 'package:nutrinutri/core/services/ai_service.dart';
import 'package:nutrinutri/core/services/device_id_service.dart';
import 'package:nutrinutri/core/services/google_user_info.dart';
import 'package:nutrinutri/core/services/settings_service.dart';
import 'package:nutrinutri/core/services/sync_service.dart';
import 'package:nutrinutri/features/diary/data/diary_service.dart';
import 'package:nutrinutri/features/settings/domain/ai_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}

@Riverpod(keepAlive: true)
DeviceIdService deviceIdService(Ref ref) {
  return DeviceIdService(ref.watch(appDatabaseProvider));
}

@Riverpod(keepAlive: true)
SettingsService settingsService(Ref ref) {
  return SettingsService(
    ref.watch(appDatabaseProvider),
    ref.watch(deviceIdServiceProvider),
  );
}

@Riverpod(keepAlive: true)
Future<String?> apiKey(Ref ref) async {
  return ref.watch(settingsServiceProvider).getApiKey();
}

@Riverpod(keepAlive: true)
Future<UserProfile?> userProfile(Ref ref) async {
  return ref.watch(settingsServiceProvider).getUserProfile();
}

@Riverpod(keepAlive: true)
Future<AIService> aiService(Ref ref) async {
  final apiKey = await ref.watch(apiKeyProvider.future);
  final settings = ref.watch(settingsServiceProvider);
  final model = await settings.getAIModel();
  final provider = providerById(await settings.getProvider());
  final customBaseUrl = await settings.getCustomBaseUrl();
  final nutritionistInstructions = await settings.getNutritionistInstructions();
  final trainerInstructions = await settings.getTrainerInstructions();
  return AIService(
    apiKey: apiKey ?? '',
    model: model,
    baseUrl: resolveChatEndpoint(provider, customBaseUrl),
    extraHeaders: providerHeaders(provider),
    nutritionistInstructions: nutritionistInstructions,
    trainerInstructions: trainerInstructions,
  );
}

@Riverpod(keepAlive: true)
DiaryService diaryService(Ref ref) {
  return DiaryService(
    ref.watch(appDatabaseProvider),
    ref.watch(deviceIdServiceProvider),
    ref.watch(syncServiceProvider),
  );
}

@Riverpod(keepAlive: true)
SyncService syncService(Ref ref) {
  return SyncService(db: ref.watch(appDatabaseProvider));
}

@Riverpod(keepAlive: true)
Stream<GoogleUserInfo?> currentUser(Ref ref) async* {
  final syncService = ref.watch(syncServiceProvider);
  yield syncService.currentUser;
  yield* syncService.onCurrentUserChanged;
}
