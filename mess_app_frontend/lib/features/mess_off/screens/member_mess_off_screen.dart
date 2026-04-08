import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/providers/auth_provider.dart';
import '../providers/mess_off_provider.dart';
import '../widgets/mess_off_card.dart';

class MemberMessOffScreen extends StatelessWidget {
  const MemberMessOffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final memberId = authProvider.currentUser?.id ?? 0;

    return ChangeNotifierProvider(
      create: (_) => MessOffProvider()..fetchMessOffEntriesByMember(memberId),
      child: const _MemberMessOffView(),
    );
  }
}

class _MemberMessOffView extends StatelessWidget {
  const _MemberMessOffView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MessOffProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('My Mess Off')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : provider.errorMessage != null
            ? Center(child: Text(provider.errorMessage!))
            : provider.filteredEntries.isEmpty
            ? const Center(child: Text('No mess off history found'))
            : RefreshIndicator(
                onRefresh: () async {
                  final authProvider = context.read<AuthProvider>();
                  final memberId = authProvider.currentUser?.id ?? 0;
                  await context
                      .read<MessOffProvider>()
                      .fetchMessOffEntriesByMember(memberId);
                },
                child: ListView.builder(
                  itemCount: provider.filteredEntries.length,
                  itemBuilder: (context, index) {
                    final entry = provider.filteredEntries[index];
                    return MessOffCard(entry: entry);
                  },
                ),
              ),
      ),
    );
  }
}
