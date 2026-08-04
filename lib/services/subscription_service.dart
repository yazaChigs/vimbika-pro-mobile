import 'dart:convert';
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
}
