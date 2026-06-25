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

  Future<Bank?> saveBank(Bank bank) async {
    final String responseStr = await _client.post(
      '/bank/save',
      jsonEncode(bank.toJson()),
    );

    final Map<String, dynamic> response = jsonDecode(responseStr);
    if (response.containsKey('item') && response['item'] != null) {
      return Bank.fromJson(response['item']);
    }
    return null;
  }

  Future<Bank?> saveBankWithCompany(Bank bank, String companyId) async {
    final String responseStr = await _client.postAuthWithCompanyHeader(
      '/bank/save',
      jsonEncode(bank.toJson()),
      companyId,
      'POST'
    );

    final Map<String, dynamic> response = jsonDecode(responseStr);
    if (response.containsKey('item') && response['item'] != null) {
      return Bank.fromJson(response['item']);
    }
    return null;
  }
}
