import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:special_coffee/core/constants/app_constants.dart';
import 'package:special_coffee/core/theme/app_colors.dart';
import 'package:special_coffee/core/theme/app_text_styles.dart';
import 'package:special_coffee/domain/entities/brewing_session.dart';
import 'package:special_coffee/domain/entities/lot.dart';
import 'package:special_coffee/presentation/providers/auth_provider.dart';
import 'package:special_coffee/presentation/providers/brewing_history_provider.dart';
import 'package:special_coffee/presentation/providers/brewing_session_provider.dart';
import 'package:special_coffee/presentation/providers/lot_provider.dart';
import 'package:special_coffee/presentation/providers/lot_summary_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user      = ref.watch(currentUserProvider);
    final lotsAsync = ref.watch(userLotsProvider);
    final role      = user?.role ?? 'producer';

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('SpecialCoffee AI'),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(userLotsProvider),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          children: [
            _GreetingCard(user: user),
            const SizedBox(height: 20),
            _QuickActions(role: role),
            const SizedBox(height: 24),
            lotsAsync.when(
              loading: () => const _LoadingSkeleton(),
              error:   (e, _) => _ErrorCard(onRetry: () => ref.invalidate(userLotsProvider)),
              data:    (lots)  => _RoleContent(role: role, lots: lots),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Role dispatcher ───────────────────────────────────────────────────────────

class _RoleContent extends ConsumerWidget {
  const _RoleContent({required this.role, required this.lots});

  final String    role;
  final List<Lot> lots;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (role) {
      'processor'                               => _ProcessorView(lots: lots),
      'barista'                                 => _BaristaView(lots: lots),
      'coffee_master' || 'producer_integral'    => _ProcessorView(lots: lots),
      'brand_manager' || 'entrepreneur'         => _FarmerView(lots: lots),
      _                                         => _FarmerView(lots: lots),   // producer + legacy
    };
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CAFICULTOR view
// ══════════════════════════════════════════════════════════════════════════════

class _FarmerView extends ConsumerWidget {
  const _FarmerView({required this.lots});

  final List<Lot> lots;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active  = lots.where((l) => _isActive(l.status)).toList()
      ..sort((a, b) => _urgency(b.status).compareTo(_urgency(a.status)));
    final criticals = active.where((l) => _urgency(l.status) == 2).toList();
    final userId  = ref.watch(currentUserIdProvider);
    final insights = ref.watch(lotInsightsProvider(userId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Critical alert banner — only shown if there's a fermenting lot
        if (criticals.isNotEmpty) ...[
          _CriticalBanner(lot: criticals.first),
          const SizedBox(height: 16),
        ],

        // "¿Qué hago hoy?"
        _WhatToDoCard(lots: active),
        const SizedBox(height: 20),

        // Lot semaphore list
        _SectionHeader(title: 'Lotes activos', onSeeAll: () => context.go(AppRoutes.lots)),
        const SizedBox(height: 10),
        if (active.isEmpty)
          const _NoLotsCard()
        else
          ...active.take(4).map((lot) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SemaphoreLotCard(
                  lot: lot,
                  onTap: () => context.go(AppRoutes.lotDetail.replaceFirst(':id', lot.id)),
                ),
              )),

        // Recent insights
        insights.when(
          loading: () => const SizedBox.shrink(),
          error:   (_, __) => const SizedBox.shrink(),
          data:    (list) {
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
  }

  static bool _isActive(String s) => s != 'pending' && s != 'ready';
  static int  _urgency(String s)  => switch (s) {
    'fermenting' => 2,
    'drying'     => 1,
    'milling'    => 1,
    _            => 0,
  };
}

// ── What to do today ──────────────────────────────────────────────────────────

class _WhatToDoCard extends StatelessWidget {
  const _WhatToDoCard({required this.lots});

  final List<Lot> lots;

  @override
  Widget build(BuildContext context) {
    final (action, icon, route) = _todayAction(lots, context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.aiBlueContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.aiBlue.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: AppColors.aiBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('¿Qué hago hoy?', style: AppTextStyles.labelSmall.copyWith(color: AppColors.aiBlue)),
                const SizedBox(height: 4),
                Text(action, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (route != null)
            IconButton(
              icon: const Icon(Icons.arrow_forward_rounded, color: AppColors.aiBlue),
              onPressed: () => context.go(route),
            ),
        ],
      ),
    );
  }

  (String, IconData, String?) _todayAction(List<Lot> lots, BuildContext ctx) {
    if (lots.isEmpty) return ('Crea tu primer lote para comenzar.', Icons.add_circle_outline, AppRoutes.lotCreate);
    final fermenting = lots.where((l) => l.status == 'fermenting').firstOrNull;
    if (fermenting != null) return ('Revisar fermentación — ${fermenting.varietyName}', Icons.science_outlined, AppRoutes.fermentation.replaceFirst(':id', fermenting.id));
    final drying = lots.where((l) => l.status == 'drying').firstOrNull;
    if (drying != null) return ('Tomar lectura de secado — ${drying.varietyName}', Icons.wb_sunny_outlined, AppRoutes.drying.replaceFirst(':id', drying.id));
    final milling = lots.where((l) => l.status == 'milling').firstOrNull;
    if (milling != null) return ('Registrar trilla — ${milling.varietyName}', Icons.precision_manufacturing_outlined, AppRoutes.milling.replaceFirst(':id', milling.id));
    return ('Iniciar nuevo lote', Icons.add_circle_outline, AppRoutes.lotCreate);
  }
}

// ── Semaphore lot card ────────────────────────────────────────────────────────

class _SemaphoreLotCard extends StatelessWidget {
  const _SemaphoreLotCard({required this.lot, required this.onTap});

  final Lot          lot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (indicator, label, color) = _semaphore(lot.status);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Text(indicator, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lot.varietyName, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                  Text('${lot.region.isNotEmpty ? lot.region : "Sin región"} · $label', style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  (String, String, Color) _semaphore(String status) => switch (status) {
    'fermenting' => ('🔴', 'Fermentando — revisar pH', AppColors.error),
    'drying'     => ('🟡', 'En secado', AppColors.warning),
    'milling'    => ('🟡', 'En trilla', AppColors.warning),
    'ready'      => ('✅', 'Listo', AppColors.success),
    _            => ('⚪', 'Pendiente', AppColors.onSurfaceVariant),
  };
}

// ── Critical alert banner ─────────────────────────────────────────────────────

class _CriticalBanner extends StatelessWidget {
  const _CriticalBanner({required this.lot});

  final Lot lot;

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
              '${lot.varietyName} está fermentando — revisa el estado ahora.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () => context.go(AppRoutes.fermentation.replaceFirst(':id', lot.id)),
            child: const Text('Ver'),
          ),
        ],
      ),
    );
  }
}

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
// PROCESADOR view
// ══════════════════════════════════════════════════════════════════════════════

class _ProcessorView extends StatelessWidget {
  const _ProcessorView({required this.lots});

  final List<Lot> lots;

  @override
  Widget build(BuildContext context) {
    final active      = lots.where((l) => l.status != 'ready').toList()
      ..sort((a, b) => _urgency(b.status).compareTo(_urgency(a.status)));
    final fermenting  = lots.where((l) => l.status == 'fermenting').length;
    final drying      = lots.where((l) => l.status == 'drying').length;
    final criticals   = active.where((l) => l.status == 'fermenting').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary counters
        _ProcessorSummary(active: active.length, fermenting: fermenting, drying: drying),
        const SizedBox(height: 16),

        // Critical alerts first
        if (criticals.isNotEmpty) ...[
          const _SectionHeader(title: '🔴 Requieren atención', onSeeAll: null),
          const SizedBox(height: 10),
          ...criticals.take(3).map((lot) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ActiveLotCard(
                  lot: lot,
                  onTap: () => context.go(AppRoutes.fermentation.replaceFirst(':id', lot.id)),
                ),
              )),
          const SizedBox(height: 12),
        ],

        // All active lots
        _SectionHeader(
          title: 'Todos los lotes activos',
          onSeeAll: () => context.go(AppRoutes.lots),
        ),
        const SizedBox(height: 10),
        if (active.isEmpty)
          const _NoLotsCard()
        else
          ...active.map((lot) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SemaphoreLotCard(
                  lot: lot,
                  onTap: () => context.go(AppRoutes.lotDetail.replaceFirst(':id', lot.id)),
                ),
              )),
      ],
    );
  }

  static int _urgency(String s) => switch (s) {
    'fermenting' => 2,
    'drying'     => 1,
    'milling'    => 1,
    _            => 0,
  };
}

