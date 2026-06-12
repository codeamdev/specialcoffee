import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:special_coffee/ai_engine/models/ai_context.dart';
import 'package:special_coffee/core/constants/app_constants.dart';
import 'package:special_coffee/ai_engine/models/ai_rule.dart';
import 'package:special_coffee/ai_engine/models/brew_recipe.dart';
import 'package:special_coffee/core/theme/app_colors.dart';
import 'package:special_coffee/core/theme/app_text_styles.dart';
import 'package:special_coffee/domain/entities/coffee_reference.dart';
import 'package:special_coffee/presentation/providers/auth_provider.dart';
import 'package:special_coffee/presentation/providers/brew_provider.dart';
import 'package:special_coffee/presentation/providers/brewing_history_provider.dart';
import 'package:special_coffee/presentation/providers/coffee_reference_provider.dart';
import 'package:special_coffee/presentation/screens/barista/coffee_reference_form.dart';
import 'package:special_coffee/presentation/widgets/ai/recommendation_card.dart';

// ── Method data (screen-private) ──────────────────────────────────────────

class _Method {
  final String id;
  final String name;
  final String tagline;
  final String baseRatio;
  final IconData icon;

  const _Method(
      this.id, this.name, this.tagline, this.baseRatio, this.icon);
}

// ── Screen ─────────────────────────────────────────────────────────────────

class BrewScreen extends ConsumerStatefulWidget {
  const BrewScreen({super.key, this.initialReference});

  final CoffeeReference? initialReference;

  @override
  ConsumerState<BrewScreen> createState() => _BrewScreenState();
}

class _BrewScreenState extends ConsumerState<BrewScreen> {
  // ── Static data ───────────────────────────────────────────────────────────

  static const _methods = [
    _Method('v60',          'V60',          'Limpio y delicado',     '1 : 15.5', Icons.filter_alt_outlined),
    _Method('chemex',       'Chemex',       'Sedoso y suave',        '1 : 16.5', Icons.science_outlined),
    _Method('aeropress',    'Aeropress',    'Versátil y con cuerpo', '1 : 13',   Icons.compress),
    _Method('french_press', 'French Press', 'Denso y con textura',   '1 : 15',   Icons.free_breakfast_outlined),
    _Method('espresso',     'Espresso',     'Concentrado e intenso', '1 : 2',    Icons.local_cafe_outlined),
    _Method('moka',         'Moka',         'Fuerte y aromático',    '1 : 7.5',  Icons.whatshot_outlined),
    _Method('cold_brew',    'Cold Brew',    'Frío e intenso',        '1 : 8',    Icons.ac_unit_outlined),
  ];

  static const _roastLevels = [
    ('light',  'Claro'),
    ('medium', 'Medio'),
    ('dark',   'Oscuro'),
  ];

  static const _processes = [
    (null,              'N/A'),
    ('lavado',          'Lavado'),
    ('natural',         'Natural'),
    ('anaerobic_lactic','Anaeróbico'),
    ('honey_yellow',    'Honey'),
  ];

  // ── Form state ────────────────────────────────────────────────────────────

  String  _method     = 'v60';
  String  _roastLevel = 'medium';
  String? _processType;      // null = N/A
  double  _taste      = 0.5; // 0.0 = acidity preference, 1.0 = sweetness

  final _formKey        = GlobalKey<FormState>();
  final _diagFormKey    = GlobalKey<FormState>();
  final _scrollCtrl     = ScrollController();
  final _roastDaysCtrl  = TextEditingController(text: '14');
  final _altitudeCtrl   = TextEditingController(text: '1800');
  final _hardnessCtrl   = TextEditingController();
  final _tdsMinCtrl     = TextEditingController(text: '1.30');
  final _tdsMaxCtrl     = TextEditingController(text: '1.38');
  final _tdsResultCtrl  = TextEditingController();
  final _yieldResultCtrl= TextEditingController();

  bool _tdsPrefilledFromHistory = false;
  bool _recipeAdjOpen = true;

  // Coffee reference (optional, linked after saving via CoffeeReferenceForm)
  CoffeeReference? _coffeeRef;

  @override
  void initState() {
    super.initState();
    final ref = widget.initialReference;
    if (ref != null) _applyReference(ref);
  }

