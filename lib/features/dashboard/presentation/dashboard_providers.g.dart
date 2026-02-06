// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(syncUpdate)
final syncUpdateProvider = SyncUpdateProvider._();

final class SyncUpdateProvider
    extends $FunctionalProvider<AsyncValue<void>, void, Stream<void>>
    with $FutureModifier<void>, $StreamProvider<void> {
  SyncUpdateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncUpdateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncUpdateHash();

  @$internal
  @override
  $StreamProviderElement<void> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<void> create(Ref ref) {
    return syncUpdate(ref);
  }
}

String _$syncUpdateHash() => r'10a4d54f9d17cc704a6e664d05cc1510e593301c';

@ProviderFor(dailySummary)
final dailySummaryProvider = DailySummaryFamily._();

final class DailySummaryProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, double>>,
          Map<String, double>,
          FutureOr<Map<String, double>>
        >
    with
        $FutureModifier<Map<String, double>>,
        $FutureProvider<Map<String, double>> {
  DailySummaryProvider._({
    required DailySummaryFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'dailySummaryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$dailySummaryHash();

  @override
  String toString() {
    return r'dailySummaryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Map<String, double>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, double>> create(Ref ref) {
    final argument = this.argument as DateTime;
    return dailySummary(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DailySummaryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$dailySummaryHash() => r'98c688de6fa15fdb44eba545d188412c167f96a2';

final class DailySummaryFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Map<String, double>>, DateTime> {
  DailySummaryFamily._()
    : super(
        retry: null,
        name: r'dailySummaryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  DailySummaryProvider call(DateTime date) =>
      DailySummaryProvider._(argument: date, from: this);

  @override
  String toString() => r'dailySummaryProvider';
}

@ProviderFor(dayEntries)
final dayEntriesProvider = DayEntriesFamily._();

final class DayEntriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<DiaryEntry>>,
          List<DiaryEntry>,
          FutureOr<List<DiaryEntry>>
        >
    with $FutureModifier<List<DiaryEntry>>, $FutureProvider<List<DiaryEntry>> {
  DayEntriesProvider._({
    required DayEntriesFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'dayEntriesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$dayEntriesHash();

  @override
  String toString() {
    return r'dayEntriesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<DiaryEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<DiaryEntry>> create(Ref ref) {
    final argument = this.argument as DateTime;
    return dayEntries(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DayEntriesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$dayEntriesHash() => r'f20e789788925e11cda2318a4938e252977ee4d8';

final class DayEntriesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<DiaryEntry>>, DateTime> {
  DayEntriesFamily._()
    : super(
        retry: null,
        name: r'dayEntriesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  DayEntriesProvider call(DateTime date) =>
      DayEntriesProvider._(argument: date, from: this);

  @override
  String toString() => r'dayEntriesProvider';
}
