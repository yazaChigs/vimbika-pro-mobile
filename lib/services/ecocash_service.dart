import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vimbika_pro/model/ecocash_charge_request.dart';
import 'package:vimbika_pro/model/ecocash_charge_response.dart';
import 'package:vimbika_pro/services/base_http_client.dart';

class EcocashService {
  // This _baseUrl and credentials are for direct EcoCash gateway interaction,
  // which we are moving away from for the initiate flow.
  // static const String _baseUrl = 'https://payonline.ecocash.co.zw/ecocashGateway-preprod/payment/v1/transactions/amount';
  // static const String _username = 'ecocash';
  // static const String _password = 'mobiquity';

  // The chargeDirect method is being replaced by initiatePayment via backend
  // Future<EcocashChargeResponse> chargeDirect(EcocashChargeRequest request) async {
  //   final response = await http.post(
  //     Uri.parse(_baseUrl),
  //     headers: {
  //       'Content-Type': 'application/json',
  //       'Authorization': 'Basic ${base64Encode(utf8.encode('$_username:$_password'))}',
  //     },
  //     body: jsonEncode(request.toJson()),
  //   );

  //   if (response.statusCode == 200) {
  //     return EcocashChargeResponse.fromJson(jsonDecode(response.body));
  //   } else {
  //     throw Exception('Failed to make charge request: ${response.body}');
  //   }
  // }


  final BaseHttpClient _client = BaseHttpClient();

  // New method to initiate payment via your backend
  Future<Map<String, dynamic>> initiatePayment(Map<String, dynamic> request) async {
    final responseStr = await _client.post('/payments/ecocash/initiate', jsonEncode(request));
    print('Response from backend: $responseStr');
    // Assuming your backend returns EcocashChargeResponse directly
    return jsonDecode(responseStr);
  }

  Future<Map<String, dynamic>> charge(EcocashChargeRequest request) async {
    final responseStr = await _client.post('/payments/ecocash/charge', jsonEncode(request.toJson()));
    return jsonDecode(responseStr);
  }

  Future<Map<String, dynamic>> checkStatus(String clientCorrelator) async {
    final responseStr = await _client.get('/payments/ecocash/status/$clientCorrelator');
    return jsonDecode(responseStr);
  }
}
