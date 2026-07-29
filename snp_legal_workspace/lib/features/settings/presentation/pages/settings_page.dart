import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/security/security_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lock = ref.watch(appLockProvider);
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(title: const Text('Settings & security')),
      body: ListView(
        children: [
          if (auth.advocateName != null || auth.email != null)
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(auth.advocateName ?? 'Advocate'),
              subtitle: Text(auth.email ?? auth.userId ?? ''),
            ),
          const Divider(),
          SwitchListTile(
            secondary: const Icon(Icons.fingerprint),
            title: const Text('Biometric / PIN app lock'),
            subtitle: const Text(
              'Require device authentication when opening the app',
            ),
            value: lock.lockEnabled,
            onChanged: (v) async {
              await ref.read(appLockProvider.notifier).setEnabled(v);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        v ? 'App lock enabled' : 'App lock disabled'),
                  ),
                );
              }
            },
          ),
          if (lock.lockEnabled)
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Lock now'),
              onTap: () => ref.read(appLockProvider.notifier).lock(),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.policy_outlined),
            title: const Text('Privacy & DPDP consents'),
            onTap: () => context.push('/compliance'),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Document templates'),
            onTap: () => context.push('/templates'),
          ),
          ListTile(
            leading: const Icon(Icons.assignment_ind_outlined),
            title: const Text('Client intake form'),
            onTap: () => context.push('/intake/new'),
          ),
          ListTile(
            leading: const Icon(Icons.menu_book_outlined),
            title: const Text('Clause library'),
            onTap: () => context.push('/clauses'),
          ),
          ListTile(
            leading: const Icon(Icons.event_available_outlined),
            title: const Text('Court holidays & deadlines'),
            onTap: () => context.push('/deadlines'),
          ),
          ListTile(
            leading: const Icon(Icons.auto_awesome),
            title: const Text('AI Assist'),
            onTap: () => context.push('/ai'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.chat_outlined),
            title: const Text('Share via WhatsApp'),
            subtitle: const Text(
                'Opens WhatsApp with a draft (no Business API key)'),
            onTap: () async {
              final uri = Uri.parse(
                'https://wa.me/?text=${Uri.encodeComponent("Update from SNP Legal Workspace regarding your matter.")}',
              );
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign out',
                style: TextStyle(color: Colors.red)),
            onTap: () async {
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) context.go('/login');
            },
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Bar Council Rule 36: no public lawyer directory, ratings, or client solicitation.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