  void _applyReference(CoffeeReference ref) {
    _coffeeRef   = ref;
    _roastLevel  = ref.roastLevel;
    if (ref.processType != null) _processType = ref.processType;
    if (ref.roastDate != null) {
      _roastDaysCtrl.text =
          DateTime.now().difference(ref.roastDate!).inDays.clamp(1, 365).toString();
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _roastDaysCtrl.dispose();
    _altitudeCtrl.dispose();
    _hardnessCtrl.dispose();
    _tdsMinCtrl.dispose();
    _tdsMaxCtrl.dispose();
    _tdsResultCtrl.dispose();
    _yieldResultCtrl.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state  = ref.watch(brewProvider);
    final userId = ref.read(currentUserIdProvider);

    // Pre-populate TDS controllers from session history when ≥5 sessions exist.
    // Only runs once — user edits after that are not overwritten.
    ref.listen<AsyncValue<BrewingTdsPrefs>>(brewingTdsPrefsProvider(userId), (_, next) {
      if (_tdsPrefilledFromHistory) return;
      final prefs = next.value;
      if (prefs != null && prefs.hasEnoughData) {
        _tdsMinCtrl.text = prefs.tdsMin.toStringAsFixed(2);
        _tdsMaxCtrl.text = prefs.tdsMax.toStringAsFixed(2);
        _tdsPrefilledFromHistory = true;
      }
    });

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Preparación'),
        actions: [
          if (state.hasRecipe)
            IconButton(
              icon: const Icon(Icons.refresh_outlined),
              tooltip: 'Nueva receta',
              onPressed: () =>
                  ref.read(brewProvider.notifier).reset(),
            ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 56),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Method selector ──────────────────────────────────────
            _Label('Método', Icons.local_cafe_outlined),
            const SizedBox(height: 10),
            _buildMethodCards(),
            const SizedBox(height: 18),

            // ── Parameters form ──────────────────────────────────────
            _Label('Parámetros', Icons.tune_outlined),
            const SizedBox(height: 10),
            _buildParamsCard(),
            const SizedBox(height: 20),

            // ── Generate button ──────────────────────────────────────
            _buildGenerateButton(state),

            // ── Recipe output ────────────────────────────────────────
            AnimatedSize(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              child: state.hasRecipe
                  ? _RecipeCard(
                      recipe: state.recipe!,
                      recs: state.recipeRecs,
                      adjustmentsOpen: _recipeAdjOpen,
                      onToggleAdjustments: () =>
                          setState(() => _recipeAdjOpen = !_recipeAdjOpen),
                    )
                  : const SizedBox.shrink(),
            ),

            // ── Diagnosis ────────────────────────────────────────────
            AnimatedSize(
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOut,
              child: state.hasRecipe
                  ? _DiagnosisSection(
                      tdsCtrl: _tdsResultCtrl,
                      yieldCtrl: _yieldResultCtrl,
                      formKey: _diagFormKey,
                      recs: state.diagnosisRecs,
                      isLoading: state.isDiagnosing,
                      onDiagnose: _diagnose,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Method cards ──────────────────────────────────────────────────────────

  Widget _buildMethodCards() {
    return SizedBox(
      height: 155,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _methods.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final m       = _methods[i];
          final selected = _method == m.id;
          return GestureDetector(
            onTap: () => setState(() => _method = m.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: 114,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              decoration: BoxDecoration(
                color: selected ? AppColors.aiBlueContainer : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected
                      ? AppColors.aiBlue
                      : AppColors.outlineVariant,
                  width: selected ? 2.0 : 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(m.icon,
                      size: 22,
                      color: selected
                          ? AppColors.aiBlue
                          : AppColors.caramel),
                  const Spacer(),
                  Text(
                    m.name,
                    style: AppTextStyles.labelLarge.copyWith(
                        color: selected
                            ? AppColors.aiBlue
                            : AppColors.onSurface),
                  ),
                  const SizedBox(height: 3),
                  Text(m.tagline,
                      style: AppTextStyles.labelSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 5),
                  Text(
                    m.baseRatio,
                    style: AppTextStyles.numericSmall.copyWith(
                        color: selected
                            ? AppColors.aiBlue
                            : AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Parameters card ───────────────────────────────────────────────────────

  Widget _buildParamsCard() {
    final hasRef = _coffeeRef != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Referencia de café ────────────────────────────────────
            Row(
              children: [
                _Sub('Café', Icons.eco_outlined),
                const Spacer(),
                // Picker — seleccionar de lista guardada
                IconButton(
                  onPressed: _showReferencePicker,
                  icon: const Icon(Icons.coffee_outlined, size: 18),
                  tooltip: 'Mis cafés guardados',
                  color: AppColors.caramel,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 6),
                // Crear / editar referencia
                GestureDetector(
                  onTap: _showCoffeeRefModal,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: hasRef ? AppColors.caramel.withValues(alpha: 0.1) : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: hasRef ? AppColors.caramel : AppColors.outlineVariant,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasRef ? Icons.check_circle_outline : Icons.add_circle_outline,
                          size: 13,
                          color: hasRef ? AppColors.caramel : AppColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          hasRef ? _coffeeRef!.name : 'Nuevo café',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: hasRef ? AppColors.caramel : AppColors.onSurfaceVariant,
                            fontWeight: hasRef ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tueste',
                          style: AppTextStyles.labelMedium),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: _roastLevels.map((r) {
                          final sel = _roastLevel == r.$1;
                          return GestureDetector(
                            onTap: hasRef ? null : () => setState(() => _roastLevel = r.$1),
                            child: ChoiceChip(
                              label: Text(r.$2),
                              selected: sel,
                              selectedColor: AppColors.aiBlueContainer,
                              labelStyle: AppTextStyles.labelSmall.copyWith(
                                color: sel ? AppColors.aiBlue : AppColors.onSurfaceVariant,
                                fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                              ),
                              onSelected: hasRef ? null : (_) => setState(() => _roastLevel = r.$1),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 88,
                  child: TextFormField(
                    controller: _roastDaysCtrl,
                    readOnly: hasRef,
                    decoration: _inp('Días tueste'),
                    keyboardType: TextInputType.number,
                    style: AppTextStyles.numericSmall
                        .copyWith(color: AppColors.onSurface),
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n < 1 || n > 365) return '1–365';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text('Proceso', style: AppTextStyles.labelMedium),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: _processes.map((p) {
                final sel = _processType == p.$1;
                return GestureDetector(
                  onTap: hasRef ? null : () => setState(() => _processType = sel ? null : p.$1),
                  child: ChoiceChip(
                    label: Text(p.$2),
                    selected: sel,
                    selectedColor: AppColors.aiBlueContainer,
                    labelStyle: AppTextStyles.labelSmall.copyWith(
                      color: sel ? AppColors.aiBlue : AppColors.onSurfaceVariant,
                      fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                    ),
                    onSelected: hasRef ? null : (_) => setState(() => _processType = sel ? null : p.$1),
                  ),
                );
              }).toList(),
            ),

            const Divider(height: 24, color: AppColors.divider),

            // ── Entorno ───────────────────────────────────────────────
            _Sub('Entorno', Icons.landscape_outlined),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _altitudeCtrl,
                    decoration: _inp('Altitud (msnm)'),
                    keyboardType: TextInputType.number,
                    style: AppTextStyles.numericSmall
                        .copyWith(color: AppColors.onSurface),
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n < 0 || n > 3500) return '0–3500';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _hardnessCtrl,
                    decoration: _inp('Dureza agua (ppm)')
                        .copyWith(hintText: 'Opcional'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: AppTextStyles.numericSmall
                        .copyWith(color: AppColors.onSurface),
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      final n = double.tryParse(v);
                      if (n == null || n < 0 || n > 500) return '0–500';
                      return null;
                    },
                  ),
                ),
              ],
            ),

            const Divider(height: 24, color: AppColors.divider),

            // ── Preferencias ──────────────────────────────────────────
            _Sub('Preferencias', Icons.person_outline_rounded),
            const SizedBox(height: 10),
            _TasteSlider(
                value: _taste,
                onChanged: (v) => setState(() => _taste = v)),
            const SizedBox(height: 14),
            Row(children: [
              Text('TDS objetivo:',
                  style: AppTextStyles.labelMedium),
              const SizedBox(width: 10),
              SizedBox(
                width: 78,
                child: TextFormField(
                  controller: _tdsMinCtrl,
                  decoration: _inp('Mín %'),
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  style: AppTextStyles.numericSmall
                      .copyWith(color: AppColors.onSurface),
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    if (n == null || n < 0.5 || n > 2.5) return '0.5–2.5';
                    return null;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text('–', style: AppTextStyles.labelLarge),
              ),
              SizedBox(
                width: 78,
                child: TextFormField(
                  controller: _tdsMaxCtrl,
                  decoration: _inp('Máx %'),
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  style: AppTextStyles.numericSmall
                      .copyWith(color: AppColors.onSurface),
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    if (n == null || n < 0.5 || n > 2.5) return '0.5–2.5';
                    return null;
                  },
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  // ── Generate button ───────────────────────────────────────────────────────

  Widget _buildGenerateButton(BrewState state) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: state.isGenerating ? null : _generate,
        icon: state.isGenerating
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.auto_awesome_rounded, size: 18),
        label: Text(
          state.isGenerating ? 'Generando...' : 'Generar receta IA',
          style: AppTextStyles.buttonLarge,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.aiBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.aiBlue.withValues(alpha: 0.6),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // ── Logic ─────────────────────────────────────────────────────────────────

  Future<void> _generate() async {
    if (!_formKey.currentState!.validate()) return;

    final userId  = ref.read(currentUserIdProvider);
    final roleStr = ref.read(currentUserProvider)?.role ?? 'producer';
    final region  = ref.read(currentUserProvider)?.region ?? '';
    final userRole = roleFromString(roleStr);

    final ctx = AIContext(
      userId:              userId,
      userRole:            userRole,
      module:              'brewing',
      varietyId:           'unknown',
      altitudeMasl:        int.parse(_altitudeCtrl.text.trim()),
      region:              region,
      ambientTempC:        18.0,
      ambientHumidityPct:  65.0,
      processType:         _processType,
      brewMethod:          _method,
      roastLevel:          _roastLevel,
      roastDays:           int.parse(_roastDaysCtrl.text.trim()),
      waterHardnessPpm:    double.tryParse(_hardnessCtrl.text.trim()) ?? 0.0,
      userSweetnessWeight: _taste,
      userAcidityWeight:   (1.0 - _taste).clamp(0.0, 1.0),
      userPreferredTdsMin: double.parse(_tdsMinCtrl.text.trim()),
      userPreferredTdsMax: double.parse(_tdsMaxCtrl.text.trim()),
      userLotsCompleted:   0,
    );

    await ref.read(brewProvider.notifier).generateRecipe(ctx);
    _scrollToRecipe();
  }

  void _showReferencePicker() {
    final refs = ref.read(coffeeReferencesProvider).value ?? [];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Mis cafés', style: AppTextStyles.displaySmall.copyWith(fontSize: 18)),
            const SizedBox(height: 4),
            const Text('Selecciona un café para pre-llenar la preparación.',
                style: AppTextStyles.bodySmall),
            const SizedBox(height: 16),
            if (refs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('Aún no tienes cafés guardados.',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.onSurfaceVariant)),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: refs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final r = refs[i];
                    return GestureDetector(
                      onTap: () {
                        Navigator.of(ctx).pop();
                        setState(() => _applyReference(r));
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _coffeeRef?.name == r.name
                              ? AppColors.caramel.withValues(alpha: 0.08)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _coffeeRef?.name == r.name
                                ? AppColors.caramel
                                : AppColors.outlineVariant,
                          ),
                        ),
                        child: Row(children: [
                          const Icon(Icons.coffee, size: 18, color: AppColors.caramel),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.name,
                                    style: AppTextStyles.labelMedium
                                        .copyWith(fontWeight: FontWeight.w600)),
                                if (r.origin != null || r.farmer != null)
                                  Text(
                                    [r.origin, r.farmer]
                                        .whereType<String>()
                                        .join(' · '),
                                    style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.onSurfaceVariant),
                                  ),
                              ],
                            ),
                          ),
                          _RoastBadge(r.roastLevel),
                        ]),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showCoffeeRefModal() {
    // Reset notifier state so isSaved doesn't fire immediately on re-open
    ref.read(coffeeReferenceProvider.notifier).reset();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CoffeeReferenceForm(
        existing: _coffeeRef,
        onSaved: (saved) => setState(() => _coffeeRef = saved),
      ),
    );
  }

  Future<void> _diagnose() async {
    if (!_diagFormKey.currentState!.validate()) return;
    await ref.read(brewProvider.notifier).diagnose(
      tds:    double.parse(_tdsResultCtrl.text.trim()),
      yield_: double.parse(_yieldResultCtrl.text.trim()),
    );
  }

  void _scrollToRecipe() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 480),
          curve: Curves.easeOut,
        );
      }
    });
  }

  InputDecoration _inp(String label) => InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.labelMedium,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppColors.aiBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      );
}

// ── Shared label widgets ──────────────────────────────────────────────────

class _Label extends StatelessWidget {
  const _Label(this.text, this.icon);
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 18, color: AppColors.caramel),
        const SizedBox(width: 8),
        Text(text, style: AppTextStyles.labelLarge),
      ]);
}

class _Sub extends StatelessWidget {
  const _Sub(this.text, this.icon);
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 14, color: AppColors.caramel),
        const SizedBox(width: 6),
        Text(text,
            style: AppTextStyles.labelMedium
                .copyWith(color: AppColors.onSurface)),
      ]);
}

