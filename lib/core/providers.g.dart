// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$keyValueStoreHash() => r'78b920813d032d9e9a1cea015c77bf446a256a8c';

/// See also [keyValueStore].
@ProviderFor(keyValueStore)
final keyValueStoreProvider = FutureProvider<KVStore>.internal(
  keyValueStore,
  name: r'keyValueStoreProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$keyValueStoreHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef KeyValueStoreRef = FutureProviderRef<KVStore>;
String _$settingsServiceHash() => r'ea09814a0aa21a0f1fe7696df556e15a2baab86b';

/// See also [settingsService].
@ProviderFor(settingsService)
final settingsServiceProvider = Provider<SettingsService>.internal(
  settingsService,
  name: r'settingsServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$settingsServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SettingsServiceRef = ProviderRef<SettingsService>;
String _$apiKeyHash() => r'f57f2517816f8b768ac9ffbb591baefc9b6f2de0';

/// See also [apiKey].
@ProviderFor(apiKey)
final apiKeyProvider = FutureProvider<String?>.internal(
  apiKey,
  name: r'apiKeyProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$apiKeyHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ApiKeyRef = FutureProviderRef<String?>;
String _$aiServiceHash() => r'b5d640fa6d61a0435966283e3d0eb4cc8ed2fc6c';

/// See also [aiService].
@ProviderFor(aiService)
final aiServiceProvider = FutureProvider<AIService>.internal(
  aiService,
  name: r'aiServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$aiServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AiServiceRef = FutureProviderRef<AIService>;
String _$diaryServiceHash() => r'20a5f67093c14abed9e2898d33373579615e7ba9';

/// See also [diaryService].
@ProviderFor(diaryService)
final diaryServiceProvider = Provider<DiaryService>.internal(
  diaryService,
  name: r'diaryServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$diaryServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DiaryServiceRef = ProviderRef<DiaryService>;
String _$syncServiceHash() => r'37c64bbe5dc8030dd13b40a270dd62778b0e21c6';

/// See also [syncService].
@ProviderFor(syncService)
final syncServiceProvider = Provider<SyncService>.internal(
  syncService,
  name: r'syncServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$syncServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SyncServiceRef = ProviderRef<SyncService>;
String _$currentUserHash() => r'b4e60355b9f6ed5b0be4be4ea8c1f9f0a26b3f31';

/// Stream provider that watches the Google Sign-In authentication state.
/// This ensures the UI rebuilds when sign-in completes.
///
/// Copied from [currentUser].
@ProviderFor(currentUser)
final currentUserProvider = StreamProvider<GoogleUserInfo?>.internal(
  currentUser,
  name: r'currentUserProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentUserHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentUserRef = StreamProviderRef<GoogleUserInfo?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
