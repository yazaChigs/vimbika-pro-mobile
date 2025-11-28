
import 'dart:async';
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
import 'package:vimbika_pos_app/src/shared/models/payment_received_model.dart';

import '../../../services/app_exceptions.dart';
import '../../../services/background_service.dart';
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
  RxList<SaleInfoModel> reversedSales = <SaleInfoModel>[].obs;
  RxList<SaleInfoModel> offlineSales = <SaleInfoModel>[].obs;

  List<ShiftModel>  shifts = [];
  var currencyAmountList = <CurrencyAmount>[].obs;
  var isCurrencySelected = false.obs;
  final LocalStorageService _localStorageService = LocalStorageService();
  final TextEditingController amountTextEditingController = TextEditingController();
  final TextEditingController notesTextEditingController = TextEditingController();
  PrinterService printerService = Get.put(PrinterService());
  var activeShift = ShiftModel().obs;
  var shiftAvailable = false.obs;
  late GetStorage box;

  // Debouncer for close shift operation
  Timer? _closeShiftDebouncer;
  var isClosingShift = false.obs;
  bool _isClosingShift = false;

  // Debouncer for open shift operation
  Timer? _openShiftDebouncer;
  var isOpeningShift = false.obs;
  bool _isOpeningShift = false;

  // This will store the total amounts grouped by currency
  // final List<Map<String, dynamic>> totalAmountsByCurrency = [];
  var totalAmountsByCurrency = <Map<String, dynamic>>[].obs;
  var totalSales = <Map<String, dynamic>>[].obs;
  var totalTips = <Map<String, dynamic>>[].obs;
  var breakages = <Map<String, dynamic>>[].obs;
  var refundsList = <Map<String, dynamic>>[].obs;
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
  }

  getSales() {
    // Reload user to ensure we have the current logged-in user
    // This ensures calculations use the correct user's shift
    var model = box.read(AppConstants.USER_INFO) ?? {};
    if(model.isNotEmpty){
      user = UserModel.fromMap(Map<String, dynamic>.from(model));
    }
    
    // Note: activeShift should already be set correctly by shiftInfo() which is called before getSales()
    // But we ensure it's the current user's shift by reloading it if needed
    if(activeShift.value.shiftReference != null && activeShift.value.userId != null && user.id != null && activeShift.value.userId != user.id){
      // Shift doesn't belong to current user, reload it
      shifts = loadShifts(box);
      _localStorageService.getActiveShift(shifts, box, user, true).then((tempActiveShift) {
        if(tempActiveShift != null) {
          activeShift.value = tempActiveShift;
          shiftAvailable.value = true;
        }
        // Recalculate after shift is updated
        calculateTotalAmountsByCurrency();
        calculateTotalAmountsByPaymentType();
      });
    }
    
    List<SaleInfoModel> sales = getExistingOfflineSales(box);
    List<SaleInfoModel> actualSales = [];
    List<SaleInfoModel> otherSales = [];
    offlineSales.value = sales.where((sale)=> sale.syncStatus == false).toList();
    for(SaleInfoModel s in sales){
      if(s.sale!.saleStatus == "COMPLETE" || s.sale!.saleStatus == "PENDING"){
        if(!actualSales.any((sale)=> sale.sale!.posReference==s.sale!.posReference)) //filter duplicates
          actualSales.add(s);
      } else if(s.sale!.saleStatus == 'REVERSED'){
       otherSales.add(s);
      }
    }
    allReceipts.value = actualSales;
    reversedSales.value = otherSales;
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
    // Reload user to ensure we have the current logged-in user
    // This is critical when a user logs in after another user has logged out
    var model = box.read(AppConstants.USER_INFO) ?? {};
    if(model.isNotEmpty){
      user = UserModel.fromMap(Map<String, dynamic>.from(model));
      print("Shift Info: Loaded user ${user.userName} with ID ${user.id}");
    }

    shifts = loadShifts(box);
    ShiftModel? tempActiveShift = await _localStorageService.getActiveShift(shifts, box, user, true);
    if(tempActiveShift != null) {
      print("Shift Info: Found active shift ${tempActiveShift.shiftReference} for user ${user.userName} (ID: ${user.id})");
      print("Shift belongs to user ID: ${tempActiveShift.userId}");
      tempActiveShift.shiftCurrencyAmounts!.forEach((currencyAmount)=>
        print(currencyAmount.toJson())
      );
      activeShift.value = tempActiveShift;
      shiftAvailable.value = true;
      activeShift.value.shiftCurrencyAmounts?.sort((a, b) => a.timeCreated.compareTo(b.timeCreated));
    } else {
      print("Shift Info: No active shift found for user ${user.userName} (ID: ${user.id})");
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

  // Debounced open shift method
  void debouncedOpenShift() {
    _openShiftDebouncer?.cancel();
    
    if (_isOpeningShift) {
      Get.snackbar("Info", "Open shift operation in progress...",
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    
    _openShiftDebouncer = Timer(Duration(milliseconds: 500), () {
      _performOpenShift();
    });
  }

  // Internal method that performs the actual open shift
  Future<void> _performOpenShift() async {
    if (_isOpeningShift) return;
    
    _isOpeningShift = true;
    isOpeningShift.value = true;
    
    try {
      await openShift();
    } catch (e) {
      e.printError();
      Get.snackbar("Error", "Failed to open shift: ${e.toString()}",
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      _isOpeningShift = false;
      isOpeningShift.value = false;
    }
  }

  Future<void> openShift() async {
    // Reload user to ensure we have the current logged-in user
    // This is critical when a user logs in after another user has logged out
    var model = box.read(AppConstants.USER_INFO) ?? {};
    if(model.isNotEmpty){
      user = UserModel.fromMap(Map<String, dynamic>.from(model));
      print("Open Shift: Loaded user ${user.userName} with ID ${user.id}");
    }
    
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

    for (CurrencyAmount currencyAmount in activeShift.value.shiftCurrencyAmounts??[]) {
      final currencyId = currencyAmount.currency.id;
      if(allReceipts!=null && allReceipts.isNotEmpty) {
        var sale = allReceipts.firstWhere((sale) => currencyAmount.paymentType!.startsWith("CASH-") &&
          (sale.sale?.posReference == currencyAmount.posReference || sale.sale?.referenceNumber == currencyAmount.posReference) &&
            sale.sale?.currency?.id == currencyId && currencyAmount.amountType == "SALE",orElse: () => SaleInfoModel(sale: null,syncStatus: false)).sale;
        if(sale!=null){
          for(PaymentReceivedModel paymentReceived in sale.paymentTypes!){
            if(paymentReceived.paymentType!.name!.startsWith("CASH")){
              totals[currencyId!] = (totals[currencyId] ?? 0.0) + (paymentReceived.amount ?? 0.00);
            }
          }
        }
      }
       if ((currencyAmount.amountType == 'CASH_IN' && (currencyAmount.paymentType!.startsWith("CASH") || currencyAmount.paymentType!.startsWith("ACC") ))|| currencyAmount.amountType == 'OPENING_AMOUNT'){
        totals[currencyId!] = (totals[currencyId] ?? 0.0) + currencyAmount.amount;
      } else if (currencyAmount.amountType == 'CASH_OUT') {
        totals[currencyId!] = (totals[currencyId] ?? 0.0) - currencyAmount.amount;
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
    Map<String, double> tips = {};
    Map<String, double> breaks = {};
    Map<String, double> refunds = {};
    var sales = allReceipts.where((element) => element.sale?.shiftReference == activeShift.value.shiftReference);
    for (var sale in sales) {
      final currencyId = sale.sale!.currency!.id;
        if ((sale.sale?.saleStatus == 'COMPLETE' ||
                sale.sale?.saleStatus == 'PENDING') &&
            sale.sale?.shiftReference == activeShift.value.shiftReference) {
          for(var paymentReceived in sale.sale!.paymentTypes!) {
            final paymentTypeId = paymentReceived.paymentType?.id;
          totals[paymentTypeId!] = (totals[paymentTypeId] ?? 0.0) +
              (paymentReceived.amount ?? 0.0);
        }

          if(sale.sale!.tipAmount!=null && sale.sale!.tipAmount!>0) {
            tips[currencyId!] = (tips[currencyId] ?? 0.0) + sale.sale!.tipAmount!;
          }
      }
    }
    for (SaleInfoModel sale in reversedSales) {
      if (sale.sale?.shiftReference == activeShift.value.shiftReference) {
        print("Reversd reference ${sale.sale!.shiftReference}");
        for (var paymentReceived in sale.sale!.paymentTypes!) {
          final currencyId = paymentReceived.paymentType?.currency!.id;
          refunds[currencyId!] = (refunds[currencyId] ?? 0.0) +
              (paymentReceived.amount ?? 0.0);
        }
      }
    }
    for(CurrencyAmount currencyAmount in activeShift.value.shiftCurrencyAmounts??[]) {
      if (currencyAmount.amountType == "BREAKAGE") {
        SaleInfoModel sale = allReceipts.firstWhere((sale) => sale.sale!.posReference == currencyAmount.posReference);
        print(sale.sale!.toJson());
        sale.sale!.items!.forEach((item) {
          breaks[item.inventoryItem!.name!] = (breaks[item.inventoryItem!.name] ?? 0.0) + item.quantity!;
        });
      }
    }
    breakages.clear();
    totalAmountsByPaymentType.clear();
    totalTips.clear();
    refundsList.clear();

    tips.forEach((currencyId, total) {
      final currency = allReceipts
          .firstWhere((sale) => sale.sale!.currency!.id == currencyId).sale!
          .currency;
      totalTips.add({
        "currencyName": currency!.symbol,
        "totalAmount": total,
      });
    });
    refunds.forEach((currencyId, total) {
      final currency = reversedSales
          .firstWhere((sale) => sale.sale!.currency!.id == currencyId).sale!
          .currency;
      refundsList.add({
        "currencyName": currency!.symbol,
        "totalAmount": total,
      });
    });
    breaks.forEach((currencyId, total) {
      breakages.add({
        "name": currencyId,
        "qty": total,
      });
    });
    totals.forEach((paymentTypeId, total) {
      PaymentReceivedModel? paymentReceivedModel ;
      for(SaleInfoModel sale in allReceipts){
        if(sale.sale?.paymentTypes!.firstWhereOrNull((pt) => pt.paymentType?.id == paymentTypeId) != null){
          paymentReceivedModel = sale.sale!.paymentTypes!.firstWhere((pt) => pt.paymentType?.id == paymentTypeId);
          break;
        }
      }
      if(paymentReceivedModel!=null) {
        totalAmountsByPaymentType.add({
          "paymentTypeName":
              paymentReceivedModel.paymentType?.name ?? 'Unknown',
          "currencySymbol": paymentReceivedModel.paymentType!.currency?.symbol,
          "totalAmount": total,
        });
      }
    });
  }

  closeShift(){
    // Reload user to ensure we have the current logged-in user
    var model = box.read(AppConstants.USER_INFO) ?? {};
    if(model.isNotEmpty){
      user = UserModel.fromMap(Map<String, dynamic>.from(model));
      print("Close Shift: Loaded user ${user.userName} with ID ${user.id}");
    }
    
    // Verify the shift belongs to the current user before closing
    ShiftModel temp  = activeShift.value;
    if(temp.userId != null && user.id != null && temp.userId != user.id){
      Get.snackbar("Error", "Cannot close shift: This shift belongs to another user", snackPosition: SnackPosition.BOTTOM);
      return;
    }
    
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
    // Reload user to ensure we have the current logged-in user
    // This is critical when a user logs in after another user has logged out
    var model = box.read(AppConstants.USER_INFO) ?? {};
    if(model.isNotEmpty){
      user = UserModel.fromMap(Map<String, dynamic>.from(model));
      print("Close Active Shift: Loaded user ${user.userName} with ID ${user.id}");
    }
    
    // Verify the shift belongs to the current user before closing
    if(activeShift.value.userId != null && user.id != null && activeShift.value.userId != user.id){
      Get.snackbar("Error", "Cannot close shift: This shift belongs to another user", snackPosition: SnackPosition.BOTTOM);
      AppHelper.hideLoading();
      return;
    }
    
    List<SaleInfoModel> allSales = getExistingOfflineSales(box);
    offlineSales.value = allSales.where((sale)=> sale.syncStatus == false).toList();
    bool stat = await _connectivityService.checkServerConnection();
    // Allow closing shift even with unsynced sales - they will be preserved for later syncing
    AppHelper.showLoading();
    if(stat){
      if(!offlineSales.isEmpty)
        await BackgroundService().syncOfflineSales(false);
      await SyncService.savePaymentReceived(user, box);
      await SyncService.saveCustomer(user, box);
    }
    List<ShiftModel> itemsToBeSynced = [];
    ShiftModel temp = activeShift.value;
    DateTime now = DateTime.now();
    String closingTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
    temp.isShiftClosed = true;
    temp.active = true;
    temp.closingTime = closingTime;
    itemsToBeSynced.add(temp);

    String jsonShiftItems = json.encode(
        itemsToBeSynced.map((shift) => shift.toMap()).toList());
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

    List<ShiftModel> shi = _localStorageService.replaceShift(temp, shifts);
    _localStorageService.writeItems(AppConstants.SHIFT_LIST, shi, box);
    
    // Show message about unsynced sales if any
    if (!offlineSales.isEmpty) {
      Get.snackbar("Shift Closed", 
          "Shift closed successfully. ${offlineSales.length} unsynced sale(s) preserved for later syncing.",
          snackPosition: SnackPosition.BOTTOM);
    } else {
      Get.snackbar("Success", "Shift closed successfully",
          snackPosition: SnackPosition.BOTTOM);
    }
    
    SyncService.syncOfflineShifts(user, box);

    AppHelper.hideLoading();
    signOut();
  }
  void showConfirmDialogCloseShift() {
    // Prevent multiple dialogs
    if (_isClosingShift) {
      Get.snackbar("Info", "Close shift operation in progress...",
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    Get.defaultDialog(
      title: "Confirmation",
      middleText: "Are you sure you want to proceed?",
      textCancel: "No",
      textConfirm: "Yes",
      onCancel: () {
        Get.back(); // Close the dialog
      },
      onConfirm: () {
        Get.back(); // Close dialog first
        debouncedCloseShift();
      },
    );
  }

  // Debounced close shift method to prevent double-clicks
  void debouncedCloseShift() {
    _closeShiftDebouncer?.cancel();
    
    if (_isClosingShift) {
      Get.snackbar("Info", "Close shift operation in progress...",
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    
    _closeShiftDebouncer = Timer(Duration(milliseconds: 500), () {
      _performCloseShift();
    });
  }

  // Internal method that performs the actual close shift
  Future<void> _performCloseShift() async {
    if (_isClosingShift) return;
    
    _isClosingShift = true;
    isClosingShift.value = true;
    
    try {
      await closeActiveShift();
    } catch (e) {
      Get.snackbar("Error", "Failed to close shift: ${e.toString()}",
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      _isClosingShift = false;
      isClosingShift.value = false;
    }
  }

  void printShift(ShiftModel shift) async {
    GetStorage box = GetStorage();
    AvailablePrinterModel? ap = _localStorageService.findActivePrinter(box);
    if(ap != null) {
      if(ap.type == 'SUNMI_INBUILT_PRINTER') {
        await printerService.printShiftDetails(shift,allReceipts, totalAmountsByCurrency,totalAmountsByPaymentType,totalCashIn,
            totalCashOut, totalCashSubmittedList, totalSales,totalTips,breakages,refundsList);
      }
      if(ap.type == "bluetooth") {
        await printerService.printShiftDetailsBluetooth(shift, ap, totalAmountsByCurrency);
      }
      if(ap.type == "usb") {
        await printerService.printShiftDetailsUsb(shift, allReceipts, totalAmountsByCurrency, totalAmountsByPaymentType, totalCashIn,
            totalCashOut, totalCashSubmittedList, totalSales, totalTips, breakages, refundsList, ap);
      }
    }else{
      Get.snackbar('Error', 'Default Printer Not Found. Please add printer.', snackPosition: SnackPosition.BOTTOM);
      print("Default Printer Not Found. Please add printer.");
    }

  }

  void printShiftSummary(ShiftModel shift) async {
    GetStorage box = GetStorage();
    AvailablePrinterModel? ap = _localStorageService.findActivePrinter(box);
    if(ap != null) {
      if(ap.type == 'SUNMI_INBUILT_PRINTER') {
        await printerService.printShiftSummary(shift,allReceipts, totalAmountsByCurrency,totalAmountsByPaymentType,totalCashIn,
            totalCashOut, totalCashSubmittedList, totalSales,totalTips,breakages,refundsList);
      }
      if(ap.type == "bluetooth") {
        await printerService.printShiftDetailsBluetooth(shift, ap, totalAmountsByCurrency);
      }
      if(ap.type == "usb") {
        await printerService.printShiftSummaryUsb(shift, allReceipts, totalAmountsByCurrency, totalAmountsByPaymentType, totalCashIn,
            totalCashOut, totalCashSubmittedList, totalSales, totalTips, breakages, refundsList, ap);
      }
    }else{
      Get.snackbar('Error', 'Default Printer Not Found. Please add printer.', snackPosition: SnackPosition.BOTTOM);
      print("Default Printer Not Found. Please add printer.");
    }

  }


  signOut() async {
    GetStorage box = GetStorage();
    
    // Preserve unsynced sales for later syncing - only remove synced sales
    List<SaleInfoModel> allSales = getExistingOfflineSales(box);
    List<SaleInfoModel> unsyncedSales = allSales.where((sale) => sale.syncStatus == false).toList();
    
    if (unsyncedSales.isNotEmpty) {
      // Save only unsynced sales back to storage
      List<Map<String, dynamic>> unsyncedSalesMap = unsyncedSales.map((item) => item.toMap()).toList();
      box.write(AppConstants.SALE_LIST, unsyncedSalesMap);
      print("Preserved ${unsyncedSales.length} unsynced sale(s) for later syncing");
      
      // Preserve shifts that are referenced by unsynced sales
      // This allows shifts to be updated when sales are synced later
      // IMPORTANT: Merge with existing preserved shifts from other users to avoid overwriting them
      List<ShiftModel> allShifts = loadShifts(box);
      Set<String> shiftReferences = unsyncedSales
          .where((sale) => sale.sale?.shiftReference != null && sale.sale!.shiftReference!.isNotEmpty)
          .map((sale) => sale.sale!.shiftReference!)
          .toSet();
      
      if (shiftReferences.isNotEmpty) {
        // Get current user ID if not already set
        if(user.id == null){
          var model = box.read(AppConstants.USER_INFO) ?? {};
          user = UserModel.fromMap(Map<String, dynamic>.from(model));
        }
        
        // Find shifts that belong to the current user AND are referenced by unsynced sales
        List<ShiftModel> currentUserShiftsToPreserve = allShifts
            .where((shift) => 
                shiftReferences.contains(shift.shiftReference) &&
                shift.userId != null && 
                user.id != null && 
                shift.userId == user.id)
            .toList();
        
        // Find shifts from OTHER users that should be preserved (they have unsynced sales from previous logouts)
        // These are shifts that don't belong to current user but are in the existing preserved list
        List<ShiftModel> otherUsersPreservedShifts = allShifts
            .where((shift) => 
                shift.userId != null && 
                user.id != null && 
                shift.userId != user.id)
            .toList();
        
        // Merge current user's shifts with other users' preserved shifts
        List<ShiftModel> allShiftsToPreserve = [
          ...currentUserShiftsToPreserve,
          ...otherUsersPreservedShifts,
        ];
        
        if (allShiftsToPreserve.isNotEmpty) {
          List<Map<String, dynamic>> shiftsMap = allShiftsToPreserve.map((item) => item.toMap()).toList();
          box.write(AppConstants.SHIFT_LIST, shiftsMap);
          print("Preserved ${currentUserShiftsToPreserve.length} shift(s) for user ${user.id} and ${otherUsersPreservedShifts.length} shift(s) from other users");
        } else {
          box.remove(AppConstants.SHIFT_LIST);
        }
      } else {
        // No shift references in current user's unsynced sales
        // But we should preserve shifts from other users if they exist
        List<ShiftModel> otherUsersPreservedShifts = allShifts
            .where((shift) => 
                shift.userId != null && 
                user.id != null && 
                shift.userId != user.id)
            .toList();
        
        if (otherUsersPreservedShifts.isNotEmpty) {
          List<Map<String, dynamic>> shiftsMap = otherUsersPreservedShifts.map((item) => item.toMap()).toList();
          box.write(AppConstants.SHIFT_LIST, shiftsMap);
          print("Preserved ${otherUsersPreservedShifts.length} shift(s) from other users (no shifts for current user)");
        } else {
          box.remove(AppConstants.SHIFT_LIST);
        }
      }
    } else {
      // No unsynced sales, remove both sales and shifts
      box.remove(AppConstants.SALE_LIST);
      box.remove(AppConstants.SHIFT_LIST);
    }
    
    // Remove payment received data
    box.remove(AppConstants.PAYMENT_RECEIVED_LIST);
    
    // Remove access token and set authentication to false (user needs to login again)
    box.remove(AppConstants.CACHED_ACCESS_TOKEN);
    box.write(AppConstants.IS_AUTHENTICATED, false);
    
    // Note: USER_INFO, USER_PASSWORD, and IS_USER_INITIALLY_AUTHENTICATED are preserved
    // to allow offline login after closing shift
    
    // Clean up controllers
    Get.delete<SaleController>();
    Get.delete<BackgroundService>();
    
    // Navigate to login screen
    Get.offAllNamed(AppRoutes.LOGIN);
  }

  void addBreakage(CurrencyAmount currencyAmount, double value, String notes) {
    int count = activeShift.value.shiftCurrencyAmounts!.length + 1;
    String ref = AppConstants.getDateNowRef("BR_", count);
    CurrencyAmount breakage = CurrencyAmount(amount: value, currency: currencyAmount.currency, posReference: currencyAmount.posReference,
        amountType: 'BREAKAGE', ref: ref, timeCreated: DateTime.now().toIso8601String(), paymentType: currencyAmount.paymentType,
        shiftReference: currencyAmount.shiftReference, notes: notes);
    ShiftModel temp  = activeShift.value;
    temp.active = true;
      temp.shiftCurrencyAmounts!.firstWhereOrNull((ca)=>ca.posReference==currencyAmount.posReference)!.amount-=value;
      temp.shiftCurrencyAmounts!.add(breakage);
    List<ShiftModel> shi =  _localStorageService.replaceShift(temp, shifts);
    _localStorageService.writeItems(AppConstants.SHIFT_LIST, shi, box);
  }

  @override
  void onClose() {
    _closeShiftDebouncer?.cancel();
    _openShiftDebouncer?.cancel();
    super.onClose();
  }
}