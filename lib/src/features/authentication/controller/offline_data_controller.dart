import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vimbika_pos_app/src/constants/app_constants.dart';
import 'package:vimbika_pos_app/src/constants/app_routes.dart';
import 'package:vimbika_pos_app/src/features/authentication/model/user_model.dart';
import 'package:vimbika_pos_app/src/features/shift/model/shift_setting_model.dart';
import 'package:vimbika_pos_app/src/services/app_exceptions.dart';
import 'package:vimbika_pos_app/src/services/background_service.dart';
import 'package:vimbika_pos_app/src/services/base_http_client.dart';
import 'package:vimbika_pos_app/src/services/connectivity_service.dart';
import 'package:vimbika_pos_app/src/services/sync_service.dart';
import 'package:vimbika_pos_app/src/shared/models/bank_model.dart';
import 'package:vimbika_pos_app/src/shared/models/base_name_model.dart';
import 'package:vimbika_pos_app/src/shared/models/branch_model.dart';
import 'package:vimbika_pos_app/src/shared/models/company_model.dart';
import 'package:vimbika_pos_app/src/shared/models/currency_model.dart';
import 'package:vimbika_pos_app/src/shared/models/customer_model.dart';
import 'package:vimbika_pos_app/src/shared/models/fiscal_device_model.dart';
import 'package:vimbika_pos_app/src/shared/models/payment_type_model.dart';
import 'package:vimbika_pos_app/src/shared/models/settings_model.dart';
import 'package:vimbika_pos_app/src/utils/app_helper.dart';
import 'package:http/http.dart' as http;

import '../../../services/local_storage_service.dart';
// import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';

class OfflineDataController extends GetxController {
  final ConnectivityService _connectivityService = ConnectivityService();
  late UserModel user = UserModel(firstName: "", lastName: "", userName: "");
  Rx<BranchModel?> selectedBranch = BranchModel().obs;
  final LocalStorageService _localStorageService = LocalStorageService();
  Rx<CompanyModel?> selectedCompany = CompanyModel(fiscalisationEnabled: false).obs;
  var isCompanySelected = false.obs;
  var isBranchSelected = false.obs;
  RxList<BranchModel> branchList = <BranchModel>[].obs;
  RxList<CompanyModel> companyList = <CompanyModel>[].obs;
  RxList<CurrencyModel> currencyList = <CurrencyModel>[].obs;
  RxList<CustomerModel> customerList = <CustomerModel>[].obs;
  RxList<BankModel> bankList = <BankModel>[].obs;
  RxList<PaymentTypeModel> paymentTypeList = <PaymentTypeModel>[].obs;
  RxList<FiscalDeviceModel> fiscalDeviceList = <FiscalDeviceModel>[].obs;
  var isInternetAccess = false.obs;
  late GetStorage box;
  @override
  Future<void> onInit() async {
    super.onInit();
    isInternetAccess.value =  await _connectivityService.checkServerConnection();
    box = GetStorage();
    var model = box.read(AppConstants.USER_INFO) ?? {};
    user = UserModel.fromMap(Map<String, dynamic>.from(model));
    getOfflineData(user, box);

  }

  Future<void> getOfflineData(UserModel user, GetStorage box) async{
    // Always load cached data first to ensure app works offline
    loadCachedData(box);
    print("getting getOfflineData");
    if(isInternetAccess.value){
      // Try to fetch fresh data from server
      // Use await to ensure companies are loaded before UI renders dropdown
      await getCompanies(user, box);
      getSettings(user, box);
      // Only fetch branches if a company is selected (branches are company-specific)
      if(isCompanySelected.isTrue && selectedCompany.value != null) {
        await getBranches(user, box, selectedCompany.value!.id!);//download branches
      } else {
        // If no company selected yet, branches will be loaded when company is selected
        // But we should still try to load branches for the user's default company
        if(user.companyId != null) {
          await getBranches(user, box, user.companyId!);//download branches
        }
      }
      getCurrencies(user, box);//download currencies

      getPaymentTypes(user, box);

      getCustomers(user, box, user.companyId!);
      // getCategories(user, box, user.companyId!);
      getBrands(user, box, user.companyId!);
      getShiftSetting(user, box);
      getBanks(user, box);
      print("getting getOfflineData");
      await SyncService.getBranchStock(box, user);

      Timer.periodic(Duration(minutes: 45), (timer) async {
        print("init syncing branchStock...");
        await SyncService.getBranchStock(box, user);
        await SyncService.saveCustomer(user, box);
        await SyncService.savePaymentReceived(user, box);
        await SyncService.getCustomers(user, box, user.companyId!);
        // syncOfflineSales();
      });


    } else{
      showSnackBar("Message", "Offline Branch Selected");
      var selectedBranch = box.read(AppConstants.SELECTED_BRANCH);
      if(selectedBranch != null){
        BranchModel branch = BranchModel.fromMap(selectedBranch);
        branchList.add(branch);
      } else{
        List<BranchModel> storageBranchList = getBranchList(box);
        branchList.value = storageBranchList;
      }
    }
  }
  
