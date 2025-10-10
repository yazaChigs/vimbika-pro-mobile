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
    if(isInternetAccess.value){
      getCompanies(user, box);
      getSettings(user, box);
      getBranches(user, box, user.companyId!);//download branches
      getCurrencies(user, box);//download currencies

      getPaymentTypes(user, box);

      getCustomers(user, box, user.companyId!);
      // getCategories(user, box, user.companyId!);
      getBrands(user, box, user.companyId!);
      getShiftSetting(user, box);
      getBanks(user, box);
      print("getting getOfflineData");
      await SyncService.getBranchStock(box, user);

      Timer.periodic(Duration(minutes: 20), (timer) async {
        print("init syncing branchStock...");
        await SyncService.getBranchStock(box, user);
        await SyncService.savePaymentReceived(user, box);
        await SyncService.saveCustomer(user, box);
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
  downloadBranchRelatedInfor(UserModel user, GetStorage box, String branchId){
    //getTickets(user, box, user.companyId!, branchId);
    // SyncService.syncTickets(user, box, user.companyId!, branchId);
  }

  Future<void> onCompanyChange(CompanyModel company) async{
      branchList.value = [];
      isBranchSelected.value = false;
      selectedBranch.value = BranchModel();
     getBranches(user, box, company.id!);
  }

  Future<void>  getBranches(UserModel user, GetStorage box, String companyId) async{
    var response = await BaseHttpClient().getAuthWithCompanyHeader("/branch/get-by-company", companyId).catchError((onError){
      if (onError is BadRequestException) {
        var apiError = json.decode(onError.message!);
        AppHelper.showErroDialog(description: apiError["reason"]);
      } else {
        AppHelper.handleError(onError);
      }
    });
    if(response != null) {
      List<dynamic> list = jsonDecode(response);
      List<BranchModel> itemsList = List<BranchModel>.from(list.map((i) => BranchModel.fromMap(i)));
      branchList.value = itemsList;

      branchList.refresh();
      List<Map<String, dynamic>> itemsListMap = itemsList.map((item) =>
          item.toMap()).toList();
      //showSnackBar("Message", "Branches downloaded successfully");
      box.write(AppConstants.BRANCH_LIST, itemsListMap);
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
      print("USERS");
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
      companyList.value = itemsList;
      List<Map<String, dynamic>> itemsListMap = itemsList.map((item) =>
          item.toMap()).toList();
      //showSnackBar("Message", "Companies downloaded successfully");
      box.write(AppConstants.COMPANY_LIST, itemsListMap);
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
      print(itemConverted.sellNilItems);
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
      print("printing response");
      if(response.toString().length >0) {
        print("fiscal device available");
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