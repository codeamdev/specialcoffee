import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:special_coffee/core/notifications/pending_deep_link_service.dart';
import 'package:special_coffee/domain/repositories/auth_repository.dart';

/// Wrapper sobre OneSignal SDK v5.
///
/// Responsabilidades:
///   • Inicializar OneSignal y solicitar permisos de notificación
///   • Registrar el player_id en el backend tras login
///   • Re-registrar si el player_id rota (cambio de dispositivo / reinstalación)
///   • Manejar notificaciones en foreground (banner in-app)
///   • Manejar taps en notificación → deep-link al lote via PendingDeepLinkService
///
/// Requisito de build:  --dart-define=ONESIGNAL_APP_ID=<id-del-dashboard>
class OneSignalService {
  static const String _appId =
      String.fromEnvironment('ONESIGNAL_APP_ID', defaultValue: '');

  /// Inicializa OneSignal y sincroniza el player_id con el backend.
  /// Llamar una vez después del login/register exitoso.
  static Future<void> init(AuthRepository authRepo) async {
    if (_appId.isEmpty) {
      if (kDebugMode) debugPrint('[OneSignal] ONESIGNAL_APP_ID no configurado — skip');
      return;
    }

    OneSignal.initialize(_appId);
    await OneSignal.Notifications.requestPermission(true);

    final playerId = OneSignal.User.pushSubscription.id;
    if (playerId != null && playerId.isNotEmpty) {
      if (kDebugMode) debugPrint('[OneSignal] player_id: $playerId');
      await authRepo.registerDevice(playerId);
    }

    // Re-registrar si el player_id rota (reinstalación, cambio de dispositivo)
    OneSignal.User.pushSubscription.addObserver((change) {
      final newId = change.current.id;
      if (newId != null && newId.isNotEmpty) {
        if (kDebugMode) debugPrint('[OneSignal] player_id rotado: $newId');
        authRepo.registerDevice(newId).ignore();
      }
    });

    // Foreground: mostrar banner in-app y dejar que OneSignal también muestre
    // la notificación del sistema operativo
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      event.notification.display();
    });

    // Tap en notificación → deep-link al lote
    OneSignal.Notifications.addClickListener((event) {
      final data    = event.notification.additionalData;
      final lotId   = data?['lot_id'] as String?;
      if (lotId != null && lotId.isNotEmpty) {
        PendingDeepLinkService.instance.push(lotId);
      }
    });

    if (kDebugMode) debugPrint('[OneSignal] inicializado');
  }

  /// Desconecta el dispositivo de OneSignal.
  /// Llamar en logout para que el dispatcher no envíe más notificaciones
  /// a este dispositivo con la sesión del usuario anterior.
  static Future<void> dispose() async {
    if (_appId.isEmpty) return;
    await OneSignal.logout();
  }
}
