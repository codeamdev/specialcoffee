import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:special_coffee/core/di/providers.dart';
import 'package:special_coffee/domain/entities/physical_analysis.dart';
import 'package:special_coffee/domain/entities/roast_profile.dart';
import 'package:special_coffee/domain/entities/cupping_evaluation.dart';
import 'package:special_coffee/presentation/providers/auth_provider.dart';

class CoffeeMasterLotScreen extends ConsumerWidget {
  const CoffeeMasterLotScreen({super.key, required this.lotId});

  final String lotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Coffee Master'),
          bottom: const TabBar(tabs: [
            Tab(text: 'Análisis físico'),
            Tab(text: 'Perfiles tueste'),
            Tab(text: 'Catación SCA'),
          ]),
        ),
        body: TabBarView(children: [
          _PhysicalAnalysisTab(lotId: lotId),
          _RoastProfileTab(lotId: lotId),
          _CuppingEvaluationTab(lotId: lotId),
        ]),
      ),
    );
  }
}

// ── Physical Analysis tab ────────────────────────────────────────────────────

class _PhysicalAnalysisTab extends ConsumerWidget {
  const _PhysicalAnalysisTab({required this.lotId});
  final String lotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<PhysicalAnalysis>>(
      future: ref.read(physicalAnalysisLocalRepoProvider).getByLotId(lotId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snap.data ?? [];
        if (items.isEmpty) {
          return _EmptyState(
            icon: Icons.science_outlined,
            label: 'Sin análisis físico',
            onAdd: () => _showPhysicalAnalysisForm(context, ref),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (_, i) => _PhysicalAnalysisCard(item: items[i]),
        );
      },
    );
  }

  void _showPhysicalAnalysisForm(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PhysicalAnalysisForm(lotId: lotId, ref: ref),
    );
  }
}

class _PhysicalAnalysisCard extends StatelessWidget {
  const _PhysicalAnalysisCard({required this.item});
  final PhysicalAnalysis item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            _fmt(item.analyzedAt),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 4, children: [
            if (item.moisturePct != null)
              Chip(label: Text('Humedad ${item.moisturePct!.toStringAsFixed(1)}%')),
            if (item.greenDensityGcm3 != null)
              Chip(label: Text('Densidad ${item.greenDensityGcm3!.toStringAsFixed(2)} g/cm³')),
            if (item.waterActivityAw != null)
              Chip(label: Text('Aw ${item.waterActivityAw!.toStringAsFixed(2)}')),
            if (item.screenSize != null)
              Chip(label: Text('Zaranda ${item.screenSize}')),
          ]),
          if (item.defectsPrimary != null || item.defectsSecondary != null) ...[
            const SizedBox(height: 4),
            Text(
              'Defectos: ${item.defectsPrimary ?? 0} primarios · '
              '${item.defectsSecondary ?? 0} secundarios',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ]),
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

class _PhysicalAnalysisForm extends ConsumerStatefulWidget {
  const _PhysicalAnalysisForm({required this.lotId, required this.ref});
  final String lotId;
  final WidgetRef ref;

  @override
  ConsumerState<_PhysicalAnalysisForm> createState() => _PhysicalAnalysisFormState();
}

class _PhysicalAnalysisFormState extends ConsumerState<_PhysicalAnalysisForm> {
  final _moisture    = TextEditingController();
  final _density     = TextEditingController();
  final _waterAct    = TextEditingController();
  final _defPrimary  = TextEditingController();
  final _defSecond   = TextEditingController();
  final _screenSize  = TextEditingController();
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Nuevo análisis físico',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          _field(_moisture,   'Humedad (%)',       'ISO 6673: 10–12%'),
          _field(_density,    'Densidad (g/cm³)',  'SCA: 0.60–0.90'),
          _field(_waterAct,   'Actividad de agua', 'SCA: 0.50–0.65'),
          _field(_defPrimary, 'Defectos primarios', ''),
          _field(_defSecond,  'Defectos secundarios', ''),
          _field(_screenSize, 'Zaranda (mesh)',    ''),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox.square(dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Guardar'),
          ),
        ]),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, String hint) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: label, hintText: hint,
              border: const OutlineInputBorder()),
        ),
      );

  Future<void> _save() async {
    setState(() => _saving = true);
    final userId = ref.read(currentUserIdProvider);
    await ref.read(physicalAnalysisLocalRepoProvider).save(PhysicalAnalysis(
      id:               '',
      lotId:            widget.lotId,
      analyzedBy:       userId,
      analyzedAt:       DateTime.now(),
      moisturePct:      double.tryParse(_moisture.text),
      greenDensityGcm3: double.tryParse(_density.text),
      waterActivityAw:  double.tryParse(_waterAct.text),
      defectsPrimary:   int.tryParse(_defPrimary.text),
      defectsSecondary: int.tryParse(_defSecond.text),
      screenSize:       int.tryParse(_screenSize.text),
    ));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _moisture.dispose(); _density.dispose(); _waterAct.dispose();
    _defPrimary.dispose(); _defSecond.dispose(); _screenSize.dispose();
    super.dispose();
  }
}

