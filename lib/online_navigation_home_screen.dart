import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:vimbika_pro/custom_drawer/drawer_user_controller.dart';
import 'package:vimbika_pro/custom_drawer/home_drawer.dart';
import 'package:vimbika_pro/home_screen.dart';
import 'package:vimbika_pro/screens/online/online_reports_screen.dart';
import 'package:vimbika_pro/screens/offline/settings/settings_screen.dart';
import 'package:vimbika_pro/POS/pos_screen.dart'; // Import POSScreen
import 'package:vimbika_pro/customer/customer_list_screen.dart'; // Import CustomerManagementScreen
import 'package:vimbika_pro/supplier/supplier_management_screen.dart'; // Import SupplierManagementScreen
import 'package:vimbika_pro/sales/sales_screen.dart'; // Import SalesScreen
import 'package:vimbika_pro/inventory/inventory_screen.dart'; // Import InventoryScreen
import 'package:vimbika_pro/purchases_screen.dart'; // Import PurchasesScreen
import 'package:vimbika_pro/expenses_screen.dart'; // Import ExpensesScreen
import 'package:flutter/material.dart';
import 'package:vimbika_pro/shift/shift_management_screen.dart';

class OnlineNavigationHomeScreen extends StatefulWidget {
  final bool isOnline;
  const OnlineNavigationHomeScreen({super.key, this.isOnline = false});

  @override
  State<OnlineNavigationHomeScreen> createState() => _OnlineNavigationHomeScreenState();
}

class _OnlineNavigationHomeScreenState extends State<OnlineNavigationHomeScreen> {
  Widget? screenView;
  DrawerIndex? drawerIndex;

  @override
  void initState() {
    drawerIndex = DrawerIndex.home;
    screenView = const MyHomePage();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print('OnlineNavigationHomeScreen: build called. Current screenView type: ${screenView.runtimeType}');
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
              print('OnlineNavigationHomeScreen: onDrawerCall received $drawerIndexdata');
              changeIndex(drawerIndexdata);
            },
            screenView: screenView,
          ),
        ),
      ),
    );
  }

  void changeIndex(DrawerIndex drawerIndexdata) {
    print('OnlineNavigationHomeScreen: changeIndex called with $drawerIndexdata. Current drawerIndex: $drawerIndex');
    if (drawerIndex != drawerIndexdata) {
      drawerIndex = drawerIndexdata;
      switch (drawerIndex) {
        case DrawerIndex.home:
          setState(() {
            print('OnlineNavigationHomeScreen: Setting screenView to MyHomePage');
            screenView = const MyHomePage();
          });
          break;
        case DrawerIndex.reports:
          setState(() {
            print('OnlineNavigationHomeScreen: Setting screenView to OnlineReportsScreen');
            screenView = const OnlineReportsScreen();
          });
          break;
        case DrawerIndex.settings:
          setState(() {
            print('OnlineNavigationHomeScreen: Setting screenView to SettingsScreen');
            screenView = SettingsScreen();
          });
          break;
        case DrawerIndex.pos:
          setState(() {
            print('OnlineNavigationHomeScreen: Setting screenView to POSScreen');
            screenView = const POSScreen();
          });
          break;
        case DrawerIndex.customers:
          setState(() {
            print('OnlineNavigationHomeScreen: Setting screenView to CustomerManagementScreen');
            screenView = const CustomerListScreen();
          });
          break;
        case DrawerIndex.suppliers:
          setState(() {
            print('OnlineNavigationHomeScreen: Setting screenView to SupplierManagementScreen');
            screenView = const SupplierManagementScreen();
          });
          break;
        case DrawerIndex.sales:
          setState(() {
            print('OnlineNavigationHomeScreen: Setting screenView to SalesScreen');
            screenView = SalesScreen();
          });
          break;
        case DrawerIndex.inventory:
          setState(() {
            print('OnlineNavigationHomeScreen: Setting screenView to InventoryScreen');
            screenView = const InventoryScreen();
          });
          break;
        case DrawerIndex.purchases:
          setState(() {
            print('OnlineNavigationHomeScreen: Setting screenView to PurchasesScreen');
            screenView = const PurchasesScreen();
          });
          break;
        case DrawerIndex.expenses:
          setState(() {
            print('OnlineNavigationHomeScreen: Setting screenView to ExpensesScreen');
            screenView = const ExpensesScreen();
          });
          break;
        case DrawerIndex.shifts:
          setState(() {
            screenView = const ShiftManagementScreen();
          });
          break;
        default:
          print('OnlineNavigationHomeScreen: Unknown DrawerIndex: $drawerIndex. Defaulting to MyHomePage.');
          setState(() {
            screenView = const MyHomePage();
          });
          break;
      }
    } else {
      print('OnlineNavigationHomeScreen: DrawerIndex $drawerIndexdata is already selected. No change.');
    }
  }
}
