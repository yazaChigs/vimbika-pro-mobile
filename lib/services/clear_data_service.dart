import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' as painting;
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vimbika_pro/app_constants/app_constants.dart';
import 'package:vimbika_pro/model/user_role.dart';
import 'package:vimbika_pro/model/sale.dart';
import 'package:vimbika_pro/model/inventory_item.dart';
import 'package:vimbika_pro/model/branch_stock.dart';
import 'package:vimbika_pro/model/customer.dart';
import 'package:vimbika_pro/model/payment_received.dart';
import 'package:vimbika_pro/services/isar_service.dart';

class ClearDataService {
  final IsarService _isarService = IsarService();

  /// Returns current counts of stored records in local storage.
  Future<Map<String, int>> getDataCounts() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // Sales count: preferences + isar db
      final List<String> sales = prefs.getStringList(AppConstants.keySales) ?? [];
      final List<String> offlineSales = prefs.getStringList(AppConstants.keyOfflineSales) ?? [];
      int isarSalesCount = 0;
      if (Isar.getInstance() != null) {
        try {
          final isar = await _isarService.db;
          isarSalesCount = await isar.sales.count();
        } catch (_) {}
      }
      final int totalSales = sales.length + offlineSales.length + isarSalesCount;

      // Inventory count: items + branch stocks + isar
      final List<String> items = prefs.getStringList(AppConstants.keyInventoryItems) ?? [];
      final List<String> offlineItems = prefs.getStringList(AppConstants.keyOfflineInventoryItems) ?? [];
      final List<String> branchStocks = prefs.getStringList(AppConstants.keyBranchStock) ?? [];
      final List<String> offlineBranchStocks = prefs.getStringList(AppConstants.keyOfflineBranchStock) ?? [];
      int isarInventoryCount = 0;
      if (Isar.getInstance() != null) {
        try {
          final isar = await _isarService.db;
          isarInventoryCount = (await isar.inventoryItems.count()) + (await isar.branchStocks.count());
        } catch (_) {}
      }
      final int totalInventory = items.length + offlineItems.length + branchStocks.length + offlineBranchStocks.length + isarInventoryCount;

      // Customers count: preferences + isar
      final List<String> customers = prefs.getStringList(AppConstants.keyCustomers) ?? [];
      final List<String> offlineCustomers = prefs.getStringList(AppConstants.keyOfflineCustomers) ?? [];
      int isarCustomersCount = 0;
      if (Isar.getInstance() != null) {
        try {
          final isar = await _isarService.db;
          isarCustomersCount = await isar.customers.count();
        } catch (_) {}
      }
      final int totalCustomers = customers.length + offlineCustomers.length + isarCustomersCount;

      // Payments count: preferences + isar
      final List<String> payments = prefs.getStringList(AppConstants.keyPaymentsReceived) ?? [];
      final List<String> offlinePayments = prefs.getStringList(AppConstants.keyOfflinePaymentsReceived) ?? [];
      final List<String> unsyncedPayments = prefs.getStringList(AppConstants.keyUnsyncedReceivedPayments) ?? [];
      int isarPaymentsCount = 0;
      if (Isar.getInstance() != null) {
        try {
          final isar = await _isarService.db;
          isarPaymentsCount = await isar.paymentReceiveds.count();
        } catch (_) {}
      }
      final int totalPayments = payments.length + offlinePayments.length + unsyncedPayments.length + isarPaymentsCount;