// ── Taste slider ──────────────────────────────────────────────────────────

class _TasteSlider extends StatelessWidget {
  const _TasteSlider({required this.value, required this.onChanged});
  final double value;
  final void Function(double) onChanged;

  @override
  Widget build(BuildContext context) {
    final label = value < 0.3
        ? 'Acidez brillante'
        : value > 0.7
            ? 'Cuerpo y dulzor'
            : 'Equilibrado';

    return Column(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Perfil gustativo', style: AppTextStyles.labelMedium),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.aiBlueContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(label,
                style: AppTextStyles.aiCaption
                    .copyWith(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      Slider(
        value: value,
        min: 0,
        max: 1,
        divisions: 10,
        activeColor: AppColors.aiBlue,
        onChanged: onChanged,
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Acidez', style: AppTextStyles.labelSmall),
          Text('Dulzor', style: AppTextStyles.labelSmall),
        ],
      ),
    ]);
  }
}

// ── Recipe card ────────────────────────────────────────────────────────────

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({
    required this.recipe,
    required this.recs,
    required this.adjustmentsOpen,
    required this.onToggleAdjustments,
  });

  final BrewRecipe           recipe;
  final List<Recommendation> recs;
  final bool                 adjustmentsOpen;
  final VoidCallback         onToggleAdjustments;

  @override
  Widget build(BuildContext context) {
    final r           = recipe;
    final isColdBrew  = r.method == 'cold_brew';
    final hasBloom    = r.bloomSeconds > 0;
    final hasMoka     = r.waterTempC == 0 && !isColdBrew;

    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Section heading ────────────────────────────────────────
        Row(children: [
          Container(
            width: 4,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.aiBlue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text('Receta IA',
              style: AppTextStyles.displaySmall.copyWith(fontSize: 19)),
          const SizedBox(width: 8),
          _Pill(_prettyMethod(r.method)),
        ]),
        const SizedBox(height: 12),

        // ── Main parameters ────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.aiBlue.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: AppColors.aiBlue.withValues(alpha: 0.07),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: [
            // Row 1
            Row(children: [
              _Param('Dosis',  '${r.doseG.toInt()} g',       Icons.monitor_weight),
              _Param('Agua',   '${r.waterG.toInt()} g',      Icons.water_drop_outlined),
              _Param('Ratio',  '1 : ${r.ratio.toStringAsFixed(1)}', Icons.balance),
            ]),
            const SizedBox(height: 14),
            // Row 2
            Row(children: [
              _Param(
                'Temperatura',
                isColdBrew
                    ? '${r.waterTempC.toInt()} °C (frío)'
                    : hasMoka
                        ? 'Fuego directo'
                        : '${r.waterTempC.toInt()} °C',
                Icons.thermostat_outlined,
                color: isColdBrew
                    ? AppColors.aiBlue
                    : hasMoka
                        ? AppColors.disabled
                        : _tempColor(r.waterTempC),
              ),
              _Param(
                isColdBrew ? 'Maceración' : 'Bloom',
                isColdBrew
                    ? '${r.steepHours}h (12–24h)'
                    : hasBloom
                        ? '${r.bloomG.toInt()} g × ${r.bloomSeconds}s'
                        : 'No aplica',
                isColdBrew ? Icons.timelapse_outlined : Icons.hourglass_top_outlined,
                color: (isColdBrew || hasBloom) ? null : AppColors.disabled,
              ),
              _Param(
                'TDS objetivo',
                '${r.tdsTargetMin}–${r.tdsTargetMax} %',
                Icons.analytics_outlined,
                color: AppColors.success,
              ),
            ]),

            // TDS visual range
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: _TdsBar(min: r.tdsTargetMin, max: r.tdsTargetMax),
            ),
          ]),
        ),

        // ── Adjustments accordion ──────────────────────────────────
        if (r.adjustmentsApplied.isNotEmpty) ...[
          const SizedBox(height: 10),
          _AdjAccordion(
            items:    r.adjustmentsApplied,
            open:     adjustmentsOpen,
            onToggle: onToggleAdjustments,
          ),
        ],

        // ── AI recommendations ─────────────────────────────────────
        if (recs.isNotEmpty) ...[
          const SizedBox(height: 18),
          Row(children: [
            Container(
                width: 3, height: 16,
                decoration: BoxDecoration(
                    color: AppColors.aiBlue,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Text('Recomendaciones IA',
                style: AppTextStyles.labelLarge
                    .copyWith(color: AppColors.aiBlue)),
          ]),
          const SizedBox(height: 8),
          ...recs.indexed.map((e) => RecommendationCard(
                recommendation: e.$2,
                isTopCard: e.$1 == 0,
              )),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.push(
              AppRoutes.brewRecipe,
              extra: <String, dynamic>{},
            ),
            icon: const Icon(Icons.save_alt_rounded, size: 18),
            label: const Text('Registrar sesión de preparación'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.caramel,
              side: const BorderSide(color: AppColors.caramel),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ]),
    );
  }

  Color _tempColor(double t) {
    if (t < 85) return AppColors.info;
    if (t < 90) return AppColors.success;
    if (t < 94) return AppColors.warning;
    return AppColors.error;
  }

  String _prettyMethod(String m) => switch (m) {
        'french_press' => 'French Press',
        'aeropress'    => 'Aeropress',
        'cold_brew'    => 'Cold Brew',
        _              => m.toUpperCase(),
      };

}

