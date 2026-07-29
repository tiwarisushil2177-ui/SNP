import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/compliance_api.dart';

class CompliancePage extends ConsumerStatefulWidget {
  const CompliancePage({super.key});

  @override
  ConsumerState<CompliancePage> createState() => _CompliancePageState();
}

class _CompliancePageState extends ConsumerState<CompliancePage> {
  bool _busy = false;
  String? _message;
  List<dynamic> _consents = const [];
  List<dynamic> _audit = const [];
  Map<String, dynamic>? _retention;

  ComplianceApi _api() {
    final storage = SecureStorageService(
      const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      ),
    );
    return ComplianceApi(ApiClient(storage));
  }

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final api = _api();
      final consents = await api.consents();
      final audit = await api.auditLogs();
      final retention = await api.retention();
      if (!mounted) return;
      setState(() {
        _consents = consents;
        _audit = audit.take(40).toList();
        _retention = retention;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message = 'API offline. Start backend/api on :8090 and sign in.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _recordConsent() async {
    setState(() => _busy = true);
    try {
      await _api().recordConsent(purpose: 'processing_case_and_client_data');
      setState(() => _message = 'Consent recorded (version 1.0).');
      await _refresh();
    } catch (_) {
      setState(() => _message = 'Could not record consent.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final data = await _api().exportAll();
      final pretty = _api().prettyJson(data);
      await Clipboard.setData(ClipboardData(text: pretty));
      if (!mounted) return;
      setState(() =>
          _message = 'Export copied to clipboard (${pretty.length} chars).');
      await _refresh();
    } catch (_) {
      setState(() => _message = 'Export failed.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editRetention() async {
    final current = _retention ?? {};
    final casesCtrl =
        TextEditingController(text: '${current['cases_days'] ?? 2555}');
    final clientsCtrl =
        TextEditingController(text: '${current['clients_days'] ?? 2555}');
    final docsCtrl =
        TextEditingController(text: '${current['documents_days'] ?? 2555}');
    final intakesCtrl =
        TextEditingController(text: '${current['intakes_days'] ?? 1095}');
    var autoPurge = current['auto_purge'] == true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Retention policy (days)'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: casesCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Cases')),
                TextField(
                    controller: clientsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Clients')),
                TextField(
                    controller: docsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Documents')),
                TextField(
                    controller: intakesCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Intakes')),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable auto-purge'),
                  value: autoPurge,
                  onChanged: (v) => setLocal(() => autoPurge = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Save')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await _api().updateRetention({
        'cases_days': int.tryParse(casesCtrl.text) ?? 2555,
        'clients_days': int.tryParse(clientsCtrl.text) ?? 2555,
        'documents_days': int.tryParse(docsCtrl.text) ?? 2555,
        'intakes_days': int.tryParse(intakesCtrl.text) ?? 1095,
        'auto_purge': autoPurge,
      });
      setState(() => _message = 'Retention policy saved.');
      await _refresh();
    } catch (_) {
      setState(() => _message = 'Could not save retention.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _purge() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Run retention purge?'),
        content: const Text('Only deletes when auto_purge is enabled.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Purge')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      final r = await _api().runPurge();
      setState(() => _message = 'Purge result: $r');
      await _refresh();
    } catch (_) {
      setState(() => _message = 'Purge failed.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _erase() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Erase all account data?'),
        content: const Text(
            'Irreversible server wipe of practice data. Password invalidated.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Erase'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await _api().eraseAccount();
      await ref.read(authProvider.notifier).signOut();
      if (!mounted) return;
      context.go('/login');
    } catch (_) {
      setState(() => _message = 'Erase failed.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _breach() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log breach incident'),
        content: TextField(controller: ctrl, maxLines: 3),
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
      await _api().breachReport(ctrl.text.trim());
      setState(() => _message = 'Breach logged.');
      await _refresh();
    } catch (_) {
      setState(() => _message = 'Could not log breach.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        title: const Text('Privacy & compliance'),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _busy ? null : _refresh),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'DPDP-oriented technical controls (not a legal certificate). API: ${AppConstants.apiBaseUrl}',
            style:
                const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          if (_message != null) ...[
            const SizedBox(height: 12),
            Text(_message!),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _export,
            style: FilledButton.styleFrom(backgroundColor: AppColors.deepNavy),
            child: const Text('Export my data (copy JSON)'),
          ),
          OutlinedButton(
              onPressed: _busy ? null : _recordConsent,
              child: const Text('Record consent v1.0')),
          OutlinedButton(
              onPressed: _busy ? null : _breach,
              child: const Text('Log potential breach')),
          OutlinedButton(
              onPressed: _busy ? null : _editRetention,
              child: const Text('Edit retention policy')),
          OutlinedButton(
              onPressed: _busy ? null : _purge,
              child: const Text('Run retention purge')),
          TextButton(
            onPressed: _busy ? null : _erase,
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Erase all account data'),
          ),
          if (_retention != null) ...[
            const Divider(height: 32),
            Text(
              'Retention: cases ${_retention!['cases_days']}d, clients ${_retention!['clients_days']}d, auto_purge=${_retention!['auto_purge']}',
            ),
          ],
          const Divider(height: 32),
          Text('Consent history (${_consents.length})',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          ..._consents.reversed.take(15).map((c) {
            final m = Map<String, dynamic>.from(c as Map);
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text('${m['purpose']} · v${m['version']}'),
              subtitle: Text('${m['at']} · granted=${m['granted']}'),
            );
          }),
          const Divider(height: 32),
          Text('Audit trail (${_audit.length})',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          ..._audit.map((e) {
            final m = Map<String, dynamic>.from(e as Map);
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text('${m['action']}'),
              subtitle:
                  Text('${m['at']} ${m['severity'] ?? ''} ${m['ip'] ?? ''}'),
            );
          }),
          if (_busy)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator())),
        ],
      ),
    );
  }
}
