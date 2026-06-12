import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:special_coffee/core/config/gemini_config.dart';
import 'package:special_coffee/core/theme/app_colors.dart';
import 'package:special_coffee/core/theme/app_text_styles.dart';

// ── Knowledge base ──────────────────────────────────────────────────────────

class _Topic {
  const _Topic({required this.title, required this.icon, required this.tags, required this.content});
  final String title;
  final IconData icon;
  final List<String> tags;
  final String content;
}

const _topics = [
  _Topic(
    title: 'Cosecha y madurez',
    icon: Icons.eco_outlined,
    tags: ['cosecha', 'brix', 'madurez', 'cereza'],
    content:
        'La cosecha selectiva recoge solo cerezas maduras (rojas/amarillas). '
        'Indicadores de madurez:\n\n'
        '• °Brix óptimo: 18–24 °Bx (especialidad, SCA). < 15 °Bx = inmaduro. > 24 °Bx = sobremadurez.\n'
        '• Color: ≥ 95 % cerezas rojas/amarillas. 90–94.9 % = advertencia (verde 5–10 %). '
        '< 90 % = crítico (verde > 10 %).\n'
        '• Lluvia: si probabilidad ≥ 70 %, cosechar con urgencia para evitar fermentación '
        'en árbol y dilución de azúcares.\n\n'
        'Intervalos recomendados entre pases: 7–10 días en temporada alta (Cenicafé AT 420, 2012). '
        'Recolectores con recipientes limpios; sin mezclar variedades distintas.',
  ),
  _Topic(
    title: 'Flotación y clasificación',
    icon: Icons.water_outlined,
    tags: ['flotación', 'clasificación', 'defectos', 'densidad'],
    content:
        'Clasificación por densidad en agua (beneficio húmedo):\n\n'
        '• Granos flotantes = vanos, brocados, sobrefermentados o con daño físico.\n'
        '• < 20 % flotantes: normal. > 20 %: revisar calidad de cosecha. > 35 %: '
        'problema mayor — reproceso u rechazo del lote.\n'
        '• Aprovechamiento esperado (kg seleccionado / kg entrada): 60–75 % en cosecha '
        'selectiva colombiana. < 60 % = ineficiencia o exceso de defectos.\n\n'
        'Fuente: Manual del Cafetero Colombiano (FNC/Cenicafé).',
  ),
  _Topic(
    title: 'Despulpado',
    icon: Icons.settings_outlined,
    tags: ['despulpado', 'mucílago', 'fermentación'],
    content:
        'Despulpar el café el mismo día de la recolección.\n\n'
        '• Ideal: dentro de las 6 h desde la cosecha o clasificación.\n'
        '• > 6 h: riesgo de fermentación indeseada pre-despulpado (advertencia).\n'
        '• > 8 h: daño organoléptico probable — vinagre, fermento (crítico).\n\n'
        'Variedades sensibles (Geisha, Pink Bourbon): respetar ≤ 4–6 h por mayor fragilidad '
        'del mucílago. Calibrar la despulpadora según diámetro del grano para evitar cortes '
        'en el pergamino.\n\nFuente: Manual del Cafetero FNC/Cenicafé, 4ª ed.',
  ),
  _Topic(
    title: 'Fermentación: Lavado',
    icon: Icons.science_outlined,
    tags: ['fermentación', 'lavado', 'ph', 'temperatura', 'horas'],
    content:
        'Fermentación húmeda (mucílago sumergido en agua):\n\n'
        '• Duración típica colombiana: 16–36 h según altitud, temperatura y variedad.\n'
        '• pH objetivo al final: 4.0–5.0 (mucílago degradado). pH > 5.5 en efluente de '
        'lavado = fermentación incompleta.\n'
        '• Temperatura: mantener < 25 °C para control microbiológico. > 30 °C = '
        'proliferación bacteriana no deseada.\n'
        '• Señal de endpoint: el mucílago se despega completamente al frotar ("punto de '
        'lavado limpio").\n\n'
        'No alargar innecesariamente: > 36 h sin alcanzar punto de lavado = riesgo de '
        'sobre-fermentación (vinagre, alcohol).\n\nFuente: Manual del Cafetero FNC/Cenicafé.',
  ),
  _Topic(
    title: 'Fermentación: Honey',
    icon: Icons.hexagon_outlined,
    tags: ['honey', 'fermentación', 'mucílago', 'anaeróbico'],
    content:
        'Procesamiento honey: mucílago total o parcialmente retenido sobre el grano, '
        'sin agua.\n\n'
        '• Duración típica: 48–96 h (Colombia: Nariño/Huila). Variaciones: '
        'Yellow 72–96 h, Red 10–20 días con secado lento.\n'
        '• Temperatura: sin agua de enfriamiento, puede subir rápido. > 28 °C = '
        'riesgo de sobrecalentamiento del mucílago.\n'
        '• > 96 h = riesgo de sobrefermentación honey (alcohólico, fermento excesivo).\n'
        '• Endpoint: mucílago seco al tacto + ≥ 48 h transcurridas.\n\n'
        'Voltear el café cada 12–24 h para uniformizar y evitar encostrado. '
        'Secado inmediatamente tras alcanzar endpoint.\n'
        'Fuente: WCR + práctica procesadores Colombia.',
  ),
  _Topic(
    title: 'Fermentación: Anaeróbica',
    icon: Icons.lock_outlined,
    tags: ['anaeróbico', 'fermentación', 'ph', 'láctico', 'tanque'],
    content:
        'Proceso láctico en tanque sellado (anaerobic lactic):\n\n'
        '• pH objetivo: 3.8–4.2 (láctico limpio, especialidad).\n'
        '• pH < 3.8: actividad ácido-láctica intensa — monitorear. '
        'pH < 3.5: sobrefermentación irreversible (detener proceso).\n'
        '• Temperatura: < 20 °C para fermentación lenta y controlada '
        '(mayor complejidad aromática).\n'
        '• Duración mínima: 48 h para proceso completo. < 48 h = proceso incompleto.\n'
        '• Usar solo agua limpia y sin cloro; lavar el tanque entre lotes.\n\n'
        'Fuente: WCR Fermentation Research + práctica procesadores Colombia.',
  ),
  _Topic(
    title: 'Lavado del café',
    icon: Icons.water_drop_outlined,
    tags: ['lavado', 'agua', 'cambios', 'ph', 'temperatura'],
    content:
        'Remoción del mucílago post-fermentación con agua limpia:\n\n'
        '• Mínimo 2 cambios de agua. Estándar especialidad: 3 cambios completos.\n'
        '• Temperatura del agua: 15–30 °C. '
        '< 15 °C = lavado ineficiente (actividad enzimática reducida). '
        '> 30 °C = riesgo bacteriano.\n'
        '• pH del efluente de lavado: ≤ 5.5 indica fermentación completa y mucílago '
        'bien degradado. pH > 5.5 = mucílago sin degradar completamente.\n'
        '• Usar agua de fuente limpia y sin contaminantes. Tratar el agua residual '
        '(fosa de oxidación) para no contaminar fuentes hídricas.\n\n'
        'Fuente: Manual del Cafetero FNC/Cenicafé, cap. Beneficio Húmedo.',
  ),
  _Topic(
    title: 'Secado: solar y camas africanas',
    icon: Icons.wb_sunny_outlined,
    tags: ['secado', 'solar', 'patio', 'camas africanas', 'humedad'],
    content:
        'Rango de humedad objetivo (pergamino): 10.5–12.0 % (SCA). '
        '< 10 % = sobredesecado.\n\n'
        'Temperatura ambiental:\n'
        '• > 35 °C: riesgo de agrietamiento del grano (gradiente interno de vapor). '
        'Proteger con media sombra.\n\n'
        'Humedad relativa ambiental:\n'
        '• > 80 %: tasa de evaporación < reabsorción → secado ineficiente. '
        'Suspender o cubrír en lluvia.\n'
        '• > 85 %: riesgo de hongos (Aspergillus, Fusarium). Detener secado exterior.\n\n'
        'Volteo: desde el día 3 con grano > 40 % de humedad. Voltear cada 2–4 h '
        'para uniformizar el frente de secado y evitar encostrado superficial.\n\n'
        'Camas africanas: típicamente 15–20 días en Colombia. > 18 días con > 15 % '
        'HR = proceso muy lento (revisar carga o condiciones).\n\n'
        'Cómo medir humedad del café: higrómetro de inserción (Wile 55, Pfeuffer HE 50, '
        'Draminski). Introducir sonda en el grano, mantener 30 s.\n'
        'Cómo medir HR ambiental: termohigrómetro (Govee, Inkbird). Colocar a la sombra, '
        '1–1.5 m del suelo.\n\n'
        'Fuente: Manual del Cafetero FNC/Cenicafé + literatura Cenicafé de secado solar.',
  ),
  _Topic(
    title: 'Secado mecánico',
    icon: Icons.air_outlined,
    tags: ['secado', 'mecánico', 'temperatura', 'guarda'],
    content:
        'Secado en guardas o tambores con aire caliente forzado:\n\n'
        '• Temperatura del aire ≤ 40 °C: proceso eficiente sin daño.\n'
        '• > 40 °C con grano semiseco (< 30 % HR): acelera gradiente de humedad '
        '— advertencia de temperatura.\n'
        '• > 45 °C: fisuras internas ("grano cristalizado") — daño irreversible del '
        'endospermo. Detener de inmediato.\n'
        '• Día 5+ con > 30 % HR: proceso lento — revisar flujo de aire y temperatura.\n\n'
        'Ventaja: independiente del clima. Desventaja: costo energético y riesgo de '
        'sobre-temperatura sin control.\n\n'
        'Fuente: Manual del Cafetero Colombiano FNC/Cenicafé, 9ª ed., cap. Secado Mecánico.',
  ),
  _Topic(
    title: 'Trilla y rendimiento',
    icon: Icons.factory_outlined,
    tags: ['trilla', 'rendimiento', 'almendra', 'pergamino'],
    content:
        'Trilla: separación del pergamino para obtener almendra verde (café oro).\n\n'
        '• Rendimiento esperado: 18–22 % (kg almendra verde / kg pergamino seco).\n'
        '  - Castillo: ~20 %. Colombia: 19–21 %. Variedades especiales: 18–22 %.\n'
        '• < 18 %: pérdidas críticas — grano defectuoso, sobresecado o ajuste '
        'incorrecto de trilladora.\n'
        '• > 22 %: revisar pesaje (posible pergamino húmedo o equipo mal calibrado).\n\n'
        'Almacenar pergamino en sitio fresco y seco (HR < 65 %, temperatura estable). '
        'Sacos de fique o GrainPro para conservar la humedad.\n\n'
        'Fuente: SCA Coffee Standards; estudios Cenicafé por variedad.',
  ),
  _Topic(
    title: 'Agua para preparación',
    icon: Icons.water_outlined,
    tags: ['agua', 'tds', 'ph', 'dureza', 'sca'],
    content:
        'El agua representa ~98 % de una taza de café. Estándares SCA Water Quality Handbook (2018):\n\n'
        '• TDS (Total Dissolved Solids): óptimo 75–250 mg/L (ppm).\n'
        '  < 75 ppm = agua demasiado pura → subextracción (café plano).\n'
        '  > 250 ppm = dureza excesiva → sabor metálico, incrustaciones.\n\n'
        '• pH: óptimo 6.5–7.5.\n'
        '  < 6.5 = agua ácida → sobreextrae ácidos.\n'
        '  > 7.5 = agua alcalina → extracción plana (neutraliza acidez del café).\n\n'
        '• Dureza total: 50–175 mg/L CaCO₃ (recomendado SCA).\n'
        '• Sin cloro libre (filtraje con carbón activo o filtro de osmosis inversa).\n\n'
        'Cómo medir TDS del agua: TDS meter digital (HM Digital, Apera). '
        'Para café preparado: refractómetro óptico (Atago PAL-COFFEE, Difluid R2).\n\n'
        'Fuente: SCA Water Quality Handbook, 2018.',
  ),
  _Topic(
    title: 'TDS y extracción',
    icon: Icons.science_outlined,
    tags: ['tds', 'extracción', 'refractómetro', 'brewing', 'sca'],
    content:
        'TDS (Total Dissolved Solids) en café preparado: % de sólidos disueltos en la infusión.\n\n'
        'Rangos SCA:\n'
        '• Filtro (pour-over, french press, aeropress): 1.15–1.45 %.\n'
        '• Espresso: 8–12 % (concentrado, diferente escala).\n\n'
        'Cómo medir:\n'
        '• Refractómetro óptico (Atago PAL-COFFEE, Difluid R2, Vison): toma 2–3 gotas '
        'de café a temperatura ambiente sobre el prisma y lee directamente.\n'
        '• Algunos usan refractómetro Brix: convertir con factor de corrección '
        '(TDS ≈ Brix × 0.85 para filtro).\n\n'
        '• Por debajo del rango → subextracción (agrio, acuoso, corto en boca).\n'
        '• Por encima → sobreextracción (amargo astringente, áspero).\n\n'
        'Rendimiento de extracción (EY): EY (%) = TDS × volumen agua / masa café × 100. '
        'Rango SCA: 18–22 %.\n\n'
        'Fuente: SCA Brewing Standards (2019); Scott Rao, The Coffee Brewer\'s Companion.',
  ),
  _Topic(
    title: 'Tueste: frescura y reposo',
    icon: Icons.local_fire_department_outlined,
    tags: ['tueste', 'reposo', 'degassing', 'frescura', 'oxidación'],
    content:
        'El café recién tostado contiene CO₂ que interfiere con la extracción. '
        'Requiere un período de reposo ("degassing").\n\n'
        'Filtro (pour-over, V60, aeropress, french press):\n'
        '• Reposo ideal: 5–21 días post-tueste.\n'
        '• < 5 días: CO₂ residual interfiere con el bloom — extracción irregular.\n'
        '• > 45 días: oxidación significativa (rancio, plano).\n\n'
        'Espresso:\n'
        '• Reposo ideal: 10–30 días (espresso tolera más degassing).\n'
        '• < 10 días: café "cerrado", difícil extraer uniformemente.\n\n'
        'Almacenamiento: bolsa con válvula unidireccional, alejado de luz y humedad. '
        'Congelar solo si el café no se va a usar en más de 3 semanas (y no descongelar '
        'varias veces).\n\n'
        'Fuente: SCA Brewing Standards 2019; BH Education; Scott Rao.',
  ),
];

