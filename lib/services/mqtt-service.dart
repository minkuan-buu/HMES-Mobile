import 'dart:async';
import 'dart:convert';

import 'package:hmes/helper/secureStorageHelper.dart';
import 'package:hmes/helper/sharedPreferencesHelper.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:flutter/foundation.dart';
import 'package:hmes/services/notification_service.dart';

class MqttService {
  static final MqttService _instance = MqttService._internal();
  factory MqttService() => _instance;

  final String broker = '14.225.210.123'; // MQTT broker address
  final int port = 1883;
  String clientId = '';
  String? userId;
  MqttServerClient? _client;
  Function(String message)? onNewNotification; // Callback for new notifications
  Function(String message)? onRefreshData;

  // Refresh management variables
  bool _isRefreshing = false;
  StreamSubscription? _notificationSubscription;
  StreamSubscription? _refreshSubscription;

  // Private constructor to ensure a single instance
  MqttService._internal();

  // Connect to MQTT broker
  Future<void> connect() async {
    userId = await getTempKey('userId');
    clientId = (await getDeviceId()) ?? '';

    if (clientId.isEmpty || userId == null) {
      debugPrint('Client ID or User ID is empty, cannot connect to MQTT.');
      return;
    }

    final String notificationTopic = 'push/notification/$userId';
    final String refreshTopic = 'esp32/refresh/$userId';

    _client = MqttServerClient(broker, clientId);
    _client!.port = port;
    _client!.logging(on: false);
    _client!.keepAlivePeriod = 20;
    _client!.onDisconnected = onDisconnected;
    _client!.onConnected = onConnected;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    _client!.connectionMessage = connMessage;

    try {
      await _client!.connect();
      if (_client!.connectionStatus!.state == MqttConnectionState.connected) {
        debugPrint('MQTT Connected successfully');
        debugPrint('MQTT Connected successfully+$userId');
        _subscribeToNotificationTopic(notificationTopic);
      } else {
        debugPrint('MQTT Connection Failed');
        _attemptReconnect();
      }
    } catch (e) {
      debugPrint('MQTT Connection Error: $e');
      _attemptReconnect();
    }
  }

  // Subscribe to notification topic
  void _subscribeToNotificationTopic(String topic) {
    if (_client != null &&
        _client!.connectionStatus != null &&
        _client!.connectionStatus!.state == MqttConnectionState.connected) {
      _client!.subscribe(topic, MqttQos.atLeastOnce);

      _notificationSubscription = _client!.updates?.listen((messages) {
        final MqttPublishMessage recMessage =
            messages[0].payload as MqttPublishMessage;
        final payload = MqttPublishPayload.bytesToStringAsString(
          recMessage.payload.message,
        );

        // Only process notification if not in refresh state
        // if (!_isRefreshing) {
        try {
          final Map<String, dynamic> notificationData = jsonDecode(payload);
          // Check if this is not a refresh response
          if (messages.last.topic == 'push/notification/$userId') {
            debugPrint('Received notification: $payload');

            // Initialize notification service and show notification
            _showNotification(
              notificationData['title'] ?? 'New notification',
              notificationData['message'] ?? '',
            );

            onNewNotification?.call(payload);
          }
        } catch (e) {
          debugPrint('Error parsing notification: $e');
          //onNewNotification?.call();
        }
        // }
      });
    } else {
      debugPrint(
        'Client is not connected, cannot subscribe to notification topic.',
      );
    }
  }

  // Helper method to show notifications
  Future<void> _showNotification(String title, String message) async {
    // Create a new instance and ensure initialization
    final notificationService = NotificationService();

    // Make sure notifications are initialized before showing
    if (!notificationService.isInitialized) {
      await notificationService.initNotification();
    }

    // Generate a unique ID based on time
    final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);

    try {
      await notificationService.showNotification(
        id: id,
        title: title,
        body: message,
      );
      debugPrint('Local notification shown with ID: $id');
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  // Send refresh signal
  Future<void> sendRefreshSignal(String deviceItemId) async {
    // Set refresh state
    // _isRefreshing = true;

    final String topic = 'esp32/refresh/$deviceItemId';
    final String responseTopic = 'esp32/refresh/response/$deviceItemId';

    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    builder.addString('refresh');

    final completer = Completer<void>();

    try {
      if (_client != null &&
          _client!.connectionStatus != null &&
          _client!.connectionStatus!.state == MqttConnectionState.connected) {
        // Subscribe to response topic before sending
        _client!.subscribe(responseTopic, MqttQos.atLeastOnce);

        // Send refresh signal
        await _client!.publishMessage(
          topic,
          MqttQos.atLeastOnce,
          builder.payload!,
        );
        debugPrint('Refresh signal sent to IoT');

        // Listen for refresh response
        _refreshSubscription = _client!.updates?.listen((messages) {
          final MqttPublishMessage recMessage =
              messages[0].payload as MqttPublishMessage;
          final payload = MqttPublishPayload.bytesToStringAsString(
            recMessage.payload.message,
          );

          try {
            final Map<String, dynamic> response = jsonDecode(payload);

            // Check if this is a refresh response
            if (messages.last.topic == responseTopic) {
              onRefreshData?.call(payload);
              debugPrint('Received refresh response: $payload');
              debugPrint('Refresh response received');

              // Unsubscribe from refresh topic
              _client!.unsubscribe(responseTopic);
              _refreshSubscription?.cancel();

              // Complete refresh process
              if (!completer.isCompleted) {
                completer.complete();
              }
            }
          } catch (e) {
            debugPrint('Error parsing refresh response: $e');
          }
        });

        // Timeout for refresh
        Future.delayed(Duration(seconds: 30), () {
          if (!completer.isCompleted) {
            debugPrint('Refresh response timeout');
            onNewNotification?.call('');
            _client!.unsubscribe(responseTopic);
            _refreshSubscription?.cancel();
            //completer.completeError('Timeout');
          }
        });
      } else {
        debugPrint('MQTT Client is not connected. Attempting to reconnect...');
        _attemptReconnect();
        completer.completeError('Not connected');
      }
    } catch (e) {
      debugPrint('Error sending refresh signal: $e');
      _attemptReconnect();
      completer.completeError(e);
    } finally {
      // Ensure refresh state is reset
      return completer.future.whenComplete(() {
        _isRefreshing = false;
      });
    }
  }

  // Attempt to reconnect to MQTT broker
  void _attemptReconnect() {
    Future.delayed(Duration(seconds: 5), () async {
      if (_client == null ||
          _client!.connectionStatus!.state != MqttConnectionState.connected) {
        debugPrint('Attempting to reconnect to MQTT Broker...');
        await connect();
      }
    });
  }

  // Disconnect from MQTT broker
  void disconnect() {
    // Cancel any active subscriptions
    _notificationSubscription?.cancel();
    _refreshSubscription?.cancel();

    // Disconnect the client
    _client?.disconnect();
  }

  // Callback when connected to MQTT broker
  void onConnected() {
    debugPrint('Connected to MQTT Broker');
  }

  // Callback when disconnected from MQTT broker
  void onDisconnected() {
    debugPrint('Disconnected from MQTT Broker');
    _attemptReconnect();
  }
}
