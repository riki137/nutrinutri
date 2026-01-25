import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nutrinutri/core/providers.dart';
import 'package:nutrinutri/core/utils/platform_helper.dart';
import 'package:nutrinutri/core/widgets/adaptive_shell.dart';
import 'package:nutrinutri/features/dashboard/presentation/dashboard_page.dart';
import 'package:nutrinutri/features/diary/data/diary_service.dart';
import 'package:nutrinutri/features/logging/presentation/add_entry_page.dart';
import 'package:nutrinutri/features/onboarding/presentation/onboarding_page.dart';
import 'package:nutrinutri/features/settings/presentation/settings_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      // Simple check to redirect to onboarding if not configured
      // Note: In a real app this should probably be reactive to a 'userStateProvider'
      final onboarded = await settingsService.isOnboarded();
      final isGoingToOnboarding = state.matchedLocation == '/onboarding';

      if (!onboarded && !isGoingToOnboarding) {
        return '/onboarding';
      }

      if (onboarded && isGoingToOnboarding) {
        return '/';
      }

      return null;
    },
    routes: [
      // Shell route for main navigation on desktop
      ShellRoute(
        builder: (context, state, child) {
          // On desktop/web, wrap with adaptive shell
          if (PlatformHelper.isDesktopOrWeb) {
            return AdaptiveShell(
              currentPath: state.matchedLocation,
              child: child,
            );
          }
          // On mobile, just return child directly
          return child;
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
      // Routes outside the shell (full-screen)
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/add-entry',
        builder: (context, state) {
          final entry = state.extra as DiaryEntry?;
          final typeStr = state.uri.queryParameters['type'];
          final initialType = typeStr == 'exercise'
              ? EntryType.exercise
              : EntryType.food;
          return AddEntryPage(existingEntry: entry, initialType: initialType);
        },
      ),
    ],
  );
});
