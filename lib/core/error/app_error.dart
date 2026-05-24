import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_error.freezed.dart';

@freezed
sealed class AppError with _$AppError {
  const factory AppError.network({
    required String message,
    int? statusCode,
  }) = NetworkError;

  const factory AppError.local({
    required String message,
  }) = LocalError;

  const factory AppError.auth({
    required String message,
  }) = AuthError;

  const factory AppError.validation({
    required String field,
    required String message,
  }) = ValidationError;

  const factory AppError.aiEngine({
    required String message,
    String? ruleId,
  }) = AiEngineError;

  const factory AppError.unknown({
    required String message,
  }) = UnknownError;
}

extension AppErrorMessage on AppError {
  String get userMessage => when(
        network: (msg, _) => 'Sin conexión. Trabajando en modo offline.',
        local: (msg) => 'Error al acceder a datos locales.',
        auth: (msg) => msg,
        validation: (field, msg) => msg,
        aiEngine: (msg, _) => 'El motor de IA encontró un problema: $msg',
        unknown: (msg) => 'Algo salió mal. Intenta de nuevo.',
      );
}
