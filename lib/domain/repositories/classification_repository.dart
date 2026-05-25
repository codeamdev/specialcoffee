import 'package:special_coffee/domain/entities/classification_session.dart';

abstract interface class ClassificationRepository {
  Future<ClassificationSession?> getByLotId(String lotId);
  Future<ClassificationSession> save(ClassificationSession session);
}
