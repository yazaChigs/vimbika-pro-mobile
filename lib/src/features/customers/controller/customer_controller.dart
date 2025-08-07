import 'dart:convert';
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';
import 'package:vimbika_pos_app/src/constants/app_constants.dart';
import 'package:vimbika_pos_app/src/features/authentication/model/user_model.dart';
import 'package:vimbika_pos_app/src/features/customers/model/customer_currency_amount.dart';
import 'package:vimbika_pos_app/src/services/connectivity_service.dart';
import 'package:vimbika_pos_app/src/services/local_storage_service.dart';
import 'package:vimbika_pos_app/src/shared/models/base_name_model.dart';
import 'package:vimbika_pos_app/src/shared/models/customer_model.dart';

import '../../../services/app_exceptions.dart';
import '../../../services/base_http_client.dart';
import '../../../shared/models/bank_model.dart';
import '../../../shared/models/branch_model.dart';
import '../../../shared/models/currency_model.dart';
import '../../../shared/models/payment_received_model.dart';
import '../../../shared/models/payment_type_model.dart';
import '../../../utils/app_helper.dart';
import '../../sale/controller/cart_controller.dart';

class CustomerController extends GetxController {
  late UserModel user = UserModel(firstName: "", lastName: "", userName: "");
  final ConnectivityService _connectivityService = ConnectivityService();
  RxList<CustomerModel> allCustomers = <CustomerModel>[].obs;
  RxList<CustomerModel> filteredCustomers = <CustomerModel>[].obs;
  Rx<String> searchQuery = "".obs;
  var isInternetAccess = false.obs;
  var editCustomer = false.obs;
  RxList<CurrencyModel> currencyList = <CurrencyModel>[].obs;
  Rx<CurrencyModel?> selectedCurrency = CurrencyModel().obs;
  var isCurrencySelected = false.obs;
  Rx<PaymentTypeModel?> selectedPaymentType = PaymentTypeModel().obs;
  RxList<PaymentTypeModel> selectedPaymentTypes = <PaymentTypeModel>[].obs;
  Rx<BankModel?> selectedBank = BankModel().obs;
  RxList<PaymentReceivedModel> paymentReceivedList = <PaymentReceivedModel>[].obs;
  RxList<PaymentTypeModel> paymentTypesList = <PaymentTypeModel>[].obs;
  RxList<PaymentTypeModel> filteredPaymentTypesList = <PaymentTypeModel>[].obs;
  var isPaymentTypeSelected = false.obs;
  final TextEditingController amountPaidTextEditingController = TextEditingController();
  RxDouble totalCostInBaseCurrency = 0.0.obs;
  RxDouble totalCostInSelectedCurrency = 0.0.obs;
  RxDouble totalTaxInBaseCurrency = 0.0.obs;
  RxDouble totalTaxInSelectedCurrency = 0.0.obs;
  RxDouble amountPaid = 0.0.obs;
  RxDouble paymentTypeAmountPaid = 0.0.obs;
  RxDouble customerAmountPaid = 0.0.obs;
  RxDouble change = 0.0.obs;
  late GetStorage box;
  final LocalStorageService _localStorageService = LocalStorageService();
  final TextEditingController nameEditingController = TextEditingController();
  final TextEditingController payAccAmtEditingController = TextEditingController();
  final TextEditingController accNoEditingController = TextEditingController();
  final TextEditingController mobileNumberEditingController = TextEditingController();
  final TextEditingController emailEditingController = TextEditingController();
  final TextEditingController descriptionEditingController = TextEditingController();
  final TextEditingController vatEditingController = TextEditingController();
  final TextEditingController tinEditingController = TextEditingController();
  final TextEditingController addressEditingController = TextEditingController();
  final CartController cartController = Get.put(CartController());
  Rx<CustomerModel?> selectedCustomer = CustomerModel().obs;
  var payAccAMt = 0.00.obs;
  var name = "".obs;
  var mobilePhone = "".obs;
  var accountNumber = "".obs;
  var email = "".obs;
  var description = "".obs;
  Rx<CurrencyModel?> baseCurrency = CurrencyModel().obs;

  var vat = "".obs;
  var tin = "".obs;
  var address = "".obs;
  GlobalKey<FormState> formKeyForm = GlobalKey<FormState>();


