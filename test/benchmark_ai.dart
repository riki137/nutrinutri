import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:nutrinutri/core/services/ai_service.dart';
import 'package:nutrinutri/features/settings/domain/ai_provider.dart';

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

/// Path to the append-only results cache. Never rewritten in place - only
/// ever appended to, so a completed API call is durable the instant it's
/// written, even if the run is later killed or crashes.
const String _resultsFilePath = 'test/benchmark_results.jsonl';

/// Splits a comma-separated env/dart-define value into a trimmed, non-empty
/// set (mirrors the OPENROUTER_API_KEY lookup below).
Set<String> _splitEnvList(String raw) => raw
    .split(',')
    .map((s) => s.trim())
    .where((s) => s.isNotEmpty)
    .toSet();

/// Builds the cache/lookup key identifying one (model, case, iteration)
/// combination.
String _cacheKey(String model, String caseName, int iteration) =>
    '$model $caseName $iteration';

/// Loads previously recorded results from [_resultsFilePath], keyed by
/// [_cacheKey]. Later lines for the same key overwrite earlier ones, so a
/// forced re-run's fresh line always wins over the stale one still sitting
/// in the file.
Map<String, Map<String, dynamic>> _loadCache() {
  final file = File(_resultsFilePath);
  if (!file.existsSync()) return {};

  final cache = <String, Map<String, dynamic>>{};
  for (final line in file.readAsLinesSync()) {
    if (line.trim().isEmpty) continue;
    final record = jsonDecode(line) as Map<String, dynamic>;
    final key = _cacheKey(
      record['model'] as String,
      record['caseName'] as String,
      record['iteration'] as int,
    );
    cache[key] = record;
  }
  return cache;
}

