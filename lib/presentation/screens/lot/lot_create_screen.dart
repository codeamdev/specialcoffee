import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:special_coffee/ai_engine/models/ai_context.dart';
import 'package:uuid/uuid.dart';
import 'package:special_coffee/ai_engine/models/ai_rule.dart';
import 'package:special_coffee/core/constants/app_constants.dart';
import 'package:special_coffee/core/theme/app_colors.dart';
import 'package:special_coffee/core/theme/app_text_styles.dart';
import 'package:special_coffee/domain/entities/lot.dart';
import 'package:special_coffee/presentation/providers/auth_provider.dart';
import 'package:special_coffee/presentation/providers/lot_provider.dart';
import 'package:special_coffee/domain/entities/coffee_variety.dart';
import 'package:special_coffee/presentation/providers/varieties_provider.dart';
import 'package:special_coffee/presentation/providers/weather_provider.dart';
import 'package:special_coffee/presentation/widgets/ai/gemini_status_banner.dart';
import 'package:special_coffee/presentation/widgets/ai/recommendation_card.dart';
import 'package:special_coffee/presentation/widgets/guides/process_guide_card.dart';

// ── Screen ─────────────────────────────────────────────────────────────────

class LotCreateScreen extends ConsumerStatefulWidget {
  const LotCreateScreen({super.key});

  @override
  ConsumerState<LotCreateScreen> createState() => _LotCreateScreenState();
}

class _LotCreateScreenState extends ConsumerState<LotCreateScreen> {
  static const _processes = [
    ('lavado',           'Lavado'),
    ('natural',          'Natural'),
    ('anaerobic_lactic', 'Anaeróbico'),
    ('honey_yellow',     'Honey'),
  ];

  final _formKey        = GlobalKey<FormState>();
  final _scrollCtrl     = ScrollController();
  final _recsKey        = GlobalKey();
  final _altitudeCtrl   = TextEditingController(text: '1650');
  final _regionCtrl     = TextEditingController(text: 'Huila');
  final _tempCtrl       = TextEditingController(text: '20.0');
  final _humidityCtrl   = TextEditingController(text: '75.0');

  String  _varietyId        = 'var_castillo';
  double  _rainPct          = 10.0;
  String  _processType      = 'lavado';
  String? _createdLotId;
  bool    _weatherAutoFilled = false;

  @override
  void initState() {
    super.initState();
    _fetchGpsAndWeather();
  }

