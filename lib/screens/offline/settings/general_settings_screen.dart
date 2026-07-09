import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:vimbika_pro/app_constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vimbika_pro/services/printer_service.dart';

class GeneralSettingsScreen extends StatefulWidget {
  const GeneralSettingsScreen({super.key});

  @override
  State<GeneralSettingsScreen> createState() => _GeneralSettingsScreenState();
}

class _GeneralSettingsScreenState extends State<GeneralSettingsScreen> {
  bool _allowOutOfStockSales = false;
  bool _isPriceInclusiveTax = true;
  bool _useKOT = false;
  bool _isLoading = true;
  final PrinterService _printerService = PrinterService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await _printerService.init();
    setState(() {
      _allowOutOfStockSales = prefs.getBool(AppConstants.keyAllowOutOfStockSales) ?? false;
      _isPriceInclusiveTax = prefs.getBool(AppConstants.keyIsPriceInclusiveTax) ?? true;
      _useKOT = prefs.getBool(AppConstants.keyUseKOT) ?? false;
      _isLoading = false;
    });
  }

  Future<void> _toggleOutOfStock(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyAllowOutOfStockSales, value);
    setState(() {
      _allowOutOfStockSales = value;
    });
  }

  Future<void> _togglePriceInclusiveTax(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyIsPriceInclusiveTax, value);
    setState(() {
      _isPriceInclusiveTax = value;
    });
  }

  Future<void> _toggleUseKOT(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyUseKOT, value);
    setState(() {
      _useKOT = value;
    });
  }


  Future<void> _deleteAllInventory() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Inventory?'),
        content: const Text('This will permanently remove ALL products and branch stock records. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('DELETE ALL', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await prefs.remove(AppConstants.keyInventoryItems);
      await prefs.remove(AppConstants.keyBranchStock);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All inventory data has been cleared'), backgroundColor: Colors.black),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.nearlyWhite,
      appBar: AppBar(
        title: const Text('General Settings', style: AppTheme.title),
        backgroundColor: AppTheme.white,
        iconTheme: const IconThemeData(color: AppTheme.nearlyBlack),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSettingSection('Inventory & Sales'),
                _buildSwitchTile(
                  title: 'Allow Out of Stock Sales',
                  subtitle: 'Permit items to be sold even when the recorded quantity is zero or less.',
                  value: _allowOutOfStockSales,
                  onChanged: _toggleOutOfStock,
                ),
                _buildSwitchTile(
                  title: 'Do you charge tax?',
                  subtitle: 'Enable or disable tax processing in sales.',
                  value: _isPriceInclusiveTax,
                  onChanged: _togglePriceInclusiveTax,
                ),
                _buildSwitchTile(
                  title: 'Use KOT',
                  subtitle: 'Enable Kitchen Order Ticket printing in POS.',
                  value: _useKOT,
                  onChanged: _toggleUseKOT,
                ),
                const SizedBox(height: 24),
                _buildSettingSection('Danger Zone'),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    title: const Text('Delete All Inventory',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Permanently remove all products and stock records.'),
                    trailing: const Icon(Icons.delete_forever, color: Colors.red),
                    onTap: _deleteAllInventory,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSettingSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 16, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppTheme.grey.withAlpha(150),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.vimbikaBlue,
      ),
    );
  }
}
