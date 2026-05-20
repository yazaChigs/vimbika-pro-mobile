import 'package:vimbika_pro/app_constants/app_constants.dart';
import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:vimbika_pro/screens/offline/settings/tax_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'category_management_screen.dart';
import 'currency_management_screen.dart';
import 'expense_category_management_screen.dart';
import 'unit_management_screen.dart';
import 'payment_type_management_screen.dart';
import 'bank_management_screen.dart';
import 'inventory_import_screen.dart';
import '../../../customer/customer_import_screen.dart';
import '../../../supplier/supplier_import_screen.dart';
import 'branch_management_screen.dart';
import 'company_profile_screen.dart';

class ConfigurationSettingsScreen extends StatefulWidget {
  const ConfigurationSettingsScreen({super.key});

  @override
  State<ConfigurationSettingsScreen> createState() => _ConfigurationSettingsScreenState();
}

class _ConfigurationSettingsScreenState extends State<ConfigurationSettingsScreen> {
  bool _isOfflineMode = true; // Default to true

  @override
  void initState() {
    super.initState();
    _loadMode();
  }

  Future<void> _loadMode() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isOfflineMode = prefs.getBool(AppConstants.keyIsOfflineMode) ?? true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.nearlyWhite,
      appBar: AppBar(
        title: const Text('Configuration', style: AppTheme.title),
        backgroundColor: AppTheme.white,
        iconTheme: const IconThemeData(color: AppTheme.nearlyBlack),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          _buildConfigItem(
            context,
            icon: Icons.business_outlined,
            title: 'Company Profile',
            subtitle: 'Update company details and contact info',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CompanyProfileScreen()),
              );
            },
          ),
          _buildConfigItem(
            context,
            icon: Icons.store_outlined,
            title: 'Manage Branches',
            subtitle: 'Add or edit business locations',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BranchManagementScreen()),
              );
            },
          ),
          const Divider(height: 32),
          if (_isOfflineMode) ...[
            _buildConfigItem(
              context,
              icon: Icons.inventory_2_outlined,
              title: 'Inventory Import',
              subtitle: 'Download template & upload stock',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const InventoryImportScreen()),
                );
              },
            ),
            _buildConfigItem(
              context,
              icon: Icons.people_outline,
              title: 'Customer Import',
              subtitle: 'Bulk import customers via CSV',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CustomerImportScreen()),
                );
              },
            ),
            _buildConfigItem(
              context,
              icon: Icons.local_shipping_outlined,
              title: 'Supplier Import',
              subtitle: 'Bulk import suppliers via CSV',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SupplierImportScreen()),
                );
              },
            ),
            _buildConfigItem(
              context,
              icon: Icons.account_balance_wallet_outlined,
              title: 'Expense Categories',
              subtitle: 'Manage categories for expenses',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ExpenseCategoryManagementScreen()),
                );
              },
            ),
            _buildConfigItem(
              context,
              icon: Icons.straighten_outlined,
              title: 'Units of Measure',
              subtitle: 'Define units like Kg, Ltrs, Pcs',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UnitManagementScreen()),
                );
              },
            ),
            _buildConfigItem(
              context,
              icon: Icons.receipt_long_outlined,
              title: 'Taxes',
              subtitle: 'Define tax percentages and rules',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TaxManagementScreen()),
                );
              },
            ),
          ],
          _buildConfigItem(
            context,
            icon: Icons.monetization_on_outlined,
            title: 'Currencies',
            subtitle: 'Manage app currencies and rates',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CurrencyManagementScreen()),
              );
            },
          ),
          _buildConfigItem(
            context,
            icon: Icons.category_outlined,
            title: 'Product Categories',
            subtitle: 'Manage product categories',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CategoryManagementScreen()),
              );
            },
          ),
          _buildConfigItem(
            context,
            icon: Icons.payment_outlined,
            title: 'Payment Methods',
            subtitle: 'Manage Cash, Bank, Mobile Money',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PaymentTypeManagementScreen()),
              );
            },
          ),
          _buildConfigItem(
            context,
            icon: Icons.account_balance_outlined,
            title: 'Manage Banks',
            subtitle: 'Add or edit bank accounts',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BankManagementScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConfigItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.vimbikaBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.vimbikaBlue),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.darkText,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 14, color: AppTheme.grey),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.grey),
        onTap: onTap,
      ),
    );
  }
}
