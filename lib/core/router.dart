import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nutrinutri/core/providers.dart';
import 'package:nutrinutri/features/dashboard/presentation/dashboard_page.dart';
import 'package:nutrinutri/features/onboarding/presentation/onboarding_page.dart';
import 'package:nutrinutri/features/settings/presentation/settings_page.dart';
import 'package:nutrinutri/features/logging/presentation/add_entry_page.dart';

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
      GoRoute(path: '/', builder: (context, state) => const DashboardPage()),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/add-entry',
        builder: (context, state) => const AddEntryPage(),
      ),
    ],
  );
});
