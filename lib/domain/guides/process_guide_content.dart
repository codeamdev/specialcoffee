/// Contenido educativo estático para cada módulo de proceso.
/// No requiere red — funciona 100% offline.
abstract final class ProcessGuideContent {
  // ── LOT CREATION ───────────────────────────────────────────────────────────

  static const Map<String, CoffeeProcessInfo> processTypes = {
    'lavado': CoffeeProcessInfo(
      name: 'Proceso Lavado',
      icon: '💧',
      duration: '20–36 horas de fermentación + 10–15 días de secado',
      description:
          'Se despulpa el café y se fermenta en agua o en seco para eliminar el mucílago. '
          'Produce tazas limpias, brillantes y con acidez pronunciada. '
          'Ideal para resaltar el origen y la variedad.',
      steps: [
        'Despulpar dentro de las 6–12 h después de la cosecha',
        'Fermentar en tanque con agua (o en seco) durante 20–36 h',
        'Lavar con agua limpia hasta que el grano "cante" (no quede pegajoso)',
        'Secar en camas africanas o patio hasta 10.5–12% de humedad',
      ],
      keyParams: [
        ProcessParam('pH inicial', '6.0–6.5', 'Al inicio de la fermentación'),
        ProcessParam('pH final', '3.8–4.2', 'Punto de parada — evita sobre-fermentación'),
        ProcessParam('Temperatura', '18–25 °C', 'Más calor = fermentación más rápida'),
        ProcessParam('Tiempo', '20–36 h', 'Varía según altitud y temperatura'),
      ],
      tips: [
        'A mayor altitud (> 1800 m) la fermentación es más lenta — puede tardar 36+ h',
        'Cubrir el tanque en la noche evita contaminación por insectos',
        'Controla el pH cada 4–6 h para no sobre-fermentar',
      ],
      warning: 'Si el pH baja de 3.8, detén la fermentación inmediatamente — '
          'el café tendrá sabores vinagres o pútridos.',
    ),

    'natural': CoffeeProcessInfo(
      name: 'Proceso Natural',
      icon: '☀️',
      duration: '3–6 semanas de secado total (con pulpa)',
      description:
          'El café se seca con la pulpa intacta. El azúcar de la pulpa fermenta lentamente '
          'y penetra el grano, generando sabores frutados, dulces y vínicos. '
          'Requiere control cuidadoso para evitar defectos.',
      steps: [
        'Seleccionar solo cerezas maduras y rojas (mínimo 90% madurez)',
        'Extender en camas africanas en capas delgadas (< 4 cm)',
        'Voltear cada 1–2 horas en los primeros 3 días',
        'Cubrir en las noches con plástico transpirable',
        'Secar 3–6 semanas hasta 10.5–12% de humedad',
      ],
      keyParams: [
        ProcessParam('Madurez cerezas', '≥ 90%', 'Clave para sabores dulces sin defectos'),
        ProcessParam('Capa de secado', '< 4 cm', 'Capas gruesas = riesgo de moho'),
        ProcessParam('Volteos día 1–3', 'Cada 1–2 h', 'Evita fermentación anaeróbica no deseada'),
        ProcessParam('Humedad final', '10.5–12%', 'Igual que lavado — tarda más en llegar'),
      ],
      tips: [
        'Un café natural mal manejado puede arruinar todo el lote — requiere más atención que el lavado',
        'La lluvia es el mayor enemigo — siempre ten cubierta disponible',
        'El olor a "fermentado limpio" es buena señal; olor a vinagre o putrefacción = defecto',
      ],
      warning: 'Nunca acumules cerezas en capas gruesas los primeros días — '
          'el calor interno puede causar moho y sobre-fermentación.',
    ),

    'honey_yellow': CoffeeProcessInfo(
      name: 'Proceso Honey',
      icon: '🍯',
      duration: '20–35 días de secado (con algo de mucílago)',
      description:
          'Término medio entre lavado y natural. Se despulpa pero se deja parte del mucílago '
          '(pulpa). Yellow Honey = poco mucílago (20–40%), Red Honey = más (60–80%), '
          'Black Honey = casi todo. Sabores entre dulzura y limpieza.',
      steps: [
        'Despulpar ajustando la máquina para dejar el % de mucílago deseado',
        'Extender en camas africanas inmediatamente',
        'Voltear frecuentemente los primeros 5 días (cada 2–3 h)',
        'Reducir volteos en la segunda semana',
        'Secar hasta 10.5–12% (20–35 días según mucílago)',
      ],
      keyParams: [
        ProcessParam('Mucílago', '20–80%', 'Define el "color" Honey y el perfil de taza'),
        ProcessParam('Volteos iniciales', 'Cada 2–3 h', 'Clave para secado uniforme'),
        ProcessParam('Temperatura cama', '< 40 °C', 'Más calor seca desigual'),
        ProcessParam('Tiempo', '20–35 días', 'Depende del % de mucílago'),
      ],
      tips: [
        'El mucílago actúa como pegamento — volteos constantes evitan que el café se apelozone',
        'Observa el color: debe cambiar de amarillo brillante a marrón oscuro gradualmente',
        'El mucílago protege el grano — menos sensible a lluvia corta que el natural',
      ],
      warning: 'Si el café se pega entre sí en la cama, no tienes suficientes volteos '
          '— aumenta la frecuencia o reduce la capa.',
    ),

    'anaerobic_lactic': CoffeeProcessInfo(
      name: 'Proceso Anaeróbico',
      icon: '🔬',
      duration: '48–120 horas en tanque sellado + secado variable',
      description:
          'El café fermenta en ausencia de oxígeno, generando ácido láctico y '
          'compuestos aromáticos únicos. Produce sabores complejos, tropicales y '
          'con notas fermentadas controladas. Proceso experimental — requiere más control.',
      steps: [
        'Llenar tanque sellado con cerezas (o pergamino despulpado)',
        'Purgar el oxígeno con CO₂ o sellar herméticamente',
        'Monitorear pH y temperatura cada 8–12 h',
        'Detener cuando pH llegue a 3.5–3.8 (48–120 h dependiendo)',
        'Lavar y secar normalmente',
      ],
      keyParams: [
        ProcessParam('pH objetivo', '3.5–3.8', 'Más bajo = más acidez lática en taza'),
        ProcessParam('Temperatura', '16–22 °C', 'Más frío = proceso más lento y controlado'),
        ProcessParam('Tiempo', '48–120 h', 'Variable — controla con pH, no con tiempo'),
        ProcessParam('Presión CO₂', 'Liberar cada 12 h', 'Previene explosiones en el tanque'),
      ],
      tips: [
        'Usa un airlock (válvula de escape) para dejar salir CO₂ sin que entre O₂',
        'La temperatura es el control más importante — refrigerador = proceso lento y limpio',
        'Documenta cada experimento — este proceso necesita calibración por finca',
      ],
      warning: 'Si el tanque huele a acetona, azufre o "rancio" — el lote tiene defectos. '
          'No lo mezcles con otros cafés.',
    ),
  };

