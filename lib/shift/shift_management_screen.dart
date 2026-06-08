import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:vimbika_pro/login/login_screen.dart';
import 'package:vimbika_pro/services/sale_sync_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart'; // Import for DateFormat
import '../app_constants/app_constants.dart';
import '../model/mobile_pos_shift.dart';
import '../model/mobile_shift_currency_amount.dart';
import '../model/currency.dart';
import '../model/user.dart';
import '../services/mobile_shift_service.dart';
import '../model/base_name_model.dart'; // Import BaseNameModel
import 'shift_summary_preview_screen.dart'; // Import the new preview screen
import '../services/printer_service.dart'; // Import PrinterService
import 'shift_data_screen.dart'; // Import ShiftDataScreen
import '../services/excel_export_service.dart';
import 'shift_excel_preview_screen.dart';

class ShiftManagementScreen extends StatefulWidget {
  const ShiftManagementScreen({super.key}); // Use super.key

  @override
  State<ShiftManagementScreen> createState() => _ShiftManagementScreenState(); // Explicitly define return type
}

class _ShiftManagementScreenState extends State<ShiftManagementScreen> {
  MobilePosShift? _currentShift;
  List<MobilePosShift> _pastShifts = [];
  bool _isLoading = true;
  User? _currentUser;
  List<Currency> _availableCurrencies = [];
  Currency? _selectedCurrency; // This will be the default selected currency for the dialog
  bool _isOfflineMode = false; // Added for offline/online mode
  bool _isActivitiesExpanded = false; // Added to control the expansion of the activities section

  final MobilePosShiftService _shiftService = MobilePosShiftService();
  final SaleSyncService _saleSyncService = SaleSyncService();
  final PrinterService _printerService = PrinterService(); // Instantiate PrinterService
  final ExcelExportService _excelExportService = ExcelExportService();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return; // Added check
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

