import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:special_coffee/core/constants/app_constants.dart';
import 'package:special_coffee/core/theme/app_colors.dart';
import 'package:special_coffee/core/theme/app_text_styles.dart';
import 'package:special_coffee/domain/entities/cosecha_pase.dart';
import 'package:special_coffee/presentation/providers/cosecha_pase_provider.dart';

class PasesListScreen extends ConsumerStatefulWidget {
  const PasesListScreen({super.key});

  @override
  ConsumerState<PasesListScreen> createState() => _PasesListScreenState();
}

class _PasesListScreenState extends ConsumerState<PasesListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Pases de Recolección'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.caramel,
          unselectedLabelColor: AppColors.onSurfaceVariant,
          indicatorColor: AppColors.caramel,
          tabs: const [
            Tab(text: 'En proceso'),
            Tab(text: 'Completados'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.pasesCreate),
        backgroundColor: AppColors.caramel,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Nuevo pase',
            style: AppTextStyles.labelLarge.copyWith(color: Colors.white)),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _ActivePasesTab(),
          _CompletedPasesTab(),
        ],
      ),
    );
  }
}

// ── Active tab ─────────────────────────────────────────────────────────────────

class _ActivePasesTab extends ConsumerWidget {
  const _ActivePasesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(activePasesProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:   (e, _) => Center(child: Text('Error: $e')),
      data: (pases) {
        if (pases.isEmpty) {
          return const _EmptyState(
            icon: Icons.hourglass_empty_rounded,
            message: 'Sin pases en proceso.',
            hint: 'Ve a un lote y crea un nuevo pase de cosecha.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          itemCount: pases.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) => _PaseCard(pase: pases[i]),
        );
      },
    );
  }
}

// ── Completed tab ──────────────────────────────────────────────────────────────

class _CompletedPasesTab extends ConsumerWidget {
  const _CompletedPasesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(completedPasesProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:   (e, _) => Center(child: Text('Error: $e')),
      data: (pases) {
        if (pases.isEmpty) {
          return const _EmptyState(
            icon: Icons.check_circle_outline_rounded,
            message: 'Aún no hay pases completados.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          itemCount: pases.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) => _PaseCard(pase: pases[i]),
        );
      },
    );
  }
}

// ── Pase card ──────────────────────────────────────────────────────────────────

class _PaseCard extends StatelessWidget {
  const _PaseCard({required this.pase});

  final CosechaPase pase;

  @override
  Widget build(BuildContext context) {
    final (icon, color, etapaLabel) = _etapaInfo(pase.etapaActual, pase.status);
    return GestureDetector(
      onTap: () => context.push('${AppRoutes.pases}/${pase.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _tipoLabel(pase.tipoProceso),
                        style: AppTextStyles.bodyMedium
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      _Badge(label: etapaLabel, color: color),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${pase.pesoCerezaKg.toStringAsFixed(0)} kg · ${_fmt(pase.fechaRecoleccion)}',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  static (IconData, Color, String) _etapaInfo(String etapa, String status) {
    if (status == 'completado') {
      return (Icons.check_circle_outline_rounded, AppColors.success, 'Completado');
    }
    return switch (etapa) {
      'clasificacion' => (Icons.sort_rounded,                     AppColors.caramel,      'Clasificación'),
      'fermentacion'  => (Icons.science_outlined,                 AppColors.error,         'Fermentando'),
      'lavado'        => (Icons.water_drop_outlined,              AppColors.aiBlue,        'Lavado'),
      'secado'        => (Icons.wb_sunny_outlined,                AppColors.warning,       'Secado'),
      'trilla'        => (Icons.precision_manufacturing_outlined, AppColors.roleProcessor, 'Trilla'),
      _               => (Icons.hourglass_empty_rounded,          AppColors.disabled,      etapa),
    };
  }

  static String _tipoLabel(String t) => switch (t) {
    'lavado'             => 'Lavado',
    'natural'            => 'Natural',
    'honey_yellow'       => 'Honey Yellow',
    'honey_red'          => 'Honey Red',
    'anaerobic_lactic'   => 'Anaeróbico Láctico',
    'anaerobic_carbonic' => 'Anaeróbico Carbónico',
    _                    => t,
  };

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// ── Badge ──────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color  color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color:  color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(label,
            style: AppTextStyles.aiCaption
                .copyWith(color: color, fontWeight: FontWeight.w600)),
      );
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message, this.hint});

  final IconData icon;
  final String   message;
  final String?  hint;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.disabled),
            const SizedBox(height: 12),
            Text(message, style: AppTextStyles.bodyMedium),
            if (hint != null) ...[
              const SizedBox(height: 4),
              Text(hint!,
                  style: AppTextStyles.bodySmall,
                  textAlign: TextAlign.center),
            ],
          ],
        ),
      );
}
