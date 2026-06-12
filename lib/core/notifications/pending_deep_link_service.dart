import 'dart:async';

/// Puente entre FcmService (singleton) y el árbol de widgets Riverpod.
///
/// FcmService no tiene acceso a ProviderContainer, así que escribe aquí.
/// El provider `pendingDeepLinkProvider` escucha el stream y navega.
/// Para el caso de app abierta desde killed: almacena el ID hasta que
/// haya un listener activo, luego lo consume y limpia.
class PendingDeepLinkService {
  PendingDeepLinkService._();
  static final PendingDeepLinkService instance = PendingDeepLinkService._();

  final StreamController<String> _controller =
      StreamController<String>.broadcast();

  Stream<String> get lotIdStream => _controller.stream;

  String? _pending;

  void push(String lotId) {
    _pending = lotId;
    _controller.add(lotId);
  }

  /// Consume el lotId pendiente (para el caso de app lanzada desde notification).
  /// Retorna null si no hay nada pendiente.
  String? consumePending() {
    final id = _pending;
    _pending = null;
    return id;
  }
}
