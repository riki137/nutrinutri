import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:nutrinutri/core/services/ai_service.dart';

/// Define the benchmark cases
class FoodBenchmarkCase {
  final String name;
  final String? description;
  final String? imagePath;
  // Expected/Real values for comparison
  final int? realCalories;
  final int? realProtein;
  final int? realCarbs;
  final int? realFats;

  const FoodBenchmarkCase({
    required this.name,
    this.description,
    this.imagePath,
    this.realCalories,
    this.realProtein,
    this.realCarbs,
    this.realFats,
  });
}

/// Store the result of a single benchmark run
class BenchmarkResult {
  final String modelName;
  final FoodBenchmarkCase foodCase;
  final int iteration;
  final Map<String, dynamic>? aiResponse;
  final Duration latency;
  final Object? error;

  BenchmarkResult({
    required this.modelName,
    required this.foodCase,
    required this.iteration,
    this.aiResponse,
    required this.latency,
    this.error,
  });
}

void main() {
  // CONFIGURATION
  // Try to get API key from environment variables or --dart-define
  const dartDefineKey = String.fromEnvironment('OPENROUTER_API_KEY');
  final String apiKey = dartDefineKey.isNotEmpty
      ? dartDefineKey
      : Platform.environment['OPENROUTER_API_KEY'] ?? 'YOUR_OPENROUTER_API_KEY';

  // Models to test
  const List<String> modelsToTest = [
    'google/gemini-3-flash-preview',
    'google/gemini-3-pro-preview',
    'openai/gpt-5.2',
    // 'openai/gpt-5-mini',
    // 'openai/gpt-5-nano',
    // 'openai/gpt-oss-120b',
    // 'anthropic/claude-sonnet-4.5',
    // 'moonshotai/kimi-k2.5',
    // 'deepseek/deepseek-v3.2',
    // 'x-ai/grok-4.1-fast',
  ];

  // Benchmark Cases
  final List<FoodBenchmarkCase> cases = [
    const FoodBenchmarkCase(
      name: 'Double Cheeseburger (McDonald\'s, Text only)',
      description: 'double cheeseburger from mcdonalds',
      realCalories: 440,
      realProtein: 25,
      realCarbs: 34,
      realFats: 24,
    ),

    // https://fineli.fi/fineli/en/elintarvikkeet/31785?
    const FoodBenchmarkCase(
      name: 'Karelian Pasty, Rice Filling, Pirkka 300g (Finnish text)',
      description: 'Karjalanpiirakka, pirkka 300g',
      realCalories: 669,
      realProtein: 15,
      realCarbs: 102,
      realFats: 20,
    ),
    const FoodBenchmarkCase(
      name: 'Cottage Cheese (Image Only)',
      imagePath: 'test/assets/cottage_cheese.jpg',
      realCalories: 135,
      realProtein: 22,
      realFats: 4,
      realCarbs: 2,
    ),

    const FoodBenchmarkCase(
      name: 'Apple (Text Only)',
      description: 'apple',
      realCalories: 95,
      realProtein: 0,
      realCarbs: 25,
      realFats: 0,
    ),

    // https://www.kaloricketabulky.sk/potraviny/horalky-arasidove-sedita
    const FoodBenchmarkCase(
      name: 'Horalky (Slovak wafer snack, Picture only)',
      imagePath: 'test/assets/horalky.jpg',
      realCalories: 269,
      realProtein: 4,
      realCarbs: 26,
      realFats: 17,
    ),

    const FoodBenchmarkCase(
      name: 'Scrambled eggs (Text only)',
      description: '3 scrambled eggs on butter with onion and black pepper',
      realCalories: 334,
      realProtein: 21,
      realFats: 24,
      realCarbs: 12,
    ),

    const FoodBenchmarkCase(
      name: '30cm BBQ Rib Subway Sandwich (Text only)',
      description: '30cm bbq rib sandwich from subway',
      realCalories: 1020,
      realProtein: 47,
      realCarbs: 91,
      realFats: 54,
    ),
  ];

  test('Run AI Food Benchmark', () async {
    if (apiKey == 'YOUR_OPENROUTER_API_KEY') {
      print(
        'PLEASE SET OPENROUTER_API_KEY ENV VAR OR USE --dart-define=OPENROUTER_API_KEY=...',
      );
      return;
    }

    final results = <BenchmarkResult>[];
    const int iterationsPerCase = 3;

    print('Starting Benchmark...');
    print('Models: $modelsToTest');
    print('Cases: ${cases.length}');
    print('Iterations per case: $iterationsPerCase');
    print('--------------------------------------------------');

    for (final model in modelsToTest) {
      print('\nTesting Model: $model');
      final aiService = AIService(apiKey: apiKey, model: model);

      for (final foodCase in cases) {
        print('  Running case: ${foodCase.name}...');

        String? base64Image;
        if (foodCase.imagePath != null) {
          try {
            final file = File(foodCase.imagePath!);
            if (await file.exists()) {
              final bytes = await file.readAsBytes();
              base64Image = base64Encode(bytes);
            } else {
              print('    [WARN] Image file not found: ${foodCase.imagePath}');
            }
          } catch (e) {
            print('    [ERROR] Reading image: $e');
          }
        }

        for (int i = 1; i <= iterationsPerCase; i++) {
          print('    Iteration $i/$iterationsPerCase...');

          final stopwatch = Stopwatch()..start();
          Map<String, dynamic>? response;
          Object? error;

          try {
            response = await aiService.analyzeFood(
              textDescription: foodCase.description,
              base64Image: base64Image,
            );
          } catch (e) {
            error = e;
            print('      [ERROR] AI Request failed: $e');
          } finally {
            stopwatch.stop();
          }

          results.add(
            BenchmarkResult(
              modelName: model,
              foodCase: foodCase,
              iteration: i,
              aiResponse: response,
              latency: stopwatch.elapsed,
              error: error,
            ),
          );

          // Slight delay to avoid rate limits if running sequentially tight
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
    }

    print('\n--------------------------------------------------');
    print('Benchmark Complete. Generating Report...');
    print('--------------------------------------------------\n');

    _printDetailedTable(results);
    print('\n');
    _printSummaryTable(results);
  }, timeout: const Timeout(Duration(minutes: 60)));
}

String _formatVal(int? real, dynamic aiVal) {
  if (real == null) return '-';
  final aiInt = aiVal is int
      ? aiVal
      : (aiVal is String ? int.tryParse(aiVal) : null) ?? 0;
  return '$real / $aiInt';
}

void _printDetailedTable(List<BenchmarkResult> results) {
  // Group results by food case
  final Map<String, List<BenchmarkResult>> resultsByFood = {};
  for (final result in results) {
    if (!resultsByFood.containsKey(result.foodCase.name)) {
      resultsByFood[result.foodCase.name] = [];
    }
    resultsByFood[result.foodCase.name]!.add(result);
  }

  for (final foodName in resultsByFood.keys) {
    print('### Results for $foodName');
    print(
      '| Model | Time (s) | Cal (Real/AI) | Prot (Real/AI) | Carb (Real/AI) | Fat (Real/AI) | Cal Err % |',
    );
    print('|---|---|---|---|---|---|---|');

    for (final result in resultsByFood[foodName]!) {
      final model = result.modelName.split('/').last; // Shorten model name
      final latencySec = (result.latency.inMilliseconds / 1000.0)
          .toStringAsFixed(2);

      String calStr = '-';
      String portStr = '-';
      String carbStr = '-';
      String fatStr = '-';
      String errorStr = '-';

      if (result.error != null) {
        errorStr = 'ERROR';
      } else if (result.aiResponse != null) {
        final aiCals = result.aiResponse!['calories'];
        final aiProt = result.aiResponse!['protein'];
        final aiCarb = result.aiResponse!['carbs'];
        final aiFat = result.aiResponse!['fats'];

        calStr = _formatVal(result.foodCase.realCalories, aiCals);
        portStr = _formatVal(result.foodCase.realProtein, aiProt);
        carbStr = _formatVal(result.foodCase.realCarbs, aiCarb);
        fatStr = _formatVal(result.foodCase.realFats, aiFat);

        if (result.foodCase.realCalories != null) {
          final real = result.foodCase.realCalories!;
          final ai = aiCals is int
              ? aiCals
              : (int.tryParse(aiCals?.toString() ?? '0') ?? 0);
          final err = _calculateError(real, ai);
          errorStr = '${err.toStringAsFixed(1)}%';
        }
      }

      print(
        '| $model | $latencySec | $calStr | $portStr | $carbStr | $fatStr | $errorStr |',
      );
    }
    print('');
  }
}

double _calculateError(int real, int ai) {
  if (real == 0) return (ai - real).abs() > 0 ? 100.0 : 0.0;
  return ((ai - real).abs() / real) * 100.0;
}

void _printSummaryTable(List<BenchmarkResult> results) {
  print('### Summary');
  print('| Model | Avg Latency (s) | Avg Cal Error % | Max Cal Error % |');
  print('|---|---|---|---|');

  final models = results.map((e) => e.modelName).toSet();

  for (final model in models) {
    final modelResults = results.where((r) => r.modelName == model).toList();
    if (modelResults.isEmpty) continue;

    double totalLatency = 0;
    double totalError = 0;
    double maxError = 0;
    int errorCount = 0;

    for (final r in modelResults) {
      totalLatency += r.latency.inMilliseconds / 1000.0;

      if (r.error == null &&
          r.aiResponse != null &&
          r.foodCase.realCalories != null) {
        final real = r.foodCase.realCalories!;
        final aiVal = r.aiResponse!['calories'];
        final ai = aiVal is int
            ? aiVal
            : (int.tryParse(aiVal?.toString() ?? '0') ?? 0);

        final err = _calculateError(real, ai);
        totalError += err;
        maxError = max(maxError, err);
        errorCount++;
      }
    }

    final avgLatency = totalLatency / modelResults.length;
    final avgError = errorCount > 0 ? totalError / errorCount : 0.0;
    final shortName = model.split('/').last;

    print(
      '| $shortName | ${avgLatency.toStringAsFixed(2)} | ${avgError.toStringAsFixed(1)}% | ${maxError.toStringAsFixed(1)}% |',
    );
  }
}