class _ProcessorSummary extends StatelessWidget {
  const _ProcessorSummary({required this.active, required this.fermenting, required this.drying});

  final int active, fermenting, drying;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCell('Activos',       '$active',      Icons.inventory_2_outlined,  AppColors.onSurfaceVariant),
        const SizedBox(width: 10),
        _StatCell('Fermentando',   '$fermenting',  Icons.science_outlined,       AppColors.aiBlue),
        const SizedBox(width: 10),
        _StatCell('Secando',       '$drying',      Icons.wb_sunny_outlined,      AppColors.caramel),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// BARISTA view
// ══════════════════════════════════════════════════════════════════════════════

class _BaristaView extends ConsumerWidget {
  const _BaristaView({required this.lots});

  final List<Lot> lots;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(recentBrewingSessionsProvider);
    final cupped = lots.where((l) => l.status == 'ready').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Last brew session
        sessionsAsync.when(
          loading: () => const _LoadingSkeleton(),
          error:   (_, __) => const SizedBox.shrink(),
          data:    (sessions) {
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
        ),

        const SizedBox(height: 20),

        // Cupped lots catalog
        if (cupped.isNotEmpty) ...[
          _SectionHeader(title: 'Cafés catados', onSeeAll: () => context.go(AppRoutes.lots)),
          const SizedBox(height: 10),
          ...cupped.take(3).map((lot) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ActiveLotCard(
                  lot: lot,
                  onTap: () => context.go(AppRoutes.lotDetail.replaceFirst(':id', lot.id)),
                ),
              )),
        ] else ...[
          const _SectionHeader(title: 'Cafés catados', onSeeAll: null),
          const SizedBox(height: 10),
          const _NoLotsCard(),
        ],
      ],
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
                Text('Registra tu primera preparación.', style: AppTextStyles.bodySmall),
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
        gradient: LinearGradient(
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
    'farmer'            => ('Productor',       AppColors.roleFarmer),       // legacy
    'processor'         => ('Procesador',      AppColors.roleProcessor),    // legacy
    'coffee_master'     => ('Coffee Master',   AppColors.aiBlue),
    'producer_integral' => ('Prod. Integral',  AppColors.caramel),
    'brand_manager'     => ('Brand Manager',   AppColors.roleEntrepreneur),
    'entrepreneur'      => ('Empresario',      AppColors.roleEntrepreneur), // legacy
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
    final all = <(String, IconData, VoidCallback)>[
      ('Nuevo lote', Icons.add_circle_outline,  () => ctx.go(AppRoutes.lotCreate)),
      ('Preparar',   Icons.coffee_outlined,      () => ctx.go(AppRoutes.brew)),
      ('Mis lotes',  Icons.inventory_2_outlined, () => ctx.go(AppRoutes.lots)),
    ];
    return switch (role) {
      'barista'                              => [all[1], all[2]],
      'brand_manager' || 'entrepreneur'      => all,
      'coffee_master' || 'producer_integral' => [all[0], all[1], all[2]],
      _                                      => [all[0], all[2]], // producer + legacy farmer/processor
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
            Text(label, style: AppTextStyles.labelSmall.copyWith(color: AppColors.onSurface), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ── Shared section / lot cards ────────────────────────────────────────────────

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
            child: Text('Ver todos', style: AppTextStyles.labelSmall.copyWith(color: AppColors.caramel)),
          ),
      ],
    );
  }
}

