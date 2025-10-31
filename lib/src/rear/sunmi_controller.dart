import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vimbika_pos_app/src/rear/sunmi_repository.dart';

import '../features/sale/model/cart_item_model.dart';
import '../features/sale/model/product_full_info_model.dart';
import '../features/sale/model/sale_model.dart';

import '../features/sale/model/sale_model.dart';
import '../shared/models/currency_model.dart';

class SunmiController extends GetxController {
  final SunmiRepository _repository = SunmiRepository();

  var cartItems = <CartItemModel>[].obs;
  var sale = <SaleModel>[].obs;
  // Reactive state variables
  final isHardwareReady = false.obs;
  final statusMessage = 'Initializing...'.obs;
  final isLoading = false.obs;
  RxString companyName = "VIMBIKA POS".obs;
  RxString currency = "USD".obs;
  RxString imageUrl = "assets/images/logo/logo.png".obs;
  RxList<String> items = <String>[].obs;

  Rx<CurrencyModel?> selectedCurrency = CurrencyModel().obs;
  Rx<CurrencyModel?> baseCurrency = CurrencyModel().obs;
  RxDouble totalCostInBaseCurrency = 0.0.obs;
  RxDouble totalCostInSelectedCurrency = 0.0.obs;
  RxDouble numberOfItems = 0.0.obs;
  RxDouble totalTaxInBaseCurrency = 0.0.obs;
  bool sellNilItems = false;
  RxDouble totalTaxInSelectedCurrency = 0.0.obs;
  RxDouble amountPaid = 0.0.obs;
  RxDouble paymentTypeAmountPaid = 0.0.obs;
  RxDouble customerAmountPaid = 0.0.obs;
  RxDouble change = 0.0.obs;


  @override
  void onInit() {
    _initializeSunmi();
    super.onInit();
  }

  @override
  void onClose() {
    _cleanUp();
    super.onClose();
  }

  /// Initialize Sunmi hardware
  Future<void> _initializeSunmi() async {
    isLoading.value = true;

    try {
      final bool isBound = await _repository.bindingPrinter();

      if (!isBound) {
        statusMessage.value = 'Failed to bind to Sunmi service';
        Get.snackbar('Error', 'Failed to bind to Sunmi service');
        isLoading.value = false;
        return;
      }

      await _repository.initializeHardware();
      isHardwareReady.value = true;
      statusMessage.value = 'Sunmi T2S Ready!';
    } catch (e) {
      statusMessage.value = 'Initialization error: $e';
      // Get.snackbar('Error', 'Initialization error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Display a welcome message on the rear screen
  Future<void> displayWelcome() async {
    if (!isHardwareReady.value) return;

    try {
      await _repository.sendTextToLcd('   WELCOME!   '.padRight(20));
      await _repository.sendTextToLcd(' Please tap card '.padRight(20));
    } catch (e) {
      Get.snackbar('Error', 'Failed to display message: $e');
    }
  }

  /// Display a transaction on the rear screen
  Future<void> displayTransaction(String itemName, double price) async {
    if (!isHardwareReady.value) return;

    try {
      // Format: "Item Name       $XX.XX"
      final line1 = itemName.padRight(16).substring(0, 16) +
          '\$${price.toStringAsFixed(2)}'.padLeft(4);
      await _repository.sendTextToLcd(line1);

      // Format: "TOTAL:          $XX.XX"
      final total = price.toStringAsFixed(2);
      final line2 = 'TOTAL:'.padRight(16) + '\$$total'.padLeft(4);
      await _repository.sendTextToLcd(line2);
    } catch (e) {
      Get.snackbar('Error', 'Failed to display transaction: $e');
    }
  }

  /// Clear the rear screen
  Future<void> clearDisplay() async {
    try {
      await _repository.clearLcd();
    } catch (e) {
      Get.snackbar('Error', 'Failed to clear display: $e');
    }
  }

  /// Clean up resources
  Future<void> _cleanUp() async {
    await clearDisplay();
    await _repository.unbindService();
  }


}
