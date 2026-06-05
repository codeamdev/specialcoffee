import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:special_coffee/core/theme/app_colors.dart';
import 'package:special_coffee/core/theme/app_text_styles.dart';
import 'package:special_coffee/domain/entities/harvest_session.dart';
import 'package:special_coffee/presentation/providers/harvest_provider.dart';
import 'package:special_coffee/presentation/widgets/ai/gemini_status_banner.dart';
import 'package:special_coffee/presentation/widgets/ai/recommendation_card.dart';
import 'package:special_coffee/presentation/widgets/learning_card.dart';

// ── Screen ─────────────────────────────────────────────────────────────────

class HarvestScreen extends ConsumerStatefulWidget {
  const HarvestScreen({super.key, required this.lotId});

  final String lotId;

  @override
  ConsumerState<HarvestScreen> createState() => _HarvestScreenState();
}

class _HarvestScreenState extends ConsumerState<HarvestScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _kgCtrl    = TextEditingController();
  final _pickerCtrl = TextEditingController();
  final _brixCtrl  = TextEditingController();
  final _ripeCtrl  = TextEditingController();
  final _greenCtrl = TextEditingController();
  final _overripeCtrl = TextEditingController();
  final _dryCtrl   = TextEditingController();
  final _notesCtrl = TextEditingController();

  DateTime _passDate = DateTime.now();
  bool _showRipeness = false;

  HarvestNotifier get _notifier =>
      ref.read(harvestProvider(widget.lotId).notifier);

  @override
  void dispose() {
    _kgCtrl.dispose();
    _pickerCtrl.dispose();
    _brixCtrl.dispose();
    _ripeCtrl.dispose();
    _greenCtrl.dispose();
    _overripeCtrl.dispose();
    _dryCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // ── Ripeness validation ────────────────────────────────────────────────────

  String? _validateRipenessSum() {
    if (!_showRipeness) return null;
    final ripe    = double.tryParse(_ripeCtrl.text) ?? 0;
    final green   = double.tryParse(_greenCtrl.text) ?? 0;
    final overripe = double.tryParse(_overripeCtrl.text) ?? 0;
    final dry     = double.tryParse(_dryCtrl.text) ?? 0;
    final sum = ripe + green + overripe + dry;
    if (sum < 90 || sum > 110) return 'Suma fuera de rango (90–110%)';
    return null;
  }

  Color _ripenessSumColor() {
    final ripe    = double.tryParse(_ripeCtrl.text) ?? 0;
    final green   = double.tryParse(_greenCtrl.text) ?? 0;
    final overripe = double.tryParse(_overripeCtrl.text) ?? 0;
    final dry     = double.tryParse(_dryCtrl.text) ?? 0;
    final sum = ripe + green + overripe + dry;
    if (sum >= 97 && sum <= 103) return AppColors.success;
    if (sum >= 90 && sum <= 110) return AppColors.warning;
    return AppColors.error;
  }

  bool _isRipenessSumBlocking() {
    if (!_showRipeness) return false;
    final ripe    = double.tryParse(_ripeCtrl.text) ?? 0;
    final green   = double.tryParse(_greenCtrl.text) ?? 0;
    final overripe = double.tryParse(_overripeCtrl.text) ?? 0;
    final dry     = double.tryParse(_dryCtrl.text) ?? 0;
    final sum = ripe + green + overripe + dry;
    return sum < 90 || sum > 110;
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isRipenessSumBlocking()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Corrige la suma de madurez antes de continuar.')),
      );
      return;
    }

    final ripe     = _showRipeness ? double.tryParse(_ripeCtrl.text) : null;
    final green    = _showRipeness ? double.tryParse(_greenCtrl.text) : null;
    final overripe = _showRipeness ? double.tryParse(_overripeCtrl.text) : null;
    final dry      = _showRipeness ? double.tryParse(_dryCtrl.text) : null;

    await _notifier.addPass(
      kgCollected: double.parse(_kgCtrl.text),
      pickerCount: int.parse(_pickerCtrl.text),
      passDate: _passDate,
      ripenessRipePct: ripe,
      ripenessGreenPct: green,
      ripenessOverripePct: overripe,
      ripenesDryPct: dry,
      brixDegrees: double.tryParse(_brixCtrl.text),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    _kgCtrl.clear();
    _pickerCtrl.clear();
    _brixCtrl.clear();
    _ripeCtrl.clear();
    _greenCtrl.clear();
    _overripeCtrl.clear();
    _dryCtrl.clear();
    _notesCtrl.clear();
    setState(() { _passDate = DateTime.now(); _showRipeness = false; });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(harvestProvider(widget.lotId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Recolección'),
        actions: [
          if (state.hasPasses)
            TextButton(
              onPressed: () => _confirmComplete(context),
              child: Text(
                'Cerrar sesión',
                style: AppTextStyles.labelMedium.copyWith(color: AppColors.error),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const GeminiStatusBanner(),
            const SizedBox(height: 12),
            const LearningCard(
              title: 'Recolección selectiva',
              content:
                  'La recolección de cerezas maduras (≥95% madurez visual) es '
                  'el primer factor de calidad del café. Un Brix ≥18° indica '
                  'madurez óptima según estándares SCA.',
              terms: [
                ('Brix', 'Grados de concentración de azúcares en la cereza (refractómetro)'),
                ('Madurez visual', 'Porcentaje de cerezas de color rojo/amarillo respecto al total'),
              ],
              tip: 'Recolecta en las primeras horas de la mañana para preservar '
                  'los azúcares y reducir el calor de campo.',
            ),
            const SizedBox(height: 12),

            // ── Pass history ─────────────────────────────────────────────────
            if (state.hasPasses) ...[
              _SectionTitle('Pases registrados'),
              const SizedBox(height: 8),
              ...state.passes.map((p) => _PassTile(pass: p)),
              const SizedBox(height: 16),
              _TotalSummaryCard(passes: state.passes),
              const SizedBox(height: 20),
            ],

            // ── AI recommendations ───────────────────────────────────────────
            if (state.recommendations.isNotEmpty) ...[
              _SectionTitle('Recomendaciones IA'),
              const SizedBox(height: 8),
              ...state.recommendations.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: RecommendationCard(recommendation: r),
                ),
              ),
              const SizedBox(height: 20),
            ],

            if (state.isAnalyzing)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              ),

            // ── Pass form ────────────────────────────────────────────────────
            _SectionTitle(
              state.hasPasses
                  ? 'Registrar pase #${state.nextPassNumber}'
                  : 'Primer pase de recolección',
            ),
            const SizedBox(height: 12),
            _PassForm(
              formKey: _formKey,
              kgCtrl: _kgCtrl,
              pickerCtrl: _pickerCtrl,
              brixCtrl: _brixCtrl,
              ripeCtrl: _ripeCtrl,
              greenCtrl: _greenCtrl,
              overripeCtrl: _overripeCtrl,
              dryCtrl: _dryCtrl,
              notesCtrl: _notesCtrl,
              passDate: _passDate,
              showRipeness: _showRipeness,
              onDateTap: () => _pickDate(context),
              onToggleRipeness: (v) => setState(() => _showRipeness = v),
              ripenessSumColor: _ripenessSumColor,
              validateRipenessSum: _validateRipenessSum,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: state.isAnalyzing ? null : _submit,
                icon: const Icon(Icons.add),
                label: Text('Registrar pase #${state.nextPassNumber}'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.roleFarmer,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            // ── Next pass reminder info ──────────────────────────────────────
            if (state.hasPasses) ...[
              const SizedBox(height: 16),
              _NextPassInfo(intervalDays: state.nextIntervalDays),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _passDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _passDate = picked);
  }

  Future<void> _confirmComplete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Cerrar sesión de recolección?'),
        content: const Text(
          'Se marcará la sesión como completada. No podrá agregar más pases.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Cerrar',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _notifier.completeSession();
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}

// ── Pass form widget ────────────────────────────────────────────────────────

class _PassForm extends StatefulWidget {
  const _PassForm({
    required this.formKey,
    required this.kgCtrl,
    required this.pickerCtrl,
    required this.brixCtrl,
    required this.ripeCtrl,
    required this.greenCtrl,
    required this.overripeCtrl,
    required this.dryCtrl,
    required this.notesCtrl,
    required this.passDate,
    required this.showRipeness,
    required this.onDateTap,
    required this.onToggleRipeness,
    required this.ripenessSumColor,
    required this.validateRipenessSum,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController kgCtrl;
  final TextEditingController pickerCtrl;
  final TextEditingController brixCtrl;
  final TextEditingController ripeCtrl;
  final TextEditingController greenCtrl;
  final TextEditingController overripeCtrl;
  final TextEditingController dryCtrl;
  final TextEditingController notesCtrl;
  final DateTime passDate;
  final bool showRipeness;
  final VoidCallback onDateTap;
  final ValueChanged<bool> onToggleRipeness;
  final Color Function() ripenessSumColor;
  final String? Function() validateRipenessSum;

  @override
  State<_PassForm> createState() => _PassFormState();
}

class _PassFormState extends State<_PassForm> {
  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date selector
          InkWell(
            onTap: widget.onDateTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 18, color: AppColors.caramel),
                  const SizedBox(width: 10),
                  Text(
                    'Fecha del pase: ${_fmtDate(widget.passDate)}',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Kg + pickers row
          Row(
            children: [
              Expanded(
                child: _NumberField(
                  ctrl: widget.kgCtrl,
                  label: 'kg recolectados',
                  decimal: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requerido';
                    if ((double.tryParse(v) ?? 0) <= 0) return 'Debe ser > 0';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NumberField(
                  ctrl: widget.pickerCtrl,
                  label: 'Recolectores',
                  decimal: false,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requerido';
                    if ((int.tryParse(v) ?? 0) <= 0) return 'Debe ser > 0';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Brix (optional)
          _NumberField(
            ctrl: widget.brixCtrl,
            label: 'Grados Brix (opcional)',
            decimal: true,
            suffix: '°Brix',
          ),
          const SizedBox(height: 12),

          // Ripeness toggle
          Row(
            children: [
              Switch(
                value: widget.showRipeness,
                onChanged: widget.onToggleRipeness,
                activeThumbColor: AppColors.roleFarmer,
              ),
              const SizedBox(width: 8),
              Text(
                'Clasificar madurez',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(width: 8),
              if (!widget.showRipeness)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Sin clasificar',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),

          // Ripeness breakdown
          if (widget.showRipeness) ...[
            const SizedBox(height: 8),
            _RipenessGrid(
              ripeCtrl: widget.ripeCtrl,
              greenCtrl: widget.greenCtrl,
              overripeCtrl: widget.overripeCtrl,
              dryCtrl: widget.dryCtrl,
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: 8),
            _RipenesSumIndicator(
              ripeCtrl: widget.ripeCtrl,
              greenCtrl: widget.greenCtrl,
              overripeCtrl: widget.overripeCtrl,
              dryCtrl: widget.dryCtrl,
              sumColor: widget.ripenessSumColor(),
              validationError: widget.validateRipenessSum(),
            ),
          ],
          const SizedBox(height: 12),

          // Notes
          TextFormField(
            controller: widget.notesCtrl,
            decoration: _inputDecoration('Notas (opcional)'),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// ── Ripeness grid ───────────────────────────────────────────────────────────

class _RipenessGrid extends StatelessWidget {
  const _RipenessGrid({
    required this.ripeCtrl,
    required this.greenCtrl,
    required this.overripeCtrl,
    required this.dryCtrl,
    required this.onChanged,
  });

  final TextEditingController ripeCtrl;
  final TextEditingController greenCtrl;
  final TextEditingController overripeCtrl;
  final TextEditingController dryCtrl;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _NumberField(
                ctrl: ripeCtrl,
                label: 'Maduras (%)',
                decimal: true,
                onChanged: (_) => onChanged(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _NumberField(
                ctrl: greenCtrl,
                label: 'Verdes (%)',
                decimal: true,
                onChanged: (_) => onChanged(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _NumberField(
                ctrl: overripeCtrl,
                label: 'Sobremaduros (%)',
                decimal: true,
                onChanged: (_) => onChanged(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _NumberField(
                ctrl: dryCtrl,
                label: 'Secos (%)',
                decimal: true,
                onChanged: (_) => onChanged(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Ripeness sum indicator ──────────────────────────────────────────────────

class _RipenesSumIndicator extends StatelessWidget {
  const _RipenesSumIndicator({
    required this.ripeCtrl,
    required this.greenCtrl,
    required this.overripeCtrl,
    required this.dryCtrl,
    required this.sumColor,
    this.validationError,
  });

  final TextEditingController ripeCtrl;
  final TextEditingController greenCtrl;
  final TextEditingController overripeCtrl;
  final TextEditingController dryCtrl;
  final Color sumColor;
  final String? validationError;

  double get _sum {
    final ripe    = double.tryParse(ripeCtrl.text) ?? 0;
    final green   = double.tryParse(greenCtrl.text) ?? 0;
    final overripe = double.tryParse(overripeCtrl.text) ?? 0;
    final dry     = double.tryParse(dryCtrl.text) ?? 0;
    return ripe + green + overripe + dry;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: sumColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: sumColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            validationError == null ? Icons.check_circle_outline : Icons.warning_amber_outlined,
            size: 18,
            color: sumColor,
          ),
          const SizedBox(width: 8),
          Text(
            'Suma: ${_sum.toStringAsFixed(1)}%',
            style: AppTextStyles.bodyMedium.copyWith(
              color: sumColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (validationError != null) ...[
            const SizedBox(width: 8),
            Text(
              validationError!,
              style: AppTextStyles.bodySmall.copyWith(color: sumColor),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Pass tile ───────────────────────────────────────────────────────────────

class _PassTile extends StatelessWidget {
  const _PassTile({required this.pass});

  final HarvestPass pass;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          // Pass number badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.roleFarmer.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '#${pass.passNumber}',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.roleFarmer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${pass.kgCollected.toStringAsFixed(1)} kg',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '· ${pass.pickerCount} recolect.',
                      style: AppTextStyles.bodySmall,
                    ),
                    const Spacer(),
                    if (!pass.hasRipenessData)
                      _UnclassifiedChip()
                    else if (pass.ripenessRipePct != null)
                      Text(
                        '${pass.ripenessRipePct!.toStringAsFixed(0)}% maduras',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(_fmtDate(pass.passDate), style: AppTextStyles.bodySmall),
                    if (pass.brixDegrees != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${pass.brixDegrees!.toStringAsFixed(1)}°Brix',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.caramel,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (pass.aiAlertLevel != 'none') ...[
            const SizedBox(width: 8),
            _AlertDot(level: pass.aiAlertLevel),
          ],
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
}

class _UnclassifiedChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Text(
          'Sin clasificar',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      );
}

class _AlertDot extends StatelessWidget {
  const _AlertDot({required this.level});

  final String level;

  @override
  Widget build(BuildContext context) {
    final color = switch (level) {
      'critical' => AppColors.error,
      'high'     => AppColors.warning,
      'warning'  => AppColors.warning,
      _          => AppColors.info,
    };
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// ── Total summary card ──────────────────────────────────────────────────────

class _TotalSummaryCard extends StatelessWidget {
  const _TotalSummaryCard({required this.passes});

  final List<HarvestPass> passes;

  @override
  Widget build(BuildContext context) {
    final totalKg = passes.fold<double>(0, (sum, p) => sum + p.kgCollected);
    final totalPickers = passes.isNotEmpty ? passes.last.pickerCount : 0;
    final avgKgPerPicker =
        totalPickers > 0 ? totalKg / totalPickers : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.roleFarmer.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.roleFarmer.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            label: 'Total kg',
            value: totalKg.toStringAsFixed(1),
            icon: Icons.scale_outlined,
          ),
          _StatItem(
            label: 'Pases',
            value: '${passes.length}',
            icon: Icons.repeat_outlined,
          ),
          _StatItem(
            label: 'kg/recolector',
            value: avgKgPerPicker.toStringAsFixed(1),
            icon: Icons.person_outlined,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Icon(icon, size: 20, color: AppColors.roleFarmer),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.roleFarmer,
            ),
          ),
          Text(label, style: AppTextStyles.bodySmall),
        ],
      );
}

// ── Next pass reminder info ─────────────────────────────────────────────────

class _NextPassInfo extends StatelessWidget {
  const _NextPassInfo({required this.intervalDays});

  final int intervalDays;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.infoContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.notifications_outlined, size: 16, color: AppColors.info),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Próximo pase recomendado en $intervalDays días. '
                'Se programó un recordatorio.',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.info),
              ),
            ),
          ],
        ),
      );
}

// ── Shared helpers ──────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: AppTextStyles.labelLarge.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
      );
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.ctrl,
    required this.label,
    required this.decimal,
    this.suffix,
    this.validator,
    this.onChanged,
  });

  final TextEditingController ctrl;
  final String label;
  final bool decimal;
  final String? suffix;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: ctrl,
        keyboardType:
            decimal ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.allow(
            decimal ? RegExp(r'^\d*\.?\d*') : RegExp(r'^\d*'),
          ),
        ],
        decoration: _inputDecoration(label, suffix: suffix),
        validator: validator,
        onChanged: onChanged,
      );
}

InputDecoration _inputDecoration(String label, {String? suffix}) =>
    InputDecoration(
      labelText: label,
      suffixText: suffix,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.outlineVariant),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
