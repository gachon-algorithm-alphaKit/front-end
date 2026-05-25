import 'package:flutter_test/flutter_test.dart';

import 'package:alpha_kit/main.dart';

void main() {
  testWidgets('AlphaKit login smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('AlphaKit'), findsOneWidget);
    expect(find.text('아이디'), findsOneWidget);
    expect(find.text('비밀번호'), findsOneWidget);
  });
}
