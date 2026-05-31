import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:special_coffee/ai_engine/models/brew_recipe.dart';
import 'package:special_coffee/core/constants/app_constants.dart';
import 'package:special_coffee/core/theme/app_colors.dart';
import 'package:special_coffee/core/theme/app_text_styles.dart';
import 'package:special_coffee/presentation/providers/brew_provider.dart';

class BrewRecipeScreen extends ConsumerWidget {
  const BrewRecipeScreen({super.key, required this.params});

  final Map<String, dynamic> params;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipe = ref.watch(brewProvider).recipe;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Receta generada'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: recipe == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No hay receta activa.\nVuelve a la pantalla de preparación y genera una receta.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : _RecipeBody(recipe: recipe),
    );
  }
}

class _RecipeBody extends StatelessWidget {
  const _RecipeBody({required this.recipe});

  final BrewRecipe recipe;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MethodBadge(method: recipe.method),
          const SizedBox(height: 20),
          _Section(
            title: 'Parámetros de extracción',
            children: [
              _Row('Dosis',         '${recipe.doseG.toStringAsFixed(1)} g'),
              _Row('Agua',          '${recipe.waterG.toStringAsFixed(0)} g'),
              _Row('Ratio',         '1 : ${recipe.ratio.toStringAsFixed(1)}'),
              _Row('Temperatura',   '${recipe.waterTempC.toStringAsFixed(0)} °C'),
              if (recipe.steepHours > 0)
                _Row('Maceración', '${recipe.steepHours} h (frío)')
              else ...[
                _Row('Bloom',      '${recipe.bloomG.toStringAsFixed(0)} g / ${recipe.bloomSeconds} seg'),
              ],
            ],
          ),
          const SizedBox(height: 12),
          _Section(
            title: 'Objetivos de calidad',
            children: [
              _Row('TDS objetivo',     '${recipe.tdsTargetMin} – ${recipe.tdsTargetMax} %'),
              _Row('Rendimiento obj.', '${recipe.yieldTargetMin} – ${recipe.yieldTargetMax} %'),
            ],
          ),
          if (recipe.adjustmentsApplied.isNotEmpty) ...[
            const SizedBox(height: 12),
            _Section(
              title: 'Ajustes aplicados',
              children: recipe.adjustmentsApplied
                  .map((a) => _Row('·', a))
                  .toList(),
            ),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context.push(
                AppRoutes.brewDiagnosis,
                extra: {
                  'method':      recipe.method,
                  'doseG':       recipe.doseG,
                  'waterG':      recipe.waterG,
                  'waterTempC':  recipe.waterTempC,
                  'tdsMin':      recipe.tdsTargetMin,
                  'tdsMax':      recipe.tdsTargetMax,
                  'yieldMin':    recipe.yieldTargetMin,
                  'yieldMax':    recipe.yieldTargetMax,
                },
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Iniciar extracción'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.caramel,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodBadge extends StatelessWidget {
  const _MethodBadge({required this.method});
  final String method;

  String get _label {
    return switch (method) {
      'v60'         => 'V60',
      'chemex'      => 'Chemex',
      'aeropress'   => 'AeroPress',
      'espresso'    => 'Espresso',
      'moka'        => 'Moka',
      'cold_brew'   => 'Cold Brew',
      _             => method,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.espresso,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        _label,
        style: AppTextStyles.labelLarge.copyWith(
          color: AppColors.cream,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String       title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.labelLarge),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium),
          Text(value,
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
