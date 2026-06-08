import 'package:special_coffee/domain/entities/physical_analysis.dart';

abstract interface class PhysicalAnalysisRepository {
  Future<List<PhysicalAnalysis>> getByLotId(String lotId);
  Future<PhysicalAnalysis?> getLatestByLotId(String lotId);
  Future<PhysicalAnalysis> save(PhysicalAnalysis analysis);
}
