import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../app_constants/app_constants.dart';
import 'base_http_client.dart';
import 'excel_export_service.dart';
import '../model/sale.dart';

class SaleSyncService {
  static final SaleSyncService _instance = SaleSyncService._internal();
  final BaseHttpClient _client = BaseHttpClient();
  final ExcelExportService _excelExportService = ExcelExportService();
  Timer? _syncTimer;
  bool _isSyncing = false;

  factory SaleSyncService() {
    return _instance;
  }

  SaleSyncService._internal();

  void startSyncTimer() {
    if (_syncTimer != null && _syncTimer!.isActive) {
      return;
    }
    // Run every 20 minutes
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      syncSales();
    });
    // Also run once immediately
    syncSales();
  }

  void stopSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  Future<void> clearOfflineSales() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyOfflineSales);
    debugPrint('Cleared offline sales from SharedPreferences.');
  }

  Future<void> syncSales() async {
    print('Syncing sales...');
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      
      final bool isOfflineMode = prefs.getBool(AppConstants.keyIsOfflineMode) ?? false;
      final String salesKey = isOfflineMode ? AppConstants.keyOfflineSales : AppConstants.keySales;
      
      List<String> salesJsonList = prefs.getStringList(salesKey) ?? [];

      if (salesJsonList.isEmpty) {
        _isSyncing = false;
        return;
      }

      debugPrint('Attempting to sync ${salesJsonList.length} sales from $salesKey...');

      // Parse all sales and filter out reversed ones
      final List<Map<String, dynamic>> allSalesMapList = [];
      final List<Sale> allSalesForExcel = [];

      for (var s in salesJsonList) {
        if (s.trim().isEmpty || s == 'null') continue;
        try {
          final decoded = jsonDecode(s);
          if (decoded is Map<String, dynamic>) {
            if (decoded['status'] != 'Reversed') {
              allSalesMapList.add(decoded);
              allSalesForExcel.add(Sale.fromJson(decoded));
            }
          }
        } catch (e) {
          debugPrint('Failed to decode a sale string: $e');
        }
      }

      // Export to Excel for the day
      if (allSalesForExcel.isNotEmpty) {
         final now = DateTime.now();
         final todaySales = allSalesForExcel.where((sale) {
           if (sale.timeIniated == null) return false;
           final saleDate = DateTime.parse(sale.timeIniated!);
             if (sale.dateCreated == null) return false;
             return saleDate.year == now.year &&
                    saleDate.month == now.month &&
                    saleDate.day == now.day;
         }).toList();

         if (todaySales.isNotEmpty) {
           final fileName = 'sales_backup_${DateFormat('yyyy_MM_dd').format(now)}';
           await _excelExportService.exportSalesToExcel(todaySales, fileName);
           debugPrint('Exported ${todaySales.length} sales to excel: $fileName');
         }
      }

      if (isOfflineMode) {
        _isSyncing = false;
        return; // Don't try to sync to server if in offline mode
      }

      // Check if logged in online
      final String? userData = prefs.getString(AppConstants.keyOnlineUserData);
      if (userData == null) {
        _isSyncing = false;
        return; // Not logged in online, skip sync
      }
      
      final Map<String, dynamic> userMap = jsonDecode(userData);
      final String? companyId = userMap['branch']?['company']?['id'];
      
      if (companyId == null) {
         _isSyncing = false;
         return;
      }

      if (allSalesMapList.isEmpty) { // This list now only contains non-reversed sales
        _isSyncing = false;
        return;
      }
      
      List<Map<String, dynamic>> unsyncedSalesToProcess = [];

      // Separate sales into unsynced and others
      for (var saleMap in allSalesMapList) {
        // A sale is considered unsynced if it has no server ID and is explicitly marked as not synced.
        if (saleMap['id'] == null && (saleMap['isSynced'] == false || saleMap['isSynced'] == null)) {
          unsyncedSalesToProcess.add(saleMap);
        }
      }

      List<Map<String, dynamic>> successfullySyncedSales = [];
      List<Map<String, dynamic>> failedToSyncSales = [];

      for (var saleJson in unsyncedSalesToProcess) {
        print('syncing: $saleJson');

        try {
          final String responseBody = await _client.postAuthWithCompanyHeader(
            '/sale/save', 
            jsonEncode(saleJson), 
            companyId, 
            'POST'
          );
          
          final Map<String, dynamic> syncedSaleData = jsonDecode(responseBody);

          // Merge original local data with synced data to ensure no fields are lost
          final Map<String, dynamic> mergedSale = Map<String, dynamic>.from(saleJson);
          mergedSale.addAll(syncedSaleData);

          // Mark as synced.
          mergedSale['isSynced'] = true;
          
          debugPrint('Successfully synced sale with new ID: ${mergedSale["id"]}');
          successfullySyncedSales.add(mergedSale);
          
        } catch (e) {
          debugPrint('Failed to sync a sale: $e');
          failedToSyncSales.add(saleJson);
        }
      }

      // Reconstruct the list of sales to be saved in SharedPreferences.
      // This logic will keep all unsynced sales, but only synced sales from the last 7 days
      // to prevent SharedPreferences from growing indefinitely.

      // 1. Create a list of all sales that are now "current"
      List<Map<String, dynamic>> currentSalesState = [];
      // Add sales that were already synced or not part of the sync attempt
      currentSalesState.addAll(allSalesMapList.where((saleMap) {
        final isUnsynced = saleMap['id'] == null && (saleMap['isSynced'] == false || saleMap['isSynced'] == null);
        return !isUnsynced;
      }));
      // Add newly synced sales
      currentSalesState.addAll(successfullySyncedSales);
      // Add sales that failed to sync
      currentSalesState.addAll(failedToSyncSales);

      // 2. Now filter this `currentSalesState` list for what to save.
      List<Map<String, dynamic>> finalSalesToSave = [];
      final DateTime sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

      // Use a set of JSON strings to track duplicates. It's inefficient but safe.
      Set<String> processedSales = {};

      for (var saleMap in currentSalesState) {
        final isSynced = saleMap['id'] != null && saleMap['isSynced'] == true;

        bool shouldKeep = false;
        if (!isSynced) {
          shouldKeep = true; // Always keep unsynced sales.
        } else {
          // For synced sales, keep them if they are recent.
          final timeInitiatedString = saleMap['timeIniated'];
          if (timeInitiatedString != null) {
            try {
              final saleDate = DateTime.parse(timeInitiatedString);
              if (saleDate.isAfter(sevenDaysAgo)) {
                shouldKeep = true;
              }
            } catch (e) {
              shouldKeep = true; // Keep if date parsing fails
            }
          } else {
            shouldKeep = true; // Keep if no date info
          }
        }

        if (shouldKeep) {
          String saleJson = jsonEncode(saleMap);
          if (!processedSales.contains(saleJson)) {
            finalSalesToSave.add(saleMap);
            processedSales.add(saleJson);
          }
        }
      }

      // 3. Save `finalSalesToSave` to SharedPreferences.
      final List<String> finalSalesJsonList = finalSalesToSave
          .map((saleMap) => jsonEncode(saleMap))
          .toList();

      if (finalSalesJsonList.isEmpty) {
        await prefs.remove(salesKey);
        debugPrint('Cleared all sales from $salesKey.');
      } else {
        await prefs.setStringList(salesKey, finalSalesJsonList);
        debugPrint('Updated sales in $salesKey. Total count: ${finalSalesJsonList.length}');
      }

    } catch (e) {
      debugPrint('Error in syncSales: $e');
    } finally {
      _isSyncing = false;
    }

    await calculateSharedPreferencesSize();
  }

  Future<List<Sale>> syncSelectedSales(List<Sale> sales, String companyId) async {
    List<Sale> syncedSales = [];
    for (var sale in sales) {
      if (sale.isSynced == true && sale.id != null) {
        syncedSales.add(sale);
        continue;
      }

      try {
        final Map<String, dynamic> saleJson = sale.toJson();
        final String responseBody = await _client.postAuthWithCompanyHeader(
          '/sale/save',
          jsonEncode(saleJson),
          companyId,
          'POST'
        );

        final Map<String, dynamic> syncedSaleData = jsonDecode(responseBody);
        final Map<String, dynamic> mergedSaleJson = Map<String, dynamic>.from(saleJson);
        mergedSaleJson.addAll(syncedSaleData);
        mergedSaleJson['isSynced'] = true;

        syncedSales.add(Sale.fromJson(mergedSaleJson));
        debugPrint('Successfully synced selected sale with new ID: ${mergedSaleJson["id"]}');
      } catch (e) {
        debugPrint('Failed to sync a selected sale: $e');
        syncedSales.add(sale); // Add original if failed
      }
    }
    return syncedSales;
  }


  Future<void> calculateSharedPreferencesSize() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = [
      AppConstants.keyHasUser,
      AppConstants.keyHasLoggedIn,
      AppConstants.keyUserData,
      AppConstants.keyOnlineUserData,
      AppConstants.keyOfflineUserData,
      AppConstants.keyAllUsers,
      AppConstants.keyCompanyData,
      AppConstants.keyOnlineCompanyData,
      AppConstants.keyOfflineCompanyData,
      AppConstants.keyDefaultBranch,
      AppConstants.keyOfflineBranch,
      AppConstants.keyBranches,
      AppConstants.keyOfflineBranches,
      AppConstants.keyUserRoles,
      AppConstants.keySubscriptions,
      AppConstants.keyOfflineSubscriptions,
      AppConstants.keySubscriptionDaysRemaining,
      AppConstants.keySelectedSubscription,
      AppConstants.keySubscriptionEndDate,
      AppConstants.keyConfig,
      AppConstants.keyUnsyncedClosedShift,
      AppConstants.keyCurrencies,
      AppConstants.keyOfflineCurrencies,
      AppConstants.keyTaxes,
      AppConstants.keyOfflineTaxes,
      AppConstants.keyCategories,
      AppConstants.keyOfflineCategories,
      AppConstants.keyExpenseCategories,
      AppConstants.keyUnits,
      AppConstants.keyOfflineUnits,
      AppConstants.keyBanks,
      AppConstants.keyOfflineBanks,
      AppConstants.keyOfflinePendingBanks,
      AppConstants.keyPaymentTypes,
      AppConstants.keyOfflinePaymentTypes,
      AppConstants.keySuppliers,
      AppConstants.keyCustomers,
      AppConstants.keyOfflineCustomers,
      AppConstants.keySales,
      AppConstants.keyOfflineSales,
      AppConstants.keyPurchases,
      AppConstants.keyInventoryItems,
      AppConstants.keyOfflineInventoryItems,
      AppConstants.keyExpenses,
      AppConstants.keyOnlineExpenses,
      AppConstants.keyBranchStock,
      AppConstants.keyOfflineBranchStock,
      AppConstants.keyOutOfStockItems,
      AppConstants.keyLastSelectedDate,
      AppConstants.keyPaymentsReceived,
      AppConstants.keyOfflinePaymentsReceived,
      AppConstants.keyPaymentsPaid,
      AppConstants.keyMobileShifts,
      AppConstants.keyOfflineMobileShifts,
      AppConstants.keyCurrentOpenShift,
      AppConstants.keyHeldSales,
      AppConstants.keyUnsyncedReceivedPayments,
      AppConstants.keyCachedPastShifts,
      AppConstants.keyLastFetchedUserId,
      AppConstants.keyAllowOutOfStockSales,
      AppConstants.keyIsOfflineMode,
      AppConstants.keyIsPriceInclusiveTax,
      AppConstants.keyCompanySettings,
      AppConstants.keyPrinterType,
      AppConstants.keyPrinterMacAddress,
      AppConstants.keyPrinterName,
      AppConstants.keyAlwaysPrintReceipt,
      AppConstants.keyNumberOfReceiptsPerSale,
      AppConstants.keyUsbPrinterDevice,
    ];

    int totalSize = 0;

    for (final key in keys) {
      final dynamic value = prefs.get(key);
      if (value == null) {
        continue;
      }

      int size = 0;
      if (value is String) {
        size = utf8.encode(value).length;
      } else if (value is bool) {
        size = 1;
      } else if (value is int) {
        size = 8;
      } else if (value is double) {
        size = 8;
      } else if (value is List<String>) {
        for (final str in value) {
          size += utf8.encode(str).length;
        }
      }
      totalSize += size;
      debugPrint('Key: $key, Size: $size bytes');
    }

    debugPrint('Total SharedPreferences size: $totalSize bytes');
    debugPrint('Total SharedPreferences size: ${totalSize / 1024} KB');
    debugPrint('Total SharedPreferences size: ${totalSize / (1024 * 1024)} MB');
  }
}
