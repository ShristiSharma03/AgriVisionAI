import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationRecord {
  final String title;
  final String body;
  final DateTime timestamp;

  NotificationRecord({required this.title, required this.body, required this.timestamp});

  Map<String, dynamic> toJson() => {
        'title': title,
        'body': body,
        'timestamp': timestamp.toIso8601String(),
      };

  factory NotificationRecord.fromJson(Map<String, dynamic> json) => NotificationRecord(
        title: json['title'] ?? '',
        body: json['body'] ?? '',
        timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      );

  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

/// Handles notifications for AgriVision AI.
///
/// SCOPE NOTE: real server-triggered push notifications require
/// Firebase Cloud Functions (paid Blaze plan). This service instead
/// focuses on LOCAL notifications triggered by the app itself.
///
/// HISTORY NOTE: scheduleDailyReminder() does NOT log to history
/// itself — callers (Settings screen) log precise, context-specific
/// entries: logReminderTurnedOn() when the toggle is switched on, and
/// logReminderSummary() once when the farmer finishes editing the
/// time/note and leaves the screen (so multiple small edits in one
/// visit produce ONE combined history entry, not several duplicates).
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'agrivision_alerts';
  static const String _channelName = 'AgriVision Alerts';

  static const String pushNotificationsPrefKey = 'push_notifications_enabled';
  static const String _historyKey = 'notification_history';
  static const String _reminderHourKey = 'daily_reminder_hour';
  static const String _reminderMinuteKey = 'daily_reminder_minute';
  static const String _reminderNoteKey = 'daily_reminder_note';
  static const int _maxHistoryEntries = 50;

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Weather risk alerts, scan confirmations, and reminders',
      importance: Importance.high,
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(channel);

    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();

    await _registerToken();
    _messaging.onTokenRefresh.listen((_) => _registerToken());

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        showLocalNotification(
          title: notification.title ?? 'AgriVision AI',
          body: notification.body ?? '',
        );
      }
    });

    _isInitialized = true;
  }

  Future<void> _registerToken() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final token = await _messaging.getToken();
      if (token == null) return;
      await _firestore.collection('users').doc(uid).set(
        {'fcmToken': token, 'fcmTokenUpdatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    } catch (e) {
      // Non-fatal.
    }
  }

  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(pushNotificationsPrefKey) ?? true;
  }

  // ============================================================
  // HISTORY
  // ============================================================

  Future<void> _logNotification({required String title, required String body}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_historyKey) ?? <String>[];
      final record = NotificationRecord(title: title, body: body, timestamp: DateTime.now());
      raw.insert(0, jsonEncode(record.toJson()));
      if (raw.length > _maxHistoryEntries) {
        raw.removeRange(_maxHistoryEntries, raw.length);
      }
      await prefs.setStringList(_historyKey, raw);
    } catch (e) {
      // Non-fatal.
    }
  }

  Future<List<NotificationRecord>> getNotificationHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_historyKey) ?? <String>[];
    return raw
        .map((s) {
          try {
            return NotificationRecord.fromJson(jsonDecode(s) as Map<String, dynamic>);
          } catch (e) {
            return null;
          }
        })
        .whereType<NotificationRecord>()
        .toList();
  }

  Future<void> clearNotificationHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  Future<void> deleteNotification(DateTime timestamp) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_historyKey) ?? <String>[];
    final filtered = raw.where((s) {
      try {
        final json = jsonDecode(s) as Map<String, dynamic>;
        final recordTime = DateTime.tryParse(json['timestamp'] ?? '');
        return recordTime != timestamp;
      } catch (e) {
        return true;
      }
    }).toList();
    await prefs.setStringList(_historyKey, filtered);
  }

  // ============================================================
  // IMMEDIATE NOTIFICATIONS
  // ============================================================

  Future<void> showLocalNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails());

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );

    await _logNotification(title: title, body: body);
  }

  Future<void> notifyHighCropRisk({
    required String cropName,
    required String diseaseName,
  }) async {
    if (!await areNotificationsEnabled()) return;

    await showLocalNotification(
      title: 'High disease risk today',
      body: '$cropName is at high risk of $diseaseName based on today\'s weather. Tap to check spray timing.',
    );
  }

  Future<void> notifyScanSaved({required String diagnosis}) async {
    if (!await areNotificationsEnabled()) return;

    await showLocalNotification(
      title: 'Scan complete',
      body: '$diagnosis — saved to your Scan History.',
    );
  }

  // ============================================================
  // DAILY REMINDER (farmer-configurable time + note)
  // ============================================================

  String formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m $period';
  }

  Future<({int hour, int minute, String note})> getReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      hour: prefs.getInt(_reminderHourKey) ?? 7,
      minute: prefs.getInt(_reminderMinuteKey) ?? 0,
      note: prefs.getString(_reminderNoteKey) ?? '',
    );
  }

  Future<void> saveReminderNote(String note) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_reminderNoteKey, note.trim());
  }

  Future<void> scheduleDailyReminder({int hour = 7, int minute = 0, String note = ''}) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails());

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final trimmedNote = note.trim();
    final title = trimmedNote.isEmpty ? 'Good morning! 🌱' : 'Reminder';
    final reminderBody = trimmedNote.isEmpty
        ? "Check today's weather and crop risk before heading to the field."
        : trimmedNote;

    await _localNotifications.zonedSchedule(
      100,
      title,
      reminderBody,
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_reminderHourKey, hour);
    await prefs.setInt(_reminderMinuteKey, minute);
    await prefs.setString(_reminderNoteKey, trimmedNote);
  }

  /// Logs that notifications were turned on — call this from Settings
  /// right after a successful scheduleDailyReminder() triggered by the
  /// Push Notifications toggle.
  Future<void> logReminderTurnedOn(int hour, int minute) async {
    await _logNotification(
      title: 'Daily reminder turned on',
      body: 'You\'ll get a reminder every day at ${formatTime(hour, minute)}.',
    );
  }

  /// Logs a single combined summary of the current reminder time +
  /// note. Call this once when the farmer finishes editing (e.g.
  /// leaving the Settings screen), not after every individual tap —
  /// so setting the time and then adding a note produces ONE history
  /// entry reflecting both, not two separate ones.
  Future<void> logReminderSummary({required int hour, required int minute, required String note}) async {
    final trimmed = note.trim();
    final timeLabel = formatTime(hour, minute);
    await _logNotification(
      title: 'Daily reminder updated',
      body: trimmed.isEmpty
          ? 'Set for $timeLabel — using the default message.'
          : 'Set for $timeLabel — "$trimmed"',
    );
  }

  Future<void> cancelDailyReminder() async {
    await _localNotifications.cancel(100);
    await _logNotification(
      title: 'Daily reminder turned off',
      body: 'You won\'t get the daily weather check-in anymore.',
    );
  }

  Future<bool?> canScheduleExactAlarms() async {
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return androidPlugin?.canScheduleExactNotifications();
  }
}