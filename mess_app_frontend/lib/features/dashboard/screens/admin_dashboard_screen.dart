import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/app_drawer.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/dashboard_card.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<DashboardProvider>().fetchAdminDashboard();
      }
    });
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    await context.read<DashboardProvider>().fetchAdminDashboard();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    final data = provider.adminDashboard;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue.shade50, Colors.white],
            ),
          ),
          child: provider.isLoadingAdmin && data == null
              ? const Center(child: CircularProgressIndicator())
              : provider.adminErrorMessage != null && data == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      provider.adminErrorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                )
              : data == null
              ? const Center(child: Text('No dashboard data found'))
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Admin Dashboard',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final cards = [
                              DashboardCard(
                                title: 'Manage Units',
                                value: 'Entry & Track',
                                icon: Icons.restaurant,
                                onTap: () {
                                  context.push(AppRoutes.meals);
                                },
                              ),
                              DashboardCard(
                                title: 'Total Members',
                                value: data.totalMembers.toString(),
                                icon: Icons.people,
                              ),
                              DashboardCard(
                                title: 'Active Members',
                                value: data.activeMembers.toString(),
                                icon: Icons.verified_user,
                              ),
                              DashboardCard(
                                title: 'Pending Bills',
                                value: data.pendingBills.toString(),
                                icon: Icons.pending_actions,
                              ),
                              DashboardCard(
                                title: 'Monthly Collection',
                                value:
                                    'Rs. ${data.monthlyCollection.toStringAsFixed(0)}',
                                icon: Icons.account_balance_wallet,
                              ),
                              DashboardCard(
                                title: 'Mess Status',
                                value: data.messStatus,
                                icon: data.messStatus == 'OFF'
                                    ? Icons.toggle_off
                                    : Icons.toggle_on,
                                iconColor: data.messStatus == 'OFF'
                                    ? Colors.red
                                    : Colors.green,
                                iconBackgroundColor: data.messStatus == 'OFF'
                                    ? Colors.red.withValues(alpha: 0.12)
                                    : Colors.green.withValues(alpha: 0.12),
                              ),
                              DashboardCard(
                                title: 'Today Menu',
                                value: data.todayMenu,
                                icon: Icons.lunch_dining,
                              ),
                              DashboardCard(
                                title: "Tomorrow's Mess Off",
                                value: data.tomorrowMessOffCount.toString(),
                                icon: Icons.person_off,
                                iconColor: data.tomorrowMessOffCount > 0
                                    ? Colors.red
                                    : Colors.grey,
                                iconBackgroundColor:
                                    data.tomorrowMessOffCount > 0
                                    ? Colors.red.withValues(alpha: 0.12)
                                    : Colors.grey.withValues(alpha: 0.12),
                                onTap: () {
                                  context.push(AppRoutes.messOff);
                                },
                              ),
                            ];

                            return GridView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 280,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 1.2,
                                  ),
                              itemCount: cards.length,
                              itemBuilder: (context, index) => cards[index],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
