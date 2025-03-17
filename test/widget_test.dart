import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hmes/main.dart';
import 'package:hmes/helper/secureStorageHelper.dart';

void main() {
  late bool isLoggedIn; // ✅ Khai báo biến late để gán giá trị sau

  setUpAll(() async {
    String token = (await getToken()).toString();
    String refreshToken = (await getRefreshToken()).toString();
    String deviceId = (await getDeviceId()).toString();

    isLoggedIn =
        token.isNotEmpty && refreshToken.isNotEmpty && deviceId.isNotEmpty;
  });

  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(isLoggedIn: isLoggedIn));

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