  // Load cached data from local storage
  Future<void> loadCachedData(GetStorage box) async {
    var _activeCompany = box.read(AppConstants.ACTIVE_COMPANY);
    if(_activeCompany != null && _activeCompany is Map) {
      CompanyModel savedCompany = CompanyModel.fromMap(
          Map<String, dynamic>.from(_activeCompany));
      print("user company id = ${user.company!.id}");
      print("saved company id = ${savedCompany.id}");
      if (user.company!.id != savedCompany.id) {
        List<Map<String, dynamic>> itemsListMap = [];
        box.write(AppConstants.BRANCH_PRODUCTS, itemsListMap);
        return;
      }
    }
    // Load companies
    List<CompanyModel> cachedCompanies = _localStorageService.getOfflineList<CompanyModel>(
      AppConstants.COMPANY_LIST,
      (map) => CompanyModel.fromMap(map),
      box
    );
    
    // Deduplicate companies by ID to prevent dropdown errors
    // Keep only the first occurrence of each company ID
    if(cachedCompanies.isNotEmpty) {
      Map<String, CompanyModel> uniqueCompanies = {};
      for (CompanyModel company in cachedCompanies) {
        if (company.id != null && !uniqueCompanies.containsKey(company.id)) {
          uniqueCompanies[company.id!] = company;
        }
      }
      cachedCompanies = uniqueCompanies.values.toList();
      companyList.value = cachedCompanies;
    }

    // Auto-select company from storage if it exists (for auto-fill after logout/close shift)
    var activeCompany = box.read(AppConstants.ACTIVE_COMPANY);
    if(activeCompany != null && activeCompany is Map) {
      try {
        CompanyModel savedCompany = CompanyModel.fromMap(Map<String, dynamic>.from(activeCompany));
        if(user.company!.id == savedCompany.id) {
          // Verify the company exists in the cached list
          try {
            CompanyModel foundCompany =
                companyList.firstWhere((c) => c.id == savedCompany.id);
            selectedCompany.value = foundCompany;
            isCompanySelected.value = true;
            print(
                "Auto-selected company: ${foundCompany.name} (ID: ${foundCompany.id})");
          } catch (e) {
            print(
                "Company ${savedCompany.id} not found in cached list, skipping auto-selection");
          }
        }else{
          print("different company selected");
          return;
        }
      } catch (e) {
        print("Error auto-selecting company: $e");
      }
    }
    
    // Load branches
    List<BranchModel> cachedBranches = getBranchList(box);
    
    // Deduplicate branches by ID to prevent dropdown errors
    // Keep only the first occurrence of each branch ID
    if(cachedBranches.isNotEmpty) {
      Map<String, BranchModel> uniqueBranches = {};
      for (BranchModel branch in cachedBranches) {
        if (branch.id != null && !uniqueBranches.containsKey(branch.id)) {
          uniqueBranches[branch.id!] = branch;
        }
      }
      cachedBranches = uniqueBranches.values.toList();
      branchList.value = cachedBranches;
    }
    
    // Auto-select branch from storage if it exists (for auto-fill after logout/close shift)
    var selectedBranchData = box.read(AppConstants.SELECTED_BRANCH);
    if(selectedBranchData != null && selectedBranchData is Map) {
      try {
        BranchModel savedBranch = BranchModel.fromMap(Map<String, dynamic>.from(selectedBranchData));
        // Verify the branch exists in the cached list
        try {
          BranchModel foundBranch = branchList.firstWhere((b) => b.id == savedBranch.id);
          selectedBranch.value = foundBranch;
          isBranchSelected.value = true;
          print("Auto-selected branch: ${foundBranch.name} (ID: ${foundBranch.id})");
          // Note: Company-branch relationship will be validated when user selects company
          // or when they try to proceed (branches are filtered by company at that point)
        } catch (e) {
          print("Branch ${savedBranch.id} not found in cached list, skipping auto-selection");
        }
      } catch (e) {
        print("Error auto-selecting branch: $e");
      }
    }
    
    // Load currencies
    List<CurrencyModel> cachedCurrencies = _localStorageService.getOfflineList<CurrencyModel>(
      AppConstants.CURRENCY_LIST,
      (map) => CurrencyModel.fromMap(map),
      box
    );
    if(cachedCurrencies.isNotEmpty) {
      currencyList.value = cachedCurrencies;
    }
    
    // Load payment types
    List<PaymentTypeModel> cachedPaymentTypes = _localStorageService.getOfflineList<PaymentTypeModel>(
      AppConstants.PAYMENT_TYPE_LIST,
      (map) => PaymentTypeModel.fromMap(map),
      box
    );
    if(cachedPaymentTypes.isNotEmpty) {
      paymentTypeList.value = cachedPaymentTypes;
    }
    
    // Load customers
    List<CustomerModel> cachedCustomers = _localStorageService.getCustomers(box);
    if(cachedCustomers.isNotEmpty) {
      customerList.value = cachedCustomers;
    }
    
    // Load banks
    List<BankModel> cachedBanks = _localStorageService.getOfflineList<BankModel>(
      AppConstants.BANK_LIST,
      (map) => BankModel.fromMap(map),
      box
    );
    if(cachedBanks.isNotEmpty) {
      bankList.value = cachedBanks;
    }
  }
  downloadBranchRelatedInfor(UserModel user, GetStorage box, String branchId){
    //getTickets(user, box, user.companyId!, branchId);
    // SyncService.syncTickets(user, box, user.companyId!, branchId);
  }

