import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vimbika_pro/app_constants/app_constants.dart';
import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:vimbika_pro/model/currency.dart';
import 'package:vimbika_pro/model/mobile_pos_shift.dart';

class ShiftSummaryPreviewScreen extends StatelessWidget {
  final MobilePosShift shift;
  final List<Currency> availableCurrencies;

  const ShiftSummaryPreviewScreen({
    super.key,
    required this.shift,
    required this.availableCurrencies,
  });

  @override
  Widget build(BuildContext context) {
    // Group activities by currency
    Map<String, Map<String, double>> currencyTotals = {}; // {currencyId: {type: amount}}
    Map<String, Map<String, double>> paymentTypeBreakdown = {}; // {currencyId: {paymentTypeName: totalAmount}}

    shift.shiftCurrencyAmounts?.forEach((activity) {
      if (activity.currency.id != null) {
        currencyTotals.putIfAbsent(activity.currency.id!, () => {
          'CASH_IN': 0.0,
          'CASH_OUT': 0.0,
          'CASH_PAYMENT': 0.0, // Payments made with cash
          'OTHER_PAYMENT': 0.0, // Payments made with non-cash methods
        });

        if (activity.amountType == 'CASH_IN') {
          currencyTotals[activity.currency.id!]!['CASH_IN'] =
              (currencyTotals[activity.currency.id!]!['CASH_IN'] ?? 0.0) + activity.amount;
        } else if (activity.amountType == 'CASH_OUT') {
          currencyTotals[activity.currency.id!]!['CASH_OUT'] =
              (currencyTotals[activity.currency.id!]!['CASH_OUT'] ?? 0.0) + activity.amount;
        } else if (activity.amountType == 'SALE') {
          if ((activity.isCash ?? false) || activity.paymentType!.toLowerCase().startsWith('cash') ) {
            currencyTotals[activity.currency.id!]!['CASH_PAYMENT'] =
                (currencyTotals[activity.currency.id!]!['CASH_PAYMENT'] ?? 0.0) + activity.amount;
          } else {
            currencyTotals[activity.currency.id!]!['OTHER_PAYMENT'] =
                (currencyTotals[activity.currency.id!]!['OTHER_PAYMENT'] ?? 0.0) + activity.amount;
          }

          // Populate paymentTypeBreakdown for 'Payment' activities
          final currencyId = activity.currency.id!;
          final paymentTypeName = activity.paymentType ?? 'Unknown Payment Type';

          paymentTypeBreakdown.putIfAbsent(currencyId, () => {});
          paymentTypeBreakdown[currencyId]!.update(
            paymentTypeName,
            (value) => value + activity.amount,
            ifAbsent: () => activity.amount,
          );
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shift Summary Preview', style: AppTheme.title),
        backgroundColor: AppTheme.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.nearlyBlack),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    shift.company?.name ?? 'Company Name',
                    style: AppTheme.title.copyWith(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Center(child: Text('Shift Report', style: AppTheme.subtitle.copyWith(fontSize: 18))),
                const SizedBox(height: 16),
                _buildInfoRow('User:', shift.userFullName ?? 'N/A'),
                _buildInfoRow('Shift Start:', (shift.openingTime != null) ? DateFormat(AppConstants.APP_DATE_TIME_FMT).format(DateTime.parse(shift.openingTime!)) : 'N/A'),
                _buildInfoRow('Shift End:', (shift.closingTime != null) ? DateFormat(AppConstants.APP_DATE_TIME_FMT).format(DateTime.parse(shift.closingTime!)) : 'N/A'),
                const Divider(thickness: 1, height: 32),

                ...currencyTotals.entries.map((entry) {
                  final currencyId = entry.key;
                  final totals = entry.value;
                  final currency = availableCurrencies.firstWhere((c) => c.id == currencyId);

                  final cashInTotal = totals['CASH_IN'] ?? 0.0;
                  final cashOutTotal = totals['CASH_OUT'] ?? 0.0;
                  final cashPaymentTotal = totals['CASH_PAYMENT'] ?? 0.0;
                  final otherPaymentTotal = totals['OTHER_PAYMENT'] ?? 0.0;

                  final totalSales = cashPaymentTotal + otherPaymentTotal;
                  final totalCash = cashInTotal - cashOutTotal + cashPaymentTotal;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Summary for ${currency.name} (${currency.symbol})',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                        ),
                        const SizedBox(height: 8),
                        _buildSummaryRow('Initial Cash:', '${currency.symbol} 0.00'),
                        _buildSummaryRow('Total Cash In:', '${currency.symbol} ${cashInTotal.toStringAsFixed(2)}'),
                        _buildSummaryRow('Total Cash Out:', '${currency.symbol} ${cashOutTotal.toStringAsFixed(2)}'),
                        _buildSummaryRow('Total Cash Sales:', '${currency.symbol} ${cashPaymentTotal.toStringAsFixed(2)}'),
                        _buildSummaryRow('Total Other Sales:', '${currency.symbol} ${otherPaymentTotal.toStringAsFixed(2)}'),
                        const Divider(height: 16, thickness: 0.5),
                        _buildSummaryRow('Total Sales:', '${currency.symbol} ${totalSales.toStringAsFixed(2)}', isBold: true),
                        _buildSummaryRow('Expected Cash:', '${currency.symbol} ${totalCash.toStringAsFixed(2)}', isBold: true),

                        if (paymentTypeBreakdown.containsKey(currencyId) && paymentTypeBreakdown[currencyId]!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Sales by Payment Type:',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                ...paymentTypeBreakdown[currencyId]!.entries.map((ptEntry) {
                                  return _buildSummaryRow(
                                    '  ${ptEntry.key}:',
                                    '${currency.symbol} ${ptEntry.value.toStringAsFixed(2)}',
                                  );
                                }),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                }),
                const Divider(thickness: 1, height: 32),
                const Text(
                  'All Activities',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                ),
                const SizedBox(height: 8),
                if (shift.shiftCurrencyAmounts == null || shift.shiftCurrencyAmounts!.isEmpty)
                  const Text('No activities recorded.')
                else
                  ...shift.shiftCurrencyAmounts!.map((activity) {
                    String activityLabel;
                    if (activity.amountType == 'CASH_IN') {
                      activityLabel = 'Cash In';
                    } else if (activity.amountType == 'CASH_OUT') {
                      activityLabel = 'Cash Out';
                    } else if (activity.amountType == 'SALE') {
                      activityLabel = 'Sale (${activity.paymentType ?? 'N/A'})';
                    } else {
                      activityLabel = activity.amountType; // Fallback
                    }
                    return _buildActivityRow(
                      label: '$activityLabel: ${activity.notes ?? ''}',
                      amount: activity.amount,
                      symbol: activity.currency.symbol!,
                      isCashOut: activity.amountType == 'CASH_OUT',
                    );
                  }),
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
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityRow({required String label, required double amount, required String symbol, bool isCashOut = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          Text(
            '${isCashOut ? '-' : ''}$symbol ${amount.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 14, color: isCashOut ? Colors.red : Colors.green),
          ),
        ],
      ),
    );
  }
}