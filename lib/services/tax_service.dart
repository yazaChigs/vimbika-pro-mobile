import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_constants/app_constants.dart';
import '../model/tax.dart';
import 'base_http_client.dart'; // Changed to BaseHttpClient

class TaxService {
  final BaseHttpClient _httpClient = BaseHttpClient(); // Changed to BaseHttpClient

  Future<List<Tax>> fetchTaxes() async {
    try {
      final response = await _httpClient.get('tax/get-all');
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> taxJsonList = responseData['data']; // Assuming the API returns data in a 'data' field
        
        final List<Tax> taxes = taxJsonList.map((json) => Tax.fromJson(json)).toList();
        
        // Save to SharedPreferences
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final List<String> taxListString = taxes.map((tax) => jsonEncode(tax.toJson())).toList();
        await prefs.setStringList(AppConstants.keyTaxes, taxListString);

        return taxes;
      } else {
        throw Exception('Failed to load taxes');
      }
    } catch (e) {
      print('Error fetching taxes: $e');
      rethrow;
    }
  }
}