  // ── FERMENTATION GUIDE ─────────────────────────────────────────────────────

  static const List<FermentationPhase> fermentationPhases = [
    FermentationPhase(
      phRange: (6.5, 5.0),
      hoursRange: (0, 6),
      name: 'Inicio',
      icon: '🟢',
      whatHappens:
          'El café recién despulpado comienza a fermentar. Los microorganismos '
          'naturales empiezan a consumir el mucílago. El pH baja lentamente.',
      whatToDo: [
        'Registra el pH inicial (debe estar entre 6.0–6.5)',
        'Anota la temperatura del ambiente',
        'Asegúrate de que el tanque esté limpio y sin residuos',
        'Si es lavado: llena con agua limpia hasta cubrir el café',
      ],
      nextReadingIn: '4–6 horas',
      warningSign: 'pH > 7.0 → el café puede estar contaminado con agua sucia',
    ),
    FermentationPhase(
      phRange: (5.0, 4.2),
      hoursRange: (6, 18),
      name: 'Fermentación activa',
      icon: '🟡',
      whatHappens:
          'El pH baja rápidamente. Verás burbujas activas y el mucílago se ablanda. '
          'Esta es la fase más crítica — el café puede pasar de óptimo a sobre-fermentado '
          'en pocas horas si no se monitorea.',
      whatToDo: [
        'Registra pH y temperatura cada 4–6 horas',
        'Revisa el mucílago: debe sentirse cada vez más suelto',
        'Si la temperatura ambiente sube de 28°C, considera enfriar el tanque',
        'Observa el color del agua — debe aclararse gradualmente',
      ],
      nextReadingIn: '4–6 horas',
      warningSign: 'pH bajando muy rápido (> 0.5 unidades/hora) → fermentación acelerada, '
          'reduce temperatura o saca antes',
    ),
    FermentationPhase(
      phRange: (4.2, 3.8),
      hoursRange: (18, 30),
      name: 'Zona óptima',
      icon: '✅',
      whatHappens:
          'El café está en su punto ideal. El mucílago está casi completamente degradado. '
          'Si haces el "test del grano" — frotando el café entre las manos — '
          'debe sentirse rugoso, no pegajoso.',
      whatToDo: [
        'Monitorea cada 2–3 horas — estás cerca del punto ideal',
        'Haz el test táctil: toma un puñado y frótalo — ¿ya no está pegajoso?',
        'Prepara el área de lavado para estar listo cuando el pH llegue a 4.0',
        'Si el café "canta" (sonido crujiente al frotarlo) → listo para lavar',
      ],
      nextReadingIn: '2–3 horas',
      warningSign: 'pH < 3.8 → ¡Actúa ya! Lava inmediatamente — sobre-fermentación inminente',
    ),
    FermentationPhase(
      phRange: (3.8, 3.0),
      hoursRange: (30, 48),
      name: 'Alerta — límite',
      icon: '🔴',
      whatHappens:
          'El café está llegando o pasando el límite. El mucílago puede estar '
          'completamente degradado. Riesgo alto de notas vinagres, pútridas '
          'o alcohólicas en taza.',
      whatToDo: [
        '¡LAVAR EL CAFÉ INMEDIATAMENTE si pH ≤ 3.8!',
        'Si ya lavaste: verifica que el agua de lavado salga limpia y sin espuma',
        'Registra el pH final de lavado para tu historial',
        'Coloca en camas de secado lo antes posible',
      ],
      nextReadingIn: '1 hora o menos',
      warningSign: 'pH < 3.5 → el lote tiene riesgo alto de defectos — evalúa si vale la pena salvarlo',
    ),
  ];