  Future<void> onCompanyChange(CompanyModel company) async{
      branchList.value = [];
      isBranchSelected.value = false;
      selectedBranch.value = BranchModel();
      
      // Load cached branches immediately for offline support
      loadCachedBranchesByCompany(box, company.id!);
      
      // Try to fetch fresh branches from server
      getBranches(user, box, company.id!);
  }

  Future<void>  getBranches(UserModel user, GetStorage box, String companyId) async{
    // Store the selected branch ID before fetching (if one was auto-selected)
    String? previouslySelectedBranchId;
    if(isBranchSelected.isTrue && selectedBranch.value != null && selectedBranch.value!.id != null) {
      previouslySelectedBranchId = selectedBranch.value!.id;
      // Temporarily clear selection to prevent dropdown errors during fetch
      // We'll re-select after the new list is loaded
      selectedBranch.value = BranchModel();
      isBranchSelected.value = false;
    }
    
    var response = await BaseHttpClient().getAuthWithCompanyHeader("/branch/get-by-company", companyId).catchError((onError){
      if (onError is BadRequestException) {
        var apiError = json.decode(onError.message!);
        AppHelper.showErroDialog(description: apiError["reason"]);
      } else {
        // If network/server error, load cached branches filtered by company
        if (onError is FetchDataException || onError is ApiNotRespondingException) {
          print("Network error loading branches, using cached data");
          loadCachedBranchesByCompany(box, companyId);
        } else {
          AppHelper.handleError(onError);
        }
      }
    });
    if(response != null) {
      List<dynamic> list = jsonDecode(response);
      List<BranchModel> itemsList = List<BranchModel>.from(list.map((i) => BranchModel.fromMap(i)));
      
      // Deduplicate branches by ID to prevent dropdown errors
      // Keep only the first occurrence of each branch ID
      Map<String, BranchModel> uniqueBranches = {};
      for (BranchModel branch in itemsList) {
        if (branch.id != null && !uniqueBranches.containsKey(branch.id)) {
          uniqueBranches[branch.id!] = branch;
        }
      }
      itemsList = uniqueBranches.values.toList();
      
      branchList.value = itemsList;
      branchList.refresh();
      List<Map<String, dynamic>> itemsListMap = itemsList.map((item) =>
          item.toMap()).toList();
      //showSnackBar("Message", "Branches downloaded successfully");
      box.write(AppConstants.BRANCH_LIST, itemsListMap);
      
      // Re-select branch from storage if it was auto-selected earlier
      // This ensures the selected branch instance matches the one in the dropdown list
      if(previouslySelectedBranchId != null) {
        try {
          BranchModel foundBranch = branchList.firstWhere((b) => b.id == previouslySelectedBranchId);
          selectedBranch.value = foundBranch;
          isBranchSelected.value = true;
          print("Re-selected branch after server fetch: ${foundBranch.name} (ID: ${foundBranch.id})");
        } catch (e) {
          print("Branch ${previouslySelectedBranchId} not found in server list, keeping selection cleared");
          // Also check if it exists in SELECTED_BRANCH storage
          var selectedBranchData = box.read(AppConstants.SELECTED_BRANCH);
          if(selectedBranchData != null && selectedBranchData is Map) {
            BranchModel savedBranch = BranchModel.fromMap(Map<String, dynamic>.from(selectedBranchData));
            if(savedBranch.id == previouslySelectedBranchId) {
              print("Branch ${previouslySelectedBranchId} exists in storage but not in server list - may have been deleted");
            }
          }
        }
      }
    } else {
      // If response is null and no error was caught, try loading cached branches
      loadCachedBranchesByCompany(box, companyId);
      
      // If fetch failed, restore the previous selection if it existed
      if(previouslySelectedBranchId != null) {
        try {
          BranchModel foundBranch = branchList.firstWhere((b) => b.id == previouslySelectedBranchId);
          selectedBranch.value = foundBranch;
          isBranchSelected.value = true;
          print("Restored branch selection after failed fetch: ${foundBranch.name} (ID: ${foundBranch.id})");
        } catch (e) {
          print("Could not restore branch selection after failed fetch");
        }
      }
    }
  }
  