void main() {
  // CONFIGURATION
  // Try to get API key from environment variables or --dart-define
  const dartDefineKey = String.fromEnvironment('OPENROUTER_API_KEY');
  final String apiKey = dartDefineKey.isNotEmpty
      ? dartDefineKey
      : Platform.environment['OPENROUTER_API_KEY'] ?? 'YOUR_OPENROUTER_API_KEY';

  // Model IDs to fully redo (ignore cache) regardless of prior results, e.g.
  // FORCE_RERUN_MODELS=google/gemini-3-pro-preview
  const dartDefineForceRerunModels = String.fromEnvironment(
    'FORCE_RERUN_MODELS',
  );
  final Set<String> forceRerunModels = _splitEnvList(
    dartDefineForceRerunModels.isNotEmpty
        ? dartDefineForceRerunModels
        : Platform.environment['FORCE_RERUN_MODELS'] ?? '',
  );

  // Case names to fully redo (ignore cache) regardless of prior results.
  const dartDefineForceRerunCases = String.fromEnvironment(
    'FORCE_RERUN_CASES',
  );
  final Set<String> forceRerunCases = _splitEnvList(
    dartDefineForceRerunCases.isNotEmpty
        ? dartDefineForceRerunCases
        : Platform.environment['FORCE_RERUN_CASES'] ?? '',
  );

  // Models to test (mirrors availableModels in settings_controller.dart,
  // minus 'custom')
  const List<String> modelsToTest = [
    'google/gemini-3-flash-preview',
    'google/gemini-3.5-flash',
    'google/gemini-3.1-pro-preview',
    'openai/gpt-5.5',
    'openai/gpt-5.4-mini',
    'anthropic/claude-sonnet-5',
    'anthropic/claude-opus-4.8',
    'x-ai/grok-4.3',
    'google/gemma-4-31b-it',
    'minimax/minimax-m3',
    'xiaomi/mimo-v2.5',
  ];

  // Benchmark Cases
  //
  // Ground-truth values below come from three kinds of real sources (no invented numbers):
  //   1. Official restaurant nutrition pages/PDFs/calculators (chain's own site).
  //   2. National food composition databases (Fineli, https://fineli.fi) for raw/generic foods.
  //   3. "Recipe-computed" dishes: real per-100g values for each ingredient (from Fineli or
  //      USDA FoodData Central, https://fdc.nal.usda.gov) multiplied by real ingredient
  //      weights and summed. The per-ingredient breakdown is given in each case's comment so
  //      the totals can be independently reproduced.
  final List<FoodBenchmarkCase> cases = [
    // Restaurant: https://www.mcdonalds.com/us/en-us/product/double-cheeseburger.html
    // (McDonald's own `nutrient_facts` API payload embedded in the product page)
    const FoodBenchmarkCase(
      name: 'Double Cheeseburger (McDonald\'s, Text only)',
      description: 'double cheeseburger from mcdonalds',
      realCalories: 440,
      realProtein: 25,
      realCarbs: 34,
      realFats: 24,
    ),

    // Restaurant: Subway's current official nutrition doc no longer lists "BBQ Rib" (confirmed
    // discontinued in both the Jan 2026 US and June 2026 UK/ROI documents) — substituted with
    // "BBQ Pulled Pork", the closest current official BBQ-sauced footlong sub. Source:
    // https://www.subway.com/en-gb/media/emea/europe/uk/nutrition/2026/UKI_IngredientsNutritionalInformationJune2026.pdf
    // (footlong = official 6" value doubled, per the document's own stated methodology)
    const FoodBenchmarkCase(
      name: '30cm BBQ Pulled Pork Subway Sandwich (Text only)',
      description: '30cm bbq pulled pork sandwich from subway',
      realCalories: 692,
      realProtein: 48,
      realCarbs: 86,
      realFats: 15,
    ),

    // Restaurant: KFC's own https://www.kfc.com/nutrition calculator embeds a Nutritionix
    // widget (https://www.nutritionix.com/kfc/menu/premium) as its data source — this is the
    // literal figure KFC's official site serves, not a third-party estimate.
    const FoodBenchmarkCase(
      name: 'KFC Original Recipe Chicken Breast, 1 piece (Text only)',
      description: 'one piece of KFC original recipe chicken breast',
      realCalories: 390,
      realProtein: 39,
      realCarbs: 11,
      realFats: 21,
    ),

    // Restaurant: starbucks.com (US) is a client-rendered SPA with no scrapeable nutrition
    // data; used the official Starbucks Ireland PDF instead, with semi-skimmed milk as the
    // closest EU equivalent to US "2%". Source:
    // https://www.starbucks.ie/sites/starbucks-ie-pwa/files/2025-03/Starbucks%20Spring%20beverage%20Nutritionals.pdf
    // Note: this is notably lower than the commonly-cited US figure (~190 kcal) — likely a real
    // market/recipe difference, not a data error.
    const FoodBenchmarkCase(
      name: 'Starbucks Caffe Latte, Grande, semi-skimmed milk (Text only)',
      description: 'starbucks grande caffe latte with semi-skimmed milk',
      realCalories: 151,
      realProtein: 11,
      realCarbs: 15,
      realFats: 5,
    ),

    // Restaurant: Domino's official nutrition guide lists per-component values, not a
    // finished-slice table. Summed for 1/8 of a medium Hand Tossed Pepperoni pizza: crust
    // (110 kcal/4g protein/21g carb/1.5g fat) + sauce (10/0/2/0) + cheese (50/3/1/3.5) +
    // pepperoni (30/1/0/2.5). Source:
    // https://cache.dominos.com/olo/6_162_0/assets/build/market/US/_en/pdf/DominosNutritionGuide.pdf
    const FoodBenchmarkCase(
      name: 'Domino\'s Medium Pepperoni Pizza, 1 slice (Text only)',
      description: '1 slice of medium hand tossed pepperoni pizza from dominos',
      realCalories: 200,
      realProtein: 8,
      realCarbs: 24,
      realFats: 8,
    ),

    // Food composition database: https://fineli.fi/fineli/en/elintarvikkeet/31785
    const FoodBenchmarkCase(
      name: 'Karelian Pasty, Rice Filling, Pirkka 300g (Finnish text)',
      description: 'Karjalanpiirakka, pirkka 300g',
      realCalories: 669,
      realProtein: 15,
      realCarbs: 102,
      realFats: 20,
    ),

    // Food composition database: Fineli "Apple, Average, With Skin"
    // https://fineli.fi/fineli/en/elintarvikkeet/28916 — 37.05 kcal/100g, Fineli's own
    // medium-portion household measure is 200g: 37.05*2=74.1 kcal, 0.17*2=0.33g protein,
    // 7.71*2=15.43g carbs, 0.09*2=0.17g fat.
    const FoodBenchmarkCase(
      name: 'Apple, 1 large (~200g) (Text only)',
      description: 'one large apple',
      realCalories: 74,
      realProtein: 0,
      realCarbs: 15,
      realFats: 0,
    ),

    // Food composition database: Fineli "Banana, Without Skin"
    // https://fineli.fi/fineli/en/elintarvikkeet/11049 — 87.54 kcal/100g, Fineli's own
    // medium-portion household measure is 125g: 87.54*1.25=109.4 kcal, 1.5g protein,
    // 22.88g carbs, 0.5g fat.
    const FoodBenchmarkCase(
      name: 'Banana, 1 medium (~125g) (Text only)',
      description: 'one medium banana',
      realCalories: 109,
      realProtein: 2,
      realCarbs: 23,
      realFats: 1,
    ),

    // Food composition database: Fineli "Chicken Breast Without Skin, Fried"
    // https://fineli.fi/fineli/en/elintarvikkeet/7530 — 167.09 kcal/100g, Fineli medium-portion
    // household measure is 160g: 267.4 kcal, 42.35g protein, 0.02g carbs, 10.78g fat.
    const FoodBenchmarkCase(
      name: 'Grilled Chicken Breast, ~160g (Text only)',
      description: 'grilled skinless chicken breast, about 160g',
      realCalories: 267,
      realProtein: 42,
      realCarbs: 0,
      realFats: 11,
    ),

    // Food composition database: Fineli "Yoghurt, Plain, 2.5% Fat"
    // https://fineli.fi/fineli/en/elintarvikkeet/33162 — 54.40 kcal/100g, Fineli medium-portion
    // household measure (2dl) is 200g: 108.8 kcal, 6g protein, 9.6g carbs, 5g fat.
    const FoodBenchmarkCase(
      name: 'Plain Natural Yogurt, 200g bowl (Text only)',
      description: 'a 200g bowl of plain natural yogurt',
      realCalories: 109,
      realProtein: 6,
      realCarbs: 10,
      realFats: 5,
    ),

    // Food composition database: Fineli "Potato, Peeled, Boiled Without Salt"
    // https://fineli.fi/fineli/en/elintarvikkeet/11511 — 75.34 kcal/100g, Fineli medium-portion
    // household measure is 180g: 135.6 kcal, 3.38g protein, 27.9g carbs, 0.21g fat.
    const FoodBenchmarkCase(
      name: 'Boiled Potatoes, ~180g (Text only)',
      description: 'about 180g of boiled peeled potatoes',
      realCalories: 136,
      realProtein: 3,
      realCarbs: 28,
      realFats: 0,
    ),

    // Food composition database: Fineli "Milk, 3.5% Fat, Vitamin D"
    // https://fineli.fi/fineli/en/elintarvikkeet/689 — 63.24 kcal/100g, Fineli medium-portion
    // household measure (2dl glass) is 200g: 126.5 kcal, 6g protein, 9.6g carbs, 7g fat.
    const FoodBenchmarkCase(
      name: 'Whole Milk, 200ml glass (Text only)',
      description: 'a 200ml glass of whole milk',
      realCalories: 126,
      realProtein: 6,
      realCarbs: 10,
      realFats: 7,
    ),

    // Food composition database: Fineli "Cottage Cheese, 2-5% Fat"
    // https://fineli.fi/fineli/en/elintarvikkeet/649 — 92.04 kcal/100g; used a common-sense
    // 150g bowl serving (Fineli's own household measure is a 15g garnish amount, too small for
    // a meal): 92.04*1.5=138.06 kcal, 23.72g protein, 3.75g carbs, 3g fat.
    const FoodBenchmarkCase(
      name: 'Cottage Cheese (Image Only)',
      imagePath: 'test/assets/cottage_cheese.jpg',
      realCalories: 138,
      realProtein: 24,
      realFats: 3,
      realCarbs: 4,
    ),

    // Food composition database: Fineli "Cheese, Cheddar Type, 34% Fat"
    // https://fineli.fi/fineli/en/elintarvikkeet/698 — 412.61 kcal/100g, Fineli's own
    // medium-piece household measure is 20g: 82.5 kcal, 5.13g protein, 0.02g carbs, 6.88g fat.
    const FoodBenchmarkCase(
      name: 'Cheddar Cheese, 1 slice (~20g) (Text only)',
      description: 'one 20g slice of cheddar cheese',
      realCalories: 83,
      realProtein: 5,
      realCarbs: 0,
      realFats: 7,
    ),

    // Packaged product database: https://www.kaloricketabulky.sk/potraviny/horalky-arasidove-sedita
    const FoodBenchmarkCase(
      name: 'Horalky (Slovak wafer snack, Picture only)',
      imagePath: 'test/assets/horalky.jpg',
      realCalories: 269,
      realProtein: 4,
      realCarbs: 26,
      realFats: 17,
    ),

    // Recipe-computed (Fineli per-100g values x real ingredient grams, summed):
    // egg 150g (Fineli 858, 134.11 kcal/100g) + butter 15g (Fineli 576, 726.73 kcal/100g)
    // + onion 40g (Fineli 335, 29.36 kcal/100g) + black pepper 0.5g (Fineli 11177,
    // 279.68 kcal/100g) = 323.3 kcal, 19.65g protein, 2.68g carbs, 26.11g fat.
    const FoodBenchmarkCase(
      name: 'Scrambled eggs (Text only)',
      description: '3 scrambled eggs on butter with onion and black pepper',
      realCalories: 323,
      realProtein: 20,
      realFats: 26,
      realCarbs: 3,
    ),

    // Recipe-computed: dry pasta 100g (Fineli 121, 337.19 kcal/100g) + canned crushed tomatoes
    // 200g (Fineli 398, 22.79 kcal/100g) + olive oil 10g (Fineli 536, 883.94 kcal/100g)
    // + parmesan 20g (USDA FDC 170848 "Cheese, parmesan, hard", 392 kcal/100g) =
    // 549.6 kcal, 20.25g protein, 73.94g carbs, 16.8g fat.
    const FoodBenchmarkCase(
      name: 'Homemade Tomato Pasta with Parmesan (Text only)',
      description:
          'homemade pasta with tomato sauce, olive oil and grated parmesan, 100g dry pasta',
      realCalories: 550,
      realProtein: 20,
      realCarbs: 74,
      realFats: 17,
    ),

    // Recipe-computed: rolled oats 50g (Fineli 153, 381.98 kcal/100g) + whole milk 250g
    // (Fineli 689, 63.24 kcal/100g) + banana 125g (Fineli 11049, 87.54 kcal/100g)
    // + peanut butter 15g (Fineli 34667, 551.08 kcal/100g) = 541.2 kcal, 19.64g protein,
    // 66.75g carbs, 19.32g fat.
    const FoodBenchmarkCase(
      name: 'Peanut Butter Banana Oatmeal Bowl (Text only)',
      description:
          'oatmeal bowl with milk, banana and peanut butter, 50g dry oats',
      realCalories: 541,
      realProtein: 20,
      realCarbs: 67,
      realFats: 19,
    ),

    // Recipe-computed: raw salmon fillet 150g (Fineli 871, 195.24 kcal/100g) + cooked white
    // rice 150g (Fineli 1370, 93.34 kcal/100g) + raw broccoli 100g (Fineli 324, 34.81 kcal/100g)
    // + olive oil 5g (Fineli 536, 883.94 kcal/100g) = 511.9 kcal, 34.41g protein,
    // 32.57g carbs, 26.07g fat.
    const FoodBenchmarkCase(
      name: 'Grilled Salmon with Rice and Broccoli (Text only)',
      description:
          'grilled salmon fillet (150g) with 150g rice and 100g broccoli',
      realCalories: 512,
      realProtein: 34,
      realCarbs: 33,
      realFats: 26,
    ),

    // Recipe-computed: dry rice vermicelli 80g (Fineli 29055, 353.55 kcal/100g) + lean raw beef
    // 100g (Fineli 34201, 121.13 kcal/100g) + onion 20g (Fineli 335) + fresh mint 5g
    // (Fineli 34865) + fresh cilantro 5g (Fineli 34238) + lime 30g (USDA FDC 168155 "Limes,
    // raw", 30 kcal/100g) + fish sauce 15g (USDA FDC 174531 "Sauce, fish, ready-to-serve",
    // 35 kcal/100g) + red chili 5g (Fineli 31557, green chili used as closest available
    // variant) + roasted peanuts 10g (Fineli 378) = 483.8 kcal, 28.02g protein, 71.7g carbs,
    // 8.88g fat.
    const FoodBenchmarkCase(
      name: 'Bun Bo Nam Bo, Vietnamese Beef Noodle Salad (Picture only)',
      imagePath: 'test/assets/bun_bo_nam_bo.jpg',
      realCalories: 484,
      realProtein: 28,
      realCarbs: 72,
      realFats: 9,
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

    final cache = _loadCache();
    final sink = File(_resultsFilePath).openWrite(mode: FileMode.append);

    print('Starting Benchmark...');
    print('Models: $modelsToTest');
    print('Cases: ${cases.length}');
    print('Iterations per case: $iterationsPerCase');
    print('Cached results loaded: ${cache.length}');
    print('--------------------------------------------------');

    try {
      for (final model in modelsToTest) {
        print('\nTesting Model: $model');
        final aiService = AIService(
          apiKey: apiKey,
          model: model,
          baseUrl: resolveChatEndpoint(providerById(kDefaultProviderId), null),
          extraHeaders: providerHeaders(providerById(kDefaultProviderId)),
        );

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
                print(
                  '    [WARN] Image file not found: ${foodCase.imagePath}',
                );
              }
            } catch (e) {
              print('    [ERROR] Reading image: $e');
            }
          }

          for (int i = 1; i <= iterationsPerCase; i++) {
            final key = _cacheKey(model, foodCase.name, i);
            final cached = cache[key];
            final forceRerun =
                forceRerunModels.contains(model) ||
                forceRerunCases.contains(foodCase.name);

            if (cached != null && cached['error'] == null && !forceRerun) {
              print('    Iteration $i/$iterationsPerCase... [cached]');
              results.add(
                BenchmarkResult(
                  modelName: model,
                  foodCase: foodCase,
                  iteration: i,
                  aiResponse: cached['aiResponse'] as Map<String, dynamic>?,
                  latency: Duration(milliseconds: cached['latencyMs'] as int),
                  error: cached['error'],
                ),
              );
              continue;
            }

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

            final result = BenchmarkResult(
              modelName: model,
              foodCase: foodCase,
              iteration: i,
              aiResponse: response,
              latency: stopwatch.elapsed,
              error: error,
            );
            results.add(result);

            final record = {
              'model': model,
              'caseName': foodCase.name,
              'iteration': i,
              'aiResponse': response,
              'error': error?.toString(),
              'latencyMs': stopwatch.elapsedMilliseconds,
            };
            sink.writeln(jsonEncode(record));
            await sink.flush();
            cache[key] = record;

            // Slight delay to avoid rate limits if running sequentially tight
            await Future.delayed(const Duration(milliseconds: 500));
          }
        }
      }
    } finally {
      await sink.close();
    }

    print('\n--------------------------------------------------');
    print('Benchmark Complete. Generating Report...');
    print('--------------------------------------------------\n');

    await _writeReport(results);
    print('Report written to test/benchmark_report/index.md');
  }, timeout: const Timeout(Duration(minutes: 60)));
}

