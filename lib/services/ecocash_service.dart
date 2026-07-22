import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vimbika_pro/model/ecocash_charge_request.dart';
import 'package:vimbika_pro/model/ecocash_charge_response.dart';
import 'package:vimbika_pro/services/base_http_client.dart';

class EcocashService {

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
