import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_drawer.dart';
import '../providers/member_provider.dart';
import '../services/member_service.dart';
import '../widgets/member_card.dart';
import 'member_detail_screen.dart';
import 'member_form_screen.dart';

class MembersListScreen extends StatelessWidget {
  const MembersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MemberProvider()..fetchMembers(),
      child: const _MembersListView(),
    );
  }
}

class _MembersListView extends StatelessWidget {
  const _MembersListView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MemberProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Members')),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search members...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onChanged: provider.searchMembers,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.errorMessage != null
                  ? Center(child: Text(provider.errorMessage!))
                  : provider.filteredMembers.isEmpty
                  ? const Center(child: Text('No members found'))
                  : RefreshIndicator(
                      onRefresh: provider.fetchMembers,
                      child: ListView.builder(
                        itemCount: provider.filteredMembers.length,
                        itemBuilder: (context, index) {
                          final member = provider.filteredMembers[index];

                          return MemberCard(
                            member: member,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      MemberDetailScreen(member: member),
                                ),
                              );
                            },
                            onEdit: () async {
                              final updated = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      MemberFormScreen(member: member),
                                ),
                              );

                              if (updated == true && context.mounted) {
                                await context
                                    .read<MemberProvider>()
                                    .fetchMembers();
                              }
                            },
                            onDelete: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Delete Member'),
                                  content: Text(
                                    'Are you sure you want to delete ${member.fullName}?',
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
                                  await MemberService.deleteMember(member.id);

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Member deleted successfully',
                                        ),
                                      ),
                                    );
                                  }

                                  if (context.mounted) {
                                    await context
                                        .read<MemberProvider>()
                                        .fetchMembers();
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
            MaterialPageRoute(builder: (_) => const MemberFormScreen()),
          );

          if (created == true && context.mounted) {
            await context.read<MemberProvider>().fetchMembers();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Member'),
      ),
    );
  }
}
