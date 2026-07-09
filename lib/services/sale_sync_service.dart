import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_constants/app_constants.dart';
import 'base_http_client.dart';
import '../model/sale.dart';
import 'isar_service.dart';

class SaleSyncService {
  static final SaleSyncService _instance = SaleSyncService._internal();
  final BaseHttpClient _client = BaseHttpClient();
  final IsarService _isarService = IsarService();
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
    if (_isSyncing) {
      debugPrint('Sync already in progress...');
      return;
    }
    _isSyncing = true;
    debugPrint('Starting sales sync...');

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final bool isOfflineMode = prefs.getBool(AppConstants.keyIsOfflineMode) ?? false;

      if (isOfflineMode) {
        debugPrint('Offline mode is enabled, skipping sync.');
        _isSyncing = false;
        return;
      }

      final String? userData = prefs.getString(AppConstants.keyOnlineUserData);
      if (userData == null) {
        debugPrint('User not logged in online, skipping sync.');
        _isSyncing = false;
        return;
      }

      final Map<String, dynamic> userMap = jsonDecode(userData);
      final String? companyId = userMap['branch']?['company']?['id'];

      if (companyId == null) {
        debugPrint('Company ID not found, skipping sync.');
        _isSyncing = false;
        return;
      }

      List<Sale> unsyncedSales = await _isarService.getUnsyncedSales();

      if (unsyncedSales.isEmpty) {
        debugPrint('No unsynced sales to process.');
        _isSyncing = false;
        return;
      }

      debugPrint('Attempting to sync ${unsyncedSales.length} sales from Isar...');

      // Process sales one by one to avoid holding transactions open
      for (var sale in unsyncedSales) {
        if (sale.saleStatus == 'Reversed') {
          continue;
        }
        if(sale.isSynced == true || sale.id != null){
          continue;
        }

        if (sale.allPaymentTypes.isNotEmpty && sale.allPaymentTypes.first.bank.value != null) {
          print('Saving sale to API: ${sale.totalDiscount}');
        }
        debugPrint('Syncing sale: ${sale.totalDiscount}');
        final saleJson = sale.toJson();
        print('totalDiscount: ${saleJson['totalDiscount']}');

        try {
          final String responseBody = await _client.postAuthWithCompanyHeader(
            '/sale/save',
            jsonEncode(saleJson),
            companyId,
            'POST',
          );

          final Map<String, dynamic> syncedSaleData = jsonDecode(responseBody);

          if (syncedSaleData.containsKey('timestamp') && syncedSaleData.containsKey('status') && syncedSaleData.containsKey('error')) {
            debugPrint('Failed to sync sale ${sale.id ?? sale.isarId}: Server error: ${syncedSaleData['error']}');
            continue;
          }

          print(syncedSaleData);
          // if(syncedSaleData['id'] == null) {
          //   continue;
          // }

          // Update sale with server ID and mark as synced
          sale.id = syncedSaleData['id'];
          sale.isSynced = true;

          // This will open a new, short-lived transaction
          await _isarService.updateSale(sale);
          debugPrint('Successfully synced sale with new ID: ${sale.id}');

        } catch (e) {
          debugPrint('Failed to sync a sale: $e');
          // Decide on error handling: retry later or mark as failed?
          // For now, we just log and continue.
        }
      }

    } catch (e) {
      debugPrint('An error occurred in syncSales: $e');
    } finally {
      _isSyncing = false;
      debugPrint('Sales sync finished.');
    }
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
        print('saleitem: ${saleJson['items']}');
        final String responseBody = await _client.postAuthWithCompanyHeader(
          '/sale/save',
          jsonEncode(saleJson),
          companyId,
          'POST'
        );

        final Map<String, dynamic> syncedSaleData = jsonDecode(responseBody);

        if (syncedSaleData.containsKey('timestamp') && syncedSaleData.containsKey('status') && syncedSaleData.containsKey('error')) {
          debugPrint('Failed to sync selected sale ${sale.id ?? sale.isarId}: Server error: ${syncedSaleData['error']}');
          syncedSales.add(sale); // Add original if failed
          continue;
        }
        
        sale.id = syncedSaleData['id'];
        sale.isSynced = true;
        
        await _isarService.updateSale(sale);
        syncedSales.add(sale);
        debugPrint('Successfully synced selected sale with new ID: ${sale.id}');
      } catch (e) {
        debugPrint('Failed to sync a selected sale: $e');
        syncedSales.add(sale); // Add original if failed
      }
    }
    return syncedSales;
  }

}