/// Reads a metric value out of a raw `analyzeFood` response, which nests
/// them under a `metrics` map (see `AIService._foodMessages`).
dynamic _metric(Map<String, dynamic>? aiResponse, String key) =>
    (aiResponse?['metrics'] as Map?)?[key];

/// Coerces a metric value (usually a `double` like `100.0`, per the AI's
/// system prompt) into a display/comparison `int`.
int _asInt(dynamic value) {
  if (value is num) return value.round();
  if (value is String) {
    return int.tryParse(value) ?? double.tryParse(value)?.round() ?? 0;
  }
  return 0;
}

String _formatVal(int? real, dynamic aiVal) {
  if (real == null) return '-';
  return '$real / ${_asInt(aiVal)}';
}

double _calculateError(int real, int ai) {
  if (real == 0) return (ai - real).abs() > 0 ? 100.0 : 0.0;
  return ((ai - real).abs() / real) * 100.0;
}

double _median(List<double> values) {
  if (values.isEmpty) return 0.0;
  final sorted = [...values]..sort();
  final mid = sorted.length ~/ 2;
  return sorted.length.isOdd
      ? sorted[mid]
      : (sorted[mid - 1] + sorted[mid]) / 2.0;
}

/// Filesystem-safe name for a model's report file, e.g.
/// `nvidia/nemotron-3-super-120b-a12b:free` -> `nvidia-nemotron-3-super-120b-a12b-free`.
String _modelSlug(String model) =>
    model.replaceAll('/', '-').replaceAll(':', '-');