  // ── DRYING GUIDE ───────────────────────────────────────────────────────────

  static const List<DryingPhase> dryingPhases = [
    DryingPhase(
      moistureRange: (55, 35),
      daysRange: (1, 5),
      name: 'Secado inicial',
      icon: '💦',
      whatHappens:
          'El café pierde humedad rápidamente. La superficie se seca '
          'pero el interior todavía tiene mucha agua. '
          'Esta fase define la base de calidad del secado.',
      whatToDo: [
        'Extender en capas delgadas (< 3 cm) para máxima exposición al sol',
        'Voltear cada 30–60 minutos los primeros 2 días',
        'Cubrir con malla o plástico transpirable en las noches',
        'Registrar temperatura, humedad y % humedad del café cada día',
      ],
      nextReadingIn: '24 horas (cada día)',
      warning: 'No expongas el café recién lavado al sol intenso directo '
          'las primeras horas — puede causar "costra" exterior con interior húmedo',
    ),
    DryingPhase(
      moistureRange: (35, 20),
      daysRange: (5, 12),
      name: 'Secado medio',
      icon: '🌤️',
      whatHappens:
          'El café tiene consistencia semi-dura. '
          'La pérdida de humedad es más lenta. '
          'El riesgo de moho disminuye pero el de sobre-secado aumenta si hay días muy secos.',
      whatToDo: [
        'Reducir volteos a 3–4 veces por día',
        'Verificar que no haya granos con moho (manchas blancas o negras)',
        'Si llueve: cubrir inmediatamente y esperar 1–2 horas después de que pare',
        'Medir con higrómetro de granos cada día',
      ],
      nextReadingIn: '24 horas',
      warning: 'Si la humedad ambiente supera 85%, el café puede re-humedecerse — '
          'mueve a un área cubierta ventilada',
    ),
    DryingPhase(
      moistureRange: (20, 10.5),
      daysRange: (12, 20),
      name: 'Etapa final — zona crítica',
      icon: '⚡',
      whatHappens:
          'El café está casi listo. El pergamino suena seco al agitar el grano. '
          'La diferencia entre 11% y 9% de humedad puede significar '
          'la diferencia entre un café perfecto y uno quebradizo.',
      whatToDo: [
        'Medir humedad dos veces al día con higrómetro',
        'Cuando llegue a 11–12%: retira muestras y déjalas reposar 30 min antes de medir de nuevo',
        'El grano debe sentirse completamente duro al presionarlo con la uña',
        'Preparar almacenamiento: bolsa GrainPro, bodega < 20°C y < 60% HR',
      ],
      nextReadingIn: '12 horas',
      warning: 'No midas justo después de voltear — espera 30 min para una lectura estable',
    ),
    DryingPhase(
      moistureRange: (12, 10.5),
      daysRange: (0, 0),
      name: '✅ Punto de cosecha — listo para almacenar',
      icon: '🎯',
      whatHappens:
          'El café alcanzó el rango SCA óptimo (10.5–12% humedad). '
          'El pergamino suena al golpear los granos entre sí. '
          'El grano es completamente duro y uniforme.',
      whatToDo: [
        'Registrar peso final (comparar con peso húmedo inicial)',
        'Empacar inmediatamente en bolsa GrainPro bien sellada',
        'Etiquetar: variedad, proceso, fecha cosecha, fecha secado, % humedad final',
        'Reposar mínimo 30 días en bodega antes de trillar',
        '¡Registra todos los datos en la app para construir tu historial!',
      ],
      nextReadingIn: 'N/A — secado completo',
      warning: 'El reposo post-secado es obligatorio — el café necesita estabilizarse '
          'antes de ser trillado para evitar quebrado del grano.',
    ),
  ];

