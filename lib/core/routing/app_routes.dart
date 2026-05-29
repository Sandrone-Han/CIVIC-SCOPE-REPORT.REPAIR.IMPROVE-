/// Central location for all route paths in the application
///
/// Routes are organized by:
/// - Common routes (accessible to all roles)
/// - Auth routes (unauthenticated users)
/// - Role-specific routes (prefixed with /{role}/)
class AppRoutes {
  // ============================================================================
  // COMMON ROUTES (all roles)
  // ============================================================================

  /// Map view - Shows all reports on a map
  static const String homeMap = '/home_map';

  /// Search reports screen
  static const String searchReports = '/search_reports';

  /// Create a new report (in nav bar for citizen & all other roles)
  static const String makeReport = '/make_report';

  /// Bookmarked reports (in nav bar for citizen and settings for other roles)
  static const String bookmarks = '/bookmarks';

  /// Settings screen
  static const String settings = '/settings';

  /// Profile page
  static const String profile = '/profile';

  /// Profile page
  static const String notifications = '/notifications';

  // ============================================================================
  // AUTH ROUTES
  // ============================================================================

  /// Welcome screen (unauthenticated users)
  static const String authWelcome = '/auth/welcome';

  /// Auth loading screen (checking authentication state)
  static const String authLoading = '/auth/loading';

  /// Login screen
  static const String authLogIn = '/auth/log_in';

  /// Sign up screen
  static const String authSignUp = '/auth/sign_up';

  /// Forgot password screen
  static const String authForgotPassword = '/auth/forgot_password';

  /// Reset password screen (accessed via email link)
  static const String authResetPassword = '/auth/reset_password';

  // ============================================================================
  // WORKER ROUTES
  // ============================================================================

  /// Assigned jobs screen (in nav bar for worker)
  static const String workerAssignedJobs = '/worker/assigned_jobs';

  // ============================================================================
  // COMPANY ROUTES
  // ============================================================================

  /// Company dashboard (in nav bar)
  static const String companyDashboard = '/company/dashboard';

  /// Add worker screen (sub-route of dashboard)
  static const String companyAddWorker = '/company/dashboard/add_worker';

  // ============================================================================
  // COUNCIL ROUTES
  // ============================================================================

  /// Council panel (in nav bar)
  static const String councilPanel = '/council/panel';

  /// Register company screen (sub-route of panel)
  static const String councilRegisterCompany =
      '/council/panel/register_company';

  // ============================================================================
  // ADMIN ROUTES
  // ============================================================================

  /// Admin dashboard (in nav bar)
  static const String adminDashboard = '/admin/dashboard';

  /// Register councils screen (sub-route of dashboard)
  static const String adminRegisterCouncils =
      '/admin/dashboard/register_councils';

  /// Register company representatives screen (sub-route of dashboard)
  static const String adminRegisterCompanyReps =
      '/admin/dashboard/register_company_reps';

  /// Deletion requests screen (sub-route of dashboard)
  static const String adminDeletionRequests =
      '/admin/dashboard/deletion_requests';

  // ============================================================================
  // DEBUG/DEBUG ROUTES
  // ============================================================================

  /// Debug role selector screen (only accessible when debug mode is enabled)
  static const String debugRoleSelector = '/debug/role-selector';
}