// ── System prompt para Q&A ──────────────────────────────────────────────────

const _qaSystemPrompt = '''
Eres un experto en café de especialidad colombiano, con énfasis en procesamiento, '
beneficio húmedo y seco, y preparación de café (brewing). Ayudas a caficultores, '
baristas, Q Graders y procesadores a entender la ciencia y la práctica detrás de '
cada etapa del café.

BASE DE CONOCIMIENTO (usa estos datos como referencia principal):

COSECHA: °Brix óptimo 18–24 Bx (SCA). Color: ≥95% cerezas maduras (FNC/Cenicafé). '
Lluvia ≥70%: cosechar urgente. Intervalos 7–10 días entre pases (Cenicafé AT 420).

FLOTACIÓN: >20% flotantes = revisar calidad. >35% = problema mayor. '
Aprovechamiento 60–75% (FNC/Cenicafé).

DESPULPADO: ≤6h post-cosecha ideal. >8h = daño organoléptico (Manual del Cafetero).

FERMENTACIÓN LAVADO: 16–36h Colombia. pH efluente ≤5.5. Temp <25°C (Manual del Cafetero).
FERMENTACIÓN HONEY: 48–96h. Temp <28°C. Endpoint: mucílago seco + ≥48h. (WCR/SCA).
FERMENTACIÓN ANAERÓBICA: pH objetivo 3.8–4.2. pH <3.5 = sobrefermentación. Temp <20°C. '
Mínimo 48h (WCR).

LAVADO: ≥2 cambios de agua (estándar: 3). Temp agua 15–30°C. pH efluente ≤5.5 (Manual).

SECADO SOLAR/CAMAS AFRICANAS: Meta 10.5–12% HR grano. >35°C ambiental = agrietamiento. '
>80% HR ambiental = ineficiente. >85% HR = riesgo hongos. Voltear desde día 3 con >40% HR. '
Camas africanas: 15–20 días. Higrómetro de grano: Wile 55, Pfeuffer HE 50, Draminski. '
Higrómetro ambiental: Govee, Inkbird, AcuRite. (Manual del Cafetero/Cenicafé).

SECADO MECÁNICO: ≤40°C OK. >40°C = advertencia. >45°C = fisuras internas (Manual 9a ed.).

TRILLA: Rendimiento 18–22% (almendra/pergamino). <18% = crítico. >22% = revisar pesaje (SCA).

AGUA PREPARACIÓN: TDS 75–250 ppm. pH 6.5–7.5. Sin cloro. (SCA Water Quality 2018).

TDS CAFÉ PREPARADO: Filtro 1.15–1.45%. Espresso 8–12%. Refractómetro: Atago PAL-COFFEE, '
Difluid R2. Rendimiento extracción 18–22% (SCA Brewing 2019).

TUESTE REPOSO: Filtro 5–21 días. Espresso 10–30 días. >45d filtro = oxidación (SCA/Scott Rao).

Responde siempre en español. Sé conciso, técnico y práctico. Si la pregunta no es sobre '
café o agronomía de café, redirige amablemente. Cita las fuentes cuando sea relevante.
''';