// ── Parameter cell ────────────────────────────────────────────────────────

class _Param extends StatelessWidget {
  const _Param(this.label, this.value, this.icon, {this.color});
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Icon(icon, size: 18, color: AppColors.caramel),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.numericSmall.copyWith(
              color: color ?? AppColors.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 3),
          Text(label,
              style: AppTextStyles.labelSmall,
              textAlign: TextAlign.center),
        ]),
      );
}

// ── TDS range bar ─────────────────────────────────────────────────────────

class _TdsBar extends StatelessWidget {
  const _TdsBar({required this.min, required this.max});
  final double min;
  final double max;

  static const _lo = 1.0;
  static const _hi = 2.0;

  @override
  Widget build(BuildContext context) {
    final underF = ((min - _lo) / (_hi - _lo)).clamp(0.0, 1.0);
    final rangeF = ((max - min) / (_hi - _lo)).clamp(0.0, 1.0);

    return Column(children: [
      Row(children: [
        Text('${min.toStringAsFixed(2)} %',
            style: AppTextStyles.labelSmall
                .copyWith(color: AppColors.success)),
        const Spacer(),
        Text('${max.toStringAsFixed(2)} %',
            style: AppTextStyles.labelSmall
                .copyWith(color: AppColors.success)),
      ]),
      const SizedBox(height: 4),
      LayoutBuilder(builder: (_, c) {
        final w = c.maxWidth;
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Row(children: [
            Container(
                width: w * underF, height: 8, color: AppColors.outlineVariant),
            Container(
                width: w * rangeF, height: 8, color: AppColors.success),
            Expanded(
                child: Container(height: 8, color: AppColors.outlineVariant)),
          ]),
        );
      }),
      const SizedBox(height: 4),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Sub 1.0 %',
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.onSurfaceVariant)),
          Text('Rango personal',
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.success)),
          Text('Sobre 2.0 %',
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.onSurfaceVariant)),
        ],
      ),
    ]);
  }
}

