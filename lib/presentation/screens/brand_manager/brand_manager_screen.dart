import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:special_coffee/core/di/providers.dart';
import 'package:special_coffee/domain/entities/green_inventory.dart';
import 'package:special_coffee/domain/entities/commercial_product.dart';
import 'package:special_coffee/domain/entities/lot_certification.dart';

class BrandManagerScreen extends ConsumerWidget {
  const BrandManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Brand Manager'),
          bottom: const TabBar(tabs: [
            Tab(text: 'Inventario'),
            Tab(text: 'Productos'),
            Tab(text: 'Certificaciones'),
          ]),
        ),
        body: const TabBarView(children: [
          _InventoryTab(),
          _ProductsTab(),
          _CertificationsTab(),
        ]),
      ),
    );
  }
}

// ── Inventory tab ────────────────────────────────────────────────────────────

class _InventoryTab extends ConsumerWidget {
  const _InventoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<GreenInventory>>(
      future: ref.read(greenInventoryLocalRepoProvider).getAll(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snap.data ?? [];
        if (items.isEmpty) {
          return const Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.warehouse_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Sin inventario de café verde'),
              SizedBox(height: 8),
              Text(
                'El inventario se puebla automáticamente\nal cerrar la trilla de un lote.',
                textAlign: TextAlign.center,
              ),
            ]),
          );
        }
        final totalKg = items.fold(0.0, (s, e) => s + e.weightKg);
        return Column(children: [
          _SummaryBanner(
            label: 'Café verde disponible',
            value: '${totalKg.toStringAsFixed(1)} kg',
            icon: Icons.grass_outlined,
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (_, i) => _GreenInventoryCard(item: items[i]),
            ),
          ),
        ]);
      },
    );
  }
}

class _GreenInventoryCard extends StatelessWidget {
  const _GreenInventoryCard({required this.item});
  final GreenInventory item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.inventory_2_outlined),
        title: Text('Lote ${item.lotId.length > 8 ? item.lotId.substring(0, 8) : item.lotId}…'),
        subtitle: Text(
          '${item.weightKg.toStringAsFixed(1)} kg · ${item.sackCount} sacos ${item.sackType}'
          '${item.warehouseLocation != null ? ' · ${item.warehouseLocation}' : ''}',
        ),
        trailing: Text(
          _fmtDate(item.updatedAt),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }

  String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
}

// ── Products tab ─────────────────────────────────────────────────────────────

class _ProductsTab extends ConsumerWidget {
  const _ProductsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<CommercialProduct>>(
      future: ref.read(commercialProductLocalRepoProvider).getAll(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snap.data ?? [];
        if (items.isEmpty) {
          return const Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Sin productos comerciales'),
            ]),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (_, i) => _ProductCard(item: items[i]),
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.item});
  final CommercialProduct item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(item.name,
                  style: Theme.of(context).textTheme.titleSmall),
            ),
            Chip(label: Text('${item.formatG}g')),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            _Stat('Disponibles', '${item.unitsAvailable}'),
            const SizedBox(width: 16),
            _Stat('Producidos', '${item.unitsProduced}'),
            if (item.priceUsd != null) ...[
              const SizedBox(width: 16),
              _Stat('Precio', '\$${item.priceUsd!.toStringAsFixed(2)}'),
            ],
            if (item.marginPct != null) ...[
              const SizedBox(width: 16),
              _Stat('Margen', '${item.marginPct!.toStringAsFixed(1)}%'),
            ],
          ]),
        ]),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: Theme.of(context).textTheme.labelSmall),
      Text(value,  style: Theme.of(context).textTheme.titleMedium),
    ]);
  }
}

// ── Certifications tab ───────────────────────────────────────────────────────

class _CertificationsTab extends ConsumerWidget {
  const _CertificationsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.verified_outlined, size: 64, color: Colors.grey),
        SizedBox(height: 16),
        Text('Certificaciones por lote'),
        SizedBox(height: 8),
        Text(
          'Accede desde el detalle de un lote\npara gestionar certificaciones.',
          textAlign: TextAlign.center,
        ),
      ]),
    );
  }
}

// ── Lot-level certifications widget (embedded in LotDetailScreen) ─────────────

class LotCertificationsCard extends ConsumerWidget {
  const LotCertificationsCard({super.key, required this.lotId});
  final String lotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<LotCertification>>(
      future: ref.read(lotCertificationLocalRepoProvider).getByLotId(lotId),
      builder: (context, snap) {
        final certs = snap.data ?? [];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.verified_outlined),
                const SizedBox(width: 8),
                Text('Certificaciones',
                    style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showAddDialog(context, ref),
                ),
              ]),
              if (certs.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Sin certificaciones registradas'),
                )
              else
                Wrap(
                  spacing: 8,
                  children: certs.map((c) => Chip(
                    label: Text(_certLabel(c.type)),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () async {
                      await ref
                          .read(lotCertificationLocalRepoProvider)
                          .deleteById(c.id);
                    },
                    avatar: c.isActive
                        ? const Icon(Icons.check_circle, color: Colors.green, size: 16)
                        : const Icon(Icons.warning_amber, color: Colors.orange, size: 16),
                  )).toList(),
                ),
            ]),
          ),
        );
      },
    );
  }

  String _certLabel(String type) => switch (type) {
    'organico'          => 'Orgánico',
    'fairtrade'         => 'Fairtrade',
    'rainforest'        => 'Rainforest',
    'cup_of_excellence' => 'Cup of Excellence',
    _                   => 'Otro',
  };

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    String selected = 'organico';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Agregar certificación'),
        content: StatefulBuilder(
          builder: (ctx, setState) => DropdownButtonFormField<String>(
            initialValue: selected,
            items: const [
              DropdownMenuItem(value: 'organico',          child: Text('Orgánico')),
              DropdownMenuItem(value: 'fairtrade',         child: Text('Fairtrade')),
              DropdownMenuItem(value: 'rainforest',        child: Text('Rainforest Alliance')),
              DropdownMenuItem(value: 'cup_of_excellence', child: Text('Cup of Excellence')),
              DropdownMenuItem(value: 'otros',             child: Text('Otro')),
            ],
            onChanged: (v) => setState(() => selected = v!),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              await ref.read(lotCertificationLocalRepoProvider).save(
                    LotCertification(id: '', lotId: lotId, type: selected),
                  );
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }
}

// ── Shared ───────────────────────────────────────────────────────────────────

class _SummaryBanner extends StatelessWidget {
  const _SummaryBanner({required this.label, required this.value, required this.icon});
  final String   label;
  final String   value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.primaryContainer,
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Icon(icon, size: 32,
            color: Theme.of(context).colorScheme.onPrimaryContainer),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer)),
          Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold)),
        ]),
      ]),
    );
  }
}