class _ModelStats {
  _ModelStats({
    required this.model,
    required this.avgLatency,
    required this.avgError,
    required this.medianError,
    required this.maxError,
  });

  final String model;
  final double avgLatency;
  final double avgError;
  final double medianError;
  final double maxError;
}

/// Builds one row of a food case's detailed table for [result]. [firstColumn]
/// is the model's short name (index-wide tables) or iteration number
/// (single-model tables) - the only column that differs between the two.
String _detailRow(BenchmarkResult result, String firstColumn) {
  final latencySec = (result.latency.inMilliseconds / 1000.0).toStringAsFixed(
    2,
  );

  final aiResponse = result.aiResponse;
  if (result.error != null || aiResponse == null) {
    final errorStr = result.error != null ? 'ERROR' : '-';
    return '| $firstColumn | $latencySec | - | - | - | - | $errorStr |';
  }

  final calStr = _formatVal(
    result.foodCase.realCalories,
    _metric(aiResponse, 'calories'),
  );
  final protStr = _formatVal(
    result.foodCase.realProtein,
    _metric(aiResponse, 'protein'),
  );
  final carbStr = _formatVal(
    result.foodCase.realCarbs,
    _metric(aiResponse, 'carbs'),
  );
  final fatStr = _formatVal(
    result.foodCase.realFats,
    _metric(aiResponse, 'fats'),
  );

  String errorStr = '-';
  if (result.foodCase.realCalories != null) {
    final err = _calculateError(
      result.foodCase.realCalories!,
      _asInt(_metric(aiResponse, 'calories')),
    );
    errorStr = '${err.toStringAsFixed(1)}%';
  }

  return '| $firstColumn | $latencySec | $calStr | $protStr | $carbStr | $fatStr | $errorStr |';
}

