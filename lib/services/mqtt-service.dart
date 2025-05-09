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

  // Connection status and tracking
  bool _isConnected = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  Timer? _reconnectTimer;

  // Track processed messages to prevent duplicates
  final Set<String> _processedMessageIds = {};
  static const int _maxProcessedIds =
      100; // Limit how many we track to avoid memory issues

  // Flag to handle startup state
  bool _isInitialConnection = true;
  DateTime _startupTime = DateTime.now();
  static const int _startupGracePeriodMs =
      5000; // 5 seconds grace period on startup

  // Track connection source to avoid duplicates
  String? _connectionSource;
  DateTime? _lastConnectionAttempt;
  static const int _minConnectionIntervalMs =
      2000; // Minimum 2s between connection attempts

  // Private constructor to ensure a single instance
  MqttService._internal();

  // Getter for connection status
  bool get isConnected => _isConnected;

  // Connect to MQTT broker
  Future<bool> connect({String source = 'unknown'}) async {
    // First, check if user is logged in by checking token and user ID
    String? token = await getToken();
    bool isLoggedIn = token != null && token.isNotEmpty;

    if (!isLoggedIn) {
      debugPrint('User is not logged in, cannot connect to MQTT');
      return false;
    }

    // Track connection source and rate limit connection attempts
    final now = DateTime.now();
    if (_lastConnectionAttempt != null) {
      final timeSinceLastAttempt = now.difference(_lastConnectionAttempt!);
      if (timeSinceLastAttempt.inMilliseconds < _minConnectionIntervalMs) {
        debugPrint(
          'Rate limiting connection attempt from $source, too soon after previous attempt',
        );
        // If already connected, return success
        if (_isConnected &&
            _client != null &&
            _client!.connectionStatus!.state == MqttConnectionState.connected) {
          return true;
        }
        // Otherwise wait a bit and retry
        await Future.delayed(Duration(milliseconds: _minConnectionIntervalMs));
      }
    }
    _lastConnectionAttempt = now;

    // Log connection source
    if (_connectionSource == null) {
      _connectionSource = source;
      debugPrint('First connection attempt from: $source');
    } else if (_connectionSource != source) {
      debugPrint(
        'WARNING: Connection attempt from $source, but already connected from $_connectionSource',
      );
    }

    // Reset startup time on each new connection attempt
    if (_isInitialConnection) {
      _startupTime = DateTime.now();
      debugPrint('Initial connection attempt, setting startup time');
    }

    userId = await getTempKey('userId');
    clientId = (await getDeviceId()) ?? '';

    if (clientId.isEmpty || userId == null) {
      debugPrint('Client ID or User ID is empty, cannot connect to MQTT.');
      return false;
    }

    final String notificationTopic = 'push/notification/$userId';
    final String refreshTopic = 'esp32/refresh/$userId';

    // Cleanup any existing connection before creating a new one
    if (_client != null) {
      try {
        _client!.disconnect();
      } catch (e) {
        // Ignore disconnect errors
      }

      // Cancel any existing subscriptions to prevent duplicates
      _notificationSubscription?.cancel();
      _refreshSubscription?.cancel();
    }

    // Create a new client with a unique ID (timestamp) to avoid connection conflicts
    final uniqueId = '$clientId-${DateTime.now().millisecondsSinceEpoch}';
    debugPrint('Creating MQTT client with ID: $uniqueId');
    _client = MqttServerClient(broker, uniqueId);

    // Configure client for better reliability
    _client!.port = port;
    _client!.logging(on: false);
    _client!.keepAlivePeriod =
        60; // 60 seconds keepalive for better background operation
    _client!.autoReconnect = true; // Enable auto reconnect feature
    _client!.onAutoReconnect = onAutoReconnect;
    _client!.onDisconnected = onDisconnected;
    _client!.onConnected = onConnected;
    _client!.onSubscribed = onSubscribed;
    _client!.connectTimeoutPeriod = 5000; // 5 seconds connection timeout

    // Configure connection message with clean session and persistence
    final connMessage = MqttConnectMessage()
        .withClientIdentifier(uniqueId)
        .startClean() // Use clean session
        .withWillQos(MqttQos.atLeastOnce)
        .withWillRetain() // Retain will message
        .withWillTopic('clients/disconnected')
        .withWillMessage('$uniqueId disconnected')
        .authenticateAs(null, null); // No authentication

    _client!.connectionMessage = connMessage;

    try {
      debugPrint('Connecting to MQTT broker: $broker:$port...');
      await _client!.connect();

      if (_client!.connectionStatus!.state == MqttConnectionState.connected) {
        debugPrint('MQTT Connected successfully');
        debugPrint('MQTT Connected successfully+$userId');
        _isConnected = true;
        _reconnectAttempts = 0; // Reset reconnect attempts

        // Subscribe to notification topic with QoS 1 for better delivery guarantee
        _subscribeToNotificationTopic(notificationTopic);
        return true;
      } else {
        debugPrint(
          'MQTT Connection Failed - Status: ${_client!.connectionStatus!.state}',
        );
        _isConnected = false;
        _attemptReconnect();
        return false;
      }
    } catch (e) {
      debugPrint('MQTT Connection Error: $e');
      _isConnected = false;
      _attemptReconnect();
      return false;
    }
  }

  // Subscribe to notification topic
  void _subscribeToNotificationTopic(String topic) {
    if (_client != null &&
        _client!.connectionStatus != null &&
        _client!.connectionStatus!.state == MqttConnectionState.connected) {
      _client!.subscribe(topic, MqttQos.atLeastOnce);
      debugPrint('Subscribed to notification topic: $topic');

      // Cancel any existing subscription before creating a new one
      _notificationSubscription?.cancel();

      _notificationSubscription = _client!.updates?.listen((messages) {
        if (messages.isEmpty) return;

        // Skip processing if the message is not for our notification topic
        // This helps avoid processing refresh messages as notifications
        if (!messages.last.topic.startsWith('push/notification/')) {
          debugPrint(
            'Skipping message for topic: ${messages.last.topic} (not a notification)',
          );
          return;
        }

        final MqttPublishMessage recMessage =
            messages[0].payload as MqttPublishMessage;
        final payload = MqttPublishPayload.bytesToStringAsString(
          recMessage.payload.message,
        );

        try {
          // Check if payload contains Unicode escapes for message field
          if (payload.contains('\\u') && payload.contains('message')) {
            // Use the notification service's decode function
            final notificationService = NotificationService();
            final decodedPayload = notificationService.decodeUnicodeEscapes(
              payload,
            );
            final Map<String, dynamic> notificationData = jsonDecode(
              decodedPayload,
            );

            // Create a unique message ID based on content to avoid duplicates
            final String messageId = _generateMessageId(notificationData);

            // Check if this message should be processed
            if (messages.last.topic == 'push/notification/$userId' &&
                !_isDuplicateMessage(messageId) &&
                !_isStartupMessage()) {
              debugPrint(
                'Received notification: $decodedPayload (ID: $messageId)',
              );

              // Remember that we've processed this message
              _addProcessedMessageId(messageId);

              // First, show the notification
              _showNotification(
                notificationData['title'] ?? 'Thông báo mới',
                notificationData['message'] ?? '',
              );

              // Then inform any UI components that are listening for updates
              if (onNewNotification != null) {
                onNewNotification!(decodedPayload);
              }
            } else if (_isStartupMessage()) {
              debugPrint(
                'Skipping startup message: $messageId (startup grace period)',
              );

              // Still update the UI to show any retained messages, but don't show notification
              if (onNewNotification != null) {
                onNewNotification!(decodedPayload);
              }

              // Still track it to avoid showing it again
              _addProcessedMessageId(messageId);
            } else {
              debugPrint('Skipping duplicate message with ID: $messageId');
            }
          } else {
            // Original handling for standard JSON payloads
            final Map<String, dynamic> notificationData = jsonDecode(payload);

            // Create a unique message ID based on content to avoid duplicates
            final String messageId = _generateMessageId(notificationData);

            // Check if this message should be processed
            if (messages.last.topic == 'push/notification/$userId' &&
                !_isDuplicateMessage(messageId) &&
                !_isStartupMessage()) {
              debugPrint('Received notification: $payload (ID: $messageId)');

              // Remember that we've processed this message
              _addProcessedMessageId(messageId);

              // First, show the notification
              _showNotification(
                notificationData['title'] ?? 'Thông báo mới',
                notificationData['message'] ?? '',
              );

              // Then inform any UI components that are listening for updates
              if (onNewNotification != null) {
                onNewNotification!(payload);
              }
            } else if (_isStartupMessage()) {
              debugPrint(
                'Skipping startup message: $messageId (startup grace period)',
              );

              // Still update the UI to show any retained messages, but don't show notification
              if (onNewNotification != null) {
                onNewNotification!(payload);
              }

              // Still track it to avoid showing it again
              _addProcessedMessageId(messageId);
            } else {
              debugPrint('Skipping duplicate message with ID: $messageId');
            }
          }
        } catch (e) {
          debugPrint('Error parsing notification: $e');
        }
      });

      // After first successful connection, clear the initial connection flag
      Future.delayed(Duration(milliseconds: _startupGracePeriodMs), () {
        if (_isInitialConnection) {
          debugPrint(
            'Startup grace period ended, processing new notifications normally',
          );
          _isInitialConnection = false;
        }
      });
    } else {
      debugPrint(
        'Client is not connected, cannot subscribe to notification topic.',
      );
    }
  }

  // Generate a message ID based on content to detect duplicates
  String _generateMessageId(Map<String, dynamic> notificationData) {
    final title = notificationData['title'] ?? '';
    final message = notificationData['message'] ?? '';
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return '$title-$message-$timestamp';
  }

  // Check if a message is a duplicate we've already processed
  bool _isDuplicateMessage(String messageId) {
    return _processedMessageIds.contains(messageId);
  }

  // Add a message ID to our tracking set, maintaining max size
  void _addProcessedMessageId(String messageId) {
    _processedMessageIds.add(messageId);

    // If we've exceeded our max size, remove the oldest messages
    if (_processedMessageIds.length > _maxProcessedIds) {
      final toRemove = _processedMessageIds.length - _maxProcessedIds;
      _processedMessageIds.toList().sublist(0, toRemove).forEach((id) {
        _processedMessageIds.remove(id);
      });
    }
  }

  // Called when successfully subscribed to a topic
  void onSubscribed(String topic) {
    debugPrint('Subscribed to topic: $topic');
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
    // Cancel any existing refresh subscription to avoid duplicates
    _refreshSubscription?.cancel();
    _refreshSubscription = null;

    final String topic = 'esp32/refresh/$deviceItemId';
    final String responseTopic = 'esp32/refresh/response/$deviceItemId';

    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    builder.addString('refresh');

    final completer = Completer<void>();

    try {
      if (_client != null &&
          _client!.connectionStatus != null &&
          _client!.connectionStatus!.state == MqttConnectionState.connected) {
        // Unsubscribe first to avoid duplicate subscriptions
        _client!.unsubscribe(responseTopic);

        // Then subscribe to response topic
        _client!.subscribe(responseTopic, MqttQos.atLeastOnce);
        debugPrint('Subscribed to refresh response topic: $responseTopic');

        // Set up listener for response before sending refresh command
        _refreshSubscription = _client!.updates?.listen((messages) {
          if (messages.isEmpty) return;

          // Check if this message is for our response topic
          if (messages.last.topic != responseTopic) return;

          final MqttPublishMessage recMessage =
              messages[0].payload as MqttPublishMessage;
          final payload = MqttPublishPayload.bytesToStringAsString(
            recMessage.payload.message,
          );

          debugPrint('Received message on refresh response topic: $payload');

          try {
            // Call onNewNotification with the response payload only if it's a valid refresh response
            // This will update the UI with the new data
            if (onRefreshData != null && payload.isNotEmpty) {
              onRefreshData!(payload);
              debugPrint('Processed refresh response successfully');
            }

            // Complete the refresh process
            if (!completer.isCompleted) {
              completer.complete();
            }
          } catch (e) {
            debugPrint('Error parsing refresh response: $e');
            if (!completer.isCompleted) {
              completer.completeError(e);
            }
          } finally {
            // Clean up subscription to avoid duplicate messages
            _client!.unsubscribe(responseTopic);
            _refreshSubscription?.cancel();
            _refreshSubscription = null;
          }
        });

        // Send refresh signal
        await _client!.publishMessage(
          topic,
          MqttQos.atLeastOnce,
          builder.payload!,
        );
        debugPrint('Refresh signal sent to IoT device: $deviceItemId');

        // Set up timeout for refresh response
        Future.delayed(const Duration(seconds: 30), () {
          if (!completer.isCompleted) {
            debugPrint('Refresh response timeout after 30 seconds');

            // Call with empty string to indicate timeout
            onNewNotification?.call('');

            // Clean up
            _client!.unsubscribe(responseTopic);
            _refreshSubscription?.cancel();
            _refreshSubscription = null;

            completer.complete(); // Complete without error to avoid crashes
          }
        });
      } else {
        debugPrint('MQTT Client is not connected. Attempting to reconnect...');
        await connect(source: 'refresh'); // Try immediate reconnect
        completer.completeError('Not connected');
      }
    } catch (e) {
      debugPrint('Error sending refresh signal: $e');
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
    }

    return completer.future;
  }

  // Attempt to reconnect to MQTT broker with exponential backoff
  void _attemptReconnect() {
    // Cancel any existing reconnect timer
    _reconnectTimer?.cancel();

    // Only attempt reconnect if not connected and within max attempts
    if (!_isConnected && _reconnectAttempts < _maxReconnectAttempts) {
      _reconnectAttempts++;

      // Exponential backoff for reconnect attempts (max 60 seconds)
      final int delaySeconds = _reconnectAttempts * 5;
      debugPrint('Scheduling reconnect attempt $delaySeconds seconds from now');

      _reconnectTimer = Timer(Duration(seconds: delaySeconds), () async {
        debugPrint(
          'Attempting to reconnect to MQTT Broker (attempt $_reconnectAttempts)...',
        );
        await connect();
      });
    } else if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('Max reconnect attempts reached. Will try again later.');
      // Reset for future attempts but with a longer delay
      _reconnectAttempts = 0;
      _reconnectTimer = Timer(Duration(minutes: 5), () async {
        debugPrint('Retrying MQTT connection after cooldown...');
        await connect();
      });
    }
  }

  // Disconnect from MQTT broker
  void disconnect() {
    // Cancel any active subscriptions
    _notificationSubscription?.cancel();
    _refreshSubscription?.cancel();
    _reconnectTimer?.cancel();

    // Disconnect the client
    if (_client != null && _isConnected) {
      try {
        debugPrint('MQTT Disconnecting (initiated by $_connectionSource)');
        _client!.disconnect();
      } catch (e) {
        debugPrint('Error during MQTT disconnect: $e');
      }
    }

    // Clear connection tracking
    _isConnected = false;
    _connectionSource = null;

    debugPrint('MQTT Disconnected manually');
  }

  // Called when auto-reconnect is triggered
  void onAutoReconnect() {
    debugPrint('MQTT auto-reconnect triggered');
    _isConnected = false;
  }

  // Callback when connected to MQTT broker
  void onConnected() {
    _isConnected = true;
    _reconnectAttempts = 0; // Reset reconnect attempts on successful connection

    // If this is the initial app connection, log it
    if (_isInitialConnection) {
      debugPrint(
        'Initial MQTT connection established by $_connectionSource, may skip notifications for ${_startupGracePeriodMs}ms',
      );
    } else {
      debugPrint('Reconnected to MQTT Broker by $_connectionSource');
    }

    debugPrint('Connected to MQTT Broker');
  }

  // Callback when disconnected from MQTT broker
  void onDisconnected() {
    _isConnected = false;
    debugPrint(
      'Disconnected from MQTT Broker (was connected by $_connectionSource)',
    );

    // Only attempt manual reconnect if auto-reconnect fails or isn't configured
    if (!_client!.autoReconnect) {
      _attemptReconnect();
    }
  }

  // Check if this is a message received during startup
  bool _isStartupMessage() {
    if (!_isInitialConnection) return false;

    final now = DateTime.now();
    final timeSinceStartup = now.difference(_startupTime);
    return timeSinceStartup.inMilliseconds < _startupGracePeriodMs;
  }
}
