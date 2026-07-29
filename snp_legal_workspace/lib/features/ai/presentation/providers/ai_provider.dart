import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/security/security_providers.dart';
import '../../data/ai_assist_service.dart';
import '../../data/cloud_llm_service.dart';
import '../../domain/ai_models.dart';

final aiAssistServiceProvider = Provider<AiAssistService>((ref) {
  return AiAssistService();
});

final cloudLlmServiceProvider = Provider<CloudLlmService>((ref) {
  return CloudLlmService(ref.watch(secureStorageProvider));
});

enum AiMode { onDevice, cloud }

class AiAssistState {
  const AiAssistState({
    this.lastResult,
    this.isGenerating = false,
    this.mode = AiMode.onDevice,
    this.cloudConfigured = false,
    this.error,
  });

  final AiAssistResult? lastResult;
  final bool isGenerating;
  final AiMode mode;
  final bool cloudConfigured;
  final String? error;

  AiAssistState copyWith({
    AiAssistResult? lastResult,
    bool? isGenerating,
    AiMode? mode,
    bool? cloudConfigured,
    String? error,
    bool clearError = false,
    bool clearResult = false,
  }) {
    return AiAssistState(
      lastResult: clearResult ? null : (lastResult ?? this.lastResult),
      isGenerating: isGenerating ?? this.isGenerating,
      mode: mode ?? this.mode,
      cloudConfigured: cloudConfigured ?? this.cloudConfigured,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AiAssistNotifier extends StateNotifier<AiAssistState> {
  AiAssistNotifier(this._local, this._cloud) : super(const AiAssistState()) {
    _refreshCloudFlag();
  }

  final AiAssistService _local;
  final CloudLlmService _cloud;

  Future<void> _refreshCloudFlag() async {
    final configured = await _cloud.isConfigured();
    state = state.copyWith(cloudConfigured: configured);
  }

  void setMode(AiMode mode) {
    state = state.copyWith(mode: mode, clearError: true);
  }

  Future<void> saveCloudSettings({
    required bool enabled,
    String? apiKey,
    String? baseUrl,
    String? proxyBearer,
    String? proxyUrl,
    bool? useProxy,
  }) async {
    await _cloud.setEnabled(enabled);
    if (useProxy != null) await _cloud.setUseProxy(useProxy);
    if (proxyBearer != null) await _cloud.setProxyBearer(proxyBearer);
    if (proxyUrl != null) await _cloud.setProxyUrl(proxyUrl);
    if (apiKey != null) await _cloud.setApiKey(apiKey);
    await _refreshCloudFlag();
  }

  Future<void> generate({
    required AiToolType tool,
    String? matterTitle,
    String? courtName,
    String? stage,
    String? freeText,
  }) async {
    state = state.copyWith(isGenerating: true, clearError: true);
    try {
      if (state.mode == AiMode.cloud) {
        final prompt = '''
Tool: ${tool.title}
Matter: ${matterTitle ?? ''}
Court: ${courtName ?? ''}
Stage: ${stage ?? ''}
Notes: ${freeText ?? ''}
''';
        final result = await _cloud.complete(tool: tool, userPrompt: prompt);
        state = state.copyWith(lastResult: result, isGenerating: false);
      } else {
        final result = _local.generate(
          tool: tool,
          matterTitle: matterTitle,
          courtName: courtName,
          stage: stage,
          freeText: freeText,
        );
        state = state.copyWith(lastResult: result, isGenerating: false);
      }
    } catch (e) {
      state = state.copyWith(
        isGenerating: false,
        error: e.toString().replaceFirst('StateError: ', ''),
      );
    }
  }

  void clear() => state = AiAssistState(
        mode: state.mode,
        cloudConfigured: state.cloudConfigured,
      );
}

final aiAssistProvider =
    StateNotifierProvider<AiAssistNotifier, AiAssistState>((ref) {
  return AiAssistNotifier(
    ref.watch(aiAssistServiceProvider),
    ref.watch(cloudLlmServiceProvider),
  );
});