/// Builds `test/benchmark_report/<slug>.md`: detailed results for a single
/// model, grouped by food case.
String _buildModelReportMarkdown(
  String model,
  List<BenchmarkResult> results,
) {
  final shortName = model.split('/').last;
  final buffer = StringBuffer()
    ..writeln('# $shortName — Detailed Results')
    ..writeln()
    ..writeln('[← Back to summary](./index.md)')
    ..writeln();

  final resultsByFood = <String, List<BenchmarkResult>>{};
  for (final result in results) {
    resultsByFood.putIfAbsent(result.foodCase.name, () => []).add(result);
  }

  for (final entry in resultsByFood.entries) {
    buffer
      ..writeln('## ${entry.key}')
      ..writeln(
        '| Iteration | Time (s) | Cal (Real/AI) | Prot (Real/AI) | Carb (Real/AI) | Fat (Real/AI) | Cal Err % |',
      )
      ..writeln('|---|---|---|---|---|---|---|');
    for (final result in entry.value) {
      buffer.writeln(_detailRow(result, '${result.iteration}'));
    }
    buffer.writeln();
  }

  return buffer.toString();
}

/// Builds `test/benchmark_report/index.md`: one summary row per model,
/// linking to its detail page.
String _buildIndexMarkdown(List<_ModelStats> stats) {
  final buffer = StringBuffer()
    ..writeln('# AI Food Benchmark Report')
    ..writeln()
    ..writeln(
      '| Model | Avg Latency (s) | Avg Cal Error % | Median Cal Error % | Max Cal Error % |',
    )
    ..writeln('|---|---|---|---|---|');

  for (final s in stats) {
    final shortName = s.model.split('/').last;
    buffer.writeln(
      '| [$shortName](./${_modelSlug(s.model)}.md) | ${s.avgLatency.toStringAsFixed(2)} | '
      '${s.avgError.toStringAsFixed(1)}% | ${s.medianError.toStringAsFixed(1)}% | '
      '${s.maxError.toStringAsFixed(1)}% |',
    );
  }

  return buffer.toString();
}