// ── Roast Profile tab ────────────────────────────────────────────────────────

class _RoastProfileTab extends ConsumerWidget {
  const _RoastProfileTab({required this.lotId});
  final String lotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<RoastProfile>>(
      future: ref.read(roastProfileLocalRepoProvider).getByLotId(lotId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snap.data ?? [];
        if (items.isEmpty) {
          return _EmptyState(
            icon: Icons.local_fire_department_outlined,
            label: 'Sin perfiles de tueste',
            onAdd: () => _showForm(context, ref),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (_, i) => _RoastProfileCard(item: items[i]),
        );
      },
    );
  }

  void _showForm(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _RoastProfileForm(lotId: lotId, ref: ref),
    );
  }
}

class _RoastProfileCard extends StatelessWidget {
  const _RoastProfileCard({required this.item});
  final RoastProfile item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(_fmt(item.roastedAt),
                style: Theme.of(context).textTheme.titleSmall),
            const Spacer(),
            if (item.colorLabel != null)
              Chip(label: Text(item.colorLabel!)),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 4, children: [
            if (item.roastLossPct != null)
              Chip(label: Text('Merma ${item.roastLossPct!.toStringAsFixed(1)}%')),
            if (item.dtrPct != null)
              Chip(label: Text('DTR ${item.dtrPct!.toStringAsFixed(1)}%')),
            if (item.agtronWhole != null)
              Chip(label: Text('Agtron ${item.agtronWhole}')),
            if (item.dropTempC != null)
              Chip(label: Text('Drop ${item.dropTempC!.toStringAsFixed(0)}°C')),
          ]),
        ]),
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

class _RoastProfileForm extends ConsumerStatefulWidget {
  const _RoastProfileForm({required this.lotId, required this.ref});
  final String lotId;
  final WidgetRef ref;

  @override
  ConsumerState<_RoastProfileForm> createState() => _RoastProfileFormState();
}

class _RoastProfileFormState extends ConsumerState<_RoastProfileForm> {
  final _greenKg     = TextEditingController();
  final _roastedKg   = TextEditingController();
  final _dropTemp    = TextEditingController();
  final _devTime     = TextEditingController();
  final _totalTime   = TextEditingController();
  final _agtron      = TextEditingController();
  String _colorLabel = 'medio';
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Nuevo perfil de tueste',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          _field(_greenKg,   'Verde (kg)', ''),
          _field(_roastedKg, 'Tostado (kg)', ''),
          _field(_dropTemp,  'Temperatura drop (°C)', ''),
          _field(_devTime,   'Tiempo desarrollo (s)', 'Scott Rao: ~20–25%'),
          _field(_totalTime, 'Tiempo total (s)', ''),
          _field(_agtron,    'Agtron entero', 'SCA: 25–95'),
          DropdownButtonFormField<String>(
            initialValue: _colorLabel,
            decoration: const InputDecoration(labelText: 'Color', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'claro',  child: Text('Claro')),
              DropdownMenuItem(value: 'medio',  child: Text('Medio')),
              DropdownMenuItem(value: 'oscuro', child: Text('Oscuro')),
            ],
            onChanged: (v) => setState(() => _colorLabel = v!),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox.square(dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Guardar'),
          ),
        ]),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, String hint) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: label, hintText: hint,
              border: const OutlineInputBorder()),
        ),
      );

  Future<void> _save() async {
    setState(() => _saving = true);
    final userId   = ref.read(currentUserIdProvider);
    final greenKg  = double.tryParse(_greenKg.text);
    final roastedKg = double.tryParse(_roastedKg.text);
    final devT     = int.tryParse(_devTime.text);
    final totalT   = int.tryParse(_totalTime.text);
    final dtrPct   = (devT != null && totalT != null && totalT > 0)
        ? devT / totalT * 100
        : null;
    final lossP    = (greenKg != null && roastedKg != null && greenKg > 0)
        ? (greenKg - roastedKg) / greenKg * 100
        : null;

    await ref.read(roastProfileLocalRepoProvider).save(RoastProfile(
      id:               '',
      lotId:            widget.lotId,
      roastedBy:        userId,
      roastedAt:        DateTime.now(),
      greenWeightKg:    greenKg,
      roastedWeightKg:  roastedKg,
      roastLossPct:     lossP,
      dropTempC:        double.tryParse(_dropTemp.text),
      developmentTimeS: devT,
      totalTimeS:       totalT,
      dtrPct:           dtrPct,
      agtronWhole:      int.tryParse(_agtron.text),
      colorLabel:       _colorLabel,
    ));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _greenKg.dispose(); _roastedKg.dispose(); _dropTemp.dispose();
    _devTime.dispose(); _totalTime.dispose(); _agtron.dispose();
    super.dispose();
  }
}

