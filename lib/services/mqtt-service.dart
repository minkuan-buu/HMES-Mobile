import 'package:hmes/helper/sharedPreferencesHelper.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:flutter/foundation.dart';

class MqttService {
  final String broker = '14.225.210.123'; // Thay bằng MQTT broker của bạn
  final int port = 1883;
  final String clientId = 'flutter_client';

  String? userId;
  MqttServerClient? _client;
  Function()? onNewNotification;

  MqttService({this.onNewNotification});

  Future<void> connect() async {
    userId = await getTempKey('userId');
    if (userId == null) {
      debugPrint('User ID is null, cannot subscribe to MQTT.2');
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
      }
    } catch (e) {
      debugPrint('MQTT Connection Error: $e');
    }
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
  }
}