// ── Adjustments accordion ─────────────────────────────────────────────────

class _AdjAccordion extends StatelessWidget {
  const _AdjAccordion(
      {required this.items, required this.open, required this.onToggle});
  final List<String> items;
  final bool open;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(children: [
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(children: [
              const Icon(Icons.auto_fix_high_outlined,
                  size: 16, color: AppColors.aiBlue),
              const SizedBox(width: 8),
              Text(
                '${items.length} ajuste${items.length > 1 ? "s" : ""} aplicado${items.length > 1 ? "s" : ""}',
                style: AppTextStyles.labelMedium
                    .copyWith(color: AppColors.aiBlue),
              ),
              const Spacer(),
              Icon(open ? Icons.expand_less : Icons.expand_more,
                  size: 18, color: AppColors.aiBlue),
            ]),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 230),
          curve: Curves.easeOut,
          child: open
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                  child: Column(children: [
                    const Divider(height: 12, color: AppColors.divider),
                    ...items.map((a) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.arrow_right_rounded,
                                  size: 16, color: AppColors.aiBlue),
                              const SizedBox(width: 4),
                              Expanded(
                                  child: Text(a,
                                      style: AppTextStyles.bodySmall)),
                            ],
                          ),
                        )),
                  ]),
                )
              : const SizedBox.shrink(),
        ),
      ]),
    );
  }
}

