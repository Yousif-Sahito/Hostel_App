import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_drawer.dart';
import '../providers/notification_provider.dart';
import '../widgets/notification_tile.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (!mounted) return;
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: provider.notifications.isEmpty
                ? null
                : () => provider.markAllAsRead(),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.errorMessage != null
              ? Center(child: Text(provider.errorMessage!))
              : provider.notifications.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No notifications yet.\nNotifications appear here when the system sends alerts like mess off, payments, or bill reminders.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: provider.fetchNotifications,
                      child: ListView.separated(
                        itemCount: provider.notifications.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = provider.notifications[index];
                          return NotificationTile(
                            item: item,
                            onTap: () => provider.markAsRead(item.id),
                          );
                        },
                      ),
                    ),
    );
  }
}
