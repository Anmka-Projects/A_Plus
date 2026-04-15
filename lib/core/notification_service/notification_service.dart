// Import necessary libraries
import 'dart:developer'; // For logging and debugging
import 'dart:convert';
import 'dart:ui' show Locale;
import 'dart:math'
    show Random; // For generating random numbers (show only Random class)
import 'dart:io';
import 'package:firebase_core/firebase_core.dart'; // Firebase core functionality
import 'package:firebase_messaging/firebase_messaging.dart'; // Firebase Cloud Messaging
import 'package:educational_app/firebase_options.dart'; // Firebase options
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Local notifications plugin
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../navigation/app_router.dart';
import '../navigation/route_names.dart';
import '../../services/device_id_service.dart';

import '../../l10n/app_localizations.dart';

// Main class for handling Firebase notifications
/// Top-level background handler required by firebase_messaging
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  log('Background message received: ${message.messageId}');
  await FirebaseNotification.showBasicNotification(message);
}

@pragma('vm:entry-point')
void onDidReceiveBackgroundNotificationResponse(NotificationResponse response) {
  FirebaseNotification.handleNotificationResponsePayload(response.payload);
}

class FirebaseNotification {
  static bool _tapHandlersInitialized = false;

  // Firebase Messaging instance for handling FCM
  static final FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Local notifications plugin for showing notifications
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Variable to store the FCM token (device registration token)
  static String? fcmToken;