class _ActiveLotCard extends StatelessWidget {
  const _ActiveLotCard({required this.lot, required this.onTap});

  final Lot lot; final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusColor) = _statusInfo(lot.status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lot.varietyName,
                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis),
                  Text(lot.region.isNotEmpty ? lot.region : 'Sin región',
                      style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Text(statusLabel,
                  style: AppTextStyles.labelSmall
                      .copyWith(color: statusColor, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  (String, Color) _statusInfo(String s) => switch (s) {
    'fermenting' => ('Fermentando', AppColors.aiBlue),
    'drying'     => ('Secando',     AppColors.caramel),
    'milling'    => ('Trillando',   AppColors.roleProcessor),
    'ready'      => ('Listo',       AppColors.success),
    _            => ('Pendiente',   AppColors.warning),
  };
}

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
            Text(value, style: AppTextStyles.numericMedium.copyWith(color: color, fontSize: 22, fontWeight: FontWeight.w700)),
            Text(label, style: AppTextStyles.labelSmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ── Empty / error / loading ───────────────────────────────────────────────────

class _NoLotsCard extends StatelessWidget {
  const _NoLotsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          const Icon(Icons.inventory_2_outlined, color: AppColors.outlineVariant, size: 32),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sin lotes aún', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text('Crea tu primer lote para comenzar.', style: AppTextStyles.bodySmall),
            ],
          )),
          TextButton(onPressed: () => context.go(AppRoutes.lotCreate), child: const Text('Crear')),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.errorContainer, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text('No se pudieron cargar los lotes', style: AppTextStyles.bodySmall)),
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
      children: List.generate(2, (_) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(height: 70, decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(14))),
      )),
    );
  }
}
