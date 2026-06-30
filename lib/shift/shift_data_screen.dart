import 'package:flutter/material.dart';
import 'package:vimbika_pro/model/mobile_pos_shift.dart';
import '../app_constants/app_theme.dart';
import '../model/mobile_shift_currency_amount.dart';
import '../model/currency.dart';

class ShiftDataScreen extends StatelessWidget {
  final MobilePosShift shift;
  final List<Currency> availableCurrencies;

  const ShiftDataScreen({super.key, required this.shift, required this.availableCurrencies});

  @override
  Widget build(BuildContext context) {
    // Calculate summary data
    final Map<String, Map<String, double>> currencyTotals = {};
    final Map<String, Map<String, double>> paymentTypeBreakdown = {};

    final sortedActivities = shift.shiftCurrencyAmounts != null
        ? List<MobileShiftCurrencyAmount>.from(shift.shiftCurrencyAmounts!)
        : <MobileShiftCurrencyAmount>[];

    sortedActivities.sort((a, b) {
      if (a.timeCreated == null || b.timeCreated == null) return 0;
      try {
        return DateTime.parse(a.timeCreated!).compareTo(DateTime.parse(b.timeCreated!));
      } catch (e) {
        return 0;
      }
    });

    for (var activity in sortedActivities) {
      if (activity.currency.id != null) {
        currencyTotals.putIfAbsent(activity.currency.id!, () => {
          'CASH_IN': 0.0,
          'CASH_OUT': 0.0,
          'CASH_PAYMENT': 0.0,
          'OTHER_PAYMENT': 0.0,
          'CASH_ACCOUNT_TOP_UP': 0.0,
          'OTHER_ACCOUNT_TOP_UP': 0.0,
        });

        if (activity.amountType == 'CASH_IN') {
          currencyTotals[activity.currency.id!]!['CASH_IN'] =
              (currencyTotals[activity.currency.id!]!['CASH_IN'] ?? 0.0) + activity.amount;
        } else if (activity.amountType == 'ACCOUNT_TOP_UP') {
          if (activity.isCash == true || (activity.paymentType?.toLowerCase().startsWith('cash') ?? false)) {
            currencyTotals[activity.currency.id!]!['CASH_ACCOUNT_TOP_UP'] =
                (currencyTotals[activity.currency.id!]!['CASH_ACCOUNT_TOP_UP'] ?? 0.0) + activity.amount;
          } else {
            currencyTotals[activity.currency.id!]!['OTHER_ACCOUNT_TOP_UP'] =
                (currencyTotals[activity.currency.id!]!['OTHER_ACCOUNT_TOP_UP'] ?? 0.0) + activity.amount;
          }
        } else if (activity.amountType == 'CASH_OUT') {
          currencyTotals[activity.currency.id!]!['CASH_OUT'] =
              (currencyTotals[activity.currency.id!]!['CASH_OUT'] ?? 0.0) + activity.amount;
        } else if (activity.amountType == 'SALE') {
          if ((activity.isCash ?? false) || (activity.paymentType?.toLowerCase().startsWith('cash') ?? false)) {
            currencyTotals[activity.currency.id!]!['CASH_PAYMENT'] =
                (currencyTotals[activity.currency.id!]!['CASH_PAYMENT'] ?? 0.0) + activity.amount;
          } else {
            currencyTotals[activity.currency.id!]!['OTHER_PAYMENT'] =
                (currencyTotals[activity.currency.id!]!['OTHER_PAYMENT'] ?? 0.0) + activity.amount;
          }

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
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shift Details'),
        backgroundColor: AppTheme.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.nearlyBlack),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shift Reference: ${shift.shiftReference ?? 'N/A'}',
                      style: AppTheme.title.copyWith(fontSize: 18),
                    ),
                    const Divider(),
                    _buildDetailRow('User:', shift.userFullName ?? 'N/A'),
                    _buildDetailRow('Opening Time:', shift.openingTime ?? 'N/A'),
                    _buildDetailRow('Closing Time:', shift.closingTime ?? 'N/A'),
                    _buildDetailRow('Status:', shift.isShiftClosed ?? false ? 'Closed' : 'Open'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Shift Summary Section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shift Summary',
                      style: AppTheme.title.copyWith(fontSize: 18),
                    ),
                    const Divider(),
                    if (currencyTotals.isEmpty)
                      const Text('No monetary activities recorded for this shift.')
                    else
                      ...currencyTotals.entries.map((entry) {
                        final currencyId = entry.key;
                        final totals = entry.value;
                        final currency = availableCurrencies.firstWhere(
                          (c) => c.id == currencyId,
                          orElse: () => Currency(id: currencyId, name: 'Unknown', symbol: '?'),
                        );

                        final cashInTotal = totals['CASH_IN'] ?? 0.0;
                        final cashAccountTopUpTotal = totals['CASH_ACCOUNT_TOP_UP'] ?? 0.0;
                        final otherAccountTopUpTotal = totals['OTHER_ACCOUNT_TOP_UP'] ?? 0.0;
                        final cashOutTotal = totals['CASH_OUT'] ?? 0.0;
                        final cashPaymentTotal = totals['CASH_PAYMENT'] ?? 0.0;
                        final otherPaymentTotal = totals['OTHER_PAYMENT'] ?? 0.0;

                        final totalSales = cashPaymentTotal + otherPaymentTotal;
                        final totalCash = cashInTotal + cashAccountTopUpTotal - cashOutTotal + cashPaymentTotal;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${currency.name} (${currency.symbol})',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              _buildSummaryRow('Initial Cash:', '${currency.symbol} 0.00'),
                              _buildSummaryRow('Total Cash In:', '${currency.symbol} ${cashInTotal.toStringAsFixed(2)}', color: Colors.green),
                              if (cashAccountTopUpTotal > 0)
                                _buildSummaryRow('Cash Customer Deposits:', '${currency.symbol} ${cashAccountTopUpTotal.toStringAsFixed(2)}', color: Colors.blue),
                              if (otherAccountTopUpTotal > 0)
                                _buildSummaryRow('Other Customer Deposits:', '${currency.symbol} ${otherAccountTopUpTotal.toStringAsFixed(2)}', color: Colors.purple),
                              _buildSummaryRow('Total Cash Out:', '${currency.symbol} ${cashOutTotal.toStringAsFixed(2)}', color: Colors.orange),
                              _buildSummaryRow('Total Cash Sales:', '${currency.symbol} ${cashPaymentTotal.toStringAsFixed(2)}', color: AppTheme.vimbikaBlue),
                              _buildSummaryRow('Total Other Sales:', '${currency.symbol} ${otherPaymentTotal.toStringAsFixed(2)}', color: AppTheme.vimbikaBlue),
                              const Divider(height: 8),
                              _buildSummaryRow('Total Sales:', '${currency.symbol} ${totalSales.toStringAsFixed(2)}', isBold: true, color: AppTheme.vimbikaBlue),
                              _buildSummaryRow('Total Cash:', '${currency.symbol} ${totalCash.toStringAsFixed(2)}', isBold: true),
                              const SizedBox(height: 10),
                              if (paymentTypeBreakdown.containsKey(currencyId) && paymentTypeBreakdown[currencyId]!.isNotEmpty)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 10),
                                    Text(
                                      'Sales by Payment Type:',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.darkText),
                                    ),
                                    ...paymentTypeBreakdown[currencyId]!.entries.map((ptEntry) {
                                      return _buildSummaryRow(
                                        '  ${ptEntry.key}:',
                                        '${currency.symbol} ${ptEntry.value.toStringAsFixed(2)}',
                                        fontSize: 14,
                                      );
                                    }),
                                  ],
                                ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Activities Section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExpansionTile(
                      title: Text(
                        'Activities',
                        style: AppTheme.title.copyWith(fontSize: 18),
                      ),
                      initiallyExpanded: true, // Always expanded for a past shift view
                      children: [
                        if (sortedActivities.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('No activities recorded for this shift.'),
                          )
                        else
                          ...sortedActivities.map((activity) {
                            String activityLabel;
                            Color activityColor;
                            if (activity.amountType == 'CASH_IN') {
                              activityLabel = 'Cash In';
                              activityColor = Colors.green;
                            } else if (activity.amountType == 'ACCOUNT_TOP_UP') {
                              activityLabel = 'Account Top Up';
                              activityColor = Colors.blue;
                            } else if (activity.amountType == 'CASH_OUT') {
                              activityLabel = 'Cash Out';
                              activityColor = Colors.red;
                            } else if (activity.amountType == 'SALE') {
                              activityLabel = (activity.isCash == true || (activity.paymentType?.toLowerCase().startsWith('cash') ?? false)) ? 'Cash Sale' : 'Other Sale';
                              activityColor = AppTheme.vimbikaBlue;
                            } else {
                              activityLabel = activity.amountType;
                              activityColor = Colors.black;
                            }

                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '$activityLabel: ${activity.notes ?? ''}',
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                            if (activity.timeCreated != null)
                                              Text(
                                                '${activity.currency.name} - ${activity.paymentType ?? ''} - ${activity.timeCreated}',
                                                style: const TextStyle(fontSize: 12, color: AppTheme.grey),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${activity.amountType == 'CASH_OUT' ? '-' : ''}${activity.currency.symbol} ${activity.amount.toStringAsFixed(2)}',
                                        style: TextStyle(color: activityColor, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(),
                              ],
                            );
                          }),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? color, bool isBold = false, double fontSize = 16}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? AppTheme.darkText,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? AppTheme.darkText,
            ),
          ),
        ],
      ),
    );
  }
}