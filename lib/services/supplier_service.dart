import 'dart:convert';
import 'package:vimbika_pro/app_constants/app_constants.dart';
import 'package:vimbika_pro/model/supplier.dart';
import 'package:vimbika_pro/model/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'base_http_client.dart';

class SupplierService {
  final BaseHttpClient _client = BaseHttpClient();

  Future<List<Supplier>> getAllSuppliers() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userData = prefs.getString(AppConstants.keyOnlineUserData);
    
    if (userData == null) throw Exception('User not logged in');
    final user = User.fromJson(jsonDecode(userData));
    
    final String? companyId = user.branch?.company?.id;
    if (companyId == null) throw Exception('Company ID not found for user');

    final String responseStr = await _client.getAuthWithCompanyHeader(
        '/supplier/get-all',
        companyId
    );

    final List<dynamic> data = jsonDecode(responseStr);
    return data.map((s) => Supplier.fromJson(s)).toList();
  }
}
