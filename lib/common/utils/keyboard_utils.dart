import 'package:flutter/widgets.dart';

/// 입력 필드 바깥을 탭했을 때 키보드를 내린다.
///
/// **Flutter 는 이걸 기본으로 해주지 않는다.** 안 넣으면 폼에서 키보드가 화면
/// 절반을 가린 채 안 내려가고, 하단 CTA 바가 가려져 제출을 못 한다.
/// 웹은 브라우저가 알아서 처리해주던 부분이라 이식할 때 빠지기 쉽다.
///
/// `TextField.onTapOutside` 에 그대로 물린다:
///
/// ```dart
/// TextField(onTapOutside: dismissKeyboardOnTapOutside)
/// ```
///
/// 화면 전체를 `GestureDetector` 로 감싸는 방법도 있지만 그러지 않는다 —
/// 앱 전체에 탭 핸들러를 하나 얹는 것보다, 키보드를 띄운 당사자인 입력 필드가
/// 스스로 책임지는 편이 부작용이 없다.
///
/// ⚠️ 필드에서 필드로 이동할 때는 불리지 않는다. Flutter 가 텍스트 필드들을
///    `TextFieldTapRegion` 하나로 묶어두어서, 다른 입력 필드를 탭하는 것은
///    "바깥"으로 치지 않기 때문이다. 그래서 필드 간 이동 시 키보드가
///    깜빡이며 내려갔다 올라오지 않는다.
void dismissKeyboardOnTapOutside(PointerDownEvent _) =>
    FocusManager.instance.primaryFocus?.unfocus();