      return {
        'sales': totalSales,
        'inventory': totalInventory,
        'customers': totalCustomers,
        'payments': totalPayments,
      };
    } catch (e) {
      debugPrint('Error getting data counts: $e');
      return {
        'sales': 0,
        'inventory': 0,
        'customers': 0,
        'payments': 0,
      };
    }
  }

  /// Completely clears all local data across Isar, SharedPreferences, and local cache files.
  /// Compatible with Windows, Android, iOS, macOS, and Linux.
  Future<void> clearAllData() async {
    // 1. Clear Isar database
    if (Isar.getInstance() != null) {
      try {
        await _isarService.clearAllData();
      } catch (e) {
        debugPrint('Error clearing Isar database: $e');
      }
    }

    // 2. Clear local files & temporary cache
    await clearTempCache();

    // 3. Clear SharedPreferences
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Re-initialize default roles
      final List<UserRole> defaultRoles = [
        UserRole(name: 'ROLE_SUPER_ADMIN', description: 'Full system access'),
        UserRole(name: 'ROLE_SALES', description: 'Sales and inventory access'),
      ];
      final List<String> rolesJson = defaultRoles
          .map((role) => jsonEncode(role.toJson()))
          .toList();
      await prefs.setStringList(AppConstants.keyUserRoles, rolesJson);
      await prefs.setBool(AppConstants.keyIsOfflineMode, true);
    } catch (e) {
      debugPrint('Error clearing SharedPreferences: $e');
    }
  }

  /// Clears only transaction history (sales, payments, shifts, held sales, purchases, expenses).
  Future<void> clearTransactionsAndShifts() async {
    if (Isar.getInstance() != null) {
      try {
        await _isarService.clearSalesAndTransactions();
      } catch (e) {
        debugPrint('Error clearing Isar transactions: $e');
      }
    }

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> transactionKeys = [
        AppConstants.keySales,
        AppConstants.keyOfflineSales,
        AppConstants.keyPaymentsReceived,
        AppConstants.keyOfflinePaymentsReceived,
        AppConstants.keyPaymentsPaid,
        AppConstants.keyMobileShifts,
        AppConstants.keyOfflineMobileShifts,
        AppConstants.keyCurrentOpenShift,
        AppConstants.keyHeldSales,
        AppConstants.keyUnsyncedReceivedPayments,
        AppConstants.keyPurchases,
        AppConstants.keyExpenses,
        AppConstants.keyOnlineExpenses,
        AppConstants.keyLastSelectedDate,
      ];

      for (var key in transactionKeys) {
        await prefs.remove(key);
      }
    } catch (e) {
      debugPrint('Error clearing transaction preferences: $e');
    }
  }

  /// Clears local inventory items, branch stock, and related categories/units/taxes/suppliers.
  Future<void> clearInventoryData() async {
    if (Isar.getInstance() != null) {
      try {
        await _isarService.clearInventoryData();
      } catch (e) {
        debugPrint('Error clearing Isar inventory: $e');
      }
    }

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> inventoryKeys = [
        AppConstants.keyInventoryItems,
        AppConstants.keyOfflineInventoryItems,
        AppConstants.keyBranchStock,
        AppConstants.keyOfflineBranchStock,
        AppConstants.keyOutOfStockItems,
        AppConstants.keyCategories,
        AppConstants.keyOfflineCategories,
        AppConstants.keyExpenseCategories,
        AppConstants.keyUnits,
        AppConstants.keyOfflineUnits,
        AppConstants.keyTaxes,
        AppConstants.keyOfflineTaxes,
        AppConstants.keySuppliers,
      ];

      for (var key in inventoryKeys) {
        await prefs.remove(key);
      }
    } catch (e) {
      debugPrint('Error clearing inventory preferences: $e');
    }
  }

  /// Clears local customer records and offline balance data.
  Future<void> clearCustomerData() async {
    if (Isar.getInstance() != null) {
      try {
        await _isarService.clearCustomers();
      } catch (e) {
        debugPrint('Error clearing Isar customers: $e');
      }
    }

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.keyCustomers);
      await prefs.remove(AppConstants.keyOfflineCustomers);
    } catch (e) {
      debugPrint('Error clearing customer preferences: $e');
    }
  }

  /// Cleans local temporary cache and application documents images across platforms safely.
  Future<void> clearTempCache() async {
    try {
      painting.imageCache.clear();
      painting.imageCache.clearLiveImages();
    } catch (e) {
      debugPrint('Error clearing image cache: $e');
    }

    if (!kIsWeb) {
      // Clear company logo from documents directory
      try {
        final docDir = await getApplicationDocumentsDirectory();
        if (docDir.existsSync() &&
            docDir.path != '.' &&
            docDir.path != '/' &&
            docDir.path.length > 3) {
          final logoFile = File('${docDir.path}/company_logo.png');
          if (await logoFile.exists()) {
            await logoFile.delete();
          }
        }
      } catch (e) {
        debugPrint('Error deleting local company logo file: $e');
      }

      // Clear temp directory safely
      try {
        final tempDir = await getTemporaryDirectory();
        if (tempDir.existsSync() &&
            tempDir.path != '.' &&
            tempDir.path != '/' &&
            tempDir.path.length > 3 &&
            (tempDir.path.toLowerCase().contains('temp') ||
                tempDir.path.toLowerCase().contains('cache') ||
                tempDir.path.toLowerCase().contains('tmp') ||
                tempDir.path.toLowerCase().contains('appdata'))) {
          final List<FileSystemEntity> entities = tempDir.listSync(recursive: false);
          for (var entity in entities) {
            try {
              if (entity.path != tempDir.path) {
                await entity.delete(recursive: true);
              }
            } catch (_) {}
          }
        }
      } catch (e) {
        debugPrint('Error deleting temporary directory files: $e');
      }
    }
  }
}
