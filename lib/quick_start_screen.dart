import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:vimbika_pro/app_constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'model/currency.dart';
import 'model/tax.dart';
import 'model/payment_type.dart';
import 'model/branch.dart';
import 'model/bank.dart';
import 'login/login_screen.dart';

class QuickStartScreen extends StatefulWidget {
  final String savedUsername;
  final String? savedPassword;
  
  const QuickStartScreen({super.key, required this.savedUsername, this.savedPassword});

  @override
  State<QuickStartScreen> createState() => _QuickStartScreenState();
}

class _QuickStartScreenState extends State<QuickStartScreen> {
  bool _isLoading = false;

  // State variables for the quick start configuration
  bool _chargeTax = true;
  String? _selectedDefaultTaxId;
  List<Tax> _availableTaxes = [];
  
  String? _selectedBaseCurrencyId;
  List<Currency> _availableCurrencies = [];

  List<PaymentType> _paymentTypes = [];
  List<Bank> _banks = [];
  List<PaymentType> _displayPaymentTypes = [];
  List<Bank> _DisplayBanks = [];

  Branch? _defaultBranch;

  // New state variable for "sell nil items"
  // New state variable for "allow out of stock sales"
  bool _allowOutOfStockSales = false;

  @override
  void initState() {
    super.initState();
    _loadDefaults();
  }

  Future<void> _loadDefaults() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // 1. Load default branch
    final String? branchJson = prefs.getString(AppConstants.keyOfflineBranch);
    if (branchJson != null) {
      _defaultBranch = Branch.fromJson(jsonDecode(branchJson));
    }

    // 2. Load taxes
    final List<String> taxJson = prefs.getStringList(AppConstants.keyOfflineTaxes) ?? [];
    if (taxJson.isNotEmpty) {
      _availableTaxes = taxJson.map((e) => Tax.fromJson(jsonDecode(e))).toList();
      _selectedDefaultTaxId = _availableTaxes.isNotEmpty ? _availableTaxes.first.id : null;
    }

    // 3. Load Currencies
    final List<String> currencyJson = prefs.getStringList(AppConstants.keyOfflineCurrencies) ?? [];
    if (currencyJson.isNotEmpty) {
      _availableCurrencies = currencyJson.map((e) => Currency.fromJson(jsonDecode(e))).toList();
      try {
        _selectedBaseCurrencyId = _availableCurrencies.firstWhere((c) => c.isBaseCurrency == true).id;
      } catch (e) {
        _selectedBaseCurrencyId = _availableCurrencies.isNotEmpty ? _availableCurrencies.first.id : null;
      }
    }

    // 4. Load Payment Types - Do not clear existing ones
    final List<String> paymentTypeJson = prefs.getStringList(AppConstants.keyOfflinePaymentTypes) ?? [];
    if (paymentTypeJson.isNotEmpty) {
      _paymentTypes = paymentTypeJson.map((e) => PaymentType.fromJson(jsonDecode(e))).toList();
      _displayPaymentTypes = _paymentTypes.where((c)=>!c.isSystemCreated!).toList();
    } else {
      _paymentTypes = []; // Initialize as empty if no saved data
    }

    // 5. Load Banks - Do not clear existing ones
    final List<String> bankJson = prefs.getStringList(AppConstants.keyOfflineBanks) ?? [];
    if (bankJson.isNotEmpty) {
      _banks = bankJson.map((e) => Bank.fromJson(jsonDecode(e))).toList();
      _DisplayBanks = _banks.where((c)=>!c.isSystemCreated!).toList();
    } else {
      _banks = []; // Initialize as empty if no saved data
    }

    // 6. Load allow out of stock sales setting
    _allowOutOfStockSales = prefs.getBool(AppConstants.keyAllowOutOfStockSales) ?? false;

