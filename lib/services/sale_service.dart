import 'dart:convert';
import 'package:vimbika_pro/app_constants/app_constants.dart';
import 'package:vimbika_pro/model/online_sale.dart';
import 'package:vimbika_pro/model/sale.dart';
import 'package:vimbika_pro/model/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'base_http_client.dart';
import 'sale_sync_service.dart';
import 'excel_export_service.dart';

class SaleService {
  final BaseHttpClient _client = BaseHttpClient();
  final SaleSyncService _saleSyncService = SaleSyncService();
  final ExcelExportService _excelExportService = ExcelExportService();

  Future<void> saveSale(Sale sale) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    
    final bool isOfflineMode = prefs.getBool(AppConstants.keyIsOfflineMode) ?? false;
    final String salesKey = isOfflineMode ? AppConstants.keyOfflineSales : AppConstants.keySales;

    final List<String> salesJson = prefs.getStringList(salesKey) ?? [];
    
    // Remove existing sale with same posReference to avoid duplicates
    salesJson.removeWhere((s) {
      try {
        final Map<String, dynamic> existingSale = jsonDecode(s);
        return existingSale['posReference'] == sale.posReference;
      } catch (e) {
        return false;
      }
    });

    salesJson.add(jsonEncode(sale.toJson()));
    await prefs.setStringList(salesKey, salesJson);
    
    // Attempt to export sales immediately to ensure backup
    try {
      final List<Sale> allSalesForExcel = [];
      for (var s in salesJson) {
        if (s.trim().isEmpty || s == 'null') continue;
        try {
          final decoded = jsonDecode(s);
          if (decoded is Map<String, dynamic>) {
            allSalesForExcel.add(Sale.fromJson(decoded));
          }
        } catch (e) {
          print('Failed to decode a sale string for export: $e');
        }
      }

      if (allSalesForExcel.isNotEmpty) {
        final now = DateTime.now();
        final todaySales = allSalesForExcel.where((s) {
          final saleDate = DateTime.parse(s.timeIniated);
          return saleDate.year == now.year &&
                 saleDate.month == now.month &&
                 saleDate.day == now.day;
        }).toList();

        if (todaySales.isNotEmpty) {
          final fileName = 'sales_backup_${DateFormat('yyyy_MM_dd').format(now)}';
          await _excelExportService.exportSalesToExcel(todaySales, fileName);
          print('Exported ${todaySales.length} sales to excel: $fileName');
        }
      }
    } catch (e) {
      print('Error during immediate excel export: $e');
    }

    // No longer trigger sync here. Sync will be triggered by POSScreenController.
  }

  Future<void> syncSales() async {
    await _saleSyncService.syncSales();
  }

  Future<List<OnlineSale>> fetchSales({
    required DateTime startDate,
    required DateTime endDate,
    String? categoryId,
    String? branchId,
    String? userId, // Added userId parameter
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userData = prefs.getString(AppConstants.keyOnlineUserData);
    
    if (userData == null) throw Exception('User not logged in');
    final user = User.fromJson(jsonDecode(userData));
    
    final String? companyId = user.branch?.company?.id;
    if (companyId == null) throw Exception('Company ID not found for user');

    final String formattedStartDate = '${startDate.toIso8601String().substring(0, 23)}Z';
    final String formattedEndDate = '${endDate.toIso8601String().substring(0, 23)}Z';

    String queryParams = 'startDate=$formattedStartDate&endDate=$formattedEndDate';
    if (categoryId != null && categoryId.isNotEmpty) {
      queryParams += '&categoryId=$categoryId';
    }else{
      queryParams += '&categoryId=';
    }
    if (branchId != null && branchId.isNotEmpty) {
      queryParams += '&branchId=$branchId';
    }else{
      queryParams += '&branchId=';
    }

    final String responseStr = await _client.getAuthWithCompanyHeader(
      '/sale/app-sale-filter?$queryParams', 
      companyId
    );

    final List<dynamic> data = jsonDecode(responseStr);
    return data.map((s) => OnlineSale.fromJson(s)).toList();
  }

  Future<void> reverseSale(String saleId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userData = prefs.getString(AppConstants.keyOnlineUserData);
    
    if (userData == null) throw Exception('User not logged in');
    final user = User.fromJson(jsonDecode(userData));
    
    final String? companyId = user.branch?.company?.id;
    if (companyId == null) throw Exception('Company ID not found for user');

    await _client.postAuthWithCompanyHeader(
      '/sale/reverse',
      jsonEncode({'id': saleId}),
      companyId,
      'POST',
    );
  }
}
