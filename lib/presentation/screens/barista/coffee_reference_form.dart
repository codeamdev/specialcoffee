import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:special_coffee/core/theme/app_colors.dart';
import 'package:special_coffee/core/theme/app_text_styles.dart';
import 'package:special_coffee/domain/entities/coffee_reference.dart';
import 'package:special_coffee/presentation/providers/coffee_reference_provider.dart';

class CoffeeReferenceForm extends ConsumerStatefulWidget {
  const CoffeeReferenceForm({super.key, this.existing, this.onSaved});

  final CoffeeReference?                existing;
  final void Function(CoffeeReference)? onSaved;

  @override
  ConsumerState<CoffeeReferenceForm> createState() =>
      _CoffeeReferenceFormState();
}

class _CoffeeReferenceFormState extends ConsumerState<CoffeeReferenceForm> {
  final _formKey      = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _origin;
  late final TextEditingController _farmer;
  late final TextEditingController _grindNotes;
  late final TextEditingController _tasteNotes;

  static const _roastLevels = [
    ('light',  'Claro'),
    ('medium', 'Medio'),
    ('dark',   'Oscuro'),
  ];

  String    _roastLevel   = 'medium';
  DateTime? _roastDate;
  DateTime? _packagedDate;

  @override
  void initState() {
    super.initState();
    final e      = widget.existing;
    _name        = TextEditingController(text: e?.name ?? '');
    _origin      = TextEditingController(text: e?.origin ?? '');
    _farmer      = TextEditingController(text: e?.farmer ?? '');
    _grindNotes  = TextEditingController(text: e?.grindNotes ?? '');
    _tasteNotes  = TextEditingController(text: e?.tasteNotes ?? '');
    _roastLevel  = e?.roastLevel ?? 'medium';
    _roastDate   = e?.roastDate;
    _packagedDate = e?.packagedDate;
  }

  @override
  void dispose() {
    _name.dispose();
    _origin.dispose();
    _farmer.dispose();
    _grindNotes.dispose();
    _tasteNotes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.watch(coffeeReferenceProvider);

    ref.listen(coffeeReferenceProvider, (_, next) {
      if (next.isSaved) {
        if (next.saved != null) widget.onSaved?.call(next.saved!);
        Navigator.of(context).pop();
      }
    });

    return Container(
      decoration: const BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left:   20,
        right:  20,
        top:    16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 32,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize:       MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color:        AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                widget.existing == null ? 'Nuevo café' : 'Editar café',
                style: AppTextStyles.displaySmall.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 4),
              const Text(
                'Datos del café que vas a preparar.',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 20),

              // Nombre
              _Field(
                controller: _name,
                label:      'Nombre del café *',
                icon:       Icons.local_cafe_outlined,
                validator:  (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),

              // Finca / Origen
              _Field(
                controller: _origin,
                label:      'Finca / Origen',
                icon:       Icons.landscape_outlined,
              ),
              const SizedBox(height: 12),

              // Caficultor
              _Field(
                controller: _farmer,
                label:      'Caficultor',
                icon:       Icons.person_outline,
              ),
              const SizedBox(height: 16),

              // Nivel de tueste — chips
              Text(
                'Nivel de tueste',
                style: AppTextStyles.labelMedium
                    .copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Row(
                children: _roastLevels.map((r) {
                  final selected = _roastLevel == r.$1;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _roastLevel = r.$1),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding:
                              const EdgeInsets.symmetric(vertical: 10),
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
                          child: Center(
                            child: Text(
                              r.$2,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: selected
                                    ? AppColors.caramel
                                    : AppColors.onSurface,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Fecha de tostión
              _DateButton(
                label:     'Fecha de tostión',
                value:     _roastDate,
                onChanged: (d) => setState(() => _roastDate = d),
              ),
              const SizedBox(height: 12),

              // Fecha de empaque
              _DateButton(
                label:     'Fecha de empaque',
                value:     _packagedDate,
                onChanged: (d) => setState(() => _packagedDate = d),
              ),
              const SizedBox(height: 16),

              // Notas de molienda
              _Field(
                controller: _grindNotes,
                label:      'Notas de molienda',
                icon:       Icons.settings_outlined,
                hint:       'Ej: 18 en Comandante, 20 clicks Timemore',
                maxLines:   2,
              ),
              const SizedBox(height: 12),

              // Notas de sabor
              _Field(
                controller: _tasteNotes,
                label:      'Notas de sabor',
                icon:       Icons.spa_outlined,
                hint:       'Ej: frambuesa, caramelo, larga acidez',
                maxLines:   2,
              ),
              const SizedBox(height: 24),

              // Error
              if (notifier.error != null) ...[
                Text(
                  'Error al guardar: ${notifier.error}',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.error),
                ),
                const SizedBox(height: 10),
              ],

              // Guardar
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: notifier.isLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.caramel,
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: notifier.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'Guardar referencia',
                          style: AppTextStyles.buttonMedium
                              .copyWith(color: Colors.white),
                        ),
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
    await ref.read(coffeeReferenceProvider.notifier).save(
          CoffeeReference(
            id:           existing?.id ?? '',
            ownerId:      existing?.ownerId ?? '',
            name:         _name.text.trim(),
            origin:       _origin.text.trim().isEmpty ? null : _origin.text.trim(),
            farmer:       _farmer.text.trim().isEmpty ? null : _farmer.text.trim(),
            roastLevel:   _roastLevel,
            roastDate:    _roastDate,
            packagedDate: _packagedDate,
            grindNotes:   _grindNotes.text.trim().isEmpty ? null : _grindNotes.text.trim(),
            tasteNotes:   _tasteNotes.text.trim().isEmpty ? null : _tasteNotes.text.trim(),
            createdAt:    existing?.createdAt ?? now,
            updatedAt:    now,
          ),
        );
  }
}

// ── Input field ──────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.maxLines = 1,
    this.validator,
  });

  final TextEditingController         controller;
  final String                        label;
  final IconData                      icon;
  final String?                       hint;
  final int                           maxLines;
  final String? Function(String?)?    validator;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: AppColors.outlineVariant),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: TextFormField(
        controller:  controller,
        maxLines:    maxLines,
        validator:   validator,
        decoration:  InputDecoration(
          labelText:    label,
          hintText:     hint,
          icon:         Icon(icon, size: 18, color: AppColors.caramel),
          border:       InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        style: AppTextStyles.bodyMedium,
      ),
    );
  }
}

// ── Date button ──────────────────────────────────────────────────────────────

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String    label;
  final DateTime? value;
  final void Function(DateTime?) onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context:     context,
          initialDate: value ?? DateTime.now(),
          firstDate:   DateTime(2020),
          lastDate:    DateTime.now(),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(10),
          border:       Border.all(color: AppColors.outlineVariant),
        ),
        child: Row(children: [
          const Icon(Icons.calendar_today_outlined,
              size: 18, color: AppColors.caramel),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.onSurfaceVariant),
                ),
                Text(
                  value != null
                      ? '${value!.day.toString().padLeft(2, '0')}/'
                        '${value!.month.toString().padLeft(2, '0')}/'
                        '${value!.year}'
                      : 'Sin fecha',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: value != null
                        ? AppColors.onSurface
                        : AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (value != null)
            GestureDetector(
              onTap: () => onChanged(null),
              child: const Icon(Icons.clear,
                  size: 16, color: AppColors.onSurfaceVariant),
            ),
        ]),
      ),
    );
  }
}
