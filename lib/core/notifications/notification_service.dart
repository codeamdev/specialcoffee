import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Immediate alerts and reading reminders via flutter_local_notifications.
/// Supported platforms: Android, iOS, macOS.
/// On unsupported platforms (Windows dev) calls are silently no-ops.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  // ── Channel IDs ───────────────────────────────────────────────────────────
  static const _channelAlerts = 'sc_alerts';
  static const _channelReminders = 'sc_reminders';

  // ── ID ranges ─────────────────────────────────────────────────────────────
  // 1000–1499 → fermentation critical
  // 1500–1999 → fermentation warning
  // 2000–2099 → drying target reached
  // 2100–2199 → drying over-dried
  // 3000–3999 → fermentation reading reminders
  // 4000–4999 → drying reading reminders

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (!Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS) return;
    try {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
        macOS: DarwinInitializationSettings(),
      );
      await _plugin.initialize(settings);
      await _requestPermissions();
      _ready = true;
    } catch (_) {}
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      await ios?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  // ── Fermentation alerts ───────────────────────────────────────────────────

  Future<void> showFermentationCriticalAlert({
    required String lotId,
    required String message,
  }) =>
      _show(
        id: 1000 + (lotId.hashCode.abs() % 499),
        title: 'Alerta crítica — Fermentación',
        body: message,
        channelId: _channelAlerts,
        channelName: 'Alertas críticas',
        importance: Importance.max,
        priority: Priority.max,
      );

  Future<void> showFermentationWarning({
    required String lotId,
    required String message,
  }) =>
      _show(
        id: 1500 + (lotId.hashCode.abs() % 499),
        title: 'Advertencia — Fermentación',
        body: message,
        channelId: _channelAlerts,
        channelName: 'Alertas críticas',
        importance: Importance.high,
        priority: Priority.high,
      );

  /// Schedules a reminder to take the next fermentation reading.
  /// Uses an in-process delayed Future (sufficient for V1; swap for
  /// zonedSchedule when the timezone package is added).
  void scheduleFermentationReminder({
    required String lotId,
    Duration delay = const Duration(hours: 4),
  }) {
    final id = 3000 + (lotId.hashCode.abs() % 999);
    Future.delayed(delay, () => _show(
          id: id,
          title: 'Recordatorio — Fermentación',
          body: 'Es hora de tomar la siguiente lectura del lote.',
          channelId: _channelReminders,
          channelName: 'Recordatorios de lectura',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ));
  }

  // ── Drying alerts ─────────────────────────────────────────────────────────

  Future<void> showDryingTargetReached({
    required String lotId,
    required double moisturePct,
  }) =>
      _show(
        id: 2000 + (lotId.hashCode.abs() % 99),
        title: '¡Secado en rango objetivo!',
        body: 'Humedad ${moisturePct.toStringAsFixed(1)}% — rango 10.5–12%. '
            'Considera detener el secado.',
        channelId: _channelAlerts,
        channelName: 'Alertas críticas',
        importance: Importance.high,
        priority: Priority.high,
      );

  Future<void> showDryingOverDried({
    required String lotId,
    required double moisturePct,
  }) =>
      _show(
        id: 2100 + (lotId.hashCode.abs() % 99),
        title: 'ALERTA — Sobre-secado',
        body: 'Humedad ${moisturePct.toStringAsFixed(1)}% — bajo 10%. '
            'Detén el secado inmediatamente.',
        channelId: _channelAlerts,
        channelName: 'Alertas críticas',
        importance: Importance.max,
        priority: Priority.max,
      );

  void scheduleDryingReminder({
    required String lotId,
    Duration delay = const Duration(hours: 24),
  }) {
    final id = 4000 + (lotId.hashCode.abs() % 999);
    Future.delayed(delay, () => _show(
          id: id,
          title: 'Recordatorio — Secado',
          body: 'Toma la lectura de humedad del día de hoy.',
          channelId: _channelReminders,
          channelName: 'Recordatorios de lectura',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ));
  }

  // ── Cancel ────────────────────────────────────────────────────────────────

  Future<void> cancelAllForLot(String lotId) async {
    if (!_ready) return;
    final base = lotId.hashCode.abs();
    final ids = [
      1000 + (base % 499),
      1500 + (base % 499),
      2000 + (base % 99),
      2100 + (base % 99),
      3000 + (base % 999),
      4000 + (base % 999),
    ];
    for (final id in ids) {
      try { await _plugin.cancel(id); } catch (_) {}
    }
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  Future<void> _show({
    required int id,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
    required Importance importance,
    required Priority priority,
  }) async {
    if (!_ready) return;
    try {
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: importance,
          priority: priority,
          showWhen: true,
        ),
        iOS: const DarwinNotificationDetails(),
        macOS: const DarwinNotificationDetails(),
      );
      await _plugin.show(id, title, body, details);
    } catch (_) {}
  }
}
