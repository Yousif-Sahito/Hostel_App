import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/payment_model.dart';

class PaymentCard extends StatelessWidget {
  final PaymentModel payment;

  const PaymentCard({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        title: Text(
          payment.userName ?? 'Member #${payment.userId}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            if ((payment.userCmsId ?? '').isNotEmpty)
              Text('CMS ID: ${payment.userCmsId}'),
            if ((payment.userEmail ?? '').isNotEmpty)
              Text('Email: ${payment.userEmail}'),
            Text('Amount: Rs. ${payment.amount.toStringAsFixed(0)}'),
            Text('Method: ${payment.paymentMethod}'),
            Text('Date: ${payment.paymentDate}'),
            Text('Reference: ${payment.referenceNo ?? '-'}'),
            if ((payment.notes ?? '').trim().isNotEmpty)
              Text('Notes: ${payment.notes}'),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.share),
          tooltip: 'Share receipt',
          onPressed: () => _shareReceipt(context),
        ),
      ),
    );
  }

  void _shareReceipt(BuildContext context) {
    final message = StringBuffer();
    message.writeln(
      'Payment receipt for ${payment.userName ?? 'Member #${payment.userId}'}',
    );
    if ((payment.userCmsId ?? '').isNotEmpty) {
      message.writeln('CMS ID: ${payment.userCmsId}');
    }
    if ((payment.userEmail ?? '').isNotEmpty) {
      message.writeln('Email: ${payment.userEmail}');
    }
    message.writeln('Amount: Rs. ${payment.amount.toStringAsFixed(0)}');
    message.writeln('Method: ${payment.paymentMethod}');
    message.writeln('Date: ${payment.paymentDate}');
    message.writeln('Reference: ${payment.referenceNo ?? '-'}');
    if ((payment.notes ?? '').trim().isNotEmpty) {
      message.writeln('Notes: ${payment.notes}');
    }

    SharePlus.instance.share(ShareParams(text: message.toString()));
  }
}
