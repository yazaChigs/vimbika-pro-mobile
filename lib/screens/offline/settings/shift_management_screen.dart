import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:vimbika_pro/login/login_screen.dart';
import 'package:vimbika_pro/services/sale_sync_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart'; // Import for DateFormat
import '../../../app_constants/app_constants.dart';
import '../../../model/mobile_pos_shift.dart';
import '../../../model/mobile_shift_currency_amount.dart';
import '../../../model/currency.dart';
import '../../../model/user.dart';
import '../../../services/mobile_shift_service.dart';
import '../../../model/base_name_model.dart'; // Import BaseNameModel
import 'shift_summary_preview_screen.dart'; // Import the new preview screen
import '../../../services/printer_service.dart'; // Import PrinterService

class ShiftManagementScreen extends StatefulWidget {
  const ShiftManagementScreen({super.key}); // Use super.key

  @override
  State<ShiftManagementScreen> createState() => _ShiftManagementScreenState(); // Explicitly define return type
}

class _ShiftManagementScreenState extends State<ShiftManagementScreen> {
  MobilePosShift? _currentShift;
  bool _isLoading = true;
  User? _currentUser;
  List<Currency> _availableCurrencies = [];
  Currency? _selectedCurrency; // This will be the default selected currency for the dialog
  bool _isOfflineMode = false; // Added for offline/online mode

  final MobilePosShiftService _shiftService = MobilePosShiftService();
  final SaleSyncService _saleSyncService = SaleSyncService();
  final PrinterService _printerService = PrinterService(); // Instantiate PrinterService

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    _isOfflineMode = prefs.getBool(AppConstants.keyIsOfflineMode) ?? false;

    // Load current user based on mode
    final String userDataKey = _isOfflineMode ? AppConstants.keyOfflineUserData : AppConstants.keyOnlineUserData;
    final String? userData = prefs.getString(userDataKey);
    if (userData != null) {
      _currentUser = User.fromJson(jsonDecode(userData));
    }

    // Load available currencies based on mode
    final String currencyKey = _isOfflineMode ? AppConstants.keyOfflineCurrencies : AppConstants.keyCurrencies;
    final List<String> currencyListJson = prefs.getStringList(currencyKey) ?? [];
    _availableCurrencies = currencyListJson
        .map((item) => Currency.fromJson(jsonDecode(item)))
        .toList();
    if (_availableCurrencies.isNotEmpty) {
      _selectedCurrency = _availableCurrencies.first; // Set a default selected currency
    }

