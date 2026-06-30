import 'dart:convert';
import 'package:vimbika_pro/app_constants/app_constants.dart';
import 'package:vimbika_pro/model/branch.dart';
import 'package:vimbika_pro/model/user.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'base_http_client.dart';

class BranchService {
  final BaseHttpClient _client = BaseHttpClient();

  Future<List<Branch>> fetchUserBranches() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userData = prefs.getString(AppConstants.keyOnlineUserData);
    
    if (userData == null) throw Exception('User not logged in');
    final user = User.fromJson(jsonDecode(userData));
    
    final String? companyId = user.companyId;
    if (companyId == null) throw Exception('Company ID not found for user');

    final String responseStr = await _client.getAuthWithCompanyHeader(
      '/branch/get-by-company',
      companyId
    );

    final List<dynamic> data = jsonDecode(responseStr);
    return data.map((b) => Branch.fromJson(b)).toList();
  }



  Future<Branch?> getDefaultBranch() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? defaultBranchJson = prefs.getString(AppConstants.keyDefaultBranch);
    if (defaultBranchJson != null && defaultBranchJson.isNotEmpty) {
      try {
        return Branch.fromJson(jsonDecode(defaultBranchJson));
      } catch (e) {
        debugPrint('Error decoding default branch from SharedPreferences: $e');
        return null;
      }
    }
    return null;
  }
}
