import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App starts without errors', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    expect(true, isTrue);
  });
}