  // Android notification channel configuration (required for Android 8.0+)
  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // Channel ID (must be unique)
    'High Importance Notifications', // Channel name visible to user
    description:
        'This channel is used for important notifications.', // Channel description
    importance: Importance.high, // High importance for sound and alert
  );

  // Main initialization method for notifications
  static Future<void> initializeNotifications() async {
    // Ensure Firebase is initialized (defensive for any direct calls)
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    await requestNotificationPermission(); // Request user permission
    await getFcmToken(); // Get device FCM token
    await initializeLocalNotifications(); // Initialize local notifications
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Set up background message handler (when app is closed or in background)
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Set up foreground message listener (when app is open)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('Received foreground message: ${message.messageId}'); // Log message receipt
      showBasicNotification(message); // Show local notification
    });

    _initializeNotificationTapHandlers();
  }

  // Initialize local notifications plugin
  static Future<void> initializeLocalNotifications() async {
    // Configuration for initializing local notifications
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android:
          AndroidInitializationSettings('@mipmap/ic_launcher'), // Android icon
      iOS: DarwinInitializationSettings(), // iOS settings
    );

    // Initialize the local notifications plugin
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) =>
          handleNotificationResponsePayload(response.payload),
      onDidReceiveBackgroundNotificationResponse:
          onDidReceiveBackgroundNotificationResponse,
    );

    // Create notification channel for Android (required for Android 8.0+)
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // Request notification permissions from user
  static Future<void> requestNotificationPermission() async {
    final NotificationSettings settings = await messaging.requestPermission();
    log('Notification permission status: ${settings.authorizationStatus}'); // Log permission status
  }

  // Get and store the FCM token for this device
  static Future<void> getFcmToken() async {
    try {
      fcmToken = await messaging.getToken(); // Retrieve FCM token
      log('FCM Token: $fcmToken'); // Log the token for debugging
      await syncFcmTokenWithBackend();

      // Listen for token refresh events (tokens can change)
      messaging.onTokenRefresh.listen((String newToken) async {
        fcmToken = newToken; // Update stored token
        log('FCM Token refreshed: $newToken'); // Log token refresh
        await syncFcmTokenWithBackend();
      });
    } catch (e) {
      log('Error getting FCM token: $e'); // Log any errors
    }
  }

  static Future<void> syncFcmTokenWithBackend() async {
    var token = fcmToken;
    if (token == null || token.isEmpty) {
      try {
        token = await messaging.getToken();
        fcmToken = token;
      } catch (e) {
        log('Unable to fetch FCM token before backend sync: $e');
        return;
      }
    }
    if (token == null || token.isEmpty) return;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final appVersion = packageInfo.version;
      final deviceId = await DeviceIdService.getOrCreateDeviceId();
      final platform = Platform.isAndroid
          ? 'android'
          : Platform.isIOS
              ? 'ios'
              : 'unknown';

      await ApiClient.instance.post(
        ApiEndpoints.fcmToken,
        requireAuth: true,
        body: {
          'token': token,
          'platform': platform,
          'device_id': deviceId,
          'app_version': appVersion,
        },
      );
      log('FCM token synced with backend successfully');
    } catch (e) {
      // Expected before login or when token is not yet available in storage.
      log('Skipping FCM token backend sync: $e');
    }
  }

  static void _initializeNotificationTapHandlers() {
    if (_tapHandlersInitialized) return;
    _tapHandlersInitialized = true;

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log('Notification opened from background: ${message.messageId}');
      _handleMessageNavigation(message);
    });

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message == null) return;
      log('Notification opened from terminated state: ${message.messageId}');
      _handleMessageNavigation(message);
    });
  }

  static void _handleMessageNavigation(RemoteMessage message) {
    final deepLink = message.data['deepLink']?.toString() ??
        message.data['deep_link']?.toString();
    _navigateFromDeepLink(deepLink);
  }

  static void handleNotificationResponsePayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) return;
      final deepLink = decoded['deepLink']?.toString();
      _navigateFromDeepLink(deepLink);
    } catch (e) {
      log('Failed to parse notification payload: $e');
    }
  }

  static void _navigateFromDeepLink(String? deepLink) {
    if (deepLink == null || deepLink.isEmpty) {
      AppRouter.router.go(RouteNames.notifications);
      return;
    }

    final uri = Uri.tryParse(deepLink);
    if (uri == null || uri.scheme != 'app') {
      AppRouter.router.go(RouteNames.notifications);
      return;
    }

    switch (uri.host) {
      case 'dashboard':
        AppRouter.router.go(RouteNames.dashboard);
        return;
      case 'home':
        AppRouter.router.go(RouteNames.home);
        return;
      case 'courses':
        AppRouter.router.go(RouteNames.allCourses);
        return;
      case 'notifications':
        AppRouter.router.go(RouteNames.notifications);
        return;
      default:
        AppRouter.router.go(RouteNames.notifications);
        return;
    }
  }

  // Handle background messages (when app is closed or in background)
  // Random number generator for unique notification IDs
  static final Random random = Random();

  // Generate a random ID for notifications (prevents duplicate IDs)
  static int generateRandomId() {
    return random.nextInt(10000); // Generate random number between 0-9999
  }

  /// Shown when the user sends the app to the background (home / app switcher).
  /// Throttled so users are not spammed. Does not run after process death; use FCM for that.
  static const int _exitReminderNotificationId = 91001;
  static const String _prefsLastExitReminderMs = 'last_app_exit_reminder_ms';
  static const int _minIntervalBetweenExitRemindersMs =
      6 * 60 * 60 * 1000; // 6 hours

  static Future<void> showExitReminderIfAllowed(Locale locale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      final last = prefs.getInt(_prefsLastExitReminderMs) ?? 0;
      if (now - last < _minIntervalBetweenExitRemindersMs) {
        return;
      }
      await prefs.setInt(_prefsLastExitReminderMs, now);

      final l10n = lookupAppLocalizations(locale);

      final NotificationDetails details = NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: true,
        ),
      );

      await flutterLocalNotificationsPlugin.show(
        _exitReminderNotificationId,
        l10n.appExitNotificationTitle,
        l10n.appExitNotificationBody,
        details,
      );
      log('Exit reminder notification shown');
    } catch (e) {
      log('Error showing exit reminder: $e');
    }
  }

  // Display a basic local notification
  static Future<void> showBasicNotification(RemoteMessage message) async {
    try {
      // Notification details configuration for both platforms
      final NotificationDetails details = NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id, // Use predefined channel ID
          channel.name, // Use predefined channel name
          channelDescription: channel.description, // Channel description
          importance: Importance.high, // High importance level
          priority: Priority.high, // High priority for notification
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true, // Show alert on iOS
          presentBadge: true, // Update app badge on iOS
          presentSound: true, // Play sound on iOS
        ),
      );

      // Display the notification using local notifications plugin
      await flutterLocalNotificationsPlugin.show(
        generateRandomId(), // Unique ID for notification
        message.notification?.title ??
            message.data['title']?.toString() ??
            'No Title', // Title (with fallback)
        message.notification?.body ??
            message.data['body']?.toString() ??
            'No Body', // Body (with fallback)
        details, // Platform-specific details
        payload: jsonEncode({
          'deepLink': message.data['deepLink']?.toString() ??
              message.data['deep_link']?.toString(),
        }),
      );

      log('Local notification shown successfully'); // Log success
    } catch (e) {
      log('Error showing local notification: $e'); // Log any errors
    }
  }
}