  // Load cached branches (branches in cache are already filtered by company)
  void loadCachedBranchesByCompany(GetStorage box, String companyId) {
    List<BranchModel> cachedBranches = getBranchList(box);
    // Branches in BRANCH_LIST are already filtered by company when saved
    // So we can just load all cached branches
    
    // Deduplicate branches by ID to prevent dropdown errors
    if(cachedBranches.isNotEmpty) {
      Map<String, BranchModel> uniqueBranches = {};
      for (BranchModel branch in cachedBranches) {
        if (branch.id != null && !uniqueBranches.containsKey(branch.id)) {
          uniqueBranches[branch.id!] = branch;
        }
      }
      cachedBranches = uniqueBranches.values.toList();
      branchList.value = cachedBranches;
      branchList.refresh();
      print("Loaded ${cachedBranches.length} cached branches for company $companyId");
    } else {
      print("No cached branches found for company $companyId");
    }
  }

  Future<void>  getUsers(UserModel user, GetStorage box, String companyId, String branchId) async{
    var response = await BaseHttpClient().getAuthWithCompanyHeader("/user/get-by-branch/" + branchId, companyId).catchError((onError){
      if (onError is BadRequestException) {
        var apiError = json.decode(onError.message!);
        AppHelper.showErroDialog(description: apiError["reason"]);
      } else {
        AppHelper.handleError(onError);
      }
    });
    if(response != null) {
      List<dynamic> list = jsonDecode(response);
      List<UserModel> itemsList = List<UserModel>.from(list.map((i) => UserModel.fromMap(i)));
      print(itemsList.length);
      List<Map<String, dynamic>> itemsListMap = itemsList.map((item) =>
          item.toMap()).toList();
      //showSnackBar("Message", "Branches downloaded successfully");
      box.write(AppConstants.USER_LIST, itemsListMap);
    }
  }

  Future<void>  getBrands(UserModel user, GetStorage box, String companyId) async{
    var response = await BaseHttpClient().getAuthWithCompanyHeader("/brand/company/get-all", companyId).catchError((onError){
      if (onError is BadRequestException) {
        var apiError = json.decode(onError.message!);
        AppHelper.showErroDialog(description: apiError["reason"]);
      } else {
        AppHelper.handleError(onError);
      }
    });
    if(response != null) {
      List<dynamic> list = jsonDecode(response);
      List<BaseNameModel> itemsList = List<BaseNameModel>.from(list.map((i) => BaseNameModel.fromMap(i)));
      List<Map<String, dynamic>> itemsListMap = itemsList.map((item) =>
          item.toMap()).toList();
      //showSnackBar("Message", "Brands downloaded successfully");
      box.write(AppConstants.BRAND_LIST, itemsListMap);
    }
  }