  @override
  Future<void> onInit() async {
    super.onInit();
    box = GetStorage();
    var model = box.read(AppConstants.USER_INFO) ?? {};
    // BranchModel branch = box.read(AppConstants.SELECTED_BRANCH)!;
    user = UserModel.fromMap(Map<String, dynamic>.from(model));
    isInternetAccess.value =  await _connectivityService.checkServerConnection();
    List<CustomerModel> customers = loadCustomers(box);
    allCustomers.value = customers;
    // if(branch!= null)
    //   filteredCustomers.value = customers.where((cus) => cus.branch!.name == branch.name).toList();
    // else
      filteredCustomers.value = customers;
    List<PaymentReceivedModel> paymentReceiveds = loadPaymentReceived(box);
    paymentReceivedList.value = paymentReceiveds;

    getOfflineCurrencyList(box);
    List<PaymentTypeModel> tempList = getOfflinePaymentTypeList(box);
    paymentTypesList.value = tempList;
    filteredPaymentTypesList.value = tempList;
    print(filteredPaymentTypesList.map((f)=> f.name! + ","));
    onCurrencyChange(selectedCurrency.value!);

  }
  void filterCustomers(String query) {
    print(query);
    searchQuery.value = query;
    filteredCustomers.value = allCustomers.value.where((cus) {
      final name = cus.name!.toLowerCase() ?? '';

      var mobilePhone = '';
      if(cus.mobilePhone != null){
         mobilePhone = cus.mobilePhone!.toString().toLowerCase();
      }
      var accNo = '';
      if(cus.accountNumber != null){
         accNo = cus.accountNumber!.toString().toLowerCase();
      }
      final lowerQuery = query.toLowerCase();
      return name.contains(lowerQuery) || mobilePhone.contains(lowerQuery) || accNo.contains(lowerQuery);
    }).toList();
  }
  List<CustomerModel> loadCustomers( GetStorage box) {
    List<CustomerModel> list = _localStorageService.getOfflineList<CustomerModel>(
        AppConstants.CUSTOMER_LIST,
            (map) => CustomerModel.fromMap(map),
        box);
    return list;
  }
  List<PaymentReceivedModel> loadPaymentReceived( GetStorage box) {
    List<PaymentReceivedModel> list = _localStorageService.getOfflineList<PaymentReceivedModel>(
        AppConstants.PAYMENT_RECEIVED_LIST,
            (map) => PaymentReceivedModel.fromMap(map),
        box);
    return list;
  }

