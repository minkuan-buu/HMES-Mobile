import 'package:hmes/helper/secureStorageHelper.dart';
import 'package:hmes/helper/sharedPreferencesHelper.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:flutter/foundation.dart';

class MqttService {
  final String broker = '14.225.210.123'; // Thay bằng MQTT broker của bạn
  final int port = 1883;
  String clientId = '';

  String? userId;
  MqttServerClient? _client;
  Function()? onNewNotification;

  MqttService({this.onNewNotification});

  Future<void> connect() async {
    userId = await getTempKey('userId');
    clientId = (await getDeviceId()) ?? '';
    // Client ID is guaranteed to be non-null, so this check is unnecessary.
    if (clientId.isEmpty) {
      debugPrint('Client ID is empty, cannot subscribe to MQTT.');
      return;
    }
    if (userId == null) {
      debugPrint('User ID is null, cannot subscribe to MQTT.');
      return;
    }

    final String topic = 'push/notification/$userId';
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
        debugPrint('MQTT Connected');
        _subscribeToTopic(topic);
      } else {
        debugPrint('MQTT Connection Failed');
        _attemptReconnect();
      }
    } catch (e) {
      debugPrint('MQTT Connection Error: $e');
      _attemptReconnect();
    }
  }

  void _attemptReconnect() {
    Future.delayed(Duration(seconds: 5), () {
      if (_client == null ||
          _client!.connectionStatus!.state != MqttConnectionState.connected) {
        debugPrint('Reconnecting to MQTT Broker...');
        connect();
      }
    });
  }

  void _subscribeToTopic(String topic) {
    _client!.subscribe(topic, MqttQos.atLeastOnce);
    _client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      final MqttPublishMessage recMessage =
          messages[0].payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(
        recMessage.payload.message,
      );
      debugPrint('Received: $payload');
      if (onNewNotification != null) {
        onNewNotification!(); // Gọi hàm cập nhật UI
      }
    });
  }

  void disconnect() {
    _client?.disconnect();
  }

  void onConnected() {
    debugPrint('Connected to MQTT Broker');
  }

  void onDisconnected() {
    debugPrint('Disconnected from MQTT Broker');
    Future.delayed(Duration(seconds: 5), () {
      if (_client != null &&
          _client!.connectionStatus!.state != MqttConnectionState.connected) {
        debugPrint('Reconnecting to MQTT Broker...');
        connect();
      }
    });
  }
}
