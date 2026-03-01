// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'add_entry_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AddEntryController)
final addEntryControllerProvider = AddEntryControllerProvider._();

final class AddEntryControllerProvider
    extends $NotifierProvider<AddEntryController, AddEntryState> {
  AddEntryControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'addEntryControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$addEntryControllerHash();

  @$internal
  @override
  AddEntryController create() => AddEntryController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AddEntryState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AddEntryState>(value),
    );
  }
}

String _$addEntryControllerHash() =>
    r'e4582b554b7f350f7c25816fe6f9c0ffd47921b6';

abstract class _$AddEntryController extends $Notifier<AddEntryState> {
  AddEntryState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AddEntryState, AddEntryState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AddEntryState, AddEntryState>,
              AddEntryState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
