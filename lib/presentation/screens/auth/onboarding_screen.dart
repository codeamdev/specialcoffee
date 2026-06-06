import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:special_coffee/core/constants/app_constants.dart';
import 'package:special_coffee/core/theme/app_colors.dart';
import 'package:special_coffee/core/theme/app_text_styles.dart';
import 'package:special_coffee/core/network/api_client.dart';
import 'package:special_coffee/presentation/providers/auth_provider.dart';

class _Role {
  final String id;
  final String label;
  final String description;
  final IconData icon;
  const _Role(this.id, this.label, this.description, this.icon);
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _roles = [
    _Role('producer',          'Productor',       'Cultivo, proceso y trilla de café',     Icons.grass_outlined),
    _Role('coffee_master',     'Coffee Master',   'Análisis físico, tueste y catación SCA', Icons.science_outlined),
    _Role('brand_manager',     'Brand Manager',   'Inventario, precios y certificaciones', Icons.business_outlined),
    _Role('producer_integral', 'Prod. Integral',  'Control farm-to-cup completo',          Icons.agriculture_outlined),
    _Role('barista',           'Barista',         'Preparación y experiencia en taza',     Icons.local_cafe_outlined),
  ];

  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  String _role     = 'farmer';
  bool _obscure    = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).register(
      email:       _emailCtrl.text.trim(),
      password:    _passCtrl.text,
      displayName: _nameCtrl.text.trim(),
      role:        _role,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    ref.listen(authProvider, (_, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ApiClient.errorMessage(next.error!)),
          backgroundColor: AppColors.error,
        ));
      }
    });

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Crear cuenta'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.login),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Configuración inicial', style: AppTextStyles.displayMedium),
                const SizedBox(height: 4),
                Text(
                  'Cuéntanos sobre tu rol para personalizar la IA.',
                  style: AppTextStyles.bodyLarge.copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 32),

                // Nombre
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Ingresa tu nombre' : null,
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Ingresa tu correo';
                    if (!v.contains('@')) return 'Correo inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Contraseña
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ingresa una contraseña';
                    if (v.length < 6) return 'Mínimo 6 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // Selección de rol
                Text('¿Cuál es tu rol?', style: AppTextStyles.labelLarge),
                const SizedBox(height: 12),
                ...(_roles.map((r) => _RoleTile(
                  role: r,
                  selected: _role == r.id,
                  onTap: () => setState(() => _role = r.id),
                ))),
                const SizedBox(height: 32),

                // Botón registro
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _register,
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Crear cuenta'),
                  ),
                ),
                const SizedBox(height: 16),

                Center(
                  child: TextButton(
                    onPressed: () => context.go(AppRoutes.login),
                    child: Text(
                      '¿Ya tienes cuenta? Iniciar sesión',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.caramel),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  final _Role role;
  final bool selected;
  final VoidCallback onTap;

  const _RoleTile({required this.role, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.parchment : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.caramel : AppColors.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(role.icon,
                color: selected ? AppColors.caramel : AppColors.onSurfaceVariant),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(role.label,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: selected ? AppColors.caramel : AppColors.onSurface,
                      )),
                  Text(role.description,
                      style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.caramel, size: 20),
          ],
        ),
      ),
    );
  }
}
