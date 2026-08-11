import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import '../router/app_router.dart';
import '../router/app_routes.dart';
import '../widgets/in_app_notification.dart';

/// Background message handler — must be a top-level function
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background message: ${message.notification?.title}');
}

class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _androidChannel = AndroidNotificationChannel(
    'hr_app_high_importance',
    'HR App Notifications',
    description: 'Leave approvals, KPI updates, and overtime alerts',
    importance: Importance.high,
  );

  // ── Init ───────────────────────────────────────────────────────────────────

  Future<void> init() async {
    // 1. Request permission (Android 13+ / iOS)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Create Android high-importance channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    // 3. Init local notifications
    const androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          try {
            final data = jsonDecode(response.payload!) as Map<String, dynamic>;
            final message = RemoteMessage(data: data);
            _onNotificationTap(message);
          } catch (e) {
            debugPrint('[FCM] Error parsing notification response: $e');
          }
        }
      },
    );

    // 4. Foreground notification display (Android/iOS)
    // Set alert to false to prevent native heads-up popups on iOS in the foreground
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: true,
      sound: true,
    );

    // 5. Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

    // 6. Handle foreground messages
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // 7. Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationTap);

    // 8. Check if app was opened from a terminated-state notification
    final initial = await _messaging.getInitialMessage();
    if (initial != null) _onNotificationTap(initial);

    debugPrint('[FCM] Initialized successfully');
  }

  // ── Token ──────────────────────────────────────────────────────────────────

  Future<String?> getToken() async {
    final token = await _messaging.getToken();
    debugPrint('[FCM] Device token: $token');
    return token;
  }

  /// Call this after login to register the token with our NestJS backend
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  // ── Foreground Handler ─────────────────────────────────────────────────────

  void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    // Show system tray notification SILENTLY (low importance) in foreground
    // This inserts the notification quietly into the status drawer,
    // avoiding heads-up overlaps with our custom glassmorphic in-app banner.
    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.low,
          priority: Priority.low,
          playSound: false,
          enableVibration: false,
          icon: '@mipmap/launcher_icon',
          color: const Color(0xFF0B6E64),
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
          styleInformation: const BigTextStyleInformation(''),
        ),
      ),
      payload: jsonEncode(message.data),
    );

    // Show premium in-app notification banner
    final context = AppRouter.navigatorKey.currentContext;
    if (context != null) {
      InAppNotification.show(
        context,
        title: notification.title ?? '',
        body: notification.body ?? '',
        data: message.data,
        onTap: () => _onNotificationTap(message),
      );
    }

    debugPrint('[FCM] Foreground: ${notification.title} — ${notification.body}');
  }

  // ── Tap Handler ────────────────────────────────────────────────────────────

  RemoteMessage? _pendingMessage;

  void consumePendingNotification(BuildContext context) {
    if (_pendingMessage != null) {
      final msg = _pendingMessage!;
      _pendingMessage = null;
      _onNotificationTap(msg);
    }
  }

  void _onNotificationTap(RemoteMessage message) {
    debugPrint('[FCM] Notification tapped: ${message.data}');
    final type = message.data['type']?.toString();
    if (type == null) return;

    final context = AppRouter.navigatorKey.currentContext;
    if (context != null && context.mounted) {
      if (type.startsWith('leave')) {
        context.go(AppRoutes.leave);
      } else if (type == 'kpi_updated') {
        context.go(AppRoutes.kpi);
      } else if (type.startsWith('overtime')) {
        context.go(AppRoutes.attendance);
      }
    } else {
      debugPrint('[FCM] Context not ready yet, caching pending notification: ${message.data}');
      _pendingMessage = message;
    }
  }
}
