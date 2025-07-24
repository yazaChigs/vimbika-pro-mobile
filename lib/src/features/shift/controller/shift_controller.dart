
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:vimbika_pos_app/src/constants/app_constants.dart';
import 'package:vimbika_pos_app/src/constants/app_routes.dart';
import 'package:vimbika_pos_app/src/features/authentication/model/user_model.dart';
import 'package:vimbika_pos_app/src/features/printers/model/available_printer_model.dart';
import 'package:vimbika_pos_app/src/features/sale/controller/cart_controller.dart';
import 'package:vimbika_pos_app/src/features/sale/controller/sale_controller.dart';
import 'package:vimbika_pos_app/src/features/shift/model/currency_amount.dart';
import 'package:vimbika_pos_app/src/features/shift/model/shift_model.dart';
import 'package:vimbika_pos_app/src/features/shift/model/shift_response_model.dart';
import 'package:vimbika_pos_app/src/services/local_storage_service.dart';
import 'package:vimbika_pos_app/src/services/printer_service.dart';
import 'package:vimbika_pos_app/src/services/sync_service.dart';
import 'package:vimbika_pos_app/src/shared/models/currency_model.dart';

import '../../../services/app_exceptions.dart';
import '../../../services/base_http_client.dart';
import '../../../services/connectivity_service.dart';
import '../../../utils/app_helper.dart';
import '../../sale/model/sale_infor_model.dart';

class ShiftController extends GetxController {
  late UserModel user = UserModel(id: null, firstName: "", lastName: "", userName: "");
  Rx<CurrencyModel?> selectedCurrency = CurrencyModel().obs;
  Rx<CurrencyModel?> baseCurrency = CurrencyModel().obs;
  final ConnectivityService _connectivityService = ConnectivityService();
  RxList<CurrencyModel> currencyList = <CurrencyModel>[].obs;
  RxList<SaleInfoModel> allReceipts = <SaleInfoModel>[].obs;

  List<ShiftModel>  shifts = [];
  var currencyAmountList = <CurrencyAmount>[].obs;
  var isCurrencySelected = false.obs;
  final LocalStorageService _localStorageService = LocalStorageService();
  final TextEditingController amountTextEditingController = TextEditingController();
  PrinterService printerService = Get.put(PrinterService());
  var activeShift = ShiftModel().obs;
  var shiftAvailable = false.obs;
  late GetStorage box;

  // This will store the total amounts grouped by currency
  // final List<Map<String, dynamic>> totalAmountsByCurrency = [];
  var totalAmountsByCurrency = <Map<String, dynamic>>[].obs;
  var totalSales = <Map<String, dynamic>>[].obs;
  var totalAmountsByPaymentType = <Map<String, dynamic>>[].obs;
  var totalCashIn = <Map<String, dynamic>>[].obs;
  var totalCashOut = <Map<String, dynamic>>[].obs;
  var totalCashSubmittedList = <Map<String, dynamic>>[].obs;
  @override
  Future<void> onInit() async {
    super.onInit();
     box = GetStorage();
    var model = box.read(AppConstants.USER_INFO) ?? {};
    user = UserModel.fromMap(Map<String, dynamic>.from(model));
    //print(user);
    List<CurrencyModel> tempList = loadCurrencies(box);
    currencyList.value = tempList;
    baseCurrency.value = _localStorageService.getBaseCurrency(currencyList);
    selectedCurrency.value = baseCurrency.value;
    isCurrencySelected.value = true;
    shiftInfo();
    // getSales(); //moved to shiftInfo
    // initCurrencies();

  }
  getSales() {
    List<SaleInfoModel> sales = getExistingOfflineSales(box);
    print("saels: ${sales.length}");
    List<SaleInfoModel> actualSales = [];
    for(SaleInfoModel s in sales){
      if(s.sale!.saleStatus == "COMPLETE" || s.sale!.saleStatus == "PENDING"){
        actualSales.add(s);
      }
    }
    allReceipts.value = actualSales;
    calculateTotalAmountsByCurrency();
    calculateTotalAmountsByPaymentType();
  }

  List<SaleInfoModel> getExistingOfflineSales(GetStorage box) {
    List<SaleInfoModel> sales = _localStorageService.getOfflineList<SaleInfoModel>(
        AppConstants.SALE_LIST,
            (map) => SaleInfoModel.fromMap(map),
        box);
    return sales;
  }