    setState(() {});
  }

  Future<void> _saveConfigAndContinue() async {
    setState(() => _isLoading = true);

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // Save Tax Settings
      await prefs.setBool(AppConstants.keyIsPriceInclusiveTax, _chargeTax);
      // NOTE: If you have a specific key for default tax, save it here.
      if (_chargeTax && _selectedDefaultTaxId != null) {
          // If needed, save default tax ID
      }

      // Update base currency based on selection
      if (_selectedBaseCurrencyId != null) {
        final updatedCurrencies = _availableCurrencies.map((c) {
          return c.copyWith(isBaseCurrency: c.id == _selectedBaseCurrencyId);
        }).toList();
        await prefs.setStringList(
          AppConstants.keyOfflineCurrencies, 
          updatedCurrencies.map((c) => jsonEncode(c.toJson())).toList()
        );
      }

      // Save taxes
      await prefs.setStringList(
        AppConstants.keyOfflineTaxes,
        _availableTaxes.map((t) => jsonEncode(t.toJson())).toList()
      );

      // Save updated payment types (active/inactive status)
      await prefs.setStringList(
        AppConstants.keyOfflinePaymentTypes, 
        _paymentTypes.map((pt) => jsonEncode(pt.toJson())).toList()
      );

      // Save banks
      await prefs.setStringList(
        AppConstants.keyOfflineBanks,
        _banks.map((b) => jsonEncode(b.toJson())).toList()
      );

      // Save allow out of stock sales setting
      await prefs.setBool(AppConstants.keyAllowOutOfStockSales, _allowOutOfStockSales);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LoginScreen(
              initialUsername: widget.savedUsername,
              initialPassword: widget.savedPassword,
            ),
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving configuration: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _addNewCurrency() {
    String name = '';
    String symbol = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Currency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Currency Name (e.g. USD)'),
              onChanged: (val) => name = val,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Symbol (e.g. \$)'),
              onChanged: (val) => symbol = val,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (name.isNotEmpty && symbol.isNotEmpty) {
                final newCurrency = Currency(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  symbol: symbol,
                  isBaseCurrency: _availableCurrencies.isEmpty,
                );
                setState(() {
                  _availableCurrencies.add(newCurrency);
                  if (_availableCurrencies.length == 1) {
                    _selectedBaseCurrencyId = newCurrency.id;
                  }
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addNewTax() {
    String name = '';
    double percentage = 0.0;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Tax'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Tax Name (e.g. VAT)'),
              onChanged: (val) => name = val,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Percentage (e.g. 15)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (val) => percentage = double.tryParse(val) ?? 0.0,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (name.isNotEmpty) {
                final newTax = Tax(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  taxPercentage: percentage,
                );
                setState(() {
                  _availableTaxes.add(newTax);
                  if (_availableTaxes.length == 1) {
                    _selectedDefaultTaxId = newTax.id;
                  }
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addNewPaymentType() {
    String name = '';
    String? selectedCurrencyId;
    String? selectedBankId; // Changed from List<String> to String?

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add Payment Method'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    decoration: const InputDecoration(labelText: 'Method Name (e.g. Cash)'),
                    onChanged: (val) => name = val,
                  ),
                  const SizedBox(height: 16),
                  const Text('Currency (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
                  if (_availableCurrencies.isNotEmpty)
                    DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text('Select Currency'),
                      value: selectedCurrencyId,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Any Currency')),
                        ..._availableCurrencies.map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text('${c.name} (${c.symbol})'),
                        )),
                      ],
                      onChanged: (val) => setDialogState(() => selectedCurrencyId = val),
                    ),
                  if (_availableCurrencies.isEmpty)
                    const Text('No currencies available.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 16),
                  const Text('Associated Bank (Optional)', style: TextStyle(fontWeight: FontWeight.bold)), // Changed label
                  if (_DisplayBanks.isNotEmpty)
                    ..._DisplayBanks.map((bank) {
                      return RadioListTile<String>( // Changed to RadioListTile
                        title: Text(bank.name),
                        subtitle: Text(bank.accountNumber ?? ''),
                        value: bank.id??'', // Value is the bank's ID
                        groupValue: selectedBankId, // Group value is the currently selected bank ID
                        onChanged: (String? value) {
                          setDialogState(() {
                            selectedBankId = value; // Update selectedBankId
                          });
                        },
                      );
                    }),
                  if (_DisplayBanks.isEmpty)
                    const Text('No banks available.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (name.isNotEmpty) {
                    Currency? selectedCurrency;
                    if (selectedCurrencyId != null) {
                      selectedCurrency = _availableCurrencies.firstWhere((c) => c.id == selectedCurrencyId);
                    }
                    
                    List<Bank> selectedBanks = [];
                    if (selectedBankId != null) { // Check for single selectedBankId
                      final bank = _DisplayBanks.firstWhere((b) => b.id == selectedBankId);
                      selectedBanks.add(bank);
                    }

                    final newPaymentType = PaymentType(
                      id:null,
                      name: name,
                      active: true,
                      currency: selectedCurrency,
                      banks: selectedBanks.isNotEmpty ? selectedBanks : null,
                    );
                    setState(() {
                      _paymentTypes.add(newPaymentType);
                      _displayPaymentTypes.add(newPaymentType);
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        }
      ),
    );
  }

  void _addNewBank() {
    String name = '';
    String accountNumber = '';
    String branch = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Bank'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Bank Name'),
              onChanged: (val) => name = val,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Account Number'),
              onChanged: (val) => accountNumber = val,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Branch Name'),
              onChanged: (val) => branch = val,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (name.isNotEmpty) {
                final newBank = Bank(
                  id: null,
                  name: name,
                  accountNumber: accountNumber,
                  branch: branch,
                );
                setState(() {
                  _banks.add(newBank);
                  _DisplayBanks.add(newBank);
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.nearlyWhite,
      appBar: AppBar(
        title: const Text('Quick Setup', style: AppTheme.title),
        backgroundColor: AppTheme.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, // Prevent going back
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Let\'s verify some basic settings before you start.',
                    style: TextStyle(fontSize: 16, color: AppTheme.grey),
                  ),
                  const SizedBox(height: 24),
                  
                  // 1. Branch Info (Read Only)
                  const Text('Your Default Branch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 0,
                    color: AppTheme.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                    child: ListTile(
                      leading: const Icon(Icons.store, color: AppTheme.vimbikaBlue),
                      title: Text(_defaultBranch?.name ?? 'Main Branch'),
                      subtitle: Text(_defaultBranch?.address ?? 'No address provided'),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 2. Currency Setup
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Base Currency', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('Select the main currency for your reports and dashboard.', style: TextStyle(fontSize: 12, color: AppTheme.grey)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: AppTheme.vimbikaBlue),
                        onPressed: _addNewCurrency,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_availableCurrencies.isEmpty)
                    const Text('No currencies available. Please add one.', style: TextStyle(color: Colors.red)),
                  if (_availableCurrencies.isNotEmpty)
                    Card(
                      elevation: 0,
                      color: AppTheme.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedBaseCurrencyId,
                            items: _availableCurrencies.map((c) => DropdownMenuItem(
                              value: c.id,
                              child: Text('${c.name} (${c.symbol})'),
                            )).toList(),
                            onChanged: (val) => setState(() => _selectedBaseCurrencyId = val),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // 3. Tax Setup
                  const Text('Tax Configuration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 0,
                    color: AppTheme.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Do you charge tax?'),
                          activeThumbColor: AppTheme.vimbikaBlue,
                          value: _chargeTax,
                          onChanged: (val) => setState(() => _chargeTax = val),
                        ),
                        if (_chargeTax) ...[
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Default Tax Class', style: TextStyle(fontSize: 14)),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline, color: AppTheme.vimbikaBlue, size: 20),
                                      onPressed: _addNewTax,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (_availableTaxes.isEmpty)
                                  const Text('No taxes available. Please add one.', style: TextStyle(color: Colors.red)),
                                if (_availableTaxes.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        isExpanded: true,
                                        value: _selectedDefaultTaxId,
                                        items: _availableTaxes.map((t) => DropdownMenuItem(
                                          value: t.id,
                                          child: Text('${t.name} (${t.taxPercentage}%)'),
                                        )).toList(),
                                        onChanged: (val) => setState(() => _selectedDefaultTaxId = val),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 4. Allow Out of Stock Sales
                  const Text('Stock Management', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 0,
                    color: AppTheme.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                    child: SwitchListTile(
                      title: const Text('Allow Out of Stock Sales'),
                      subtitle: const Text('Enable to sell items even if their stock count is zero or negative.'),
                      activeThumbColor: AppTheme.vimbikaBlue,
                      value: _allowOutOfStockSales,
                      onChanged: (val) => setState(() => _allowOutOfStockSales = val),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 5. Banks
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Banks', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('Add banks for your transactions.', style: TextStyle(fontSize: 12, color: AppTheme.grey)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: AppTheme.vimbikaBlue),
                        onPressed: _addNewBank,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_DisplayBanks.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Would you like to add any banks?', style: TextStyle(color: AppTheme.grey, fontStyle: FontStyle.italic)),
                    ),
                  if (_DisplayBanks.isNotEmpty)
                    Card(
                      elevation: 0,
                      color: AppTheme.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                      child: Column(
                        children: List.generate(_DisplayBanks.length, (index) {
                          final bank = _DisplayBanks[index];
                          return Column(
                            children: [
                              if (index > 0) const Divider(height: 1),
                              ListTile(
                                leading: const Icon(Icons.account_balance, color: AppTheme.vimbikaBlue),
                                title: Text(bank.name),
                                subtitle: Text([bank.accountNumber, bank.branch].where((s) => s != null && s.isNotEmpty).join(' - ')),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // 6. Payment Types
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Payment Methods', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('Enable the payment methods you accept.', style: TextStyle(fontSize: 12, color: AppTheme.grey)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: AppTheme.vimbikaBlue),
                        onPressed: _addNewPaymentType,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_displayPaymentTypes.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Would you like to add any other payment methods?', style: TextStyle(color: AppTheme.grey, fontStyle: FontStyle.italic)),
                    ),
                  if (_displayPaymentTypes.isNotEmpty)
                    Card(
                      elevation: 0,
                      color: AppTheme.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                      child: Column(
                        children: List.generate(_displayPaymentTypes.length, (index) {
                          final pt = _displayPaymentTypes[index];
                          return Column(
                            children: [
                              if (index > 0) const Divider(height: 1),
                              CheckboxListTile(
                                title: Text(pt.name),
                                subtitle: pt.currency.value != null ? Text('For ${pt.currency.value!.name} only${pt.banks != null && pt.banks!.isNotEmpty ? ' (${pt.banks!.length} Banks)' : ''}') : (pt.banks != null && pt.banks!.isNotEmpty ? Text('${pt.banks!.length} Banks') : null),
                                value: pt.active,
                                // activeColor: AppTheme.vimbikaBlue, // remove deprecated warning again just in case
                                activeColor: AppTheme.vimbikaBlue,
                                onChanged: (val) {
                                  setState(() {
                                    _paymentTypes[index] = pt.copyWith(active: val ?? false);
                                  });
                                },
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveConfigAndContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.vimbikaBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save & Continue', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}