import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_constants/app_constants.dart';
import '../model/inventory_item.dart';
import '../model/user.dart';
import 'base_http_client.dart';

class SubscriptionService {
  final BaseHttpClient _client = BaseHttpClient();

  Future<List<InventoryItem>> getAvailableSubscriptions(String availability) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userData = prefs.getString(AppConstants.keyOnlineUserData);
    
    if (userData == null) throw Exception('User not logged in');
    final user = User.fromJson(jsonDecode(userData));
    
    final String? companyId = user.branch?.company?.id;
    if (companyId == null) throw Exception('Company ID not found for user');

    final String responseStr = await _client.getAuthWithCompanyHeader(
      '/inventory/billing-package/get-by-availability/$availability',
      companyId
    );

    final List<dynamic> data = jsonDecode(responseStr);
    return data.map((s) => InventoryItem.fromJson(s)).toList();
  }
}