  initCurrencies(){
    currencyList.forEach((currency) {
      addCurrencyAmount(currency);
    },);
  }
  shiftInfo() async {

    shifts = loadShifts(box);
    ShiftModel? tempActiveShift = await _localStorageService.getActiveShift(shifts, box, user, true);
    if(tempActiveShift != null) {
      print("Updating shift..");
      activeShift.value = tempActiveShift;
      shiftAvailable.value = true;
      activeShift.value.shiftCurrencyAmounts?.sort((a, b) => a.timeCreated.compareTo(b.timeCreated));
      // calculateTotalAmountsByCurrency();
    }
    getSales();
  }
  List<CurrencyModel> loadCurrencies( GetStorage box) {
    List<CurrencyModel> currencies = _localStorageService.getOfflineList<CurrencyModel>(
      AppConstants.CURRENCY_LIST,
          (map) => CurrencyModel.fromMap(map),
    box);
    return currencies;
  }
  List<ShiftModel> loadShifts( GetStorage box) {
    List<ShiftModel> list = _localStorageService.getOfflineList<ShiftModel>(
        AppConstants.SHIFT_LIST,
            (map) => ShiftModel.fromMap(map),
        box);
    return list;
  }


  void addCurrencyAmount(CurrencyModel currency) {
    DateTime now = DateTime.now();
    String timeInit = DateFormat(AppConstants.APP_DATE_TIME_FMT).format(now);
    int count = currencyAmountList.length + 1;
    String ref = AppConstants.getDateNowRef("OA_", count);
    List<CurrencyAmount> amts = [];
    amts.add(CurrencyAmount(
      currency: currency, // Use this as the main reference
      amountType: "OPENING_AMOUNT",
      ref: ref,
      timeCreated: timeInit,
      shiftReference: null,
      amount: 0
    ));
    currencyAmountList.addAll(amts);
    currencyAmountList.refresh();
  }



  void removeCurrencyAmount(int index) {
    currencyAmountList.removeAt(index);
  }

  void updateAmount(int index, String newAmount) {
    double amount = 0.0;
    try {
      amount = double.parse(newAmount);
    } catch (e) {
      // Handle error or invalid input
    }
    currencyAmountList[index].amount = amount;
  }

  Future<void> openShift() async {
    String fullName = "${user.firstName} ${user.lastName}";
    DateTime now = DateTime.now();
    int shiftCount = shifts.length + 1;
    String ref = AppConstants.getDateNowRef("SF", shiftCount);
    String timeInit = DateFormat(AppConstants.APP_DATE_TIME_FMT).format(now);

    currencyAmountList.forEach((element) {
      element.shiftReference = ref;
      element.active = true;
    },);
    ShiftModel shiftModel = ShiftModel(userId: user.id, active: true, stopSync: false, userFullName: fullName, shiftCurrencyAmounts: currencyAmountList, openingTime: timeInit, company: user.company, shiftReference: ref, synced: false);
    activeShift.value = shiftModel;
    shifts.add(shiftModel);
    _localStorageService.writeItems(AppConstants.SHIFT_LIST, shifts, box);
    bool stat = await _connectivityService.checkServerConnection();
    if(stat) {
      await SyncService.syncOfflineShifts(user, box);
    }
    calculateTotalAmountsByCurrency();
    Get.offNamed(AppRoutes.VIEW_SHIFT);


  }

