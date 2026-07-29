import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/ai_models.dart';
import '../providers/ai_provider.dart';

class AiToolsPage extends ConsumerStatefulWidget {
  const AiToolsPage({super.key});

  @override
  ConsumerState<AiToolsPage> createState() => _AiToolsPageState();
}

class _AiToolsPageState extends ConsumerState<AiToolsPage> {
  AiToolType _tool = AiToolType.caseBrief;
  final _titleCtrl = TextEditingController();
  final _courtCtrl = TextEditingController();
  final _stageCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _courtCtrl.dispose();
    _stageCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _run() {
    ref.read(aiAssistProvider.notifier).generate(
          tool: _tool,
          matterTitle: _titleCtrl.text,
          courtName: _courtCtrl.text,
          stage: _stageCtrl.text,
          freeText: _notesCtrl.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiAssistProvider);

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(title: const Text('AI Assist')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.deepNavy.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Privacy: templates run on this device. Nothing is sent to '
              'external AI services. Do not paste privileged client material '
              'unless you intend it to appear in the draft.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AiToolType.values.map((t) {
              final selected = _tool == t;
              return ChoiceChip(
                label: Text(t.title),
                selected: selected,
                onSelected: (_) => setState(() => _tool = t),
                selectedColor: AppColors.saffron.withOpacity(0.25),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text(_tool.description,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          TextField(
            controller: _titleCtrl,
            decoration:
                const InputDecoration(labelText: 'Matter / case title'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _courtCtrl,
            decoration: const InputDecoration(labelText: 'Court'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _stageCtrl,
            decoration: const InputDecoration(labelText: 'Stage'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Optional notes (you choose what to include)',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _run,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Generate on-device'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.deepNavy,
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          if (state.lastResult != null) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Text(state.lastResult!.tool.title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () async {
                    await Clipboard.setData(
                        ClipboardData(text: state.lastResult!.content));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard')),
                    );
                  },
                ),
              ],
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: SelectableText(
                state.lastResult!.content,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
