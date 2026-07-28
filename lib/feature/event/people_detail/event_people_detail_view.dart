import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/widgets/ds/ds.dart';
import 'package:iam/data/data_manager.dart';

import 'event_people_detail_controller.dart';

/// 08 프로필 상세 — 찜 · 명함 교환.
///
/// 라우트   : AppRoutes.eventPeopleDetail
/// 웹 대응  : `IAM_web/src/app/(app)/event/[slug]/people/[userId]/page.tsx`
/// 디자인   : Figma `3.UI` node 116:389 · v3-07 (239:1012)
class EventPeopleDetailView extends GetView<EventPeopleDetailController> {
  const EventPeopleDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfacePage,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            IamAppHeader(
              title: '프로필',
              onBack: Get.back,
              variant: IamHeaderVariant.center,
            ),
            Expanded(child: Obx(_body)),
          ],
        ),
      ),
      bottomNavigationBar: Obx(_bottomBar),
    );
  }

  Widget _body() {
    if (controller.isLoading.value) return _skeleton();
    final u = controller.user.value;
    if (u == null) {
      final notFound = controller.notFound.value;
      return Center(
        child: IamEmptyState(
          icon: notFound ? IamIconName.user : IamIconName.alertCircle,
          title: notFound ? '존재하지 않는 사용자예요' : '불러오기 실패',
          description: notFound
              ? '탈퇴했거나 잘못된 링크예요.'
              : '네트워크 문제가 생겼어요. 다시 시도해 주세요.',
          action: notFound
              ? null
              : IamButton(
                  label: '다시 시도',
                  variant: IamButtonVariant.secondary,
                  size: IamButtonSize.sm,
                  onPressed: controller.load,
                ),
        ),
      );
    }
    return SingleChildScrollView(child: _detail(u));
  }

  Widget _detail(PublicUser u) {
    return IamProfileDetail(
      name: u.nickname,
      photo: u.photoUrl,
      headline: u.oneLiner,
      introduction: u.introduction,
      tags: [for (final t in u.interests) t.label],
      careers: [
        for (final c in u.careers ?? const <CareerItem>[])
          ProfileCareerRow(
            company: c.company,
            title: c.title,
            period: c.period,
            current: c.isCurrent,
          ),
      ],
      records: _records(u),
      skills: u.skills ?? const [],
      links: [
        for (final l in u.links ?? const <LinkItem>[])
          ProfileLinkRow(type: l.type, label: l.label ?? l.url, url: l.url),
      ],
      onOpenLink: (l) => l.url == null ? null : controller.openLink(l.url!),
    );
  }

  /// 학력·자격증·수상·어학 4개 배열을 한 목록으로 합친다.
  List<ProfileRecordRow> _records(PublicUser u) => [
    for (final e in u.educations ?? const <EducationItem>[])
      ProfileRecordRow(
        kind: RecordKind.education.label,
        title: [
          e.school,
          e.major,
          e.degree,
        ].where((s) => s != null && s.isNotEmpty).join(' · ').nonEmptyOr('학력'),
        subtitle: [
          e.startYearMonth,
          e.endYearMonth,
        ].where((s) => s != null && s.isNotEmpty).join(' – ').orNull(),
      ),
    for (final c in u.certifications ?? const <CertificationItem>[])
      ProfileRecordRow(
        kind: RecordKind.certification.label,
        title: c.name,
        subtitle: [
          c.issuer,
          c.acquiredDate,
        ].where((s) => s != null && s.isNotEmpty).join(' · ').orNull(),
      ),
    for (final a in u.awards ?? const <AwardItem>[])
      ProfileRecordRow(
        kind: RecordKind.award.label,
        title: a.name,
        subtitle: [
          a.organization,
          a.awardedDate,
        ].where((s) => s != null && s.isNotEmpty).join(' · ').orNull(),
      ),
    for (final l in u.languages ?? const <LanguageItem>[])
      ProfileRecordRow(
        kind: RecordKind.language.label,
        title: l.language,
        subtitle: [
          l.level?.label,
          l.score,
        ].where((s) => s != null && s.isNotEmpty).join(' · ').orNull(),
      ),
  ];

  Widget _skeleton() => const Padding(
    padding: EdgeInsets.symmetric(
      horizontal: AppDimens.gutterMobile,
      vertical: AppDimens.space6,
    ),
    child: Column(
      children: [
        IamSkeleton.circle(width: 88),
        SizedBox(height: AppDimens.space3),
        IamSkeleton(width: 100, height: 22),
        SizedBox(height: AppDimens.space2),
        IamSkeleton(width: 200, height: 16),
        SizedBox(height: AppDimens.space6),
        IamSkeleton.block(height: 72),
      ],
    ),
  );

  // ── 하단 CTA ────────────────────────────────────────────────
  Widget _bottomBar() {
    // 본인 프로필에는 액션이 없다.
    if (controller.isLoading.value ||
        controller.user.value == null ||
        controller.isMe) {
      return const SizedBox.shrink();
    }

    final cta = controller.exchangeCta;

    return IamBottomCTABar(
      info: _caption(cta),
      children: [
        IamLikeButton(
          variant: IamLikeVariant.pill,
          liked: controller.liked.value,
          enabled:
              controller.bothMembers.value && !controller.likePending.value,
          onChanged: (_) => controller.toggleLike(),
        ),
        Expanded(child: _exchangeButton(cta)),
      ],
    );
  }

  Widget _exchangeButton(CardExchangeCta cta) => switch (cta) {
    CardExchangeCta.active => IamButton(
      label: '명함 교환 요청',
      size: IamButtonSize.lg,
      block: true,
      onPressed: () => _confirmExchange(Get.context!),
    ),
    CardExchangeCta.loading => const IamButton(
      label: '명함 교환 요청',
      size: IamButtonSize.lg,
      block: true,
      loading: true,
    ),
    CardExchangeCta.noOwnCard => const IamButton(
      label: '명함 교환 요청',
      size: IamButtonSize.lg,
      block: true,
      enabled: false,
    ),
    CardExchangeCta.pending => const IamButton(
      label: '교환 대기중',
      size: IamButtonSize.lg,
      block: true,
      enabled: false,
    ),
    CardExchangeCta.incoming => IamButton(
      label: '명함 교환 수락',
      size: IamButtonSize.lg,
      block: true,
      onPressed: controller.acceptExchange,
    ),
    CardExchangeCta.done => IamButton(
      label: '교환 완료 · 명함첩에서 보기',
      variant: IamButtonVariant.accent,
      size: IamButtonSize.lg,
      block: true,
      iconLeft: const IamIcon(
        IamIconName.check,
        size: 18,
        color: AppColors.gray0,
      ),
      onPressed: controller.openMyCards,
    ),
  };

  /// 버튼만으로는 왜 못 누르는지 알 수 없다 — 한 줄로 이유를 알린다.
  Widget? _caption(CardExchangeCta cta) {
    final name = controller.user.value?.nickname ?? '';
    final text = switch (cta) {
      CardExchangeCta.noOwnCard => '명함 교환은 내 명함이 필요해요',
      CardExchangeCta.pending => '상대의 수락을 기다리는 중이에요',
      CardExchangeCta.incoming => '$name님이 명함 교환을 요청했어요',
      _ when !controller.bothMembers.value => '참가가 확정된 사람끼리만 찜할 수 있어요',
      CardExchangeCta.active => '찜은 상대에게 알려져요 · 명함은 수락 시 공개돼요',
      _ => null,
    };
    if (text == null) return null;

    return Text(
      text,
      textAlign: TextAlign.center,
      style: AppTypography.caption.copyWith(
        height: 1.4,
        color: AppColors.textTertiary,
      ),
    );
  }

  Future<void> _confirmExchange(BuildContext context) async {
    final name = controller.user.value?.nickname ?? '';
    final ok = await IamDialog.show(
      context,
      title: '명함을 교환할까요?',
      description: '$name님에게 명함 교환을 요청해요. 상대가 수락하면 서로의 명함이 공개돼요.',
      confirmText: '요청 보내기',
    );
    if (ok) await controller.requestExchange();
  }
}

/// 빈 문자열 정리용 — 이력 표시 문자열 조합에서만 쓴다.
extension _StringFallback on String {
  String nonEmptyOr(String fallback) => isEmpty ? fallback : this;
  String? orNull() => isEmpty ? null : this;
}
