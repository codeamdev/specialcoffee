import 'package:special_coffee/ai_engine/models/ai_context.dart';

/// Construye prompts estructurados para Gemini según el módulo activo.
/// Cada módulo expone solo las variables relevantes para evitar ruido en el modelo.
abstract final class PromptBuilder {
  // ── Instrucción de sistema compartida ────────────────────────────────────

  static const String systemInstruction = '''
Eres un experto en café de especialidad con certificación Q-Grader internacional y más de 15 años de experiencia en producción y preparación de café de origen en Colombia y Latinoamérica.

Tu misión es analizar los datos proporcionados y generar recomendaciones concretas, accionables y explicadas en lenguaje claro adaptado al rol del usuario.

REGLAS OBLIGATORIAS:
1. Responde EXCLUSIVAMENTE en formato JSON válido, sin texto adicional antes ni después.
2. Genera entre 1 y 4 recomendaciones ordenadas de mayor a menor urgencia.
3. El campo "explanation" debe estar en español, ser claro para el rol indicado y explicar el PORQUÉ de la recomendación.
4. El campo "alertLevel" solo puede ser: "none", "info", "warning", "high" o "critical".
5. El campo "confidence" es un número entre 0.0 y 1.0.
6. Si los datos son insuficientes para recomendar, devuelve una recomendación informativa con alertLevel "info".
7. Nunca inventes datos que no estén en el contexto.

FORMATO DE RESPUESTA:
{
  "recommendations": [
    {
      "action": "identificador_snake_case",
      "alertLevel": "none|info|warning|high|critical",
      "confidence": 0.0,
      "explanation": "Explicación en español para el rol del usuario",
      "suggestedActions": ["Acción concreta 1", "Acción concreta 2"]
    }
  ]
}
''';

  // ── Entry point principal ─────────────────────────────────────────────────

  /// Construye el prompt de usuario según el módulo del AIContext.
  static String build(AIContext ctx) => switch (ctx.module) {
        'fermentation'      => _fermentation(ctx),
        'process_selection' => _processSelection(ctx),
        'brewing'           => _brewing(ctx),
        'drying'            => _drying(ctx),
        'harvest'           => _harvest(ctx),
        _                   => _general(ctx),
      };

  // ── Módulo: Fermentación ──────────────────────────────────────────────────

  static String _fermentation(AIContext ctx) {
    final rolLabel = _roleLabel(ctx.userRole);
    final variety  = _varietyLabel(ctx.varietyId);
    final process  = _processLabel(ctx.processType);
    final mucilage = _mucilageLabel(ctx.mucilageState);

    return '''
ROL DEL USUARIO: $rolLabel

DATOS DEL LOTE:
- Variedad: $variety
- Proceso de beneficio: $process
- Altitud de la finca: ${ctx.altitudeMasl} m.s.n.m.
- Región: ${ctx.region.isNotEmpty ? ctx.region : 'No especificada'}
- Sensibilidad de la variedad a la fermentación: ${ctx.varietySensitivity}

LECTURA ACTUAL DE FERMENTACIÓN:
- pH del mucílago: ${ctx.currentPh > 0 ? ctx.currentPh.toStringAsFixed(2) : 'No medido'}
- Temperatura del mucílago: ${ctx.mucilagoTempC > 0 ? '${ctx.mucilagoTempC.toStringAsFixed(1)} °C' : 'No medida'}
- Horas transcurridas: ${ctx.fermentationHoursElapsed.toStringAsFixed(1)} h
- Estado visual del mucílago: $mucilage
- Estado general: ${ctx.fermentationStatus}

CONDICIONES AMBIENTALES ACTUALES:
- Temperatura ambiente: ${ctx.ambientTempC.toStringAsFixed(1)} °C
- Humedad relativa: ${ctx.ambientHumidityPct.toStringAsFixed(0)} %

HISTORIAL DEL PRODUCTOR:
- Lotes completados: ${ctx.userLotsCompleted}
- Promedio de horas de fermentación: ${ctx.userAvgFermentationH > 0 ? '${ctx.userAvgFermentationH.toStringAsFixed(0)} h' : 'Sin historial'}

PREGUNTA: Analiza el estado actual de la fermentación. ¿Está dentro del rango óptimo para este proceso y variedad? ¿Cuándo debería terminar? ¿Hay riesgos inminentes?
''';
  }

