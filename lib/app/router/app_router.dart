import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/superadmin/presentation/pages/superadmin_dashboard_page.dart';
import '../../features/superadmin/presentation/pages/user_management_page.dart';
import '../../features/superadmin/presentation/pages/create_user_page.dart';
import '../../features/lab_admin/presentation/pages/lab_admin_dashboard_page.dart';
import '../../features/student/presentation/pages/student_home_page.dart';

/// Membuat router utama LabFlow.
///
/// Halaman awal ditentukan dari status first-launch device.
/// Nantinya router ini akan dikembangkan lagi untuk menangani
/// authentication guard dan role-based access.
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
      ///
      /// Untuk sementara tetap dipertahankan sampai
      /// dashboard Student dan Lab Admin dibuat.
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardPage(),
      ),

      /// Dashboard khusus Superadmin.
      GoRoute(
        path: '/superadmin',
        builder: (context, state) => const SuperadminDashboardPage(),
      ),

      GoRoute(
        path: '/superadmin/users',
        builder: (context, state) => const UserManagementPage(),
      ),

      GoRoute(
        path: '/superadmin/users/create',
        builder: (context, state) => const CreateUserPage(),
      ),

      GoRoute(
        path: '/student',
        builder: (context, state) => const StudentHomePage(),
      ),

      GoRoute(
        path: '/lab-admin',
        builder: (context, state) => const LabAdminDashboardPage(),
      ),
    ],
  );
}
