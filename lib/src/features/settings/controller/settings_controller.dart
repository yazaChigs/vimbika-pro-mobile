import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:vimbika_pos_app/src/constants/app_constants.dart';
import 'package:vimbika_pos_app/src/constants/app_routes.dart';
import 'package:vimbika_pos_app/src/features/sale/controller/cart_controller.dart';
import 'package:vimbika_pos_app/src/shared/models/currency_model.dart';
import 'package:vimbika_pos_app/src/shared/models/payment_type_model.dart';
import 'package:vimbika_pos_app/src/shared/models/company_model.dart';

import '../../../services/connectivity_service.dart';
import '../../../services/sync_service.dart';
import '../../authentication/model/user_model.dart';


class SettingsController extends GetxController {
  final CartController cartController = Get.find();
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

  @override
  void onInit() {
    super.onInit();
    box = GetStorage();
    isFiscalisationEnabled.value  = box.read(AppConstants.DEFAULT_FISCAL_SETTING) ?? false;
    useNfc.value  = box.read(AppConstants.USE_NFC) ?? false;
    defaultPaymentMethodId.value  = box.read(AppConstants.DEFAULT_PAYMENT_METHOD_ID) ?? "";
    List<PaymentTypeModel> tempList = getOfflinePaymentTypeList(box);
    paymentTypesList.value = tempList;
    defaultCurrencyId.value  = box.read(AppConstants.DEFAULT_CURRENCY_ID) ?? "";

    loadCurrencies(box);
  }

  void toggleDefaultFiscalSetting() {
    isFiscalisationEnabled.value = !isFiscalisationEnabled.value;
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
    cartController.selectedCurrency.value = currency;
    cartController.isCurrencySelected.value = true;
    cartController.calculateTotalAmounts(cartController.cartItems);
  }
  void setDefaultPaymentMethod(PaymentTypeModel paymentType) {
    defaultPaymentMethod.value = paymentType;
    defaultPaymentMethodId.value = paymentType.id!;
    box.write(AppConstants.DEFAULT_PAYMENT_METHOD_ID, paymentType.id);
    print(defaultPaymentMethodId);
    paymentTypesList.refresh(); // Notify the UI of changes
  }
  void saveFiscalSetting() {
    box.write(AppConstants.DEFAULT_FISCAL_SETTING, isFiscalisationEnabled.value);
    // Get.toNamed(AppRoutes.DEFAULT_FISCAL_SETTINGS);
    Get.back();
    Get.snackbar(
      'Settings Saved',
      'Your preference has been updated.',
      snackPosition: SnackPosition.BOTTOM,
    );

  }

  void testCompanyFields() {
    try {
      var companyData = box.read(AppConstants.ACTIVE_COMPANY);
      if (companyData != null && companyData is Map) {
        CompanyModel company = CompanyModel.fromMap(Map<String, dynamic>.from(companyData));
        
        // Build address from components
        List<String> addressParts = [];
        if (company.street != null && company.street!.isNotEmpty) addressParts.add(company.street!);
        if (company.stateProvince != null && company.stateProvince!.isNotEmpty) addressParts.add(company.stateProvince!);
        if (company.city != null && company.city!.isNotEmpty) addressParts.add(company.city!);
        String address = addressParts.isNotEmpty ? addressParts.join(' ') : 'Not available';
        
        // Show dialog with all company fields
        Get.dialog(
          AlertDialog(
            title: Text('Company Fields Test'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildFieldRow('ID', company.id ?? 'Not available'),
                  _buildFieldRow('Name', company.name ?? 'Not available'),
                  _buildFieldRow('Company ID (TIN)', company.companyID ?? 'Not available'),
                  _buildFieldRow('Street', company.street ?? 'Not available'),
                  _buildFieldRow('City', company.city ?? 'Not available'),
                  _buildFieldRow('State/Province', company.stateProvince ?? 'Not available'),
                  _buildFieldRow('Address (Combined)', address),
                  _buildFieldRow('Email', company.email ?? 'Not available'),
                  _buildFieldRow('Mobile Phone', company.mobilePhone ?? 'Not available'),
                  _buildFieldRow('Fiscalisation Enabled', company.fiscalisationEnabled?.toString() ?? 'Not available'),
                  _buildFieldRow('Logo', company.logo != null ? 'Available' : 'Not available'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: Text('Close'),
              ),
            ],
          ),
        );
      } else {
        Get.snackbar(
          'Error',
          'No company data found in storage',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to read company data: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Widget _buildFieldRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: value == 'Not available' ? Colors.red : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
