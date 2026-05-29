import 'package:civic_scope/features/roles/company/presentation/add_worker/add_worker_screen.dart';
import 'package:civic_scope/features/roles/company/presentation/company_dashboard/company_dashboard_screen.dart';
import 'package:civic_scope/shared/providers/auth_provider.dart';
import 'package:civic_scope/shared/providers/user_provider.dart';
import 'package:civic_scope/shared/providers/debug_mode_provider.dart';
import 'package:civic_scope/core/utils/constants/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'app_routes.dart';

// Authentication screen imports
import '../../features/authentication/presentation/welcome_screen.dart';
import '../../features/authentication/presentation/auth_loading_screen.dart';
import '../../features/authentication/presentation/log_in_screen.dart';
import '../../features/authentication/presentation/sign_up_screen.dart';
import '../../features/authentication/presentation/forgot_password_screen.dart';
import '../../features/authentication/presentation/reset_password_screen.dart';

// Debug screen imports
import '../../features/debug/presentation/role_selector_screen.dart';

// Other screen imports
import '../../features/home_map/presentation/home_map_screen.dart';
import '../../features/home_map/presentation/work_in_progress_screen.dart';
import '../../features/reports/presentation/search_reports_screen.dart';
import '../../features/reports/presentation/make_report_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/roles/worker/presentation/assigned_jobs.dart';
import '../../features/roles/council/presentation/council_panel/council_panel_screen.dart';
import '../../features/roles/council/presentation/register_company/register_company_screen.dart';
import '../../features/roles/admin/presentation/admin_panel/admin_panel_screen.dart';
import '../../features/roles/admin/presentation/deletion_requests_list/deletion_requests_list_screen.dart';

// Scaffold imports
import '../../features/roles/guest/presentation/guest_scaffold.dart';
import '../../features/roles/citizen/presentation/citizen_scaffold.dart';
import '../../features/roles/worker/presentation/worker_scaffold.dart';
import '../../features/roles/company/presentation/company_scaffold.dart';
import '../../features/roles/council/council_scaffold.dart';
import '../../features/roles/admin/presentation/admin_scaffold.dart';

/// Provider for the unified app router
///
/// Watches currentUserRoleProvider (from Firestore) and rebuilds the router when role changes
/// Includes redirect logic for authentication-based routing
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final currentUserRole = ref.watch(currentUserRoleProvider);
  final debugMode = ref.watch(debugModeProvider);

  return GoRouter(
    initialLocation: AppRoutes.authLoading,
    redirect: (context, state) {
      final location = state.uri.toString();

      // 1. LOADING STATE: Show loading screen while checking auth
      if (authState == AppAuthState.loading) {
        return location == AppRoutes.authLoading ? null : AppRoutes.authLoading;
      }

      // 2. AUTHENTICATED: Redirect from welcome/loading to home
      if (authState == AppAuthState.authenticated &&
          (location.startsWith('/auth') ||
              location == AppRoutes.debugRoleSelector)) {
        return AppRoutes.homeMap;
      }

      // 3. DEBUG MODE: Unauthenticated users with debug mode go to role selector
      if (debugMode) {
        if (authState == AppAuthState.unauthenticated) {
          return AppRoutes.debugRoleSelector;
        }
        if (location == AppRoutes.debugRoleSelector) {
          return null;
        }
      }

      // 4. ROLE-BASED GUARDS: Check if user has access to route
      if (!_hasAccessToRoute(location, currentUserRole)) {
        return AppRoutes.homeMap; // Redirect unauthorized access to home
      }

      // 5. UNAUTHENTICATED: Redirect to welcome screen
      if (authState == AppAuthState.unauthenticated &&
          location.startsWith('/auth/loading')) {
        return AppRoutes.authWelcome; // Redirect to welcome
      }

      return null; // Allow navigation
    },
    routes: [
      // ========================================================================
      // STANDALONE ROUTES (outside navigation bar)
      // ========================================================================

      // Welcome screen (unauthenticated users)
      GoRoute(
        path: AppRoutes.authWelcome,
        builder: (context, state) => const WelcomeScreen(),
      ),

      // Auth loading screen (checking authentication state)
      GoRoute(
        path: AppRoutes.authLoading,
        builder: (context, state) => const AuthLoadingScreen(),
      ),

      // Login screen
      GoRoute(
        path: AppRoutes.authLogIn,
        builder: (context, state) => const LoginPage(),
      ),

      // Sign up screen
      GoRoute(
        path: AppRoutes.authSignUp,
        builder: (context, state) => const SignUpScreen(),
      ),

      // Forgot password screen
      GoRoute(
        path: AppRoutes.authForgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Reset password screen (accessed via email link)
      GoRoute(
        path: AppRoutes.authResetPassword,
        builder: (context, state) {
          final code = state.uri.queryParameters['code'] ?? '';
          return ResetPasswordScreen(code: code);
        },
      ),

      // Debug role selector (only accessible when debug mode is enabled)
      GoRoute(
        path: AppRoutes.debugRoleSelector,
        builder: (context, state) => const RoleSelectorScreen(),
      ),
      // Profile page, nested in settings
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const WIPScreen('Profile'),
      ),
      // Notifications page, nested in home
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const WIPScreen('Notifications'),
      ),
      // ========================================================================
      // STATEFUL SHELL ROUTE (navigation bar)
      // ========================================================================
      StatefulShellRoute.indexedStack(
        branches: _buildBranchesForRole(currentUserRole),
        builder: (context, state, navigationShell) =>
            _buildScaffoldForRole(currentUserRole, navigationShell),
      ),

      // Bookmarks page, nested in settings
      GoRoute(
        path: AppRoutes.bookmarks,
        builder: (context, state) => const WIPScreen('Bookmarks'),
      ),
    ],
  );
});

