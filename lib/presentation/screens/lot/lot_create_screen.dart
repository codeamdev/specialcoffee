import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:special_coffee/core/constants/app_constants.dart';
import 'package:special_coffee/core/di/providers.dart';
import 'package:special_coffee/core/theme/app_colors.dart';
import 'package:special_coffee/core/theme/app_text_styles.dart';
import 'package:special_coffee/domain/entities/lot.dart';
import 'package:special_coffee/presentation/providers/auth_provider.dart';
import 'package:special_coffee/presentation/providers/lot_provider.dart';
import 'package:special_coffee/domain/entities/coffee_variety.dart';
import 'package:special_coffee/presentation/providers/varieties_provider.dart';
import 'package:special_coffee/presentation/providers/weather_provider.dart';

// ── Screen ─────────────────────────────────────────────────────────────────

class LotCreateScreen extends ConsumerStatefulWidget {
  const LotCreateScreen({super.key, this.existing});

  final Lot? existing;

  @override
  ConsumerState<LotCreateScreen> createState() => _LotCreateScreenState();
}

class _LotCreateScreenState extends ConsumerState<LotCreateScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _altitudeCtrl = TextEditingController(text: '1650');
  final _regionCtrl   = TextEditingController(text: 'Huila');
  final _latCtrl      = TextEditingController();
  final _lngCtrl      = TextEditingController();
  final _farmAreaCtrl    = TextEditingController();
  final _plantAgeCtrl   = TextEditingController();
  final _notesCtrl       = TextEditingController();

  Set<String> _selectedIds = {};
  String?     _plantType;
  bool        _saving      = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _altitudeCtrl.text = e.altitudeMasl.toString();
      _regionCtrl.text   = e.region;
      if (e.latitude != null)      _latCtrl.text      = e.latitude!.toStringAsFixed(6);
      if (e.longitude != null)     _lngCtrl.text      = e.longitude!.toStringAsFixed(6);
      if (e.farmAreaHa != null)    _farmAreaCtrl.text  = e.farmAreaHa!.toString();
      if (e.plantAgeYears != null) _plantAgeCtrl.text = e.plantAgeYears!.toString();
      _notesCtrl.text = e.notes ?? '';
      _plantType      = e.plantType;
      _selectedIds    = e.blendVarietyIds != null
          ? e.blendVarietyIds!.split(',').toSet()
          : {e.varietyId};
    } else {
      _fetchGps();
    }
  }

  Future<void> _fetchGps() async {
    try {
      final gps = await ref.read(currentGpsPositionProvider.future);
      if (gps != null && mounted) {
        setState(() {
          _altitudeCtrl.text = gps.altitudeMeters.round().toString();
          _latCtrl.text = gps.latitude.toStringAsFixed(6);
          _lngCtrl.text = gps.longitude.toStringAsFixed(6);
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _altitudeCtrl.dispose();
    _regionCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _farmAreaCtrl.dispose();
    _plantAgeCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final varieties = ref.watch(coffeeVarietiesProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: Text(widget.existing == null ? 'Nuevo Lote' : 'Editar Lote')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildVarietySection(varieties),
              const SizedBox(height: 12),
              _buildCultivoSection(),
              const SizedBox(height: 12),
              _buildLocationSection(),
              const SizedBox(height: 12),
              _buildNotesSection(),
              const SizedBox(height: 24),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Form sections ─────────────────────────────────────────────────────────

  Widget _buildVarietySection(AsyncValue<List<CoffeeVariety>> varietiesAsync) {
    return _FormSection(
      title: 'Variedad y ubicación',
      icon: Icons.eco_outlined,
      children: [
        varietiesAsync.when(
          loading: () => const LinearProgressIndicator(),
          error:   (_, __) => const Text('Error al cargar variedades'),
          data: (varieties) {
            return _VarietyMultiSelect(
              varieties: varieties,
              selectedIds: _selectedIds,
              onChanged: (ids) => setState(() => _selectedIds = ids),
            );
          },
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: _altitudeCtrl,
              decoration: _decor('Altitud (msnm)'),
              keyboardType: TextInputType.number,
              style: AppTextStyles.numericSmall.copyWith(color: AppColors.onSurface),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n < 500 || n > 3200) return '500–3200';
                return null;
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: _regionCtrl,
              decoration: _decor('Región / Municipio'),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
          ),
        ]),
      ],
    );
  }

  Widget _buildCultivoSection() {
    const tipos = [
      ('nuevo',     'Nuevo',     Icons.eco_outlined),
      ('reciembra', 'Reciembra', Icons.replay_outlined),
      ('soca',      'Soca',      Icons.content_cut_outlined),
    ];
    return _FormSection(
      title: 'Características del cultivo',
      icon:  Icons.agriculture_outlined,
      children: [
        TextFormField(
          controller:   _plantAgeCtrl,
          decoration:   _decor('Años del café'),
          keyboardType: TextInputType.number,
          style: AppTextStyles.numericSmall.copyWith(color: AppColors.onSurface),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return null;
            final n = int.tryParse(v.trim());
            if (n == null || n < 1 || n > 100) return '1–100';
            return null;
          },
        ),
        const SizedBox(height: 14),
        Text('Tipo de plantación',
            style: AppTextStyles.labelMedium
                .copyWith(color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 8),
        Row(
          children: tipos.map((t) {
            final (key, label, icon) = t;
            final selected = _plantType == key;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _plantType = key),
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.caramel.withValues(alpha: 0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? AppColors.caramel
                            : AppColors.outlineVariant,
                        width: selected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(icon,
                            size:  18,
                            color: selected
                                ? AppColors.caramel
                                : AppColors.onSurfaceVariant),
                        const SizedBox(height: 4),
                        Text(label,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: selected
                                  ? AppColors.caramel
                                  : AppColors.onSurface,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            )),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return _FormSection(
      title: 'Datos de finca',
      icon: Icons.location_on_outlined,
      subtitle: 'Obtenidos automáticamente del GPS.',
      children: [
        Row(children: [
          Expanded(
            child: TextFormField(
              controller: _latCtrl,
              enabled: false,
              decoration: _decor('Latitud'),
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              style:
                  AppTextStyles.numericSmall.copyWith(color: AppColors.onSurface),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: _lngCtrl,
              enabled: false,
              decoration: _decor('Longitud'),
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              style:
                  AppTextStyles.numericSmall.copyWith(color: AppColors.onSurface),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        TextFormField(
          controller: _farmAreaCtrl,
          decoration: _decor('Área de finca (ha)'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: AppTextStyles.numericSmall.copyWith(color: AppColors.onSurface),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return null;
            final n = double.tryParse(v.trim());
            if (n == null || n <= 0 || n > 10000) return '0–10000 ha';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return _FormSection(
      title: 'Notas',
      icon: Icons.notes_outlined,
      children: [
        TextFormField(
          controller: _notesCtrl,
          decoration: _decor('Observaciones (opcional)'),
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _saving ? null : _submit,
        icon: _saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.save_outlined, size: 18),
        label: Text(
          _saving ? 'Guardando...' : 'Guardar lote',
          style: AppTextStyles.buttonLarge,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.caramel,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.caramel.withValues(alpha: 0.6),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // ── Logic ─────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos una variedad')),
      );
      return;
    }
    setState(() => _saving = true);

    try {
      final userId    = ref.read(currentUserIdProvider);
      final varieties = ref.read(coffeeVarietiesProvider).value ?? const [];

      final selected  = varieties.where((v) => _selectedIds.contains(v.id)).toList();
      final primaryId = selected.isNotEmpty ? selected.first.id : _selectedIds.first;
      final names     = selected.map((v) => v.name).join(' + ');
      final isBlend   = selected.length > 1;

      final existing = widget.existing;
      final lotId = existing?.id ?? const Uuid().v4();
      final lot = Lot(
        id:              lotId,
        userId:          userId,
        varietyId:       primaryId,
        varietyName:     names.isNotEmpty ? names : primaryId,
        altitudeMasl:    int.parse(_altitudeCtrl.text.trim()),
        region:          _regionCtrl.text.trim(),
        processType:     existing?.processType ?? '',
        status:          existing?.status ?? 'pending',
        latitude:        double.tryParse(_latCtrl.text.trim()),
        longitude:       double.tryParse(_lngCtrl.text.trim()),
        farmAreaHa:      double.tryParse(_farmAreaCtrl.text.trim()),
        blendVarietyIds: isBlend ? _selectedIds.join(',') : null,
        plantAgeYears:   int.tryParse(_plantAgeCtrl.text.trim()),
        plantType:       _plantType,
        createdAt:       existing?.createdAt ?? DateTime.now(),
        notes:           _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );

      await ref.read(lotLocalRepoProvider).saveLot(lot);
      ref.invalidate(userLotsProvider);

      if (!mounted) return;
      context.go(AppRoutes.lotDetail.replaceFirst(':id', lotId));
    } catch (e) {
      setState(() => _saving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );
}

// ── Variety multi-select ───────────────────────────────────────────────────

class _VarietyMultiSelect extends StatelessWidget {
  const _VarietyMultiSelect({
    required this.varieties,
    required this.selectedIds,
    required this.onChanged,
  });

  final List<CoffeeVariety>       varieties;
  final Set<String>               selectedIds;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          selectedIds.length > 1 ? 'Blend seleccionado' : 'Variedad',
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: varieties.map((v) {
            final selected = selectedIds.contains(v.id);
            return FilterChip(
              label: Text(v.name),
              selected: selected,
              onSelected: (checked) {
                final next = Set<String>.from(selectedIds);
                if (checked) {
                  next.add(v.id);
                } else if (next.length > 1) {
                  next.remove(v.id);
                }
                onChanged(next);
              },
              selectedColor: AppColors.caramel.withValues(alpha: 0.15),
              checkmarkColor: AppColors.caramel,
              labelStyle: TextStyle(
                color: selected ? AppColors.caramel : AppColors.onSurface,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: selected
                    ? AppColors.caramel
                    : AppColors.outlineVariant,
                width: selected ? 1.5 : 1.0,
              ),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            );
          }).toList(),
        ),
        if (selectedIds.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.blender_outlined,
                  size: 14, color: AppColors.caramel),
              const SizedBox(width: 4),
              Text('Blend de ${selectedIds.length} variedades',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.caramel)),
            ],
          ),
        ],
      ],
    );
  }
}

// ── Reusable section container ─────────────────────────────────────────────

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.title,
    required this.icon,
    required this.children,
    this.subtitle,
  });

  final String        title;
  final IconData      icon;
  final String?       subtitle;
  final List<Widget>  children;

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
          Row(children: [
            Icon(icon, size: 18, color: AppColors.caramel),
            const SizedBox(width: 8),
            Text(title, style: AppTextStyles.labelLarge),
          ]),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: AppTextStyles.bodySmall),
          ],
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
