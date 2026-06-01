import 'package:vimbika_pro/app_constants/app_constants.dart';
import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../account_settings_screen.dart';
import '../../../printer_settings_screen.dart'; // Import the printer settings screen
import 'bulk_price_adjustment_screen.dart';
import 'configuration_settings_screen.dart';
import 'general_settings_screen.dart';
import 'help_support_screen.dart';
import 'subscription_screen.dart';
import 'sales_backup_screen.dart';
import 'dart:convert';
import '../../../model/user.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isOfflineMode = true; // Default to true
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadMode();
  }

  Future<void> _loadMode() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final isOffline = prefs.getBool(AppConstants.keyIsOfflineMode) ?? true;
    
    final String userKey = isOffline ? AppConstants.keyOfflineUserData : AppConstants.keyOnlineUserData;
    final String? userData = prefs.getString(userKey);
    
    setState(() {
      _isOfflineMode = isOffline;
      if (userData != null) {
        _currentUser = User.fromJson(jsonDecode(userData));
      }
    });
  }

  bool _isSuperAdmin() {
    if (_currentUser == null) return false;
    
    // Check role string directly
    if (_currentUser!.role == 'ROLE_SUPER_ADMIN') {
       return true;
    }
    
    // Or check userRoles list
    if (_currentUser!.userRoles != null) {
        return _currentUser!.userRoles!.any((role) => role.name == 'ROLE_SUPER_ADMIN');
    }
    
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.nearlyWhite,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: <Widget>[
            Container(
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top,
                  left: 16,
                  right: 16),
              child: Row(
                children: <Widget>[
                  IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: <Widget>[
                  _buildSettingItem(
                    icon: Icons.settings_applications_outlined,
                    title: 'General',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GeneralSettingsScreen(),
                        ),
                      );
                    },
                  ),
                  if (_isOfflineMode) // Conditionally show Account settings
                    _buildSettingItem(
                      icon: Icons.person_outline,
                      title: 'Account',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AccountSettingsScreen(),
                          ),
                        );
                      },
                    ),
                  _buildSettingItem(
                    icon: Icons.print_outlined, // Icon for printer settings
                    title: 'Printer Settings',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PrinterSettingsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildSettingItem(
                    icon: Icons.settings_outlined,
                    title: 'Configuration',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ConfigurationSettingsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildSettingItem(
                    icon: Icons.price_change_outlined,
                    title: 'Bulk Price Adjustment',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BulkPriceAdjustmentScreen(),
                        ),
                      );
                    },
                  ),
                  // if (_isSuperAdmin())
                    _buildSettingItem(
                      icon: Icons.backup_table,
                      title: 'Sales Backups',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SalesBackupScreen(),
                          ),
                        );
                      },
                    ),
                  _buildSettingItem(
                    icon: Icons.card_membership,
                    title: 'Subscription',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SubscriptionScreen(),
                        ),
                      );
                    },
                  ),
                  // _buildSettingItem(
                  //   icon: Icons.notifications_none,
                  //   title: 'Notifications',
                  //   onTap: () {},
                  // ),
                  // _buildSettingItem(
                  //   icon: Icons.lock_outline,
                  //   title: 'Privacy & Security',
                  //   onTap: () {},
                  // ),
                  // _buildSettingItem(
                  //   icon: Icons.language_outlined,
                  //   title: 'Language',
                  //   onTap: () {},
                  // ),
                  _buildSettingItem(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HelpSupportScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.grey),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: AppTheme.darkText,
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
