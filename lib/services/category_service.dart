import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_constants/app_constants.dart';
import '../model/category.dart';
import '../model/user.dart';
import 'base_http_client.dart';

class CategoryService {
  final BaseHttpClient _client = BaseHttpClient();

  Future<List<Category>> fetchCategoriesByBranch(String branchId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userData = prefs.getString(AppConstants.keyOnlineUserData);
    
    if (userData == null) throw Exception('User not logged in');
    final user = User.fromJson(jsonDecode(userData));
    
    final String? companyId = user.branch?.company?.id;
    if (companyId == null) throw Exception('Company ID not found for user');

    final String responseStr = await _client.getAuthWithCompanyHeader(
      '/product-category/get-by-branch-stock/$branchId',
      companyId
    );

    final List<dynamic> data = jsonDecode(responseStr);
    final List<Category> categories = data.map((c) => Category.fromJson(c)).toList();
    
    // Save to shared preferences
    await prefs.setStringList(AppConstants.keyCategories, categories.map((c) => jsonEncode(c.toJson())).toList());
    print('Categories saved to shared preferences ${categories.length}');
    
    return categories;
  }
}
