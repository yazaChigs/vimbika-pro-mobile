import 'dart:convert';
import 'package:vimbika_pro/app_constants/app_constants.dart';
import 'package:vimbika_pro/model/currency.dart'; // Assuming a Currency model exists
import 'package:vimbika_pro/model/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'base_http_client.dart';

class CurrencyService {
  final BaseHttpClient _client = BaseHttpClient();

  Future<List<Currency>> fetchCurrencies() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userData = prefs.getString(AppConstants.keyOnlineUserData);
    
    if (userData == null) throw Exception('User not logged in');
    final user = User.fromJson(jsonDecode(userData));
    
    final String? companyId = user.companyId;
    if (companyId == null) throw Exception('Company ID not found for user');

    final String responseStr = await _client.getAuthWithCompanyHeader(
      '/currency/get-all', // Assuming this is the endpoint for currencies
      companyId
    );

    final List<dynamic> data = jsonDecode(responseStr);
    final List<Currency> currencies = data.map((c) => Currency.fromJson(c)).toList();
    
    // Save to shared preferences
    await prefs.setStringList(AppConstants.keyCurrencies, currencies.map((c) => jsonEncode(c.toJson())).toList());
    
    return currencies;
  }
}
