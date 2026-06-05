import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:alpha_kit/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('End-to-End Test: Login -> Campus Nav', (WidgetTester tester) async {
    // 1. 앱 실행 및 로딩 대기
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // 2. 학번 및 비밀번호 입력창 찾아서 텍스트 타이핑하기 (id: byou0070, pw: @134679Vzxo@)
    final idField = find.widgetWithText(TextFormField, '아이디');
    final pwField = find.widgetWithText(TextFormField, '비밀번호');
    
    // 만약 이미 로그인 되어 있다면 이 부분은 스킵하거나 에러가 날 수 있지만, 
    // 처음 실행된다고 가정합니다.
    if (idField.evaluate().isNotEmpty) {
      await tester.enterText(idField, 'byou0070');
      await tester.enterText(pwField, '@134679Vzxo@');
      await tester.pumpAndSettle();

      // 3. '로그인' 버튼 터치(클릭)하기
      final loginBtn = find.widgetWithText(FilledButton, '로그인');
      await tester.tap(loginBtn);
      
      // API 호출 대기 (최대 10초)
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(seconds: 1));
        if (find.text('오늘의 토픽').evaluate().isNotEmpty) {
          break;
        }
      }
    }

    // 4. 대시보드 화면으로 정상적으로 넘어갔는지(오늘의 토픽 widget이 보이는지) 시각적 확인하기
    final topicWidget = find.text('오늘의 토픽');
    expect(topicWidget, findsWidgets);

    // 5. 캠퍼스 길찾기 실행
    final navButton = find.text('캠퍼스 길찾기');
    await tester.tap(navButton);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 6. 경유지 2번 추가
    final addWaypointBtn = find.text('경유지 추가');
    await tester.tap(addWaypointBtn);
    await tester.pumpAndSettle();
    await tester.tap(addWaypointBtn);
    await tester.pumpAndSettle();

    // 7. 출발지: AI관, 도착지: 비전타워, 경유지1: 운동장, 경유지2: 중앙도서관 입력
    final departField = find.widgetWithText(TextField, '출발지');
    final destField = find.widgetWithText(TextField, '도착지');
    final wp1Field = find.widgetWithText(TextField, '경유지 1');
    final wp2Field = find.widgetWithText(TextField, '경유지 2');

    await tester.enterText(departField, 'AI관');
    await tester.pumpAndSettle();
    await tester.enterText(destField, '비전타워');
    await tester.pumpAndSettle();
    await tester.enterText(wp1Field, '운동장');
    await tester.pumpAndSettle();
    await tester.enterText(wp2Field, '중앙도서관');
    await tester.pumpAndSettle();

    // 키보드 내리기
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    // 8. 최적 경로 탐색 클릭
    final searchBtn = find.text('최적 경로 탐색');
    await tester.ensureVisible(searchBtn);
    await tester.tap(searchBtn);
    
    // 탐색 완료 대기
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    // 9. 스크롤 내려서 "그래프 시각화", "네이버 지도"(불러와 진거) 각각 3초 확인
    final graphTab = find.text('그래프 시각화');
    final naverMapTab = find.text('네이버 지도');
    
    if (graphTab.evaluate().isNotEmpty) {
      await tester.ensureVisible(graphTab);
      await tester.tap(graphTab);
      // 3초 대기 (시각적 확인)
      await tester.pump(const Duration(seconds: 3));
    }
    
    if (naverMapTab.evaluate().isNotEmpty) {
      await tester.ensureVisible(naverMapTab);
      await tester.tap(naverMapTab);
      // 3초 대기 (시각적 확인)
      await tester.pump(const Duration(seconds: 3));
    }

    // 10. 대시보드로 돌아오기
    final backButton = find.byTooltip('Back');
    if (backButton.evaluate().isNotEmpty) {
      await tester.tap(backButton);
    } else {
      // 툴팁이 없으면 pop 시도
      final BuildContext context = tester.element(find.byType(Scaffold).last);
      Navigator.pop(context);
    }
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('오늘의 토픽'), findsWidgets);
  });
}
