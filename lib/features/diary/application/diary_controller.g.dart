// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DiaryController)
final diaryControllerProvider = DiaryControllerProvider._();

final class DiaryControllerProvider
    extends $AsyncNotifierProvider<DiaryController, void> {
  DiaryControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryControllerHash();

  @$internal
  @override
  DiaryController create() => DiaryController();
}

String _$diaryControllerHash() => r'2ff873a6054ae69bf2dd375ae86206cbc5de9772';

abstract class _$DiaryController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
