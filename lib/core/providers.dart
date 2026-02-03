import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrinutri/core/services/ai_service.dart';
import 'package:nutrinutri/core/services/google_user_info.dart';
import 'package:nutrinutri/core/services/kv_store.dart';
import 'package:nutrinutri/core/services/settings_service.dart';
import 'package:nutrinutri/core/services/sync_service.dart';
import 'package:nutrinutri/features/diary/data/diary_service.dart';
import 'package:nutrinutri/core/services/food_index_service.dart';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
Future<KVStore> keyValueStore(Ref ref) async {
  final kv = KVStore();
  await kv.init();
  return kv;
}

@Riverpod(keepAlive: true)
SettingsService settingsService(Ref ref) {
  final kv = ref.watch(keyValueStoreProvider).valueOrNull;
  if (kv == null) throw UnimplementedError('KVStore not initialized');
  return SettingsService(kv);
}

@Riverpod(keepAlive: true)
Future<String?> apiKey(Ref ref) async {
  final settings = ref.watch(settingsServiceProvider);
  return await settings.getApiKey();
}

@Riverpod(keepAlive: true)
Future<AIService> aiService(Ref ref) async {
  final apiKey = await ref.watch(apiKeyProvider.future);
  final settings = ref.watch(settingsServiceProvider);
  final model = await settings.getAIModel();
  return AIService(apiKey: apiKey ?? '', model: model);
}

@Riverpod(keepAlive: true)
DiaryService diaryService(Ref ref) {
  final kv = ref.watch(keyValueStoreProvider).valueOrNull;
  final foodIndex = ref.read(foodIndexServiceProvider);
  if (kv == null) throw UnimplementedError('KVStore not initialized');
  return DiaryService(kv, foodIndex);
}

@Riverpod(keepAlive: true)
SyncService syncService(Ref ref) {
  final kv = ref.watch(keyValueStoreProvider).valueOrNull;
  if (kv == null) throw UnimplementedError('KVStore not initialized');
  return SyncService(kv);
}

@Riverpod(keepAlive: true)
FoodIndexService foodIndexService(Ref ref) {
  final kv = ref.watch(keyValueStoreProvider).valueOrNull;
  if (kv == null) throw UnimplementedError('KVStore not initialized');
  return FoodIndexService(kv);
}

/// Stream provider that watches the Google Sign-In authentication state.
/// This ensures the UI rebuilds when sign-in completes.
@Riverpod(keepAlive: true)
Stream<GoogleUserInfo?> currentUser(Ref ref) async* {
  final syncService = ref.watch(syncServiceProvider);
  // Emit the current cached user info immediately
  yield syncService.currentUser;
  // Then listen for changes
  yield* syncService.onCurrentUserChanged;
}