/// Builds navigation branches based on user role
///
/// Branch indices must match the order of BottomNavigationBarItem in scaffolds
List<StatefulShellBranch> _buildBranchesForRole(UserRole role) {
  final branches = <StatefulShellBranch>[];

  // Index 0: Home/Map (ALL roles, different screens)
  branches.add(
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: AppRoutes.homeMap,
          builder: (context, state) => HomeMapScreen(),
        ),
      ],
    ),
  );

  // Index 1: Search (ALL roles)
  branches.add(
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: AppRoutes.searchReports,
          builder: (context, state) => const SearchReportsScreen(),
        ),
      ],
    ),
  );

  // Index 2: Role-specific main feature
  switch (role) {
    case UserRole.guest:
      // Guest: Settings tab at index 2 (3-tab layout)
      branches.add(
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.settings,
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      );
      return branches; // Early return - guest has only 3 tabs

    case UserRole.citizen:
      // Citizen: Make Report
      branches.add(
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.makeReport,
              builder: (context, state) => const MakeReportScreen(),
            ),
          ],
        ),
      );
      break;

    case UserRole.worker:
      // Worker: Assigned Jobs
      branches.add(
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.workerAssignedJobs,
              builder: (context, state) => const AssignedJobsScreen(),
            ),
          ],
        ),
      );
      break;

    case UserRole.company:
      // Company: Dashboard with sub-routes
      branches.add(
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.companyDashboard,
              builder: (context, state) =>  CompanyDashboardScreen(),
              routes: [
                GoRoute(
                  path: 'add_worker',
                  builder: (context, state) => const AddWorkerScreen(),
                ),
              ],
            ),
          ],
        ),
      );
      break;

    case UserRole.council:
      // Council: Panel with sub-routes
      branches.add(
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.councilPanel,
              builder: (context, state) => const CouncilPanelScreen(),
              routes: [
                GoRoute(
                  path: 'register_company',
                  builder: (context, state) => const RegisterCompanyScreen(),
                ),
              ],
            ),
          ],
        ),
      );
      break;

    case UserRole.admin:
      // Admin: Dashboard with multiple sub-routes
      branches.add(
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.adminDashboard,
              builder: (context, state) => const AdminPanelScreen(),
              routes: [
                GoRoute(
                  path: 'register_company_reps',
                  builder: (context, state) => const RegisterCompanyScreen(),
                ),
                GoRoute(
                  path: 'deletion_requests',
                  builder: (context, state) =>
                       DeletionRequestsListScreen(),
                ),
              ],
            ),
          ],
        ),
      );
      break;
  }

  // Index 3: Bookmarks (citizen) or Add report (other non-guest roles)
  if (role == UserRole.citizen) {
    branches.add(
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.bookmarks,
            builder: (context, state) => const WIPScreen('Bookmarks'),
          ),
        ],
      ),
    );
  } else {
    branches.add(
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.makeReport,
            builder: (context, state) => const MakeReportScreen(),
          ),
        ],
      ),
    );
  }

  // Index 4: Settings (ALL non-guest roles)
  branches.add(
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: AppRoutes.settings,
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
  );

  return branches;
}

/// Builds the appropriate scaffold based on user role
Widget _buildScaffoldForRole(
  UserRole role,
  StatefulNavigationShell navigationShell,
) {
  switch (role) {
    case UserRole.guest:
      return GuestScaffold(navigationShell: navigationShell);

    case UserRole.citizen:
      return CitizenScaffold(navigationShell: navigationShell);

    case UserRole.worker:
      return WorkerScaffold(navigationShell: navigationShell);

    case UserRole.company:
      return CompanyScaffold(navigationShell: navigationShell);

    case UserRole.council:
      return CouncilScaffold(navigationShell: navigationShell);

    case UserRole.admin:
      return AdminScaffold(navigationShell: navigationShell);
  }
}

/// Route guard function to check if a user role has access to a specific route
///
/// Returns true if the user can access the route, false otherwise
bool _hasAccessToRoute(String location, UserRole role) {
  // Common routes accessible to all roles
  final commonRoutes = [
    AppRoutes.notifications,
    AppRoutes.homeMap,
    AppRoutes.searchReports,
    AppRoutes.makeReport,
    AppRoutes.bookmarks,
    AppRoutes.settings,
    AppRoutes.profile,
  ];

  return (role == UserRole.guest
          ? location.startsWith('/auth/')
          : location.startsWith('/${role.name}/')) ||
      commonRoutes.any((route) => location.startsWith(route));
}
