import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:special_coffee/core/constants/app_constants.dart';
import 'package:special_coffee/core/theme/app_colors.dart';
import 'package:special_coffee/core/theme/app_text_styles.dart';
import 'package:special_coffee/domain/entities/brewing_session.dart';
import 'package:special_coffee/domain/entities/cosecha_pase.dart';
import 'package:special_coffee/presentation/providers/auth_provider.dart';
import 'package:special_coffee/presentation/providers/brewing_history_provider.dart';
import 'package:special_coffee/presentation/providers/cosecha_pase_provider.dart';
import 'package:special_coffee/presentation/providers/lot_summary_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final role = user?.role ?? 'producer';

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('SpecialCoffee AI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined),
            tooltip: 'Lotes',
            onPressed: () => context.go(AppRoutes.lots),
          ),
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(activePasesProvider),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          children: [
            _GreetingCard(user: user),
            const SizedBox(height: 20),
            _QuickActions(role: role),
            const SizedBox(height: 24),
            _RoleView(role: role),
          ],
        ),
      ),
    );
  }
}

// ── Role dispatcher ───────────────────────────────────────────────────────────

class _RoleView extends StatelessWidget {
  const _RoleView({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) => switch (role) {
    'barista' => const _BaristaView(),
    _         => const _FarmerView(),
  };
}

// ══════════════════════════════════════════════════════════════════════════════
// CAFICULTOR / PRODUCTOR view — centrado en pases de cosecha
// ══════════════════════════════════════════════════════════════════════════════

class _FarmerView extends ConsumerWidget {
  const _FarmerView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pasesAsync = ref.watch(activePasesProvider);
    final userId     = ref.watch(currentUserIdProvider);
    final insights   = ref.watch(lotInsightsProvider(userId));

    return pasesAsync.when(
      loading: () => const _LoadingSkeleton(),
      error:   (_, __) => _ErrorCard(onRetry: () => ref.invalidate(activePasesProvider)),
      data: (pases) {
        final fermenting = pases.where((p) => p.etapaActual == 'fermentacion').toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (fermenting.isNotEmpty) ...[
              _PaseCriticalBanner(pase: fermenting.first),
              const SizedBox(height: 16),
            ],

            _PaseStatsRow(pases: pases),
            const SizedBox(height: 16),

            _SectionHeader(
              title: 'Pases en proceso',
              onSeeAll: pases.isNotEmpty ? () => context.go(AppRoutes.pases) : null,
            ),
            const SizedBox(height: 10),
            if (pases.isEmpty)
              const _NoPasesCard()
            else
              ...pases.take(4).map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _DashboardPaseCard(pase: p),
                  )),

            insights.when(
              loading: () => const SizedBox.shrink(),
              error:   (_, __) => const SizedBox.shrink(),
              data: (list) {
                if (list.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    const _SectionHeader(title: 'Aprendizaje acumulado', onSeeAll: null),
                    const SizedBox(height: 10),
                    ...list.take(2).map((i) => _InsightCard(insight: i.insightText)),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}

// ── Pase critical banner ──────────────────────────────────────────────────────

class _PaseCriticalBanner extends StatelessWidget {
  const _PaseCriticalBanner({required this.pase});
  final CosechaPase pase;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${_tipoLabel(pase.tipoProceso)} en fermentación — revisa el estado.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.error, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () => context.push(
              '/lots/${pase.lotId}/fermentation?paseId=${pase.id}',
            ),
            child: const Text('Ver'),
          ),
        ],
      ),
    );
  }
}

// ── Pase stats row ────────────────────────────────────────────────────────────

class _PaseStatsRow extends StatelessWidget {
  const _PaseStatsRow({required this.pases});
  final List<CosechaPase> pases;

  @override
  Widget build(BuildContext context) {
    final clas = pases.where((p) => p.etapaActual == 'clasificacion').length;
    final ferm = pases.where((p) => p.etapaActual == 'fermentacion').length;
    final sec  = pases.where((p) => p.etapaActual == 'secado').length;
    return Row(
      children: [
        _StatCell('Clasificación', '$clas', Icons.sort_rounded,        AppColors.caramel),
        const SizedBox(width: 10),
        _StatCell('Fermentando',   '$ferm', Icons.science_outlined,    AppColors.error),
        const SizedBox(width: 10),
        _StatCell('Secado',        '$sec',  Icons.wb_sunny_outlined,   AppColors.warning),
      ],
    );
  }
}

// ── Dashboard pase card ───────────────────────────────────────────────────────

class _DashboardPaseCard extends StatelessWidget {
  const _DashboardPaseCard({required this.pase});
  final CosechaPase pase;

