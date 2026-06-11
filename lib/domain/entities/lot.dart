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
    @Default('') String processType,
    @Default(18.0) double ambientTempC,
    @Default(70.0) double ambientHumidityPct,
    @Default(0.0) double rainProbabilityPct,
    required DateTime createdAt,
    @Default('pending') String status,
    String? notes,
    // Farm fields — local only, not synced (G-1/D-12)
    double? latitude,
    double? longitude,
    double? farmAreaHa,
    String? blendVarietyIds,
    int? plantAgeYears,
    String? plantType,
  }) = _Lot;

  factory Lot.fromJson(Map<String, dynamic> json) => _$LotFromJson(json);
}
