import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/services/secure_storage_service.dart';
import '../domain/ai_models.dart';

/// Optional cloud LLM. API key stored only in secure storage.
class CloudLlmService {
  CloudLlmService(this._storage, {Dio? dio}) : _dio = dio ?? Dio();

  final SecureStorageService _storage;
  final Dio _dio;

  static const _keyApiKey = 'snp_llm_api_key';
  static const _keyEnabled = 'snp_llm_cloud_enabled';
  static const _keyBaseUrl = 'snp_llm_base_url';
  static const defaultBaseUrl = 'https://api.openai.com/v1';

  Future<bool> isEnabled() async =>
      (await _storage.read(_keyEnabled)) == '1';

  Future<void> setEnabled(bool v) async =>
      _storage.write(_keyEnabled, v ? '1' : '0');

  Future<String?> getApiKey() => _storage.read(_keyApiKey);

  Future<void> setApiKey(String? key) async {
    if (key == null || key.trim().isEmpty) {
      await _storage.delete(_keyApiKey);
    } else {
      await _storage.write(_keyApiKey, key.trim());
    }
  }

  Future<String> getBaseUrl() async {
    final v = await _storage.read(_keyBaseUrl);
    if (v == null || v.isEmpty) return defaultBaseUrl;
    return v;
  }

  Future<void> setBaseUrl(String? url) async {
    if (url == null || url.trim().isEmpty) {
      await _storage.delete(_keyBaseUrl);
    } else {
      await _storage.write(_keyBaseUrl, url.trim());
    }
  }

  Future<bool> isConfigured() async {
    final key = await getApiKey();
    return key != null && key.isNotEmpty && await isEnabled();
  }

  Future<AiAssistResult> complete({
    required AiToolType tool,
    required String userPrompt,
    String model = 'gpt-4o-mini',
  }) async {
    if (!await isConfigured()) {
      throw StateError(
        'Cloud LLM is off or API key missing. Enable under AI settings.',
      );
    }
    final apiKey = await getApiKey();
    final base = await getBaseUrl();
    final system = _systemPrompt(tool);

    final res = await _dio.post(
      '$base/chat/completions',
      options: Options(
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 30),
      ),
      data: {
        'model': model,
        'temperature': 0.3,
        'messages': [
          {'role': 'system', 'content': system},
          {'role': 'user', 'content': userPrompt},
        ],
      },
    );

    final data = res.data is Map
        ? Map<String, dynamic>.from(res.data as Map)
        : jsonDecode(res.data as String) as Map<String, dynamic>;
    final choices = data['choices'] as List? ?? const [];
    if (choices.isEmpty) throw StateError('Empty response from LLM');
    final message = choices.first['message'] as Map? ?? {};
    final content = (message['content'] as String? ?? '').trim();
    if (content.isEmpty) throw StateError('Empty content from LLM');

    return AiAssistResult(
      tool: tool,
      content: '$content\n\n'
          '[Cloud LLM — review carefully. Not legal advice.]',
      generatedAt: DateTime.now(),
    );
  }

  String _systemPrompt(AiToolType tool) {
    const base =
        'You assist an Indian advocate. Do not invent citations. Not legal advice.';
    return switch (tool) {
      AiToolType.caseBrief => '$base Produce a structured case brief.',
      AiToolType.hearingPrep => '$base Produce hearing preparation notes.',
      AiToolType.draftOutline => '$base Produce a draft outline only.',
      AiToolType.checklist => '$base Produce a court filing checklist.',
      AiToolType.plainLanguage => '$base Produce a plain-language client update.',
    };
  }
}
