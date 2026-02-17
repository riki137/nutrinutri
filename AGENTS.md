# AGENTS.md

Guide for AI coding agents working on the NutriNutri codebase.

## Project Overview

NutriNutri is a cross-platform AI-powered nutrition tracker built with Flutter. It supports Web, Android, Linux, macOS, and Windows. The app uses AI (via OpenRouter API) to analyze food/exercise from photos or text descriptions.

**Stack:** Flutter SDK ^3.10.7, Riverpod (code generation), Drift (SQLite), go_router, flutter_animate, Google Fonts, Material 3

**Monorepo:** `/lib` (Flutter app), `/landing` (Astro landing page)

---

## Build/Lint/Test Commands

### Flutter App (root directory)

```bash
flutter pub get                           # Install dependencies
flutter analyze                           # Lint
flutter build apk/web/windows/macos/linux # Production builds

dart run build_runner build --delete-conflicting-outputs  # Generate code
dart run build_runner watch --delete-conflicting-outputs   # Watch mode

flutter test                              # Run all tests
flutter test test/path/to/test_file.dart  # Single test file
flutter test --name "testName" test/path/to/test_file.dart  # Specific test
```

### Landing Page (/landing) (Astro )

```bash
cd landing && bun install && bun run dev  # Dev server
bun run build                             # Production build
```

---

## Code Style Guidelines

### Formatting & Types

- `dart format .` to format
- Trailing commas required, prefer `final` for locals
- Always declare return types, use `const` constructors
- Use Dart 3 features (records, patterns) where appropriate

### Naming Conventions

- **Files**: snake_case (`diary_controller.dart`)
- **Classes**: PascalCase (`DiaryController`)
- **Variables/Methods**: camelCase (`getEntriesForDate`)
- **Private members**: `_underscore` prefix
- **Providers**: `{name}Provider` (`diaryServiceProvider`)
- **Generated files**: `.g.dart` suffix

### Project Structure

```
lib/
  core/           # Shared: db/, services/, utils/, widgets/, providers.dart, router.dart
  features/
    {feature}/
      application/  # Controllers, use cases
      data/         # Services, repositories
      domain/       # Entities, value objects
      presentation/ # Pages, widgets
```

### Riverpod Patterns

```dart
part 'my_controller.g.dart';

@Riverpod(keepAlive: true)  // Singleton-like services
class DiaryController extends _$DiaryController {
  @override
  FutureOr<void> build() {}
}

@riverpod  // Disposable derived state
Future<List<DiaryEntry>> dayEntries(Ref ref, DateTime date) async {
  return ref.watch(diaryServiceProvider).getEntriesForDate(date);
}
```

- `ref.watch()` for reactive state, `ref.read()` in handlers, `ref.invalidate()` to refresh

### Widget Patterns

- Use `ConsumerWidget`/`ConsumerStatefulWidget` with `WidgetRef ref` parameter

### Error Handling

- Use `unawaited()` for fire-and-forget futures
- Handle errors with try/catch; use `debugPrint()` (not `print()`)
- Return nullable types or defaults instead of throwing when appropriate

### Database (Drift)

- Tables use `AuditColumns` mixin for soft delete
- Use `DataClassName` annotation, store enums as `.index`
- Use `clientDefault` for auto-generated values

### Responsive Design

```dart
final isDesktop = PlatformHelper.isDesktopOrWeb;
final isWide = constraints.maxWidth >= 700;
```

---

## Important Files

- `pubspec.yaml`, `analysis_options.yaml`, `lib/main.dart`
- `lib/core/providers.dart`, `lib/core/router.dart`, `lib/core/db/app_database.dart`

## Notes

- No tests exist yet. Place tests in `/test` mirroring lib structure.
- Run `dart run build_runner build` after modifying Riverpod/Drift code.
- 
