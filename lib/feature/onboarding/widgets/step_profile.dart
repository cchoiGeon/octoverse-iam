import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:iam/common/constants/defines.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/widgets/ds/ds.dart';

import '../onboarding_controller.dart';
import '../onboarding_view.dart';

/// Step 1 — 닉네임·한 줄 소개·자기소개·관심사·스킬.
class OnboardingStepProfile extends GetView<OnboardingController> {
  const OnboardingStepProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      title: '프로필을 만들어 주세요',
      description: '모임에서 다른 참가자에게 보여질 정보예요.',
      actions: IamButton(
        label: '다음',
        size: IamButtonSize.lg,
        block: true,
        onPressed: controller.next,
      ),
      children: [
        Obx(
          () => IamImageUpload(
            preview: controller.photo.value == null
                ? null
                : FileImage(controller.photo.value!),
            onPick: controller.pickPhoto,
            onRemove: controller.removePhoto,
          ),
        ),
        const SizedBox(height: AppDimens.space5),
        Obx(
          () => IamInput(
            controller: controller.nickname,
            label: '닉네임',
            required: true,
            placeholder: '표시될 이름',
            maxLength: 30,
            error: controller.nicknameError.value,
            onChanged: (_) => controller.nicknameError.value = null,
          ),
        ),
        const SizedBox(height: AppDimens.space5),
        IamInput(
          controller: controller.oneLiner,
          label: '한 줄 소개',
          placeholder: '나를 한 문장으로',
          maxLength: kMaxOneLiner,
        ),
        const SizedBox(height: AppDimens.space5),
        IamTextarea(
          controller: controller.introduction,
          label: '자기소개',
          placeholder: '관심사·하는 일·만나고 싶은 사람 등',
          maxLength: kMaxIntroduction,
          rows: 6,
        ),
        const SizedBox(height: AppDimens.space5),
        Obx(
          () => IamTagSelect(
            label: '관심사',
            options: [
              for (final t in controller.interestOptions)
                IamTagOption('${t.id}', t.label),
            ],
            value: controller.interestIds.toList(),
            onChanged: (v) => controller.interestIds.value = v,
            max: kMaxInterests,
            hint: '최대 $kMaxInterests개까지 선택할 수 있어요.',
          ),
        ),
        const SizedBox(height: AppDimens.space5),
        Obx(
          () => IamTagSelect(
            label: '보유 스킬',
            options: [
              for (final s in controller.skillOptions)
                IamTagOption(s.name, s.name),
            ],
            value: controller.skills.toList(),
            onChanged: (v) => controller.skills.value = v,
            max: kMaxSkills,
            hint: '사전 정의 목록에서 선택 (최대 $kMaxSkills개)',
          ),
        ),
      ],
    );
  }
}
