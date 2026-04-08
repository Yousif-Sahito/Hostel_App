import 'package:flutter/material.dart';

import '../models/bill_model.dart';
import '../services/bill_service.dart';
import '../../payments/screens/payment_form_screen.dart';

class MemberBillScreen extends StatefulWidget {
  final BillModel bill;

  const MemberBillScreen({super.key, required this.bill});

  @override
  State<MemberBillScreen> createState() => _MemberBillScreenState();
}

class _MemberBillScreenState extends State<MemberBillScreen> {
  late final TextEditingController extraChargesController;
  late final TextEditingController paidAmountController;
  late String paymentStatus;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    extraChargesController = TextEditingController(
      text: widget.bill.extraCharges > 0
          ? widget.bill.extraCharges.toStringAsFixed(0)
          : '',
    );

    paidAmountController = TextEditingController(
      text: widget.bill.paidAmount > 0
          ? widget.bill.paidAmount.toStringAsFixed(0)
          : '',
    );

    paymentStatus = widget.bill.paymentStatus;
  }

  @override
  void dispose() {
    extraChargesController.dispose();
    paidAmountController.dispose();
    super.dispose();
  }

  // ✅ ONLY LOGIC HERE (FIXED)
  Future<void> _save() async {
    setState(() => isLoading = true);

    try {
      await BillService.updateBill(
        id: widget.bill.id!,
        extraCharges: double.tryParse(extraChargesController.text.trim()) ?? 0,
        paidAmount: double.tryParse(paidAmountController.text.trim()) ?? 0,
        paymentStatus: paymentStatus,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bill updated successfully')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Widget _item(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bill = widget.bill;

    return Scaffold(
      appBar: AppBar(title: const Text('Bill Detail')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _item('Member', bill.userName ?? 'Member #${bill.userId}'),
                _item('Month/Year', '${bill.month}/${bill.year}'),
                _item('Breakfast Units', bill.breakfastUnits.toString()),
                _item('Lunch Units', bill.lunchUnits.toString()),
                _item('Dinner Units', bill.dinnerUnits.toString()),
                _item('Guest Units', bill.guestUnits.toString()),
                _item(
                  'Helper Charge',
                  'Rs. ${bill.helperCharge.toStringAsFixed(0)}',
                ),
                _item(
                  'Total Amount',
                  'Rs. ${bill.totalAmount.toStringAsFixed(0)}',
                ),
                _item('Due Amount', 'Rs. ${bill.dueAmount.toStringAsFixed(0)}'),

                const SizedBox(height: 10),

                // ✅ Extra Charges
                TextField(
                  controller: extraChargesController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Extra Charges',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // ✅ Paid Amount
                TextField(
                  controller: paidAmountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Paid Amount',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // ✅ Status Dropdown
                DropdownButtonFormField<String>(
                  initialValue: paymentStatus,
                  decoration: InputDecoration(
                    labelText: 'Payment Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'PAID', child: Text('PAID')),
                    DropdownMenuItem(value: 'PARTIAL', child: Text('PARTIAL')),
                    DropdownMenuItem(value: 'UNPAID', child: Text('UNPAID')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => paymentStatus = value);
                    }
                  },
                ),

                const SizedBox(height: 16),

                // ✅ ADD PAYMENT BUTTON (CORRECT PLACE)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PaymentFormScreen(bill: bill),
                        ),
                      );

                      if (mounted && result == true) {
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Payment added successfully'),
                          ),
                        );
                      }
                    },
                    child: const Text('Add Payment'),
                  ),
                ),

                const SizedBox(height: 16),

                // ✅ UPDATE BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _save,
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Update Bill'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
