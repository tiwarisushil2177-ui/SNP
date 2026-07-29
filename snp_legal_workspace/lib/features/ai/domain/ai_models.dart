/// Privacy-first AI assist — templates run on-device; no privileged data
/// is sent to external APIs unless the user explicitly pastes content.

enum AiToolType {
  caseBrief,
  hearingPrep,
  draftOutline,
  checklist,
  plainLanguage;

  String get title {
    switch (this) {
      case AiToolType.caseBrief:
        return 'Case brief outline';
      case AiToolType.hearingPrep:
        return 'Hearing preparation';
      case AiToolType.draftOutline:
        return 'Draft outline';
      case AiToolType.checklist:
        return 'Filing checklist';
      case AiToolType.plainLanguage:
        return 'Plain-language summary';
    }
  }

  String get description {
    switch (this) {
      case AiToolType.caseBrief:
        return 'Structure facts, issues, arguments and prayer.';
      case AiToolType.hearingPrep:
        return 'What to carry, questions to anticipate, orders sought.';
      case AiToolType.draftOutline:
        return 'Skeleton for petition / application / reply.';
      case AiToolType.checklist:
        return 'Court-filing documents and verification steps.';
      case AiToolType.plainLanguage:
        return 'Client-facing summary of status (non-privileged template).';
    }
  }
}

class AiAssistResult {
  const AiAssistResult({
    required this.tool,
    required this.content,
    required this.generatedAt,
  });

  final AiToolType tool;
  final String content;
  final DateTime generatedAt;
}
