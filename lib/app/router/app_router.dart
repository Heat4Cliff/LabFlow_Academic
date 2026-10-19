import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/widgets/labflow_account_status_gate.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/lab_admin/presentation/pages/lab_admin_dashboard_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/student/presentation/pages/student_home_page.dart';
import '../../features/superadmin/presentation/pages/activity_log_page.dart';
import '../../features/superadmin/presentation/pages/create_laboratory_page.dart';
import '../../features/superadmin/presentation/pages/create_user_page.dart';
import '../../features/superadmin/presentation/pages/edit_laboratory_page.dart';
import '../../features/superadmin/presentation/pages/edit_user_page.dart';
import '../../features/superadmin/presentation/pages/lab_membership_page.dart';
import '../../features/superadmin/presentation/pages/laboratory_management_page.dart';
import '../../features/superadmin/presentation/pages/superadmin_dashboard_page.dart';
import '../../features/superadmin/presentation/pages/user_management_page.dart';
import '../../features/superadmin/presentation/pages/superadmin_profile_page.dart';

/// Membuat router utama LabFlow.
///
/// Halaman awal tetap ditentukan oleh status first-launch device.
///
/// Seluruh route Superadmin melewati account status gate
/// dengan role `superadmin`.
GoRouter createAppRouter({required String initialLocation}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),

      /// Dashboard placeholder lama.
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardPage(),
      ),

      /// Area Superadmin.
      GoRoute(
        path: '/superadmin',
        builder: (context, state) {
          return const LabFlowAccountStatusGate(
            requiredRole: 'superadmin',
            child: SuperadminDashboardPage(),
          );
        },
      ),
      GoRoute(
        path: '/superadmin/users',
        builder: (context, state) {
          return const LabFlowAccountStatusGate(
            requiredRole: 'superadmin',
            child: UserManagementPage(),
          );
        },
      ),
      GoRoute(
        path: '/superadmin/users/create',
        builder: (context, state) {
          return const LabFlowAccountStatusGate(
            requiredRole: 'superadmin',
            child: CreateUserPage(),
          );
        },
      ),

      /// Entry Student.
      GoRoute(
        path: '/student',
        builder: (context, state) => const StudentHomePage(),
      ),

      /// Entry Lab Admin.
      GoRoute(
        path: '/lab-admin',
        builder: (context, state) => const LabAdminDashboardPage(),
      ),

      GoRoute(
        path: '/superadmin/labs',
        builder: (context, state) {
          return const LabFlowAccountStatusGate(
            requiredRole: 'superadmin',
            child: LaboratoryManagementPage(),
          );
        },
      ),
      GoRoute(
        path: '/superadmin/labs/create',
        builder: (context, state) {
          return const LabFlowAccountStatusGate(
            requiredRole: 'superadmin',
            child: CreateLaboratoryPage(),
          );
        },
      ),
      GoRoute(
        path: '/superadmin/memberships',
        builder: (context, state) {
          return const LabFlowAccountStatusGate(
            requiredRole: 'superadmin',
            child: LabMembershipPage(),
          );
        },
      ),
      GoRoute(
        path: '/superadmin/labs/:labId/edit',
        builder: (context, state) {
          final labId = state.pathParameters['labId']!;

          return LabFlowAccountStatusGate(
            requiredRole: 'superadmin',
            child: EditLaboratoryPage(laboratoryId: labId),
          );
        },
      ),
      GoRoute(
        path: '/superadmin/users/:userId/edit',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;

          return LabFlowAccountStatusGate(
            requiredRole: 'superadmin',
            child: EditUserPage(userId: userId),
          );
        },
      ),
      GoRoute(
        path: '/superadmin/activity',
        builder: (context, state) {
          return const LabFlowAccountStatusGate(
            requiredRole: 'superadmin',
            child: ActivityLogPage(),
          );
        },
      ),
      GoRoute(
        path: '/superadmin/profile',
        builder: (context, state) {
          return const LabFlowAccountStatusGate(
            requiredRole: 'superadmin',
            child: SuperadminProfilePage(),
          );
        },
      ),
    ],
  );
}
