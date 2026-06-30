import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vimbika_pro/model/base_name_model.dart';
import '../app_constants/app_constants.dart';
import '../model/mobile_pos_shift.dart';
import '../model/user.dart';
import '../model/mobile_shift_currency_amount.dart';
import '../app_constants/app_theme.dart';
import 'package:intl/intl.dart';
import '../services/mobile_shift_service.dart';

class ShiftExcelPreviewScreen extends StatefulWidget {
  final List<MobileShiftCurrencyAmount> amounts;
  final String fileName;

  const ShiftExcelPreviewScreen({
    super.key,
    required this.amounts,
    required this.fileName,
  });

  @override
  State<ShiftExcelPreviewScreen> createState() => _ShiftExcelPreviewScreenState();
}

class _ShiftExcelPreviewScreenState extends State<ShiftExcelPreviewScreen> {
  final MobilePosShiftService _shiftService = MobilePosShiftService();
  bool _isSaving = false;

  Future<void> _saveToApi() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? userData = prefs.getString(AppConstants.keyOnlineUserData);
      if (userData == null) throw Exception('User not logged in');
      final user = User.fromJson(jsonDecode(userData));

      // Extract shift reference from filename (remove extension if present)
      String shiftReference = widget.fileName;
      if (shiftReference.contains('.')) {
        shiftReference = shiftReference.substring(0, shiftReference.lastIndexOf('.'));
      }

      // Update amounts with this shift reference
      final List<MobileShiftCurrencyAmount> amountsToSave = widget.amounts.map((amount) {
        return amount.copyWith(shiftReference: shiftReference);
      }).toList();

      final MobilePosShift shiftToSave = MobilePosShift(
        shiftReference: shiftReference,
        userId: user.id,
        company: BaseNameModel(id: user.companyId, name: user.branch?.company.value?.name),
        userFullName: '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim(),
        createdByName: user.userName,
        openingTime: DateFormat(AppConstants.APP_DATE_TIME_FMT).format(DateTime.now()),
        dateCreated: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        shiftCurrencyAmounts: amountsToSave,
        active: true,
        isShiftClosed: true, // Assuming imported shifts are complete/closed
      );

      await _shiftService.createShift(shiftToSave, syncOnly: true);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shift and activities saved to API successfully!')),
      );
      Navigator.pop(context); // Close preview after success
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save to API: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Group totals by payment type and currency
    Map<String, Map<String, double>> totalsByPaymentType = {};
    Map<String, double> totalCash = {};
    Map<String, double> totalSales = {};

    for (final amount in widget.amounts) {
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
        title: Text('Preview: ${widget.fileName}'),
        backgroundColor: AppTheme.vimbikaBlue,
        foregroundColor: Colors.white,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
            )
          else
            IconButton(
              icon: const Icon(Icons.cloud_upload),
              tooltip: 'Save to API',
              onPressed: _saveToApi,
            ),
        ],
      ),
      body: widget.amounts.isEmpty
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
                    itemCount: widget.amounts.length,
                    itemBuilder: (context, index) {
                      final amount = widget.amounts[index];
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
                              if (amount.shiftReference != null)
                                Text('Shift Ref: ${amount.shiftReference}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
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
