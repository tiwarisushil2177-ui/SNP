import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/create_workspace_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/cases/presentation/pages/cases_page.dart';
import '../../features/calendar/presentation/pages/calendar_page.dart';
import '../../features/documents/presentation/pages/documents_page.dart';
import '../../features/clients/presentation/pages/clients_page.dart';
import '../../features/billing/presentation/pages/billing_page.dart';
import '../../features/court_sync/presentation/pages/cnr_lookup_page.dart';
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
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/create-workspace',
        builder: (context, state) => const CreateWorkspacePage(),
      ),
      GoRoute(
        path: '/cnr-lookup',
        builder: (context, state) => const CnrLookupPage(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardPage(),
            ),
          ),
          GoRoute(
            path: '/cases',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CasesPage(),
            ),
          ),
          GoRoute(
            path: '/calendar',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CalendarPage(),
            ),
          ),
          GoRoute(
            path: '/documents',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DocumentsPage(),
            ),
          ),
          GoRoute(
            path: '/clients',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ClientsPage(),
            ),
          ),
          GoRoute(
            path: '/billing',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: BillingPage(),
            ),
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