/// Writes the full markdown report to `test/benchmark_report/`, rebuilding it
/// from scratch every time from whatever's in [results] (cache hits and/or
/// fresh calls) - safe to re-run without touching the results cache.
Future<void> _writeReport(List<BenchmarkResult> results) async {
  final reportDir = Directory('test/benchmark_report');
  await reportDir.create(recursive: true);

  final modelsInOrder = <String>[];
  for (final r in results) {
    if (!modelsInOrder.contains(r.modelName)) modelsInOrder.add(r.modelName);
  }

  final stats = <_ModelStats>[];
  for (final model in modelsInOrder) {
    final modelResults = results.where((r) => r.modelName == model).toList();

    final errors = <double>[];
    double totalLatency = 0;
    for (final r in modelResults) {
      totalLatency += r.latency.inMilliseconds / 1000.0;
      if (r.error == null &&
          r.aiResponse != null &&
          r.foodCase.realCalories != null) {
        errors.add(
          _calculateError(
            r.foodCase.realCalories!,
            _asInt(_metric(r.aiResponse, 'calories')),
          ),
        );
      }
    }

    stats.add(
      _ModelStats(
        model: model,
        avgLatency: totalLatency / modelResults.length,
        avgError: errors.isEmpty
            ? 0.0
            : errors.reduce((a, b) => a + b) / errors.length,
        medianError: _median(errors),
        maxError: errors.isEmpty ? 0.0 : errors.reduce(max),
      ),
    );

    await File(
      'test/benchmark_report/${_modelSlug(model)}.md',
    ).writeAsString(_buildModelReportMarkdown(model, modelResults));
  }

  await File(
    'test/benchmark_report/index.md',
  ).writeAsString(_buildIndexMarkdown(stats));
}
