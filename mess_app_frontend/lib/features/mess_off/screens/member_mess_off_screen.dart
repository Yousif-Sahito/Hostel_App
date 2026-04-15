import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/providers/auth_provider.dart';
import '../providers/mess_off_provider.dart';
import '../services/mess_off_service.dart';
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

  Future<void> _refresh(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final memberId = authProvider.currentUser?.id ?? 0;
    await context.read<MessOffProvider>().fetchMessOffEntriesByMember(memberId);
  }

  Future<void> _toggleMessOff(BuildContext context) async {
    try {
      final isOff = await MessOffService.toggleMessStatus();
      if (!context.mounted) return;

      await _refresh(context);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isOff
                ? 'Mess marked OFF for tomorrow.'
                : 'Mess turned back ON for tomorrow.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MessOffProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Mess Off'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: provider.isLoading ? null : () => _refresh(context),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: provider.isLoading ? null : () => _toggleMessOff(context),
                icon: const Icon(Icons.toggle_on),
                label: const Text('Toggle Tomorrow Mess Off'),
              ),
            ),
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Use this button before 1 PM to turn tomorrow mess off/on. Your history appears below.',
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.errorMessage != null
                  ? Center(child: Text(provider.errorMessage!))
                  : provider.filteredEntries.isEmpty
                  ? const Center(child: Text('No mess off history found'))
                  : RefreshIndicator(
                      onRefresh: () => _refresh(context),
                      child: ListView.builder(
                        itemCount: provider.filteredEntries.length,
                        itemBuilder: (context, index) {
                          final entry = provider.filteredEntries[index];
                          return MessOffCard(entry: entry);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
