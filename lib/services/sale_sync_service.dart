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
    _syncTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      syncSales();
    });
    // Also run once immediately
    syncSales();
  }

  void stopSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  Future<void> syncSales() async {
    print('Syncing sales...');
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // We still want to export to excel even if offline
      final bool isOfflineMode = prefs.getBool(AppConstants.keyIsOfflineMode) ?? false;
      final String salesKey = isOfflineMode ? AppConstants.keyOfflineSales : AppConstants.keySales;
      
      final List<String> salesJsonList = prefs.getStringList(salesKey) ?? [];

      if (salesJsonList.isEmpty) {
        _isSyncing = false;
        return;
      }

      debugPrint('Attempting to sync ${salesJsonList.length} sales from $salesKey...');

      // Parse and filter valid sales
      final List<Map<String, dynamic>> allSalesMapList = [];
      final List<Sale> allSalesForExcel = [];
      
      for (var s in salesJsonList) {
        if (s.trim().isEmpty || s == 'null') continue;
        try {
          final decoded = jsonDecode(s);
          if (decoded is Map<String, dynamic>) {
            allSalesMapList.add(decoded);
            allSalesForExcel.add(Sale.fromJson(decoded));
          }
        } catch (e) {
          debugPrint('Failed to decode a sale string: $e');
        }
      }

      // Export to Excel for the day
      if (allSalesForExcel.isNotEmpty) {
         final now = DateTime.now();
         final todaySales = allSalesForExcel.where((sale) {
           final saleDate = DateTime.parse(sale.timeIniated);
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

      if (allSalesMapList.isEmpty) {
        _isSyncing = false;
        return;
      }
      
      List<Map<String, dynamic>> unsyncedSalesToProcess = [];
      List<Map<String, dynamic>> otherSales = []; // Includes already synced, or sales with unexpected states

      // Separate sales into unsynced and others
      for (var saleMap in allSalesMapList) {
        // A sale is considered unsynced if it has no server ID and is explicitly marked as not synced.
        if (saleMap['id'] == null && (saleMap['isSynced'] == false || saleMap['isSynced'] == null)) {
          unsyncedSalesToProcess.add(saleMap);
        } else {
          otherSales.add(saleMap);
        }
      }

      List<Map<String, dynamic>> successfullySyncedSales = [];
      List<Map<String, dynamic>> failedToSyncSales = [];
      bool syncCycleFailed = false;

      for (var saleJson in unsyncedSalesToProcess) {
        if (syncCycleFailed) {
          failedToSyncSales.add(saleJson);
          continue;
        }
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
          syncCycleFailed = true;
          failedToSyncSales.add(saleJson);
        }
      }

      // Reconstruct final list using posReference to avoid duplicates
      final Map<String, Map<String, dynamic>> finalSalesMap = {};

      void addToFinalMap(List<Map<String, dynamic>> sales) {
        for (var sale in sales) {
          final String? posRef = sale['posReference']?.toString();
          if (posRef != null) {
            // If already exists, prefer the one with an ID or isSynced=true
            if (!finalSalesMap.containsKey(posRef) || 
                (sale['id'] != null || sale['isSynced'] == true)) {
              finalSalesMap[posRef] = sale;
            }
          } else {
            // If no posReference, use id as fallback or just add if it has neither (shouldn't happen)
            final String fallbackKey = sale['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString();
            finalSalesMap[fallbackKey] = sale;
          }
        }
      }

      addToFinalMap(otherSales);
      addToFinalMap(successfullySyncedSales);
      addToFinalMap(failedToSyncSales);

      final List<String> finalSalesJsonList = finalSalesMap.values
          .map((saleMap) => jsonEncode(saleMap))
          .toList();

      await prefs.setStringList(AppConstants.keySales, finalSalesJsonList);

    } catch (e) {
      debugPrint('Error in syncSales: $e');
    } finally {
      _isSyncing = false;
    }
  }
}
