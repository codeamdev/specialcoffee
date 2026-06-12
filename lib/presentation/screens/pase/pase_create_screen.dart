import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:special_coffee/core/constants/app_constants.dart';
import 'package:special_coffee/core/theme/app_colors.dart';
import 'package:special_coffee/core/theme/app_text_styles.dart';
import 'package:special_coffee/domain/entities/lot.dart';
import 'package:special_coffee/core/di/providers.dart';
import 'package:special_coffee/presentation/providers/auth_provider.dart';
import 'package:special_coffee/presentation/providers/cosecha_pase_provider.dart';
import 'package:special_coffee/presentation/providers/lot_provider.dart';
import 'package:special_coffee/presentation/providers/settings_provider.dart';

class PaseCreateScreen extends ConsumerStatefulWidget {
  const PaseCreateScreen({super.key, this.lotId});

  /// Pre-selected lot. If null the user picks a lot in step 0.
  final String? lotId;

  @override
  ConsumerState<PaseCreateScreen> createState() => _PaseCreateScreenState();
}

class _PaseCreateScreenState extends ConsumerState<PaseCreateScreen> {
  static const _procesos = [
    ('lavado',             'Lavado',             Icons.water_drop_outlined),
    ('natural',            'Natural',            Icons.wb_sunny_outlined),
    ('honey_yellow',       'Honey Amarillo',     Icons.hexagon_outlined),
    ('honey_red',          'Honey Rojo',         Icons.hexagon_outlined),
    ('anaerobic_lactic',   'Anaeróbico Láctico',   Icons.science_outlined),
    ('anaerobic_carbonic', 'Anaeróbico Carbónico',  Icons.bubble_chart_outlined),
  ];

  final _formKey      = GlobalKey<FormState>();
  final _pesoCtrl     = TextEditingController();
  final _brixCtrl     = TextEditingController();
  final _madurezCtrl  = TextEditingController();
  final _notasCtrl    = TextEditingController();

  DateTime _fecha       = DateTime.now();
  String   _tipoProceso = 'lavado';
  bool     _saving      = false;

  // null means user hasn't picked a lot yet (only when widget.lotId is null)
  String? _selectedLotId;
  String? _selectedLotName;

  @override
  void initState() {
    super.initState();
    _selectedLotId   = widget.lotId;
  }

