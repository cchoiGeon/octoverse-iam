import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/widgets/ds/ds.dart';
import 'package:iam/data/data_manager.dart';

import '../onboarding_controller.dart';
import '../onboarding_view.dart';
import 'section_block.dart';

/// Step 2 — 경력 · 이력(학력/자격증/수상/어학) · 외부 링크.
///
/// 셋 다 "목록 + 인라인 추가 폼" 같은 모양이다. 폼 상태는 화면 로컬이라
/// 컨트롤러에 두지 않고 여기서 관리한다(추가되면 컨트롤러 리스트로 넘어간다).
class OnboardingStepHistory extends StatefulWidget {
  const OnboardingStepHistory({super.key});

  @override
  State<OnboardingStepHistory> createState() => _OnboardingStepHistoryState();
}

class _OnboardingStepHistoryState extends State<OnboardingStepHistory> {
  OnboardingController get c => Get.find<OnboardingController>();

  bool _careerOpen = false;
  bool _recordOpen = false;
  bool _linkOpen = false;

  // ── 경력 폼 ─────────────────────────────────────────────────
  final _company = TextEditingController();
  final _title = TextEditingController();
  final _cStart = TextEditingController();
  final _cEnd = TextEditingController();
  final _cDesc = TextEditingController();
  bool _isCurrent = false;
  JobCategory? _jobCategory;

  // ── 이력 폼 ─────────────────────────────────────────────────
  RecordKind _recordKind = RecordKind.education;
  final _school = TextEditingController();
  final _major = TextEditingController();
  final _degree = TextEditingController();
  final _eduStart = TextEditingController();
  final _eduEnd = TextEditingController();
  final _certName = TextEditingController();
  final _certIssuer = TextEditingController();
  final _certDate = TextEditingController();
  final _awardName = TextEditingController();
  final _awardOrg = TextEditingController();
  final _awardDate = TextEditingController();
  final _language = TextEditingController();
  final _langScore = TextEditingController();
  LanguageLevel? _langLevel;

  // ── 링크 폼 ─────────────────────────────────────────────────
  LinkType _linkType = LinkType.sns;
  final _linkUrl = TextEditingController();
  final _linkLabel = TextEditingController();