    // Load past shifts
    await _loadPastShifts();

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadPastShifts() async {
    if (_currentUser?.id == null) return;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? cachedPastShiftsJson = prefs.getString(AppConstants.keyCachedPastShifts);

    if (cachedPastShiftsJson != null && cachedPastShiftsJson.isNotEmpty) {
      try {
        final List<dynamic> jsonList = jsonDecode(cachedPastShiftsJson);
        final List<MobilePosShift> cachedShifts = jsonList
            .map((json) {
              if (json is String) {
                return MobilePosShift.fromRawJson(json);
              }
              return MobilePosShift.fromJson(json);
            })
            .toList();
        if (!mounted) return; // Added check
        if (mounted) {
          setState(() {
            _pastShifts = cachedShifts.where((s) => s.isShiftClosed == true).toList();
          });
        }
        // If cached data is available and valid, use it and return.
        return;
      } catch (e) {
        print('Error parsing cached past shifts JSON: $e');
        await prefs.remove(AppConstants.keyCachedPastShifts); // Clear malformed cache
        // If cache was malformed, proceed to fetch from network if not in offline mode.
      }
    }
    // Fetch from API if not in offline mode AND cache was empty or malformed
    if (!_isOfflineMode) {
      try {
        final shifts = await _shiftService.getShiftsByUserId(_currentUser!.id!);
        if (!mounted) return; // Added check
        if (mounted) {
          setState(() {
            _pastShifts = shifts.where((s) => s.isShiftClosed == true).toList();
          });
        }
        // Cache the fetched shifts
        final List<Map<String, dynamic>> shiftsJsonList = _pastShifts.map((shift) => shift.toMap()).toList();
        await prefs.setString(AppConstants.keyCachedPastShifts, jsonEncode(shiftsJsonList));
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load past shifts from network: $e')),
          );
        }
      }
    }
  }

  Future<void> _openShift() async {
    if (_currentUser == null || _currentUser!.branch?.company == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User or company information not available. Cannot open shift.')),
      );
      return;
    }

    if (!mounted) return; // Added check
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
        active: true
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
    if (!mounted) return; // Added check
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

  Future<void> _viewSavedShiftExcel() async {
    if (!mounted) return; // Added check
    setState(() {
      _isLoading = true;
    });
    try {
      final amounts = await _excelExportService.importShiftCurrencyAmountsFromExcel();
      if (amounts.isNotEmpty) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShiftExcelPreviewScreen(
              amounts: amounts,
              fileName: "Imported Shift Excel",
            ),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No shift data imported or operation cancelled.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error importing Excel: $e')),
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
    if (!mounted) return; // Added check
    setState(() {
      _isLoading = true;
    });
    try {
      // Clear user preferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.keyUserData);
      await prefs.setBool(AppConstants.keyHasUser, false);
      await prefs.setBool(AppConstants.keyIsOfflineMode, true); // Default to offline mode on logout
      await prefs.remove(AppConstants.keyCachedPastShifts); // Clear cached past shifts on logout

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

    if (!mounted) return; // Added check
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
        isCash: true,
        ref: 'SL_${DateTime.now().millisecondsSinceEpoch}',
        posReference:type == 'Cash In' ? 'CASH_IN${DateTime.now().millisecondsSinceEpoch}' : 'CASH_OUT${DateTime.now().millisecondsSinceEpoch}',
        paymentType: 'CASH-${selectedCurrency.name}'

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
    if (!mounted) return; // Added check
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
      if (!mounted) return; // Added check
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shift summary sent to printer.')),
      );
    } catch (e) {
      if (!mounted) return; // Added check
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
      if (!mounted) return; // Added check
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Full shift report sent to printer.')),
      );
    } catch (e) {
      if (!mounted) return; // Added check
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
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            onPressed: _viewSavedShiftExcel,
            tooltip: 'View Saved Shift Excel',
          ),
        ],
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
                              label: const Text('Close Shift & Log Out'),
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
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _closeShift,
                                    icon: const Icon(Icons.stop),
                                    label: const Text('Close Current Shift'),
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(50),
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _logout,
                                    icon: const Icon(Icons.logout),
                                    label: const Text('Close Shift & Log Out'),
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(50),
                                      backgroundColor: AppTheme.vimbikaBlue,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
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

    final sortedActivities = _currentShift!.shiftCurrencyAmounts != null
        ? List<MobileShiftCurrencyAmount>.from(_currentShift!.shiftCurrencyAmounts!)
        : <MobileShiftCurrencyAmount>[];

    sortedActivities.sort((a, b) {
      if (a.timeCreated == null || b.timeCreated == null) return 0;
      try {
        // Sort in descending order (latest on top)
        return DateTime.parse(b.timeCreated!).compareTo(DateTime.parse(a.timeCreated!));
      } catch (e) {
        return 0;
      }
    });

    for (var activity in sortedActivities) {
      print(activity.toJson());
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
                final currency = _availableCurrencies.firstWhere(
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
            const SizedBox(height: 10),
            ExpansionTile(
              title: Text(
                'Activities',
                style: AppTheme.subtitle.copyWith(fontSize: 16),
              ),
              initiallyExpanded: _isActivitiesExpanded,
              onExpansionChanged: (bool expanded) {
                if (!mounted) return; // Added check
                setState(() {
                  _isActivitiesExpanded = expanded;
                });
              },
              children: [
                if (sortedActivities.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('No activities recorded yet.'),
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
                                child: Text(
                                  '$activityLabel: ${activity.notes ?? ''}',
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
            if (_pastShifts.isEmpty)
              const Text('No past shifts to display yet.')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _pastShifts.length,
                itemBuilder: (context, index) {
                  final shift = _pastShifts[index];
                  return ListTile(
                    title: Text(shift.shiftReference ?? 'N/A'),
                    subtitle: Text('Closed: ${shift.closingTime ?? 'N/A'}'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      if (!mounted) return; // Added check
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ShiftDataScreen(
                            shift: shift,
                            availableCurrencies: _availableCurrencies, // Pass availableCurrencies here
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
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