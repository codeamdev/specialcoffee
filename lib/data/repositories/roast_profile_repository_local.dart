import 'package:drift/drift.dart';
import 'package:special_coffee/core/database/app_database.dart';
import 'package:special_coffee/core/database/daos/roast_profile_dao.dart';
import 'package:special_coffee/domain/entities/roast_profile.dart';
import 'package:special_coffee/domain/repositories/roast_profile_repository.dart';
import 'package:uuid/uuid.dart';

class RoastProfileLocalRepository implements RoastProfileRepository {
  RoastProfileLocalRepository(this._dao, this._roastedBy);

  final RoastProfileDao _dao;
  final String _roastedBy;
  static const _uuid = Uuid();

  @override
  Future<List<RoastProfile>> getByLotId(String lotId) async {
    final rows = await _dao.getByLotId(lotId);
    return rows.map(_fromRow).toList();
  }

  @override
  Future<RoastProfile?> getById(String id) async {
    final row = await _dao.getById(id);
    return row != null ? _fromRow(row) : null;
  }

  @override
  Future<RoastProfile> save(RoastProfile profile) async {
    final id = profile.id.isEmpty ? _uuid.v4() : profile.id;
    await _dao.upsert(RoastProfilesCompanion(
      id:               Value(id),
      lotId:            Value(profile.lotId),
      roastedBy:        Value(_roastedBy),
      roastedAt:        Value(profile.roastedAt),
      greenWeightKg:    Value(profile.greenWeightKg),
      roastedWeightKg:  Value(profile.roastedWeightKg),
      roastLossPct:     Value(profile.roastLossPct),
      chargeTempC:      Value(profile.chargeTempC),
      dropTempC:        Value(profile.dropTempC),
      firstCrackTimeS:  Value(profile.firstCrackTimeS),
      firstCrackTempC:  Value(profile.firstCrackTempC),
      developmentTimeS: Value(profile.developmentTimeS),
      totalTimeS:       Value(profile.totalTimeS),
      dtrPct:           Value(profile.dtrPct),
      agtronWhole:      Value(profile.agtronWhole),
      agtronGround:     Value(profile.agtronGround),
      colorLabel:       Value(profile.colorLabel),
      roastNotes:       Value(profile.roastNotes),
    ));
    return RoastProfile(
      id:               id,
      lotId:            profile.lotId,
      roastedBy:        _roastedBy,
      roastedAt:        profile.roastedAt,
      greenWeightKg:    profile.greenWeightKg,
      roastedWeightKg:  profile.roastedWeightKg,
      roastLossPct:     profile.roastLossPct,
      chargeTempC:      profile.chargeTempC,
      dropTempC:        profile.dropTempC,
      firstCrackTimeS:  profile.firstCrackTimeS,
      firstCrackTempC:  profile.firstCrackTempC,
      developmentTimeS: profile.developmentTimeS,
      totalTimeS:       profile.totalTimeS,
      dtrPct:           profile.dtrPct,
      agtronWhole:      profile.agtronWhole,
      agtronGround:     profile.agtronGround,
      colorLabel:       profile.colorLabel,
      roastNotes:       profile.roastNotes,
    );
  }

  RoastProfile _fromRow(DbRoastProfile r) => RoastProfile(
        id:               r.id,
        lotId:            r.lotId,
        roastedBy:        r.roastedBy,
        roastedAt:        r.roastedAt,
        greenWeightKg:    r.greenWeightKg,
        roastedWeightKg:  r.roastedWeightKg,
        roastLossPct:     r.roastLossPct,
        chargeTempC:      r.chargeTempC,
        dropTempC:        r.dropTempC,
        firstCrackTimeS:  r.firstCrackTimeS,
        firstCrackTempC:  r.firstCrackTempC,
        developmentTimeS: r.developmentTimeS,
        totalTimeS:       r.totalTimeS,
        dtrPct:           r.dtrPct,
        agtronWhole:      r.agtronWhole,
        agtronGround:     r.agtronGround,
        colorLabel:       r.colorLabel,
        roastNotes:       r.roastNotes,
      );
}
