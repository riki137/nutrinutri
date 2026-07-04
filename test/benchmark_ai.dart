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
