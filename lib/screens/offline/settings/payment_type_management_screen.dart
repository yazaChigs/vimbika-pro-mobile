import 'package:uuid/uuid.dart';
import 'package:vimbika_pro/app_constants/app_constants.dart';
import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:vimbika_pro/model/user.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../model/payment_type.dart';
import '../../../model/currency.dart';
import '../../../model/bank.dart';
import '../../../services/payments_service.dart'; // Import PaymentService
import '../../../services/currency_service.dart'; // Import CurrencyService

class PaymentTypeManagementScreen extends StatefulWidget {
  const PaymentTypeManagementScreen({super.key});

  @override
  State<PaymentTypeManagementScreen> createState() => _PaymentTypeManagementScreenState();
}

class _PaymentTypeManagementScreenState extends State<PaymentTypeManagementScreen> {
  List<PaymentType> _paymentTypes = [];
  List<Currency> _currencies = [];
  List<Bank> _banks = [];
  Currency? _selectedFilterCurrency;
  bool _isLoading = true;
  bool _isOfflineMode = false; // New state variable
  bool _canEdit = true;
  final Uuid _uuid = const Uuid(); // Initialize Uuid

  final PaymentsService _paymentsService = PaymentsService(); // Initialize PaymentService
  final CurrencyService _currencyService = CurrencyService(); // Initialize CurrencyService

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _isOfflineMode = prefs.getBool(AppConstants.keyIsOfflineMode) ?? false; // Set offline mode state

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
    
    setState(() {
      _canEdit = canEdit;
    });

