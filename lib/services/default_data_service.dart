import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart' as painting;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_constants/app_constants.dart';
import '../model/branch.dart';
import '../model/currency.dart';
import 'base_http_client.dart';
import 'branch_service.dart';
import 'currency_service.dart';
import 'category_service.dart';
import 'customer_service.dart';
import 'payments_service.dart';
import 'bank_service.dart';
import 'package:http/http.dart' as http; // Add this import

class DefaultDataService {
  final BranchService _branchService = BranchService();
  final CurrencyService _currencyService = CurrencyService();
  final CategoryService _categoryService = CategoryService();
  final CustomerService _customerService = CustomerService();
  final PaymentsService _paymentsService = PaymentsService();
  final BankService _bankService = BankService();

  Future<void> fetchAndSaveDefaultData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final Branch? branch = await _branchService.getDefaultBranch();
    
    try {
      // 1. Fetch defaults from API if possible (branches, currencies are from API)
      final List<Branch> branches = await _branchService.fetchUserBranches();
      await prefs.setStringList(AppConstants.keyBranches, branches.map((b) => jsonEncode(b.toJson())).toList());

      final List<Currency> currencies = await _currencyService.fetchCurrencies();
      await prefs.setStringList(AppConstants.keyCurrencies, currencies.map((c) => jsonEncode(c.toJson())).toList());
      
      // Fetch payment types from API
      await _paymentsService.fetchPaymentTypes();

      // Fetch banks from API
      await _bankService.fetchBanks();

      // Fetch categories for all branches (or just the default one)
      if (branches.isNotEmpty) {
      //   // Fetch categories for the first branch, this might need to be dynamic based on selected branch
        final String branchId = branches.first.id!;
        await _categoryService.fetchCategoriesByBranch(branchId);
      }
      //
      // // Fetch customers
      await _customerService.fetchCustomers();
      if(branch!=null && branch.company!=null) {
        await downloadAndSaveImage(branch.company!.id!);
      }



    } catch (e) {
      rethrow;
    }
  }

  Future<File?> getImage(String companyId) async {
    final directory = await getApplicationDocumentsDirectory();
    final imagePath = '${directory.path}/company_logo.png';
    final imageFile = File(imagePath);

    if (await imageFile.exists()) {
      return imageFile;
    } else {
      final downloadedPath = await downloadAndSaveImage(companyId);
      if (downloadedPath != null) {
        return File(downloadedPath);
      }
    }
    return null;
  }


  Future<String?> downloadAndSaveImage(String companyId) async {
    final BaseHttpClient _client = BaseHttpClient();
    String imageUrl = "/company/logo/${companyId}";
    try {
      // Get the application directory for storing files
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = '${directory.path}/company_logo.png';


      print('Attempting to download image from: $imageUrl');
      // Download the image from the URL
      final http.Response response = await _client.getAuthRaw(imageUrl);
      
      print('Download Response Status Code: ${response.statusCode}');
      print('Download Response Content-Type: ${response.headers['content-type']}');
      print('Download Response Content-Length: ${response.headers['content-length']}');
      print('Download Response Body Length: ${response.bodyBytes.length} bytes');

      if (response.statusCode == 200) {
        if(response.bodyBytes.isEmpty) {
          print('Warning: Downloaded image is empty.');
          return null;
        }

        // Save the image to local storage
        final file = File(imagePath);
        // Ensure directory exists
        await file.parent.create(recursive: true);
        await file.writeAsBytes(response.bodyBytes);
        
        final savedSize = await file.length();
        print('Image successfully saved to: $imagePath. Saved size: $savedSize bytes.');
        
        // Evict cache to ensure the new image is loaded next time Image.file is used
        painting.imageCache.evict(painting.FileImage(file));

        return imagePath; // Return the local file path of the image
      } else {
         print('Failed to download image. Server returned: ${response.body}');
      }
    } catch (e) {
      print('Failed to download and save image: $e');
    }
    return null;
  }
}
