import 'dart:convert';
import 'package:vimbika_pro/app_constants/app_constants.dart';
import 'package:vimbika_pro/model/purchase.dart';
import 'package:vimbika_pro/model/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'base_http_client.dart';

class PurchaseService {
  final BaseHttpClient _client = BaseHttpClient();

  Future<List<Purchase>> fetchPurchases({
    required DateTime startDate,
    required DateTime endDate,
    String? branchId,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userData = prefs.getString(AppConstants.keyOnlineUserData);
    
    if (userData == null) throw Exception('User not logged in');
    final user = User.fromJson(jsonDecode(userData));
    
    final String? companyId = user.companyId;
    if (companyId == null) throw Exception('Company ID not found for user');

    final String formattedStartDate = '${startDate.toIso8601String().substring(0, 23)}Z';
    final String formattedEndDate = '${endDate.toIso8601String().substring(0, 23)}Z';

    final Map<String, dynamic> payload = {
      "endDateString": formattedEndDate,
      "startDateString": formattedStartDate,
    };

    final String responseStr = await _client.postAuthWithCompanyHeader(
        '/purchase/dynamic-query',
        jsonEncode(payload),
        companyId,
        "POST"
    );

    final List<dynamic> data = jsonDecode(responseStr);
    return data.map((p) => Purchase.fromJson(p)).toList();
  }

  Future<List<Purchase>> getAllPurchases() async {
    // Fetch purchases for a wide date range, e.g., last 10 years
    DateTime endDate = DateTime.now();
    DateTime startDate = DateTime(endDate.year - 10, endDate.month, endDate.day);
    return fetchPurchases(startDate: startDate, endDate: endDate);
  }

  Future<Purchase> updatePurchase(Purchase purchase) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userData = prefs.getString(AppConstants.keyOnlineUserData);
    
    if (userData == null) throw Exception('User not logged in');
    final user = User.fromJson(jsonDecode(userData));
    
    final String? companyId = user.companyId;
    if (companyId == null) throw Exception('Company ID not found for user');

    if (purchase.id == null) throw Exception('Purchase ID cannot be null for update');

    final String responseStr = await _client.postAuthWithCompanyHeader(
        '/purchase/${purchase.id}', // Assuming PUT endpoint for updating a purchase
        jsonEncode(purchase.toJson()),
        companyId,
        "PUT" // Use PUT for updates
    );

    return Purchase.fromJson(jsonDecode(responseStr));
  }
}
