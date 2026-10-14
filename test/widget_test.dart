import 'package:flutter_test/flutter_test.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:ngozi_yangu/app.dart';

void main() {
  testWidgets('login screen renders', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const SuraYanguApp());
    await tester.pumpAndSettle();
    expect(find.text('Sura Yangu'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
  });
}
