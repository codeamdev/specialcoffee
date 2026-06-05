import 'package:flutter_test/flutter_test.dart';
import 'package:special_coffee/ai_engine/core/brew_recipe_generator.dart';

import '../helpers/test_context.dart';

void main() {
  late BrewRecipeGenerator gen;

  setUp(() => gen = BrewRecipeGenerator());

  // ── Base recipes ─────────────────────────────────────────────────────────

  group('BrewRecipeGenerator — base recipes', () {
    test('V60 base: ratio 15.5, temp 91°C, bloom 35s', () {
      final r = gen.generate(ctx(
        module: 'brewing',
        brewMethod: 'v60',
        altitudeMasl: 0,
        roastLevel: 'medium',
        roastDays: 20,
        waterHardnessPpm: 120,
      ));
      expect(r.ratio, 15.5);
      expect(r.waterTempC, 91.0);
      expect(r.bloomSeconds, 35);
      expect(r.doseG, 20.0);
    });

    test('Chemex base: ratio 16.5, temp 92°C, bloom 40s', () {
      final r = gen.generate(ctx(
        module: 'brewing',
        brewMethod: 'chemex',
        altitudeMasl: 0,
        roastLevel: 'medium',
        roastDays: 20,
      ));
      expect(r.ratio, 16.5);
      expect(r.waterTempC, 92.0);
      expect(r.bloomSeconds, 40);
    });

    test('AeroPress base: ratio 13, temp 85°C, bloom 30s', () {
      final r = gen.generate(ctx(
        module: 'brewing',
        brewMethod: 'aeropress',
        altitudeMasl: 0,
        roastLevel: 'medium',
        roastDays: 20,
      ));
      expect(r.ratio, 13.0);
      expect(r.waterTempC, 85.0);
      expect(r.bloomSeconds, 30);
    });

    test('Espresso: no bloom (bloomSeconds=0)', () {
      final r = gen.generate(ctx(
        module: 'brewing',
        brewMethod: 'espresso',
        altitudeMasl: 0,
        roastLevel: 'medium',
        roastDays: 20,
      ));
      expect(r.bloomSeconds, 0);
      expect(r.bloomG, 0.0);
    });

    test('Moka: tempC stays 0 (no heating control), no bloom', () {
      final r = gen.generate(ctx(
        module: 'brewing',
        brewMethod: 'moka',
        altitudeMasl: 0,
        roastLevel: 'medium',
        roastDays: 20,
      ));
      expect(r.waterTempC, 0.0);
      expect(r.bloomSeconds, 0);
    });

    test('unknown method falls back to V60', () {
      final r = gen.generate(ctx(
        module: 'brewing',
        brewMethod: 'siphon',
        altitudeMasl: 0,
        roastLevel: 'medium',
        roastDays: 20,
      ));
      expect(r.ratio, 15.5); // V60 default
    });
  });

  // ── Ajuste 1: Altitud ────────────────────────────────────────────────────

  group('Ajuste 1 — Altitud > 1500 masl caps temperature', () {
    test('1800 masl → temp ≤ boilingMax (100 - 1800/300 - 2 = 92°C)', () {
      final r = gen.generate(ctx(
        module: 'brewing',
        brewMethod: 'chemex', // base 92°C
        altitudeMasl: 1800,
        roastLevel: 'medium',
        roastDays: 20,
      ));
      // boiling = 100 - 1800/300 = 94°C; maxUsable = 92°C
      // Chemex base 92°C ≤ 92°C → no cap applied
      expect(r.waterTempC, lessThanOrEqualTo(92.0));
    });

    test('2400 masl → temp significantly reduced', () {
      final r = gen.generate(ctx(
        module: 'brewing',
        brewMethod: 'v60',
        altitudeMasl: 2400,
        roastLevel: 'medium',
        roastDays: 20,
      ));
      // boiling = 100 - 2400/300 = 92°C; maxUsable = 90°C
      // V60 base 91°C > 90°C → capped at 90°C
      expect(r.waterTempC, lessThanOrEqualTo(90.0));
      expect(r.adjustmentsApplied, isNotEmpty);
    });

    test('altitude adjustment recorded in adjustmentsApplied', () {
      final r = gen.generate(ctx(
        module: 'brewing',
        brewMethod: 'v60',
        altitudeMasl: 3000,
        roastLevel: 'medium',
        roastDays: 20,
      ));
      expect(r.adjustmentsApplied.any((a) => a.contains('ebullición')), isTrue);
    });

    test('altitude ≤ 1500 → no altitude adjustment', () {
      final r = gen.generate(ctx(
        module: 'brewing',
        brewMethod: 'v60',
        altitudeMasl: 1500,
        roastLevel: 'medium',
        roastDays: 20,
      ));
      expect(r.adjustmentsApplied.any((a) => a.contains('ebullición')), isFalse);
    });
  });

  // ── Ajuste 2: Tueste ─────────────────────────────────────────────────────

  group('Ajuste 2 — Roast level adjusts temperature', () {
    test('light roast → +1°C vs medium', () {
      final medium = gen.generate(ctx(
        module: 'brewing', brewMethod: 'v60', altitudeMasl: 0, roastLevel: 'medium', roastDays: 20,
      ));
      final light = gen.generate(ctx(
        module: 'brewing', brewMethod: 'v60', altitudeMasl: 0, roastLevel: 'light', roastDays: 20,
      ));
      expect(light.waterTempC, medium.waterTempC + 1.0);
    });

    test('dark roast → -2°C vs medium', () {
      final medium = gen.generate(ctx(
        module: 'brewing', brewMethod: 'v60', altitudeMasl: 0, roastLevel: 'medium', roastDays: 20,
      ));
      final dark = gen.generate(ctx(
        module: 'brewing', brewMethod: 'v60', altitudeMasl: 0, roastLevel: 'dark', roastDays: 20,
      ));
      expect(dark.waterTempC, medium.waterTempC - 2.0);
    });

    test('roast adjustment recorded in adjustmentsApplied', () {
      final r = gen.generate(ctx(
        module: 'brewing', brewMethod: 'v60', altitudeMasl: 0, roastLevel: 'light', roastDays: 20,
      ));
      expect(r.adjustmentsApplied.any((a) => a.contains('tueste')), isTrue);
    });
  });

  // ── Ajuste 3: Días de tueste → bloom ─────────────────────────────────────

  group('Ajuste 3 — Roast days adjusts bloom time', () {
    test('roastDays 5 (≤7) → bloom +20s', () {
      final base = gen.generate(ctx(
        module: 'brewing', brewMethod: 'v60', altitudeMasl: 0, roastLevel: 'medium', roastDays: 20,
      ));
      final fresh = gen.generate(ctx(
        module: 'brewing', brewMethod: 'v60', altitudeMasl: 0, roastLevel: 'medium', roastDays: 5,
      ));
      expect(fresh.bloomSeconds, base.bloomSeconds + 20);
    });

    test('roastDays 10 (≤14) → bloom +10s', () {
      final base = gen.generate(ctx(
        module: 'brewing', brewMethod: 'v60', altitudeMasl: 0, roastLevel: 'medium', roastDays: 20,
      ));
      final semifresh = gen.generate(ctx(
        module: 'brewing', brewMethod: 'v60', altitudeMasl: 0, roastLevel: 'medium', roastDays: 10,
      ));
      expect(semifresh.bloomSeconds, base.bloomSeconds + 10);
    });

    test('roastDays 60 (>45) → bloom reduced by 25%', () {
      // V60 base bloom = 35s; aged: floor(35 * 0.75) = 26s
      final aged = gen.generate(ctx(
        module: 'brewing', brewMethod: 'v60', altitudeMasl: 0, roastLevel: 'medium', roastDays: 60,
      ));
      expect(aged.bloomSeconds, (35 * 0.75).round());
    });

    test('espresso has no bloom — roastDays has no effect on bloomSeconds', () {
      final fresh = gen.generate(ctx(
        module: 'brewing', brewMethod: 'espresso', altitudeMasl: 0, roastLevel: 'medium', roastDays: 5,
      ));
      expect(fresh.bloomSeconds, 0);
    });
  });

  // ── Ajuste 4: Proceso → temperatura ─────────────────────────────────────

  group('Ajuste 4 — Process type adjusts temperature', () {
    test('anaerobic_lactic → -1°C vs lavado', () {
      final lavado = gen.generate(ctx(
        module: 'brewing', brewMethod: 'v60', altitudeMasl: 0,
        roastLevel: 'medium', roastDays: 20, processType: 'lavado',
      ));
      final anaerobic = gen.generate(ctx(
        module: 'brewing', brewMethod: 'v60', altitudeMasl: 0,
        roastLevel: 'medium', roastDays: 20, processType: 'anaerobic_lactic',
      ));
      expect(anaerobic.waterTempC, lavado.waterTempC - 1.0);
    });

    test('natural → -0.5°C vs lavado', () {
      final lavado = gen.generate(ctx(
        module: 'brewing', brewMethod: 'v60', altitudeMasl: 0,
        roastLevel: 'medium', roastDays: 20, processType: 'lavado',
      ));
      final natural = gen.generate(ctx(
        module: 'brewing', brewMethod: 'v60', altitudeMasl: 0,
        roastLevel: 'medium', roastDays: 20, processType: 'natural',
      ));
      expect(natural.waterTempC, lavado.waterTempC - 0.5);
    });

    test('null processType → no process adjustment', () {
      final noProcess = gen.generate(ctx(
        module: 'brewing', brewMethod: 'v60', altitudeMasl: 0,
        roastLevel: 'medium', roastDays: 20, processType: null,
      ));
      final lavado = gen.generate(ctx(
        module: 'brewing', brewMethod: 'v60', altitudeMasl: 0,
        roastLevel: 'medium', roastDays: 20, processType: 'lavado',
      ));
      expect(noProcess.waterTempC, lavado.waterTempC);
    });
  });

  // ── Ajuste 5: Preferencias → ratio ───────────────────────────────────────

  group('Ajuste 5 — User preferences adjust ratio', () {
    test('userSweetnessWeight 0.8 → ratio -0.5', () {
      final base = gen.generate(ctx(
        module: 'brewing', brewMethod: 'v60', altitudeMasl: 0,
        roastLevel: 'medium', roastDays: 20,
        userSweetnessWeight: 0.5, userAcidityWeight: 0.5,
      ));
      final sweet = gen.generate(ctx(
        module: 'brewing', brewMethod: 'v60', altitudeMasl: 0,
        roastLevel: 'medium', roastDays: 20,
        userSweetnessWeight: 0.8, userAcidityWeight: 0.2,
      ));
      expect(sweet.ratio, base.ratio - 0.5);
    });

    test('userAcidityWeight 0.8 → ratio +0.5', () {
      final base = gen.generate(ctx(
        module: 'brewing', brewMethod: 'v60', altitudeMasl: 0,
        roastLevel: 'medium', roastDays: 20,
        userSweetnessWeight: 0.5, userAcidityWeight: 0.5,
      ));
      final acidic = gen.generate(ctx(
        module: 'brewing', brewMethod: 'v60', altitudeMasl: 0,
        roastLevel: 'medium', roastDays: 20,
        userSweetnessWeight: 0.2, userAcidityWeight: 0.8,
      ));
      expect(acidic.ratio, base.ratio + 0.5);
    });

    test('waterG = doseG × ratio', () {
      final r = gen.generate(ctx(
        module: 'brewing', brewMethod: 'v60', altitudeMasl: 0,
        roastLevel: 'medium', roastDays: 20,
      ));
      expect(r.waterG, r.doseG * r.ratio);
    });
  });

  // ── Ajuste 6: Dureza del agua → temperatura ─────────────────────────────

  group('Ajuste 6 — Water hardness adjusts temperature', () {
    test('waterHardness 250 ppm (>200) → -1°C', () {
      final soft = gen.generate(ctx(
        module: 'brewing', brewMethod: 'v60', altitudeMasl: 0,
        roastLevel: 'medium', roastDays: 20, waterHardnessPpm: 120,
      ));
      final hard = gen.generate(ctx(
        module: 'brewing', brewMethod: 'v60', altitudeMasl: 0,
        roastLevel: 'medium', roastDays: 20, waterHardnessPpm: 250,
      ));
      expect(hard.waterTempC, soft.waterTempC - 1.0);
    });

    test('waterHardness 30 ppm (<50) → +0.5°C', () {
      final normal = gen.generate(ctx(
        module: 'brewing', brewMethod: 'v60', altitudeMasl: 0,
        roastLevel: 'medium', roastDays: 20, waterHardnessPpm: 120,
      ));
      final verysoft = gen.generate(ctx(
        module: 'brewing', brewMethod: 'v60', altitudeMasl: 0,
        roastLevel: 'medium', roastDays: 20, waterHardnessPpm: 30,
      ));
      expect(verysoft.waterTempC, normal.waterTempC + 0.5);
    });

    test('hardness 0 ppm → no hardness adjustment (between 0 and 50, exclusive)', () {
      // waterHardnessPpm 0 does not satisfy `> 0 && < 50`
      final r = gen.generate(ctx(
        module: 'brewing', brewMethod: 'v60', altitudeMasl: 0,
        roastLevel: 'medium', roastDays: 20, waterHardnessPpm: 0,
      ));
      expect(r.adjustmentsApplied.any((a) => a.contains('ppm')), isFalse);
    });
  });

  // ── Cumulative adjustments ────────────────────────────────────────────────

  group('Cumulative adjustments', () {
    test('all adjustments combine correctly without NaN or negative temp', () {
      final r = gen.generate(ctx(
        module: 'brewing',
        brewMethod: 'v60',
        altitudeMasl: 1800,
        roastLevel: 'light',
        roastDays: 5,
        processType: 'anaerobic_lactic',
        userSweetnessWeight: 0.8,
        userAcidityWeight: 0.2,
        waterHardnessPpm: 250,
      ));
      expect(r.waterTempC, isPositive);
      expect(r.waterTempC, isNaN.not);
      expect(r.adjustmentsApplied.length, greaterThan(2));
    });

    test('bloom is recorded in bloomG = doseG × bloomRatio', () {
      final r = gen.generate(ctx(
        module: 'brewing', brewMethod: 'v60', altitudeMasl: 0,
        roastLevel: 'medium', roastDays: 20,
      ));
      // V60 bloomRatio = 2.5; doseG = 20 → bloomG = 50
      expect(r.bloomG, 50.0);
    });
  });
}

extension on Matcher {
  Matcher get not => isNot(this);
}
