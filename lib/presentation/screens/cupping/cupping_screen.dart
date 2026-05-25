import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:special_coffee/ai_engine/models/ai_rule.dart';
import 'package:special_coffee/domain/entities/cupping_session.dart';
import 'package:special_coffee/presentation/providers/cupping_provider.dart';

class CuppingScreen extends ConsumerStatefulWidget {
  const CuppingScreen({super.key, required this.lotId});

  final String lotId;

  @override
  ConsumerState<CuppingScreen> createState() => _CuppingScreenState();
}

class _CuppingScreenState extends ConsumerState<CuppingScreen> {
  // ── SCA attribute sliders (6.0–10.0, 16 divisions of 0.25) ─────────────
  double _fragranceAroma = 7.5;
  double _flavor         = 7.5;
  double _aftertaste     = 7.5;
  double _acidity        = 7.5;
  double _body           = 7.5;
  double _balance        = 7.5;
  double _overall        = 7.5;

  // ── Intensity qualifiers ─────────────────────────────────────────────────
  String _acidityIntensity = 'medium';
  String _bodyLevel        = 'medium';

  // ── Cup counts (0–5) ────────────────────────────────────────────────────
  int _uniformityCups = 5;
  int _cleanCupCups   = 5;
  int _sweetnessCups  = 5;

  // ── Defects ──────────────────────────────────────────────────────────────
  int _defectsCat1 = 0;
  int _defectsCat2 = 0;

  // ── Meta ─────────────────────────────────────────────────────────────────
  DateTime _cuppedAt = DateTime.now();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  double get _liveScore => CuppingSession.computeScore(
        fragranceAroma:   _fragranceAroma,
        flavor:           _flavor,
        aftertaste:       _aftertaste,
        acidity:          _acidity,
        body:             _body,
        balance:          _balance,
        uniformityCups:   _uniformityCups,
        cleanCupCups:     _cleanCupCups,
        sweetnessCups:    _sweetnessCups,
        overall:          _overall,
        defectsCat1Count: _defectsCat1,
        defectsCat2Count: _defectsCat2,
      );

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context:     context,
      initialDate: _cuppedAt,
      firstDate:   DateTime(2020),
      lastDate:    DateTime.now(),
    );
    if (picked != null) setState(() => _cuppedAt = picked);
  }

  Future<void> _submit() async {
    await ref.read(cuppingProvider(widget.lotId).notifier).register(
          fragranceAroma:   _fragranceAroma,
          flavor:           _flavor,
          aftertaste:       _aftertaste,
          acidity:          _acidity,
          acidityIntensity: _acidityIntensity,
          body:             _body,
          bodyLevel:        _bodyLevel,
          balance:          _balance,
          uniformityCups:   _uniformityCups,
          cleanCupCups:     _cleanCupCups,
          sweetnessCups:    _sweetnessCups,
          overall:          _overall,
          defectsCat1Count: _defectsCat1,
          defectsCat2Count: _defectsCat2,
          cuppedAt:         _cuppedAt,
          notes:            _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cuppingProvider(widget.lotId));

    ref.listen<CuppingState>(cuppingProvider(widget.lotId), (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Catación SCA')),
      body: state.isComplete
          ? _ResultView(
              session:         state.session!,
              recommendations: state.recommendations,
              onBack:          () => context.pop(),
            )
          : _FormView(
              fragranceAroma:   _fragranceAroma,
              flavor:           _flavor,
              aftertaste:       _aftertaste,
              acidity:          _acidity,
              acidityIntensity: _acidityIntensity,
              body:             _body,
              bodyLevel:        _bodyLevel,
              balance:          _balance,
              overall:          _overall,
              uniformityCups:   _uniformityCups,
              cleanCupCups:     _cleanCupCups,
              sweetnessCups:    _sweetnessCups,
              defectsCat1:      _defectsCat1,
              defectsCat2:      _defectsCat2,
              liveScore:        _liveScore,
              cuppedAt:         _cuppedAt,
              notesController:  _notesController,
              isLoading:        state.isLoading,
              onChangeFrag:     (v) => setState(() => _fragranceAroma = v),
              onChangeFlavor:   (v) => setState(() => _flavor = v),
              onChangeAfter:    (v) => setState(() => _aftertaste = v),
              onChangeAcidity:  (v) => setState(() => _acidity = v),
              onChangeAcidityI: (v) => setState(() => _acidityIntensity = v),
              onChangeBody:     (v) => setState(() => _body = v),
              onChangeBodyL:    (v) => setState(() => _bodyLevel = v),
              onChangeBalance:  (v) => setState(() => _balance = v),
              onChangeOverall:  (v) => setState(() => _overall = v),
              onChangeUniform:  (v) => setState(() => _uniformityCups = v),
              onChangeClean:    (v) => setState(() => _cleanCupCups = v),
              onChangeSweet:    (v) => setState(() => _sweetnessCups = v),
              onChangeDef1:     (v) => setState(() => _defectsCat1 = v),
              onChangeDef2:     (v) => setState(() => _defectsCat2 = v),
              onPickDate:       _pickDate,
              onSubmit:         _submit,
            ),
    );
  }
}

