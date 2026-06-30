import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_constants/app_constants.dart';
import '../model/tax.dart';
import '../model/user.dart';
import 'base_http_client.dart'; // Changed to BaseHttpClient

class TaxService {
  final BaseHttpClient _httpClient = BaseHttpClient(); // Changed to BaseHttpClient

  Future<List<Tax>> fetchTaxes() async {
    try {

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? userData = prefs.getString(AppConstants.keyOnlineUserData);

      if (userData == null) throw Exception('User not logged in');
      final user = User.fromJson(jsonDecode(userData));

      final String? companyId = user.companyId;
      if (companyId == null) throw Exception('Company ID not found for user');
      final response = await _httpClient.getAuthWithCompanyHeader('/tax/get-all', companyId);

      final List<dynamic> data = jsonDecode(response);
      final List<Tax> taxes = data.map((b) => Tax.fromJson(b)).toList();

      // Save to SharedPreferences
      final List<String> taxListString = taxes.map((tax) => jsonEncode(tax.toJson())).toList();
      await prefs.setStringList(AppConstants.keyTaxes, taxListString);

      return taxes;
    } catch (e) {
      print('Error fetching taxes: $e');
      rethrow;
    }
  }
}
