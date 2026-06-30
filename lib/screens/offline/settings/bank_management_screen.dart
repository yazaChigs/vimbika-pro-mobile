import 'package:vimbika_pro/app_constants/app_constants.dart';
import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:vimbika_pro/model/user.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../model/bank.dart';
import '../../../model/currency.dart';
import '../../../services/bank_service.dart'; // Import BankService
import '../../../services/currency_service.dart'; // Import CurrencyService

class BankManagementScreen extends StatefulWidget {
  const BankManagementScreen({super.key});

  @override
  State<BankManagementScreen> createState() => _BankManagementScreenState();
}

class _BankManagementScreenState extends State<BankManagementScreen> {
  List<Bank> _banks = [];
  List<Currency> _availableCurrencies = [];
  bool _isLoading = true;
  bool _isOfflineMode = false; // Track offline mode status
  bool _canEdit = true;

  final BankService _bankService = BankService(); // Initialize BankService
  final CurrencyService _currencyService = CurrencyService(); // Initialize CurrencyService

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _isOfflineMode = prefs.getBool(AppConstants.keyIsOfflineMode) ?? false; // Get offline mode status
    
    bool canEdit = true;
    if (!_isOfflineMode) {
      final String? userDataJson = prefs.getString(AppConstants.keyOnlineUserData);
      if (userDataJson != null) {
        final user = User.fromJson(jsonDecode(userDataJson));
        canEdit = user.userRoles?.any((role) => role.name == 'ROLE_SUPER_ADMIN') ?? false;
      } else {
        canEdit = false;
      }
    }

    // Determine which key to use based on offline mode
    final String bankKey = _isOfflineMode ? AppConstants.keyOfflineBanks : AppConstants.keyBanks;
    final String currencyKey = _isOfflineMode ? AppConstants.keyOfflineCurrencies : AppConstants.keyCurrencies;

    // Load Banks
    final List<String> bankListJson = prefs.getStringList(bankKey) ?? [];
    
    // Load Currencies for dropdown
    final List<String> currencyListJson = prefs.getStringList(currencyKey) ?? [];
    