// ── Cupping Evaluation tab ───────────────────────────────────────────────────

class _CuppingEvaluationTab extends ConsumerWidget {
  const _CuppingEvaluationTab({required this.lotId});
  final String lotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<CuppingEvaluation>>(
      future: ref.read(cuppingEvaluationLocalRepoProvider).getByLotId(lotId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snap.data ?? [];
        if (items.isEmpty) {
          return _EmptyState(
            icon: Icons.coffee_outlined,
            label: 'Sin cataciones SCA',
            onAdd: () => _showForm(context, ref),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (_, i) => _CuppingEvaluationCard(item: items[i]),
        );
      },
    );
  }

  void _showForm(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CuppingEvaluationForm(lotId: lotId, ref: ref),
    );
  }
}

class _CuppingEvaluationCard extends StatelessWidget {
  const _CuppingEvaluationCard({required this.item});
  final CuppingEvaluation item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(_fmt(item.cuppedAt),
                style: Theme.of(context).textTheme.titleSmall),
            const Spacer(),
            if (item.totalScore != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _scoreColor(item.totalScore!),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  item.totalScore!.toStringAsFixed(2),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 4, children: [
            if (item.acidity != null)
              Chip(label: Text('Acidez ${item.acidity!.toStringAsFixed(1)}')),
            if (item.acidityIntensity != null)
              Chip(label: Text('Int.ácido ${item.acidityIntensity!.toStringAsFixed(1)}')),
            if (item.body != null)
              Chip(label: Text('Cuerpo ${item.body!.toStringAsFixed(1)}')),
            if (item.bodyTexture != null)
              Chip(label: Text('Textura ${item.bodyTexture!.toStringAsFixed(1)}')),
            if (item.balance != null)
              Chip(label: Text('Balance ${item.balance!.toStringAsFixed(1)}')),
            if (item.overall != null)
              Chip(label: Text('Overall ${item.overall!.toStringAsFixed(1)}')),
          ]),
          if (item.flavorDescriptors != null &&
              item.flavorDescriptors!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Descriptores:',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey[600])),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: _parseDescriptors(item.flavorDescriptors!)
                  .map((d) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.brown.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.brown.shade200),
                        ),
                        child: Text(d,
                            style: TextStyle(
                                fontSize: 11, color: Colors.brown.shade700)),
                      ))
                  .toList(),
            ),
          ],
          if (item.notes != null && item.notes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(item.notes!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey[600])),
          ],
        ]),
      ),
    );
  }

  List<String> _parseDescriptors(String raw) {
    try {
      final decoded = (raw.startsWith('['))
          ? (raw
              .replaceAll('[', '')
              .replaceAll(']', '')
              .replaceAll('"', '')
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList())
          : raw.split(',').map((s) => s.trim()).toList();
      return decoded;
    } catch (_) {
      return [raw];
    }
  }

  Color _scoreColor(double score) {
    if (score >= 90) return Colors.green.shade700;
    if (score >= 85) return Colors.green;
    if (score >= 80) return Colors.orange;
    return Colors.red;
  }

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

class _CuppingEvaluationForm extends ConsumerStatefulWidget {
  const _CuppingEvaluationForm({required this.lotId, required this.ref});
  final String lotId;
  final WidgetRef ref;

  @override
  ConsumerState<_CuppingEvaluationForm> createState() =>
      _CuppingEvaluationFormState();
}

// SCA Flavor Wheel descriptors (simplified for on-device use)
const _scaDescriptors = [
  'Floral', 'Jazmín', 'Rosa', 'Frutal', 'Cítrico', 'Limón', 'Naranja',
  'Manzana', 'Durazno', 'Cereza', 'Frutos rojos', 'Fruta tropical',
  'Mango', 'Maracuyá', 'Panela', 'Caramelo', 'Chocolate', 'Nuez',
  'Avellana', 'Almendra', 'Vainilla', 'Miel', 'Canela', 'Especias',
  'Herbal', 'Tabaco', 'Tostado', 'Ahumado', 'Cedro', 'Terroso',
];

