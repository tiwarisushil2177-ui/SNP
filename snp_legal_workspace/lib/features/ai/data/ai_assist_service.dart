import '../domain/ai_models.dart';

/// On-device template assist. Does **not** call external LLMs.
/// No API keys. User pastes only what they choose to include.
class AiAssistService {
  AiAssistResult generate({
    required AiToolType tool,
    String? matterTitle,
    String? courtName,
    String? stage,
    String? freeText,
  }) {
    final title = (matterTitle ?? '').trim().isEmpty
        ? '[Matter title]'
        : matterTitle!.trim();
    final court =
        (courtName ?? '').trim().isEmpty ? '[Court]' : courtName!.trim();
    final st = (stage ?? '').trim().isEmpty ? '[Stage]' : stage!.trim();
    final notes = (freeText ?? '').trim();

    final body = switch (tool) {
      AiToolType.caseBrief => _caseBrief(title, court, st, notes),
      AiToolType.hearingPrep => _hearingPrep(title, court, st, notes),
      AiToolType.draftOutline => _draftOutline(title, court, notes),
      AiToolType.checklist => _checklist(title, court, notes),
      AiToolType.plainLanguage => _plainLanguage(title, court, st, notes),
    };

    return AiAssistResult(
      tool: tool,
      content: body,
      generatedAt: DateTime.now(),
    );
  }

  String _caseBrief(String title, String court, String stage, String notes) {
    return '''
CASE BRIEF — $title
Court: $court | Stage: $stage

1. PARTIES
   - Petitioner / Plaintiff:
   - Respondent / Defendant:

2. FACTS (chronology)
   -
   -

3. ISSUES
   1.
   2.

4. PROVISIONS / PRECEDENT RELIED ON
   -

5. ARGUMENTS
   For:
   Against:

6. RELIEF SOUGHT
   -

7. NEXT STEPS
   -

---
Advocate notes:
${notes.isEmpty ? '(none)' : notes}

[Generated on-device by SNP Legal Workspace. Review before use. Not legal advice.]
''';
  }

  String _hearingPrep(String title, String court, String stage, String notes) {
    return '''
HEARING PREP — $title
Court: $court | Stage: $stage

BEFORE COURT
□ Cause list / board number confirmed
□ File with indexed documents
□ Vakalatnama / authorization in order
□ Copies for opposite counsel / court
□ Citations printed / bookmarked

ORDERS / DIRECTIONS SOUGHT
1.
2.

ANTICIPATED QUESTIONS
-
-

FALLBACK IF ADJOURNED
- Next convenient date:
- Interim protection needed? Yes / No

NOTES
${notes.isEmpty ? '(none)' : notes}

[On-device template — SNP Legal Workspace]
''';
  }

  String _draftOutline(String title, String court, String notes) {
    return '''
DRAFT OUTLINE — $title
Court: $court

I. TITLE / CAUSE TITLE
II. PARTIES
III. JURISDICTION & LIMITATION
IV. FACTS
V. GROUNDS
VI. LEGAL PROVISIONS
VII. PRAYER
VIII. VERIFICATION / AFFIDAVIT
IX. ANNEXURES LIST

Working notes:
${notes.isEmpty ? '(none)' : notes}

[On-device template — not a substitute for professional drafting]
''';
  }

  String _checklist(String title, String court, String notes) {
    return '''
FILING CHECKLIST — $title
Court: $court

□ Index / list of dates
□ Memo of parties
□ Petition / application (signed)
□ Vakalatnama
□ Affidavit / verification
□ Court fee / process fee
□ Spare copies as per rules
□ Caveat search (if applicable)
□ Supporting documents marked as annexures
□ Soft copy / e-filing compliance (if e-court)

Notes:
${notes.isEmpty ? '(none)' : notes}

[On-device checklist — SNP Legal Workspace]
''';
  }

  String _plainLanguage(
      String title, String court, String stage, String notes) {
    return '''
CLIENT UPDATE (draft) — $title

Your matter is listed before $court. Current stage: $stage.

In simple terms:
- What happened last:
- What we are asking the court for:
- What you may need to do / provide:
- Next expected date / step:

${notes.isEmpty ? '' : 'Advocate remarks:\n$notes\n'}
This note is for your information only and is not a court order.

[Draft for your review — SNP Legal Workspace]
''';
  }
}
