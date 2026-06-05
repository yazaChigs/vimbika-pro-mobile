import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vimbika_pro/model/payment_received.dart';
import 'package:vimbika_pro/services/printer_service.dart';

import '../app_constants/app_theme.dart';

class PaymentReceiptScreen extends StatelessWidget {
  final PaymentReceived payment;

  const PaymentReceiptScreen({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    final printerService = PrinterService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Receipt', style: AppTheme.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              scaffoldMessenger.showSnackBar(
                const SnackBar(content: Text('Printing receipt...')),
              );
              await printerService.printPaymentReceipt(payment);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'Official Payment Receipt',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.vimbikaBlue),
                  ),
                ),
                const SizedBox(height: 20),
                _buildInfoRow('Receipt #:', payment.reference ?? 'N/A'),
                _buildInfoRow('Date:', DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())),
                const Divider(height: 30),
                _buildInfoRow('Received From:', payment.payer?.name ?? 'N/A'),
                _buildInfoRow('Amount:', '${payment.currency?.symbol ?? ''} ${payment.amount.toStringAsFixed(2)}'),
                _buildInfoRow('Payment Method:', payment.paymentType?.name ?? 'N/A'),
                if (payment.bank != null) _buildInfoRow('Bank:', payment.bank!.name),
                const Divider(height: 30),
                const Text(
                  'Thank you for your payment!',
                  style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: AppTheme.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}
