#!/usr/bin/env bash
#
# 일상 실행 스크립트.
#
# 카카오 네이티브 앱 키는 주입 경로가 둘로 갈라져 있다 — 하나만 채우면
# "키는 등록했는데 왜 로그인이 안 되지?" 가 된다. 진입 경로가 카카오 하나뿐이라
# (개발용 로그인은 인증 우회라 제거했다) 키가 비면 앱을 아예 못 쓴다.
#
#   · Android 네이티브(리다이렉트 스킴 kakao{key}://oauth)
#       → gradle 이 환경변수 KAKAO_NATIVE_KEY 또는 android/kakao.properties 를 읽는다
#   · Dart 코드(kKakaoNativeKey · 로그인 분기)
#       → --dart-define 으로만 들어간다. kakao.properties 는 Dart 가 못 본다.
#
# 그래서 여기서 kakao.properties 한 곳을 읽어 양쪽에 같은 값을 흘린다.
# 값을 두 군데 적지 않는 게 핵심이다.
set -euo pipefail

cd "$(dirname "$0")/.."

API_BASE="${API_BASE:-https://dev-api.octoverse.kr/iam/v1}"
WEB_ORIGIN="${WEB_ORIGIN:-https://iam.octoverse.kr}"

# 환경변수가 이미 있으면 존중하고, 없으면 kakao.properties 에서 읽는다
# (gradle 의 우선순위와 같은 순서).
if [[ -z "${KAKAO_NATIVE_KEY:-}" && -f android/kakao.properties ]]; then
  KAKAO_NATIVE_KEY="$(sed -n 's/^kakao\.nativeKey=//p' android/kakao.properties | tr -d '[:space:]')"
fi
KAKAO_NATIVE_KEY="${KAKAO_NATIVE_KEY:-}"

if [[ -z "$KAKAO_NATIVE_KEY" ]]; then
  echo "⚠️  카카오 키 없음 → KakaoSdk.init 를 건너뛰어 로그인이 실패한다(진입 경로가 이것뿐이다)."
  echo "    android/kakao.properties 에 kakao.nativeKey=... 를 넣는다."
else
  echo "✅ 카카오 키 로드됨 (${KAKAO_NATIVE_KEY:0:6}…) → 실 카카오 로그인"
fi

# gradle 이 manifestPlaceholder 로 읽어간다.
export KAKAO_NATIVE_KEY

exec flutter run \
  --dart-define=API_BASE="$API_BASE" \
  --dart-define=WEB_ORIGIN="$WEB_ORIGIN" \
  --dart-define=KAKAO_NATIVE_KEY="$KAKAO_NATIVE_KEY" \
  "$@"
