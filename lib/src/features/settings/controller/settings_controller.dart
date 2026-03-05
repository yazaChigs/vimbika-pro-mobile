import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:vimbika_pos_app/src/constants/app_constants.dart';
import 'package:vimbika_pos_app/src/constants/app_routes.dart';
import 'package:vimbika_pos_app/src/features/sale/controller/cart_controller.dart';
import 'package:vimbika_pos_app/src/shared/models/branch_model.dart';
import 'package:vimbika_pos_app/src/shared/models/currency_model.dart';
import 'package:vimbika_pos_app/src/shared/models/payment_type_model.dart';

import '../../../services/connectivity_service.dart';
import '../../../services/sync_service.dart';
import '../../authentication/model/user_model.dart';


class SettingsController extends GetxController {
  CartController? get cartController {
    try {
      return Get.find<CartController>();
    } catch (e) {
      // CartController not found, create it if needed
      return Get.put(CartController());
    }
  }
  RxList<CurrencyModel> currencyList = <CurrencyModel>[].obs;
  RxList<PaymentTypeModel> paymentTypesList = <PaymentTypeModel>[].obs;

  // Default currency (tracked for UI updates)
  Rxn<CurrencyModel> defaultCurrency = Rxn<CurrencyModel>();
  Rxn<PaymentTypeModel> defaultPaymentMethod = Rxn<PaymentTypeModel>();
  late  GetStorage box;
  var defaultCurrencyId = "".obs;
  var defaultPaymentMethodId = "".obs;
  RxBool isFiscalisationEnabled = false.obs;
  RxBool useNfc = false.obs;
  RxBool isDarkModeEnabled = false.obs;

  // Debouncer for save fiscal setting operation
  Timer? _saveFiscalDebouncer;
  var isSaving = false.obs;
  bool _isSaving = false;
  BranchModel selectedBranch = BranchModel();
  late UserModel user = UserModel(firstName: "", lastName: "", userName: "");

  @override
  void onInit() {
    super.onInit();
    box = GetStorage();
    useNfc.value  = box.read(AppConstants.USE_NFC) ?? false;
    isDarkModeEnabled.value = box.read(AppConstants.THEME_MODE) ?? false;
    defaultPaymentMethodId.value  = box.read(AppConstants.DEFAULT_PAYMENT_METHOD_ID) ?? "";
    List<PaymentTypeModel> tempList = getOfflinePaymentTypeList(box);
    paymentTypesList.value = tempList;
    defaultCurrencyId.value  = box.read(AppConstants.DEFAULT_CURRENCY_ID) ?? "";
    var model = box.read(AppConstants.USER_INFO) ?? {};
    user = UserModel.fromMap(Map<String, dynamic>.from(model));

    var branch = box.read(AppConstants.SELECTED_BRANCH);

    selectedBranch = BranchModel.fromMap(Map<String, dynamic>.from(branch));
    isFiscalisationEnabled.value  = selectedBranch!.alwaysFiscalize!;

    loadCurrencies(box);
  }

  void toggleDefaultFiscalSetting() {
    selectedBranch!.alwaysFiscalize = !selectedBranch!.alwaysFiscalize!;
    isFiscalisationEnabled.value = selectedBranch!.alwaysFiscalize!;
    box.write(AppConstants.SELECTED_BRANCH, selectedBranch!.toMap());

    SyncService.saveBranch(selectedBranch!, user, box);
  }
  void toggleUseNfcSetting() {
    useNfc.value = !useNfc.value;
    box.write(AppConstants.USE_NFC, useNfc.value);
    Get.snackbar(
      'Settings Saved',
      'Your preference has been updated.',
      snackPosition: SnackPosition.BOTTOM,
    );

  }

