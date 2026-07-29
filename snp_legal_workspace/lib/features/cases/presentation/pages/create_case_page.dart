import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../court_sync/domain/court_sync_models.dart';
import '../../../court_sync/presentation/providers/court_sync_provider.dart';
import '../../domain/case_models.dart';
import '../providers/cases_provider.dart';

class CreateCasePage extends ConsumerStatefulWidget {
  const CreateCasePage({super.key});

  @override
  ConsumerState<CreateCasePage> createState() => _CreateCasePageState();
}

class _CreateCasePageState extends ConsumerState<CreateCasePage> {
  final _formKey = GlobalKey<FormState>();
  final _cnrCtrl = TextEditingController();
  final _courtCtrl = TextEditingController();
  final _caseTypeCtrl = TextEditingController();
  final _petitionerCtrl = TextEditingController();
  final _respondentCtrl = TextEditingController();
  final _sectionsCtrl = TextEditingController();
  final _purposeCtrl = TextEditingController();
  final _counselCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  CaseStage _stage = CaseStage.filed;
  DateTime? _filingDate;
  DateTime? _nextHearing;
  bool _saving = false;
  bool _lookingUp = false;
  String? _lookupMessage;
  SyncStatus? _lookupStatus;

  @override
  void dispose() {
    _cnrCtrl.dispose();
    _courtCtrl.dispose();
    _caseTypeCtrl.dispose();
    _petitionerCtrl.dispose();
    _respondentCtrl.dispose();
    _sectionsCtrl.dispose();
    _purposeCtrl.dispose();
    _counselCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _lookupCnr() async {
    final raw = _cnrCtrl.text.trim();
    if (raw.isEmpty) {
      setState(() {
        _lookupMessage = 'Enter a CNR to look up.';
        _lookupStatus = SyncStatus.notFound;
      });
      return;
    }
    if (!CnrNumber.isValidFormat(raw)) {
      setState(() {
        _lookupMessage =
            'Invalid CNR format. Expected 16 alphanumeric characters.';
        _lookupStatus = SyncStatus.notFound;
      });
      return;
    }
    setState(() {
      _lookingUp = true;
      _lookupMessage = null;
      _lookupStatus = SyncStatus.syncing;
    });
    final result = await ref.read(courtSyncServiceProvider).lookupByCnr(raw);
    if (!mounted) return;
    setState(() {
      _lookingUp = false;
      _lookupStatus = result.status;
      _lookupMessage = result.message;
    });
    final status = result.caseStatus;
    if (result.status == SyncStatus.success && status != null) {
      final draft = CaseFromCourtSync.draftFrom(status);
      setState(() {
        _cnrCtrl.text = status.cnr;
        if (draft.court != null) _courtCtrl.text = draft.court!;
        if (draft.caseType != null) _caseTypeCtrl.text = draft.caseType!;
        if (draft.petitioners.isNotEmpty) {
          _petitionerCtrl.text = draft.petitioners.join(', ');
        }
        if (draft.respondents.isNotEmpty) {
          _respondentCtrl.text = draft.respondents.join(', ');
        }
        _stage = draft.stage;
        _nextHearing = draft.nextHearingDate;
        if (draft.nextHearingPurpose != null) {
          _purposeCtrl.text = draft.nextHearingPurpose!;
        }
        _lookupMessage = 'Court data loaded. Review fields before saving.';
      });
    }
  }

  Future<void> _pickDate({required bool filing}) async {
    final initial = filing
        ? (_filingDate ?? DateTime.now())
        : (_nextHearing ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked == null) return;
    setState(() {
      if (filing) {
        _filingDate = picked;
      } else {
        _nextHearing = picked;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final draft = CaseDraft(
      cnr: _cnrCtrl.text.trim().isEmpty ? null : _cnrCtrl.text.trim(),
      court: _courtCtrl.text.trim().isEmpty ? null : _courtCtrl.text.trim(),
      caseType:
          _caseTypeCtrl.text.trim().isEmpty ? null : _caseTypeCtrl.text.trim(),
      petitioners: _petitionerCtrl.text
          .split(RegExp(r'[,;]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      respondents: _respondentCtrl.text
          .split(RegExp(r'[,;]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      sections: _sectionsCtrl.text
          .split(RegExp(r'[,;]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      filingDate: _filingDate,
      stage: _stage,
      nextHearingDate: _nextHearing,
      nextHearingPurpose:
          _purposeCtrl.text.trim().isEmpty ? null : _purposeCtrl.text.trim(),
      opposingCounsel:
          _counselCtrl.text.trim().isEmpty ? null : _counselCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
    try {
      final created =
          await ref.read(casesListProvider.notifier).create(draft);
      if (!mounted) return;
      context.go('/cases/${created.id}');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save case. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy');
    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        title: const Text('New Case'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            const Text('Court identity',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepNavy)),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cnrCtrl,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[A-Za-z0-9\-\s]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'CNR number',
                      hintText: 'e.g. DLCT010012342024',
                      helperText: '16 characters; hyphens optional',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: FilledButton.tonal(
                    onPressed: _lookingUp ? null : _lookupCnr,
                    child: _lookingUp
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Lookup'),
                  ),
                ),
              ],
            ),
            if (_lookupMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_lookupMessage!,
                    style: const TextStyle(fontSize: 13)),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _courtCtrl,
              decoration: const InputDecoration(
                  labelText: 'Court', hintText: 'Court name, district, state'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _caseTypeCtrl,
              decoration: const InputDecoration(
                  labelText: 'Case type', hintText: 'e.g. Civil, Criminal'),
            ),
            const SizedBox(height: 20),
            const Text('Parties',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepNavy)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _petitionerCtrl,
              decoration: const InputDecoration(
                  labelText: 'Petitioner(s)',
                  hintText: 'Comma-separated if multiple'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'At least one petitioner is required'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _respondentCtrl,
              decoration: const InputDecoration(
                  labelText: 'Respondent(s)',
                  hintText: 'Comma-separated if multiple'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'At least one respondent is required'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sectionsCtrl,
              decoration: const InputDecoration(
                  labelText: 'Sections / laws',
                  hintText: 'e.g. BNS 103, BNSS 173'),
            ),
            const SizedBox(height: 20),
            const Text('Stage & hearings',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepNavy)),
            const SizedBox(height: 8),
            DropdownButtonFormField<CaseStage>(
              value: _stage,
              decoration: const InputDecoration(labelText: 'Stage'),
              items: CaseStage.values
                  .map((s) =>
                      DropdownMenuItem(value: s, child: Text(s.label)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _stage = v);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Filing date'),
              subtitle: Text(_filingDate == null
                  ? 'Not set'
                  : dateFmt.format(_filingDate!)),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () => _pickDate(filing: true),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Next hearing date'),
              subtitle: Text(_nextHearing == null
                  ? 'Not set — enter manually if court not supported'
                  : dateFmt.format(_nextHearing!)),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () => _pickDate(filing: false),
              ),
            ),
            TextFormField(
              controller: _purposeCtrl,
              decoration: const InputDecoration(
                  labelText: 'Hearing purpose',
                  hintText: 'e.g. Arguments, Evidence'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _counselCtrl,
              decoration:
                  const InputDecoration(labelText: 'Opposing counsel'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Notes', alignLabelWithHint: true),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _saving ? null : _save,
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
                  : const Text('Save case'),
            ),
          ],
        ),
      ),
    );
  }
}