  Future<void>  getCategories(UserModel user, GetStorage box, String companyId) async{
    var response = await BaseHttpClient().getAuthWithCompanyHeader("/product-category/get-by-branch-stock/${selectedBranch.value!.id}", companyId).catchError((onError){
      if (onError is BadRequestException) {
        var apiError = json.decode(onError.message!);
        AppHelper.showErroDialog(description: apiError["reason"]);
      } else {
        AppHelper.handleError(onError);
      }
    });
    if(response != null) {
      List<dynamic> list = jsonDecode(response);
      List<BaseNameModel> itemsList = List<BaseNameModel>.from(list.map((i) => BaseNameModel.fromMap(i)));
      List<Map<String, dynamic>> itemsListMap = itemsList.map((item) =>
          item.toMap()).toList();
      //showSnackBar("Message", "Categories downloaded successfully");
      box.write(AppConstants.CATEGORY_LIST, itemsListMap);
    }
  }




  Future<void>  getCustomers(UserModel user, GetStorage box, String companyId) async{
    List<CustomerModel> newCustomers = _localStorageService.getCustomers(box);
    newCustomers = newCustomers.where((cust)=>cust.updated ?? false).toList();
    var response = await BaseHttpClient().getAuthWithCompanyHeader("/customer/get-all", companyId).catchError((onError){
      if (onError is BadRequestException) {
        var apiError = json.decode(onError.message!);
        AppHelper.showErroDialog(description: apiError["reason"]);
      } else {
        AppHelper.handleError(onError);
      }
    });
    if(response != null) {
      List<dynamic> list = jsonDecode(response);
      List<CustomerModel> itemsList = List<CustomerModel>.from(list.map((i) => CustomerModel.fromMap(i)));
      itemsList.addAll(newCustomers);
      customerList.value = itemsList;
      List<Map<String, dynamic>> itemsListMap = itemsList.map((item) =>
          item.toMap()).toList();
      //showSnackBar("Message", "Customers downloaded successfully");
      box.write(AppConstants.CUSTOMER_LIST, itemsListMap);
    }
  }