  void toggleDarkMode() {
    isDarkModeEnabled.value = !isDarkModeEnabled.value;
    box.write(AppConstants.THEME_MODE, isDarkModeEnabled.value);
    Get.changeThemeMode(isDarkModeEnabled.value ? ThemeMode.dark : ThemeMode.light);
    Get.snackbar(
      'Settings Saved',
      'Dark mode has been ${isDarkModeEnabled.value ? "enabled" : "disabled"}.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

   loadCurrencies(GetStorage box) {
    // Read the data as a List<dynamic>
    List<dynamic>? itemsListDynamic = box.read<List<dynamic>>(AppConstants.CURRENCY_LIST);
    // Check if the read data is not null
    if (itemsListDynamic != null) {
      // Convert the List<dynamic> to List<Map<String, dynamic>>
      List<Map<String, dynamic>> itemsListMap = itemsListDynamic.map((item) {
        return item as Map<String, dynamic>;
      }).toList();
      List<CurrencyModel> currencies   =  List<CurrencyModel>.from(itemsListMap.map((map) => CurrencyModel.fromMap(map)));
      currencyList.value = currencies;
      for(var cur in currencies)  {
        if(defaultCurrencyId.value == cur.id){
          defaultCurrency.value = cur;
          break;
        }
        if(cur.isBaseCurrency!){
          defaultCurrency.value = cur;
        }
      }
    }
  }
  List<PaymentTypeModel> getOfflinePaymentTypeList(GetStorage box) {
    // Read the data as a List<dynamic>
    List<dynamic>? itemsListDynamic = box.read<List<dynamic>>(AppConstants.PAYMENT_TYPE_LIST);
    // Check if the read data is not null
    if (itemsListDynamic != null) {
      // Convert the List<dynamic> to List<Map<String, dynamic>>
      List<Map<String, dynamic>> itemsListMap = itemsListDynamic.map((item) {
        return item as Map<String, dynamic>;
      }).toList();
      List<PaymentTypeModel> list   = List<PaymentTypeModel>.from(itemsListMap.map((map) => PaymentTypeModel.fromMap(map)));
      for(var cur in list)  {
        if(defaultPaymentMethodId.value == cur.id){
          defaultPaymentMethod.value = cur;
          break;
        }

      }
      return list;
    } else {
      return [];
    }
  }


  void setDefaultCurrency(CurrencyModel currency) {
    defaultCurrency.value = currency;
    defaultCurrencyId.value = currency.id!;
    box.write(AppConstants.DEFAULT_CURRENCY_ID, currency.id);
    currencyList.refresh(); // Notify the UI of changes
    // Only update CartController if it exists (may not exist immediately after shift close)
    try {
      CartController? cartCtrl = cartController;
      if (cartCtrl != null) {
        cartCtrl.selectedCurrency.value = currency;
        cartCtrl.isCurrencySelected.value = true;
        cartCtrl.calculateTotalAmounts(cartCtrl.cartItems);
      }
    } catch (e) {
      // CartController not available, skip update (will be updated when sale screen loads)
      print("CartController not available for currency update: $e");
    }
  }
  void setDefaultPaymentMethod(PaymentTypeModel paymentType) {
    defaultPaymentMethod.value = paymentType;
    defaultPaymentMethodId.value = paymentType.id!;
    box.write(AppConstants.DEFAULT_PAYMENT_METHOD_ID, paymentType.id);
    print(defaultPaymentMethodId);
    paymentTypesList.refresh(); // Notify the UI of changes
  }
  // Debounced save fiscal setting method
  void debouncedSaveFiscalSetting() {
    _saveFiscalDebouncer?.cancel();
    
    if (_isSaving) {
      Get.snackbar("Info", "Save operation in progress...",
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    
    _saveFiscalDebouncer = Timer(Duration(milliseconds: 500), () {
      _performSaveFiscalSetting();
    });
  }

  // Internal method that performs the actual save
  void _performSaveFiscalSetting() {
    if (_isSaving) return;
    
    _isSaving = true;
    isSaving.value = true;
    
    try {
      saveFiscalSetting();
    } catch (e) {
      Get.snackbar("Error", "Failed to save settings: ${e.toString()}",
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      _isSaving = false;
      isSaving.value = false;
    }
  }

  void saveFiscalSetting() {
    box.write(AppConstants.DEFAULT_FISCAL_SETTING, isFiscalisationEnabled.value);
    Get.back();
    Get.snackbar(
      'Settings Saved',
      'Your preference has been updated.',
      snackPosition: SnackPosition.BOTTOM,
    );

  }

  @override
  void onClose() {
    _saveFiscalDebouncer?.cancel();
    super.onClose();
  }

}
