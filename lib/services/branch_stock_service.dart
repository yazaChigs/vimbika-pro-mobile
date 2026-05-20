import 'dart:convert';
import 'package:vimbika_pro/app_constants/app_constants.dart';
import 'package:vimbika_pro/model/base_name_model.dart';
import 'package:vimbika_pro/model/branch.dart';
import 'package:vimbika_pro/model/branch_stock.dart';
import 'package:vimbika_pro/model/inventory_item.dart';
import 'package:vimbika_pro/model/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'base_http_client.dart';

class BranchStockService {
  final BaseHttpClient _client = BaseHttpClient();

  Future<List<BranchStock>> fetchAndSaveBranchStock() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userData = prefs.getString(AppConstants.keyUserData) ?? prefs.getString(AppConstants.keyOnlineUserData);
    
    if (userData == null) throw Exception('User not logged in');
    final user = User.fromJson(jsonDecode(userData));
    
    final String? companyId = user.branch?.company?.id;
    if (companyId == null) throw Exception('Company ID not found for user');

    final String responseStr = await _client.getAuthWithCompanyHeader(
      '/branch-stock/get-by-company',
      companyId
    );

    final List<dynamic> data = jsonDecode(responseStr);
    final List<BranchStock> stocks = data.map((b) => BranchStock.fromJson(b)).toList();
    
    // Save to SharedPreferences
    final List<String> stockJsonList = stocks.map((s) => jsonEncode(s.toJson())).toList();
    print('Saving branch stock to SharedPreferences: ${stockJsonList.length}');
    await prefs.setStringList(AppConstants.keyBranchStock, stockJsonList);
    
    return stocks;
  }

  Future<List<BranchStock>> fetchBranchStock() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userData = prefs.getString(AppConstants.keyUserData) ?? prefs.getString(AppConstants.keyOnlineUserData);
    
    if (userData == null) throw Exception('User not logged in');
    final user = User.fromJson(jsonDecode(userData));
    
    final String? companyId = user.branch?.company?.id;
    if (companyId == null) throw Exception('Company ID not found for user');

    final Map<String, dynamic> payload = {
      "brand": null,
      "category": null,
      "description": null,
      "itemCode": null,
      "itemType": null,
      "name": null,
      "supplier": null,
      "getAll": true
      // "branch": user.branch
    };
    final String responseStr = await _client.postAuthWithCompanyHeader(
      '/inventory/search-dynamic-query',
      jsonEncode(payload),
      companyId,
      'POST'
    );

    final List<dynamic> data = jsonDecode(responseStr);
    return data.map((b) => BranchStock.fromJson(b)).toList();
  }

  Future<List<BranchStock>> fetchStockByBranch(Branch branch) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userData = prefs.getString(AppConstants.keyUserData) ?? prefs.getString(AppConstants.keyOnlineUserData);

    if (userData == null) throw Exception('User not logged in');
    final user = User.fromJson(jsonDecode(userData));

    final String? companyId = user.branch?.company?.id;
    if (companyId == null) throw Exception('Company ID not found for user');

    final String responseStr = await _client.getAuthWithCompanyHeader(
      '/inventory/items/list?branchId=${branch.id}',
      companyId,
    );

    final List<dynamic> data = jsonDecode(responseStr);
    return data.map((b) => BranchStock.fromJson(b)).toList();
  }



  Future<List<InventoryItem>> fetchOutOfStock() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userData = prefs.getString(AppConstants.keyOnlineUserData) ?? prefs.getString(AppConstants.keyUserData);

    if (userData == null) throw Exception('User not logged in');
    final user = User.fromJson(jsonDecode(userData));

    final String? companyId = user.branch?.company?.id;
    if (companyId == null) throw Exception('Company ID not found for user');

    final Map<String, dynamic> payload = {
      "brand": null,
      "category": null,
      "description": null,
      "itemCode": null,
      "itemType": null,
      "name": null,
      "supplier": null
    };

    final String responseStr = await _client.postAuthWithCompanyHeader(
      '/inventory/stock-alerts',
      jsonEncode(payload),
      companyId,
      "POST"
    );

    final List<dynamic> data = jsonDecode(responseStr);
    return data.map((b) => InventoryItem.fromJson(b)).toList();
  }

  Future<Map<String, double>> getStockSummary({String? branchId}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userData = prefs.getString(AppConstants.keyOnlineUserData) ?? prefs.getString(AppConstants.keyUserData);

    if (userData == null) throw Exception('User not logged in');
    final user = User.fromJson(jsonDecode(userData));

    final String? companyId = user.branch?.company?.id;
    if (companyId == null) throw Exception('Company ID not found for user');

    String endpoint = '/inventory/stock-summary';
    if (branchId != null) {
      endpoint += '?branchId=$branchId';
    }

    final String responseStr = await _client.getAuthWithCompanyHeader(
      endpoint,
      companyId
    );

    final Map<String, dynamic> data = jsonDecode(responseStr);
    
    // Convert Map<String, dynamic> to Map<String, double> safely
    Map<String, double> summary = {};
    data.forEach((key, value) {
      if (value is num) {
        summary[key] = value.toDouble();
      } else if (value is String) {
        summary[key] = double.tryParse(value) ?? 0.0;
      }
    });

    return summary;
  }
}