    await _loadCurrencies();
    await _loadBanks();
    await _loadPaymentTypes();
  }

  Future<void> _loadBanks() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String bankKey = _isOfflineMode ? AppConstants.keyOfflineBanks : AppConstants.keyBanks;
    final List<String> bankJsonStrings = prefs.getStringList(bankKey) ?? [];

    setState(() {
      _banks = bankJsonStrings
          .map((jsonString) {
            try {
              return Bank.fromJson(jsonDecode(jsonString));
            } catch (e) {
              debugPrint('Error decoding bank: $e');
              return null;
            }
          })
          .whereType<Bank>()
          .toList();
    });
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch from API using services
      await _currencyService.fetchCurrencies();
      // Also fetch banks if possible (assume PaymentsService or similar has it, or just use BankService if it exists)
      // For now let's just refresh what we have.
      
      await _paymentsService.fetchPaymentTypes();

      // Reload data from SharedPreferences (services handle saving)
      await _loadCurrencies();
      await _loadBanks();
      await _loadPaymentTypes();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data refreshed from API')),
        );
      }
    } catch (e) {
      debugPrint('Error refreshing data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to refresh data: $e')),
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

  Future<void> _loadCurrencies() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String currencyKey = _isOfflineMode ? AppConstants.keyOfflineCurrencies : AppConstants.keyCurrencies;
    final List<String> currencyJsonStrings = prefs.getStringList(currencyKey) ?? [];

    debugPrint('Attempting to load currencies. Found ${currencyJsonStrings.length} raw entries.');

    setState(() {
      _currencies = currencyJsonStrings
          .map((jsonString) {
            try {
              debugPrint('Processing currency string: $jsonString (Type: ${jsonString.runtimeType})');
              dynamic decodedData = jsonDecode(jsonString);

              // Check if it's a double-encoded string and decode again
              if (decodedData is String) {
                debugPrint('Detected double-encoded string. Attempting to decode again.');
                decodedData = jsonDecode(decodedData);
              }

              if (decodedData is! Map<String, dynamic>) {
                debugPrint('jsonDecode did not return a Map<String, dynamic> after one or two decodes. Actual type: ${decodedData.runtimeType}');
                return Currency(id: 'INVALID', name: 'Invalid Currency - Unexpected Decoded Type');
              }
              final Map<String, dynamic> jsonMap = decodedData;
              return Currency.fromJson(jsonMap);
            } catch (e) {
              debugPrint('Caught error during currency decoding: $e for string: $jsonString');
              return Currency(id: 'INVALID', name: 'Invalid Currency - Decoding Error');
            }
          })
          .where((currency) => currency.id != 'INVALID')
          .toList();
      debugPrint('Successfully loaded ${_currencies.length} valid currencies.');
    });
  }



  Future<void> _loadPaymentTypes() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String paymentTypeKey = _isOfflineMode ? AppConstants.keyOfflinePaymentTypes : AppConstants.keyPaymentTypes;
    final List<String> listJson = prefs.getStringList(paymentTypeKey) ?? [];

    setState(() {
      _paymentTypes = listJson
          .map((item) => PaymentType.fromJson(jsonDecode(item)))
          .where((pt) => pt.isSystemCreated != true) // Filter out system created payment types
          .toList();
      _isLoading = false;
    });
  }

  Future<void> _savePaymentTypes(List<PaymentType> paymentTypesToSave) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String paymentTypeKey = _isOfflineMode ? AppConstants.keyOfflinePaymentTypes : AppConstants.keyPaymentTypes;

    // We must read existing to not overwrite system created ones
    final List<String> existingListJson = prefs.getStringList(paymentTypeKey) ?? [];
    final List<PaymentType> allExisting = existingListJson.map((item) => PaymentType.fromJson(jsonDecode(item))).toList();
    
    final List<PaymentType> systemCreated = allExisting.where((pt) => pt.isSystemCreated == true).toList();
    
    // Combine newly edited with system ones
    final List<PaymentType> allToSave = [...paymentTypesToSave, ...systemCreated];

    final List<String> listJson = allToSave
        .map((item) => jsonEncode(item.toJson()))
        .toList();
    await prefs.setStringList(paymentTypeKey, listJson);
  }

  /// Get filtered payment types based on selected currency
  List<PaymentType> _getFilteredPaymentTypes() {
    if (_selectedFilterCurrency == null) {
      return _paymentTypes;
    }

    return _paymentTypes.where((pt) {
      // Show payment types that:
      // 1. Have no currency restriction (currency is null), OR
      // 2. Match the selected filter currency
      return pt.currency.value == null || pt.currency.value?.id == _selectedFilterCurrency!.id;
    }).toList();
  }

  void _showPaymentTypeDialog({PaymentType? paymentType}) {
    if (!_canEdit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You do not have permission to edit payment methods.')),
      );
      return;
    }

    final nameController = TextEditingController(text: paymentType?.name);
    final descriptionController = TextEditingController(text: paymentType?.description);
    bool isCash = paymentType?.isCash ?? false;
    bool isCard = paymentType?.isCard ?? false;
    bool isMobileMoney = paymentType?.isMobileMoney ?? false;
    bool isBankTransfer = paymentType?.isBankTransfer ?? false;
    bool active = paymentType?.active ?? true;
    Currency? selectedCurrency = paymentType?.currency.value;

    // Initialize selected banks from the paymentType
    List<Bank> selectedBanks = [];
    if (paymentType?.banks != null) {
      for (var bank in paymentType!.banks!) {
        final foundBank = _banks.firstWhere((b) => b.id == bank.id, orElse: () => bank);
        selectedBanks.add(foundBank);
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) {
          return AlertDialog(
            title: Text(paymentType == null ? 'Add Payment Method' : 'Edit Payment Method'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Payment Method Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Currency Selection Dropdown
                  DropdownButtonFormField<Currency?>(
                    initialValue: selectedCurrency,
                    decoration: const InputDecoration(
                      labelText: 'Currency (Optional)',
                      hintText: 'Select currency or leave empty for all',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<Currency?>(
                        value: null,
                        child: Text('All Currencies'),
                      ),
                      ..._currencies.map((currency) => DropdownMenuItem<Currency?>(
                        value: currency,
                        child: Text('${currency.name} (${currency.symbol})'),
                      )),
                    ],
                    onChanged: (Currency? value) {
                      setDialogState(() {
                        selectedCurrency = value;
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  Divider(),
                  SwitchListTile(
                    title: Text('Enabled', style: TextStyle(fontWeight: FontWeight.bold, color: active ? Colors.green : Colors.grey)),
                    subtitle: Text(active ? 'Method is active' : 'Method is disabled'),
                    value: active,
                    activeThumbColor: Colors.green,
                    onChanged: (bool value) {
                      setDialogState(() {
                        active = value;
                      });
                    },
                  ),
                  Divider(),
                  SizedBox(height: 8),
                  Text('Payment Method Types', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  SwitchListTile(
                    title: Text('Is Cash'),
                    value: isCash,
                    onChanged: (bool value) {
                      setDialogState(() {
                        isCash = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: Text('Is Card'),
                    value: isCard,
                    onChanged: (bool value) {
                      setDialogState(() {
                        isCard = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: Text('Is Mobile Money'),
                    value: isMobileMoney,
                    onChanged: (bool value) {
                      setDialogState(() {
                        isMobileMoney = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: Text('Is Bank Transfer'),
                    value: isBankTransfer,
                    onChanged: (bool value) {
                      setDialogState(() {
                        isBankTransfer = value;
                    });
                    },
                  ),
                  if (isBankTransfer) ...[
                    SizedBox(height: 8),
                    Text('Select Banks', style: TextStyle(fontWeight: FontWeight.bold)),
                    ..._banks.map((bank) {
                      final isSelected = selectedBanks.any((b) => b.id == bank.id);
                      return CheckboxListTile(
                        title: Text(bank.name),
                        subtitle: Text(bank.accountNumber ?? ''),
                        value: isSelected,
                        onChanged: (bool? value) {
                          setDialogState(() {
                            if (value == true) {
                              selectedBanks.add(bank);
                            } else {
                              selectedBanks.removeWhere((b) => b.id == bank.id);
                            }
                          });
                        },
                      );
                    }),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isEmpty) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Payment method name is required')),
                      );
                    }
                    return;
                  }

                  // If editing, use copyWith to preserve existing metadata
                  final newPaymentType = paymentType != null
                      ? paymentType.copyWith(
                          name: nameController.text,
                          description: descriptionController.text.isNotEmpty ? descriptionController.text : null,
                          isCash: isCash,
                          isCard: isCard,
                          isMobileMoney: isMobileMoney,
                          isBankTransfer: isBankTransfer,
                          currency: selectedCurrency ?? _currencies.cast<Currency?>().firstWhere((c) => c?.isBaseCurrency == true, orElse: () => null),
                          active: active,
                          banks: isBankTransfer ? selectedBanks : null,
                        )
                      : PaymentType(
                          id: _uuid.v4(),
                          name: nameController.text,
                          description: descriptionController.text.isNotEmpty ? descriptionController.text : null,
                          isCash: isCash,
                          isCard: isCard,
                          isMobileMoney: isMobileMoney,
                          isBankTransfer: isBankTransfer,
                          currency: selectedCurrency ?? _currencies.cast<Currency?>().firstWhere((c) => c?.isBaseCurrency == true, orElse: () => null),
                          active: active,
                          banks: isBankTransfer ? selectedBanks : null,
                        );

                  setState(() {
                    if (paymentType == null) {
                      _paymentTypes.add(newPaymentType);
                    } else {
                      final index = _paymentTypes.indexWhere((pt) => pt.id == paymentType.id);
                      if (index != -1) {
                        _paymentTypes[index] = newPaymentType;
                      }
                    }
                  });
                  await _savePaymentTypes(_paymentTypes); // Use the new _savePaymentTypes
                  if (context.mounted) {
                    Navigator.pop(context);

                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(paymentType == null ? 'Payment method added' : 'Payment method updated')),
                    );
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deletePaymentType(PaymentType paymentType) {
    if (!_canEdit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You do not have permission to delete payment methods.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Payment Method?'),
        content: Text('Are you sure you want to delete "${paymentType.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              setState(() {
                _paymentTypes.removeWhere((pt) => pt.id == paymentType.id);
              });
              await _savePaymentTypes(_paymentTypes); // Use the new _savePaymentTypes
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Payment method deleted')),
                );
              }
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
    final filteredPaymentTypes = _getFilteredPaymentTypes();

    debugPrint('Number of currencies available for filter: ${_currencies.length}');
    debugPrint('Currency filter dropdown will be shown: ${_currencies.isNotEmpty}');

    return Scaffold(
      backgroundColor: AppTheme.nearlyWhite,
      appBar: AppBar(
        title: Text('Manage Payment Methods', style: AppTheme.title),
        backgroundColor: AppTheme.white,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.nearlyBlack),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: (_isLoading || _isOfflineMode) ? null : _refreshData, // Allow all users to refresh in online mode
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Currency Filter Dropdown
          if (_currencies.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              color: AppTheme.white,
              child: DropdownButtonFormField<Currency?>(
                initialValue: _selectedFilterCurrency,
                decoration: const InputDecoration(
                  labelText: 'Filter by Currency',
                  hintText: 'Select currency to filter',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.filter_list),
                ),
                items: [
                  const DropdownMenuItem<Currency?>(
                    value: null,
                    child: Text('All Payment Methods'),
                  ),
                  ..._currencies.map((currency) => DropdownMenuItem<Currency?>(
                    value: currency,
                    child: Text('${currency.name} (${currency.symbol})'),
                  )),
                ],
                onChanged: (Currency? value) {
                  setState(() {
                    _selectedFilterCurrency = value;
                  });
                },
              ),
            ),
          // Payment Types List
          Expanded(
            child: filteredPaymentTypes.isEmpty
                ? Center(
              child: Text(
                _selectedFilterCurrency == null
                    ? 'No payment methods added yet.'
                    : 'No payment methods found for ${_selectedFilterCurrency!.name}',
              ),
            )
                : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: filteredPaymentTypes.length,
              itemBuilder: (context, index) {
                final paymentType = filteredPaymentTypes[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: paymentType.active 
                        ? AppTheme.vimbikaBlue.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                      child: Icon(_getPaymentTypeIcon(paymentType), 
                        color: paymentType.active ? AppTheme.vimbikaBlue : Colors.grey),
                    ),
                    title: Row(
                      children: [
                        Text(
                          paymentType.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: paymentType.active ? null : TextDecoration.lineThrough,
                            color: paymentType.active ? Colors.black : Colors.grey,
                          ),
                        ),
                        if (!paymentType.active)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('Disabled', style: TextStyle(fontSize: 10, color: Colors.black54)),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(paymentType.description ?? _getPaymentTypeDescription(paymentType)),
                        if (paymentType.currency.value != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Chip(
                              label: Text(
                                '${paymentType.currency.value!.symbol} ${paymentType.currency.value!.name}',
                                style: const TextStyle(fontSize: 11),
                              ),
                              backgroundColor: AppTheme.vimbikaBlue.withValues(alpha: 0.2),
                            ),
                          ),
                        if (paymentType.isBankTransfer && paymentType.banks != null && paymentType.banks!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Wrap(
                              spacing: 4,
                              children: paymentType.banks!.map((bank) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                                ),
                                child: Text(bank.name, style: const TextStyle(fontSize: 10, color: Colors.green)),
                              )).toList(),
                            ),
                          ),
                      ],
                    ),
                    trailing: _canEdit ? PopupMenuButton<String>(
                      onSelected: (String result) {
                        if (result == 'edit') {
                          _showPaymentTypeDialog(paymentType: paymentType);
                        } else if (result == 'delete') {
                          _deletePaymentType(paymentType);
                        }
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit),
                            title: Text('Edit'),
                            dense: true,
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete, color: Colors.red),
                            title: Text('Delete', style: TextStyle(color: Colors.red)),
                            dense: true,
                          ),
                        ),
                      ],
                    ) : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _canEdit ? FloatingActionButton(
        onPressed: () => _showPaymentTypeDialog(),
        backgroundColor: AppTheme.vimbikaBlue,
        child: Icon(Icons.add),
      ) : null,
    );
  }

  IconData _getPaymentTypeIcon(PaymentType type) {
    if (type.isCash) return Icons.money;
    if (type.isCard) return Icons.credit_card;
    if (type.isMobileMoney) return Icons.phone_android;
    if (type.isBankTransfer) return Icons.account_balance;
    return Icons.payment;
  }

  String _getPaymentTypeDescription(PaymentType type) {
    List<String> types = [];
    if (type.isCash) types.add('Cash');
    if (type.isCard) types.add('Card');
    if (type.isMobileMoney) types.add('Mobile Money');
    if (type.isBankTransfer) types.add('Bank Transfer');
    return types.isNotEmpty ? types.join(', ') : 'No payment method selected';
  }
}
