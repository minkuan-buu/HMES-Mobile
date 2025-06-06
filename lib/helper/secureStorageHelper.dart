import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const storage = FlutterSecureStorage();

Future<void> saveToken(
  String token,
  String refreshToken,
  String deviceId,
) async {
  await storage.write(key: 'token', value: token);
  await storage.write(key: 'refreshToken', value: refreshToken);
  await storage.write(key: 'deviceId', value: deviceId);
}

Future<void> saveKey(Map<String, String> keyMap) async {
  for (var entry in keyMap.entries) {
    await storage.write(key: entry.key, value: entry.value);
  }
}

Future<String?> getKey(String key) async {
  return await storage.read(key: key) ?? '';
}

Future<void> removeKey(String key) async {
  await storage.delete(key: key);
}

Future<void> updateToken(String token) async {
  await storage.delete(key: 'token');
  await storage.write(key: 'token', value: token);
}

Future<String?> getToken() async {
  return await storage.read(key: 'token') ?? '';
}

Future<String?> getRefreshToken() async {
  return await storage.read(key: 'refreshToken') ?? '';
}

Future<String?> getDeviceId() async {
  return await storage.read(key: 'deviceId') ?? '';
}

Future<void> removeToken() async {
  await storage.delete(key: 'token');
  await storage.delete(key: 'refreshToken');
  await storage.delete(key: 'deviceId');
}