// ── Pill badge ────────────────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  const _Pill(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.aiBlueContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: AppTextStyles.aiCaption
                .copyWith(fontWeight: FontWeight.w700)),
      );
}

// ── Diagnosis section ─────────────────────────────────────────────────────

class _DiagnosisSection extends StatelessWidget {
  const _DiagnosisSection({
    required this.tdsCtrl,
    required this.yieldCtrl,
    required this.formKey,
    required this.recs,
    required this.isLoading,
    required this.onDiagnose,
  });

  final TextEditingController tdsCtrl;
  final TextEditingController yieldCtrl;
  final GlobalKey<FormState> formKey;
  final List<Recommendation> recs;
  final bool isLoading;
  final VoidCallback onDiagnose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 26),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _Label('Diagnóstico post-extracción', Icons.science_outlined),
        const SizedBox(height: 4),
        Text('Mide el TDS y el rendimiento para recibir ajustes precisos.',
            style: AppTextStyles.bodySmall),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Form(
            key: formKey,
            child: Column(children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _DiagField(tdsCtrl,   'TDS medido (%)',     '1.35', lo: 0.5, hi: 3.0)),
                  const SizedBox(width: 10),
                  Expanded(child: _DiagField(yieldCtrl, 'Rendimiento (%)', '20.5',   lo: 5,   hi: 35)),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : onDiagnose,
                  icon: isLoading
                      ? const SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.aiBlue))
                      : const Icon(Icons.auto_awesome_rounded, size: 16),
                  label: Text(
                    isLoading
                        ? 'Analizando...'
                        : 'Diagnosticar extracción',
                    style: AppTextStyles.buttonMedium
                        .copyWith(color: AppColors.aiBlue),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.aiBlue),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              if (recs.isNotEmpty) ...[
                const SizedBox(height: 16),
                ...recs.indexed.map((e) => RecommendationCard(
                      recommendation: e.$2,
                      isTopCard: e.$1 == 0,
                    )),
              ],
            ]),
          ),
        ),
      ]),
    );
  }
}


// ── Diagnosis field ───────────────────────────────────────────────────────

class _DiagField extends StatelessWidget {
  const _DiagField(this.ctrl, this.label, this.hint,
      {required this.lo, required this.hi});
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final double lo;
  final double hi;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
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
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
      style: AppTextStyles.numericSmall
          .copyWith(color: AppColors.onSurface),
      validator: (v) {
        final n = double.tryParse(v ?? '');
        if (n == null || n < lo || n > hi) return '$lo–$hi';
        return null;
      },
    );
  }
}

// ── Roast badge ───────────────────────────────────────────────────────────────

class _RoastBadge extends StatelessWidget {
  const _RoastBadge(this.level);
  final String level;

  @override
  Widget build(BuildContext context) {
    final label = switch (level) {
      'light'  => 'Claro',
      'medium' => 'Medio',
      'dark'   => 'Oscuro',
      _        => level,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.caramel.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: AppTextStyles.labelSmall
              .copyWith(color: AppColors.caramel, fontWeight: FontWeight.w600)),
    );
  }
}
