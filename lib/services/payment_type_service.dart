import 'dart:convert';
import '../model/payment_type.dart';
import 'base_http_client.dart';

class PaymentTypeService {
  final BaseHttpClient _client = BaseHttpClient();

  Future<PaymentType?> savePaymentType(PaymentType type) async {
    final String responseStr = await _client.post(
      '/payment-type/save',
      jsonEncode(type.toJson()),
    );

    final Map<String, dynamic> response = jsonDecode(responseStr);
    if (response.containsKey('item') && response['item'] != null) {
      return PaymentType.fromJson(response['item']);
    }
    return null;
  }

  Future<PaymentType?> savePaymentTypeWithCompany(PaymentType type, String companyId) async {
    final String responseStr = await _client.postAuthWithCompanyHeader(
      '/payment-method/save',
      jsonEncode(type.toJson()),
      companyId,
      'POST'
    );

    final Map<String, dynamic> response = jsonDecode(responseStr);
    if (response.containsKey('item') && response['item'] != null) {
      return PaymentType.fromJson(response['item']);
    }
    return null;
  }
}
