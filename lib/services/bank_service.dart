import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_constants/app_constants.dart';
import '../model/bank.dart';
import '../model/user.dart';
import 'base_http_client.dart';

class BankService {
  final BaseHttpClient _client = BaseHttpClient();

  Future<List<Bank>> fetchBanks() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userData = prefs.getString(AppConstants.keyOnlineUserData);
    
    if (userData == null) throw Exception('User not logged in');
    final user = User.fromJson(jsonDecode(userData));
    
    final String? companyId = user.branch?.company?.id;
    if (companyId == null) throw Exception('Company ID not found for user');

    final String responseStr = await _client.getAuthWithCompanyHeader(
      '/bank/get-all',
      companyId
    );

    final List<dynamic> data = jsonDecode(responseStr);
    final List<Bank> banks = data.map((b) => Bank.fromJson(b)).toList();
    
    // Save to shared preferences
    await prefs.setStringList(AppConstants.keyBanks, banks.map((b) => jsonEncode(b.toJson())).toList());
    print('Banks saved to shared preferences ${banks.length}');
    
    return banks;
  }
}