  Future<void>  getCompanies(UserModel user, GetStorage box) async{
    // Store the selected company ID before fetching (if one was auto-selected)
    String? previouslySelectedCompanyId;
    if(isCompanySelected.isTrue && selectedCompany.value != null) {
      previouslySelectedCompanyId = selectedCompany.value!.id;
      // Temporarily clear selection to prevent dropdown errors during fetch
      // We'll re-select after the new list is loaded
      selectedCompany.value = CompanyModel(fiscalisationEnabled: false);
      isCompanySelected.value = false;
    }
    
    var response = await BaseHttpClient().getAuthWithCompanyHeader("/company/get-all", user.companyId!).catchError((onError){
      if (onError is BadRequestException) {
        var apiError = json.decode(onError.message!);
        AppHelper.showErroDialog(description: apiError["reason"]);
      } else {
        AppHelper.handleError(onError);
      }
    });
    if(response != null) {
      List<dynamic> list = jsonDecode(response);
      List<CompanyModel> itemsList = List<CompanyModel>.from(list.map((i) => CompanyModel.fromMap(i)));
      
      // Deduplicate companies by ID to prevent dropdown errors
      // Keep only the first occurrence of each company ID
      Map<String, CompanyModel> uniqueCompanies = {};
      for (CompanyModel company in itemsList) {
        if (company.id != null && !uniqueCompanies.containsKey(company.id)) {
          uniqueCompanies[company.id!] = company;
        }
      }
      itemsList = uniqueCompanies.values.toList();
      
      companyList.value = itemsList;
      List<Map<String, dynamic>> itemsListMap = itemsList.map((item) =>
          item.toMap()).toList();
      //showSnackBar("Message", "Companies downloaded successfully");
      box.write(AppConstants.COMPANY_LIST, itemsListMap);
      
      // Re-select company from storage if it was auto-selected earlier
      // This ensures the selected company instance matches the one in the dropdown list
      if(previouslySelectedCompanyId != null) {
        try {
          CompanyModel foundCompany = companyList.firstWhere((c) => c.id == previouslySelectedCompanyId);
          selectedCompany.value = foundCompany;
          isCompanySelected.value = true;
          print("Re-selected company after server fetch: ${foundCompany.name} (ID: ${foundCompany.id})");
        } catch (e) {
          print("Company ${previouslySelectedCompanyId} not found in server list, keeping selection cleared");
          // Also check if it exists in ACTIVE_COMPANY storage
          var activeCompany = box.read(AppConstants.ACTIVE_COMPANY);
          if(activeCompany != null && activeCompany is Map) {
            CompanyModel savedCompany = CompanyModel.fromMap(Map<String, dynamic>.from(activeCompany));
            if(savedCompany.id == previouslySelectedCompanyId) {
              print("Company ${previouslySelectedCompanyId} exists in storage but not in server list - may have been deleted");
            }
          }
        }
      }
    } else {
      // If fetch failed, restore the previous selection if it existed
      if(previouslySelectedCompanyId != null) {
        try {
          CompanyModel foundCompany = companyList.firstWhere((c) => c.id == previouslySelectedCompanyId);
          selectedCompany.value = foundCompany;
          isCompanySelected.value = true;
          print("Restored company selection after failed fetch: ${foundCompany.name} (ID: ${foundCompany.id})");
        } catch (e) {
          print("Could not restore company selection after failed fetch");
        }
      }
    }
  }
  Future<void>  getSettings(UserModel user, GetStorage box) async{
    var response = await BaseHttpClient().getAuthWithCompanyHeader("/product-feature/get", user.companyId!).catchError((onError){
      if (onError is BadRequestException) {
        var apiError = json.decode(onError.message!);
        AppHelper.showErroDialog(description: apiError["reason"]);
      } else {
        AppHelper.handleError(onError);
      }
    });
    if(response != null) {
      SettingsModel itemConverted = SettingsModel.fromJson(response);
      box.write(AppConstants.COMPANY_SETTINGS, itemConverted.toMap());
    }
  }
  Future<void>  getPaymentTypes(UserModel user, GetStorage box) async{
    var response = await BaseHttpClient().getAuthWithCompanyHeader("/payment-method/get-all", user.companyId!).catchError((onError){
      if (onError is BadRequestException) {
        var apiError = json.decode(onError.message!);
        AppHelper.showErroDialog(description: apiError["reason"]);
      } else {
        AppHelper.handleError(onError);
      }
    });
    if(response != null) {
      List<dynamic> list = jsonDecode(response);
      List<PaymentTypeModel> itemsList = List<PaymentTypeModel>.from(list.map((i) => PaymentTypeModel.fromMap(i)));
      paymentTypeList.value = itemsList;
      List<Map<String, dynamic>> itemsListMap = itemsList.map((item) =>
          item.toMap()).toList();
      //showSnackBar("Message", "Payment Types downloaded successfully");
      box.write(AppConstants.PAYMENT_TYPE_LIST, itemsListMap);
    }
  }

  onChangeBranch(String? branchId){
    getCategories(user, box, user.companyId!);
    getFiscalDevice(user, branchId!);
  }

  Future<void> getFiscalDevice(UserModel user, String branchId) async{
    var response = await BaseHttpClient().getAuthWithCompanyHeader("/fiscal-device/get-by-branch/" + branchId,  user.companyId!).catchError((onError){
      if (onError is BadRequestException) {
        var apiError = json.decode(onError.message!);
        AppHelper.showErroDialog(description: apiError["reason"]);
      } else {
        AppHelper.handleError(onError);
      }
    });

    if(response != null) {
      if(response.toString().length >0) {
        FiscalDeviceModel itemConverted = FiscalDeviceModel.fromJson(response);
        box.write(AppConstants.FISCAL_DEVICE, itemConverted.toMap());
        box.write(AppConstants.IS_FISCALISATION_ENABLED, true);
        showSnackBar("Message", "Fiscal status updated successfully");
      } else{
        box.write(AppConstants.IS_FISCALISATION_ENABLED, false);
      }
    } else{
      box.write(AppConstants.IS_FISCALISATION_ENABLED, false);
    }
  }

