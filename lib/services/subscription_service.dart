import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_constants/app_constants.dart';
import '../model/inventory_item.dart';
import '../model/subscription.dart';
import '../model/user.dart';
import 'base_http_client.dart';

class SubscriptionService {
  final BaseHttpClient _client = BaseHttpClient();

  Future<List<InventoryItem>> getAvailableSubscriptions(String availability) async {
    final String responseStr = await _client.get(
      '/inventory/billing-package/get-by-availability/$availability',
    );

    final List<dynamic> data = jsonDecode(responseStr);
    return data.map((s) => InventoryItem.fromJson(s)).toList();
  }

  Future<List<InventoryItem>> getPublicSubscriptions(String category) async {
    final String responseStr = await _client.get(
      '/inventory/billing-package/get-public/$category',
    );

    final List<dynamic> data = jsonDecode(responseStr);
    return data.map((s) => InventoryItem.fromJson(s)).toList();
  }

  Future<User?> saveVimbikaUser(User user) async {
    final String responseStr = await _client.post(
      '/user/vimbika/save',
      jsonEncode(user.toJson()),
    );

    final Map<String, dynamic> response = jsonDecode(responseStr);
    if (response.containsKey('item') && response['item'] != null) {
      return User.fromJson(response['item']);
    }
    return null;
  }

  Future<Subscription?> saveSubscriptionPro(Subscription subscription) async {
    final String responseStr = await _client.post(
      '/subscription/save-pro',
      jsonEncode(subscription.toJson()),
    );

    final Map<String, dynamic> response = jsonDecode(responseStr);
    if (response.containsKey('item') && response['item'] != null) {
      return Subscription.fromJson(response['item']);
    }
    return null;
  }
}
