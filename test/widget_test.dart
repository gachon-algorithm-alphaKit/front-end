import 'package:flutter_test/flutter_test.dart';

import 'package:alpha_kit/main.dart';

void main() {
  testWidgets('AlphaKit dashboard smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('AlphaKit'), findsOneWidget);
    expect(find.text('캠퍼스 종합 서비스'), findsOneWidget);
    expect(find.text('캠퍼스 길찾기'), findsOneWidget);
  });
}
