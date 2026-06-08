import 'package:drift/drift.dart';
import 'package:special_coffee/core/database/app_database.dart';
import 'package:special_coffee/core/database/daos/physical_analysis_dao.dart';
import 'package:special_coffee/domain/entities/physical_analysis.dart';
import 'package:special_coffee/domain/repositories/physical_analysis_repository.dart';
import 'package:uuid/uuid.dart';

class PhysicalAnalysisLocalRepository implements PhysicalAnalysisRepository {
  PhysicalAnalysisLocalRepository(this._dao, this._analyzedBy);

  final PhysicalAnalysisDao _dao;
  final String _analyzedBy;
  static const _uuid = Uuid();

  @override
  Future<List<PhysicalAnalysis>> getByLotId(String lotId) async {
    final rows = await _dao.getByLotId(lotId);
    return rows.map(_fromRow).toList();
  }

  @override
  Future<PhysicalAnalysis?> getLatestByLotId(String lotId) async {
    final row = await _dao.getLatestByLotId(lotId);
    return row != null ? _fromRow(row) : null;
  }

  @override
  Future<PhysicalAnalysis> save(PhysicalAnalysis analysis) async {
    final id = analysis.id.isEmpty ? _uuid.v4() : analysis.id;
    await _dao.upsert(PhysicalAnalysesCompanion(
      id:                Value(id),
      lotId:             Value(analysis.lotId),
      analyzedBy:        Value(_analyzedBy),
      analyzedAt:        Value(analysis.analyzedAt),
      greenDensityGcm3:  Value(analysis.greenDensityGcm3),
      moisturePct:       Value(analysis.moisturePct),
      waterActivityAw:   Value(analysis.waterActivityAw),
      defectsPrimary:    Value(analysis.defectsPrimary),
      defectsSecondary:  Value(analysis.defectsSecondary),
      defectTypes:       Value(analysis.defectTypes),
      screenSize:        Value(analysis.screenSize),
      notes:             Value(analysis.notes),
    ));
    return PhysicalAnalysis(
      id:               id,
      lotId:            analysis.lotId,
      analyzedBy:       _analyzedBy,
      analyzedAt:       analysis.analyzedAt,
      greenDensityGcm3: analysis.greenDensityGcm3,
      moisturePct:      analysis.moisturePct,
      waterActivityAw:  analysis.waterActivityAw,
      defectsPrimary:   analysis.defectsPrimary,
      defectsSecondary: analysis.defectsSecondary,
      defectTypes:      analysis.defectTypes,
      screenSize:       analysis.screenSize,
      notes:            analysis.notes,
    );
  }

  PhysicalAnalysis _fromRow(DbPhysicalAnalysis r) => PhysicalAnalysis(
        id:               r.id,
        lotId:            r.lotId,
        analyzedBy:       r.analyzedBy,
        analyzedAt:       r.analyzedAt,
        greenDensityGcm3: r.greenDensityGcm3,
        moisturePct:      r.moisturePct,
        waterActivityAw:  r.waterActivityAw,
        defectsPrimary:   r.defectsPrimary,
        defectsSecondary: r.defectsSecondary,
        defectTypes:      r.defectTypes,
        screenSize:       r.screenSize,
        notes:            r.notes,
      );
}
