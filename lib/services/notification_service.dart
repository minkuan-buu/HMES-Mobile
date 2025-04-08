import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import '../context/baseAPI_URL.dart';
import '../models/notification_model.dart';
import '../helper/secureStorageHelper.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    hide NotificationResponse;
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as ln;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  NotificationService._internal();

  final notificationPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initNotification() async {
    if (_isInitialized) return;

    // Define the Android notification channel
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Define iOS settings
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    // Create initialization settings
    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    // Initialize the plugin
    await notificationPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (ln.NotificationResponse details) {
        debugPrint('Notification clicked: ${details.payload}');
      },
    );

    // Request permissions is handled automatically in iOS during initialization
    // Android requires permissions in AndroidManifest.xml

    _isInitialized = true;
    debugPrint('Notification service initialized successfully');
  }

  NotificationDetails notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'hmes_notification_channel', // Channel ID
        'HMES Notifications', // Channel name
        channelDescription: 'Channel for HMES app notifications',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        enableLights: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  Future<void> showNotification({
    int id = 0,
    String? title,
    String? body,
    String? payload,
  }) async {
    if (!_isInitialized) {
      await initNotification();
    }

    debugPrint('Showing notification - Title: $title, Body: $body');

    try {
      await notificationPlugin.show(
        id,
        title,
        body,
        notificationDetails(),
        payload: payload,
      );
      debugPrint('Notification displayed successfully');
    } catch (e) {
      debugPrint('Error showing notification: $e');
      rethrow;
    }
  }

  Future<NotificationApiResponse> getNotifications({
    int pageIndex = 1,
    int pageSize = 10,
    String? keyword,
    String? type,
  }) async {
    String? token = await getToken();
    String refreshToken = (await getRefreshToken()).toString();
    String deviceId = (await getDeviceId()).toString();

    if (token == null || token.isEmpty) {
      throw Exception('Không tìm thấy token đăng nhập');
    }

    String url = '${apiUrl}notify?pageIndex=$pageIndex&pageSize=$pageSize';

    if (keyword != null && keyword.isNotEmpty) {
      url += '&keyword=$keyword';
    }

    if (type != null && type.isNotEmpty) {
      url += '&type=$type';
    }

    try {
      debugPrint('Calling API: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Cookie': 'DeviceId=$deviceId; RefreshToken=$refreshToken',
        },
      );

      debugPrint('API Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('API Response body: ${response.body}');
        return NotificationApiResponse.fromJson(json.decode(response.body));
      } else {
        debugPrint('API Error body: ${response.body}');
        throw Exception('Không thể tải thông báo: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('API call exception: $e');
      rethrow; // Rethrow to let the UI handle it
    }
  }

  Future<bool> markAsRead(String notificationId) async {
    String? token = await getToken();
    String refreshToken = (await getRefreshToken()).toString();
    String deviceId = (await getDeviceId()).toString();

    if (token == null || token.isEmpty) {
      throw Exception('Không tìm thấy token đăng nhập');
    }

    final response = await http.put(
      Uri.parse('${apiUrl}notify/$notificationId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'Cookie': 'DeviceId=$deviceId; RefreshToken=$refreshToken',
      },
    );

    return response.statusCode == 200;
  }

  // Process MQTT notification message
  Future<void> processMqttNotification(String message) async {
    if (!_isInitialized) {
      await initNotification();
    }

    try {
      final Map<String, dynamic> notificationData = jsonDecode(message);

      // Extract notification details from the message
      final String title = notificationData['title'] ?? 'New Notification';
      final String body = notificationData['message'] ?? '';

      // Show local notification
      await showNotification(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: title,
        body: body,
        payload: message,
      );
    } catch (e) {
      debugPrint('Error processing MQTT notification: $e');
    }
  }
}
