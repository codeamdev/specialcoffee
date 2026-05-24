import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:special_coffee/core/theme/app_text_styles.dart';

class BrewRecipeScreen extends ConsumerWidget {
  const BrewRecipeScreen({super.key, required this.params});

  final Map<String, dynamic> params;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receta IA')),
      body: const Center(
        child: Text('Receta generada por IA', style: AppTextStyles.displaySmall),
      ),
    );
  }
}
