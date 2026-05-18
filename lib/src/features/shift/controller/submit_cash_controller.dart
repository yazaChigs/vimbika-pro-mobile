import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';
import 'package:vimbika_pos_app/src/constants/app_constants.dart';
import 'package:vimbika_pos_app/src/constants/app_routes.dart';
import 'package:vimbika_pos_app/src/features/authentication/model/user_model.dart';
import 'package:vimbika_pos_app/src/features/shift/controller/shift_controller.dart';
import 'package:vimbika_pos_app/src/features/shift/model/currency_amount.dart';
import 'package:vimbika_pos_app/src/features/shift/model/shift_model.dart';
import 'package:vimbika_pos_app/src/services/local_storage_service.dart';
import 'package:vimbika_pos_app/src/services/printer_service.dart';
import 'package:vimbika_pos_app/src/shared/models/currency_model.dart';

import '../../../services/backup_service.dart';
import '../../../services/sync_service.dart';

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
  var cashSubmitCLicked = false.obs;
  late GetStorage box;

  // Debouncer for submit cash operation
  Timer? _submitCashDebouncer;
  var isSubmitting = false.obs;
  bool _isSubmitting = false;
  var totalAmountsByCurrency = <Map<String, dynamic>>[].obs;
  final PrinterService _printerService = Get.put(PrinterService());
  Rx<UserModel?> user = UserModel(firstName: "", lastName: "", userName: "").obs;
  @override
  Future<void> onInit() async {
    super.onInit();
    box = GetStorage();
    var model = box.read(AppConstants.USER_INFO) ?? {};
    user.value = UserModel.fromMap(Map<String, dynamic>.from(model));

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
  shiftInfo() async {
    // Reload user to ensure we have the current logged-in user
    var model = box.read(AppConstants.USER_INFO) ?? {};
    if(model.isNotEmpty){
      user.value = UserModel.fromMap(Map<String, dynamic>.from(model));
      print("Submit Cash: Loaded user ${user.value!.userName} with ID ${user.value!.id}");
    }

    shifts = loadShifts(box);
    shiftList.value = shifts;
    ShiftModel? tempActiveShift = await _localStorageService.getActiveShift(shifts, box, user.value!, true);
    if(tempActiveShift != null) {
      print("Submit Cash: Found active shift ${tempActiveShift.shiftReference} for user ${user.value!.userName} (ID: ${user.value!.id})");
      activeShift.value = tempActiveShift;
      shiftAvailable.value = true;
    } else {
      print("Submit Cash: No active shift found for user ${user.value!.userName} (ID: ${user.value!.id})");
    }
  }

  void addCurrencyAmount(CurrencyModel currency) async {
    // Reload user and shift to ensure we have the current user's shift
    var model = box.read(AppConstants.USER_INFO) ?? {};
    if(model.isNotEmpty){
      user.value = UserModel.fromMap(Map<String, dynamic>.from(model));
    }
    
    // Reload shifts and get the active shift for the current user
    shifts = loadShifts(box);
    shiftList.value = shifts;
    ShiftModel? tempActiveShift = await _localStorageService.getActiveShift(shifts, box, user.value!, true);
    if(tempActiveShift != null) {
      activeShift.value = tempActiveShift;
      shiftAvailable.value = true;
      print("Add Currency Amount: Using shift ${activeShift.value.shiftReference} for user ${user.value!.userName} (ID: ${user.value!.id})");
    } else {
      print("Add Currency Amount: No active shift found for user ${user.value!.userName} (ID: ${user.value!.id})");
      Get.snackbar("Error", "No active shift found!", snackPosition: SnackPosition.BOTTOM);
      return;
    }
    
    DateTime now = DateTime.now();
    String timeInit = DateFormat(AppConstants.APP_DATE_TIME_FMT).format(now);
    int count = currencyAmountList.length + 1;
    String ref = AppConstants.getDateNowRef("CB_", count);
    List<CurrencyAmount> amts = [];
    amts.add(CurrencyAmount(
        currency: currency, // Use this as the main reference
        amountType: "CASH_SUBMIT",
        paymentType: "CASH_SUBMIT-${currency.name}",
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
    // Prevent multiple dialogs
    if (_isSubmitting) {
      Get.snackbar("Info", "Submit cash operation in progress...",
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
        debouncedSubmitCash();
      },
    );
  }

  // Debounced submit cash method
  void debouncedSubmitCash() {
    _submitCashDebouncer?.cancel();
    
    if (_isSubmitting) {
      Get.snackbar("Info", "Submit cash operation in progress...",
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    
    _submitCashDebouncer = Timer(Duration(milliseconds: 500), () {
      _performSubmitCash();
    });
  }

  // Internal method that performs the actual submit cash
  Future<void> _performSubmitCash() async {
    if (_isSubmitting) return;
    
    _isSubmitting = true;
    isSubmitting.value = true;
    
    try {
      if(cashSubmitCLicked.isFalse) {
        cashSubmitCLicked.value = true;
        await submitCash();
        await openCashDrawer();
        Get.snackbar("Confirmed", "Cash submitted successfully");
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to submit cash: ${e.toString()}",
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      _isSubmitting = false;
      isSubmitting.value = false;
    }
  }


  Future<void> openCashDrawer() async {
    try {
      await SunmiPrinter.openDrawer();
    } catch (e) {
      debugPrint("Error opening cash drawer: $e");
    }
  }

  Future<void> submitCash() async {
    // Reload user and shift to ensure we have the current user's shift
    var model = box.read(AppConstants.USER_INFO) ?? {};
    if(model.isNotEmpty){
      user.value = UserModel.fromMap(Map<String, dynamic>.from(model));
    }
    
    // Reload shifts and get the active shift for the current user
    shifts = loadShifts(box);
    shiftList.value = shifts;
    ShiftModel? tempActiveShift = await _localStorageService.getActiveShift(shifts, box, user.value!, true);
    if(tempActiveShift != null) {
      activeShift.value = tempActiveShift;
      shiftAvailable.value = true;
      print("Submit Cash: Using shift ${activeShift.value.shiftReference} for user ${user.value!.userName} (ID: ${user.value!.id})");
    } else {
      print("Submit Cash: No active shift found for user ${user.value!.userName} (ID: ${user.value!.id})");
      Get.snackbar("Error", "No active shift found!", snackPosition: SnackPosition.BOTTOM);
      return;
    }
    
    ShiftModel shift = activeShift.value;
    currencyAmountList.forEach((element) {
      shift.shiftCurrencyAmounts!.add(element);
    },);
    List<ShiftModel> updatedShifts = _localStorageService.replaceShift(shift, shiftList);
    _localStorageService.writeItems(AppConstants.SHIFT_LIST, updatedShifts, box);
    
    // Backup the shift to Excel (CSV)
    BackupService.backupShiftToCsv(shift);
    
    _printerService.printSunmiCashSubmitReceipt("CASH_SUBMIT", currencyAmountList);
    await SyncService.syncOfflineShifts(user.value!, box);

    Get.delete<SubmitCashController>();
    Get.put(ShiftController());
    Get.offNamed(AppRoutes.VIEW_SHIFT);

  }

  @override
  void onClose() {
    _submitCashDebouncer?.cancel();
    super.onClose();
  }
}