import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Immediate alerts and reading reminders via flutter_local_notifications.
/// Supported platforms: Android, iOS, macOS.
/// On unsupported platforms (Windows dev) all calls are silent no-ops.
///
/// Reminders use zonedSchedule — they fire even when the app is closed,
/// provided the OS hasn't killed the scheduled alarm (Android Doze, iOS
/// background restrictions notwithstanding).
///
/// Android setup required when adding the android/ platform:
///   AndroidManifest.xml:
///     `<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>`
///     `<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>`
///   USE_EXACT_ALARM no se declara — usamos inexactAllowWhileIdle.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _channelAlerts = 'sc_alerts';
  static const _channelReminders = 'sc_reminders';

  // ── ID ranges ─────────────────────────────────────────────────────────────
  // 1000–1499 fermentation critical  |  1500–1999 fermentation warning
  // 2000–2099 drying target reached  |  2100–2199 drying over-dried
  // 3000–3999 fermentation reminders |  4000–4999 drying reminders

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (!Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS) return;
    try {
      // Timezone data required for zonedSchedule
      tz_data.initializeTimeZones();
      try {
        final localTz = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(localTz));
      } catch (_) {
        // Fallback to UTC; reminders fire at correct offset from now
        tz.setLocalLocation(tz.UTC);
      }

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

  // ── Fermentation — immediate alerts ───────────────────────────────────────

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

  // ── Fermentation — scheduled reminder ────────────────────────────────────

  /// Schedules a reminder for the next fermentation reading.
  /// Cancels any previous reminder for the same lot first.
  /// Fires even when the app is closed (uses OS alarm manager).
  Future<void> scheduleFermentationReminder({
    required String lotId,
    Duration delay = const Duration(hours: 4),
  }) async {
    if (!_ready) return;
    final id = 3000 + (lotId.hashCode.abs() % 999);
    await _cancelById(id);
    await _schedule(
      id: id,
      title: 'Recordatorio — Fermentación',
      body: 'Es hora de tomar la siguiente lectura del lote.',
      scheduledAt: tz.TZDateTime.now(tz.local).add(delay),
    );
  }

  // ── Drying — immediate alerts ─────────────────────────────────────────────

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

  // ── Drying — scheduled reminder ───────────────────────────────────────────

  /// Schedules the next daily drying reading reminder.
  /// Cancels any previous reminder for the same lot first.
  Future<void> scheduleDryingReminder({
    required String lotId,
    Duration delay = const Duration(hours: 24),
  }) async {
    if (!_ready) return;
    final id = 4000 + (lotId.hashCode.abs() % 999);
    await _cancelById(id);
    await _schedule(
      id: id,
      title: 'Recordatorio — Secado',
      body: 'Toma la lectura de humedad del día de hoy.',
      scheduledAt: tz.TZDateTime.now(tz.local).add(delay),
    );
  }

  // ── Cancel ────────────────────────────────────────────────────────────────

  Future<void> cancelAllForLot(String lotId) async {
    if (!_ready) return;
    final base = lotId.hashCode.abs();
    for (final id in [
      1000 + (base % 499),
      1500 + (base % 499),
      2000 + (base % 99),
      2100 + (base % 99),
      3000 + (base % 999),
      4000 + (base % 999),
    ]) {
      await _cancelById(id);
    }
  }

  Future<void> _cancelById(int id) async {
    try {
      await _plugin.cancel(id);
    } catch (_) {}
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
      await _plugin.show(
        id,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            importance: importance,
            priority: priority,
            showWhen: true,
          ),
          iOS: const DarwinNotificationDetails(),
          macOS: const DarwinNotificationDetails(),
        ),
      );
    } catch (_) {}
  }

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledAt,
  }) async {
    if (!_ready) return;
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledAt,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelReminders,
            'Recordatorios de lectura',
          ),
          iOS: DarwinNotificationDetails(),
          macOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {}
  }
}
