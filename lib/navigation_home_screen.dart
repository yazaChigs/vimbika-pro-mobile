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
import 'package:vimbika_pro/sales_screen.dart';
import 'package:vimbika_pro/POS/pos_screen.dart';
import 'package:vimbika_pro/purchases_screen.dart';
import 'package:vimbika_pro/expenses_screen.dart';
import 'package:vimbika_pro/reports_screen.dart';
import 'package:vimbika_pro/screens/online/online_reports_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'inventory/inventory_screen.dart';

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
    return Container(
      color: AppTheme.white,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Scaffold(
          backgroundColor: AppTheme.nearlyWhite,
          body: DrawerUserController(
            screenIndex: drawerIndex,
            drawerWidth: MediaQuery.of(context).size.width * 0.75,
            onDrawerCall: (DrawerIndex drawerIndexdata) {
              changeIndex(drawerIndexdata);
            },
            screenView: screenView,
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
        default:
          break;
      }
    }
  }
}
