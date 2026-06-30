import 'dart:convert';
import 'package:vimbika_pro/model/inventory_item.dart';
import 'package:vimbika_pro/services/base_http_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_constants/app_constants.dart';
import '../model/user.dart';

class InventoryItemService {
  final BaseHttpClient _client = BaseHttpClient();

  Future<InventoryItem> saveInventoryItem(InventoryItem item) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userData = prefs.getString(AppConstants.keyOnlineUserData);

    if (userData == null) {
      throw Exception('User not logged in or user data not found.');
    }

    final User currentUser = User.fromJson(jsonDecode(userData));
    final String? companyId = currentUser.companyId;

    if (companyId == null) {
      throw Exception('Company ID not found for the current user.');
    }

    final String endpoint = '/item/save'; // Assuming this is the correct endpoint
    final String method = item.id != null && !item.id!.contains('_bs') ? 'PUT' : 'POST'; // Use PUT for existing items, POST for new

    final responseBody = await _client.postAuthWithCompanyHeader(
      endpoint,
      jsonEncode(item.toJson()),
      companyId,
      method,
    );

    return InventoryItem.fromJson(jsonDecode(responseBody));
  }

  Future<List<InventoryItem>> getAllInventoryItems() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userData = prefs.getString(AppConstants.keyOnlineUserData);

    if (userData == null) {
      throw Exception('User not logged in or user data not found.');
    }

    final User currentUser = User.fromJson(jsonDecode(userData));
    final String? companyId = currentUser.companyId;

    if (companyId == null) {
      throw Exception('Company ID not found for the current user.');
    }

    // Assuming an endpoint to fetch all inventory items, similar to dynamic-query for purchases
    // If this endpoint doesn't exist, it will need to be adjusted based on the actual API.
    final String responseStr = await _client.postAuthWithCompanyHeader(
        '/item/dynamic-query', // Assuming this endpoint can fetch all items without specific filters
        jsonEncode({}), // Empty payload to get all items
        companyId,
        "POST"
    );

    final List<dynamic> data = jsonDecode(responseStr);
    return data.map((item) => InventoryItem.fromJson(item)).toList();
  }
}