// ── Screen ──────────────────────────────────────────────────────────────────

class GlossaryScreen extends ConsumerStatefulWidget {
  const GlossaryScreen({super.key});

  @override
  ConsumerState<GlossaryScreen> createState() => _GlossaryScreenState();
}

class _GlossaryScreenState extends ConsumerState<GlossaryScreen> {
  final _searchCtrl    = TextEditingController();
  final _questionCtrl  = TextEditingController();
  final _scrollCtrl    = ScrollController();
  String _query        = '';
  String _answer       = '';
  bool   _isAsking     = false;
  String _error        = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    _questionCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  List<_Topic> get _filtered {
    if (_query.isEmpty) return _topics;
    final q = _query.toLowerCase();
    return _topics.where((t) =>
      t.title.toLowerCase().contains(q) ||
      t.content.toLowerCase().contains(q) ||
      t.tags.any((tag) => tag.contains(q)),
    ).toList();
  }

  Future<void> _askAI() async {
    final question = _questionCtrl.text.trim();
    if (question.isEmpty) return;
    if (!GeminiConfig.isConfigured) {
      setState(() => _error = 'Gemini no está configurado en esta instalación.');
      return;
    }
    setState(() { _isAsking = true; _answer = ''; _error = ''; });
    try {
      final model = GenerativeModel(
        model: GeminiConfig.model,
        apiKey: GeminiConfig.apiKey,
        systemInstruction: Content.system(_qaSystemPrompt),
        generationConfig: GenerationConfig(
          maxOutputTokens: 512,
          temperature: 0.3,
        ),
      );
      final response = await model.generateContent([Content.text(question)]);
      setState(() {
        _answer   = response.text ?? 'Sin respuesta.';
        _isAsking = false;
      });
    } catch (e) {
      setState(() {
        _error    = 'Error al consultar la IA: $e';
        _isAsking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Base de investigación')),
      body: ListView(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 48),
        children: [
          // ── Search bar ──────────────────────────────────────────────────
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Buscar: fermentación, TDS, secado…',
              hintStyle: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.onSurfaceVariant),
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.caramel, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Topic count ─────────────────────────────────────────────────
          if (_query.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                '${filtered.length} resultado${filtered.length != 1 ? 's' : ''}',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.onSurfaceVariant),
              ),
            ),

          // ── Topic cards ─────────────────────────────────────────────────
          if (filtered.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text('Sin resultados para "$_query"',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.onSurfaceVariant)),
              ),
            )
          else
            ...filtered.map((t) => _TopicCard(topic: t)),

