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

  Future<Map<String, dynamic>> redeemLicenseKey(String keyCode, {String? companyId, String? availability}) async {
    final Map<String, dynamic> bodyMap = {'keyCode': keyCode.trim()};
    if (companyId != null && companyId.trim().isNotEmpty) {
      bodyMap['companyId'] = companyId.trim();
    }
    if (availability != null && availability.trim().isNotEmpty) {
      bodyMap['availability'] = availability.trim();
    }
    final payload = jsonEncode(bodyMap);
    String responseStr;
    if (companyId != null && companyId.trim().isNotEmpty) {
      try {
        responseStr = await _client.postAuthWithCompanyHeader(
          '/subscription/license/redeem-company/${companyId.trim()}',
          payload,
          companyId.trim(),
          'POST',
        );
      } catch (e) {
        try {
          responseStr = await _client.postAuth(
            '/subscription/license/redeem',
            payload,
          );
        } catch (e2) {
          responseStr = await _client.post(
            '/subscription/license/redeem',
            payload,
          );
        }
      }
    } else {
      try {
        responseStr = await _client.postAuth(
          '/subscription/license/redeem',
          payload,
        );
      } catch (e) {
        responseStr = await _client.post(
          '/subscription/license/redeem',
          payload,
        );
      }
    }

    final dynamic decoded = jsonDecode(responseStr);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return {'status': 'SUCCESS', 'raw': decoded};
  }
}
