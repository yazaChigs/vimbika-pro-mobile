import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vimbika_pro/model/ecocash_charge_request.dart';
import 'package:vimbika_pro/model/ecocash_charge_response.dart';

class EcocashService {
  static const String _baseUrl = 'https://payonline.ecocash.co.zw/ecocashGateway-preprod/payment/v1/transactions/amount';
  static const String _username = 'ecocash';
  static const String _password = 'mobiquity';

  Future<EcocashChargeResponse> charge(EcocashChargeRequest request) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Basic ${base64Encode(utf8.encode('$_username:$_password'))}',
      },
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200) {
      return EcocashChargeResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to make charge request: ${response.body}');
    }
  }
}
