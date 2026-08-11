import 'package:flutter_test/flutter_test.dart';

import 'package:civic_app/main.dart';

void main() {
  testWidgets('app opens from splash to sign in', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('CIVIC CONNECT'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1900));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Civic Connect'), findsOneWidget);
    expect(find.text('Sign In'), findsWidgets);
  });
}
