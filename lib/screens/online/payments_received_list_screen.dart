import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vimbika_pro/app_constants/app_colors.dart';
import 'package:vimbika_pro/model/payment_received.dart';
import 'package:vimbika_pro/model/currency.dart';

class PaymentsReceivedListScreen extends StatelessWidget {
  final List<PaymentReceived> payments;
  final Currency? selectedCurrency;

  const PaymentsReceivedListScreen({
    super.key,
    required this.payments,
    this.selectedCurrency,
  });

  @override
  Widget build(BuildContext context) {
    final symbol = selectedCurrency?.symbol ?? '\$';
    final totalAmount = payments.fold(0.0, (sum, p) => sum + p.amount);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Payments Received",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              children: [
                Text(
                  "$symbol${totalAmount.toStringAsFixed(2)}",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold),
                ),
                const Text("Total Payments Received",
                    style: TextStyle(color: Colors.white70, fontSize: 16)),
              ],
            ),
          ),
          Expanded(
            child: payments.isEmpty
                ? const Center(
                    child: Text("No payments received found for the selected period",
                        style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: payments.length,
                    itemBuilder: (context, index) {
                      final payment = payments[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.success.withOpacity(0.1),
                            child: const Icon(Icons.attach_money,
                                color: AppColors.success),
                          ),
                          title: Text(
                            payment.payer.value?.name ?? 'Anonymous Payer',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                payment.paymentType.value?.name ?? 'General Payment',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              if (payment.paymentDescription != null &&
                                  payment.paymentDescription!.isNotEmpty)
                                Text(payment.paymentDescription!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              if (payment.paymentDate != null)
                                Text(payment.paymentDate!,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                            ],
                          ),
                          trailing: Text(
                            "$symbol${payment.amount.toStringAsFixed(2)}",
                            style: const TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
