import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/widgets/ds/ds.dart';
import 'package:iam/data/data_manager.dart';

import 'channel_form_controller.dart';
import 'schedule_field.dart';

/// 모임 생성·수정이 공유하는 입력 본문.
/// 두 화면의 차이는 헤더 문구와 제출 동작뿐이라 폼은 하나로 둔다.
class ChannelFormBody extends StatelessWidget {
  const ChannelFormBody({super.key, required this.controller});

  final ChannelFormMixin controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      // 하단 여백 0 — 마지막 항목("공개 모임")이 하단 CTA 바에 바로 붙는다.
      // 여백을 두면 스크롤 끝에 빈 공간이 남아 폼이 덜 끝난 것처럼 보인다.
      padding: const EdgeInsets.fromLTRB(
        AppDimens.gutterMobile,
        AppDimens.space5,
        AppDimens.gutterMobile,
        0,
      ),
      children: [
        Obx(
          () => IamImageUpload(
            label: '커버 이미지',
            required: true,
            error: controller.coverError.value,
            shape: IamImageShape.card,
            placeholder: '모임을 대표할 이미지',
            preview: controller.coverFile.value != null
                ? FileImage(controller.coverFile.value!)
                : (controller.coverUrl.value != null
                          ? NetworkImage(controller.coverUrl.value!)
                          : null)
                      as ImageProvider?,
            onPick: controller.pickCover,
            onRemove: controller.removeCover,
          ),
        ),
        const SizedBox(height: AppDimens.space5),
        Obx(
          () => IamInput(
            controller: controller.title,
            label: '모임 이름',
            required: true,
            placeholder: '예: 판교 AI 사이드프로젝트 밋업',
            maxLength: 50,
            error: controller.titleError.value,
            onChanged: (_) => controller.titleError.value = null,
          ),
        ),
        const SizedBox(height: AppDimens.space5),
        Obx(
          () => ScheduleField(
            start: controller.startAt.value,
            end: controller.endAt.value,
            error: controller.scheduleError.value,
            onChanged: controller.setSchedule,
          ),
        ),
        const SizedBox(height: AppDimens.space5),
        Obx(
          () => IamInput(
            controller: controller.location,
            label: '장소',
            required: true,
            placeholder: '예: 강남 위워크 12F',
            error: controller.locationError.value,
            onChanged: (_) => controller.locationError.value = null,
          ),
        ),
        const SizedBox(height: AppDimens.space5),
        Obx(
          () => IamInput(
            controller: controller.capacity,
            label: '정원',
            required: true,
            placeholder: '30',
            suffix: '명',
            keyboardType: TextInputType.number,
            error: controller.capacityError.value,
            onChanged: (_) => controller.capacityError.value = null,
          ),
        ),
        const SizedBox(height: AppDimens.space5),
        Obx(() => _categoryGroup()),
        const SizedBox(height: AppDimens.space5),
        Obx(
          () => IamTagSelect(
            label: '관련 관심사',
            options: [
              for (final t in controller.reference.interests)
                IamTagOption('${t.id}', t.label),
            ],
            value: controller.interestIds.toList(),
            onChanged: (v) => controller.interestIds.value = v,
            max: 5,
            hint: '참가자가 모임을 찾는 데 쓰여요. 최대 5개.',
          ),
        ),
        const SizedBox(height: AppDimens.space5),
        IamTextarea(
          controller: controller.description,
          label: '모임 소개',
          placeholder: '어떤 모임인지, 누가 오면 좋을지 적어주세요',
          maxLength: 2000,
          rows: 5,
        ),
        const SizedBox(height: AppDimens.space5),
        Obx(
          () => IamListItem(
            title: '공개 모임',
            description: '끄면 링크·QR을 아는 사람만 들어올 수 있어요',
            showChevron: false,
            trailing: IamToggle(
              checked: controller.isPublic.value,
              onChanged: (v) => controller.isPublic.value = v,
              semanticLabel: '공개 모임',
            ),
          ),
        ),
      ],
    );
  }

  /// 카테고리는 단일 선택이라 `IamTagSelect`(다중) 대신 칩 그룹으로 둔다.
  Widget _categoryGroup() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          const TextSpan(
            text: '카테고리',
            children: [
              TextSpan(
                text: ' *',
                style: TextStyle(color: AppColors.error600),
              ),
            ],
          ),
          style: AppTypography.bodyS.copyWith(
            height: 1.3,
            fontWeight: AppTypography.semibold,
          ),
        ),
        const SizedBox(height: AppDimens.space2),
        Wrap(
          spacing: AppDimens.space2,
          runSpacing: AppDimens.space2,
          children: [
            for (final c in EventCategory.values)
              IamFilterChip(
                label: c.label,
                selected: controller.category.value == c,
                size: IamFilterChipSize.sm,
                onTap: () {
                  controller.category.value = controller.category.value == c
                      ? null
                      : c;
                  controller.categoryError.value = null;
                },
              ),
          ],
        ),
        if (controller.categoryError.value != null) ...[
          const SizedBox(height: AppDimens.space2),
          Text(
            controller.categoryError.value!,
            style: AppTypography.caption.copyWith(
              height: 1.4,
              color: AppColors.error700,
            ),
          ),
        ],
      ],
    );
  }
}
