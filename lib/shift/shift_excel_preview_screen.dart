import 'package:flutter/material.dart';
import '../model/mobile_shift_currency_amount.dart';
import '../app_constants/app_theme.dart';
import 'package:intl/intl.dart';

class ShiftExcelPreviewScreen extends StatelessWidget {
  final List<MobileShiftCurrencyAmount> amounts;
  final String fileName;

  const ShiftExcelPreviewScreen({
    super.key,
    required this.amounts,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    // Group totals by payment type and currency
    Map<String, Map<String, double>> totalsByPaymentType = {};
    Map<String, double> totalCash = {};
    Map<String, double> totalSales = {};

    for (final amount in amounts) {
      String pt = 'Other';
      if (amount.paymentType != null && amount.paymentType!.isNotEmpty) {
        pt = amount.paymentType!;
      } else if (amount.isCash == true) {
        pt = 'Cash';
      }
      
      final String cn = amount.currency.name ?? 'Unknown';
      
      // Totals by payment type
      totalsByPaymentType.putIfAbsent(pt, () => <String, double>{});
      totalsByPaymentType[pt]![cn] = (totalsByPaymentType[pt]![cn] ?? 0.0) + amount.amount;

      // Total Cash
      if (amount.isCash == true) {
        totalCash[cn] = (totalCash[cn] ?? 0.0) + amount.amount;
      }

      // Total Sales
      if (amount.amountType == 'SALE') {
        totalSales[cn] = (totalSales[cn] ?? 0.0) + amount.amount;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Preview: $fileName'),
        backgroundColor: AppTheme.vimbikaBlue,
        foregroundColor: Colors.white,
      ),
      body: amounts.isEmpty
          ? const Center(child: Text('No data found in the Excel file.'))
          : Column(
              children: [
                SizedBox(
                  height: 200,
                  child: _buildSummarySection(totalsByPaymentType, totalCash, totalSales),
                ),
                const Divider(thickness: 2),
                Expanded(
                  child: ListView.builder(
                    itemCount: amounts.length,
                    itemBuilder: (context, index) {
                      final amount = amounts[index];
                      String displayPt = 'Other';
                      if (amount.paymentType != null && amount.paymentType!.isNotEmpty) {
                        displayPt = amount.paymentType!;
                      } else if (amount.isCash == true) {
                        displayPt = 'Cash';
                      }
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: ListTile(
                          title: Text(
                            '${amount.currency.symbol} ${amount.amount.toStringAsFixed(2)} - $displayPt',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Ref: ${amount.ref ?? 'N/A'}'),
                              if (amount.notes != null && amount.notes!.isNotEmpty)
                                Text('Notes: ${amount.notes}'),
                              Text('Time: ${amount.timeCreated ?? 'N/A'}'),
                            ],
                          ),
                          trailing: Text(amount.amountType),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummarySection(
    Map<String, Map<String, double>> totalsByPaymentType,
    Map<String, double> totalCash,
    Map<String, double> totalSales,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (totalCash.isNotEmpty) ...[
              const Text(
                'Total Cash',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ...totalCash.entries.map((e) => Text('${e.key}: ${e.value.toStringAsFixed(2)}')),
              const SizedBox(height: 10),
            ],
            if (totalSales.isNotEmpty) ...[
              const Text(
                'Total Sales',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ...totalSales.entries.map((e) => Text('${e.key}: ${e.value.toStringAsFixed(2)}')),
              const SizedBox(height: 10),
            ],
            const Text(
              'Totals by Payment Type',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...totalsByPaymentType.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key,
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.vimbikaBlue),
                  ),
                  ...entry.value.entries.map((currencyEntry) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Text('${currencyEntry.key}: ${currencyEntry.value.toStringAsFixed(2)}'),
                    );
                  }),
                  const SizedBox(height: 8),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
