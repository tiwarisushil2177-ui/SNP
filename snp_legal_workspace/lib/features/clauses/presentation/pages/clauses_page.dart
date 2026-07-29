import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/clause_library.dart';

class ClausesPage extends StatefulWidget {
  const ClausesPage({super.key});

  @override
  State<ClausesPage> createState() => _ClausesPageState();
}

class _ClausesPageState extends State<ClausesPage> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final items = clauseLibrary.where((c) {
      if (_q.isEmpty) return true;
      final hay = '${c.title} ${c.text} ${c.tags.join(' ')}'.toLowerCase();
      return hay.contains(_q.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(title: const Text('Clause library')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search clauses…',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _q = v),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final c = items[i];
                return Material(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  child: ListTile(
                    title: Text(c.title,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(c.text,
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: c.text));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Copied')),
                          );
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
