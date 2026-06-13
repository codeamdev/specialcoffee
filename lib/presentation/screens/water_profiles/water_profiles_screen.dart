import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:special_coffee/core/theme/app_colors.dart';
import 'package:special_coffee/core/theme/app_text_styles.dart';
import 'package:special_coffee/domain/entities/water_profile.dart';
import 'package:special_coffee/presentation/providers/water_profile_provider.dart';

class WaterProfilesScreen extends ConsumerWidget {
  const WaterProfilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(waterProfilesProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Perfiles de agua')),
      body: profilesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Error: $e')),
        data:    (profiles) => profiles.isEmpty
            ? _EmptyState(onAdd: () => _showForm(context, ref))
            : _ProfileList(profiles: profiles, onAdd: () => _showForm(context, ref)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, ref),
        backgroundColor: AppColors.aiBlue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showForm(BuildContext context, WidgetRef ref, [WaterProfile? existing]) {
    ref.read(waterProfileProvider.notifier);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WaterProfileForm(existing: existing),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.water_drop_outlined,
                  size: 64, color: AppColors.outline),
              const SizedBox(height: 16),
              Text('Sin perfiles de agua',
                  style: AppTextStyles.displaySmall,
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                'Registra los parámetros del agua que usas para preparar café '
                '(TDS, pH, dureza) según los estándares SCA.',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Agregar perfil'),
                style: FilledButton.styleFrom(backgroundColor: AppColors.aiBlue),
              ),
            ],
          ),
        ),
      );
}

// ── Profile list ─────────────────────────────────────────────────────────────

class _ProfileList extends StatelessWidget {
  const _ProfileList({required this.profiles, required this.onAdd});

  final List<WaterProfile> profiles;
  final VoidCallback       onAdd;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Text('${profiles.length} perfil${profiles.length != 1 ? 'es' : ''}',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.onSurfaceVariant)),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              itemCount: profiles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) => _ProfileCard(profile: profiles[i]),
            ),
          ),
        ],
      );
}

// ── Profile card ──────────────────────────────────────────────────────────────

class _ProfileCard extends ConsumerWidget {
  const _ProfileCard({required this.profile});

  final WaterProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compliant = profile.isScaCompliant;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: compliant
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(profile.name, style: AppTextStyles.labelLarge),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (compliant ? AppColors.success : AppColors.warning)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                compliant ? 'SCA OK' : 'Fuera de rango',
                style: AppTextStyles.labelSmall.copyWith(
                  color: compliant ? AppColors.success : AppColors.warning,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _Param('TDS', '${profile.tdsPpm.toStringAsFixed(0)} ppm',
                profile.isTdsOk),
            const SizedBox(width: 16),
            _Param('pH', profile.phLevel.toStringAsFixed(1),
                profile.isPhOk),
            const SizedBox(width: 16),
            _Param('Dureza', '${profile.hardnessPpm.toStringAsFixed(0)} mg/L',
                profile.isHardnessOk),
          ]),
          if (profile.notes != null && profile.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(profile.notes!,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.onSurfaceVariant)),
          ],
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(
              onPressed: () => _showEditForm(context, ref),
              child: const Text('Editar'),
            ),
          ]),
        ],
      ),
    );
  }

  void _showEditForm(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WaterProfileForm(existing: profile),
    );
  }
}

class _Param extends StatelessWidget {
  const _Param(this.label, this.value, this.ok);

  final String label;
  final String value;
  final bool   ok;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: ok ? AppColors.onSurface : AppColors.warning,
            ),
          ),
        ],
      );
}

// ── Form ──────────────────────────────────────────────────────────────────────

class _WaterProfileForm extends ConsumerStatefulWidget {
  const _WaterProfileForm({this.existing});

  final WaterProfile? existing;

  @override
  ConsumerState<_WaterProfileForm> createState() => _WaterProfileFormState();
}

class _WaterProfileFormState extends ConsumerState<_WaterProfileForm> {
  final _formKey    = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _tdsCtrl    = TextEditingController();
  final _phCtrl     = TextEditingController();
  final _hardnessCtrl = TextEditingController();
  final _notesCtrl  = TextEditingController();

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text     = e.name;
      _tdsCtrl.text      = e.tdsPpm.toStringAsFixed(0);
      _phCtrl.text       = e.phLevel.toStringAsFixed(1);
      _hardnessCtrl.text = e.hardnessPpm.toStringAsFixed(0);
      _notesCtrl.text    = e.notes ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _tdsCtrl.dispose();
    _phCtrl.dispose();
    _hardnessCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.watch(waterProfileProvider);

    ref.listen(waterProfileProvider, (_, next) {
      if (next.isSaved) Navigator.of(context).pop();
    });

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 32,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.existing == null ? 'Nuevo perfil de agua' : 'Editar perfil',
                style: AppTextStyles.displaySmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Estándares SCA: TDS 75–250 ppm · pH 6.5–7.5 · Dureza 50–175 mg/L',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              _field('Nombre del perfil', _nameCtrl,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: _field('TDS (ppm)', _tdsCtrl,
                      hint: '75–250',
                      keyboard: TextInputType.number,
                      validator: (v) {
                        final n = double.tryParse(v?.trim() ?? '');
                        if (n == null) return 'Requerido';
                        return null;
                      }),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _field('pH', _phCtrl,
                      hint: '6.5–7.5',
                      keyboard: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        final n = double.tryParse(v?.trim() ?? '');
                        if (n == null) return 'Requerido';
                        if (n < 0 || n > 14) return '0–14';
                        return null;
                      }),
                ),
              ]),
              const SizedBox(height: 12),
              _field('Dureza (mg/L CaCO₃)', _hardnessCtrl,
                  hint: '50–175',
                  keyboard: TextInputType.number,
                  validator: (v) {
                    final n = double.tryParse(v?.trim() ?? '');
                    if (n == null) return 'Requerido';
                    return null;
                  }),
              const SizedBox(height: 12),
              _field('Notas (opcional)', _notesCtrl, maxLines: 2),
              const SizedBox(height: 8),
              if (notifier.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Error: ${notifier.error}',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.error),
                  ),
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: notifier.isLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.aiBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: notifier.isLoading
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Guardar perfil'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final now      = DateTime.now();
    final existing = widget.existing;
    await ref.read(waterProfileProvider.notifier).save(
          WaterProfile(
            id:          existing?.id ?? '',
            ownerId:     existing?.ownerId ?? '',
            name:        _nameCtrl.text.trim(),
            tdsPpm:      double.parse(_tdsCtrl.text.trim()),
            phLevel:     double.parse(_phCtrl.text.trim()),
            hardnessPpm: double.parse(_hardnessCtrl.text.trim()),
            notes:       _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
            createdAt:   existing?.createdAt ?? now,
            updatedAt:   now,
          ),
        );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    String? hint,
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboard,
        validator: validator,
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
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      );
}
