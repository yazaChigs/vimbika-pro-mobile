import 'package:vimbika_pro/app_constants/app_constants.dart';
import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:vimbika_pro/model/user.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../model/currency.dart';

import '../../../services/currency_service.dart'; // Import CurrencyService

class CurrencyManagementScreen extends StatefulWidget {
  @override
  _CurrencyManagementScreenState createState() => _CurrencyManagementScreenState();
}

class _CurrencyManagementScreenState extends State<CurrencyManagementScreen> {
  List<Currency> _currencies = [];
  bool _isLoading = true;
  bool _isOfflineMode = false; // Track offline mode status
  bool _canEdit = true;
  final CurrencyService _currencyService = CurrencyService(); // Initialize CurrencyService

  @override
  void initState() {
    super.initState();
    _loadCurrencies();
  }

  Future<void> _loadCurrencies() async {
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
    final String currencyKey = _isOfflineMode ? AppConstants.keyOfflineCurrencies : AppConstants.keyCurrencies;
    
    final List<String> currencyListJson = prefs.getStringList(currencyKey) ?? [];
    
    setState(() {
      _currencies = currencyListJson
          .map((item) => Currency.fromJson(jsonDecode(item)))
          .where((c) => c.isSystemCreated != true) // Filter out system created currencies
          .toList();
      _isLoading = false;
      _canEdit = canEdit;
    });
  }

  Future<void> _saveCurrencies() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Determine which key to use based on offline mode
    final String currencyKey = _isOfflineMode ? AppConstants.keyOfflineCurrencies : AppConstants.keyCurrencies;

    // We must read existing to not overwrite system created ones
    final List<String> existingCurrencyListJson = prefs.getStringList(currencyKey) ?? [];
    final List<Currency> allExistingCurrencies = existingCurrencyListJson.map((item) => Currency.fromJson(jsonDecode(item))).toList();
    
    final List<Currency> systemCreatedCurrencies = allExistingCurrencies.where((c) => c.isSystemCreated == true).toList();
    
    // Combine newly edited currencies with system ones
    final List<Currency> allCurrenciesToSave = [..._currencies, ...systemCreatedCurrencies];

    final List<String> currencyListJson = allCurrenciesToSave
        .map((item) => jsonEncode(item.toJson()))
        .toList();
    await prefs.setStringList(currencyKey, currencyListJson);
  }

  Future<void> _syncCurrencies() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _currencyService.fetchCurrencies(); // Fetch from API and save to SharedPreferences
      await _loadCurrencies(); // Reload from SharedPreferences
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Currencies synced from API')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sync currencies: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showCurrencyDialog({Currency? currency}) {
    if (!_canEdit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You do not have permission to edit currencies.')),
      );
      return;
    }

    final nameController = TextEditingController(text: currency?.name);
    final symbolController = TextEditingController(text: currency?.symbol);
    final rateController = TextEditingController(text: currency?.rate.toString() ?? '1.0');
    bool isBaseCurrency = currency?.isBaseCurrency ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(currency == null ? 'Add Currency' : 'Edit Currency'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: InputDecoration(labelText: 'Name (e.g. US Dollar)')),
                TextField(controller: symbolController, decoration: InputDecoration(labelText: 'Symbol (e.g. \$)')),
                TextField(
                  controller: rateController, 
                  decoration: InputDecoration(labelText: 'Exchange Rate'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                SwitchListTile(
                  title: Text('Base Currency'),
                  value: isBaseCurrency,
                  onChanged: (bool value) {
                    setState(() {
                      isBaseCurrency = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isEmpty) return;
                
                final newCurrency = Currency(
                  id: currency?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                  symbol: symbolController.text,
                  rate: double.tryParse(rateController.text) ?? 1.0,
                  isBaseCurrency: isBaseCurrency,
                  isSystemCreated: currency?.isSystemCreated ?? false,
                );

                this.setState(() {
                  // If this is set as base, unset others
                  if (isBaseCurrency) {
                    _currencies = _currencies.map((c) {
                      return Currency(
                        id: c.id,
                        name: c.name,
                        symbol: c.symbol,
                        rate: c.rate,
                        isBaseCurrency: false,
                        isSystemCreated: c.isSystemCreated,
                      );
                    }).toList();
                  }

                  if (currency == null) {
                    _currencies.add(newCurrency);
                  } else {
                    final index = _currencies.indexWhere((c) => c.id == currency.id);
                    _currencies[index] = newCurrency;
                  }
                });
                _saveCurrencies();
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.nearlyWhite,
      appBar: AppBar(
        title: Text('Manage Currencies', style: AppTheme.title),
        backgroundColor: AppTheme.white,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.nearlyBlack),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: (_isLoading || _isOfflineMode) ? null : _syncCurrencies, // Allow all users to sync in online mode
            tooltip: 'Sync Currencies',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _currencies.isEmpty
              ? Center(child: Text('No currencies added yet.'))
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _currencies.length,
                  itemBuilder: (context, index) {
                    final currency = _currencies[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.vimbikaBlue.withValues(alpha: 0.1),
                          child: Text(currency.symbol!, style: TextStyle(color: AppTheme.vimbikaBlue)),
                        ),
                        title: Row(
                          children: [
                            Text(currency.name!, style: TextStyle(fontWeight: FontWeight.bold)),
                            if (currency.isBaseCurrency!)
                              Container(
                                margin: EdgeInsets.only(left: 8),
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text('BASE', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                        subtitle: Text('Rate: ${currency.rate}'),
                        trailing: _canEdit ? IconButton(
                          icon: Icon(Icons.edit, color: AppTheme.grey),
                          onPressed: () => _showCurrencyDialog(currency: currency),
                        ) : null,
                      ),
                    );
                  },
                ),
      floatingActionButton: _canEdit ? FloatingActionButton(
        onPressed: () => _showCurrencyDialog(),
        backgroundColor: AppTheme.vimbikaBlue,
        child: Icon(Icons.add),
      ) : null,
    );
  }
}
