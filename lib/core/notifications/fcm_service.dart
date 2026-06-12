import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:special_coffee/core/notifications/notification_service.dart';
import 'package:special_coffee/core/notifications/pending_deep_link_service.dart';
import 'package:special_coffee/firebase_options.dart';

/// Background FCM handler — top-level, not in a class.
/// Runs in a separate isolate when the app is killed; must re-initialize
/// Firebase and the notification plugin before doing anything.
@pragma('vm:entry-point')
Future<void> fcmBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.instance.init();
  await _showFromMessage(message);
}

Future<void> _showFromMessage(RemoteMessage message) async {
  final lotId = message.data['lot_id'] ?? 'lot';
  final body = message.notification?.body
      ?? message.data['message']
      ?? 'Nueva alerta de SpecialCoffee AI.';
  final isCritical = message.data['alert_level'] == 'critical';

  if (isCritical) {
    await NotificationService.instance.showFermentationCriticalAlert(
      lotId: lotId,
      message: body,
    );
  } else {
    await NotificationService.instance.showFermentationWarning(
      lotId: lotId,
      message: body,
    );
  }
}

/// Firebase Cloud Messaging — push notifications desde la nube.
/// Solo activo en Android e iOS; no-op en Windows (máquina de desarrollo).
///
/// Flujos cubiertos:
///   • App en primer plano → muestra notificación local vía NotificationService
///   • App en fondo (backgrounded) → Firebase SDK muestra la notificación si
///     el mensaje trae `notification`; fcmBackgroundHandler para data-only
///   • App cerrada (killed) → ídem, via fcmBackgroundHandler
///   • Tap en notificación → abre la app (deep-link a lote: Bloque 5c)
class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  bool get _supported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  String? _token;
  String? get token => _token;

  Future<void> Function(String)? _tokenSyncCallback;

  /// Registra un callback que se invoca inmediatamente (si ya hay token)
  /// y en cada rotación de token. Llamar desde el repositorio de auth
  /// después de un login/register/refresh exitoso.
  void setTokenSyncCallback(Future<void> Function(String token) callback) {
    _tokenSyncCallback = callback;
    if (_token != null) callback(_token!).ignore();
  }

  Future<void> init() async {
    if (!_supported) return;
    try {
      FirebaseMessaging.onBackgroundMessage(fcmBackgroundHandler);

      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        criticalAlert: true, // pH crítico a las 2am
      );

      if (kDebugMode) {
        debugPrint('FCM permission: ${settings.authorizationStatus}');
      }

      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        return;
      }

      _token = await FirebaseMessaging.instance.getToken();
      if (kDebugMode) debugPrint('FCM token: $_token');

      // Token puede rotar — mantener backend sincronizado
      FirebaseMessaging.instance.onTokenRefresh.listen((t) {
        _token = t;
        if (kDebugMode) debugPrint('FCM token refreshed: $t');
        _tokenSyncCallback?.call(t).ignore();
      });

      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_onTap);

      // App abierta desde notificación (estado terminado)
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) _onTap(initial);
    } catch (e, st) {
      if (kDebugMode) debugPrint('FcmService.init error: $e\n$st');
    }
  }

  Future<void> _onForegroundMessage(RemoteMessage message) =>
      _showFromMessage(message);

  void _onTap(RemoteMessage message) {
    final lotId = message.data['lot_id'] as String?;
    if (kDebugMode) debugPrint('FCM tap — lot: $lotId');
    if (lotId != null) PendingDeepLinkService.instance.push(lotId);
  }

  /// Suscribir al topic del lote para recibir alertas específicas.
  /// Llamar cuando el usuario empieza a monitorear un lote.
  Future<void> subscribeToLot(String lotId) async {
    if (!_supported) return;
    await FirebaseMessaging.instance.subscribeToTopic('lot_$lotId');
  }

  /// Desuscribir al cerrar o completar un lote.
  Future<void> unsubscribeFromLot(String lotId) async {
    if (!_supported) return;
    await FirebaseMessaging.instance.unsubscribeFromTopic('lot_$lotId');
  }
}
