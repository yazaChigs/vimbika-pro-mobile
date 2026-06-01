import 'package:flutter/material.dart';
import 'package:vimbika_pro/model/mobile_pos_shift.dart';
import '../app_constants/app_theme.dart';

class ShiftDataScreen extends StatelessWidget {
  final MobilePosShift shift;

  const ShiftDataScreen({Key? key, required this.shift}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Shift Details'),
        backgroundColor: AppTheme.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.nearlyBlack),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
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
                const SizedBox(height: 20),
                Text(
                  'Activities',
                  style: AppTheme.title.copyWith(fontSize: 16),
                ),
                const Divider(),
                if (shift.shiftCurrencyAmounts == null || shift.shiftCurrencyAmounts!.isEmpty)
                  const Text('No activities recorded for this shift.')
                else
                  ...shift.shiftCurrencyAmounts!.map((activity) {
                    return ListTile(
                      title: Text('${activity.amountType} - ${activity.notes ?? ''}'),
                      trailing: Text(
                        '${activity.currency.symbol} ${activity.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: activity.amountType == 'CASH_OUT' ? Colors.red : Colors.green,
                        ),
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),
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
}