// ── Form ─────────────────────────────────────────────────────────────────────

class _FormView extends StatelessWidget {
  const _FormView({
    required this.fragranceAroma,
    required this.flavor,
    required this.aftertaste,
    required this.acidity,
    required this.acidityIntensity,
    required this.body,
    required this.bodyLevel,
    required this.balance,
    required this.overall,
    required this.uniformityCups,
    required this.cleanCupCups,
    required this.sweetnessCups,
    required this.defectsCat1,
    required this.defectsCat2,
    required this.liveScore,
    required this.cuppedAt,
    required this.notesController,
    required this.isLoading,
    required this.onChangeFrag,
    required this.onChangeFlavor,
    required this.onChangeAfter,
    required this.onChangeAcidity,
    required this.onChangeAcidityI,
    required this.onChangeBody,
    required this.onChangeBodyL,
    required this.onChangeBalance,
    required this.onChangeOverall,
    required this.onChangeUniform,
    required this.onChangeClean,
    required this.onChangeSweet,
    required this.onChangeDef1,
    required this.onChangeDef2,
    required this.onPickDate,
    required this.onSubmit,
  });

  final double fragranceAroma, flavor, aftertaste, acidity, body, balance, overall;
  final String acidityIntensity, bodyLevel;
  final int    uniformityCups, cleanCupCups, sweetnessCups, defectsCat1, defectsCat2;
  final double liveScore;
  final DateTime cuppedAt;
  final TextEditingController notesController;
  final bool isLoading;

