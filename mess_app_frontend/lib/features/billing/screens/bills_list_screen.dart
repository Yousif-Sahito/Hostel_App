import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_drawer.dart';
import '../models/bill_model.dart';
import '../providers/bill_provider.dart';
import '../services/bill_service.dart';
import '../widgets/bill_card.dart';
import 'member_bill_screen.dart';

class BillsListScreen extends StatelessWidget {
  const BillsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BillProvider()..fetchBills(),
      child: const _BillsListView(),
    );
  }
}

class _BillsListView extends StatelessWidget {
  const _BillsListView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BillProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Bills')),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search bills...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onChanged: provider.searchBills,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.errorMessage != null
                  ? Center(child: Text(provider.errorMessage!))
                  : provider.filteredBills.isEmpty
                  ? const Center(child: Text('No bills found'))
                  : RefreshIndicator(
                      onRefresh: provider.fetchBills,
                      child: ListView.builder(
                        itemCount: provider.filteredBills.length,
                        itemBuilder: (context, index) {
                          final BillModel bill = provider.filteredBills[index];

                          return BillCard(
                            bill: bill,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MemberBillScreen(bill: bill),
                                ),
                              );
                              if (context.mounted) {
                                await context.read<BillProvider>().fetchBills();
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
        onPressed: () => _showGenerateDialog(context),
        icon: const Icon(Icons.receipt_long),
        label: const Text('Generate Bills'),
      ),
    );
  }

  Future<void> _showGenerateDialog(BuildContext context) async {
    final now = DateTime.now();
    final monthController = TextEditingController(text: now.month.toString());
    final yearController = TextEditingController(text: now.year.toString());
    final memberIdController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Generate Monthly Bills'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: monthController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Month',
                hintText: 'e.g. 3',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: yearController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Year',
                hintText: 'e.g. 2026',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: memberIdController,
              decoration: const InputDecoration(
                labelText: 'Member ID or CMS ID (optional)',
                hintText: 'e.g. 133-24-0003 or 123',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final month = int.parse(monthController.text.trim());
                final year = int.parse(yearController.text.trim());
                final memberIdentifier = memberIdController.text.trim().isEmpty
                    ? null
                    : memberIdController.text.trim();

                await BillService.generateBills(
                  month: month,
                  year: year,
                  memberIdentifier: memberIdentifier,
                );

                if (context.mounted) {
                  Navigator.pop(context, true);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceFirst('Exception: ', '')),
                    ),
                  );
                }
              }
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bills generated successfully')),
      );
      await context.read<BillProvider>().fetchBills();
    }
  }
}