  @override
  void dispose() {
    _pesoCtrl.dispose();
    _brixCtrl.dispose();
    _madurezCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Nuevo pase de cosecha'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: _selectedLotId == null
          ? _LotPicker(onSelected: (lot) => setState(() {
              _selectedLotId   = lot.id;
              _selectedLotName = lot.varietyName;
            }))
          : _buildForm(),
    );
  }

  Widget _buildForm() => Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 48),
          children: [
            // Lot indicator (only when picked from pases tab)
            if (widget.lotId == null) ...[
              _LotIndicator(
                name: _selectedLotName ?? _selectedLotId!,
                onClear: () => setState(() {
                  _selectedLotId   = null;
                  _selectedLotName = null;
                }),
              ),
              const SizedBox(height: 20),
            ],
            _SectionLabel('Fecha de recolección'),
            const SizedBox(height: 8),
            _DatePickerField(
              date:     _fecha,
              onPicked: (d) => setState(() => _fecha = d),
            ),
            const SizedBox(height: 20),
            _SectionLabel('Datos de la recolección'),
            const SizedBox(height: 8),
            _Field(
              ctrl:    _pesoCtrl,
              label:   'Peso cereza (kg)',
              hint:    'ej. 450',
              keyType: TextInputType.number,
              validator: (v) =>
                  (v == null || double.tryParse(v.trim().replaceAll(',', '.')) == null)
                      ? 'Requerido'
                      : null,
            ),
            const SizedBox(height: 12),
            _Field(
              ctrl:    _brixCtrl,
              label:   'Brix promedio (°Bx)',
              hint:    'ej. 21.5',
              keyType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            _Field(
              ctrl:    _madurezCtrl,
              label:   '% madurez visual',
              hint:    'ej. 85',
              keyType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            _SectionLabel('Tipo de proceso'),
            const SizedBox(height: 10),
            _ProcesoSelector(
              selected: _tipoProceso,
              procesos: _procesos,
              onSelect: (v) => setState(() => _tipoProceso = v),
            ),
            const SizedBox(height: 20),
            _SectionLabel('Notas (opcional)'),
            const SizedBox(height: 8),
            TextFormField(
              controller:  _notasCtrl,
              maxLines:    3,
              decoration: InputDecoration(
                hintText:       'Observaciones del día...',
                border:         OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled:         true,
                fillColor:      Colors.white,
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _saving ? null : _submit,
              style: FilledButton.styleFrom(
                minimumSize:     const Size.fromHeight(52),
                shape:           RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                backgroundColor: AppColors.caramel,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'Registrar pase',
                      style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
                    ),
            ),
          ],
        ),
      );

  static String _norm(String s) => s.trim().replaceAll(',', '.');

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final lotId = _selectedLotId!;
    // Capture repo and userId before any async gap — avoids autoDispose issues.
    final repo   = ref.read(cosechaPaseLocalRepoProvider);
    final userId = ref.read(currentUserIdProvider);
    try {
      final pase = await repo.create(
        lotId:            lotId,
        createdBy:        userId,
        fechaRecoleccion: _fecha,
        pesoCerezaKg:     double.parse(_norm(_pesoCtrl.text)),
        tipoProceso:      _tipoProceso,
        brixPromedio:     double.tryParse(_norm(_brixCtrl.text)),
        pctMadurezVisual: double.tryParse(_norm(_madurezCtrl.text)),
        notas:            _notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim(),
      );
      if (mounted) {
        ref.invalidate(pasesByLotProvider(lotId));
        ref.invalidate(activePasesProvider);
        context.go('${AppRoutes.pases}/${pase.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            duration: const Duration(seconds: 6),
            action: SnackBarAction(label: 'OK', onPressed: () {}),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ── Lot picker (step 0 when no lotId pre-selected) ────────────────────────────

class _LotPicker extends ConsumerWidget {
  const _LotPicker({required this.onSelected});

  final ValueChanged<Lot> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lotsAsync = ref.watch(userLotsProvider);
    return lotsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:   (e, _) => Center(child: Text('Error: $e')),
      data: (lots) {
        if (lots.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.disabled),
                const SizedBox(height: 12),
                const Text('No tienes lotes registrados.'),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.go(AppRoutes.lotCreate),
                  child: const Text('Crear un lote'),
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          itemCount: lots.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'Selecciona el lote para este pase',
                  style: AppTextStyles.labelLarge
                      .copyWith(color: AppColors.onSurfaceVariant),
                ),
              );
            }
            final lot = lots[i - 1];
            return InkWell(
              onTap: () => onSelected(lot),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.caramel.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.eco_outlined,
                          color: AppColors.caramel, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(lot.varietyName,
                              style: AppTextStyles.bodyMedium
                                  .copyWith(fontWeight: FontWeight.w600)),
                          Text(
                            '${lot.region} · ${lot.altitudeMasl} msnm',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        size: 18, color: AppColors.onSurfaceVariant),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ── Lot indicator chip shown at top of form after lot is selected ─────────────

class _LotIndicator extends StatelessWidget {
  const _LotIndicator({required this.name, required this.onClear});

  final String    name;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.caramel.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.caramel.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.eco_outlined, size: 18, color: AppColors.caramel),
            const SizedBox(width: 8),
            Expanded(
              child: Text(name,
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600)),
            ),
            GestureDetector(
              onTap: onClear,
              child: const Icon(Icons.close_rounded,
                  size: 18, color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      );
}

// ── Widgets internos ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: AppTextStyles.labelLarge.copyWith(color: AppColors.onSurfaceVariant),
      );
}

class _Field extends StatelessWidget {
  const _Field({
    required this.ctrl,
    required this.label,
    required this.hint,
    this.keyType = TextInputType.text,
    this.validator,
  });

  final TextEditingController ctrl;
  final String               label;
  final String               hint;
  final TextInputType        keyType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller:  ctrl,
        keyboardType: keyType,
        validator:   validator,
        decoration: InputDecoration(
          labelText:   label,
          hintText:    hint,
          border:      OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled:      true,
          fillColor:   Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      );
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({required this.date, required this.onPicked});

  final DateTime                date;
  final ValueChanged<DateTime>  onPicked;

  @override
  Widget build(BuildContext context) {
    final label =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context:     context,
          initialDate: date,
          firstDate:   DateTime(2020),
          lastDate:    DateTime.now(),
        );
        if (picked != null) onPicked(picked);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: AppColors.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.caramel),
            const SizedBox(width: 10),
            Text(label, style: AppTextStyles.bodyMedium),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _ProcesoSelector extends ConsumerWidget {
  const _ProcesoSelector({
    required this.selected,
    required this.procesos,
    required this.onSelect,
  });

  final String                           selected;
  final List<(String, String, IconData)> procesos;
  final ValueChanged<String>             onSelect;

  static const _explanations = <String, String>{
    'lavado':
        'El café se despulpa y fermenta en agua, luego se lava para eliminar el mucílago. '
        'Produce tazas limpias con alta acidez y notas florales. Proceso estándar en Colombia.',
    'natural':
        'El café se seca con la cereza intacta. El mucílago fermenta naturalmente, '
        'aportando dulzura, cuerpo y notas frutales intensas. Requiere control riguroso del secado.',
    'honey_yellow':
        'Se retira la pulpa pero se conserva parte del mucílago (~25%). '
        'Genera perfiles suaves con acidez moderada y ligeras notas dulces.',
    'honey_red':
        'Mayor retención de mucílago (~50%) que el amarillo. '
        'Desarrolla más dulzura y cuerpo, con notas a fruta madura y caramelo.',
    'anaerobic_lactic':
        'Fermentación sin oxígeno que favorece bacterias lácticas. '
        'Genera perfiles complejos con notas ácidas, frutales y winey. '
        'Requiere control preciso de temperatura.',
    'anaerobic_carbonic':
        'Inspirado en la maceración carbónica del vino. '
        'Produce perfiles únicos con alta complejidad, notas tropicales y dulzura pronunciada.',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showExplanations = ref.watch(learningModeProvider);
    return Column(
      children: procesos.map((p) {
        final (key, label, icon) = p;
        final isSelected = key == selected;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            children: [
              InkWell(
                onTap: () => onSelect(key),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.caramel.withValues(alpha: 0.08)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.caramel : AppColors.outlineVariant,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(icon,
                          size: 20,
                          color: isSelected
                              ? AppColors.caramel
                              : AppColors.onSurfaceVariant),
                      const SizedBox(width: 12),
                      Text(
                        label,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected
                              ? AppColors.caramel
                              : AppColors.onSurface,
                        ),
                      ),
                      const Spacer(),
                      if (isSelected)
                        const Icon(Icons.check_circle_rounded,
                            size: 18, color: AppColors.caramel),
                    ],
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                child: (isSelected && showExplanations)
                    ? Container(
                        margin: const EdgeInsets.only(top: 4, bottom: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.caramel.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color:
                                  AppColors.caramel.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                size: 16, color: AppColors.caramel),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _explanations[key] ?? '',
                                style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.onSurface),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