  void calculateTotalAmountsByCurrency() {
    Map<String, double> totals = {};
    Map<String, double> cashIns = {};
    Map<String, double> sales = {};
    Map<String, double> cashOuts = {};
    Map<String, double> totalCashSubmitted = {};

    for (var currencyAmount in activeShift.value.shiftCurrencyAmounts!) {
      final currencyId = currencyAmount.currency.id;
      bool isCash = false;
      if(allReceipts!=null && allReceipts.isNotEmpty) {
        // for(var sale in allReceipts) {
        //  print(sale.sale!.posReference!.toJson());
        // }
        var sale = allReceipts
            .firstWhere((sale) =>
        sale.sale?.posReference == currencyAmount.posReference &&
            sale.sale?.currency?.id == currencyId,orElse: () => SaleInfoModel(sale: null,syncStatus: false))
            .sale;
        if(sale!=null){
          isCash = sale.paymentType!
              .name!
              .startsWith("CASH") ?? false;
        }
        if(currencyAmount.amountType == 'CASH_IN' ||
            currencyAmount.amountType == 'OPENING_AMOUNT' ||
            currencyAmount.amountType == 'CASH_OUT') {
          isCash = true; // Default to true for these types
        }
        // else{
        //   isCash = true; // Default to true if no sale found
        // }

      }
       if (((currencyAmount.amountType == 'CASH_IN' || currencyAmount.amountType == 'OPENING_AMOUNT' || currencyAmount.amountType == 'SALE')
           && (isCash || currencyAmount.isCash! == true)) || (currencyAmount.paymentType!=null && currencyAmount.paymentType!.startsWith("CASH-"))) {
        totals[currencyId!] = (totals[currencyId] ?? 0.0) + currencyAmount.amount;
        print("Adding to totals: ${currencyAmount.amount} for currency: ${currencyAmount.currency.symbol}");
      } else if (currencyAmount.amountType == 'CASH_OUT') {
        totals[currencyId!] = (totals[currencyId] ?? 0.0) - currencyAmount.amount;
        print("Subtracting from totals: ${currencyAmount.amount} for currency: ${currencyAmount.currency.symbol}");
        cashOuts[currencyId] = (cashOuts[currencyId] ?? 0.0) + currencyAmount.amount;
      } else if (currencyAmount.amountType == 'CASH_SUBMIT') {
        totalCashSubmitted[currencyId!] = (totalCashSubmitted[currencyId] ?? 0.0) + currencyAmount.amount;
      }
      if (currencyAmount.amountType == 'CASH_IN') {
        cashIns[currencyId!] = (cashIns[currencyId] ?? 0.0) + currencyAmount.amount;
      }
      if (currencyAmount.amountType == 'SALE') {
        sales[currencyId!] = (sales[currencyId] ?? 0.0) + currencyAmount.amount;
      }
    }

    totalAmountsByCurrency.clear();
    totalSales.clear();
    totalCashIn.clear();
    totalCashOut.clear();
    totalCashSubmittedList.clear(); // Clear previous cash submitted data

    totalCashSubmitted.forEach((currencyId, total) {
      final currency = activeShift.value.shiftCurrencyAmounts!
          .firstWhere((amount) => amount.currency.id == currencyId)
          .currency;
      totalCashSubmittedList.add({
        "currencyName": currency.symbol,
        "totalAmount": total,
      });
    });

    totals.forEach((currencyId, total) {
      final currency = activeShift.value.shiftCurrencyAmounts!
          .firstWhere((amount) => amount.currency.id == currencyId)
          .currency;
      print("Currency: ${currency.symbol}, Total: $total, Cash Submitted: ${totalCashSubmitted[currencyId] ?? 0.0}");
      totalAmountsByCurrency.add({
        "currencyName": currency.symbol,
        "totalAmount": total-(totalCashSubmitted[currencyId] ?? 0.0),
      });
    });
    sales.forEach((currencyId, total) {
      final currency = activeShift.value.shiftCurrencyAmounts!
          .firstWhere((amount) => amount.currency.id == currencyId)
          .currency;
      totalSales.add({
        "currencyName": currency.symbol,
        "totalAmount": total,
      });
    });
    cashIns.forEach((currencyId, total) {
      final currency = activeShift.value.shiftCurrencyAmounts!
          .firstWhere((amount) => amount.currency.id == currencyId)
          .currency;
      totalCashIn.add({
        "currencyName": currency.symbol,
        "totalAmount": total,
      });
    });
    cashOuts.forEach((currencyId, total) {
      final currency = activeShift.value.shiftCurrencyAmounts!
          .firstWhere((amount) => amount.currency.id == currencyId)
          .currency;
      totalCashOut.add({
        "currencyName": currency.symbol,
        "totalAmount": total,
      });
    });
  }

  void calculateTotalAmountsByPaymentType() {
    Map<String, double> totals = {};
    for (var sale in allReceipts) {
      final paymentTypeId = sale.sale?.paymentType?.id;

      if ((sale.sale?.saleStatus == 'COMPLETE' || sale.sale?.saleStatus == 'PENDING') && sale.sale?.shiftReference==activeShift.value.shiftReference) {
        totals[paymentTypeId!] = (totals[paymentTypeId] ?? 0.0) + (sale.sale!.amountAfterDiscount ?? 0.0);
      }
    }
    totalAmountsByPaymentType.clear();
    totals.forEach((paymentTypeId, total) {
      final sale = allReceipts
          .firstWhere((sale) => sale.sale?.paymentType?.id == paymentTypeId)
          .sale;
      totalAmountsByPaymentType.add({
        "paymentTypeName": sale?.paymentType?.name ?? 'Unknown',
        "currencySymbol": sale?.currency?.symbol,
        "totalAmount": total,
      });
    });
  }




