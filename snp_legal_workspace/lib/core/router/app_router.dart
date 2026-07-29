import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/create_workspace_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/cases/presentation/pages/cases_page.dart';
import '../../features/cases/presentation/pages/create_case_page.dart';
import '../../features/cases/presentation/pages/case_detail_page.dart';
import '../../features/calendar/presentation/pages/calendar_page.dart';
import '../../features/documents/presentation/pages/documents_page.dart';
import '../../features/clients/presentation/pages/clients_page.dart';
import '../../features/clients/presentation/pages/create_client_page.dart';
import '../../features/clients/presentation/pages/client_detail_page.dart';
import '../../features/billing/presentation/pages/billing_page.dart';
import '../../features/billing/presentation/pages/create_invoice_page.dart';
import '../../features/billing/presentation/pages/invoice_detail_page.dart';
import '../../features/billing/presentation/pages/time_entries_page.dart';
import '../../features/ai/presentation/pages/ai_tools_page.dart';
import '../../features/court_sync/presentation/pages/cnr_lookup_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/templates/presentation/pages/templates_page.dart';
import '../../features/intake/presentation/pages/client_intake_page.dart';
import '../../features/clauses/presentation/pages/clauses_page.dart';
import '../../features/deadlines/presentation/deadlines_page.dart';
import '../../features/compliance/presentation/pages/compliance_page.dart';
import '../../shared/widgets/main_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: _AuthChangeNotifier(ref),
    redirect: (context, state) {
      final isAuth = authState.isAuthenticated;
      final isLoading = authState.isLoading;
      final loc = state.matchedLocation;
      if (isLoading) return null;
      final isLoginRoute = loc == '/login' || loc == '/create-workspace';
      if (!isAuth && !isLoginRoute) return '/login';
      if (isAuth && isLoginRoute) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(
          path: '/create-workspace',
          builder: (_, __) => const CreateWorkspacePage()),
      GoRoute(
        path: '/cnr-lookup',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const CnrLookupPage(),
      ),
      GoRoute(
        path: '/cases/new',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const CreateCasePage(),
      ),
      GoRoute(
        path: '/cases/:caseId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (c, s) => CaseDetailPage(caseId: s.pathParameters['caseId']!),
      ),
      GoRoute(
        path: '/clients/new',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const CreateClientPage(),
      ),
      GoRoute(
        path: '/clients/:clientId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (c, s) =>
            ClientDetailPage(clientId: s.pathParameters['clientId']!),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const SettingsPage(),
      ),
      GoRoute(
        path: '/templates',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const TemplatesPage(),
      ),
      GoRoute(
        path: '/intake/new',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const ClientIntakePage(),
      ),
      GoRoute(
        path: '/clauses',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const ClausesPage(),
      ),
      GoRoute(
        path: '/deadlines',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const DeadlinesPage(),
      ),
      GoRoute(
        path: '/compliance',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const CompliancePage(),
      ),
      GoRoute(
        path: '/billing/time',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const TimeEntriesPage(),
      ),
      GoRoute(
        path: '/ai',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const AiToolsPage(),
      ),
      GoRoute(
        path: '/billing/new',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const CreateInvoicePage(),
      ),
      GoRoute(
        path: '/billing/:invoiceId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (c, s) =>
            InvoiceDetailPage(invoiceId: s.pathParameters['invoiceId']!),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (c, s, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: DashboardPage()),
          ),
          GoRoute(
            path: '/cases',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: CasesPage()),
          ),
          GoRoute(
            path: '/calendar',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: CalendarPage()),
          ),
          GoRoute(
            path: '/documents',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: DocumentsPage()),
          ),
          GoRoute(
            path: '/clients',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: ClientsPage()),
          ),
          GoRoute(
            path: '/billing',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: BillingPage()),
          ),
        ],
      ),
    ],
  );
});

class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(this._ref) {
    _ref.listen(authProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
}
