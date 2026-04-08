import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/providers/auth_provider.dart';
import '../providers/payment_provider.dart';
import '../widgets/payment_card.dart';

class PaymentHistoryScreen extends StatelessWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final memberId = authProvider.currentUser?.id ?? 0;
    final isAdmin = authProvider.currentUser?.role == 'ADMIN';

    return ChangeNotifierProvider(
      create: (_) {
        final provider = PaymentProvider();
        if (isAdmin) {
          provider.fetchAllPayments();
        } else {
          provider.fetchPaymentsByMember(memberId);
        }
        return provider;
      },
      child: const _PaymentHistoryView(),
    );
  }
}

class _PaymentHistoryView extends StatelessWidget {
  const _PaymentHistoryView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PaymentProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Payment History')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search by name, CMS ID, email, date or reference...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onChanged: provider.searchPayments,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.errorMessage != null
                  ? Center(child: Text(provider.errorMessage!))
                  : provider.filteredPayments.isEmpty
                  ? const Center(child: Text('No payment history found'))
                  : RefreshIndicator(
                      onRefresh: () async {
                        final authProvider = context.read<AuthProvider>();
                        final memberId = authProvider.currentUser?.id ?? 0;
                        final isAdmin = authProvider.currentUser?.role == 'ADMIN';
                        if (isAdmin) {
                          await context.read<PaymentProvider>().fetchAllPayments();
                        } else {
                          await context
                              .read<PaymentProvider>()
                              .fetchPaymentsByMember(memberId);
                        }
                      },
                      child: ListView.builder(
                        itemCount: provider.filteredPayments.length,
                        itemBuilder: (context, index) {
                          final payment = provider.filteredPayments[index];
                          return PaymentCard(payment: payment);
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
