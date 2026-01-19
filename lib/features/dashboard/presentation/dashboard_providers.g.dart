// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$dailySummaryHash() => r'701f7ec1b3ee7a493f28e200598d3989e1a4b80c';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [dailySummary].
@ProviderFor(dailySummary)
const dailySummaryProvider = DailySummaryFamily();

/// See also [dailySummary].
class DailySummaryFamily extends Family<AsyncValue<Map<String, double>>> {
  /// See also [dailySummary].
  const DailySummaryFamily();

  /// See also [dailySummary].
  DailySummaryProvider call(DateTime date) {
    return DailySummaryProvider(date);
  }

  @override
  DailySummaryProvider getProviderOverride(
    covariant DailySummaryProvider provider,
  ) {
    return call(provider.date);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'dailySummaryProvider';
}

/// See also [dailySummary].
class DailySummaryProvider
    extends AutoDisposeFutureProvider<Map<String, double>> {
  /// See also [dailySummary].
  DailySummaryProvider(DateTime date)
    : this._internal(
        (ref) => dailySummary(ref as DailySummaryRef, date),
        from: dailySummaryProvider,
        name: r'dailySummaryProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$dailySummaryHash,
        dependencies: DailySummaryFamily._dependencies,
        allTransitiveDependencies:
            DailySummaryFamily._allTransitiveDependencies,
        date: date,
      );

  DailySummaryProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.date,
  }) : super.internal();

  final DateTime date;

  @override
  Override overrideWith(
    FutureOr<Map<String, double>> Function(DailySummaryRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DailySummaryProvider._internal(
        (ref) => create(ref as DailySummaryRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        date: date,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Map<String, double>> createElement() {
    return _DailySummaryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DailySummaryProvider && other.date == date;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, date.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin DailySummaryRef on AutoDisposeFutureProviderRef<Map<String, double>> {
  /// The parameter `date` of this provider.
  DateTime get date;
}

class _DailySummaryProviderElement
    extends AutoDisposeFutureProviderElement<Map<String, double>>
    with DailySummaryRef {
  _DailySummaryProviderElement(super.provider);

  @override
  DateTime get date => (origin as DailySummaryProvider).date;
}

String _$dayEntriesHash() => r'8586d8892988e7b35f49d21f0019eecb3ae64bec';

/// See also [dayEntries].
@ProviderFor(dayEntries)
const dayEntriesProvider = DayEntriesFamily();

/// See also [dayEntries].
class DayEntriesFamily extends Family<AsyncValue<List<FoodEntry>>> {
  /// See also [dayEntries].
  const DayEntriesFamily();

  /// See also [dayEntries].
  DayEntriesProvider call(DateTime date) {
    return DayEntriesProvider(date);
  }

  @override
  DayEntriesProvider getProviderOverride(
    covariant DayEntriesProvider provider,
  ) {
    return call(provider.date);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'dayEntriesProvider';
}

/// See also [dayEntries].
class DayEntriesProvider extends AutoDisposeFutureProvider<List<FoodEntry>> {
  /// See also [dayEntries].
  DayEntriesProvider(DateTime date)
    : this._internal(
        (ref) => dayEntries(ref as DayEntriesRef, date),
        from: dayEntriesProvider,
        name: r'dayEntriesProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$dayEntriesHash,
        dependencies: DayEntriesFamily._dependencies,
        allTransitiveDependencies: DayEntriesFamily._allTransitiveDependencies,
        date: date,
      );

  DayEntriesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.date,
  }) : super.internal();

  final DateTime date;

  @override
  Override overrideWith(
    FutureOr<List<FoodEntry>> Function(DayEntriesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DayEntriesProvider._internal(
        (ref) => create(ref as DayEntriesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        date: date,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<FoodEntry>> createElement() {
    return _DayEntriesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DayEntriesProvider && other.date == date;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, date.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin DayEntriesRef on AutoDisposeFutureProviderRef<List<FoodEntry>> {
  /// The parameter `date` of this provider.
  DateTime get date;
}

class _DayEntriesProviderElement
    extends AutoDisposeFutureProviderElement<List<FoodEntry>>
    with DayEntriesRef {
  _DayEntriesProviderElement(super.provider);

  @override
  DateTime get date => (origin as DayEntriesProvider).date;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
