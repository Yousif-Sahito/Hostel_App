import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_drawer.dart';
import '../providers/mess_off_provider.dart';
import '../services/mess_off_service.dart';
import '../widgets/mess_off_card.dart';
import 'mess_off_form_screen.dart';

class MessOffListScreen extends StatelessWidget {
  const MessOffListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MessOffProvider()..fetchMessOffEntries(),
      child: const _MessOffListView(),
    );
  }
}

class _MessOffListView extends StatelessWidget {
  const _MessOffListView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MessOffProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Mess Off')),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search mess off entries...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onChanged: provider.searchEntries,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.errorMessage != null
                  ? Center(child: Text(provider.errorMessage!))
                  : provider.filteredEntries.isEmpty
                  ? const Center(child: Text('No mess off entries found'))
                  : RefreshIndicator(
                      onRefresh: provider.fetchMessOffEntries,
                      child: ListView.builder(
                        itemCount: provider.filteredEntries.length,
                        itemBuilder: (context, index) {
                          final entry = provider.filteredEntries[index];

                          return MessOffCard(
                            entry: entry,
                            showActions: true,
                            onEdit: () async {
                              final updated = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      MessOffFormScreen(entry: entry),
                                ),
                              );

                              if (updated == true && context.mounted) {
                                await context
                                    .read<MessOffProvider>()
                                    .fetchMessOffEntries();
                              }
                            },
                            onDelete: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Delete Mess Off'),
                                  content: const Text(
                                    'Are you sure you want to delete this mess off entry?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true && context.mounted) {
                                try {
                                  await MessOffService.deleteMessOff(entry.id!);

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Mess off entry deleted successfully',
                                        ),
                                      ),
                                    );
                                  }

                                  if (context.mounted) {
                                    await context
                                        .read<MessOffProvider>()
                                        .fetchMessOffEntries();
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          e.toString().replaceFirst(
                                            'Exception: ',
                                            '',
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MessOffFormScreen()),
          );

          if (created == true && context.mounted) {
            await context.read<MessOffProvider>().fetchMessOffEntries();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Mess Off'),
      ),
    );
  }
}
