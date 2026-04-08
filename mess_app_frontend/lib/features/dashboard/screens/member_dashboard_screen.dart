import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_drawer.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/dashboard_card.dart';

class MemberDashboardScreen extends StatefulWidget {
  const MemberDashboardScreen({super.key});

  @override
  State<MemberDashboardScreen> createState() => _MemberDashboardScreenState();
}

class _MemberDashboardScreenState extends State<MemberDashboardScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<DashboardProvider>().fetchMemberDashboard();
      }
    });
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    await context.read<DashboardProvider>().fetchMemberDashboard();
  }

  Future<void> _toggleMess() async {
    final now = DateTime.now();
    if (now.hour >= 13) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mess off toggle is only allowed before 1 PM.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final provider = context.read<DashboardProvider>();
      await provider.toggleMessStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mess status updated successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    final data = provider.memberDashboard;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Dashboard'),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: provider.isLoadingMember && data == null
            ? const Center(child: CircularProgressIndicator())
            : provider.memberErrorMessage != null && data == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    provider.memberErrorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              )
            : data == null
            ? const Center(child: Text('No dashboard data found'))
            : RefreshIndicator(
                onRefresh: _refresh,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    int crossAxisCount = 1;

                    if (constraints.maxWidth >= 1200) {
                      crossAxisCount = 3;
                    } else if (constraints.maxWidth >= 700) {
                      crossAxisCount = 2;
                    }

                    return GridView.count(
                      padding: const EdgeInsets.all(16),
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: constraints.maxWidth < 700 ? 2.1 : 2.35,
                      children: [
                        DashboardCard(
                          title: 'Today Menu',
                          value: data.todayMenu,
                          icon: Icons.restaurant_menu,
                        ),
                        DashboardCard(
                          title: 'Mess (Tomorrow)',
                          value: data.tomorrowMessStatus == 'OFF' ? 'OFF' : 'ON',
                          icon: data.tomorrowMessStatus == 'OFF'
                              ? Icons.toggle_off
                              : Icons.toggle_on,
                          iconColor: data.tomorrowMessStatus == 'OFF'
                              ? Colors.red
                              : Colors.green,
                          iconBackgroundColor: data.tomorrowMessStatus == 'OFF'
                              ? Colors.red.withValues(alpha: 0.12)
                              : Colors.green.withValues(alpha: 0.12),
                          onTap: provider.isTogglingMess ? null : _toggleMess,
                        ),
                        DashboardCard(
                          title: 'Monthly Units',
                          value: data.monthlyUnits.toString(),
                          icon: Icons.breakfast_dining,
                        ),
                        DashboardCard(
                          title: 'Current Bill',
                          value: 'Rs. ${data.currentBill.toStringAsFixed(0)}',
                          icon: Icons.receipt_long,
                        ),
                        DashboardCard(
                          title: 'Due Amount',
                          value: 'Rs. ${data.dueAmount.toStringAsFixed(0)}',
                          icon: Icons.warning_amber,
                          iconColor: data.dueAmount > 0
                              ? Colors.orange
                              : Colors.green,
                          iconBackgroundColor: data.dueAmount > 0
                              ? Colors.orange.withValues(alpha: 0.12)
                              : Colors.green.withValues(alpha: 0.12),
                        ),
                        DashboardCard(
                          title: 'Current Status',
                          value: data.messStatus,
                          icon: data.messStatus == 'OFF' ? Icons.block : Icons.check_circle,
                          iconColor: data.messStatus == 'OFF' ? Colors.red : Colors.green,
                        ),
                      ],
                    );
                  },
                ),
              ),
      ),
    );
  }
}
