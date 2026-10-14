import 'package:flutter_test/flutter_test.dart';

import 'package:ngozi_yangu/app.dart';

void main() {
  testWidgets('login screen renders', (tester) async {
    await tester.pumpWidget(const SuraYanguApp());
    expect(find.text('Sura Yangu'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
  });
}
