import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_constants/app_constants.dart';
import '../model/company.dart';
import '../model/user.dart';
import 'base_http_client.dart';
import 'app_exceptions.dart';

class CompanyService {
  static final CompanyService _instance = CompanyService._internal();

  factory CompanyService() {
    return _instance;
  }

  CompanyService._internal();

  /// Gets the current company based on the active mode (online or offline).
  /// Prioritizes mode-specific keys and falls back to legacy key.
  Future<Company?> getCompany() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool isOffline = prefs.getBool(AppConstants.keyIsOfflineMode) ?? true;

    String? companyJson;
    if (isOffline) {
      companyJson = prefs.getString(AppConstants.keyOfflineCompanyData);
    } else {
      companyJson = prefs.getString(AppConstants.keyOnlineCompanyData);
    }

    // Fallback to legacy key if mode-specific key is not found
    companyJson ??= prefs.getString(AppConstants.keyCompanyData);

    if (companyJson != null) {
      try {
        return Company.fromJson(jsonDecode(companyJson));
      } catch (e) {
        print('Error decoding company data: $e');
        return null;
      }
    }
    return null;
  }


  Future<Company?> getCompanyFromLocalStorage() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? companyJson = prefs.getString(AppConstants.keyOfflineCompanyData);
    if (companyJson != null && companyJson.isNotEmpty && companyJson != 'null') {
      try {
        return Company.fromJson(jsonDecode(companyJson));
      } on FormatException catch (e) {
        debugPrint('Error decoding Company from SharedPreferences: $e');
        // Optionally, remove the corrupted data
        await prefs.remove(AppConstants.keyOfflineCompanyData);
        return null;
      }
    }
    return null;
  }

  /// Saves online company data.
  Future<void> saveOnlineCompany(Company company) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String companyJson = jsonEncode(company.toJson());
    await prefs.setString(AppConstants.keyOnlineCompanyData, companyJson);
    // Maintain legacy key for compatibility
    await prefs.setString(AppConstants.keyCompanyData, companyJson);
  }

  /// Saves offline company data.
  Future<void> saveOfflineCompany(Company company) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String companyJson = jsonEncode(company.toJson());
    await prefs.setString(AppConstants.keyOfflineCompanyData, companyJson);
    // Maintain legacy key for compatibility
    await prefs.setString(AppConstants.keyCompanyData, companyJson);
  }

  /// Clears all company-related data from storage.
  Future<void> clearCompanyData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyOnlineCompanyData);
    await prefs.remove(AppConstants.keyOfflineCompanyData);
    await prefs.remove(AppConstants.keyCompanyData);
  }

  Future<List<Company>> getUserCompanies(User user) async {
    try {
      var response = await BaseHttpClient()
          .getAuthWithCompanyHeader("/company/get-all", user.branch!.company!.id!)
          .catchError((onError) {
        if (onError is BadRequestException) {
          // In a real app, we might want to show a dialog here,
          // but since AppHelper is missing, we'll rethrow or handle accordingly.
          // For now, we rethrow so the caller can handle it (e.g., showing a SnackBar).
          throw onError;
        } else {
          throw onError;
        }
      });

      List<dynamic> data = json.decode(response);
      return data.map((item) => Company.fromJson(item)).toList();
    } catch (e) {
      print('Error fetching user companies: $e');
      rethrow;
    }
  }

  Future<String?> downloadAndSaveImage(String companyId) async {
    String imageUrl = "${AppConstants.VIMBIKA_BACKEND_URL}/company/logo/$companyId";
    //  String imageUrl = "https://selfservice.nyaradzo.co.zw/assets/media/logos/logo-9.png";
    try {
      // Get the application directory for storing files
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = '${directory.path}/company_logo.png';

      // Download the image from the URL
      final response = await http.get(Uri.parse(imageUrl));
      print(response.headers['content-type']);
      if (response.statusCode == 200) {
        // Save the image to local storage
        final file = File(imagePath);
        await file.writeAsBytes(response.bodyBytes);
        print('Image saved to: $imagePath');
        return imagePath; // Return the local file path of the image
      }
    } catch (e) {
      print('Failed to download and save image: $e');
    }
    return null;
  }
}
