import 'dart:convert';
import 'package:vimbika_pro/app_constants/app_constants.dart';
import 'package:vimbika_pro/model/expense.dart';
import 'package:vimbika_pro/model/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'base_http_client.dart';

class ExpenseService {
  final BaseHttpClient _client = BaseHttpClient();

  Future<List<Expense>> fetchExpenses({
    required DateTime startDate,
    required DateTime endDate,
    String? branchId,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userData = prefs.getString(AppConstants.keyOnlineUserData);
    
    if (userData == null) throw Exception('User not logged in');
    final user = User.fromJson(jsonDecode(userData));
    
    final String? companyId = user.companyId;
    if (companyId == null) throw Exception('Company ID not found for user');

    final String formattedStartDate = '${startDate.toIso8601String().substring(0, 23)}Z';
    final String formattedEndDate = '${endDate.toIso8601String().substring(0, 23)}Z';


    final Map<String, dynamic> payload = {
      "endDateString": formattedEndDate,
      "startDateString": formattedStartDate,
    };

    final String responseStr = await _client.postAuthWithCompanyHeader(
      '/expense/dynamic-query',
        jsonEncode(payload),
      companyId,
      "POST"
    );

    final List<dynamic> data = jsonDecode(responseStr);
    final List<Expense> expenses = data.map((e) => Expense.fromJson(e)).toList();

    // Save expenses to local storage
    await prefs.setStringList(AppConstants.keyOnlineExpenses, expenses.map((e) => jsonEncode(e.toJson())).toList());

    return expenses;
  }
}
