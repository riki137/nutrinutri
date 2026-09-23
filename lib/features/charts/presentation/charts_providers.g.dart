// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'charts_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(chartsData)
final chartsDataProvider = ChartsDataFamily._();

final class ChartsDataProvider
    extends
        $FunctionalProvider<
          AsyncValue<ChartsData?>,
          ChartsData?,
          FutureOr<ChartsData?>
        >
    with $FutureModifier<ChartsData?>, $FutureProvider<ChartsData?> {
  ChartsDataProvider._({
    required ChartsDataFamily super.from,
    required (DateTime, DateTime) super.argument,
  }) : super(
         retry: null,
         name: r'chartsDataProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$chartsDataHash();

  @override
  String toString() {
    return r'chartsDataProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<ChartsData?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ChartsData?> create(Ref ref) {
    final argument = this.argument as (DateTime, DateTime);
    return chartsData(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is ChartsDataProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chartsDataHash() => r'9cddd991de4f4ffd2be9ad2e9b2f86254da15acd';

final class ChartsDataFamily extends $Family
    with
        $FunctionalFamilyOverride<FutureOr<ChartsData?>, (DateTime, DateTime)> {
  ChartsDataFamily._()
    : super(
        retry: null,
        name: r'chartsDataProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ChartsDataProvider call(DateTime start, DateTime end) =>
      ChartsDataProvider._(argument: (start, end), from: this);

  @override
  String toString() => r'chartsDataProvider';
}
