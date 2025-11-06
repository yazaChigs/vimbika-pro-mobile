import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vimbika_pos_app/src/constants/app_constants.dart';
import 'package:vimbika_pos_app/src/features/authentication/model/user_model.dart';
import 'package:vimbika_pos_app/src/features/printers/model/available_printer_model.dart';
import 'package:vimbika_pos_app/src/features/sale/model/sale_infor_model.dart';
import 'package:vimbika_pos_app/src/features/sale/model/sale_model.dart';
import 'package:vimbika_pos_app/src/features/shift/model/currency_amount.dart';
import 'package:vimbika_pos_app/src/services/app_exceptions.dart';
import 'package:vimbika_pos_app/src/services/base_http_client.dart';
import 'package:vimbika_pos_app/src/services/connectivity_service.dart';
import 'package:vimbika_pos_app/src/services/local_storage_service.dart';
import 'package:vimbika_pos_app/src/services/printer_service.dart';
import 'package:http/http.dart' as http;
import 'package:vimbika_pos_app/src/shared/models/base_name_model.dart';
import 'package:vimbika_pos_app/src/shared/models/branch_model.dart';
import 'package:vimbika_pos_app/src/utils/app_helper.dart';

import '../../../services/sync_service.dart';
import '../../shift/model/shift_model.dart';
import '../screen/receipt_screen.dart';


class ReceiptController extends GetxController {
  late UserModel user = UserModel(firstName: "", lastName: "", userName: "");
  final ConnectivityService _connectivityService = ConnectivityService();
  RxList<SaleInfoModel> allReceipts = <SaleInfoModel>[].obs;
  RxList<SaleInfoModel> tickets = <SaleInfoModel>[].obs;
  RxList<SaleInfoModel> filteredReceipts = <SaleInfoModel>[].obs;
  Rx<String> searchQuery = "".obs;
  var isInternetAccess = false.obs;
  late GetStorage box;
  PrinterService printerService = Get.put(PrinterService());
  final LocalStorageService _localStorageService = LocalStorageService();
  final TextEditingController startDateController = TextEditingController();

  final TextEditingController endDateController = TextEditingController();
  var todayDate = "".obs;
  var startDate = "".obs;
  var endDate = "".obs;
  final PrinterService _printerService = Get.put(PrinterService());
  RxList<BaseNameModel> categories = <BaseNameModel>[].obs;
  Rx<BaseNameModel?> selectedCategory = BaseNameModel().obs;
  var activeShift = ShiftModel().obs;
  var shiftAvailable = false.obs;
  List<ShiftModel>  shifts = [];
  var isCatSelected = false.obs;
  var isPrintClicked = false.obs;
  Rx<BranchModel?> branch = BranchModel().obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    box = GetStorage();
    var model = box.read(AppConstants.USER_INFO) ?? {};
    user = UserModel.fromMap(Map<String, dynamic>.from(model));
    isInternetAccess.value = await _connectivityService.checkServerConnection();
    var branchModel = box.read(AppConstants.SELECTED_BRANCH) ?? {};
    branch.value = BranchModel.fromMap(Map<String, dynamic>.from(branchModel));
    //getSales();
    // Get today's date in the required format