          const SizedBox(height: 28),

          // ── AI Q&A ──────────────────────────────────────────────────────
          _AiQaSection(
            controller: _questionCtrl,
            answer:    _answer,
            error:     _error,
            isAsking:  _isAsking,
            onAsk:     _askAI,
          ),
        ],
      ),
    );
  }
}

// ── Topic card ───────────────────────────────────────────────────────────────

class _TopicCard extends StatefulWidget {
  const _TopicCard({required this.topic});
  final _Topic topic;

  @override
  State<_TopicCard> createState() => _TopicCardState();
}

class _TopicCardState extends State<_TopicCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
              decoration: BoxDecoration(
                color: _expanded
                    ? AppColors.caramel.withValues(alpha: 0.06)
                    : Colors.transparent,
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(14),
                  bottom: _expanded ? Radius.zero : const Radius.circular(14),
                ),
              ),
              child: Row(children: [
                Icon(widget.topic.icon, size: 18, color: AppColors.caramel),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(widget.topic.title,
                      style: AppTextStyles.labelLarge),
                ),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: AppColors.onSurfaceVariant,
                ),
              ]),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 2, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 16, color: AppColors.divider),
                  Text(widget.topic.content,
                      style: AppTextStyles.bodySmall
                          .copyWith(height: 1.55)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── AI Q&A section ───────────────────────────────────────────────────────────

class _AiQaSection extends StatelessWidget {
  const _AiQaSection({
    required this.controller,
    required this.answer,
    required this.error,
    required this.isAsking,
    required this.onAsk,
  });

  final TextEditingController controller;
  final String       answer;
  final String       error;
  final bool         isAsking;
  final VoidCallback onAsk;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.aiBlueContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppColors.aiBlue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.auto_awesome_rounded,
                size: 18, color: AppColors.aiBlue),
            const SizedBox(width: 8),
            Text('Pregunta a la IA',
                style: AppTextStyles.labelLarge
                    .copyWith(color: AppColors.aiBlue)),
          ]),
          const SizedBox(height: 4),
          Text(
            'Consulta sobre cualquier tema de la base de investigación. '
            'La IA responde con base en estándares FNC/Cenicafé y SCA.',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.aiBlue.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText:
                  '¿Cuánto tiempo debo fermentar un honey a 2000 m.s.n.m.?',
              hintStyle: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.onSurfaceVariant),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: AppColors.aiBlue, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isAsking ? null : onAsk,
              icon: isAsking
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded, size: 16),
              label: Text(
                isAsking ? 'Consultando…' : 'Preguntar',
                style: AppTextStyles.buttonMedium,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.aiBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          if (error.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(error,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.error)),
          ],
          if (answer.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.aiBlue.withValues(alpha: 0.25)),
              ),
              child: Text(answer,
                  style: AppTextStyles.bodySmall.copyWith(height: 1.6)),
            ),
          ],
        ],
      ),
    );
  }
}
