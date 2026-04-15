import 'package:go_router/go_router.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/reset_password_screen.dart';
import '../../features/auth/screens/verify_email_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/dashboard/screens/admin_dashboard_screen.dart';
import '../../features/dashboard/screens/member_dashboard_screen.dart';
import '../../features/members/screens/members_list_screen.dart';
import '../../features/rooms/screens/rooms_list_screen.dart';
import '../../features/menu/screens/weekly_menu_screen.dart';
import '../../features/meals/screens/daily_meal_attendance_screen.dart';
import '../../features/meals/screens/member_meals_screen.dart';
import '../../features/meals/screens/meal_units_summary_screen.dart';
import '../../features/billing/screens/bills_list_screen.dart';
import '../../features/billing/screens/member_bills_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/settings/screens/meal_prices_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/payments/screens/payment_history_screen.dart';
import '../../features/mess_off/screens/mess_off_list_screen.dart';
import '../../features/mess_off/screens/member_mess_off_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';

import 'app_routes.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.login,
    errorBuilder: (context, state) => const LoginScreen(),
    redirect: (context, state) {
      // Prevent going back to login from dashboard
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) => ResetPasswordScreen(
          tokenFromLink: state.uri.queryParameters['token'],
        ),
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        builder: (context, state) => VerifyEmailScreen(
          tokenFromLink: state.uri.queryParameters['token'],
        ),
      ),
      GoRoute(
        path: AppRoutes.signUp,
        builder: (context, state) => const SignUpScreen(),
      ),
      // Admin Routes
      GoRoute(
        path: AppRoutes.adminDashboard,
        builder: (context, state) => const AdminDashboardScreen(),
        routes: [
          GoRoute(
            path: 'members',
            builder: (context, state) => const MembersListScreen(),
          ),
          GoRoute(
            path: 'rooms',
            builder: (context, state) => const RoomsListScreen(),
          ),
          GoRoute(
            path: 'weekly-menu',
            builder: (context, state) => const WeeklyMenuScreen(),
          ),
          GoRoute(
            path: 'meals',
            builder: (context, state) => const DailyMealAttendanceScreen(),
          ),
          GoRoute(
            path: 'meal-units-summary',
            builder: (context, state) => const MealUnitsSummaryScreen(),
          ),
          GoRoute(
            path: 'bills',
            builder: (context, state) => const BillsListScreen(),
          ),
          GoRoute(
            path: 'payment-history',
            builder: (context, state) => const PaymentHistoryScreen(),
          ),
          GoRoute(
            path: 'meal-prices',
            builder: (context, state) => const MealPricesScreen(),
          ),
          GoRoute(
            path: 'mess-off',
            builder: (context, state) => const MessOffListScreen(),
          ),
          GoRoute(
            path: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: 'notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
        ],
      ),
      // Member Routes
      GoRoute(
        path: AppRoutes.memberDashboard,
        builder: (context, state) => const MemberDashboardScreen(),
        routes: [
          GoRoute(
            path: 'meals',
            builder: (context, state) => const MemberMealsScreen(),
          ),
          GoRoute(
            path: 'bills',
            builder: (context, state) => const MemberBillsScreen(),
          ),
          GoRoute(
            path: 'payment-history',
            builder: (context, state) => const PaymentHistoryScreen(),
          ),
          GoRoute(
            path: 'mess-off',
            builder: (context, state) => const MemberMessOffScreen(),
          ),
          GoRoute(
            path: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: 'notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
        ],
      ),
      // Fallback routes for direct access
      GoRoute(
        path: AppRoutes.members,
        builder: (context, state) => const MembersListScreen(),
      ),
      GoRoute(
        path: AppRoutes.rooms,
        builder: (context, state) => const RoomsListScreen(),
      ),
      GoRoute(
        path: AppRoutes.weeklyMenu,
        builder: (context, state) => const WeeklyMenuScreen(),
      ),
      GoRoute(
        path: AppRoutes.memberMeals,
        builder: (context, state) => const MemberMealsScreen(),
      ),
      GoRoute(
        path: AppRoutes.memberBills,
        builder: (context, state) => const MemberBillsScreen(),
      ),
      GoRoute(
        path: AppRoutes.mealPrices,
        builder: (context, state) => const MealPricesScreen(),
      ),
      GoRoute(
        path: AppRoutes.memberMessOff,
        builder: (context, state) => const MemberMessOffScreen(),
      ),
      GoRoute(
        path: AppRoutes.meals,
        builder: (context, state) => const DailyMealAttendanceScreen(),
      ),
      GoRoute(
        path: AppRoutes.mealUnitsSummary,
        builder: (context, state) => const MealUnitsSummaryScreen(),
      ),
      GoRoute(
        path: AppRoutes.bills,
        builder: (context, state) => const BillsListScreen(),
      ),
      GoRoute(
        path: AppRoutes.paymentHistory,
        builder: (context, state) => const PaymentHistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.messOff,
        builder: (context, state) => const MessOffListScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
  );
}
