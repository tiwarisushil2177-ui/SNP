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

  Future<void> _openCloudSettings() async {
    final keyCtrl = TextEditingController();
    final urlCtrl =
        TextEditingController(text: 'https://api.openai.com/v1');
    var enabled = ref.read(aiAssistProvider).cloudConfigured;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Cloud LLM settings'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'API key stays in secure storage. Prefer a backend proxy. '
                  'Do not send privileged data without consent.',
                  style: TextStyle(fontSize: 12),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable cloud LLM'),
                  value: enabled,
                  onChanged: (v) => setLocal(() => enabled = v),
                ),
                TextField(
                  controller: keyCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'API key'),
                ),
                TextField(
                  controller: urlCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Base URL (OpenAI-compatible)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                await ref.read(aiAssistProvider.notifier).saveCloudSettings(
                      enabled: enabled,
                      apiKey: keyCtrl.text.trim().isEmpty
                          ? null
                          : keyCtrl.text.trim(),
                      baseUrl: urlCtrl.text.trim(),
                    );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
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
      appBar: AppBar(
        title: const Text('AI Assist'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openCloudSettings,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          SegmentedButton<AiMode>(
            segments: const [
              ButtonSegment(value: AiMode.onDevice, label: Text('On-device')),
              ButtonSegment(value: AiMode.cloud, label: Text('Cloud')),
            ],
            selected: {state.mode},
            onSelectionChanged: (s) =>
                ref.read(aiAssistProvider.notifier).setMode(s.first),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AiToolType.values.map((t) {
              return ChoiceChip(
                label: Text(t.title),
                selected: _tool == t,
                onSelected: (_) => setState(() => _tool = t),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
              controller: _titleCtrl,
              decoration:
                  const InputDecoration(labelText: 'Matter / case title')),
          TextField(
              controller: _courtCtrl,
              decoration: const InputDecoration(labelText: 'Court')),
          TextField(
              controller: _stageCtrl,
              decoration: const InputDecoration(labelText: 'Stage')),
          TextField(
            controller: _notesCtrl,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Notes'),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: state.isGenerating ? null : _run,
            icon: const Icon(Icons.auto_awesome),
            label: Text(state.mode == AiMode.cloud
                ? 'Generate (cloud)'
                : 'Generate on-device'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.deepNavy,
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(state.error!,
                  style: const TextStyle(color: Colors.red)),
            ),
          if (state.lastResult != null) ...[
            const SizedBox(height: 16),
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
                  },
                ),
              ],
            ),
            SelectableText(state.lastResult!.content),
          ],
        ],
      ),
    );
  }
}
