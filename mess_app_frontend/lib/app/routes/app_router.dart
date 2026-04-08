import 'package:go_router/go_router.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/dashboard/screens/admin_dashboard_screen.dart';
import '../../features/dashboard/screens/member_dashboard_screen.dart';
import '../../features/members/screens/members_list_screen.dart';
import '../../features/rooms/screens/rooms_list_screen.dart';
import '../../features/menu/screens/weekly_menu_screen.dart';
import '../../features/meals/screens/daily_meal_attendance_screen.dart';
import '../../features/meals/screens/member_meals_screen.dart';
import '../../features/billing/screens/bills_list_screen.dart';
import '../../features/billing/screens/member_bills_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/settings/screens/meal_prices_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/payments/screens/payment_history_screen.dart';
import '../../features/mess_off/screens/mess_off_list_screen.dart';
import '../../features/mess_off/screens/member_mess_off_screen.dart';

import 'app_routes.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.login,
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminDashboard,
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.memberDashboard,
        builder: (context, state) => const MemberDashboardScreen(),
      ),
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
        path: AppRoutes.meals,
        builder: (context, state) => const DailyMealAttendanceScreen(),
      ),
      GoRoute(
        path: AppRoutes.memberMeals,
        builder: (context, state) => const MemberMealsScreen(),
      ),
      GoRoute(
        path: AppRoutes.bills,
        builder: (context, state) => const BillsListScreen(),
      ),
      GoRoute(
        path: AppRoutes.memberBills,
        builder: (context, state) => const MemberBillsScreen(),
      ),
      GoRoute(
        path: AppRoutes.paymentHistory,
        builder: (context, state) => const PaymentHistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.mealPrices,
        builder: (context, state) => const MealPricesScreen(),
      ),
      GoRoute(
        path: AppRoutes.messOff,
        builder: (context, state) => const MessOffListScreen(),
      ),
      GoRoute(
        path: AppRoutes.memberMessOff,
        builder: (context, state) => const MemberMessOffScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}
