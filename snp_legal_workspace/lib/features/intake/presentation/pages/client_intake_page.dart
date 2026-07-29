import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../clients/domain/client_models.dart';
import '../../../clients/presentation/providers/clients_provider.dart';

class ClientIntakePage extends ConsumerStatefulWidget {
  const ClientIntakePage({super.key});

  @override
  ConsumerState<ClientIntakePage> createState() => _ClientIntakePageState();
}

class _ClientIntakePageState extends ConsumerState<ClientIntakePage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _matter = TextEditingController();
  final _facts = TextEditingController();
  final _opposing = TextEditingController();
  bool _consentDpdP = false;
  bool _isMinorInvolved = false;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _matter.dispose();
    _facts.dispose();
    _opposing.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_consentDpdP) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('DPDP processing consent is required.')),
      );
      return;
    }
    if (_isMinorInvolved) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Minors data'),
          content: const Text(
            'Confirm guardian consent will be obtained before processing.',
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Confirm')),
          ],
        ),
      );
      if (ok != true) return;
    }
    setState(() => _saving = true);
    try {
      final notes = StringBuffer()
        ..writeln('INTAKE ${const Uuid().v4().substring(0, 8)}')
        ..writeln('Matter: ${_matter.text.trim()}')
        ..writeln('Facts: ${_facts.text.trim()}')
        ..writeln('Opposing party: ${_opposing.text.trim()}')
        ..writeln('Minor involved: $_isMinorInvolved')
        ..writeln('DPDP consent: yes @ ${DateTime.now().toIso8601String()}');
      await ref.read(clientsListProvider.notifier).create(
            ClientDraft(
              name: _name.text.trim(),
              phone: _phone.text.trim(),
              email: _email.text.trim(),
              notes: notes.toString(),
            ),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Intake saved as client profile')),
      );
      context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(title: const Text('Client intake')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Client name *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextFormField(
              controller: _matter,
              decoration:
                  const InputDecoration(labelText: 'Matter type / court'),
            ),
            TextFormField(
              controller: _facts,
              maxLines: 4,
              decoration: const InputDecoration(
                  labelText: 'Brief facts', alignLabelWithHint: true),
            ),
            TextFormField(
              controller: _opposing,
              decoration: const InputDecoration(
                  labelText: 'Opposing party (conflict check)'),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _isMinorInvolved,
              onChanged: (v) =>
                  setState(() => _isMinorInvolved = v ?? false),
              title: const Text('Matter involves a minor'),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _consentDpdP,
              onChanged: (v) => setState(() => _consentDpdP = v ?? false),
              title: const Text('DPDP processing consent'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.deepNavy,
                minimumSize: const Size.fromHeight(48),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Save intake'),
            ),
          ],
        ),
      ),
    );
  }
}
