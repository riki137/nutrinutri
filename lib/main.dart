import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nutrinutri/core/providers.dart';
import 'package:nutrinutri/core/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();
  // Warm up DB early (also applies schema migrations).
  container.read(appDatabaseProvider);

  // Initialize Sync Service & Restore Session
  final syncService = container.read(syncServiceProvider);
  // We don't await this to keep startup fast.
  // The UI listeners will update when the user is restored.
  unawaited(syncService.restoreSession());

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const NutriNutriAppWrapper(),
    ),
  );
}

class NutriNutriAppWrapper extends StatefulWidget {
  const NutriNutriAppWrapper({super.key});

  @override
  State<NutriNutriAppWrapper> createState() => _NutriNutriAppWrapperState();
}

class _NutriNutriAppWrapperState extends State<NutriNutriAppWrapper> {
  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(
      onResume: _onResume,
      onInactive: _onInactive,
    );
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  Future<void> _onResume() async {
    final container = ProviderScope.containerOf(context, listen: false);
    await container.read(syncServiceProvider).syncIfNeeded();
  }

  Future<void> _onInactive() async {
    final container = ProviderScope.containerOf(context, listen: false);
    await container.read(syncServiceProvider).syncIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    return const MyApp();
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'NutriNutri',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6F61), // Vibrant Coral
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.outfitTextTheme(),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6F61), // Vibrant Coral
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      ),
      routerConfig: router,
    );
  }
}