    // Load current open shift
    final String? currentShiftJson = prefs.getString(AppConstants.keyCurrentOpenShift);
    if (currentShiftJson != null && currentShiftJson.isNotEmpty) {
      try {
        _currentShift = MobilePosShift.fromRawJson(currentShiftJson);
      } catch (e) {
        // If parsing fails, it means the stored JSON is invalid.
        // Log the error and clear the malformed data.
        print('Error parsing stored shift JSON: $e');
        await prefs.remove(AppConstants.keyCurrentOpenShift);
        _currentShift = null;
      }
    } else {
      _currentShift = null;
    }
    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _openShift() async {
    if (_currentUser == null || _currentUser!.branch?.company == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User or company information not available. Cannot open shift.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });
    try {
      final BaseNameModel companyBaseNameModel = BaseNameModel(
        id: _currentUser!.branch!.company!.id,
        name: _currentUser!.branch!.company!.name,
      );

      final newShift = MobilePosShift(
        userId: _currentUser!.id,
        userFullName: _currentUser!.userName,
        company: companyBaseNameModel,
        openingTime: DateFormat(AppConstants.APP_DATE_TIME_FMT).format(DateTime.now()),
        isShiftClosed: false,
        shiftCurrencyAmounts: [],
        shiftReference: 'SF${DateTime.now().millisecondsSinceEpoch}',
      );

      if (_isOfflineMode) {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.keyCurrentOpenShift, newShift.toJson());
        if (!mounted) return;
        setState(() {
          _currentShift = newShift;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offline shift opened successfully!')),
        );
      } else {
        final createdShift = await _shiftService.createShift(newShift);
        if (!mounted) return;
        setState(() {
          _currentShift = createdShift;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shift opened successfully!')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open shift: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _closeShift() async {
    setState(() {
      _isLoading = true;
    });
    try {
      if (_currentShift == null || (_currentShift?.isShiftClosed ?? true)) {
        throw Exception('No active shift to close.');
      }

      // Stop the sale sync timer
      _saleSyncService.stopSyncTimer();

      // Sync all unsynced items
      await _saleSyncService.syncSales();

      _currentShift!.closingTime = DateFormat(AppConstants.APP_DATE_TIME_FMT).format(DateTime.now());
      _currentShift!.isShiftClosed = true;

      // Save or update shift based on mode
      if (_isOfflineMode) {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.keyCurrentOpenShift, _currentShift!.toJson());
      } else {
        await _shiftService.createShift(_currentShift!);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shift closed successfully!')),
      );
      await _loadInitialData(); // Reload data to update UI after closing shift

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to close shift: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Clear user preferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.keyUserData);
      await prefs.setBool(AppConstants.keyHasUser, false);
      await prefs.setBool(AppConstants.keyIsOfflineMode, true); // Default to offline mode on logout

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logged out successfully!')),
      );

      // Navigate to login screen and remove all previous routes
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to log out: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showCashActivityDialog(String type) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController notesController = TextEditingController();
    Currency? dialogSelectedCurrency = _selectedCurrency;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$type Amount'),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amount'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Notes (Optional)'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<Currency>(
                  initialValue: dialogSelectedCurrency,
                  decoration: const InputDecoration(
                    labelText: 'Currency',
                    border: OutlineInputBorder(),
                  ),
                  items: _availableCurrencies.map((currency) {
                    return DropdownMenuItem(
                      value: currency,
                      child: Text('${currency.name} (${currency.symbol})'),
                    );
                  }).toList(),
                  onChanged: (Currency? newValue) {
                    setState(() {
                      dialogSelectedCurrency = newValue;
                    });
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final double? amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0 && dialogSelectedCurrency != null) {
                _recordCashActivity(type, amount, notesController.text, dialogSelectedCurrency!);
                Navigator.pop(context);
              } else {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid amount and select a currency')),
                );
              }
            },
            child: Text('Record $type'),
          ),
        ],
      ),
    );
  }

  Future<void> _recordCashActivity(String type, double amount, String notes, Currency selectedCurrency) async {
    if (_currentShift == null || (_currentShift?.isShiftClosed ?? true)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active shift to record activity.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final MobileShiftCurrencyAmount newActivity = MobileShiftCurrencyAmount(
        amount: amount,
        currency: selectedCurrency,
        amountType: type == 'Cash In' ? 'CASH_IN' : 'CASH_OUT',
        notes: notes,
        timeCreated: DateFormat(AppConstants.APP_DATE_TIME_FMT).format(DateTime.now()),
        shiftReference: _currentShift!.shiftReference,
        isCash: true, ref: '',
      );

      _currentShift!.shiftCurrencyAmounts ??= [];
      _currentShift!.shiftCurrencyAmounts!.add(newActivity);

      if (_isOfflineMode) {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.keyCurrentOpenShift, _currentShift!.toJson());
      } else {
        final updatedShift = await _shiftService.createShift(_currentShift!);
        if (!mounted) return;
        setState(() {
          _currentShift = updatedShift;
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$type of ${selectedCurrency.symbol} ${amount.toStringAsFixed(2)} recorded successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to record $type: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _previewShiftSummary() {
    if (_currentShift == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active shift to preview.')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShiftSummaryPreviewScreen(
          shift: _currentShift!,
          availableCurrencies: _availableCurrencies,
        ),
      ),
    );
  }

  Future<void> _printShiftSummary() async {
    if (_currentShift == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active shift to print summary.')),
      );
      return;
    }
    if (!_printerService.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Printer not connected. Please check printer settings.')),
      );
      return;
    }
    if (_currentUser?.branch?.company == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Company information not available. Cannot print summary.')),
      );
      return;
    }
    try {
      await _printerService.printShiftSummary(_currentShift!, _availableCurrencies, _currentUser!.branch!.company!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shift summary sent to printer.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to print shift summary: $e')),
      );
    }
  }

  Future<void> _printFullShiftReport() async {
    if (_currentShift == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active shift to print full report.')),
      );
      return;
    }
    if (!_printerService.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Printer not connected. Please check printer settings.')),
      );
      return;
    }
    if (_currentUser?.branch?.company == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Company information not available. Cannot print full report.')),
      );
      return;
    }
    try {
      await _printerService.printFullShiftReport(_currentShift!, _availableCurrencies, _currentUser!.branch!.company!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Full shift report sent to printer.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to print full shift report: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.nearlyWhite,
      appBar: AppBar(
        title: const Text('Shift Management', style: AppTheme.title),
        backgroundColor: AppTheme.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.nearlyBlack),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCurrentShiftStatus(),
                  const SizedBox(height: 20),
                  _currentShift == null || (_currentShift?.isShiftClosed ?? true)
                      ? Column(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _openShift,
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Open New Shift'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(50),
                                backgroundColor: AppTheme.vimbikaBlue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              onPressed: _logout,
                              icon: const Icon(Icons.logout),
                              label: const Text('Log Out'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(50),
                                backgroundColor: AppTheme.vimbikaBlue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _closeShift,
                              icon: const Icon(Icons.stop),
                              label: const Text('Close Current Shift'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(50),
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              onPressed: _logout,
                              icon: const Icon(Icons.logout),
                              label: const Text('Log Out'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(50),
                                backgroundColor: AppTheme.vimbikaBlue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildShiftActivityButtons(),
                            const SizedBox(height: 20),
                            _buildShiftSummary(),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: _printFullShiftReport,
                              icon: const Icon(Icons.print),
                              label: const Text('Print Full Shift Report'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(50),
                                backgroundColor: AppTheme.vimbikaBlue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                  const SizedBox(height: 30),
                  _buildPastShiftsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildCurrentShiftStatus() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Shift Status',
              style: AppTheme.title.copyWith(fontSize: 18),
            ),
            const Divider(),
            if (_currentShift == null || (_currentShift?.isShiftClosed ?? true))
              const Text('No active shift.', style: TextStyle(fontSize: 16, color: AppTheme.grey))
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Shift Reference: ${_currentShift!.shiftReference ?? 'N/A'}', style: const TextStyle(fontSize: 16)),
                  Text('Opened by: ${_currentShift!.userFullName ?? 'N/A'}', style: const TextStyle(fontSize: 16)),
                  Text(
                    'Opening Time: ${(_currentShift!.openingTime != null) ? DateFormat(AppConstants.APP_DATE_TIME_FMT).format(DateTime.parse(_currentShift!.openingTime!)) : 'N/A'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text('Status: ${_currentShift!.isShiftClosed! ? 'Closed' : 'Open'}', style: TextStyle(fontSize: 16, color: _currentShift!.isShiftClosed! ? Colors.red : Colors.green)),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildShiftActivityButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  if (_availableCurrencies.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No currencies available. Please configure currencies.')),
                    );
                    return;
                  }
                  _showCashActivityDialog('Cash In');
                },
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Cash In'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade400,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  if (_availableCurrencies.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No currencies available. Please configure currencies.')),
                    );
                    return;
                  }
                  _showCashActivityDialog('Cash Out');
                },
                icon: const Icon(Icons.remove_circle_outline),
                label: const Text('Cash Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade400,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildShiftSummary() {
    if (_currentShift == null || (_currentShift?.isShiftClosed ?? true)) {
      return const SizedBox.shrink();
    }

    Map<String, Map<String, double>> currencyTotals = {};
    Map<String, Map<String, double>> paymentTypeBreakdown = {};

    _currentShift!.shiftCurrencyAmounts?.forEach((activity) {
      if (activity.currency.id != null) {
        currencyTotals.putIfAbsent(activity.currency.id!, () => {
          'CASH_IN': 0.0,
          'CASH_OUT': 0.0,
          'CASH_PAYMENT': 0.0,
          'OTHER_PAYMENT': 0.0,
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

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Shift Summary',
                  style: AppTheme.title.copyWith(fontSize: 18),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.receipt),
                      onPressed: _previewShiftSummary,
                      tooltip: 'Preview Shift Summary',
                    ),
                    IconButton(
                      icon: const Icon(Icons.print),
                      onPressed: _printShiftSummary,
                      tooltip: 'Print Shift Summary',
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            if (currencyTotals.isEmpty)
              const Text('No monetary activities recorded yet.')
            else
              ...currencyTotals.entries.map((entry) {
                final currencyId = entry.key;
                final totals = entry.value;
                final currency = _availableCurrencies.firstWhere((c) => c.id == currencyId);

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
                        '${currency.name} (${currency.symbol})',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      _buildSummaryRow('Initial Cash:', '${currency.symbol} 0.00'),
                      _buildSummaryRow('Total Cash In:', '${currency.symbol} ${cashInTotal.toStringAsFixed(2)}', color: Colors.green),
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
            const SizedBox(height: 10),
            Text(
              'Activities:',
              style: AppTheme.subtitle.copyWith(fontSize: 16),
            ),
            if (_currentShift!.shiftCurrencyAmounts == null || _currentShift!.shiftCurrencyAmounts!.isEmpty)
              const Text('No activities recorded yet.')
            else
              ..._currentShift!.shiftCurrencyAmounts!.map((activity) {
                String activityLabel;
                Color activityColor;
                if (activity.amountType == 'CASH_IN') {
                  activityLabel = 'Cash In';
                  activityColor = Colors.green;
                } else if (activity.amountType == 'CASH_OUT') {
                  activityLabel = 'Cash Out';
                  activityColor = Colors.red;
                } else if (activity.amountType == 'SALE') {
                  activityLabel = activity.isCash == true ? 'Cash Sale' : 'Other Sale';
                  activityColor = AppTheme.vimbikaBlue;
                } else {
                  activityLabel = activity.amountType;
                  activityColor = Colors.black;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          '$activityLabel: ${activity.notes ?? ''}',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${activity.amountType == 'CASH_OUT' ? '-' : ''}${activity.currency.symbol} ${activity.amount.toStringAsFixed(2)}',
                        style: TextStyle(color: activityColor),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildPastShiftsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Past Shifts',
              style: AppTheme.title.copyWith(fontSize: 18),
            ),
            const Divider(),
            const Text('No past shifts to display yet.'),
          ],
        ),
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