  saveCustomerInfo() async{
    GetStorage bb = GetStorage();
    var branchModel = bb.read(AppConstants.SELECTED_BRANCH) ?? {};
    int count  = allCustomers.length + 1;
    if(!allCustomers.any((customer)=>customer.name == name.value)) {
      String ref = AppConstants.getDateNowRef("CUS", count);
      BaseNameModel branch =
          BaseNameModel.fromMap(Map<String, dynamic>.from(branchModel));
      CustomerModel customerModel = CustomerModel(
          id: null,
          customerId: ref,
          name: name.value,
          companyName: "",
          email: email.value,
          mobilePhone: mobilePhone.value,
          description: description.value,
          branch: branch,
          taxNumber: vat.value,
          street: address.value,
          tinNumber: tin.value,
          accountNumber: accountNumber.value,
        currencyBalance: [],
        updated: true,
      );
      List<CustomerModel> customers = _localStorageService.getCustomers(box);
      customers.add(customerModel);
      allCustomers.value = customers;
      filteredCustomers.value = customers;
      allCustomers.refresh();
      filteredCustomers.refresh();
      _localStorageService.writeItems(AppConstants.CUSTOMER_LIST, customers, box);
      clearForm();
      Get.snackbar("New Customer", "Customer Saved Successfully",
          snackPosition: SnackPosition.BOTTOM);
      Navigator.of(Get.overlayContext!).pop();
      Get.back();
      cartController.refreshCustomers();
    }else{
      Get.snackbar("Error", "Customer Already Exists",
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  savePayment(){
    print("Saving payment");
    CustomerModel customer = selectedCustomer.value!;
    cartController.selectedCustomer.value = selectedCustomer.value;
    GetStorage bb = GetStorage();
    onCurrencyChange(selectedCurrency.value!);
    // int count = _localStorageService.getPaymentReceivedList(box).length + 1;
     var ref = AppConstants.getDateNowRef("OFF", 1);
     // print(double.parse(payAccAmtEditingController.text));

    PaymentReceivedModel paymentReceivedModel = PaymentReceivedModel(
        id: null,
        dateTime: DateFormat(AppConstants.APP_DATE_TIME_FMT).format(DateTime.now()),
        amount: double.parse(payAccAmtEditingController.text),
        amountPaid: double.parse(payAccAmtEditingController.text),
        paymentType: selectedPaymentType.value,
        isPaid: true,
        payer: customer,
        currency: selectedCurrency.value,
        bank: selectedBank.value
    );
    print(paymentReceivedModel.toJson());
    List<PaymentReceivedModel> prlist = paymentReceivedList.value;
    prlist.add(paymentReceivedModel);
    paymentReceivedList.value = prlist;
    List<Map<String, dynamic>> itemsListMap =
    prlist.map((item) => item.toMap()).toList();
    bb.write(AppConstants.PAYMENT_RECEIVED_LIST, itemsListMap);
    Get.snackbar("New Payment", "Payment Saved Successfully",
        snackPosition: SnackPosition.BOTTOM);
    var index = allCustomers.indexOf(customer);
    if(customer.currencyBalance==null || customer.currencyBalance!.isEmpty) {
      CustomerCurrencyAmount currencyAmount = CustomerCurrencyAmount(currency: selectedCurrency.value!, balance: double.parse(payAccAmtEditingController.text),
      );
      customer.currencyBalance!.add(currencyAmount);
    } else{
      var prev = customer.currencyBalance!.firstWhere((cd)=>cd.currency.id == selectedCurrency.value!.id).balance;
      customer.currencyBalance!.firstWhere((cd)=>cd.currency.id == selectedCurrency.value!.id).balance = (prev! + double.parse(payAccAmtEditingController.text));
    }
    allCustomers[index] = customer;
    List<CustomerModel> customers = allCustomers.value;
    List<Map<String, dynamic>> customersListMap =
    customers.map((item) => item.toMap()).toList();
    box.write(AppConstants.CUSTOMER_LIST, customersListMap);
    cartController.refreshCustomers();
    List<PaymentReceivedModel> paymentTypes =[];
    paymentTypes.add(paymentReceivedModel);
    print(paymentTypes.length);
    cartController.updateShiftWithNewSale(ref, paymentReceivedModel.dateTime!, paymentReceivedModel.amount!, isInternetAccess.value,
        customer.name!, paymentTypes,"CASH_IN",customer.name!);
    Navigator.of(Get.overlayContext!).pop();
    allCustomers.refresh();
    filteredCustomers.value = allCustomers.value;
    filteredCustomers.refresh();
    selectedCustomer.value = null;
    amountPaidTextEditingController.clear();
    clearForm();
  }

  setLoyalCustomer( CustomerModel customer){
    GetStorage bb = GetStorage();
    int? index =  allCustomers.indexOf((customer));
    customer.isLoyalCustomer = true;
    customer.updated = true;
    List<CustomerModel> customers = allCustomers.value;
    customers[index] = customer;
    allCustomers.value = customers;
    filteredCustomers.value = customers;
    List<Map<String, dynamic>> itemsListMap = customers.map((item) => item.toMap()).toList();
    bb.write(AppConstants.CUSTOMER_LIST, itemsListMap);
    cartController.refreshCustomers();
    allCustomers.refresh();
    filteredCustomers.refresh();
    Get.snackbar("Edit Customer", "Customer updated Successfully", snackPosition: SnackPosition.BOTTOM);
    clearForm();
  }
  updateCustomerInfo(){
    GetStorage bb = GetStorage();
    CustomerModel? customer =  allCustomers.firstWhereOrNull((customer)=> customer.name == name.value);
    var index = allCustomers.indexOf(customer);
    print(customer!.name);
    if(customer!=null && allCustomers.any((customer)=>customer.name == name.value)){
      customer.name = name.value;
      customer.accountNumber = accountNumber.value;
      customer.taxNumber = vat.value;
      customer.tinNumber = tin.value;
      customer.email = email.value;
      customer.mobilePhone = mobilePhone.value;
      customer.updated = true;
    }
    allCustomers[index] = customer;
    List<CustomerModel> customers = allCustomers.value;
    allCustomers.value = customers;
    filteredCustomers.value = customers;
    allCustomers.refresh();
    filteredCustomers.refresh();
    List<Map<String, dynamic>> itemsListMap = customers.map((item) => item.toMap()).toList();
    bb.write(AppConstants.CUSTOMER_LIST, itemsListMap);
    Get.snackbar("Edit Customer", "Customer updated Successfully", snackPosition: SnackPosition.BOTTOM);
    Navigator.of(Get.overlayContext!).pop();
    clearForm();
  }
  void showConfirmDialogToSaveCustomer() {
    Get.defaultDialog(
      title: "Confirmation",
      middleText: "Are you sure you want to proceed?",
      textCancel: "No",
      textConfirm: "Yes",
      onCancel: () {
        Get.back(); // Close the dialog
      },
      onConfirm: () {
        print("CLICKED");
        saveCustomerInfo();
        cartController.refreshCustomers();
        Navigator.of(Get.overlayContext!).pop();
       Get.back();
      },
    );
  }


  Future<void>  getCustomers(UserModel user, GetStorage box, String companyId) async{
    List<CustomerModel> newCustomer = _localStorageService.getCustomers(box);
    newCustomer = newCustomer.where((cust)=>cust.updated ?? false).toList();
    if(isInternetAccess.value==true) {
      var response = await BaseHttpClient()
          .getAuthWithCompanyHeader("/customer/get-all", companyId)
          .catchError((onError) {
        if (onError is BadRequestException) {
          var apiError = json.decode(onError.message!);
          AppHelper.showErroDialog(description: apiError["reason"]);
        } else {
          AppHelper.handleError(onError);
        }
      });
      if (response != null) {
        List<dynamic> list = jsonDecode(response);
        List<CustomerModel> itemsList =
            List<CustomerModel>.from(list.map((i) => CustomerModel.fromMap(i)));
        itemsList.addAll(newCustomer);
        allCustomers.value = itemsList;
        List<Map<String, dynamic>> itemsListMap =
            itemsList.map((item) => item.toMap()).toList();
        // showSnackBar("Message", "Customers downloaded successfully");
        box.write(AppConstants.CUSTOMER_LIST, itemsListMap);
      }
    }
    else {
      allCustomers = _localStorageService.getOfflineList<CustomerModel>(
          AppConstants.CUSTOMER_LIST,
          (map) => CustomerModel.fromMap(map),
          box
      ).obs;
    }
    allCustomers.refresh();
    filteredCustomers.value = allCustomers.value;
    filteredCustomers.refresh();
  }


  List<CurrencyModel> getOfflineCurrencyList(GetStorage box) {
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
      var currencyId = box.read(AppConstants.DEFAULT_CURRENCY_ID) ?? "";
      for(var cur in currencies)  {
        if(cur.isBaseCurrency!){
          selectedCurrency.value = cur;
          baseCurrency.value = cur;
          isCurrencySelected.value = true;
          // onCurrencyChange(cur);
        }
      }
      for(var cur in currencies)  {
        if(cur.id == currencyId){
          selectedCurrency.value = cur;
          isCurrencySelected.value = true;
        }
      }
      return currencies;
    } else {
      return [];
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
      List<PaymentTypeModel>  list =  List<PaymentTypeModel>.from(itemsListMap.map((map) => PaymentTypeModel.fromMap(map)));

      return list;
    } else {
      return [];
    }
  }

  void clearForm() {
    // Clear the text fields
    nameEditingController.clear();
    mobileNumberEditingController.clear();
    emailEditingController.clear();
    descriptionEditingController.clear();
    accNoEditingController.clear();

    // Reset the form's state
    formKeyForm.currentState?.reset();
  }


  onChangePaymentType(PaymentTypeModel paymentType, bool multiple){
    isPaymentTypeSelected.value = true;
    selectedPaymentType.value = paymentType;
    if(!multiple) {
      selectedPaymentTypes.clear();
    }
    selectedPaymentTypes.add(paymentType);
    selectCorrectBank();
  }
  onCurrencyChange(CurrencyModel newValue){
    isCurrencySelected.value = true;
    selectedCurrency.value = newValue;
    isPaymentTypeSelected.value = false;
    double totalCostInSelCurrency = totalCostInBaseCurrency.value * newValue.rate!;
    double totalTaxInSelCurrency = totalTaxInBaseCurrency.value * newValue.rate!;
    totalCostInSelectedCurrency.value = totalCostInSelCurrency;
    totalTaxInSelectedCurrency.value = totalTaxInSelCurrency;
    filterPaymentTypes(newValue, selectedCustomer.value!);
    selectedPaymentType.value = filteredPaymentTypesList.firstWhere((pt)=> pt.name == "ACC-${newValue.name}");
    selectCorrectBank();

  }

  void filterPaymentTypes(CurrencyModel selectedCurrency, CustomerModel selectedCus) {
    List<PaymentTypeModel> tempList = [];
    if (selectedCurrency.name != null) {
      for (PaymentTypeModel pt in paymentTypesList) {
        // Check if the payment type currency matches the selected currency
        if (pt.currency?.id == selectedCurrency.id) {
          tempList.add(pt);
        }
      }
    }
    // If the customer is 'WalkIn', filter out payment types containing 'credit'
    if (selectedCus.name != null && selectedCus.name!.toLowerCase() == 'walkin') {
      tempList = tempList
          .where((type) => !type.isCredit!)
          .toList();
    }
    // Assign the filtered results to the reactive list
    filteredPaymentTypesList.value = tempList;
    filteredPaymentTypesList.refresh();
  }
  void selectCorrectBank() {
    if (selectedCurrency.value != null && selectedPaymentType.value != null) {
      // Debugging to verify values
      print('Selected Currency: ${selectedCurrency.value?.name}');
      print('Selected Payment Type: ${selectedPaymentType.value?.name}');

      final paymentType = selectedPaymentType.value;
      final currency = selectedCurrency.value;

      if (paymentType?.banks != null) {
        for (BankModel bank in paymentType!.banks!) {
          if (bank.currency?.id == currency!.id) {
            selectedBank.value = bank;
            print('Selected Bank: ${bank.bankName}');
          }
        }
      } else {
        print('No banks associated with the selected payment type.');
      }
    } else {
      print('Either selectedCurrency or selectedPaymentType is null.');
    }
  }



}