  Future<void> _fetchGpsAndWeather() async {
    double? lat, lng;
    try {
      final gps = await ref.read(currentGpsPositionProvider.future);
      if (gps != null && mounted) {
        lat = gps.latitude;
        lng = gps.longitude;
        setState(() =>
            _altitudeCtrl.text = gps.altitudeMeters.round().toString());
      }
    } catch (_) {}

    if (lat == null || lng == null) return;
    try {
      final weather = await ref
          .read(weatherProvider.notifier)
          .fetchForLocation(lat: lat, lng: lng);
      if (weather != null && mounted) {
        setState(() {
          if (weather.ambientTempC != null) {
            _tempCtrl.text = weather.ambientTempC!.toStringAsFixed(1);
          }
          if (weather.ambientHumidityPct != null) {
            _humidityCtrl.text = weather.ambientHumidityPct!.toStringAsFixed(1);
          }
          if (weather.rainProbabilityPct != null) {
            _rainPct = weather.rainProbabilityPct!.clamp(0.0, 100.0);
          }
          _weatherAutoFilled = true;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _altitudeCtrl.dispose();
    _regionCtrl.dispose();
    _tempCtrl.dispose();
    _humidityCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state     = ref.watch(lotCreateProvider);
    final varieties = ref.watch(coffeeVarietiesProvider);

    ref.listen(lotCreateProvider, (_, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
      if (next.hasValue && next.value!.isNotEmpty) {
        _scrollToRecs();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Nuevo Lote'),
        actions: [
          if (state.hasValue && state.value!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh_outlined),
              tooltip: 'Limpiar y nuevo',
              onPressed: () => ref.read(lotCreateProvider.notifier).reset(),
            ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const GeminiStatusBanner(),
            _buildIntro(),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildVarietySection(varieties),
                  const SizedBox(height: 12),
                  _buildEnvironmentSection(),
                  const SizedBox(height: 12),
                  _buildProcessSection(),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ProcessTypeGuideCard(
              key: ValueKey(_processType),
              processType: _processType,
            ),
            const SizedBox(height: 24),
            _buildSubmitButton(state),
            AnimatedSize(
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOut,
              child: state.hasValue && state.value!.isNotEmpty
                  ? _RecommendationsSection(
                      key: _recsKey,
                      recommendations: state.value!,
                      lotId: _createdLotId,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Form sections ─────────────────────────────────────────────────────────

  Widget _buildIntro() {
    return Text(
      'Registra los datos del lote para recibir recomendaciones de proceso basadas en IA.',
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
    );
  }

  Widget _buildVarietySection(AsyncValue<List<CoffeeVariety>> varietiesAsync) {
    return _FormSection(
      title: 'Variedad y ubicación',
      icon: Icons.eco_outlined,
      children: [
        varietiesAsync.when(
          loading: () => DropdownButtonFormField<String>(
            value: null,
            decoration: _inputDecor('Variedad'),
            items: const [],
            onChanged: null,
          ),
          error: (_, __) => DropdownButtonFormField<String>(
            value: null,
            decoration: _inputDecor('Variedad (error al cargar)'),
            items: const [],
            onChanged: null,
          ),
          data: (varieties) {
            final validId = varieties.any((v) => v.id == _varietyId)
                ? _varietyId
                : (varieties.isNotEmpty ? varieties.first.id : null);
            return DropdownButtonFormField<String>(
              value: validId,
              decoration: _inputDecor('Variedad'),
              items: varieties
                  .map((v) => DropdownMenuItem(value: v.id, child: Text(v.name)))
                  .toList(),
              onChanged: (val) => setState(() => _varietyId = val ?? _varietyId),
              validator: (v) => v == null ? 'Selecciona una variedad' : null,
            );
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _altitudeCtrl,
                decoration: _inputDecor('Altitud (msnm)'),
                keyboardType: TextInputType.number,
                style: AppTextStyles.numericSmall
                    .copyWith(color: AppColors.onSurface),
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
                decoration: _inputDecor('Región / Municipio'),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEnvironmentSection() {
    return _FormSection(
      title: 'Condiciones ambientales',
      icon: Icons.thermostat_outlined,
      children: [
        if (_weatherAutoFilled)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.cloud_done_outlined,
                    size: 14, color: AppColors.aiBlue),
                const SizedBox(width: 4),
                Text(
                  'Datos obtenidos automáticamente — puedes editarlos',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.aiBlue),
                ),
              ],
            ),
          ),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _tempCtrl,
                decoration: _inputDecor('Temperatura (°C)'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: AppTextStyles.numericSmall
                    .copyWith(color: AppColors.onSurface),
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  if (n == null || n < 5 || n > 45) return '5–45 °C';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _humidityCtrl,
                decoration: _inputDecor('Humedad (%)'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: AppTextStyles.numericSmall
                    .copyWith(color: AppColors.onSurface),
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  if (n == null || n < 0 || n > 100) return '0–100%';
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(Icons.water_drop_outlined,
                size: 18, color: AppColors.aiBlue),
            const SizedBox(width: 8),
            Text(
              'Lluvia: ',
              style: AppTextStyles.labelMedium,
            ),
            Text(
              '${_rainPct.round()}%',
              style: AppTextStyles.numericSmall
                  .copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        Slider(
          value: _rainPct,
          min: 0,
          max: 100,
          divisions: 20,
          activeColor: AppColors.aiBlue,
          onChanged: (val) => setState(() => _rainPct = val),
        ),
      ],
    );
  }

  Widget _buildProcessSection() {
    return _FormSection(
      title: 'Proceso tentativo',
      icon: Icons.science_outlined,
      subtitle: 'La IA puede sugerir uno diferente según las condiciones.',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _processes.map((p) {
            final selected = _processType == p.$1;
            return GestureDetector(
              onTap: () => setState(() => _processType = p.$1),
              child: ChoiceChip(
                label: Text(p.$2),
                selected: selected,
                selectedColor: AppColors.aiBlueContainer,
                labelStyle: AppTextStyles.labelMedium.copyWith(
                  color: selected
                      ? AppColors.aiBlue
                      : AppColors.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
                onSelected: (_) => setState(() => _processType = p.$1),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Widget _buildSubmitButton(AsyncValue<List<Recommendation>> state) {
    final isLoading = state.isLoading;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : _submit,
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.auto_awesome_rounded, size: 18),
        label: Text(
          isLoading ? 'Analizando...' : 'Crear lote y ver recomendaciones IA',
          style: AppTextStyles.buttonLarge,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.aiBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.aiBlue.withValues(alpha: 0.6),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // ── Logic ─────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final altitude     = int.parse(_altitudeCtrl.text.trim());
    final temp         = double.parse(_tempCtrl.text.trim());
    final humidity     = double.parse(_humidityCtrl.text.trim());
    final allVarieties = ref.read(coffeeVarietiesProvider).value ?? const [];
    final matching     = allVarieties.where((v) => v.id == _varietyId);
    final variety      = matching.isNotEmpty ? matching.first : null;
    final varietyName  = variety?.name          ?? _varietyId;
    final sensitivity  = variety?.sensitivity   ?? 'medium';
    final scaPotential = variety?.scaPotential  ?? 84.0;

    final userId   = ref.read(currentUserIdProvider);
    final roleStr  = ref.read(currentUserProvider)?.role ?? 'producer';
    final userRole = roleFromString(roleStr);

    final lotId = const Uuid().v4();
    setState(() => _createdLotId = lotId);

    final lot = Lot(
      id:                  lotId,
      userId:              userId,
      varietyId:           _varietyId,
      varietyName:         varietyName,
      altitudeMasl:        altitude,
      region:              _regionCtrl.text.trim(),
      processType:         _processType,
      ambientTempC:        temp,
      ambientHumidityPct:  humidity,
      rainProbabilityPct:  _rainPct,
      createdAt:           DateTime.now(),
    );

    final aiContext = AIContext(
      userId:              userId,
      userRole:            userRole,
      module:              'process_selection',
      lotId:               lot.id,
      varietyId:           _varietyId,
      altitudeMasl:        altitude,
      region:              _regionCtrl.text.trim(),
      ambientTempC:        temp,
      ambientHumidityPct:  humidity,
      rainProbabilityPct:  _rainPct,
      processType:         _processType,
      varietySensitivity:  sensitivity,
      varietyScaPotential: scaPotential,
      userLotsCompleted:   ref.read(userLotsProvider).asData?.value.length ?? 0,
    );

    await ref
        .read(lotCreateProvider.notifier)
        .createLot(lot: lot, aiContext: aiContext);
  }

  void _scrollToRecs() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _recsKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx,
            duration: const Duration(milliseconds: 480), curve: Curves.easeOut);
      }
    });
  }

  InputDecoration _inputDecor(String label) => InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.labelMedium,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.aiBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );
}

// ── Reusable section container ────────────────────────────────────────────

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.title,
    required this.icon,
    required this.children,
    this.subtitle,
  });

  final String title;
  final IconData icon;
  final String? subtitle;
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

// ── AI Recommendations section ─────────────────────────────────────────────

class _RecommendationsSection extends StatelessWidget {
  const _RecommendationsSection({
    super.key,
    required this.recommendations,
    required this.lotId,
  });

  final List<Recommendation> recommendations;
  final String? lotId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.aiBlue,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Recomendaciones IA',
              style: AppTextStyles.displaySmall.copyWith(fontSize: 20),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.aiBlueContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${recommendations.length}',
                style: AppTextStyles.aiCaption
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ]),
          const SizedBox(height: 4),
          Text(
            'Basadas en variedad, altitud y condiciones ambientales.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 14),
          ...recommendations.indexed.map(
            (entry) => RecommendationCard(
              recommendation: entry.$2,
              isTopCard: entry.$1 == 0,
            ),
          ),
          if (lotId != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.go(
                  AppRoutes.lotDetail.replaceFirst(':id', lotId!),
                ),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('Ver detalle del lote'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
