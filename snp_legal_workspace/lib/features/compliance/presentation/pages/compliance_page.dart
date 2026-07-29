import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/services/secure_storage_service.dart';

class CompliancePage extends ConsumerStatefulWidget {
  const CompliancePage({super.key});

  @override
  ConsumerState<CompliancePage> createState() => _CompliancePageState();
}

class _CompliancePageState extends ConsumerState<CompliancePage> {
  bool _busy = false;
  String? _message;

  Future<ApiClient> _client() async {
    final storage = SecureStorageService(
      const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      ),
    );
    return ApiClient(storage);
  }

  Future<void> _recordConsent() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final api = await _client();
      await api.dio.post('/compliance/consent', data: {
        'purpose': 'processing_case_and_client_data',
        'version': '1.0',
        'granted': true,
      });
      setState(
          () => _message = 'Consent recorded on server (account-scoped).');
    } catch (_) {
      setState(() => _message =
          'Could not reach API. Start backend/api on :8090.');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _breachReport() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log breach incident'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(
              hintText: 'What happened (minimal personal data)'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Log')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      final api = await _client();
      await api.dio.post('/compliance/breach-report',
          data: {'summary': ctrl.text.trim()});
      setState(() => _message = 'Breach report logged on account audit trail.');
    } catch (_) {
      setState(() => _message =
          'API unavailable — document offline and notify your DPO.');
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(title: const Text('Privacy & compliance')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'DPDP-oriented controls (account-isolated on SNP API). Not legal advice.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _recordConsent,
            style: FilledButton.styleFrom(backgroundColor: AppColors.deepNavy),
            child: const Text('Record processing consent'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _busy ? null : _breachReport,
            child: const Text('Log potential breach'),
          ),
          if (_message != null) ...[
            const SizedBox(height: 16),
            Text(_message!),
          ],
          const Divider(height: 32),
          const Text(
            '• No public lawyer discovery/ratings (Rule 36).\n'
            '• Server data under per-user directories.\n'
            '• Intake forces DPDP consent; minors need guardian confirm.\n'
            '• API: API_BASE_URL (default 127.0.0.1:8090).',
          ),
        ],
      ),
    );
  }
}