  @override
  Widget build(BuildContext context) {
    final (icon, color, etapaLabel) = _etapaInfo(pase.etapaActual);
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
                  Row(children: [
                    Text(
                      _tipoLabel(pase.tipoProceso),
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        etapaLabel,
                        style: AppTextStyles.aiCaption
                            .copyWith(color: color, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 3),
                  Text(
                    '${pase.pesoCerezaKg.toStringAsFixed(0)} kg · ${_fmt(pase.fechaRecoleccion)}',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  static (IconData, Color, String) _etapaInfo(String e) => switch (e) {
    'clasificacion' => (Icons.sort_rounded,                     AppColors.caramel,      'Clasificación'),
    'fermentacion'  => (Icons.science_outlined,                 AppColors.error,        'Fermentando'),
    'lavado'        => (Icons.water_drop_outlined,              AppColors.aiBlue,       'Lavado'),
    'secado'        => (Icons.wb_sunny_outlined,                AppColors.warning,      'Secado'),
    'trilla'        => (Icons.precision_manufacturing_outlined, AppColors.roleProcessor,'Trilla'),
    _               => (Icons.hourglass_empty_rounded,          AppColors.disabled,     e),
  };

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// ── No pases card ─────────────────────────────────────────────────────────────

class _NoPasesCard extends StatelessWidget {
  const _NoPasesCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.agriculture_outlined, color: AppColors.outlineVariant, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sin pases activos',
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                const Text('Crea tu primer pase de recolección.', style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.push(AppRoutes.pasesCreate),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }
}

// ── Shared helper ─────────────────────────────────────────────────────────────

String _tipoLabel(String t) => switch (t) {
  'lavado'             => 'Lavado',
  'natural'            => 'Natural',
  'honey_yellow'       => 'Honey Yellow',
  'honey_red'          => 'Honey Red',
  'anaerobic_lactic'   => 'Anaeróbico Láctico',
  'anaerobic_carbonic' => 'Anaeróbico Carbónico',
  _                    => t,
};

// ── Insight card ──────────────────────────────────────────────────────────────

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});

  final String insight;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline_rounded, size: 18, color: AppColors.caramel),
          const SizedBox(width: 10),
          Expanded(child: Text(insight, style: AppTextStyles.bodySmall)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// BARISTA view
// ══════════════════════════════════════════════════════════════════════════════

class _BaristaView extends ConsumerWidget {
  const _BaristaView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(recentBrewingSessionsProvider);

    return sessionsAsync.when(
      loading: () => const _LoadingSkeleton(),
      error:   (_, __) => const SizedBox.shrink(),
      data: (sessions) {
        if (sessions.isEmpty) {
          return _NoBruewCard();
        }
        final last = sessions.first;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(title: 'Última sesión', onSeeAll: null),
            const SizedBox(height: 10),
            _LastBrewCard(session: last),
            const SizedBox(height: 8),
            _TdsStreakRow(sessions: sessions),
          ],
        );
      },
    );
  }
}

class _LastBrewCard extends StatelessWidget {
  const _LastBrewCard({required this.session});

  final BrewingSession session;

  @override
  Widget build(BuildContext context) {
    final method = _prettyMethod(session.method);
    final tds    = session.tdsPct != null
        ? '${session.tdsPct!.toStringAsFixed(2)}%'
        : 'Sin TDS';
    final ratio  = (session.waterG / session.doseG).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.coffee_outlined, size: 18, color: AppColors.caramel),
            const SizedBox(width: 8),
            Text(method, style: AppTextStyles.labelLarge),
          ]),
          const SizedBox(height: 12),
          Row(
            children: [
              _BrewStat('Dosis', '${session.doseG.toStringAsFixed(1)} g'),
              _BrewStat('Agua', '${session.waterG.toStringAsFixed(0)} g'),
              _BrewStat('Ratio', '1:$ratio'),
              _BrewStat('TDS', tds),
            ],
          ),
        ],
      ),
    );
  }

  String _prettyMethod(String m) => switch (m) {
    'v60'          => 'V60',
    'chemex'       => 'Chemex',
    'aeropress'    => 'Aeropress',
    'french_press' => 'French Press',
    'espresso'     => 'Espresso',
    'moka'         => 'Moka',
    'cold_brew'    => 'Cold Brew',
    _              => m,
  };
}

class _BrewStat extends StatelessWidget {
  const _BrewStat(this.label, this.value);

