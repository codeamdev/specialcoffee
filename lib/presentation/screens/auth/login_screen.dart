import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:special_coffee/core/constants/app_constants.dart';
import 'package:special_coffee/core/theme/app_colors.dart';
import 'package:special_coffee/core/theme/app_text_styles.dart';
import 'package:special_coffee/core/network/api_client.dart';
import 'package:special_coffee/presentation/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  bool _obscure     = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).login(
      email:    _emailCtrl.text.trim(),
      password: _passCtrl.text,
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
      backgroundColor: AppColors.espresso,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),
                const Icon(Icons.coffee, size: 48, color: AppColors.caramel),
                const SizedBox(height: 16),
                Text(
                  AppConstants.appName,
                  style: AppTextStyles.displayLarge.copyWith(color: AppColors.cream),
                ),
                Text(
                  'Tu Q Grader digital',
                  style: AppTextStyles.bodyLarge.copyWith(color: AppColors.outline),
                ),
                const SizedBox(height: 48),

                // Email
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppColors.cream),
                  decoration: _inputDecor('Correo electrónico', Icons.email_outlined),
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
                  style: const TextStyle(color: AppColors.cream),
                  decoration: _inputDecor(
                    'Contraseña',
                    Icons.lock_outline,
                    suffix: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.outline,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                    if (v.length < 6) return 'Mínimo 6 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Botón login
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _login,
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Iniciar sesión'),
                  ),
                ),
                const SizedBox(height: 16),

                // Ir a registro
                Center(
                  child: TextButton(
                    onPressed: () => context.go(AppRoutes.onboarding),
                    child: Text(
                      '¿No tienes cuenta? Crear cuenta',
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

  InputDecoration _inputDecor(String label, IconData icon, {Widget? suffix}) =>
      InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.outline),
        prefixIcon: Icon(icon, color: AppColors.outline),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.espressoLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.caramel, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        errorStyle: const TextStyle(color: AppColors.error),
      );
}
