import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/legal_templates.dart';

class TemplatesPage extends StatelessWidget {
  const TemplatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(title: const Text('Document templates')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: legalTemplates.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final t = legalTemplates[i];
          return Material(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            child: ListTile(
              title: Text(t.title,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(t.category),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _TemplateDetail(template: t),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _TemplateDetail extends StatelessWidget {
  const _TemplateDetail({required this.template});
  final LegalTemplate template;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        title: Text(template.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: template.body));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Template copied')),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(template.body,
            style: const TextStyle(fontSize: 14, height: 1.45)),
      ),
    );
  }
}
