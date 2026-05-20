import 'package:vimbika_pro/customer/customer_management_screen.dart';
import 'package:vimbika_pro/expenses_screen.dart';
import 'package:vimbika_pro/POS/pos_screen.dart';
import 'package:vimbika_pro/purchases_screen.dart';
import 'package:vimbika_pro/reports_screen.dart';
import 'package:vimbika_pro/sales_screen.dart';
import 'package:vimbika_pro/screens/offline/settings/settings_screen.dart';
import 'package:vimbika_pro/screens/offline/settings/shift_management_screen.dart'; // Import ShiftManagementScreen
import 'package:flutter/widgets.dart';

import '../inventory/inventory_screen.dart';

class HomeList {
  HomeList({
    this.navigateScreen,
    this.imagePath = '',
    this.title = '',
  });

  Widget? navigateScreen;
  String imagePath;
  String title;

  static List<HomeList> homeList = [
    HomeList(
      imagePath: 'assets/images/image_reports.png',
      title: 'Reports',
      navigateScreen: const ReportsScreen(),
    ),
    HomeList(
      imagePath: 'assets/images/image_inventory.png',
      title: 'Inventory',
      navigateScreen: const InventoryScreen(),
    ),
    HomeList(
      imagePath: 'assets/images/image_sales.png',
      title: 'Sales',
      navigateScreen: SalesScreen(),
    ),
    HomeList(
      imagePath: 'assets/images/image_POS.png',
      title: 'POS',
      navigateScreen: POSScreen(),
    ),
    HomeList(
      imagePath: 'assets/images/image_expenses.png',
      title: 'Expenses',
      navigateScreen: const ExpensesScreen(),
    ),
    HomeList(
      imagePath: 'assets/images/image_customers.png',
      title: 'Customers',
      navigateScreen: const CustomerManagementScreen(),
    ),
    HomeList(
      imagePath: 'assets/images/image_settings.png',
      title: 'Settings',
      navigateScreen: SettingsScreen(),
    ),
    HomeList(
      imagePath: 'assets/images/image_purchases.png',
      title: 'Purchases',
      navigateScreen: const PurchasesScreen(),
    ),
    HomeList(
      imagePath: 'assets/images/image_shift.png', // Assuming an image for shifts exists or will be handled by fallback
      title: 'Shifts',
      navigateScreen: const ShiftManagementScreen(),
    ),
  ];
}