  @override
  void dispose() {
    for (final ctl in [
      _company,
      _title,
      _cStart,
      _cEnd,
      _cDesc,
      _school,
      _major,
      _degree,
      _eduStart,
      _eduEnd,
      _certName,
      _certIssuer,
      _certDate,
      _awardName,
      _awardOrg,
      _awardDate,
      _language,
      _langScore,
      _linkUrl,
      _linkLabel,
    ]) {
      ctl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      title: '경력·이력을 추가해 보세요',
      description: '나중에 프로필에서도 수정할 수 있어요.',
      actions: Row(
        children: [
          IamButton(
            label: '다음에 하기',
            variant: IamButtonVariant.ghost,
            size: IamButtonSize.lg,
            onPressed: c.skipHistory,
          ),
          const SizedBox(width: AppDimens.space3),
          Expanded(
            child: IamButton(
              label: '다음',
              size: IamButtonSize.lg,
              block: true,
              onPressed: c.next,
            ),
          ),
        ],
      ),
      children: [
        _careerSection(),
        const SizedBox(height: AppDimens.space6),
        _recordSection(),
        const SizedBox(height: AppDimens.space6),
        _linkSection(),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  // 경력
  // ══════════════════════════════════════════════════════════
  Widget _careerSection() {
    return Obx(
      () => SectionBlock(
        title: '경력',
        open: _careerOpen,
        onToggle: () => setState(() => _careerOpen = !_careerOpen),
        children: [
          for (var i = 0; i < c.careers.length; i++)
            EntryCard(
              title: c.careers[i].company,
              subtitle: [
                if (c.careers[i].title != null) c.careers[i].title!,
                c.careers[i].period,
              ].join(' · '),
              onDelete: () => c.removeCareer(i),
            ),
          if (_careerOpen) _careerForm(),
        ],
      ),
    );
  }

  Widget _careerForm() {
    final canAdd =
        _company.text.trim().isNotEmpty && _cStart.text.trim().isNotEmpty;

    return InlineForm(
      children: [
        IamInput(
          controller: _company,
          label: '회사명',
          required: true,
          placeholder: '회사 이름',
          maxLength: 50,
          onChanged: (_) => setState(() {}),
        ),
        IamInput(
          controller: _title,
          label: '직책',
          placeholder: '직책·포지션',
          maxLength: 50,
        ),
        Row(
          children: [
            Expanded(
              child: IamInput(
                controller: _cStart,
                label: '시작',
                required: true,
                placeholder: 'YYYY-MM',
                maxLength: 7,
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: AppDimens.space3),
            Expanded(
              child: IamInput(
                controller: _cEnd,
                label: '종료',
                placeholder: 'YYYY-MM',
                maxLength: 7,
                enabled: !_isCurrent,
              ),
            ),
          ],
        ),
        Row(
          children: [
            IamToggle(
              checked: _isCurrent,
              onChanged: (v) => setState(() => _isCurrent = v),
              semanticLabel: '현재 재직 중',
            ),
            const SizedBox(width: AppDimens.space2),
            const Text('현재 재직 중'),
          ],
        ),
        ChoiceChipRow<JobCategory>(
          label: '직무',
          options: JobCategory.values,
          selected: _jobCategory,
          labelOf: (v) => v.label,
          onSelected: (v) => setState(() => _jobCategory = v),
        ),
        IamTextarea(
          controller: _cDesc,
          label: '업무 설명',
          placeholder: '담당 업무를 간략히',
          maxLength: 300,
          rows: 3,
        ),
        InlineFormActions(
          canAdd: canAdd,
          onCancel: () => setState(() => _careerOpen = false),
          onAdd: _addCareer,
        ),
      ],
    );
  }

  void _addCareer() {
    c.addCareer(
      CareerItem(
        company: _company.text.trim(),
        title: _nullIfEmpty(_title.text),
        startYearMonth: _cStart.text.trim(),
        endYearMonth: _isCurrent ? null : _nullIfEmpty(_cEnd.text),
        isCurrent: _isCurrent,
        description: _nullIfEmpty(_cDesc.text),
        jobCategory: _jobCategory,
      ),
    );
    for (final ctl in [_company, _title, _cStart, _cEnd, _cDesc]) {
      ctl.clear();
    }
    setState(() {
      _isCurrent = false;
      _jobCategory = null;
      _careerOpen = false;
    });
  }

  // ══════════════════════════════════════════════════════════
  // 이력 — 4종을 한 폼에서 종류만 바꿔 입력한다
  // ══════════════════════════════════════════════════════════
  Widget _recordSection() {
    return Obx(
      () => SectionBlock(
        title: '이력',
        open: _recordOpen,
        onToggle: () => setState(() => _recordOpen = !_recordOpen),
        children: [
          for (final e in c.recordEntries)
            EntryCard(
              title: e.title,
              subtitle: e.subtitle,
              onDelete: () => c.removeRecord(e),
            ),
          if (_recordOpen) _recordForm(),
        ],
      ),
    );
  }

  Widget _recordForm() {
    return InlineForm(
      children: [
        ChoiceChipRow<RecordKind>(
          label: '카테고리',
          options: RecordKind.values,
          selected: _recordKind,
          labelOf: (v) => v.label,
          allowDeselect: false,
          onSelected: (v) => setState(() {
            _recordKind = v ?? _recordKind;
            _clearRecordFields();
          }),
        ),
        ..._recordFields(),
        InlineFormActions(
          canAdd: _canAddRecord,
          onCancel: () => setState(() {
            _recordOpen = false;
            _clearRecordFields();
          }),
          onAdd: _addRecord,
        ),
      ],
    );
  }

  List<Widget> _recordFields() => switch (_recordKind) {
    RecordKind.education => [
      IamInput(
        controller: _school,
        label: '학교명',
        placeholder: '학교 이름',
        maxLength: 80,
        onChanged: (_) => setState(() {}),
      ),
      IamInput(
        controller: _major,
        label: '전공',
        placeholder: '전공명',
        maxLength: 80,
        onChanged: (_) => setState(() {}),
      ),
      IamInput(
        controller: _degree,
        label: '학위',
        placeholder: '학사·석사·박사 등',
        maxLength: 40,
      ),
      Row(
        children: [
          Expanded(
            child: IamInput(
              controller: _eduStart,
              label: '입학',
              placeholder: 'YYYY-MM',
              maxLength: 7,
            ),
          ),
          const SizedBox(width: AppDimens.space3),
          Expanded(
            child: IamInput(
              controller: _eduEnd,
              label: '졸업',
              placeholder: 'YYYY-MM',
              maxLength: 7,
            ),
          ),
        ],
      ),
    ],
    RecordKind.certification => [
      IamInput(
        controller: _certName,
        label: '자격증명',
        required: true,
        placeholder: '자격증 이름',
        maxLength: 80,
        onChanged: (_) => setState(() {}),
      ),
      IamInput(
        controller: _certIssuer,
        label: '발급 기관',
        placeholder: '발급 기관',
        maxLength: 60,
      ),
      IamInput(
        controller: _certDate,
        label: '취득일',
        placeholder: 'YYYY-MM',
        maxLength: 7,
      ),
    ],
    RecordKind.award => [
      IamInput(
        controller: _awardName,
        label: '수상명',
        required: true,
        placeholder: '수상 이름',
        maxLength: 80,
        onChanged: (_) => setState(() {}),
      ),
      IamInput(
        controller: _awardOrg,
        label: '수여 기관',
        placeholder: '수여 기관',
        maxLength: 60,
      ),
      IamInput(
        controller: _awardDate,
        label: '수상일',
        placeholder: 'YYYY-MM',
        maxLength: 7,
      ),
    ],
    RecordKind.language => [
      IamInput(
        controller: _language,
        label: '언어',
        required: true,
        placeholder: '영어·일본어·중국어 등',
        maxLength: 30,
        onChanged: (_) => setState(() {}),
      ),
      ChoiceChipRow<LanguageLevel>(
        label: '수준',
        options: LanguageLevel.values,
        selected: _langLevel,
        labelOf: (v) => v.label,
        onSelected: (v) => setState(() => _langLevel = v),
      ),
      IamInput(
        controller: _langScore,
        label: '점수·등급',
        placeholder: 'TOEIC 900·JLPT N1 등 (선택)',
        maxLength: 30,
      ),
    ],
  };

  /// 종류별 최소 입력 조건. 학력만 학교/전공 중 하나면 된다.
  bool get _canAddRecord => switch (_recordKind) {
    RecordKind.education =>
      _school.text.trim().isNotEmpty || _major.text.trim().isNotEmpty,
    RecordKind.certification => _certName.text.trim().isNotEmpty,
    RecordKind.award => _awardName.text.trim().isNotEmpty,
    RecordKind.language => _language.text.trim().isNotEmpty,
  };

  void _addRecord() {
    switch (_recordKind) {
      case RecordKind.education:
        c.addEducation(
          EducationItem(
            school: _nullIfEmpty(_school.text),
            major: _nullIfEmpty(_major.text),
            degree: _nullIfEmpty(_degree.text),
            startYearMonth: _nullIfEmpty(_eduStart.text),
            endYearMonth: _nullIfEmpty(_eduEnd.text),
          ),
        );
      case RecordKind.certification:
        c.addCertification(
          CertificationItem(
            name: _certName.text.trim(),
            issuer: _nullIfEmpty(_certIssuer.text),
            acquiredDate: _nullIfEmpty(_certDate.text),
          ),
        );
      case RecordKind.award:
        c.addAward(
          AwardItem(
            name: _awardName.text.trim(),
            organization: _nullIfEmpty(_awardOrg.text),
            awardedDate: _nullIfEmpty(_awardDate.text),
          ),
        );
      case RecordKind.language:
        c.addLanguage(
          LanguageItem(
            language: _language.text.trim(),
            level: _langLevel,
            score: _nullIfEmpty(_langScore.text),
          ),
        );
    }
    setState(() {
      _clearRecordFields();
      _recordOpen = false;
    });
  }

  void _clearRecordFields() {
    for (final ctl in [
      _school,
      _major,
      _degree,
      _eduStart,
      _eduEnd,
      _certName,
      _certIssuer,
      _certDate,
      _awardName,
      _awardOrg,
      _awardDate,
      _language,
      _langScore,
    ]) {
      ctl.clear();
    }
    _langLevel = null;
  }

  // ══════════════════════════════════════════════════════════
  // 외부 링크
  // ══════════════════════════════════════════════════════════
  Widget _linkSection() {
    return Obx(
      () => SectionBlock(
        title: '외부 링크',
        open: _linkOpen,
        onToggle: () => setState(() => _linkOpen = !_linkOpen),
        children: [
          for (var i = 0; i < c.links.length; i++)
            EntryCard(
              title: c.links[i].label ?? c.links[i].url,
              subtitle: '${c.links[i].type.label} · ${c.links[i].url}',
              onDelete: () => c.removeLink(i),
            ),
          if (_linkOpen) _linkForm(),
        ],
      ),
    );
  }

  Widget _linkForm() {
    return InlineForm(
      children: [
        ChoiceChipRow<LinkType>(
          label: '링크 유형',
          options: LinkType.values,
          selected: _linkType,
          labelOf: (v) => v.label,
          allowDeselect: false,
          onSelected: (v) => setState(() => _linkType = v ?? _linkType),
        ),
        IamInput(
          controller: _linkUrl,
          label: 'URL',
          required: true,
          placeholder: 'https://',
          keyboardType: TextInputType.url,
          onChanged: (_) => setState(() {}),
        ),
        IamInput(
          controller: _linkLabel,
          label: '표시 이름',
          placeholder: '링크 이름 (선택)',
          maxLength: 30,
        ),
        InlineFormActions(
          canAdd: _linkUrl.text.trim().isNotEmpty,
          onCancel: () => setState(() => _linkOpen = false),
          onAdd: _addLink,
        ),
      ],
    );
  }

  void _addLink() {
    final added = c.addLink(
      LinkItem(
        type: _linkType,
        url: _linkUrl.text.trim(),
        label: _nullIfEmpty(_linkLabel.text),
      ),
    );
    if (!added) return;
    _linkUrl.clear();
    _linkLabel.clear();
    setState(() => _linkOpen = false);
  }

  String? _nullIfEmpty(String s) => s.trim().isEmpty ? null : s.trim();
}
