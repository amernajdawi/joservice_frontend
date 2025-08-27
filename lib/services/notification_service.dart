import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../widgets/popup_notification.dart';
import 'api_service.dart';
import 'auth_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final ApiService _apiService = ApiService();

  // Stream controllers for notification events
  final StreamController<Map<String, dynamic>> _onNotificationTappedController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _onNotificationReceivedController = StreamController<Map<String, dynamic>>.broadcast();
  
  Stream<Map<String, dynamic>> get onNotificationTapped => _onNotificationTappedController.stream;
  Stream<Map<String, dynamic>> get onNotificationReceived => _onNotificationReceivedController.stream;

  String? _fcmToken;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      print('🚀 Initializing comprehensive notification service...');
      
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Initialize Firebase messaging
      await _initializeFirebaseMessaging();
      
      // Request permissions
      await _requestPermissions();
      
      // Get FCM token (with retry logic for iOS)
      if (Platform.isIOS) {
        // On iOS, delay FCM token retrieval to allow APNS token to be set
        Timer(const Duration(seconds: 3), () => _getFcmToken());
      } else {
        // On Android, get FCM token immediately
        await _getFcmToken();
      }
      
      _isInitialized = true;
      print('✅ Notification service initialized successfully');
    } catch (error) {
      print('❌ Error initializing notification service: $error');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }
  }

  Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel generalChannel = AndroidNotificationChannel(
      'jo_service_general',
      'General Notifications',
      description: 'General app notifications',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    const AndroidNotificationChannel bookingChannel = AndroidNotificationChannel(
      'jo_service_bookings',
      'Booking Notifications',
      description: 'Notifications about booking updates',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    const AndroidNotificationChannel chatChannel = AndroidNotificationChannel(
      'jo_service_chat',
      'Chat Notifications',
      description: 'Notifications about new messages',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    const AndroidNotificationChannel adminChannel = AndroidNotificationChannel(
      'jo_service_admin',
      'Admin Notifications',
      description: 'Admin-specific notifications',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(generalChannel);
    
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(bookingChannel);
    
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(chatChannel);
    
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(adminChannel);
  }

  Future<void> _initializeFirebaseMessaging() async {
    try {
      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      
      // Handle when app is opened from notification
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpenedApp);
      
      print('✅ Firebase messaging initialized');
    } catch (error) {
      print('❌ Error initializing Firebase messaging: $error');
    }
  }

  Future<void> _requestPermissions() async {
    try {
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('🔐 Notification permission status: ${settings.authorizationStatus}');
    } catch (error) {
      print('❌ Error requesting notification permissions: $error');
    }
  }

  Future<void> _getFcmToken() async {
    try {
      // On iOS, ensure APNS token is available first
      if (Platform.isIOS) {
        print('🍎 Waiting for APNS token on iOS...');
        
        // Try multiple times with increasing delays
        for (int attempt = 1; attempt <= 5; attempt++) {
          String? apnsToken = await _firebaseMessaging.getAPNSToken();
          if (apnsToken != null && apnsToken.isNotEmpty) {
            print('🍎 APNS Token obtained: ${apnsToken.substring(0, 20)}...');
            break;
          } else {
            print('⚠️ APNS Token attempt $attempt/5 - waiting ${attempt * 2} seconds...');
            await Future.delayed(Duration(seconds: attempt * 2));
          }
        }
        
        // Final check for APNS token
        String? finalApnsToken = await _firebaseMessaging.getAPNSToken();
        if (finalApnsToken == null || finalApnsToken.isEmpty) {
          print('⚠️ APNS Token still not available after retries, proceeding anyway...');
        }
      }
      
      // Now try to get FCM token
      print('📱 Requesting FCM token...');
      _fcmToken = await _firebaseMessaging.getToken();
      
      if (_fcmToken != null && _fcmToken!.isNotEmpty) {
        print('📱 FCM Token obtained: ${_fcmToken!.substring(0, 20)}...');
        await _updateFcmTokenOnServer();
      } else {
        print('⚠️ FCM Token not available, will retry in 10 seconds...');
        Timer(const Duration(seconds: 10), () => _getFcmToken());
      }
    } catch (error) {
      print('❌ Error getting FCM token: $error');
      
      // Handle specific APNS token errors
      if (error.toString().contains('apns-token-not-set')) {
        print('🔄 APNS token not set, retrying in 8 seconds...');
        Timer(const Duration(seconds: 8), () => _getFcmToken());
      } else {
        // For other errors, retry in 15 seconds
        print('🔄 General error, retrying in 15 seconds...');
        Timer(const Duration(seconds: 15), () => _getFcmToken());
      }
    }
  }

  Future<void> _updateFcmTokenOnServer() async {
    if (_fcmToken == null) return;
    
    try {
      // Get user type to determine which endpoint to use
      final authService = AuthService();
      final userType = await authService.getUserType();
      
      if (userType == 'provider') {
        // Update provider FCM token
        await _apiService.put('/notifications/provider/fcm-token', {
          'fcmToken': _fcmToken,
        });
        print('✅ Provider FCM token updated on server');
      } else {
        // Update user FCM token
        await _apiService.put('/notifications/fcm-token', {
          'fcmToken': _fcmToken,
        });
        print('✅ User FCM token updated on server');
      }
    } catch (error) {
      print('❌ Error updating FCM token on server: $error');
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('📱 Local notification tapped: ${response.payload}');
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        _onNotificationTappedController.add(data);
        _navigateToScreen(data);
      } catch (error) {
        print('❌ Error parsing notification payload: $error');
      }
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print('📱 Foreground message received: ${message.notification?.title}');
    
    final data = {
      'title': message.notification?.title ?? 'New Notification',
      'body': message.notification?.body ?? '',
      'data': message.data,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    _onNotificationReceivedController.add(data);
    
    // Show popup notification
    _showPopupNotification(
      title: data['title'] as String,
      body: data['body'] as String,
      data: data,
    );
    
    // Also show local notification
    showLocalNotification(
      title: data['title'] as String,
      body: data['body'] as String,
      data: data,
    );
  }

  void _handleNotificationOpenedApp(RemoteMessage message) {
    print('📱 App opened from notification: ${message.notification?.title}');
    
    final data = {
      'title': message.notification?.title ?? 'New Notification',
      'body': message.notification?.body ?? '',
      'data': message.data,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    _onNotificationTappedController.add(data);
    _navigateToScreen(data);
  }

  void _navigateToScreen(Map<String, dynamic> data) {
    // This will be handled by the app's navigation system
    print('🧭 Navigate to screen based on notification data: $data');
  }

  // Show popup notification overlay
  void _showPopupNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) {
    // Use overlay to show popup notification
    _showOverlayNotification(title, body, data);
  }

  // Show a local notification
  Future<void> showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
    int? id,
    String channelId = 'jo_service_general',
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'jo_service_general',
      'General Notifications',
      channelDescription: 'General app notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      id ?? DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      platformChannelSpecifics,
      payload: data != null ? jsonEncode(data) : null,
    );
  }

  // Show booking notification
  Future<void> showBookingNotification({
    required String title,
    required String body,
    required String bookingId,
    Map<String, dynamic>? additionalData,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'jo_service_bookings',
      'Booking Notifications',
      channelDescription: 'Notifications about booking updates',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    final data = {
      'type': 'booking',
      'bookingId': bookingId,
      'timestamp': DateTime.now().toIso8601String(),
      ...?additionalData,
    };

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      platformChannelSpecifics,
      payload: jsonEncode(data),
    );
  }

  // Show chat notification
  Future<void> showChatNotification({
    required String title,
    required String body,
    required String chatId,
    required String senderId,
    Map<String, dynamic>? additionalData,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'jo_service_chat',
      'Chat Notifications',
      channelDescription: 'Notifications about new messages',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    final data = {
      'type': 'chat',
      'chatId': chatId,
      'senderId': senderId,
      'timestamp': DateTime.now().toIso8601String(),
      ...?additionalData,
    };

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      platformChannelSpecifics,
      payload: jsonEncode(data),
    );
  }

  // Show admin notification
  Future<void> showAdminNotification({
    required String title,
    required String body,
    required String adminAction,
    Map<String, dynamic>? additionalData,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'jo_service_admin',
      'Admin Notifications',
      channelDescription: 'Admin-specific notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    final data = {
      'type': 'admin',
      'adminAction': adminAction,
      'timestamp': DateTime.now().toIso8601String(),
      ...?additionalData,
    };

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      platformChannelSpecifics,
      payload: jsonEncode(data),
    );
  }

  // Send test notification
  Future<void> sendTestNotification() async {
    try {
      await _apiService.post('/notifications/test', {});
      print('✅ Test notification sent successfully');
    } catch (error) {
      print('❌ Error sending test notification: $error');
    }
  }

  // Get notification settings
  Future<Map<String, dynamic>?> getNotificationSettings() async {
    try {
      final response = await _apiService.get('/notifications/settings');
      return response['data']['notificationSettings'];
    } catch (error) {
      print('❌ Error getting notification settings: $error');
      return null;
    }
  }

  // Update notification settings
  Future<bool> updateNotificationSettings(Map<String, bool> settings) async {
    try {
      await _apiService.put('/notifications/settings', {
        'notificationSettings': settings,
      });
      print('✅ Notification settings updated successfully');
      return true;
    } catch (error) {
      print('❌ Error updating notification settings: $error');
      return false;
    }
  }

  // Schedule a notification for later
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
    Map<String, dynamic>? data,
    int? id,
  }) async {
    // This would be implemented with flutter_local_notifications scheduling
    // For now, just show immediately as an example
    await showLocalNotification(
      title: title,
      body: body,
      data: data,
      id: id,
    );
  }

  // Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  // Get FCM token
  String? get fcmToken => _fcmToken;
  
  // Manual retry for FCM token (useful for testing)
  Future<void> retryFcmToken() async {
    print('🔄 Manually retrying FCM token retrieval...');
    await _getFcmToken();
  }
  
  // Update FCM token manually (useful for testing)
  Future<void> updateFcmToken() async {
    print('🔄 Manually updating FCM token...');
    await _updateFcmTokenOnServer();
  }
  


  // Check if service is initialized
  bool get isInitialized => _isInitialized;

  // Show overlay popup notification
  void _showOverlayNotification(String title, String body, Map<String, dynamic>? data) {
    print('🎯 Showing popup notification: $title - $body');
    
    // Use the popup notification manager
    PopupNotificationManager().showNotification(
      title: title,
      body: body,
      data: data,
      onTap: () {
        // Handle notification tap
        if (data != null) {
          _navigateToScreen(data);
        }
      },
    );
    
    // Also add to notification stream for UI updates
    _onNotificationReceivedController.add({
      'type': 'popup',
      'title': title,
      'body': body,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
      'showPopup': true,
    });
  }

  void dispose() {
    _onNotificationTappedController.close();
    _onNotificationReceivedController.close();
  }
}

// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📱 Background message received: ${message.notification?.title}');
  // Handle background messages here
}
