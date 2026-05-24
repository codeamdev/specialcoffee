import 'package:special_coffee/domain/entities/lot.dart';

abstract interface class LotRepository {
  Future<List<Lot>> getLots(String userId);
  Future<Lot> saveLot(Lot lot);
  Future<void> deleteLot(String lotId);
}
