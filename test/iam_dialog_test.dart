import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iam/common/widgets/ds/ds.dart';

/// `IamDialog`가 **띄워지기만 해도** 터지던 회귀를 막는다.
///
/// 원인: `Semantics(scopesRoute: true)`에 `explicitChildNodes: true`가 빠지면
/// rendering/object.dart의 assert가 빌드 중에 터진다. 정적 분석으로는 안 잡히고
/// 다이얼로그를 실제로 띄워야만 드러난다 — 로그아웃·회원 탈퇴·모임 삭제·
/// 모임 종료·참가 취소·명함 삭제가 전부 이 위젯을 쓴다.
void main() {
  Future<void> pumpAndOpen(WidgetTester tester, {required bool showCancel}) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (c) {
            ctx = c;
            return const Scaffold(body: SizedBox.shrink());
          },
        ),
      ),
    );

    IamDialog.show(
      ctx,
      title: '로그아웃할까요?',
      description: '다시 로그인하면 이어서 쓸 수 있어요.',
      confirmText: '로그아웃',
      showCancel: showCancel,
      tone: IamDialogTone.danger,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('띄우는 것만으로 예외가 나지 않는다', (tester) async {
    await pumpAndOpen(tester, showCancel: true);

    expect(tester.takeException(), isNull);
    expect(find.text('로그아웃할까요?'), findsOneWidget);
    expect(find.text('로그아웃'), findsOneWidget);
    expect(find.text('취소'), findsOneWidget);
  });

  testWidgets('취소 버튼이 없는 형태도 예외가 나지 않는다', (tester) async {
    await pumpAndOpen(tester, showCancel: false);

    expect(tester.takeException(), isNull);
    expect(find.text('취소'), findsNothing);
  });

  testWidgets('확인을 누르면 true, 취소를 누르면 false를 돌려준다', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (c) {
            ctx = c;
            return const Scaffold(body: SizedBox.shrink());
          },
        ),
      ),
    );

    var confirmed = IamDialog.show(ctx, title: '삭제할까요?', confirmText: '삭제');
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    expect(await confirmed, isTrue);

    confirmed = IamDialog.show(ctx, title: '삭제할까요?', confirmText: '삭제');
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(await confirmed, isFalse);
  });
}
