/// 모델 barrel — `import 'package:iam/data/models/models.dart';`
///
/// 서버 계약(REST §0~§9 + Card Exchange + Check-in)의 단일 원천이다.
/// 웹의 `IAM_web/src/types/api.ts` 하나에 있던 것을 도메인별로 나눴다.
library;

export 'auth_model.dart';
export 'channel_model.dart';
export 'page_model.dart';
export 'participation_model.dart';
export 'reference_model.dart';
export 'social_model.dart';
export 'user_model.dart';
