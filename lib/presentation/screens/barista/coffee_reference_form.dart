import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:special_coffee/core/theme/app_colors.dart';
import 'package:special_coffee/core/theme/app_text_styles.dart';
import 'package:special_coffee/domain/entities/coffee_reference.dart';
import 'package:special_coffee/presentation/providers/coffee_reference_provider.dart';

class CoffeeReferenceForm extends ConsumerStatefulWidget {
  const CoffeeReferenceForm({super.key, this.existing});

  final CoffeeReference? existing;

  @override
  ConsumerState<CoffeeReferenceForm> createState() => _CoffeeReferenceFormState();
}

class _CoffeeReferenceFormState extends ConsumerState<CoffeeReferenceForm> {
  final _formKey  = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _origin;
  late final TextEditingController _grindNotes;
  late final TextEditingController _tasteNotes;

  String    _roastLevel = 'medium';
  DateTime? _roastDate;
  DateTime? _packagedDate;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name       = TextEditingController(text: e?.name ?? '');
    _origin     = TextEditingController(text: e?.origin ?? '');
    _grindNotes = TextEditingController(text: e?.grindNotes ?? '');
    _tasteNotes = TextEditingController(text: e?.tasteNotes ?? '');
    _roastLevel  = e?.roastLevel ?? 'medium';
    _roastDate   = e?.roastDate;
    _packagedDate = e?.packagedDate;
  }

  @override
  void dispose() {
    _name.dispose();
    _origin.dispose();
    _grindNotes.dispose();
    _tasteNotes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.watch(coffeeReferenceProvider);

    ref.listen(coffeeReferenceProvider, (_, next) {
      if (next.isSaved) Navigator.of(context).pop();
    });

    return Container(
      decoration: const BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left:   20,
        right:  20,
        top:    20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color:        AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Text(
                widget.existing == null ? 'Nuevo café' : 'Editar café',
                style: AppTextStyles.displaySmall,
              ),
              const SizedBox(height: 20),

              // Name
              TextFormField(
                controller:  _name,
                decoration:  const InputDecoration(labelText: 'Nombre *'),
                validator:   (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),

              // Origin
              TextFormField(
                controller:  _origin,
                decoration:  const InputDecoration(labelText: 'Origen / finca'),
              ),
              const SizedBox(height: 12),

              // Roast level
              DropdownButtonFormField<String>(
                value:       _roastLevel,
                decoration:  const InputDecoration(labelText: 'Tueste'),
                items: const [
                  DropdownMenuItem(value: 'light',  child: Text('Claro')),
                  DropdownMenuItem(value: 'medium', child: Text('Medio')),
                  DropdownMenuItem(value: 'dark',   child: Text('Oscuro')),
                ],
                onChanged: (v) => setState(() => _roastLevel = v ?? 'medium'),
              ),
              const SizedBox(height: 12),

              // Roast date
              _DateField(
                label:       'Fecha de tueste',
                value:       _roastDate,
                onChanged:   (d) => setState(() => _roastDate = d),
              ),
              const SizedBox(height: 12),

              // Packaged date
              _DateField(
                label:       'Fecha de empaque',
                value:       _packagedDate,
                onChanged:   (d) => setState(() => _packagedDate = d),
              ),
              const SizedBox(height: 12),

              // Grind notes
              TextFormField(
                controller:  _grindNotes,
                decoration:  const InputDecoration(
                  labelText: 'Notas de molienda',
                  hintText:  'Ej: 18 en Comandante, 20 clicks Timemore',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),

              // Taste notes
              TextFormField(
                controller:  _tasteNotes,
                decoration:  const InputDecoration(
                  labelText: 'Notas de sabor',
                  hintText:  'Ej: frambuesa, caramelo, larga acidez',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: notifier.isLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.roleBarista,
                    padding:         const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: notifier.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Guardar', style: AppTextStyles.buttonLarge),
                ),
              ),

              if (notifier.error != null) ...[
                const SizedBox(height: 10),
                Text(
                  'Error al guardar: ${notifier.error}',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now();
    final existing = widget.existing;
    await ref.read(coffeeReferenceProvider.notifier).save(
          CoffeeReference(
            id:           existing?.id ?? '',
            ownerId:      existing?.ownerId ?? '',
            name:         _name.text.trim(),
            origin:       _origin.text.trim().isEmpty ? null : _origin.text.trim(),
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

// ── Date picker field ────────────────────────────────────────────────────────

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String    label;
  final DateTime? value;
  final void Function(DateTime?) onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context:      context,
          initialDate:  value ?? DateTime.now(),
          firstDate:    DateTime(2020),
          lastDate:     DateTime.now(),
        );
        onChanged(picked);
      },
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: value != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => onChanged(null),
                )
              : const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(
          value != null
              ? '${value!.day.toString().padLeft(2, '0')}/'
                '${value!.month.toString().padLeft(2, '0')}/'
                '${value!.year}'
              : 'Sin fecha',
          style: value != null
              ? AppTextStyles.bodyMedium
              : AppTextStyles.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
        ),
      ),
    );
  }
}
