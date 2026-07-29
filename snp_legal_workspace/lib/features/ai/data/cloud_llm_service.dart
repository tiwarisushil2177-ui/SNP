import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/services/secure_storage_service.dart';
import '../domain/ai_models.dart';

/// Cloud LLM via backend proxy (preferred) or direct API.
class CloudLlmService {
  CloudLlmService(this._storage, {Dio? dio}) : _dio = dio ?? Dio();

  final SecureStorageService _storage;
  final Dio _dio;

  static const _keyProxyBearer = 'snp_llm_proxy_bearer';
  static const _keyProxyUrl = 'snp_llm_proxy_url';
  static const _keyApiKey = 'snp_llm_api_key';
  static const _keyEnabled = 'snp_llm_cloud_enabled';
  static const _keyUseProxy = 'snp_llm_use_proxy';
  static const defaultProxyUrl = 'http://127.0.0.1:8081';

  Future<bool> isEnabled() async =>
      (await _storage.read(_keyEnabled)) == '1';

  Future<void> setEnabled(bool v) async =>
      _storage.write(_keyEnabled, v ? '1' : '0');

  Future<bool> useProxy() async {
    final v = await _storage.read(_keyUseProxy);
    return v != '0';
  }

  Future<void> setUseProxy(bool v) async =>
      _storage.write(_keyUseProxy, v ? '1' : '0');

  Future<String?> getProxyBearer() => _storage.read(_keyProxyBearer);

  Future<void> setProxyBearer(String? token) async {
    if (token == null || token.trim().isEmpty) {
      await _storage.delete(_keyProxyBearer);
    } else {
      await _storage.write(_keyProxyBearer, token.trim());
    }
  }

  Future<String> getProxyUrl() async {
    final v = await _storage.read(_keyProxyUrl);
    if (v == null || v.isEmpty) return defaultProxyUrl;
    return v;
  }

  Future<void> setProxyUrl(String? url) async {
    if (url == null || url.trim().isEmpty) {
      await _storage.delete(_keyProxyUrl);
    } else {
      await _storage.write(_keyProxyUrl, url.trim());
    }
  }

  Future<String?> getApiKey() => _storage.read(_keyApiKey);

  Future<void> setApiKey(String? key) async {
    if (key == null || key.trim().isEmpty) {
      await _storage.delete(_keyApiKey);
    } else {
      await _storage.write(_keyApiKey, key.trim());
    }
  }

  Future<bool> isConfigured() async {
    if (!await isEnabled()) return false;
    if (await useProxy()) {
      final bearer = await getProxyBearer();
      return bearer != null && bearer.isNotEmpty;
    }
    final key = await getApiKey();
    return key != null && key.isNotEmpty;
  }

  Future<AiAssistResult> complete({
    required AiToolType tool,
    required String userPrompt,
    String model = 'gpt-4o-mini',
  }) async {
    if (!await isConfigured()) {
      throw StateError('Cloud LLM not configured.');
    }
    final system = _systemPrompt(tool);
    final proxy = await useProxy();
    late final String url;
    late final Map<String, String> headers;
    if (proxy) {
      final base = (await getProxyUrl()).replaceAll(RegExp(r'/$'), '');
      url = '$base/v1/chat/completions';
      final bearer = await getProxyBearer();
      headers = {
        'Authorization': 'Bearer $bearer',
        'Content-Type': 'application/json',
      };
    } else {
      url = 'https://api.openai.com/v1/chat/completions';
      final apiKey = await getApiKey();
      headers = {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      };
    }
    final res = await _dio.post(
      url,
      options: Options(
        headers: headers,
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
          '[${proxy ? 'Via SNP proxy' : 'Direct LLM'} — review carefully. Not legal advice.]',
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
      AiToolType.plainLanguage =>
        '$base Produce a plain-language client update.',
    };
  }
}
