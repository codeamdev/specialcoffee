import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:special_coffee/core/constants/app_constants.dart';
import 'package:special_coffee/presentation/providers/auth_provider.dart';

class _Tab {
  final IconData icon;
  final IconData selectedIcon;
  final String   label;
  final String   route;

  const _Tab(this.icon, this.selectedIcon, this.label, this.route);
}

const _tabHome         = _Tab(Icons.dashboard_outlined,   Icons.dashboard,   'Inicio',   AppRoutes.home);
const _tabBaristaHome  = _Tab(Icons.dashboard_outlined,   Icons.dashboard,   'Inicio',   AppRoutes.baristaHome);
const _tabLots         = _Tab(Icons.inventory_2_outlined, Icons.inventory_2, 'Lotes',    AppRoutes.lots);
const _tabBrew         = _Tab(Icons.coffee_outlined,      Icons.coffee,      'Preparar', AppRoutes.brew);
const _tabProfile      = _Tab(Icons.person_outline,       Icons.person,      'Perfil',   AppRoutes.profile);

List<_Tab> _tabsFor(String role) => switch (role) {
  'barista'                          => [_tabBaristaHome, _tabBrew, _tabProfile],
  'brand_manager' || 'entrepreneur'  => [_tabHome, _tabLots, _tabBrew, _tabProfile],
  'coffee_master' || 'producer_integral' => [_tabHome, _tabLots, _tabBrew, _tabProfile],
  _                                  => [_tabHome, _tabLots, _tabProfile], // producer + legacy
};

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role     = ref.watch(currentUserProvider)?.role ?? 'producer';
    final tabs     = _tabsFor(role);
    final location = GoRouterState.of(context).matchedLocation;
    final index    = _indexOf(location, tabs);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => context.go(tabs[i].route),
        destinations: [
          for (final t in tabs)
            NavigationDestination(
              icon:         Icon(t.icon),
              selectedIcon: Icon(t.selectedIcon),
              label:        t.label,
            ),
        ],
      ),
    );
  }

  int _indexOf(String location, List<_Tab> tabs) {
    for (int i = tabs.length - 1; i >= 0; i--) {
      if (location.startsWith(tabs[i].route)) return i;
    }
    return 0;
  }
}