  closeShift(){
    ShiftModel temp  = activeShift.value;
    DateTime now = DateTime.now();
    String closingTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
    temp.isShiftClosed = true;
    temp.active = true;
    temp.closingTime = closingTime;
    List<ShiftModel> shi =  _localStorageService.replaceShift(temp, shifts);
    _localStorageService.writeItems(AppConstants.SHIFT_LIST, shi, box);
    Get.snackbar("Success", "Shift closed successfully", snackPosition: SnackPosition.BOTTOM);
    SyncService.syncOfflineShifts(user, box);
    Get.delete<ShiftController>();
    Get.delete<SaleController>();
    Get.delete<CartController>();
    Get.offNamed(AppRoutes.OPEN_SHIFT);
  }
  closeActiveShift() async {
    List<ShiftModel> itemsToBeSynced = [];
    ShiftModel temp  = activeShift.value;
    DateTime now = DateTime.now();
    String closingTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
    temp.isShiftClosed = true;
    temp.active = true;
    temp.closingTime = closingTime;
    itemsToBeSynced.add(temp);

    String jsonShiftItems = json.encode(
        itemsToBeSynced.map((shift) => shift.toMap()).toList());
    debugPrint("Shift items to be synced " + jsonShiftItems);
    debugPrint("Syncing shifts " + jsonShiftItems);
    var response = await BaseHttpClient()
        .postAuthWithCompanyHeader(
        "/mobile/pos/shift/save", jsonShiftItems, user.companyId!, "POST")
        .catchError((onError) {
      print(onError);
      AppHelper.hideLoading();
      if (onError is BadRequestException) {
        var apiError = json.decode(onError.message!);
        AppHelper.showErroDialog(description: apiError["reason"]);
      } else {
        AppHelper.handleError(onError);
      }
    });
    if (response != null) {
      // ShiftResponseModel saleResponseModel = ShiftResponseModel.fromJson(response);
      // updateItems.addAll(saleResponseModel.items ?? []);
      // updateItems.addAll(upToDateItems);
      // //List<ShiftModel> items =  saleResponseModel.items ?? [];
      //
      // List<Map<String, dynamic>> itemsListMap = updateItems.map((item) =>
      //     item.toMap()).toList();
      // box.write(AppConstants.SHIFT_LIST, itemsListMap);

      // Get.snackbar("Success", "Shifts synced successfully");
    } else {
      //Get.snackbar("Error", "No response from server");

    }

    List<ShiftModel> shi =  _localStorageService.replaceShift(temp, shifts);
    _localStorageService.writeItems(AppConstants.SHIFT_LIST, shi, box);
    Get.snackbar("Success", "Shift closed successfully", snackPosition: SnackPosition.BOTTOM);
    SyncService.syncOfflineShifts(user, box);
    Get.delete<ShiftController>();
    Get.delete<SaleController>();
    Get.delete<CartController>();
    Get.offNamed(AppRoutes.OPEN_SHIFT);
  }
  void showConfirmDialogCloseShift() {
    Get.defaultDialog(
      title: "Confirmation",
      middleText: "Are you sure you want to proceed?",
      textCancel: "No",
      textConfirm: "Yes",
      onCancel: () {
        Get.back(); // Close the dialog
      },
      onConfirm: () {
        closeActiveShift();

      },
    );
  }

  void printShift(ShiftModel shift) async {
    GetStorage box = GetStorage();
    AvailablePrinterModel? ap = _localStorageService.findActivePrinter(box);
    if(ap != null) {
      if(ap.type == 'SUNMI_INBUILT_PRINTER') {
        await printerService.printShiftDetails(shift,allReceipts, totalAmountsByCurrency,totalAmountsByPaymentType,totalCashIn, totalCashOut, totalCashSubmittedList);
      }
      if(ap.type == "bluetooth") {
        await printerService.printShiftDetailsBluetooth(shift, ap, totalAmountsByCurrency);
      }
      if(ap.type == "usb") {
        await printerService.printShiftDetailsUsb(shift, ap, totalAmountsByCurrency);
      }
    }else{
      Get.snackbar('Error', 'Default Printer Not Found. Please add printer.', snackPosition: SnackPosition.BOTTOM);
      print("Default Printer Not Found. Please add printer.");
    }

  }

}