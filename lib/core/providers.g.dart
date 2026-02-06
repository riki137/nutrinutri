// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(appDatabase)
final appDatabaseProvider = AppDatabaseProvider._();

final class AppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  AppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return appDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$appDatabaseHash() => r'59cce38d45eeaba199eddd097d8e149d66f9f3e1';

@ProviderFor(deviceIdService)
final deviceIdServiceProvider = DeviceIdServiceProvider._();

final class DeviceIdServiceProvider
    extends
        $FunctionalProvider<DeviceIdService, DeviceIdService, DeviceIdService>
    with $Provider<DeviceIdService> {
  DeviceIdServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceIdServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceIdServiceHash();

  @$internal
  @override
  $ProviderElement<DeviceIdService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DeviceIdService create(Ref ref) {
    return deviceIdService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeviceIdService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeviceIdService>(value),
    );
  }
}

String _$deviceIdServiceHash() => r'8b4b4342cad2aef5471ea8ef7d5d4b046c02f601';

@ProviderFor(settingsService)
final settingsServiceProvider = SettingsServiceProvider._();

final class SettingsServiceProvider
    extends
        $FunctionalProvider<SettingsService, SettingsService, SettingsService>
    with $Provider<SettingsService> {
  SettingsServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsServiceHash();

  @$internal
  @override
  $ProviderElement<SettingsService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SettingsService create(Ref ref) {
    return settingsService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SettingsService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SettingsService>(value),
    );
  }
}

String _$settingsServiceHash() => r'3a244e957496328dc9b67abf4413d6d6a2bb13fc';

@ProviderFor(apiKey)
final apiKeyProvider = ApiKeyProvider._();

final class ApiKeyProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  ApiKeyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'apiKeyProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$apiKeyHash();

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    return apiKey(ref);
  }
}

String _$apiKeyHash() => r'924832eaef3085a68ee2a4785acc71d4f23887b0';

@ProviderFor(aiService)
final aiServiceProvider = AiServiceProvider._();

final class AiServiceProvider
    extends
        $FunctionalProvider<
          AsyncValue<AIService>,
          AIService,
          FutureOr<AIService>
        >
    with $FutureModifier<AIService>, $FutureProvider<AIService> {
  AiServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aiServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiServiceHash();

  @$internal
  @override
  $FutureProviderElement<AIService> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<AIService> create(Ref ref) {
    return aiService(ref);
  }
}

String _$aiServiceHash() => r'b5d640fa6d61a0435966283e3d0eb4cc8ed2fc6c';

@ProviderFor(diaryService)
final diaryServiceProvider = DiaryServiceProvider._();

final class DiaryServiceProvider
    extends $FunctionalProvider<DiaryService, DiaryService, DiaryService>
    with $Provider<DiaryService> {
  DiaryServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryServiceHash();

  @$internal
  @override
  $ProviderElement<DiaryService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DiaryService create(Ref ref) {
    return diaryService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DiaryService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DiaryService>(value),
    );
  }
}

String _$diaryServiceHash() => r'716d71e447b58f3ef2ff161b9ee3417af4dc9954';

@ProviderFor(syncService)
final syncServiceProvider = SyncServiceProvider._();

final class SyncServiceProvider
    extends $FunctionalProvider<SyncService, SyncService, SyncService>
    with $Provider<SyncService> {
  SyncServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncServiceHash();

  @$internal
  @override
  $ProviderElement<SyncService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SyncService create(Ref ref) {
    return syncService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncService>(value),
    );
  }
}

String _$syncServiceHash() => r'6f40bb09a4e10f8a54a0b34a1e49b72ca8060e27';

@ProviderFor(currentUser)
final currentUserProvider = CurrentUserProvider._();

final class CurrentUserProvider
    extends
        $FunctionalProvider<
          AsyncValue<GoogleUserInfo?>,
          GoogleUserInfo?,
          Stream<GoogleUserInfo?>
        >
    with $FutureModifier<GoogleUserInfo?>, $StreamProvider<GoogleUserInfo?> {
  CurrentUserProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentUserProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentUserHash();

  @$internal
  @override
  $StreamProviderElement<GoogleUserInfo?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<GoogleUserInfo?> create(Ref ref) {
    return currentUser(ref);
  }
}

String _$currentUserHash() => r'b4e60355b9f6ed5b0be4be4ea8c1f9f0a26b3f31';