    todayDate.value = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").format(DateTime.now());
    List<BaseNameModel> catList = loadItems(box, AppConstants.CATEGORY_LIST);
    categories.value = catList;
    // Fetch sales for today's date
    await getSalesByDate(todayDate.value, todayDate.value, "", branch.value!.id!);
    shiftInfo();
  }

  getSales() {
    List<SaleInfoModel> sales = getExistingOfflineSales(box);
    allReceipts.value = sales.where((sale)=> sale.sale!.saleStatus!="ON_HOLD").toList();
    tickets.value = sales.where((sale)=> sale.sale!.saleStatus=="ON_HOLD").toList();
    filteredReceipts.value = sales.where((sale)=> sale.sale!.saleStatus!="ON_HOLD").toList();
    sortSalesByDate();
    allReceipts.refresh();
    filteredReceipts.refresh();
  }

  refreshFilter() async {
    await getSalesByDate(todayDate.value, todayDate.value, "", branch.value!.id!);
  }
  cancelFilter(){
    startDate.value = "";
    endDate.value = "";
    isCatSelected.value = false;
    selectedCategory.value = BaseNameModel();
    startDateController.text = "";
    endDateController.text = "";
  }

  List<ShiftModel> loadShifts( GetStorage box) {
    List<ShiftModel> list = _localStorageService.getOfflineList<ShiftModel>(
        AppConstants.SHIFT_LIST,
            (map) => ShiftModel.fromMap(map),
        box);
    return list;
  }

  shiftInfo() async {
    shifts = loadShifts(box);
    ShiftModel? tempActiveShift = await _localStorageService.getActiveShift(shifts, box, user, true);
    if(tempActiveShift != null) {
      activeShift.value = tempActiveShift;
      shiftAvailable.value = true;
      activeShift.value.shiftCurrencyAmounts?.sort((a, b) => a.timeCreated.compareTo(b.timeCreated));
    }
  }


  searchSales(){
    String categoryId = isCatSelected.value ? selectedCategory.value!.id! : "";
    getSalesByDate(startDate.value, endDate.value, categoryId, branch.value!.id!);
  }


  Future<void> getSalesByDate(String startDate, String endDate, String categoryId, String branchId) async{
    bool stat = await _connectivityService.checkServerConnection();
    if(stat) {
      List<SaleInfoModel> rawItems = getExistingOfflineSales(box);
      List<SaleInfoModel> items = [];
      for(SaleInfoModel s in rawItems){
        if(s.sale!.saleStatus=="ON_HOLD")
          tickets.add(s);
        if(!items.any((element) => element.sale!.posReference == s.sale!.posReference)) {
          items.add(s);
        }
      }

      List<SaleInfoModel> actualItems = [];
      actualItems = items.where((sale) => !sale.syncStatus!).toList();

      allReceipts.value = actualItems.where((sale)=> sale.sale!.saleStatus!="ON_HOLD").toList();
      filteredReceipts.value = actualItems.where((sale)=> sale.sale!.saleStatus!="ON_HOLD").toList();
      allReceipts.refresh();
      filteredReceipts.refresh();
        try {
        var response = await BaseHttpClient().getAuthWithCompanyHeader(
            "/sale/app-sale-filter?startDate=$startDate&endDate=$endDate&categoryId=$categoryId&branchId=$branchId", user.companyId!).catchError((
            onError) {
              print(onError);
          if (onError is BadRequestException) {
            var apiError = json.decode(onError.message!);
            AppHelper.showErroDialog(description: apiError["reason"]);
            print(apiError["reason"]);
          } else {
            AppHelper.handleError(onError);
          }
        });

        if (response != null) {
          List<dynamic> list = jsonDecode(response);
          List<SaleModel> itemsList = List<SaleModel>.from(list.map((i) => SaleModel.fromMap(i)));

          for (SaleModel sale in itemsList) {
            SaleInfoModel saleInfoModel = SaleInfoModel(
                sale: sale, syncStatus: true);
            if(!actualItems.any((element) => element.sale!.id == saleInfoModel.sale!.id || element.sale!.posReference==saleInfoModel.sale!.posReference)) {
              actualItems.add(saleInfoModel);
            }
            if(!items.any((element) => element.sale!.id == saleInfoModel.sale!.id)) {
              items.add(saleInfoModel);
            }
          }
          allReceipts.value = actualItems.where((sale)=> sale.sale!.saleStatus!="ON_HOLD").toList();
          filteredReceipts.value = actualItems.where((sale)=> sale.sale!.saleStatus!="ON_HOLD").toList();
          sortSalesByDate();
          allReceipts.refresh();
          filteredReceipts.refresh();
          List<Map<String, dynamic>> itemsListMap = items.map((item) =>
              item.toMap()).toList();
          box.write(AppConstants.SALE_LIST, itemsListMap);
        }
        AppHelper.hideLoading();
      } catch (e) {
        Get.snackbar('Error', 'Failed to fetch sales: $e',
            snackPosition: SnackPosition.BOTTOM);
      }
    } else{
      getSales();
    }
  }

  // REVERSE SALE
  Future<void> showConfirmDialogToDeleteItem(SaleInfoModel saleInfo, int index) async {
    bool userExists = await SyncService().showAuthenticationDialog(Get.context!);
    if(userExists) {
      AppHelper.showLoading();
      saleInfo.sale!.saleStatus = "REVERSED";
      saleInfo.syncStatus = !saleInfo.syncStatus!;
      var i = allReceipts.indexOf(saleInfo);
      allReceipts[i] = saleInfo;
      filteredReceipts[index].sale!.saleStatus = "REVERSED";
      allReceipts[i] = saleInfo;
      saveSales();
      allReceipts.refresh();
      filteredReceipts.refresh();
      var currencyAmount = activeShift.value.shiftCurrencyAmounts!
          .firstWhereOrNull((element) =>
              element.posReference == saleInfo.sale!.posReference ||
              element.posReference == saleInfo.sale!.referenceNumber);
      if (currencyAmount != null) {
        activeShift.value.shiftCurrencyAmounts?.remove(currencyAmount);
        ShiftModel temp = activeShift.value;
        List<ShiftModel> shi = _localStorageService.replaceShift(temp, shifts);
        _localStorageService.writeItems(AppConstants.SHIFT_LIST, shi, box);
      }
      AppHelper.hideLoading();
      Get.snackbar("Success", "Sale reversed");
    }

    List<ShiftModel> currentShifts = loadShifts(box);
    currentShifts.forEach((shift)=>{
      if(shift.id==activeShift.value.id){
        shift.shiftCurrencyAmounts!.forEach((currencyAmount)=>{
          print(currencyAmount.toJson())
        })
      }
    });

  }

  printSale(SaleInfoModel saleInfo) async{
    bool userExists = await SyncService().showAuthenticationDialog(Get.context!);
    if(userExists) {
      await _printerService.printCurrentSale(
          saleInfo, box, _localStorageService);
    }
    isPrintClicked.value = false;
  }
  void sortSalesByDate() {
    allReceipts.sort((a, b) {
      // Parse the dates
      DateTime dateA = DateTime.parse(a.sale!.timeIniated!);
      DateTime dateB = DateTime.parse(b.sale!.timeIniated!);

      // Compare dates for descending order
      return dateB.compareTo(dateA);
    });

    // Refresh the filtered list as well
    filteredReceipts.value = allReceipts.toList();
  }


  void filterReceipts(String query) {
    searchQuery.value = query;
    filteredReceipts.value = allReceipts.value.where((saleInfo) {
      final saleRef = saleInfo.sale!.referenceNumber!.toLowerCase() ?? '';
      final amt = saleInfo.sale!.saleCost.toString().toLowerCase() ?? '';
      final lowerQuery = query.toLowerCase();
      return saleRef.contains(lowerQuery) || amt.contains(lowerQuery);
    }).toList();
  }

  List<SaleInfoModel> getExistingOfflineSales(GetStorage box) {

    List<SaleInfoModel> sales = _localStorageService.getOfflineList<SaleInfoModel>(
        AppConstants.SALE_LIST,
            (map) => SaleInfoModel.fromMap(map),
        box);
    return sales;
  }

  saveSales(){
    List<SaleInfoModel> actualItems = [];
    for(var sale in allReceipts){
      actualItems.add(sale);
    }
    tickets.forEach((element) {
      if(!actualItems.any((actualItem)=>actualItem.sale!.referenceNumber==element.sale!.referenceNumber))
        actualItems.add(element);
    });
    List<Map<String, dynamic>> itemsListMap = actualItems.map((item) =>
        item.toMap()).toList();

    box.write(AppConstants.SALE_LIST, itemsListMap);
    allReceipts.value = actualItems;
    filteredReceipts.value = actualItems;
    allReceipts.refresh();
    filteredReceipts.refresh();
    getSales();
  }

  Map<String, double> calculateTotalByCurrency() {
    Map<String, double> totals = {};

    for (var saleInfo in filteredReceipts) {
      String? currencySymbol = saleInfo.sale?.currency?.symbol ?? '';
      double amountPaid = saleInfo.sale?.amountAfterDiscount ?? 0;
      if(saleInfo.sale!.saleStatus!= "REVERSED") {
        if (totals.containsKey(currencySymbol)) {
          totals[currencySymbol] = totals[currencySymbol]! + amountPaid;
        } else {
          totals[currencySymbol] = amountPaid;
        }
      }
    }

    return totals;
  }
  List<BaseNameModel> loadItems( GetStorage box, String itemType) {
    List<BaseNameModel> list = _localStorageService.getOfflineList<BaseNameModel>(
        itemType,
            (map) => BaseNameModel.fromMap(map),
        box);
    return list;
  }
}