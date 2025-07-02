

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';
import 'package:vimbika_pos_app/src/constants/app_constants.dart';
import 'package:vimbika_pos_app/src/constants/app_routes.dart';
import 'package:vimbika_pos_app/src/features/authentication/model/user_model.dart';
import 'package:vimbika_pos_app/src/features/shift/controller/shift_controller.dart';
import 'package:vimbika_pos_app/src/features/shift/model/currency_amount.dart';
import 'package:vimbika_pos_app/src/features/shift/model/shift_model.dart';
import 'package:vimbika_pos_app/src/features/shift/screen/pdf_preview_screen.dart';
import 'package:vimbika_pos_app/src/services/local_storage_service.dart';
import 'package:vimbika_pos_app/src/services/printer_service.dart';
import 'package:vimbika_pos_app/src/shared/models/currency_model.dart';
import 'package:pdf/widgets.dart' as pw;

class CashManagementController extends GetxController {
  Rx<CurrencyModel?> selectedCurrency = CurrencyModel().obs;
  RxList<CurrencyModel> currencyList = <CurrencyModel>[].obs;
  RxList<ShiftModel> shiftList = <ShiftModel>[].obs;
  GlobalKey<FormState> formKeyCashForm = GlobalKey<FormState>();
  var isCurrencySelected = false.obs;
  final LocalStorageService _localStorageService = LocalStorageService();
  final TextEditingController amountTextEditingController = TextEditingController();
  RxDouble amount = 0.0.obs;
  var activeShift = ShiftModel();
  var shiftAvailable = false.obs;
  var comments = "".obs;
  late GetStorage box;
  var shouldViewReceipt = false.obs;
  final PrinterService _printerService = Get.put(PrinterService());
  Rx<UserModel?> user = UserModel(firstName: "", lastName: "", userName: "").obs;
  @override
  Future<void> onInit() async {
    super.onInit();
     box = GetStorage();
    var model = box.read(AppConstants.USER_INFO) ?? {};
    user.value = UserModel.fromMap(Map<String, dynamic>.from(model));
    List<ShiftModel> tempShiftList = loadShifts(box);
    shiftList.value = tempShiftList;
    ShiftModel? tempActiveShift = await _localStorageService.getActiveShift(tempShiftList, box, user.value!, true);
    if(tempActiveShift != null) {
      activeShift = tempActiveShift;
      shiftAvailable.value = true;
    }
    List<CurrencyModel> tempList = loadCurrencies(box);
    currencyList.value = tempList;
    isCurrencySelected.value = false;
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
  onCurrencyChange(CurrencyModel newValue){
    isCurrencySelected.value = true;
    selectedCurrency.value = newValue;
  }

  payInPayOut(String payType){

    if(shiftAvailable.isFalse){
      Get.snackbar("Error", "No active shift is found!");
    }
    else{
      showConfirmDialog(payType);
    }


  }
  payInPayOutAction(String payType){

    String timeCreated = DateFormat(AppConstants.APP_DATE_TIME_FMT).format(DateTime.now());
    int count = activeShift.shiftCurrencyAmounts!.length + 1;
    print(activeShift.toJson());
    String ref = AppConstants.getDateNowRef(payType+"_", count);
    CurrencyAmount currencyAmount = CurrencyAmount(currency: selectedCurrency.value!, amountType: payType, ref: ref, timeCreated: timeCreated, notes: comments.value, amount: amount.value, shiftReference: activeShift.shiftReference);
    activeShift.shiftCurrencyAmounts!.add(currencyAmount);
    List<ShiftModel> updatedShifts = _localStorageService.replaceShift(activeShift, shiftList);
    _localStorageService.writeItems(AppConstants.SHIFT_LIST, updatedShifts, box);

    Get.delete<CashManagementController>();
    Get.put(ShiftController());
    Get.offNamed(AppRoutes.VIEW_SHIFT);
    if (shouldViewReceipt.value) {
      viewOrPrintReceipt(payType);
    }

  }

  void showConfirmDialog(String payType) {
    Get.defaultDialog(
      title: "Confirmation",
      middleText: "Are you sure you want to proceed?",
      textCancel: "No",
      textConfirm: "Yes",
      onCancel: () {
        Get.back(); // Close the dialog
      },
      onConfirm: () {
        payInPayOutAction(payType);
        Get.snackbar("Confirmed", "${payType} is confirmed");
      },
    );
  }

  void viewOrPrintReceipt(String transactionType) {
    _printerService.printSunmiCashManagementReceipt(transactionType, selectedCurrency.value!, amount.value, comments.value);
    // final pdf = generateReceipt(transactionType);
    // Get.to(() => PdfPreviewScreen(pdf: pdf));
  }

  Future<Uint8List> generateReceipt(String transactionType) async {
    final pdf = pw.Document();
// Define a custom page format for thermal receipt size (e.g., 80mm x 200mm)
    final PdfPageFormat receiptPageFormat = PdfPageFormat(
      80 * PdfPageFormat.mm, // 80mm width
      200 * PdfPageFormat.mm, // Adjustable height
      marginAll: 5 * PdfPageFormat.mm, // Small margin
    );
    pdf.addPage(
      pw.Page(
        pageFormat: receiptPageFormat,
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("Receipt", style: pw.TextStyle(fontSize: 24)),
            pw.SizedBox(height: 16),
            pw.Text("Transaction Type: $transactionType"),
            pw.Text("Currency: ${selectedCurrency.value?.name ?? 'N/A'}"),
            pw.Text("Amount: ${amount.value}"),
            pw.Text("Comments: ${comments.value}"),
            pw.SizedBox(height: 16),
            pw.Text("Thank you for using our service!"),
          ],
        ),
      ),
    );

    return pdf.save();
  }
// Generate a PDF receipt based on transaction type



}