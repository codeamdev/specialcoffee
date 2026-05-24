import 'package:freezed_annotation/freezed_annotation.dart';

part 'lot.freezed.dart';
part 'lot.g.dart';

@freezed
abstract class Lot with _$Lot {
  const factory Lot({
    required String id,
    required String userId,
    required String varietyId,
    required String varietyName,
    required int altitudeMasl,
    required String region,
    required String processType,
    required double ambientTempC,
    required double ambientHumidityPct,
    @Default(0.0) double rainProbabilityPct,
    required DateTime createdAt,
    @Default('pending') String status,
    String? notes,
  }) = _Lot;

  factory Lot.fromJson(Map<String, dynamic> json) => _$LotFromJson(json);
}