    setState(() {
      _banks = bankListJson
          .map((item) => Bank.fromJson(jsonDecode(item)))
          .where((bank) => bank.isSystemCreated != true) // Filter out system created banks
          .toList();
      _availableCurrencies = currencyListJson
          .map((item) {
            try {
              return Currency.fromJson(jsonDecode(item));
            } catch (e) {
              // Handle potential double encoding or malformed JSON
              return Currency.fromJson(jsonDecode(jsonDecode(item)));
            }
          })
          .toList();
      _isLoading = false;
      _canEdit = canEdit;
    });
  }

  Future<void> _saveBanks() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Determine which key to use based on offline mode
    final String bankKey = _isOfflineMode ? AppConstants.keyOfflineBanks : AppConstants.keyBanks;

    // We must read existing to not overwrite system created ones
    final List<String> existingBankListJson = prefs.getStringList(bankKey) ?? [];
    final List<Bank> allExistingBanks = existingBankListJson.map((item) => Bank.fromJson(jsonDecode(item))).toList();
    
    final List<Bank> systemCreatedBanks = allExistingBanks.where((bank) => bank.isSystemCreated == true).toList();
    
    // Combine newly edited banks with system ones
    final List<Bank> allBanksToSave = [..._banks, ...systemCreatedBanks];

    final List<String> listJson = allBanksToSave
        .map((item) => jsonEncode(item.toJson()))
        .toList();
    await prefs.setStringList(bankKey, listJson);
  }

  Future<void> _syncBanks() async {
    if (_isOfflineMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot sync banks in offline mode.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _currencyService.fetchCurrencies(); // Ensure currencies are up-to-date
      await _bankService.fetchBanks(); // Fetch from API and save to SharedPreferences
      await _loadData(); // Reload from SharedPreferences
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Banks synced from API')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sync banks: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showBankDialog({Bank? bank}) {
    if (!_canEdit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You do not have permission to edit banks.')),
      );
      return;
    }

    if (bank != null && bank.isSystemCreated == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot edit system-created banks.')),
      );
      return;
    }

    final nameController = TextEditingController(text: bank?.name);
    final accountController = TextEditingController(text: bank?.accountNumber);
    final branchController = TextEditingController(text: bank?.branch);
    final descriptionController = TextEditingController(text: bank?.description);
    Currency? selectedCurrency = bank?.currency.value;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(bank == null ? 'Add Bank Account' : 'Edit Bank Account'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: InputDecoration(labelText: 'Bank Name (e.g. Equity Bank)')),
                TextField(controller: accountController, decoration: InputDecoration(labelText: 'Account Number')),
                TextField(controller: branchController, decoration: InputDecoration(labelText: 'Branch')),
                const SizedBox(height: 16),
                DropdownButtonFormField<Currency>(
                  decoration: InputDecoration(labelText: 'Currency'),
                  initialValue: selectedCurrency != null && _availableCurrencies.any((c) => c.id == selectedCurrency!.id)
                      ? _availableCurrencies.firstWhere((c) => c.id == selectedCurrency!.id)
                      : null,
                  items: _availableCurrencies.map((currency) {
                    return DropdownMenuItem(
                      value: currency,
                      child: Text('${currency.name} (${currency.symbol})'),
                    );
                  }).toList(),
                  onChanged: (Currency? newValue) {
                    setState(() {
                      selectedCurrency = newValue;
                    });
                  },
                ),
                TextField(controller: descriptionController, decoration: InputDecoration(labelText: 'Description (Optional)')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
            ElevatedButton(
              onPressed: () {
              if (nameController.text.isEmpty) return;

              // If editing, use existing bank values as base
              final newBank = bank != null ? Bank(
                id: bank.id,
                name: nameController.text,
                accountNumber: accountController.text,
                branch: branchController.text,
                description: descriptionController.text,
                currency: selectedCurrency ?? _availableCurrencies.cast<Currency?>().firstWhere((c) => c?.isBaseCurrency == true, orElse: () => null),
                isSystemCreated: bank.isSystemCreated,
                dateCreated: bank.dateCreated,
                dateModified: bank.dateModified,
                createdByName: bank.createdByName,
                modifiedByName: bank.modifiedByName,
                version: bank.version,
              ) : Bank(
                id: null,
                name: nameController.text,
                accountNumber: accountController.text,
                branch: branchController.text,
                description: descriptionController.text,
                currency: selectedCurrency ?? _availableCurrencies.cast<Currency?>().firstWhere((c) => c?.isBaseCurrency == true, orElse: () => null),
              );

              this.setState(() {
                  if (bank == null) {
                    _banks.add(newBank);
                  } else {
                    final index = _banks.indexWhere((b) => b.id == bank.id);
                    _banks[index] = newBank;
                  }
                });
                _saveBanks();
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteBank(Bank bank) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Bank'),
        content: Text('Are you sure you want to delete ${bank.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _banks.removeWhere((b) => b.id == bank.id);
              });
              _saveBanks();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete', style: TextStyle(color: Colors.white)),
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
        title: Text('Manage Banks', style: AppTheme.title),
        backgroundColor: AppTheme.white,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.nearlyBlack),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: (_isLoading || _isOfflineMode) ? null : _syncBanks, // Allow all users to sync in online mode
            tooltip: 'Sync Banks',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _banks.isEmpty
              ? Center(child: Text('No bank accounts added yet.'))
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _banks.length,
                  itemBuilder: (context, index) {
                    final bank = _banks[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.vimbikaBlue.withValues(alpha: 0.1),
                          child: Icon(Icons.account_balance, color: AppTheme.vimbikaBlue),
                        ),
                        title: Text(bank.name, style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${bank.accountNumber ?? 'No Account #'} - ${bank.currency.value?.name ?? ''}'),
                        trailing: _canEdit ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: AppTheme.grey),
                              onPressed: () => _showBankDialog(bank: bank),
                            ),
                            if (bank.isSystemCreated != true)
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red.withValues(alpha: 0.7)),
                                onPressed: () => _deleteBank(bank),
                              ),
                          ],
                        ) : null,
                      ),
                    );
                  },
                ),
      floatingActionButton: _canEdit ? FloatingActionButton(
        onPressed: () => _showBankDialog(),
        backgroundColor: AppTheme.vimbikaBlue,
        child: Icon(Icons.add),
      ) : null,
    );
  }
}
