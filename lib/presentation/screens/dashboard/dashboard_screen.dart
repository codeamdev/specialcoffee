import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:special_coffee/core/constants/app_constants.dart';
import 'package:special_coffee/core/theme/app_colors.dart';
import 'package:special_coffee/core/theme/app_text_styles.dart';
import 'package:special_coffee/domain/entities/lot.dart';
import 'package:special_coffee/presentation/providers/auth_provider.dart';
import 'package:special_coffee/presentation/providers/lot_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user     = ref.watch(currentUserProvider);
    final lotsAsync = ref.watch(userLotsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('SpecialCoffee AI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(userLotsProvider),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          children: [
            _GreetingCard(user: user),
            const SizedBox(height: 20),
            _QuickActions(role: user?.role ?? 'farmer'),
            const SizedBox(height: 24),
            _SectionHeader(
              title: 'Lotes activos',
              onSeeAll: () => context.go(AppRoutes.lots),
            ),
            const SizedBox(height: 10),
            lotsAsync.when(
              loading: () => const _LoadingSkeleton(),
              error: (e, _) => _ErrorCard(onRetry: () => ref.invalidate(userLotsProvider)),
              data: (lots) {
                final active = lots.where((l) =>
                  l.status != 'ready' && l.status != 'pending'
                ).toList();
                final pending = lots.where((l) => l.status == 'pending').toList();

                if (lots.isEmpty) return const _NoLotsCard();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (active.isNotEmpty) ...[
                      ...active.take(3).map((lot) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ActiveLotCard(
                          lot: lot,
                          onTap: () => context.go(
                            AppRoutes.lotDetail.replaceFirst(':id', lot.id),
                          ),
                        ),
                      )),
                    ],
                    if (pending.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${pending.length} lote${pending.length > 1 ? "s" : ""} pendiente${pending.length > 1 ? "s" : ""} de iniciar',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning),
                      ),
                    ],
                    if (active.isEmpty && pending.isNotEmpty)
                      ...pending.take(2).map((lot) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ActiveLotCard(
                          lot: lot,
                          onTap: () => context.go(
                            AppRoutes.lotDetail.replaceFirst(':id', lot.id),
                          ),
                        ),
                      )),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            _SectionHeader(title: 'Resumen', onSeeAll: null),
            const SizedBox(height: 10),
            lotsAsync.maybeWhen(
              data: (lots) => _StatsRow(lots: lots),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Greeting ──────────────────────────────────────────────────────────────────

class _GreetingCard extends StatelessWidget {
  const _GreetingCard({required this.user});

  final dynamic user;

  @override
  Widget build(BuildContext context) {
    final hour       = DateTime.now().hour;
    final greeting   = hour < 12 ? 'Buenos días' : hour < 18 ? 'Buenas tardes' : 'Buenas noches';
    final name       = (user?.displayName as String?)?.split(' ').first ?? '';
    final (roleLabel, roleColor) = _roleInfo((user?.role as String?) ?? 'farmer');

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
                  style: AppTextStyles.displaySmall.copyWith(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: roleColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    roleLabel,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: roleColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
    'farmer'       => ('Caficultor',  AppColors.roleFarmer),
    'processor'    => ('Procesador',  AppColors.roleProcessor),
    'barista'      => ('Barista',     AppColors.roleBarista),
    'entrepreneur' => ('Empresario',  AppColors.roleEntrepreneur),
    _              => (role,          AppColors.caramelLight),
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
      ('Nuevo lote',  Icons.add_circle_outline,  () => ctx.go(AppRoutes.lotCreate)),
      ('Preparar',    Icons.coffee_outlined,      () => ctx.go(AppRoutes.brew)),
      ('Fermentar',   Icons.science_outlined,     () => ctx.go(AppRoutes.lots)),
    ];
    return switch (role) {
      'barista'      => [all[1]],
      'farmer'       => [all[0], all[2]],
      'processor'    => [all[0], all[2]],
      'entrepreneur' => all,
      _              => [all[0]],
    };
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.label, required this.icon, required this.onTap});

  final String       label;
  final IconData     icon;
  final VoidCallback onTap;

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
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.onSurface),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onSeeAll});

  final String       title;
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
            child: Text(
              'Ver todos',
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.caramel),
            ),
          ),
      ],
    );
  }
}

// ── Active lot card ───────────────────────────────────────────────────────────

class _ActiveLotCard extends StatelessWidget {
  const _ActiveLotCard({required this.lot, required this.onTap});

  final Lot          lot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusColor) = _statusInfo(lot.status);
    final (processLabel, processIcon) = _processInfo(lot.processType);

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
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(processIcon, size: 20, color: statusColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lot.varietyName,
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$processLabel · ${lot.region.isNotEmpty ? lot.region : "Sin región"}',
                    style: AppTextStyles.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                statusLabel,
                style: AppTextStyles.labelSmall.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
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

  (String, IconData) _processInfo(String p) => switch (p) {
    'lavado'    => ('Lavado',    Icons.water_drop_outlined),
    'natural'   => ('Natural',   Icons.wb_sunny_outlined),
    'honey'     => ('Honey',     Icons.hexagon_outlined),
    'anaerobio' => ('Anaerobio', Icons.science_outlined),
    _           => (p,           Icons.filter_outlined),
  };
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.lots});

  final List<Lot> lots;

  @override
  Widget build(BuildContext context) {
    final total    = lots.length;
    final active   = lots.where((l) => l.status == 'fermenting' || l.status == 'drying').length;
    final ready    = lots.where((l) => l.status == 'ready').length;

    return Row(
      children: [
        _StatCell('Total', '$total', Icons.inventory_2_outlined, AppColors.onSurfaceVariant),
        const SizedBox(width: 10),
        _StatCell('En proceso', '$active', Icons.science_outlined, AppColors.aiBlue),
        const SizedBox(width: 10),
        _StatCell('Listos', '$ready', Icons.check_circle_outline, AppColors.success),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell(this.label, this.value, this.icon, this.color);

  final String   label;
  final String   value;
  final IconData icon;
  final Color    color;

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
            Text(
              value,
              style: AppTextStyles.numericMedium.copyWith(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(label, style: AppTextStyles.labelSmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ── Empty / error / loading states ────────────────────────────────────────────

class _NoLotsCard extends StatelessWidget {
  const _NoLotsCard();

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
          const Icon(Icons.inventory_2_outlined, color: AppColors.outlineVariant, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sin lotes aún', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('Crea tu primer lote para comenzar.', style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.go(AppRoutes.lotCreate),
            child: const Text('Crear'),
          ),
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
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
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
