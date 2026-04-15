import 'package:flutter/material.dart';

import '../../billing/models/bill_model.dart';
import '../services/payment_service.dart';

class PaymentFormScreen extends StatefulWidget {
  final BillModel bill;

  const PaymentFormScreen({super.key, required this.bill});

  @override
  State<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends State<PaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController amountController;
  late final TextEditingController paymentDateController;
  late final TextEditingController referenceNoController;
  late final TextEditingController notesController;

  String paymentMethod = 'CASH';
  String paymentPurpose = 'REGULAR';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    amountController = TextEditingController();
    paymentDateController = TextEditingController(text: _todayDate());
    referenceNoController = TextEditingController();
    notesController = TextEditingController();
  }

  String _todayDate() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    amountController.dispose();
    paymentDateController.dispose();
    referenceNoController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final paymentResponse = await PaymentService.addPayment(
        billId: widget.bill.id!,
        userId: widget.bill.userId,
        amount: double.parse(amountController.text.trim()),
        paymentMethod: paymentMethod,
        paymentDate: paymentDateController.text.trim(),
        paymentType: paymentPurpose,
        referenceNo: referenceNoController.text.trim().isEmpty
            ? null
            : referenceNoController.text.trim(),
        notes: [
          paymentPurpose == 'ADVANCE' ? 'Advance payment' : 'Regular payment',
          if (notesController.text.trim().isNotEmpty) notesController.text.trim(),
        ].join(' - '),
      );

      if (!mounted) return;

      final remainingAdvanceBalance =
          (paymentResponse['remainingAdvanceBalance'] ?? 0).toDouble();
      final advancedAmount =
          (paymentResponse['advancedAmount'] ?? 0).toDouble();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            advancedAmount > 0
                ? 'Payment added. Rs. ${advancedAmount.toStringAsFixed(0)} moved to advance. Balance: Rs. ${remainingAdvanceBalance.toStringAsFixed(0)}'
                : 'Payment added successfully',
          ),
        ),
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

  Widget _textField(
    String label,
    TextEditingController controller, {
    bool requiredField = true,
    TextInputType? keyboardType,
    String? hintText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: (value) {
          if (requiredField && (value == null || value.trim().isEmpty)) {
            return '$label is required';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bill = widget.bill;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Payment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Member: ${bill.userName ?? 'Member #${bill.userId}'}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Bill Total: Rs. ${bill.totalAmount.toStringAsFixed(0)}',
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Due Amount: Rs. ${bill.dueAmount.toStringAsFixed(0)}',
                    ),
                  ),
                  const SizedBox(height: 16),
                  _textField(
                    'Amount',
                    amountController,
                    keyboardType: TextInputType.number,
                    hintText: 'e.g. 1000',
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: paymentPurpose,
                    decoration: InputDecoration(
                      labelText: 'Payment Type',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'REGULAR',
                        child: Text('Regular Payment'),
                      ),
                      DropdownMenuItem(
                        value: 'ADVANCE',
                        child: Text('Advance Payment'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => paymentPurpose = value);
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  _textField(
                    'Payment Date',
                    paymentDateController,
                    hintText: 'yyyy-mm-dd',
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: paymentMethod,
                    decoration: InputDecoration(
                      labelText: 'Payment Method',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'CASH', child: Text('CASH')),
                      DropdownMenuItem(value: 'BANK', child: Text('BANK')),
                      DropdownMenuItem(
                        value: 'EASYPAISA',
                        child: Text('EASYPAISA'),
                      ),
                      DropdownMenuItem(
                        value: 'JAZZCASH',
                        child: Text('JAZZCASH'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => paymentMethod = value);
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  _textField(
                    'Reference No',
                    referenceNoController,
                    requiredField: false,
                    hintText: 'Optional',
                  ),
                  _textField(
                    'Notes',
                    notesController,
                    requiredField: false,
                    hintText: 'Optional',
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Save Payment'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