class _CuppingEvaluationFormState extends ConsumerState<_CuppingEvaluationForm> {
  final _fragrance       = TextEditingController();
  final _flavor          = TextEditingController();
  final _aftertaste      = TextEditingController();
  final _acidity         = TextEditingController();
  final _acidityIntensity = TextEditingController();
  final _body            = TextEditingController();
  final _bodyTexture     = TextEditingController();
  final _balance         = TextEditingController();
  final _uniformity      = TextEditingController();
  final _cleanCup        = TextEditingController();
  final _sweetness       = TextEditingController();
  final _overall         = TextEditingController();
  final _notes           = TextEditingController();
  final Set<String> _selectedDescriptors = {};
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Catación SCA formal',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Escala 6–10 pts por atributo',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          _field(_fragrance,       'Fragancia/Aroma'),
          _field(_flavor,          'Sabor'),
          _field(_aftertaste,      'Postgusto'),
          Row(children: [
            Expanded(child: _field(_acidity,          'Acidez')),
            const SizedBox(width: 10),
            Expanded(child: _field(_acidityIntensity, 'Int. acidez')),
          ]),
          Row(children: [
            Expanded(child: _field(_body,         'Cuerpo')),
            const SizedBox(width: 10),
            Expanded(child: _field(_bodyTexture,  'Textura')),
          ]),
          _field(_balance,    'Balance'),
          _field(_uniformity, 'Uniformidad'),
          _field(_cleanCup,   'Taza limpia'),
          _field(_sweetness,  'Dulzura'),
          _field(_overall,    'Overall'),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Descriptores de sabor (SCA Flavor Wheel)',
                style: Theme.of(context).textTheme.bodySmall),
          ),
          const SizedBox(height: 6),
          StatefulBuilder(builder: (ctx, setS) => Wrap(
            spacing: 6, runSpacing: 6,
            children: _scaDescriptors.map((d) {
              final selected = _selectedDescriptors.contains(d);
              return FilterChip(
                label: Text(d, style: const TextStyle(fontSize: 12)),
                selected: selected,
                onSelected: (v) => setState(() {
                  if (v) { _selectedDescriptors.add(d); }
                  else   { _selectedDescriptors.remove(d); }
                }),
                selectedColor: Colors.brown.shade100,
                checkmarkColor: Colors.brown.shade700,
              );
            }).toList(),
          )),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Notas del cupper',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox.square(dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Guardar'),
          ),
        ]),
      ),
    );
  }

  Widget _field(TextEditingController c, String label) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: label,
              border: const OutlineInputBorder()),
        ),
      );

  double? _parse(TextEditingController c) => double.tryParse(c.text);

  Future<void> _save() async {
    setState(() => _saving = true);
    final userId = ref.read(currentUserIdProvider);
    final frag = _parse(_fragrance);
    final flav = _parse(_flavor);
    final aft  = _parse(_aftertaste);
    final acid = _parse(_acidity);
    final acidI = _parse(_acidityIntensity);
    final bod  = _parse(_body);
    final bodT = _parse(_bodyTexture);
    final bal  = _parse(_balance);
    final uni  = _parse(_uniformity);
    final cln  = _parse(_cleanCup);
    final swt  = _parse(_sweetness);
    final ovr  = _parse(_overall);

    final attrs = [frag, flav, aft, acid, bod, bal, uni, cln, swt, ovr]
        .whereType<double>()
        .toList();
    final total = attrs.isNotEmpty ? attrs.reduce((a, b) => a + b) + 36 : null;

    final descriptors = _selectedDescriptors.isNotEmpty
        ? _selectedDescriptors.join(', ')
        : null;

    await ref.read(cuppingEvaluationLocalRepoProvider).save(CuppingEvaluation(
      id:              '',
      lotId:           widget.lotId,
      cupperId:        userId,
      cuppedAt:        DateTime.now(),
      fragranceAroma:  frag,
      flavor:          flav,
      aftertaste:      aft,
      acidity:         acid,
      acidityIntensity: acidI,
      body:            bod,
      bodyTexture:     bodT,
      balance:         bal,
      uniformity:      uni,
      cleanCup:        cln,
      sweetness:       swt,
      overall:         ovr,
      totalScore:      total,
      flavorDescriptors: descriptors,
      notes:           _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    ));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _fragrance.dispose(); _flavor.dispose(); _aftertaste.dispose();
    _acidity.dispose(); _acidityIntensity.dispose();
    _body.dispose(); _bodyTexture.dispose();
    _balance.dispose(); _uniformity.dispose();
    _cleanCup.dispose(); _sweetness.dispose();
    _overall.dispose(); _notes.dispose();
    super.dispose();
  }
}

// ── Shared helpers ───────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.label, required this.onAdd});
  final IconData icon;
  final String label;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        Text(label, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('Registrar'),
        ),
      ]),
    );
  }
}