  // ── HELPERS ────────────────────────────────────────────────────────────────

  static FermentationPhase? currentFermentationPhase(double ph) {
    for (final phase in fermentationPhases) {
      if (ph <= phase.phRange.$1 && ph > phase.phRange.$2) return phase;
    }
    return fermentationPhases.last;
  }

  static DryingPhase? currentDryingPhase(double moisturePct) {
    for (final phase in dryingPhases) {
      if (moisturePct >= phase.moistureRange.$2 &&
          moisturePct <= phase.moistureRange.$1) return phase;
    }
    if (moisturePct > 55) return dryingPhases.first;
    return dryingPhases.last;
  }

  static String nextFermentationReadingHint(
      double currentPh, double hoursElapsed) {
    if (currentPh > 5.0) return 'Próxima lectura: en 4–6 horas';
    if (currentPh > 4.2) return 'Próxima lectura: en 4–6 horas';
    if (currentPh > 3.8) return 'Próxima lectura: en 2–3 horas — ¡ya casi!';
    return 'Próxima lectura: en 1 hora o menos — ¡zona crítica!';
  }
}

// ── Data models ────────────────────────────────────────────────────────────

class CoffeeProcessInfo {
  final String name;
  final String icon;
  final String duration;
  final String description;
  final List<String> steps;
  final List<ProcessParam> keyParams;
  final List<String> tips;
  final String warning;

  const CoffeeProcessInfo({
    required this.name,
    required this.icon,
    required this.duration,
    required this.description,
    required this.steps,
    required this.keyParams,
    required this.tips,
    required this.warning,
  });
}

class ProcessParam {
  final String name;
  final String value;
  final String note;
  const ProcessParam(this.name, this.value, this.note);
}

class FermentationPhase {
  final (double, double) phRange;    // (upper, lower) — pH decreases
  final (int, int)       hoursRange;
  final String           name;
  final String           icon;
  final String           whatHappens;
  final List<String>     whatToDo;
  final String           nextReadingIn;
  final String           warningSign;

  const FermentationPhase({
    required this.phRange,
    required this.hoursRange,
    required this.name,
    required this.icon,
    required this.whatHappens,
    required this.whatToDo,
    required this.nextReadingIn,
    required this.warningSign,
  });
}

class DryingPhase {
  final (double, double) moistureRange; // (upper, lower)
  final (int, int)       daysRange;
  final String           name;
  final String           icon;
  final String           whatHappens;
  final List<String>     whatToDo;
  final String           nextReadingIn;
  final String           warning;

  const DryingPhase({
    required this.moistureRange,
    required this.daysRange,
    required this.name,
    required this.icon,
    required this.whatHappens,
    required this.whatToDo,
    required this.nextReadingIn,
    required this.warning,
  });
}
