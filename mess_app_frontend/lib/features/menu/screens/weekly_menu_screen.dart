import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_drawer.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/menu_provider.dart';
import '../widgets/menu_day_card.dart';
import 'menu_form_screen.dart';

class WeeklyMenuScreen extends StatelessWidget {
  const WeeklyMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MenuProvider()..fetchCurrentWeekMenu(),
      child: const _WeeklyMenuView(),
    );
  }
}

class _WeeklyMenuView extends StatelessWidget {
  const _WeeklyMenuView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MenuProvider>();
    final authProvider = context.watch<AuthProvider>();
    final isAdmin = authProvider.isAdmin;

    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Menu')),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : provider.errorMessage != null
            ? Center(child: Text(provider.errorMessage!))
            : provider.currentMenu == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'No weekly menu found',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    if (isAdmin)
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MenuFormScreen(),
                            ),
                          );

                          if (result == true && context.mounted) {
                            await context
                                .read<MenuProvider>()
                                .fetchCurrentWeekMenu();
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Create Weekly Menu'),
                      ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: provider.fetchCurrentWeekMenu,
                child: ListView(
                  children: [
                    if (provider.currentMenu?.weekStartDate != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          'Week Start: ${provider.currentMenu!.weekStartDate}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ...provider.currentMenu!.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: MenuDayCard(item: item),
                      ),
                    ),
                  ],
                ),
              ),
      ),
      floatingActionButton: isAdmin && provider.currentMenu != null
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MenuFormScreen(menu: provider.currentMenu!),
                  ),
                );

                if (result == true && context.mounted) {
                  await context.read<MenuProvider>().fetchCurrentWeekMenu();
                }
              },
              icon: const Icon(Icons.edit),
              label: const Text('Edit Menu'),
            )
          : null,
    );
  }
}