  // ── Módulo: Selección de proceso ─────────────────────────────────────────

  static String _processSelection(AIContext ctx) {
    final rolLabel = _roleLabel(ctx.userRole);
    final variety  = _varietyLabel(ctx.varietyId);

    return '''
ROL DEL USUARIO: $rolLabel

DATOS DE LA COSECHA / LOTE NUEVO:
- Variedad: $variety
- Sensibilidad de la variedad: ${ctx.varietySensitivity}
- Potencial SCA estimado de la variedad: ${ctx.varietyScaPotential} puntos
- Altitud: ${ctx.altitudeMasl} m.s.n.m.
- Región: ${ctx.region.isNotEmpty ? ctx.region : 'No especificada'}
- Proceso tentativo elegido por el productor: ${_processLabel(ctx.processType)}

CONDICIONES AMBIENTALES AL MOMENTO DE LA COSECHA:
- Temperatura ambiente: ${ctx.ambientTempC.toStringAsFixed(1)} °C
- Humedad relativa: ${ctx.ambientHumidityPct.toStringAsFixed(0)} %
- Probabilidad de lluvia próximas 48h: ${ctx.rainProbabilityPct.toStringAsFixed(0)} %

CALIDAD DE LA CEREZA:
- Brix de la cereza: ${ctx.brixLevel > 0 ? '${ctx.brixLevel.toStringAsFixed(1)} °Bx' : 'No medido'}
- Porcentaje de cereza roja/madura: ${ctx.cherryColorPct > 0 ? '${ctx.cherryColorPct}%' : 'No medido'}

HISTORIAL:
- Lotes completados por este productor: ${ctx.userLotsCompleted}
- Puntaje SCA promedio obtenido: ${ctx.userAvgSca > 0 ? '${ctx.userAvgSca.toStringAsFixed(1)} pts' : 'Sin historial'}

PREGUNTA: ¿El proceso elegido es el más adecuado para maximizar la calidad del café considerando la variedad, las condiciones actuales y el potencial del lote? Si hay un proceso mejor, explica por qué.
''';
  }

  // ── Módulo: Preparación / Brewing ────────────────────────────────────────

  static String _brewing(AIContext ctx) {
    final rolLabel = _roleLabel(ctx.userRole);
    final method   = _methodLabel(ctx.brewMethod);
    final roast    = _roastLabel(ctx.roastLevel);
    final process  = _processLabel(ctx.processType);

    final hasDiagnosis = ctx.measuredTdsPct > 0 || ctx.measuredYieldPct > 0;

    return '''
ROL DEL USUARIO: $rolLabel

MÉTODO DE PREPARACIÓN: $method

DATOS DEL CAFÉ:
- Nivel de tostión: $roast
- Días desde el tueste: ${ctx.roastDays > 0 ? '${ctx.roastDays} días' : 'No especificado'}
- Proceso de beneficio del café: $process
- Altitud de origen: ${ctx.altitudeMasl} m.s.n.m.
- Región de origen: ${ctx.region.isNotEmpty ? ctx.region : 'No especificada'}

CONDICIONES DE PREPARACIÓN:
- Altitud de preparación: ${ctx.altitudeMasl} m.s.n.m.
- Dureza del agua: ${ctx.waterHardnessPpm > 0 ? '${ctx.waterHardnessPpm.toStringAsFixed(0)} ppm' : 'No especificada'}

PERFIL GUSTATIVO DEL USUARIO:
- Preferencia por dulzor: ${(ctx.userSweetnessWeight * 100).toStringAsFixed(0)}%
- Preferencia por acidez: ${(ctx.userAcidityWeight * 100).toStringAsFixed(0)}%
- TDS objetivo personal: ${ctx.userPreferredTdsMin}% – ${ctx.userPreferredTdsMax}%

${hasDiagnosis ? '''
DIAGNÓSTICO POST-EXTRACCIÓN:
- TDS medido: ${ctx.measuredTdsPct.toStringAsFixed(2)}%
- Rendimiento de extracción: ${ctx.measuredYieldPct.toStringAsFixed(1)}%

PREGUNTA: Analiza si la extracción fue correcta. ¿Está el TDS y el rendimiento dentro del rango SCA (1.15–1.45% TDS, 18–22% rendimiento)? ¿Qué ajustes específicos recomiendas para la próxima extracción?
''' : '''
PREGUNTA: Con base en el método, el café y el perfil del usuario, ¿qué ajustes recomiendas sobre la receta base generada? ¿Hay algo del proceso o del tueste que afecte significativamente los parámetros óptimos?
'''}''';
  }