  final ValueChanged<double> onChangeFrag, onChangeFlavor, onChangeAfter,
      onChangeAcidity, onChangeBody, onChangeBalance, onChangeOverall;
  final ValueChanged<String> onChangeAcidityI, onChangeBodyL;
  final ValueChanged<int>    onChangeUniform, onChangeClean, onChangeSweet,
      onChangeDef1, onChangeDef2;
  final VoidCallback onPickDate, onSubmit;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(child: _ScoreChip(score: liveScore)),
        const SizedBox(height: 20),

        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Fecha de catación'),
          subtitle: Text(DateFormat('dd/MM/yyyy').format(cuppedAt)),
          trailing: const Icon(Icons.calendar_today_outlined),
          onTap: onPickDate,
        ),
        const Divider(),

        const _SectionHeader('Atributos SCA (6.0 – 10.0)'),
        _ScaSlider('Fragancia / Aroma', fragranceAroma, onChangeFrag),
        _ScaSlider('Sabor',             flavor,         onChangeFlavor),
        _ScaSlider('Sabor residual',    aftertaste,     onChangeAfter),
        _ScaSlider('Acidez',            acidity,        onChangeAcidity),
        _IntensityPicker(
          label:     'Intensidad de acidez',
          value:     acidityIntensity,
          options:   const ['low', 'medium', 'high'],
          labels:    const ['Baja', 'Media', 'Alta'],
          onChanged: onChangeAcidityI,
        ),
        _ScaSlider('Cuerpo',   body,    onChangeBody),
        _IntensityPicker(
          label:     'Nivel de cuerpo',
          value:     bodyLevel,
          options:   const ['light', 'medium', 'heavy'],
          labels:    const ['Ligero', 'Medio', 'Pesado'],
          onChanged: onChangeBodyL,
        ),
        _ScaSlider('Balance', balance, onChangeBalance),
        _ScaSlider('General', overall, onChangeOverall),

        const SizedBox(height: 12),
        const _SectionHeader('Tazas (0 – 5 tazas)'),
        _CupStepper('Uniformidad', uniformityCups, onChangeUniform),
        _CupStepper('Taza limpia', cleanCupCups,   onChangeClean),
        _CupStepper('Dulzura',     sweetnessCups,  onChangeSweet),

        const SizedBox(height: 12),
        const _SectionHeader('Defectos'),
        _DefectCounter('Categoría 1 (×4 pts)', defectsCat1, onChangeDef1),
        _DefectCounter('Categoría 2 (×2 pts)', defectsCat2, onChangeDef2),

        const SizedBox(height: 12),
        const _SectionHeader('Notas (opcional)'),
        TextField(
          controller: notesController,
          maxLines:   3,
          decoration: const InputDecoration(
            hintText: 'Observaciones generales…',
            border:   OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 24),
        FilledButton(
          onPressed: isLoading ? null : onSubmit,
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width:  20,
                  child:  CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Registrar catación'),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

// ── Result ────────────────────────────────────────────────────────────────────

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.session,
    required this.recommendations,
    required this.onBack,
  });

  final CuppingSession        session;
  final List<Recommendation>  recommendations;
  final VoidCallback          onBack;

  Color _scoreColor(double s) => s >= 90
      ? Colors.green.shade700
      : s >= 80
          ? Colors.lightGreen.shade600
          : Colors.orange.shade700;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: Column(
            children: [
              Text(
                session.totalScore.toStringAsFixed(2),
                style: TextStyle(
                  fontSize:   52,
                  fontWeight: FontWeight.bold,
                  color:      _scoreColor(session.totalScore),
                ),
              ),
              Text(
                session.scaCategory,
                style: TextStyle(fontSize: 18, color: _scoreColor(session.totalScore)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Desglose', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _AttrRow('Fragancia/Aroma', session.fragranceAroma),
                _AttrRow('Sabor',           session.flavor),
                _AttrRow('Sabor residual',  session.aftertaste),
                _AttrRow('Acidez',          session.acidity),
                _AttrRow('Cuerpo',          session.body),
                _AttrRow('Balance',         session.balance),
                _AttrRow('Uniformidad',     session.uniformityScore),
                _AttrRow('Taza limpia',     session.cleanCupScore),
                _AttrRow('Dulzura',         session.sweetnessScore),
                _AttrRow('General',         session.overall),
                if (session.defectsCat1Count > 0 || session.defectsCat2Count > 0) ...[
                  const Divider(),
                  _AttrRow(
                    'Penalización defectos',
                    -(session.defectsCat1Count * 4.0 + session.defectsCat2Count * 2.0),
                    isNegative: true,
                  ),
                ],
              ],
            ),
          ),
        ),

        if (recommendations.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Recomendaciones IA', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...recommendations.map(
            (r) => Card(
              color: r.alertLevel == AlertLevel.warning
                  ? Colors.orange.shade50
                  : Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.explanation, style: const TextStyle(fontSize: 14)),
                    if (r.suggestedActions.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ...r.suggestedActions.map(
                        (a) => Padding(
                          padding: const EdgeInsets.only(left: 8, top: 2),
                          child: Row(
                            children: [
                              const Icon(Icons.arrow_right, size: 16),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(a, style: const TextStyle(fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],

        const SizedBox(height: 24),
        OutlinedButton(onPressed: onBack, child: const Text('Volver al lote')),
        const SizedBox(height: 32),
      ],
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({required this.score});
  final double score;

  Color get _color => score >= 90
      ? Colors.green.shade700
      : score >= 80
          ? Colors.lightGreen.shade600
          : Colors.orange.shade700;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color:        _color.withValues(alpha: 0.12),
        border:       Border.all(color: _color),
        borderRadius: BorderRadius.circular(24),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text:  score.toStringAsFixed(2),
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _color),
            ),
            TextSpan(
              text:  ' pts',
              style: TextStyle(fontSize: 14, color: _color),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Text(title, style: Theme.of(context).textTheme.titleSmall),
      );
}

class _ScaSlider extends StatelessWidget {
  const _ScaSlider(this.label, this.value, this.onChanged);
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 140,
              child: Text(label, style: const TextStyle(fontSize: 13)),
            ),
            Expanded(
              child: Slider(
                value:     value,
                min:       6.0,
                max:       10.0,
                divisions: 16,
                onChanged: onChanged,
              ),
            ),
            SizedBox(
              width: 36,
              child: Text(
                value.toStringAsFixed(2),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
}

class _IntensityPicker extends StatelessWidget {
  const _IntensityPicker({
    required this.label,
    required this.value,
    required this.options,
    required this.labels,
    required this.onChanged,
  });

  final String              label;
  final String              value;
  final List<String>        options;
  final List<String>        labels;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 4),
            SegmentedButton<String>(
              segments: List.generate(
                options.length,
                (i) => ButtonSegment(value: options[i], label: Text(labels[i])),
              ),
              selected:           {value},
              onSelectionChanged: (s) => onChanged(s.first),
              style: const ButtonStyle(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      );
}

class _CupStepper extends StatelessWidget {
  const _CupStepper(this.label, this.value, this.onChanged);
  final String            label;
  final int               value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(
              width: 140,
              child: Text(label, style: const TextStyle(fontSize: 13)),
            ),
            IconButton(
              icon:      const Icon(Icons.remove_circle_outline),
              onPressed: value > 0 ? () => onChanged(value - 1) : null,
            ),
            Text('$value / 5', style: const TextStyle(fontWeight: FontWeight.w600)),
            IconButton(
              icon:      const Icon(Icons.add_circle_outline),
              onPressed: value < 5 ? () => onChanged(value + 1) : null,
            ),
          ],
        ),
      );
}

class _DefectCounter extends StatelessWidget {
  const _DefectCounter(this.label, this.value, this.onChanged);
  final String            label;
  final int               value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(
              width: 180,
              child: Text(label, style: const TextStyle(fontSize: 13)),
            ),
            IconButton(
              icon:      const Icon(Icons.remove_circle_outline),
              onPressed: value > 0 ? () => onChanged(value - 1) : null,
            ),
            Text('$value', style: const TextStyle(fontWeight: FontWeight.w600)),
            IconButton(
              icon:      const Icon(Icons.add_circle_outline),
              onPressed: () => onChanged(value + 1),
            ),
          ],
        ),
      );
}

class _AttrRow extends StatelessWidget {
  const _AttrRow(this.label, this.value, {this.isNegative = false});
  final String label;
  final double value;
  final bool   isNegative;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13)),
            Text(
              value.toStringAsFixed(2),
              style: TextStyle(
                fontSize:   13,
                fontWeight: FontWeight.w600,
                color:      isNegative ? Colors.red : null,
              ),
            ),
          ],
        ),
      );
}
