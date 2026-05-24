import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:special_coffee/core/theme/app_text_styles.dart';

class BrewDiagnosisScreen extends ConsumerWidget {
  const BrewDiagnosisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diagnóstico')),
      body: const Center(
        child: Text('Diagnóstico post-extracción', style: AppTextStyles.displaySmall),
      ),
    );
  }
}