  // ── Módulo: Secado ───────────────────────────────────────────────────────

  static String _drying(AIContext ctx) {
    final rolLabel = _roleLabel(ctx.userRole);
    final process  = _processLabel(ctx.processType);

    return '''
ROL DEL USUARIO: $rolLabel

DATOS DEL SECADO:
- Proceso de beneficio: $process
- Día actual de secado: ${ctx.dryingDayNumber > 0 ? 'Día ${ctx.dryingDayNumber}' : 'Inicio'}
- Humedad actual del grano: ${ctx.currentHumidityPct > 0 ? '${ctx.currentHumidityPct.toStringAsFixed(1)}%' : 'No medida'}
- Meta de humedad final: 11.0% – 11.5% (estándar SCA)

CONDICIONES AMBIENTALES:
- Temperatura ambiente: ${ctx.ambientTempC.toStringAsFixed(1)} °C
- Humedad relativa: ${ctx.ambientHumidityPct.toStringAsFixed(0)} %
- Probabilidad de lluvia: ${ctx.rainProbabilityPct.toStringAsFixed(0)} %

DATOS DE LA FINCA:
- Altitud: ${ctx.altitudeMasl} m.s.n.m.
- Región: ${ctx.region.isNotEmpty ? ctx.region : 'No especificada'}

PREGUNTA: ¿Cómo va el proceso de secado? ¿Hay riesgos de sobre-secado, bajo-secado, o contaminación por humedad ambiental? ¿Qué cuidados específicos recomiendas para las próximas 24 horas?
''';
  }

  // ── Módulo: Cosecha ──────────────────────────────────────────────────────

  static String _harvest(AIContext ctx) {
    final rolLabel = _roleLabel(ctx.userRole);
    final variety  = _varietyLabel(ctx.varietyId);

    return '''
ROL DEL USUARIO: $rolLabel

DATOS DE LA COSECHA:
- Variedad: $variety
- Brix de la cereza: ${ctx.brixLevel > 0 ? '${ctx.brixLevel.toStringAsFixed(1)} °Bx' : 'No medido'}
- Porcentaje de cereza madura (roja): ${ctx.cherryColorPct > 0 ? '${ctx.cherryColorPct}%' : 'No medido'}
- Altitud: ${ctx.altitudeMasl} m.s.n.m.
- Región: ${ctx.region.isNotEmpty ? ctx.region : 'No especificada'}

CONDICIONES AL MOMENTO DE COSECHA:
- Temperatura: ${ctx.ambientTempC.toStringAsFixed(1)} °C
- Humedad: ${ctx.ambientHumidityPct.toStringAsFixed(0)} %

PREGUNTA: ¿El punto de madurez de la cereza es el adecuado para buscar café de especialidad? ¿Qué riesgos existen y qué recomendaciones tienes para la recolección?
''';
  }

