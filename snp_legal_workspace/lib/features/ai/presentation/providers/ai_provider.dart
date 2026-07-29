import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/ai_assist_service.dart';
import '../../domain/ai_models.dart';

final aiAssistServiceProvider = Provider<AiAssistService>((ref) {
  return AiAssistService();
});

class AiAssistState {
  const AiAssistState({
    this.lastResult,
    this.isGenerating = false,
  });

  final AiAssistResult? lastResult;
  final bool isGenerating;

  AiAssistState copyWith({
    AiAssistResult? lastResult,
    bool? isGenerating,
  }) {
    return AiAssistState(
      lastResult: lastResult ?? this.lastResult,
      isGenerating: isGenerating ?? this.isGenerating,
    );
  }
}

class AiAssistNotifier extends StateNotifier<AiAssistState> {
  AiAssistNotifier(this._service) : super(const AiAssistState());

  final AiAssistService _service;

  void generate({
    required AiToolType tool,
    String? matterTitle,
    String? courtName,
    String? stage,
    String? freeText,
  }) {
    state = state.copyWith(isGenerating: true);
    final result = _service.generate(
      tool: tool,
      matterTitle: matterTitle,
      courtName: courtName,
      stage: stage,
      freeText: freeText,
    );
    state = AiAssistState(lastResult: result, isGenerating: false);
  }

  void clear() => state = const AiAssistState();
}

final aiAssistProvider =
    StateNotifierProvider<AiAssistNotifier, AiAssistState>((ref) {
  return AiAssistNotifier(ref.watch(aiAssistServiceProvider));
});
