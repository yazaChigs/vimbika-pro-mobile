import 'package:vimbika_pro/app_constants/app_constants.dart';
import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:vimbika_pro/custom_drawer/drawer_user_controller.dart';
import 'package:vimbika_pro/custom_drawer/home_drawer.dart';
import 'package:vimbika_pro/screens/offline/settings/feedback_screen.dart';
import 'package:vimbika_pro/screens/offline/settings/help_screen.dart';
import 'package:vimbika_pro/home_screen.dart';
import 'package:vimbika_pro/screens/offline/settings/invite_friend_screen.dart';
import 'package:vimbika_pro/screens/offline/settings/settings_screen.dart';
import 'package:vimbika_pro/customer/customer_management_screen.dart';
import 'package:vimbika_pro/supplier/supplier_management_screen.dart';
import 'package:vimbika_pro/sales/sales_screen.dart';
import 'package:vimbika_pro/POS/pos_screen.dart';
import 'package:vimbika_pro/purchases_screen.dart';
import 'package:vimbika_pro/expenses_screen.dart';
import 'package:vimbika_pro/reports_screen.dart';
import 'package:vimbika_pro/screens/online/online_reports_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart'; // Import provider
import 'package:vimbika_pro/shift/shift_management_screen.dart';

import 'inventory/inventory_screen.dart';

// Define a provider to handle navigation within the drawer
class NavigationProvider extends ChangeNotifier {
  final Function(DrawerIndex) _changeIndexCallback;

  NavigationProvider(this._changeIndexCallback);

  void navigateTo(DrawerIndex index) {
    _changeIndexCallback(index);
  }
}

class NavigationHomeScreen extends StatefulWidget {
  const NavigationHomeScreen({super.key});

  @override
  State<NavigationHomeScreen> createState() => _NavigationHomeScreenState();
}

class _NavigationHomeScreenState extends State<NavigationHomeScreen> {
  Widget? screenView;
  DrawerIndex? drawerIndex;
  bool _isOfflineMode = true;

  @override
  void initState() {
    drawerIndex = DrawerIndex.home;
    screenView = const MyHomePage();
    super.initState();
    _loadMode();
  }

  Future<void> _loadMode() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool isOfflineMode = prefs.getBool(AppConstants.keyIsOfflineMode) ?? true;
    if (mounted) {
      setState(() {
        _isOfflineMode = isOfflineMode;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => NavigationProvider(changeIndex),
      child: Container(
        color: AppTheme.white,
        child: SafeArea(
          top: false,
          bottom: false,
          child: Scaffold(
            backgroundColor: AppTheme.nearlyWhite,
            appBar: AppBar(
              backgroundColor: AppTheme.white,
              elevation: 0,
              leading: (drawerIndex == DrawerIndex.customers ||
                      drawerIndex == DrawerIndex.sales ||
                      drawerIndex == DrawerIndex.pos ||
                      drawerIndex == DrawerIndex.settings)
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppTheme.nearlyBlack),
                      onPressed: () {
                        changeIndex(DrawerIndex.home);
                      },
                    )
                  : IconButton(
                      icon: const Icon(Icons.menu, color: AppTheme.nearlyBlack),
                      onPressed: () {
                        drawerUserControllerKey.currentState?.toggleDrawer();
                      },
                    ),
              title: Text(
                drawerIndex == DrawerIndex.home ? 'Home' :
                drawerIndex == DrawerIndex.pos ? 'POS' :
                drawerIndex == DrawerIndex.inventory ? 'Inventory' :
                drawerIndex == DrawerIndex.sales ? 'Sales' :
                drawerIndex == DrawerIndex.purchases ? 'Purchases' :
                drawerIndex == DrawerIndex.expenses ? 'Expenses' :
                drawerIndex == DrawerIndex.reports ? 'Reports' :
                drawerIndex == DrawerIndex.customers ? 'Customers' :
                drawerIndex == DrawerIndex.suppliers ? 'Suppliers' :
                drawerIndex == DrawerIndex.settings ? 'Settings' :
                drawerIndex == DrawerIndex.shifts ? 'Shifts' :
                'Vimbika Pro', // Default title
                style: AppTheme.title,
              ),
            ),
            body: DrawerUserController(
              key: drawerUserControllerKey, // Assign the GlobalKey
              screenIndex: drawerIndex,
              drawerWidth: MediaQuery.of(context).size.width * 0.75,
              onDrawerCall: (DrawerIndex drawerIndexdata) {
                changeIndex(drawerIndexdata);
              },
              screenView: screenView,
            ),
          ),
        ),
      ),
    );
  }

  void changeIndex(DrawerIndex drawerIndexdata) {
    if (drawerIndex != drawerIndexdata) {
      drawerIndex = drawerIndexdata;
      switch (drawerIndex) {
        case DrawerIndex.home:
          setState(() {
            screenView = const MyHomePage();
          });
          break;
        case DrawerIndex.help:
          setState(() {
            screenView = HelpScreen();
          });
          break;
        case DrawerIndex.feedBack:
          setState(() {
            screenView = FeedbackScreen();
          });
          break;
        case DrawerIndex.invite:
          setState(() {
            screenView = InviteFriend();
          });
          break;
        case DrawerIndex.settings:
          setState(() {
            screenView = SettingsScreen();
          });
          break;
        case DrawerIndex.customers:
          setState(() {
            screenView = const CustomerManagementScreen();
          });
          break;
        case DrawerIndex.suppliers:
          setState(() {
            screenView = const SupplierManagementScreen();
          });
          break;
        case DrawerIndex.sales:
          setState(() {
            screenView = SalesScreen();
          });
          break;
        case DrawerIndex.pos:
          setState(() {
            screenView = const POSScreen();
          });
          break;
        case DrawerIndex.inventory:
          setState(() {
            screenView = const InventoryScreen();
          });
          break;
        case DrawerIndex.purchases:
          setState(() {
            screenView = const PurchasesScreen();
          });
          break;
        case DrawerIndex.expenses:
          setState(() {
            screenView = const ExpensesScreen();
          });
          break;
        case DrawerIndex.reports:
          setState(() {
            screenView = _isOfflineMode ? const ReportsScreen() : const OnlineReportsScreen();
          });
          break;
        case DrawerIndex.shifts:
          setState(() {
            screenView = const ShiftManagementScreen();
          });
          break;
        default:
          break;
      }
    }
  }
}