  Future<void> getShiftSetting(UserModel user, GetStorage box) async{
    var response = await BaseHttpClient().getAuthWithCompanyHeader("/shift/setting/get-item", user.companyId!).catchError((onError){
      if (onError is BadRequestException) {
        var apiError = json.decode(onError.message!);
        AppHelper.showErroDialog(description: apiError["reason"]);
      } else {
        AppHelper.handleError(onError);
      }
    });
    if(response != null) {
      ShiftSettingModel itemConverted = ShiftSettingModel.fromJson(response);
      box.write(AppConstants.SHIFT_SETTING, itemConverted.toMap());
      //showSnackBar("Message", "Shift setting updated successfully");
    }
  }

  Future<void> getBanks(UserModel user, GetStorage box) async{
    var response = await BaseHttpClient().getAuthWithCompanyHeader("/bank/get-all", user.companyId!).catchError((onError){
      if (onError is BadRequestException) {
        var apiError = json.decode(onError.message!);
        AppHelper.showErroDialog(description: apiError["reason"]);
      } else {
        AppHelper.handleError(onError);
      }
    });
    if(response != null) {
      List<dynamic> list = jsonDecode(response);
      List<BankModel> itemsList = List<BankModel>.from(list.map((i) => BankModel.fromMap(i)));
      bankList.value = itemsList;
      List<Map<String, dynamic>> itemsListMap = itemsList.map((item) =>
          item.toMap()).toList();
      box.write(AppConstants.BANK_LIST, itemsListMap);
    }
  }

  Future<void> getCurrencies(UserModel user, GetStorage box) async{
    var response = await BaseHttpClient().getAuthWithCompanyHeader("/currency/get-all", user.companyId!).catchError((onError){
      if (onError is BadRequestException) {
        var apiError = json.decode(onError.message!);
        AppHelper.showErroDialog(description: apiError["reason"]);
      } else {
        AppHelper.handleError(onError);
      }
    });
    if(response != null) {
      List<dynamic> list = jsonDecode(response);
      List<CurrencyModel> itemsList = List<CurrencyModel>.from(list.map((i) => CurrencyModel.fromMap(i)));
      currencyList.value = itemsList;
      List<Map<String, dynamic>> itemsListMap = itemsList.map((item) =>
          item.toMap()).toList();
      //showSnackBar("Message", "Currencies downloaded successfully");
      box.write(AppConstants.CURRENCY_LIST, itemsListMap);
    }
  }

  void showSnackBar(String title, String msg){
    Get.snackbar(
      title,
      msg,
      snackPosition: SnackPosition.BOTTOM,
      forwardAnimationCurve: Curves.elasticInOut,
      reverseAnimationCurve: Curves.easeOut,
    );
  }

  navigateToPin(){
    Get.put(BackgroundService());

    if(isBranchSelected.isTrue) {
      GetStorage box = GetStorage();
      box.write(AppConstants.SELECTED_BRANCH, selectedBranch.value!.toMap());
      box.write(AppConstants.ACTIVE_COMPANY, selectedCompany.value!.toMap());
       downloadAndSaveImage(selectedCompany.value!.id!);
      // downloadBranchRelatedInfor(user, box, selectedBranch.value!.id!);
      getUsers(user, box, selectedCompany.value!.id!, selectedBranch.value!.id!);
      Get.toNamed(AppRoutes.ENTER_PIN);
    } else{
      showSnackBar("Message", "Select Branch");
    }
  }

  Future<String?> downloadAndSaveImage(String companyId) async {
   String imageUrl = "${AppConstants.VIMBIKA_BACKEND_URL}/company/logo/${companyId}";
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

  List<BranchModel> getBranchList(GetStorage box) {
    // Read the data as a List<dynamic>
    List<dynamic>? itemsListDynamic = box.read<List<dynamic>>(AppConstants.BRANCH_LIST);
    // Check if the read data is not null
    if (itemsListDynamic != null) {
      // Convert the List<dynamic> to List<Map<String, dynamic>>
      List<Map<String, dynamic>> itemsListMap = itemsListDynamic.map((item) {
        return item as Map<String, dynamic>;
      }).toList();
      return List<BranchModel>.from(itemsListMap.map((map) => BranchModel.fromMap(map)));
    } else {
      return [];
    }
  }
}