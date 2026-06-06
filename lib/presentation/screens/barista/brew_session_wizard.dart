import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:special_coffee/core/constants/app_constants.dart';
import 'package:special_coffee/core/theme/app_colors.dart';
import 'package:special_coffee/core/theme/app_text_styles.dart';
import 'package:special_coffee/domain/entities/coffee_reference.dart';
import 'package:special_coffee/domain/entities/water_profile.dart';
import 'package:special_coffee/presentation/providers/coffee_reference_provider.dart';
import 'package:special_coffee/presentation/providers/water_profile_provider.dart';

class BrewSessionWizard extends ConsumerStatefulWidget {
  const BrewSessionWizard({super.key});

  @override
  ConsumerState<BrewSessionWizard> createState() => _BrewSessionWizardState();
}

class _BrewSessionWizardState extends ConsumerState<BrewSessionWizard> {
  int               _step           = 0;
  CoffeeReference?  _selectedRef;
  WaterProfile?     _selectedProfile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Nueva preparación'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stepper(
        currentStep: _step,
        onStepContinue: _onContinue,
        onStepCancel:   _onCancel,
        controlsBuilder: _controls,
        steps: [
          _buildCoffeeStep(),
          _buildWaterStep(),
          _buildStartStep(),
        ],
      ),
    );
  }

  Step _buildCoffeeStep() {
    final refsAsync = ref.watch(coffeeReferencesProvider);

    return Step(
      title: const Text('Café'),
      subtitle: _selectedRef != null
          ? Text(_selectedRef!.name, style: AppTextStyles.bodySmall)
          : null,
      isActive: _step >= 0,
      state: _selectedRef != null && _step > 0
          ? StepState.complete
          : StepState.indexed,
      content: refsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Text('Error: $e'),
        data: (refs) => refs.isEmpty
            ? _NoItemsHint(message: 'Sin cafés. Agrega uno desde el inicio barista.')
            : Column(
                children: refs
                    .map((r) => _SelectTile<CoffeeReference>(
                          title:      r.name,
                          subtitle:   r.origin,
                          trailing:   _roastLabel(r.roastLevel),
                          selected:   _selectedRef?.id == r.id,
                          onSelected: () => setState(() => _selectedRef = r),
                        ))
                    .toList(),
              ),
      ),
    );
  }

  Step _buildWaterStep() {
    final profilesAsync = ref.watch(waterProfilesProvider);

    return Step(
      title: const Text('Perfil de agua'),
      subtitle: _selectedProfile != null
          ? Text(_selectedProfile!.name, style: AppTextStyles.bodySmall)
          : null,
      isActive: _step >= 1,
      state: _selectedProfile != null && _step > 1
          ? StepState.complete
          : StepState.indexed,
      content: profilesAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Text('Error: $e'),
        data: (profiles) => profiles.isEmpty
            ? _NoItemsHint(message: 'Sin perfiles de agua guardados. Puedes continuar sin uno.')
            : Column(
                children: profiles
                    .map((p) => _SelectTile<WaterProfile>(
                          title:    p.name,
                          subtitle: 'pH ${p.phLevel.toStringAsFixed(1)} · '
                              '${p.hardnessPpm.toStringAsFixed(0)} ppm · '
                              '${p.tdsPpm.toStringAsFixed(0)} TDS',
                          selected:   _selectedProfile?.id == p.id,
                          onSelected: () => setState(() => _selectedProfile = p),
                        ))
                    .toList(),
              ),
      ),
    );
  }

  Step _buildStartStep() {
    return Step(
      title: const Text('Iniciar'),
      isActive: _step >= 2,
      content: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SummaryRow(
              icon:  Icons.coffee,
              label: 'Café',
              value: _selectedRef?.name ?? 'Sin seleccionar',
            ),
            _SummaryRow(
              icon:  Icons.water_drop_outlined,
              label: 'Agua',
              value: _selectedProfile?.name ?? 'Sin seleccionar',
            ),
            if (_selectedRef?.daysSinceRoast != null)
              _SummaryRow(
                icon:  Icons.schedule_outlined,
                label: 'Días desde tueste',
                value: '${_selectedRef!.daysSinceRoast} días',
              ),
          ],
        ),
      ),
    );
  }

  void _onContinue() {
    if (_step < 2) {
      setState(() => _step++);
    } else {
      _startBrew();
    }
  }

  void _onCancel() {
    if (_step > 0) setState(() => _step--);
  }

  void _startBrew() {
    context.go(
      AppRoutes.brew,
      extra: {
        if (_selectedRef != null)     'coffeeReferenceId': _selectedRef!.id,
        if (_selectedProfile != null) 'waterProfileId':    _selectedProfile!.id,
        if (_selectedRef?.roastLevel != null) 'roastLevel': _selectedRef!.roastLevel,
        if (_selectedRef?.daysSinceRoast != null)
          'roastDays': _selectedRef!.daysSinceRoast,
        if (_selectedProfile?.hardnessPpm != null)
          'waterHardnessPpm': _selectedProfile!.hardnessPpm,
      },
    );
  }

  Widget _controls(BuildContext context, ControlsDetails details) {
    final isLast  = _step == 2;
    final canSkip = _step == 1; // water profile is optional

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          FilledButton(
            onPressed: details.onStepContinue,
            style: FilledButton.styleFrom(backgroundColor: AppColors.roleBarista),
            child: Text(isLast ? 'Preparar' : 'Siguiente'),
          ),
          const SizedBox(width: 8),
          if (_step > 0)
            TextButton(
              onPressed: details.onStepCancel,
              child: const Text('Atrás'),
            ),
          if (canSkip) ...[
            const SizedBox(width: 4),
            TextButton(
              onPressed: () => setState(() {
                _selectedProfile = null;
                _step = 2;
              }),
              child: const Text('Omitir'),
            ),
          ],
        ],
      ),
    );
  }

  String _roastLabel(String level) => switch (level) {
    'light'  => 'Claro',
    'medium' => 'Medio',
    'dark'   => 'Oscuro',
    _        => level,
  };
}

// ── Shared small widgets ──────────────────────────────────────────────────────

class _SelectTile<T> extends StatelessWidget {
  const _SelectTile({
    required this.title,
    this.subtitle,
    this.trailing,
    required this.selected,
    required this.onSelected,
  });

  final String    title;
  final String?   subtitle;
  final String?   trailing;
  final bool      selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelected,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color:  selected ? AppColors.roleBarista.withValues(alpha: 0.08) : Colors.white,
          border: Border.all(
            color: selected ? AppColors.roleBarista : AppColors.outlineVariant,
            width: selected ? 1.5 : 1.0,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                  if (subtitle != null)
                    Text(subtitle!, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            if (trailing != null)
              Text(trailing!, style: AppTextStyles.labelSmall),
            if (selected) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle_rounded, color: AppColors.roleBarista, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}

class _NoItemsHint extends StatelessWidget {
  const _NoItemsHint({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        message,
        style: AppTextStyles.bodySmall,
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String   label;
  final String   value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 10),
          Text(label, style: AppTextStyles.bodySmall),
          const Spacer(),
          Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
