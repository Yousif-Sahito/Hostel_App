import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes/app_routes.dart';
import '../../features/auth/providers/auth_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final role = authProvider.currentUser?.role.toUpperCase() ?? '';
    final isAdmin = role == 'ADMIN';
    final userName = authProvider.currentUser?.fullName ?? 'User';

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(userName),
            accountEmail: Text(role),
            currentAccountPicture: const CircleAvatar(
              child: Icon(Icons.person, size: 30),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                _drawerItem(
                  context,
                  icon: Icons.dashboard_outlined,
                  title: 'Dashboard',
                  onTap: () {
                    Navigator.pop(context);
                    context.go(
                      isAdmin
                          ? AppRoutes.adminDashboard
                          : AppRoutes.memberDashboard,
                    );
                  },
                ),

                if (isAdmin) ...[
                  _drawerItem(
                    context,
                    icon: Icons.people_alt_outlined,
                    title: 'Members',
                    onTap: () {
                      Navigator.pop(context);
                      context.go(AppRoutes.members);
                    },
                  ),
                  _drawerItem(
                    context,
                    icon: Icons.meeting_room_outlined,
                    title: 'Rooms',
                    onTap: () {
                      Navigator.pop(context);
                      context.go(AppRoutes.rooms);
                    },
                  ),
                  _drawerItem(
                    context,
                    icon: Icons.restaurant_menu_outlined,
                    title: 'Weekly Menu',
                    onTap: () {
                      Navigator.pop(context);
                      context.go(AppRoutes.weeklyMenu);
                    },
                  ),
                  _drawerItem(
                    context,
                    icon: Icons.breakfast_dining_outlined,
                    title: 'Units',
                    onTap: () {
                      Navigator.pop(context);
                      context.go(AppRoutes.meals);
                    },
                  ),
                  _drawerItem(
                    context,
                    icon: Icons.receipt_long_outlined,
                    title: 'Bills',
                    onTap: () {
                      Navigator.pop(context);
                      context.go(AppRoutes.bills);
                    },
                  ),
                  _drawerItem(
                    context,
                    icon: Icons.payments_outlined,
                    title: 'Payment History',
                    onTap: () {
                      Navigator.pop(context);
                      context.go(AppRoutes.paymentHistory);
                    },
                  ),
                  _drawerItem(
                    context,
                    icon: Icons.event_busy_outlined,
                    title: 'Mess Off',
                    onTap: () {
                      Navigator.pop(context);
                      context.go(AppRoutes.messOff);
                    },
                  ),
                  _drawerItem(
                    context,
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      context.go(AppRoutes.settings);
                    },
                  ),
                ] else ...[
                  _drawerItem(
                    context,
                    icon: Icons.restaurant_menu_outlined,
                    title: 'Weekly Menu',
                    onTap: () {
                      Navigator.pop(context);
                      context.go(AppRoutes.weeklyMenu);
                    },
                  ),
                  _drawerItem(
                    context,
                    icon: Icons.breakfast_dining_outlined,
                    title: 'My Units',
                    onTap: () {
                      Navigator.pop(context);
                      context.go(AppRoutes.memberMeals);
                    },
                  ),
                  _drawerItem(
                    context,
                    icon: Icons.receipt_long_outlined,
                    title: 'My Bill',
                    onTap: () {
                      Navigator.pop(context);
                      context.go(AppRoutes.memberBills);
                    },
                  ),
                  _drawerItem(
                    context,
                    icon: Icons.price_change_outlined,
                    title: 'Meal Prices',
                    onTap: () {
                      Navigator.pop(context);
                      context.go(AppRoutes.mealPrices);
                    },
                  ),
                  _drawerItem(
                    context,
                    icon: Icons.payments_outlined,
                    title: 'Payment History',
                    onTap: () {
                      Navigator.pop(context);
                      context.go(AppRoutes.paymentHistory);
                    },
                  ),
                  _drawerItem(
                    context,
                    icon: Icons.event_busy_outlined,
                    title: 'My Mess Off',
                    onTap: () {
                      Navigator.pop(context);
                      context.go(AppRoutes.memberMessOff);
                    },
                  ),
                ],

                _drawerItem(
                  context,
                  icon: Icons.person_outline,
                  title: 'Profile',
                  onTap: () {
                    Navigator.pop(context);
                    context.go(AppRoutes.profile);
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout'),
            onTap: () async {
              await authProvider.logout();
              if (context.mounted) {
                context.go(AppRoutes.login);
              }
            },
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(leading: Icon(icon), title: Text(title), onTap: onTap);
  }
}