  final String label, value;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(label, style: AppTextStyles.bodySmall),
            const SizedBox(height: 2),
            Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _TdsStreakRow extends StatelessWidget {
  const _TdsStreakRow({required this.sessions});

  final List<BrewingSession> sessions;

  @override
  Widget build(BuildContext context) {
    final withTds = sessions.where((s) => (s.tdsPct ?? 0) > 0).toList();
    if (withTds.isEmpty) return const SizedBox.shrink();

    // Count consecutive sessions within specialty range (1.15–1.45%)
    int streak = 0;
    for (final s in withTds) {
      if ((s.tdsPct ?? 0) >= 1.15 && (s.tdsPct ?? 0) <= 1.45) {
        streak++;
      } else {
        break;
      }
    }

    final color = streak >= 3 ? AppColors.success : AppColors.warning;
    final label = streak >= 3
        ? '$streak sesiones en rango TDS — ¡consistente!'
        : '$streak sesión${streak != 1 ? "es" : ""} en rango TDS';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(streak >= 3 ? Icons.local_fire_department_rounded : Icons.show_chart_rounded,
              size: 18, color: color),
          const SizedBox(width: 8),
          Text(label, style: AppTextStyles.bodySmall.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _NoBruewCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.coffee_outlined, color: AppColors.outlineVariant, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sin sesiones de brewing', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                const Text('Registra tu primera preparación.', style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.go(AppRoutes.brew),
            child: const Text('Ir'),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Shared widgets
// ══════════════════════════════════════════════════════════════════════════════

// ── Greeting ──────────────────────────────────────────────────────────────────

class _GreetingCard extends StatelessWidget {
  const _GreetingCard({required this.user});

  final dynamic user;

  @override
  Widget build(BuildContext context) {
    final hour     = DateTime.now().hour;
    final greeting = hour < 12 ? 'Buenos días' : hour < 18 ? 'Buenas tardes' : 'Buenas noches';
    final name     = (user?.displayName as String?)?.split(' ').first ?? '';
    final (roleLabel, roleColor) = _roleInfo((user?.role as String?) ?? 'producer');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.espresso, AppColors.espressoLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting${name.isNotEmpty ? ", $name" : ""}',
                  style: AppTextStyles.displaySmall.copyWith(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: roleColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(roleLabel,
                      style: AppTextStyles.labelSmall.copyWith(color: roleColor, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const Icon(Icons.coffee, size: 40, color: AppColors.caramel),
        ],
      ),
    );
  }

  (String, Color) _roleInfo(String role) => switch (role) {
    'producer'          => ('Productor',       AppColors.roleFarmer),
    'farmer'            => ('Productor',       AppColors.roleFarmer),
    'processor'         => ('Procesador',      AppColors.roleProcessor),
    'coffee_master'     => ('Coffee Master',   AppColors.aiBlue),
    'producer_integral' => ('Prod. Integral',  AppColors.caramel),
    'brand_manager'     => ('Brand Manager',   AppColors.roleEntrepreneur),
    'entrepreneur'      => ('Empresario',      AppColors.roleEntrepreneur),
    'barista'           => ('Barista',         AppColors.roleBarista),
    _                   => (role,              AppColors.caramelLight),
  };
}

// ── Quick actions ─────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final actions = _actionsFor(role, context);
    return Row(
      children: actions
          .map((a) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _ActionChip(label: a.$1, icon: a.$2, onTap: a.$3),
                ),
              ))
          .toList(),
    );
  }

  List<(String, IconData, VoidCallback)> _actionsFor(String role, BuildContext ctx) {
    return switch (role) {
      'barista'                              => [
        ('Preparar',  Icons.coffee_outlined,       () => ctx.go(AppRoutes.brew)),
        ('Historial', Icons.history_rounded,        () => ctx.go(AppRoutes.brew)),
      ],
      'brand_manager' || 'entrepreneur'      => [
        ('Ver pases', Icons.agriculture_outlined,  () => ctx.go(AppRoutes.pases)),
        ('Preparar',  Icons.coffee_outlined,        () => ctx.go(AppRoutes.brew)),
      ],
      'coffee_master' || 'producer_integral' => [
        ('Nuevo pase', Icons.add_circle_outline,   () => ctx.push(AppRoutes.pasesCreate)),
        ('Preparar',   Icons.coffee_outlined,       () => ctx.go(AppRoutes.brew)),
      ],
      _ => [],
    };
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.label, required this.icon, required this.onTap});

  final String label; final IconData icon; final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: AppColors.caramel),
            const SizedBox(height: 6),
            Text(label,
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.onSurface),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ── Shared section header ─────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onSeeAll});

  final String        title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: AppTextStyles.labelLarge),
        const Spacer(),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Text('Ver todos',
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.caramel)),
          ),
      ],
    );
  }
}

// ── Stat cell ─────────────────────────────────────────────────────────────────

class _StatCell extends StatelessWidget {
  const _StatCell(this.label, this.value, this.icon, this.color);

  final String label, value; final IconData icon; final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 6),
            Text(value,
                style: AppTextStyles.numericMedium
                    .copyWith(color: color, fontSize: 22, fontWeight: FontWeight.w700)),
            Text(label, style: AppTextStyles.labelSmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ── Empty / error / loading ───────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.errorContainer, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          const Expanded(child: Text('Error al cargar datos')),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        2,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }
}
