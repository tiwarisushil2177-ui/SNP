import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/document_models.dart';
import '../providers/documents_provider.dart';

class DocumentsPage extends ConsumerStatefulWidget {
  const DocumentsPage({super.key, this.caseId});
  final String? caseId;

  @override
  ConsumerState<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends ConsumerState<DocumentsPage> {
  final _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(documentsListProvider.notifier).refresh(caseId: widget.caseId);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _upload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'txt'],
      withData: false,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (!mounted) return;

    String? category = documentCategories.last;
    var markOfficial = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: const Text('Upload document'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(file.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: documentCategories
                        .map((c) =>
                            DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setLocal(() => category = v),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Mark as official filed copy'),
                    subtitle: const Text(
                        'Only one official filed document per case'),
                    value: markOfficial,
                    onChanged: (v) =>
                        setLocal(() => markOfficial = v ?? false),
                  ),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Upload')),
              ],
            );
          },
        );
      },
    );
    if (confirmed != true || !mounted) return;

    await ref.read(documentsListProvider.notifier).add(
          filename: file.name,
          caseId: widget.caseId,
          contentType: file.extension,
          sizeBytes: file.size,
          category: category,
          markOfficial: markOfficial,
          sourcePath: file.path,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Uploaded ${file.name}')),
    );
  }

  Future<void> _share(CaseDocument doc) async {
    final link = await ref.read(documentsListProvider.notifier).share(doc.id);
    if (!mounted) return;
    final text =
        'SNP share token: ${link.token}\nExpires: ${DateFormat('dd MMM yyyy HH:mm').format(link.expiresAt)}\nDownloads left: ${link.downloadsRemaining}';
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Share link created'),
        content: Text(
          'Expiring token copied to clipboard.\n\n'
          'Valid until ${DateFormat('dd MMM yyyy HH:mm').format(link.expiresAt)}.\n'
          'Max downloads: ${link.maxDownloads}.\n\n'
          'Token: ${link.token}',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(documentsListProvider);
    final dateFmt = DateFormat('dd MMM yyyy');

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: const InputDecoration(
                  hintText: 'Search documents…',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (v) =>
                    ref.read(documentsListProvider.notifier).setQuery(v),
              )
            : Text(widget.caseId != null ? 'Case documents' : 'Documents'),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  ref.read(documentsListProvider.notifier).setQuery('');
                }
              });
            },
          ),
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (c) =>
                ref.read(documentsListProvider.notifier).setCategory(c),
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('All categories')),
              ...documentCategories.map(
                (c) => PopupMenuItem(value: c, child: Text(c)),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _upload,
        backgroundColor: AppColors.deepNavy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload'),
      ),
      body: state.isLoading && state.documents.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.documents.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open,
                            size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 16),
                        Text('No documents',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(
                          'Upload petitions, orders, evidence.\nShare via expiring links.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: _upload,
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Upload'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => ref
                      .read(documentsListProvider.notifier)
                      .refresh(caseId: widget.caseId),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                    itemCount: state.documents.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final d = state.documents[i];
                      return Material(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Icon(_iconFor(d.filename),
                                  color: AppColors.deepNavy, size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      d.filename,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      [
                                        if (d.category != null) d.category!,
                                        d.sizeLabel,
                                        dateFmt.format(d.createdAt),
                                        if (d.isOfficialFiled) 'Official',
                                      ].join(' · '),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (v) async {
                                  if (v == 'share') await _share(d);
                                  if (v == 'official') {
                                    await ref
                                        .read(documentsListProvider.notifier)
                                        .toggleOfficial(d);
                                  }
                                  if (v == 'delete') {
                                    await ref
                                        .read(documentsListProvider.notifier)
                                        .delete(d.id);
                                  }
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(
                                      value: 'share',
                                      child: Text('Create share link')),
                                  PopupMenuItem(
                                    value: 'official',
                                    child: Text(d.isOfficialFiled
                                        ? 'Unmark official'
                                        : 'Mark official filed'),
                                  ),
                                  const PopupMenuItem(
                                      value: 'delete', child: Text('Delete')),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  IconData _iconFor(String name) {
    final n = name.toLowerCase();
    if (n.endsWith('.pdf')) return Icons.picture_as_pdf;
    if (n.endsWith('.jpg') || n.endsWith('.jpeg') || n.endsWith('.png')) {
      return Icons.image;
    }
    return Icons.insert_drive_file;
  }
}