  // ── Módulo: General ──────────────────────────────────────────────────────

  static String _general(AIContext ctx) {
    final rolLabel = _roleLabel(ctx.userRole);
    return '''
ROL DEL USUARIO: $rolLabel
MÓDULO: ${ctx.module}
REGIÓN: ${ctx.region.isNotEmpty ? ctx.region : 'No especificada'}
ALTITUD: ${ctx.altitudeMasl} m.s.n.m.

Analiza el contexto general y proporciona las recomendaciones más relevantes para este usuario en este momento.
''';
  }

  // ── Helpers de etiquetas ─────────────────────────────────────────────────

  static String _roleLabel(UserRole role) => switch (role) {
        UserRole.producer         => 'Productor de café (lenguaje práctico, enfoque en campo y proceso)',
        UserRole.coffeeMaster     => 'Coffee Master / Q Grader (lenguaje técnico de análisis físico y tueste)',
        UserRole.brandManager     => 'Brand Manager / Empresario cafetero (lenguaje de negocio + calidad)',
        UserRole.producerIntegral => 'Productor Integral (control farm-to-cup: campo + análisis + tueste)',
        UserRole.barista          => 'Barista / Preparador (lenguaje técnico de preparación)',
        UserRole.admin            => 'Administrador del sistema',
      };

  static String _varietyLabel(String id) => switch (id) {
        'var_geisha'       => 'Geisha (muy alta sensibilidad, potencial SCA 89+)',
        'var_pink_bourbon' => 'Pink Bourbon (alta sensibilidad, potencial SCA 88)',
        'var_typica'       => 'Typica (alta sensibilidad, potencial SCA 87)',
        'var_borbon'       => 'Borbón (alta sensibilidad, potencial SCA 86)',
        'var_caturra'      => 'Caturra (sensibilidad media-alta, potencial SCA 85)',
        'var_castillo'     => 'Castillo (sensibilidad media, potencial SCA 84)',
        'var_colombia'     => 'Colombia (sensibilidad media, potencial SCA 83)',
        _                  => 'Variedad no especificada',
      };

  static String _processLabel(String? process) => switch (process) {
        'lavado'           => 'Lavado (fermentación húmeda)',
        'natural'          => 'Natural (seco / pulpa incluida)',
        'honey_yellow'     => 'Honey Yellow (semi-lavado)',
        'honey_red'        => 'Honey Red (semi-lavado alto mucílago)',
        'honey_black'      => 'Honey Black (muy alto mucílago)',
        'anaerobic_lactic' => 'Anaeróbico láctico (fermentación controlada)',
        _                  => 'No especificado',
      };

  static String _mucilageLabel(String state) => switch (state) {
        'liquid'    => 'Líquido (mucílago muy fluido)',
        'viscous'   => 'Viscoso (mucílago espeso)',
        'gelatinous'=> 'Gelatinoso (en proceso de degradación)',
        'dry'       => 'Seco (mucílago casi degradado)',
        _           => 'No evaluado',
      };

  static String _methodLabel(String? method) => switch (method) {
        'v60'          => 'V60 (filtrado, limpio y delicado)',
        'chemex'       => 'Chemex (filtrado, sedoso)',
        'aeropress'    => 'Aeropress (presión, versátil)',
        'french_press' => 'Prensa francesa (inmersión, denso)',
        'espresso'     => 'Espresso (presión, concentrado)',
        'moka'         => 'Moka (vapor-presión, fuerte)',
        _              => 'Método no especificado',
      };

  static String _roastLabel(String level) => switch (level) {
        'light'  => 'Claro (origen preservado, alta acidez)',
        'medium' => 'Medio (balance acidez-cuerpo)',
        'dark'   => 'Oscuro (bajo acidez, cuerpo alto, notas a tueste)',
        _        => 'No especificado',
      };
}
