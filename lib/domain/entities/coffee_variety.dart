class CoffeeVariety {
  const CoffeeVariety({
    required this.id,
    required this.name,
    required this.sensitivity,
    required this.scaPotential,
    this.especie = 'arabica',
    this.altitudMinMasl,
    this.altitudMaxMasl,
    this.procesoRecomendado,
    this.perfilesSabor,
  });

  final String id;
  final String name;
  final String sensitivity;
  final double scaPotential;
  final String especie;
  final int?   altitudMinMasl;
  final int?   altitudMaxMasl;
  final String? procesoRecomendado;
  final List<String>? perfilesSabor;
}
