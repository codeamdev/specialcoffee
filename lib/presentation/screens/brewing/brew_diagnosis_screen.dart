import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:special_coffee/core/theme/app_colors.dart';
import 'package:special_coffee/core/theme/app_text_styles.dart';
import 'package:special_coffee/presentation/providers/brewing_session_provider.dart';

class BrewDiagnosisScreen extends ConsumerStatefulWidget {
  const BrewDiagnosisScreen({super.key, required this.params});

  final Map<String, dynamic> params;

  @override
  ConsumerState<BrewDiagnosisScreen> createState() =>
      _BrewDiagnosisScreenState();
}

class _BrewDiagnosisScreenState extends ConsumerState<BrewDiagnosisScreen> {
  final _timeCtrl  = TextEditingController();
  final _tdsCtrl   = TextEditingController();
  final _yieldCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _timeCtrl.dispose();
    _tdsCtrl.dispose();
    _yieldCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String get _method => (widget.params['method'] as String?) ?? 'desconocido';
  double get _doseG  => (widget.params['doseG']  as double?) ?? 0.0;
  double get _waterG => (widget.params['waterG'] as double?) ?? 0.0;
  double get _tempC  => (widget.params['waterTempC'] as double?) ?? 0.0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(brewingSessionProvider);

    ref.listen(brewingSessionProvider, (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.error!),
          backgroundColor: AppColors.error,
        ));
      }
      if (next.isSaved) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Sesión guardada correctamente'),
          backgroundColor: AppColors.success,
        ));
        Navigator.of(context).pop();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Diagnóstico post-extracción'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RecipeSummary(
                method: _method, doseG: _doseG,
                waterG: _waterG, tempC: _tempC),
            const SizedBox(height: 20),
            _Section(
              title: 'Resultados de la extracción',
              children: [
                _field(_timeCtrl,  'Tiempo real (seg)',   TextInputType.number,
                    hint: 'ej. 240'),
                const SizedBox(height: 12),
                _field(_tdsCtrl,   'TDS medido (%)',
                    const TextInputType.numberWithOptions(decimal: true),
                    hint: 'ej. 1.35  — opcional'),
                const SizedBox(height: 12),
                _field(_yieldCtrl, 'Rendimiento (g)',
                    const TextInputType.numberWithOptions(decimal: true),
                    hint: 'ej. 36  — opcional'),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesCtrl,
                  maxLines: 3,
                  decoration: _decor('Notas de cata')
                      .copyWith(hintText: 'Sabores, aroma, textura…'),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: state.isLoading ? null : _save,
                icon: state.isLoading
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_outlined),
                label: Text(
                  state.isLoading ? 'Guardando…' : 'Guardar y volver',
                  style: AppTextStyles.buttonLarge,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.espresso,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.espresso.withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    await ref.read(brewingSessionProvider.notifier).save(
          method:        _method,
          doseG:         _doseG,
          waterG:        _waterG,
          waterTempC:    _tempC,
          actualTimeSec: int.tryParse(_timeCtrl.text.trim()),
          tdsPct:        double.tryParse(_tdsCtrl.text.trim()),
          yieldG:        double.tryParse(_yieldCtrl.text.trim()),
          notes:         _notesCtrl.text.trim().isEmpty
                             ? null
                             : _notesCtrl.text.trim(),
          brewedAt:      DateTime.now(),
        );
  }

  Widget _field(TextEditingController ctrl, String label,
      TextInputType type, {String? hint}) =>
      TextField(
        controller: ctrl,
        keyboardType: type,
        decoration: _decor(label).copyWith(hintText: hint),
      );

  InputDecoration _decor(String label) => InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.labelMedium,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.caramel, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );
}

class _RecipeSummary extends StatelessWidget {
  const _RecipeSummary({
    required this.method, required this.doseG,
    required this.waterG, required this.tempC,
  });
  final String method;
  final double doseG, waterG, tempC;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.espressoLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Chip(Icons.coffee_maker_outlined, method),
          _Chip(Icons.scale_outlined, '${doseG.toStringAsFixed(1)} g'),
          _Chip(Icons.water_drop_outlined, '${waterG.toStringAsFixed(0)} g'),
          _Chip(Icons.thermostat_outlined, '${tempC.toStringAsFixed(0)} °C'),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.icon, this.label);
  final IconData icon;
  final String   label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.cream, size: 18),
        const SizedBox(height: 4),
        Text(label,
            style: AppTextStyles.labelMedium.copyWith(color: AppColors.cream)),
      ],
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
