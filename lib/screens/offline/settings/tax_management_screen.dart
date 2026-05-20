import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:vimbika_pro/model/user.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../app_constants/app_constants.dart';
import '../../../model/tax.dart';
import '../../../services/tax_service.dart'; // Import TaxService

class TaxManagementScreen extends StatefulWidget {
  @override
  _TaxManagementScreenState createState() => _TaxManagementScreenState();
}

class _TaxManagementScreenState extends State<TaxManagementScreen> {
  List<Tax> _taxes = [];
  bool _isLoading = true;
  bool _isOfflineMode = false; // New state variable
  bool _canEdit = true;

  final TaxService _taxService = TaxService(); // Initialize TaxService

  @override
  void initState() {
    super.initState();
    _loadTaxes();
  }

  Future<void> _loadTaxes() async {
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

    final String taxKey = _isOfflineMode ? AppConstants.keyOfflineTaxes : AppConstants.keyTaxes;
    final List<String> taxListJson = prefs.getStringList(taxKey) ?? [];
    
    setState(() {
      _taxes = taxListJson
          .map((item) => Tax.fromJson(jsonDecode(item)))
          .toList();
      _isLoading = false;
      _canEdit = canEdit;
    });
  }

  Future<void> _saveTaxes() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String taxKey = _isOfflineMode ? AppConstants.keyOfflineTaxes : AppConstants.keyTaxes;
    final List<String> taxListJson = _taxes
        .map((item) => jsonEncode(item.toJson()))
        .toList();
    await prefs.setStringList(taxKey, taxListJson);
  }

  Future<void> _syncTaxes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _taxService.fetchTaxes(); // Fetch from API and save to SharedPreferences
      await _loadTaxes(); // Reload from SharedPreferences
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Taxes synced from API')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sync taxes: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showTaxDialog({Tax? tax}) {
    if (!_canEdit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You do not have permission to edit taxes.')),
      );
      return;
    }
    
    final nameController = TextEditingController(text: tax?.name);
    final rateController = TextEditingController(text: tax?.taxPercentage.toString() ?? '0.0');
    final descriptionController = TextEditingController(text: tax?.description);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tax == null ? 'Add Tax' : 'Edit Tax'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: InputDecoration(labelText: 'Tax Name (e.g. VAT)')),
              TextField(
                controller: rateController, 
                decoration: InputDecoration(labelText: 'Rate (%)'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
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
              
              final newTax = Tax(
                id: tax?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameController.text,
                taxPercentage: double.tryParse(rateController.text) ?? 0.0,
                description: descriptionController.text.isNotEmpty ? descriptionController.text : null,
              );

              setState(() {
                if (tax == null) {
                  _taxes.add(newTax);
                } else {
                  final index = _taxes.indexWhere((t) => t.id == tax.id);
                  _taxes[index] = newTax;
                }
              });
              _saveTaxes();
              Navigator.pop(context);
            },
            child: Text('Save'),
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
        title: Text('Manage Taxes', style: AppTheme.title),
        backgroundColor: AppTheme.white,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.nearlyBlack),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: (_isLoading || _isOfflineMode) ? null : _syncTaxes, // Allow all users to sync in online mode
            tooltip: 'Sync Taxes',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _taxes.isEmpty
              ? Center(child: Text('No taxes added yet.'))
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _taxes.length,
                  itemBuilder: (context, index) {
                    final tax = _taxes[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.vimbikaBlue.withValues(alpha: 0.1),
                          child: Text('${tax.taxPercentage.toStringAsFixed(0)}%', style: TextStyle(color: AppTheme.vimbikaBlue)),
                        ),
                        title: Text(tax.name, style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(tax.description ?? 'No description'),
                        trailing: _canEdit ? IconButton(
                          icon: Icon(Icons.edit, color: AppTheme.grey),
                          onPressed: () => _showTaxDialog(tax: tax),
                        ) : null,
                        onLongPress: () {
                          // TODO: Implement delete confirmation
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: _canEdit ? FloatingActionButton(
        onPressed: () => _showTaxDialog(),
        backgroundColor: AppTheme.vimbikaBlue,
        child: Icon(Icons.add),
      ) : null,
    );
  }
}
