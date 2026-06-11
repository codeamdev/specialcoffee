class CosechaPase {
  final String id;
  final String lotId;
  final String createdBy;

  // Recolección
  final DateTime fechaRecoleccion;
  final DateTime? horaInicio;
  final DateTime? horaFin;
  final double pesoCerezaKg;
  final int? numOperarios;
  final double? brixPromedio;
  final double? pctMadurezVisual;

  // Proceso
  final String tipoProceso;

  // Clasificación implícita
  final double? pesoFlotacionKg;
  final double? pctFlotacion;

  // Despulpado implícito
  final double? pesoPergaminoHumedoKg;
  final double? horasHastaDespulpe;

  // Workflow
  final String etapaActual;
  final String status;

  final String? notas;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const CosechaPase({
    required this.id,
    required this.lotId,
    required this.createdBy,
    required this.fechaRecoleccion,
    this.horaInicio,
    this.horaFin,
    required this.pesoCerezaKg,
    this.numOperarios,
    this.brixPromedio,
    this.pctMadurezVisual,
    required this.tipoProceso,
    this.pesoFlotacionKg,
    this.pctFlotacion,
    this.pesoPergaminoHumedoKg,
    this.horasHastaDespulpe,
    required this.etapaActual,
    required this.status,
    this.notas,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  bool get isActive    => status == 'activo';
  bool get isCompleted => status == 'completado';

  /// Etapas ordenadas según el tipo de proceso.
  List<String> get stages => switch (tipoProceso) {
    'natural' || 'honey_yellow' || 'honey_red' =>
      ['clasificacion', 'secado', 'trilla'],
    _ => // lavado, anaerobic_lactic, anaerobic_carbonic
      ['clasificacion', 'fermentacion', 'lavado', 'secado', 'trilla'],
  };

  /// Indica si la etapa necesita botón Iniciar/Terminar (requiere medición de tiempo).
  bool etapaEsExplicita(String etapa) =>
      const {'fermentacion', 'lavado', 'secado', 'trilla'}.contains(etapa);

  /// Intervalo de medición recomendado en horas según tipo de proceso.
  double get fermentacionIntervalH => switch (tipoProceso) {
    'lavado'             => 4.0,
    'natural'            => 24.0,
    'honey_yellow' ||
    'honey_red'          => 12.0,
    'anaerobic_lactic' ||
    'anaerobic_carbonic' => 4.0,
    _                    => 6.0,
  };

  String get tipoProcesoLabel => switch (tipoProceso) {
    'lavado'             => 'Lavado',
    'natural'            => 'Natural',
    'honey_yellow'       => 'Honey Amarillo',
    'honey_red'          => 'Honey Rojo',
    'anaerobic_lactic'   => 'Anaeróbico Láctico',
    'anaerobic_carbonic' => 'Anaeróbico Carbónico',
    _                    => tipoProceso,
  };

  String get etapaLabel => switch (etapaActual) {
    'clasificacion' => 'Clasificación',
    'fermentacion'  => 'Fermentación',
    'lavado'        => 'Lavado',
    'secado'        => 'Secado',
    'trilla'        => 'Trilla',
    'completado'    => 'Completado',
    _               => etapaActual,
  };

  static String labelForEtapa(String e) => switch (e) {
    'clasificacion' => 'Clasificación',
    'fermentacion'  => 'Fermentación',
    'lavado'        => 'Lavado',
    'secado'        => 'Secado',
    'trilla'        => 'Trilla',
    'completado'    => 'Completado',
    _               => e,
  };
}
