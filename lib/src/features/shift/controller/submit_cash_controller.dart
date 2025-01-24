import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';
import 'package:vimbika_pos_app/src/constants/app_constants.dart';
import 'package:vimbika_pos_app/src/constants/app_routes.dart';
import 'package:vimbika_pos_app/src/features/shift/controller/shift_controller.dart';
import 'package:vimbika_pos_app/src/features/shift/model/currency_amount.dart';
import 'package:vimbika_pos_app/src/features/shift/model/shift_model.dart';
import 'package:vimbika_pos_app/src/services/local_storage_service.dart';
import 'package:vimbika_pos_app/src/services/printer_service.dart';
import 'package:vimbika_pos_app/src/shared/models/currency_model.dart';

class SubmitCashController extends GetxController {

  Rx<CurrencyModel?> selectedCurrency = CurrencyModel().obs;
  Rx<CurrencyModel?> baseCurrency = CurrencyModel().obs;
  RxList<CurrencyModel> currencyList = <CurrencyModel>[].obs;

  List<ShiftModel>  shifts = [];
  RxList<ShiftModel> shiftList = <ShiftModel>[].obs;
  var currencyAmountList = <CurrencyAmount>[].obs;
  var isCurrencySelected = false.obs;
  final LocalStorageService _localStorageService = LocalStorageService();
  final TextEditingController amountTextEditingController = TextEditingController();
  var activeShift = ShiftModel().obs;
  var shiftAvailable = false.obs;
  late GetStorage box;
  var totalAmountsByCurrency = <Map<String, dynamic>>[].obs;
  final PrinterService _printerService = Get.put(PrinterService());
  @override
  Future<void> onInit() async {
    super.onInit();
    box = GetStorage();

    List<CurrencyModel> tempList = loadCurrencies(box);
    currencyList.value = tempList;
    baseCurrency.value = _localStorageService.getBaseCurrency(currencyList);
    selectedCurrency.value = baseCurrency.value;
    isCurrencySelected.value = true;
    shiftInfo();
    // initCurrencies();

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
  shiftInfo(){

    shifts = loadShifts(box);
    shiftList.value = shifts;
    ShiftModel? tempActiveShift = _localStorageService.getActiveShift(shifts);
    if(tempActiveShift != null) {
      print("Updating shift");
      activeShift.value = tempActiveShift;
      shiftAvailable.value = true;
    }
  }

  void addCurrencyAmount(CurrencyModel currency) {
    DateTime now = DateTime.now();
    String timeInit = DateFormat(AppConstants.APP_DATE_TIME_FMT).format(now);
    int count = currencyAmountList.length + 1;
    String ref = AppConstants.getDateNowRef("CB_", count);
    List<CurrencyAmount> amts = [];
    amts.add(CurrencyAmount(
        currency: currency, // Use this as the main reference
        amountType: "CASH_SUBMIT",
        ref: ref,
        timeCreated: timeInit,
        shiftReference: activeShift.value.shiftReference,
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

  void showConfirmDialog() {
    Get.defaultDialog(
      title: "Confirmation",
      middleText: "Are you sure you want to proceed?",
      textCancel: "No",
      textConfirm: "Yes",
      onCancel: () {
        Get.back(); // Close the dialog
      },
      onConfirm: () {
        submitCash();
        Get.snackbar("Confirmed", "Cash submitted successfully");
      },
    );
  }

  void submitCash(){
    ShiftModel shift = activeShift.value;
    currencyAmountList.forEach((element) {
      shift.shiftCurrencyAmounts!.add(element);
    },);
    List<ShiftModel> updatedShifts = _localStorageService.replaceShift(shift, shiftList);
    _localStorageService.writeItems(AppConstants.SHIFT_LIST, updatedShifts, box);
    _printerService.printSunmiCashSubmitReceipt("CASH_SUBMIT", currencyAmountList);

    Get.delete<SubmitCashController>();
    Get.put(ShiftController());
    Get.offNamed(AppRoutes.VIEW_SHIFT);

  }
}