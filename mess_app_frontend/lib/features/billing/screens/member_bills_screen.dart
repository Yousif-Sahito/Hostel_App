import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/providers/auth_provider.dart';
import '../providers/bill_provider.dart';
import '../widgets/bill_card.dart';

class MemberBillsScreen extends StatelessWidget {
  const MemberBillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final memberId = authProvider.currentUser?.id ?? 0;

    return ChangeNotifierProvider(
      create: (_) => BillProvider()..fetchBillsByMember(memberId),
      child: const _MemberBillsView(),
    );
  }
}

class _MemberBillsView extends StatelessWidget {
  const _MemberBillsView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BillProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('My Bills')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : provider.errorMessage != null
            ? Center(child: Text(provider.errorMessage!))
            : provider.filteredBills.isEmpty
            ? const Center(child: Text('No bills found'))
            : RefreshIndicator(
                onRefresh: () async {
                  final authProvider = context.read<AuthProvider>();
                  final memberId = authProvider.currentUser?.id ?? 0;
                  await context.read<BillProvider>().fetchBillsByMember(
                    memberId,
                  );
                },
                child: ListView.builder(
                  itemCount: provider.filteredBills.length,
                  itemBuilder: (context, index) {
                    final bill = provider.filteredBills[index];
                    return BillCard(bill: bill);
                  },
                ),
              ),
      ),
    );
  }
}
