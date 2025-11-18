import 'dart:async';
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
import '../../../services/printer_service.dart';
import '../../../services/sync_service.dart';
import '../../../shared/models/bank_model.dart';
import '../../../shared/models/branch_model.dart';
import '../../../shared/models/currency_model.dart';
import '../../../shared/models/payment_received_model.dart';
import '../../../shared/models/payment_type_model.dart';
import '../../../utils/app_helper.dart';
import '../../sale/controller/cart_controller.dart';
import '../../../services/nfc_service.dart';
import '../../../constants/app_routes.dart';
import '../../shift/controller/shift_controller.dart';

class CustomerProjectionModel {
  CustomerProjectionModel(
  {this.paymentReceived,this.reference});
  PaymentReceivedModel? paymentReceived;
  String? reference;
  factory CustomerProjectionModel.fromMap(Map<String, dynamic> json) => CustomerProjectionModel(
    paymentReceived: json['paymentReceived'] != null ? PaymentReceivedModel.fromMap(json['paymentReceived']) : null,
    reference: json['reference']
  );
}

class CustomerController extends GetxController {
  late UserModel user = UserModel(firstName: "", lastName: "", userName: "");
  late BranchModel? branch;
  final ConnectivityService _connectivityService = ConnectivityService();
  RxList<CustomerModel> allCustomers = <CustomerModel>[].obs;
  RxList<CustomerModel> filteredCustomers = <CustomerModel>[].obs;
  Rx<String> searchQuery = "".obs;
  var isInternetAccess = false.obs;
  final PrinterService _printerService = Get.put(PrinterService());
  var editCustomer = false.obs;
  RxList<CurrencyModel> currencyList = <CurrencyModel>[].obs;
  Rx<CurrencyModel?> selectedCurrency = CurrencyModel().obs;
  var isCurrencySelected = false.obs;
  Rx<PaymentTypeModel?> selectedPaymentType = PaymentTypeModel().obs;
  RxList<PaymentTypeModel> selectedPaymentTypes = <PaymentTypeModel>[].obs;
  Rx<BankModel?> selectedBank = BankModel().obs;
  RxList<PaymentReceivedModel> paymentReceivedList =
      <PaymentReceivedModel>[].obs;
  RxList<PaymentTypeModel> paymentTypesList = <PaymentTypeModel>[].obs;
  RxList<PaymentTypeModel> filteredPaymentTypesList = <PaymentTypeModel>[].obs;
  var isPaymentTypeSelected = false.obs;
  final TextEditingController amountPaidTextEditingController =
      TextEditingController();
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
  final TextEditingController payAccAmtEditingController =
      TextEditingController();
  final TextEditingController accNoEditingController = TextEditingController();
  final TextEditingController mobileNumberEditingController =
      TextEditingController();
  final TextEditingController emailEditingController = TextEditingController();
  final TextEditingController descriptionEditingController =
      TextEditingController();
  final TextEditingController vatEditingController = TextEditingController();
  final TextEditingController tinEditingController = TextEditingController();
  final TextEditingController addressEditingController =
      TextEditingController();
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
  var nfcCardId = "".obs;
  var nfcCardType = "".obs;
  GlobalKey<FormState> formKeyForm = GlobalKey<FormState>();

  // Debouncer for save operations
  Timer? _saveDebouncer;
  Timer? _paymentDebouncer;
  var isSaving = false.obs;
  var isSavingPayment = false.obs;
  bool _isSaving = false;
  bool _isSavingPayment = false;

  // NFC Service
  final NfcService _nfcService = Get.put(NfcService());

  @override
  Future<void> onInit() async {
    super.onInit();
    box = GetStorage();
    var model = box.read(AppConstants.USER_INFO) ?? {};
    var rowBranch = box.read(AppConstants.SELECTED_BRANCH)!;

    user = UserModel.fromMap(Map<String, dynamic>.from(model));
    branch = BranchModel.fromMap(Map<String, dynamic>.from(rowBranch));
    isInternetAccess.value =  await _connectivityService.checkServerConnection();
    List<CustomerModel> customers = loadCustomers(box);
    allCustomers.value = customers;
    if(branch!= null) {
          print(customers.any((cus) => cus.branch!.name == branch!.name));
      filteredCustomers.value =
          customers.where((cus) => cus.branch != null && cus.branch!.name == branch!.name).toList();
    } else
      filteredCustomers.value = customers;

    getOfflineCurrencyList(box);
    List<PaymentTypeModel> tempList = getOfflinePaymentTypeList(box);
    paymentTypesList.value = tempList;
    filteredPaymentTypesList.value = tempList;
    print(filteredPaymentTypesList.map((f) => f.name! + ","));
    onCurrencyChange(selectedCurrency.value!);
  }

  void filterCustomers(String query) {
    print(query);
    searchQuery.value = query;
    filteredCustomers.value = allCustomers.value.where((cus) {
      final name = cus.name!.toLowerCase() ?? '';

      var mobilePhone = '';
      if (cus.mobilePhone != null) {
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

  List<CustomerModel> loadCustomers(GetStorage box) {
    List<CustomerModel> list =
        _localStorageService.getOfflineList<CustomerModel>(
            AppConstants.CUSTOMER_LIST,
            (map) => CustomerModel.fromMap(map),
            box);
    return list;
  }

  List<PaymentReceivedModel> loadPaymentReceived(GetStorage box) {
    List<PaymentReceivedModel> list =
        _localStorageService.getOfflineList<PaymentReceivedModel>(
            AppConstants.PAYMENT_RECEIVED_LIST,
            (map) => PaymentReceivedModel.fromMap(map),
            box);
    return list;
  }

  // Debounced save customer method
  void debouncedSaveCustomer() {
    _saveDebouncer?.cancel();
    
    if (_isSaving) {
      Get.snackbar("Info", "Save operation in progress...",
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    
    _saveDebouncer = Timer(Duration(milliseconds: 500), () {
      _performSaveCustomer();
    });
  }

  // Internal method that performs the actual save
  Future<void> _performSaveCustomer() async {
    if (_isSaving) return;
    
    _isSaving = true;
    isSaving.value = true;
    
    try {
      await saveCustomerInfo();
    } catch (e) {
      Get.snackbar("Error", "Failed to save customer: ${e.toString()}",
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      _isSaving = false;
      isSaving.value = false;
    }
  }

  saveCustomerInfo() async{
    GetStorage bb = GetStorage();
    var branchModel = bb.read(AppConstants.SELECTED_BRANCH) ?? {};
    int count = allCustomers.length + 1;
    if (!allCustomers.any((customer) => customer.name == name.value)) {
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
          nfcCardId: nfcCardId.value,
          nfcCardType: nfcCardType.value);
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

  // Show date range selection dialog
  Future<void> showDateRangeDialog(CustomerModel customer) async {
    final DateTime now = DateTime.now();
    final DateTime sevenDaysAgo = now.subtract(Duration(days: 7));
    final DateTime thirtyDaysAgo = now.subtract(Duration(days: 30));
    final DateTime ninetyDaysAgo = now.subtract(Duration(days: 90));
    
    Get.dialog(
      Dialog(
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Date Range',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              // Preset options
              ListTile(
                leading: Icon(Icons.calendar_today),
                title: Text('Last 7 Days'),
                onTap: () {
                  Get.back();
                  _printStatementWithDates(customer, sevenDaysAgo, now, 'Last 7 days');
                },
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.calendar_today),
                title: Text('Last 30 Days'),
                onTap: () {
                  Get.back();
                  _printStatementWithDates(customer, thirtyDaysAgo, now, 'Last 30 days');
                },
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.calendar_today),
                title: Text('Last 90 Days'),
                onTap: () {
                  Get.back();
                  _printStatementWithDates(customer, ninetyDaysAgo, now, 'Last 90 days');
                },
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.date_range),
                title: Text('Custom Range'),
                onTap: () async {
                  Get.back();
                  await _showCustomDateRangePicker(customer);
                },
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Show custom date range picker
  Future<void> _showCustomDateRangePicker(CustomerModel customer) async {
    final DateTime now = DateTime.now();
    final DateTime thirtyDaysAgo = now.subtract(Duration(days: 30));
    
    // Create stateful widget for date management
    final selectedStartDate = thirtyDaysAgo.obs;
    final selectedEndDate = now.obs;
    
    Get.dialog(
      Dialog(
        child: StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Select Custom Date Range',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  ListTile(
                    leading: Icon(Icons.calendar_today),
                    title: Text('Start Date'),
                    subtitle: Text(DateFormat('yyyy-MM-dd').format(selectedStartDate.value)),
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedStartDate.value,
                        firstDate: DateTime(2020, 1, 1),
                        lastDate: now,
                      );
                      if (picked != null) {
                        setState(() {
                          selectedStartDate.value = picked;
                        });
                      }
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.calendar_today),
                    title: Text('End Date'),
                    subtitle: Text(DateFormat('yyyy-MM-dd').format(selectedEndDate.value)),
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedEndDate.value,
                        firstDate: DateTime(2020, 1, 1),
                        lastDate: now,
                      );
                      if (picked != null) {
                        setState(() {
                          selectedEndDate.value = picked;
                        });
                      }
                    },
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Get.back();
                          _printStatementWithDates(customer, selectedStartDate.value, selectedEndDate.value, 'Custom range');
                        },
                        child: Text('Apply'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Internal method to print with specific dates
  Future<void> _printStatementWithDates(CustomerModel customer, DateTime startDate, DateTime endDate, String rangeDescription) async {
    await printCustomerStatementWithDates(customer, startDate: startDate, endDate: endDate, description: rangeDescription);
  }

  // Default method that shows the date range dialog
  Future<void> printCustomerStatement(CustomerModel customer) async {
    await showDateRangeDialog(customer);
  }

  // Updated method signature to accept optional date parameters
  Future<void> printCustomerStatementWithDates(
    CustomerModel customer, {
    DateTime? startDate,
    DateTime? endDate,
    String? description,
  }) async {
    var connection = await _connectivityService.checkServerConnection();
    if(connection){
      try {
        // Use provided dates or default to last 30 days
        final DateTime now = endDate ?? DateTime.now();
        final DateTime thirtyDaysAgo = startDate ?? now.subtract(Duration(days: 30));
        final String fromDate = DateFormat('yyyy-MM-dd').format(thirtyDaysAgo);
        final String toDate = DateFormat('yyyy-MM-dd').format(now);
        
        // Log the actual dates for debugging
        print("==================== ACCOUNT STATEMENT FILTER ====================");
        print("Current DateTime.now(): $now");
        print("Customer: ${customer.name}");
        print("Customer ID: ${customer.id}");
        print("Filter Period: ${description ?? 'Last 30 days'}");
        print("From Date: $fromDate");
        print("To Date: $toDate");
        print("========================================================");
        
        // Add query parameters for date filtering
        final String endpoint = "/sale/get-by-customer/${customer.id!}?startDate=$fromDate&endDate=$toDate";
        
        print("API Endpoint: $endpoint");
        print("Fetching data...");
        
        var response = await BaseHttpClient().getAuthWithCompanyHeader(
            endpoint, user.companyId!).catchError((
            onError) {
          print("ERROR: $onError");
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
          List<CustomerProjectionModel> allItemsList = List<CustomerProjectionModel>.from(list.map((i) => CustomerProjectionModel.fromMap(i)));

          // Filter transactions to selected date range
          List<CustomerProjectionModel> itemsList = allItemsList.where((item) {
            if (item.paymentReceived?.dateTime == null) return false;
            try {
              String dateStr = item.paymentReceived!.dateTime!.substring(0, 10);
              DateTime itemDate = DateTime.parse(dateStr);
              return itemDate.isAfter(thirtyDaysAgo.subtract(Duration(days: 1))) && 
                     itemDate.isBefore(now.add(Duration(days: 1)));
            } catch (e) {
              return false;
            }
          }).toList();

          print("==================== FILTERED TRANSACTIONS (${description ?? 'Last 30 Days'}) ====================");
          print("Total records before filter: ${allItemsList.length}");
          print("Total records after filter: ${itemsList.length}");
          print("\n");
          
          if (itemsList.isNotEmpty) {
            double totalAmount = 0.0;
            double totalDebit = 0.0;
            double totalCredit = 0.0;
            
            for (var i = 0; i < itemsList.length; i++) {
              var item = itemsList[i];
              var isCredit = item.paymentReceived?.paymentType?.isCredit ?? false;
              var amount = item.paymentReceived?.amount ?? 0.0;
              
              // Display transaction
              print("${i + 1}. ${item.paymentReceived?.dateTime?.substring(0, 10) ?? 'N/A'} | "
                    "Ref: ${item.reference ?? 'N/A'} | "
                    "${isCredit ? 'CR' : 'DR'} | "
                    "${item.paymentReceived?.currency?.symbol ?? '\$'}${amount.toStringAsFixed(2)} | "
                    "Bal: ${item.paymentReceived?.currency?.symbol ?? '\$'}${item.paymentReceived?.accountBalance?.toStringAsFixed(2) ?? '0.00'}");
              print("   ${item.paymentReceived?.paymentDescription ?? 'No description'}");
              
              // Calculate totals
              totalAmount += amount;
              if (isCredit) {
                totalCredit += amount;
              } else {
                totalDebit += amount;
              }
            }
            
            print("\n--- Summary ---");
            print("Total Transactions: ${itemsList.length}");
            print("Total Credit: ${totalCredit.toStringAsFixed(2)}");
            print("Total Debit: ${totalDebit.toStringAsFixed(2)}");
            print("Net Amount: ${(totalCredit - totalDebit).toStringAsFixed(2)}");
          } else {
            print("No transactions found in the last 30 days.");
          }
          print("================================================================================");

          _printerService.printCustomerStatement(customer,itemsList, box, _localStorageService, dateRangeDescription: description);
        }
        AppHelper.hideLoading();
      } catch (e) {
        Get.snackbar('Error', 'Failed to fetch sales: $e',
            snackPosition: SnackPosition.BOTTOM);
      }
    }else{
      Get.snackbar("Error", "Failed to connect to server",
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  // Debounced save payment method
  void debouncedSavePayment() {
    _paymentDebouncer?.cancel();
    
    if (_isSavingPayment) {
      Get.snackbar("Info", "Save payment operation in progress...",
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    
    _paymentDebouncer = Timer(Duration(milliseconds: 500), () {
      _performSavePayment();
    });
  }

  // Internal method that performs the actual save payment
  Future<void> _performSavePayment() async {
    if (_isSavingPayment) return;
    
    _isSavingPayment = true;
    isSavingPayment.value = true;
    
    try {
      await savePayment();
    } catch (e) {
      Get.snackbar("Error", "Failed to save payment: ${e.toString()}",
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      _isSavingPayment = false;
      isSavingPayment.value = false;
    }
  }

  savePayment() async {
    CustomerModel customer = selectedCustomer.value!;
    cartController.selectedCustomer.value = selectedCustomer.value;
    List<PaymentReceivedModel> paymentReceiveds = loadPaymentReceived(box);
    paymentReceivedList.value = paymentReceiveds;
    GetStorage bb = GetStorage();
    onCurrencyChange(selectedCurrency.value!);
     var ref = AppConstants.getDateNowRef("OFF", 1);
    PaymentReceivedModel paymentReceivedModel = PaymentReceivedModel(
        id: null,
        dateTime: DateFormat(AppConstants.APP_DATE_TIME_FMT).format(DateTime.now()),
        amount: double.parse(payAccAmtEditingController.text),
        amountPaid: double.parse(payAccAmtEditingController.text),
        paymentType: selectedPaymentType.value,
        isPaid: true,
        payer: customer,
        currency: selectedCurrency.value,
        bank: selectedBank.value,
        branch: branch,
      paymentDescription: "PAY_ACCOUNT",
        accountType: "CUSTOMER_ACCOUNT"
    );
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
    } else {
      var prev = customer.currencyBalance!
          .firstWhere((cd) => cd.currency.id == selectedCurrency.value!.id)
          .balance;
      customer.currencyBalance!
          .firstWhere((cd) => cd.currency.id == selectedCurrency.value!.id)
          .balance = (prev! + double.parse(payAccAmtEditingController.text));
    }
    allCustomers[index] = customer;
    List<CustomerModel> customers = allCustomers.value;
    List<Map<String, dynamic>> customersListMap =
        customers.map((item) => item.toMap()).toList();
    box.write(AppConstants.CUSTOMER_LIST, customersListMap);
    cartController.refreshCustomers();
    List<PaymentReceivedModel> paymentTypes =[];
    paymentReceivedModel.payer = customer;
    paymentTypes.add(paymentReceivedModel);
    cartController.updateShiftWithNewSale(ref, paymentReceivedModel.dateTime!, paymentReceivedModel.amount!, isInternetAccess.value,
        customer.name!, paymentTypes,"CASH_IN",customer.name!, false);
    Navigator.of(Get.overlayContext!).pop();
    allCustomers.refresh();
    filteredCustomers.value = allCustomers.value;
    filteredCustomers.refresh();
    selectedCustomer.value = CustomerModel();
    amountPaidTextEditingController.clear();
    // clearForm();
    Get.delete<ShiftController>();
    Get.reload();
    payAccAmtEditingController.clear();
    if(isInternetAccess.value){
      await SyncService.savePaymentReceived(user, box);
    }
  }

  setLoyalCustomer(CustomerModel customer) {
    GetStorage bb = GetStorage();
    int? index = allCustomers.indexOf((customer));
    customer.isLoyalCustomer = true;
    customer.updated = true;
    List<CustomerModel> customers = allCustomers.value;
    customers[index] = customer;
    allCustomers.value = customers;
    filteredCustomers.value = customers;
    List<Map<String, dynamic>> itemsListMap =
        customers.map((item) => item.toMap()).toList();
    bb.write(AppConstants.CUSTOMER_LIST, itemsListMap);
    cartController.refreshCustomers();
    allCustomers.refresh();
    filteredCustomers.refresh();
    Get.snackbar("Edit Customer", "Customer updated Successfully",
        snackPosition: SnackPosition.BOTTOM);
    clearForm();
  }

  updateCustomerInfo() {
    GetStorage bb = GetStorage();
    CustomerModel? customer = allCustomers
        .firstWhereOrNull((customer) => customer.name == name.value);
    var index = allCustomers.indexOf(customer);
    print(customer!.name);
    if (customer != null &&
        allCustomers.any((customer) => customer.name == name.value)) {
      customer.name = name.value;
      customer.accountNumber = accountNumber.value;
      customer.taxNumber = vat.value;
      customer.tinNumber = tin.value;
      customer.email = email.value;
      customer.mobilePhone = mobilePhone.value;
      customer.nfcCardId = nfcCardId.value;
      customer.nfcCardType = nfcCardType.value;
      customer.updated = true;
    }
    allCustomers[index] = customer;
    List<CustomerModel> customers = allCustomers.value;
    allCustomers.value = customers;
    filteredCustomers.value = customers;
    allCustomers.refresh();
    filteredCustomers.refresh();
    List<Map<String, dynamic>> itemsListMap =
        customers.map((item) => item.toMap()).toList();
    bb.write(AppConstants.CUSTOMER_LIST, itemsListMap);
    Get.snackbar("Edit Customer", "Customer updated Successfully",
        snackPosition: SnackPosition.BOTTOM);
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
    } else {
      allCustomers = _localStorageService
          .getOfflineList<CustomerModel>(AppConstants.CUSTOMER_LIST,
              (map) => CustomerModel.fromMap(map), box)
          .obs;
    }
    allCustomers.refresh();
    filteredCustomers.value = allCustomers.value;
    filteredCustomers.refresh();
  }

  List<CurrencyModel> getOfflineCurrencyList(GetStorage box) {
    // Read the data as a List<dynamic>
    List<dynamic>? itemsListDynamic =
        box.read<List<dynamic>>(AppConstants.CURRENCY_LIST);
    // Check if the read data is not null
    if (itemsListDynamic != null) {
      // Convert the List<dynamic> to List<Map<String, dynamic>>
      List<Map<String, dynamic>> itemsListMap = itemsListDynamic.map((item) {
        return item as Map<String, dynamic>;
      }).toList();
      List<CurrencyModel> currencies = List<CurrencyModel>.from(
          itemsListMap.map((map) => CurrencyModel.fromMap(map)));
      currencyList.value = currencies;
      var currencyId = box.read(AppConstants.DEFAULT_CURRENCY_ID) ?? "";
      for (var cur in currencies) {
        if (cur.isBaseCurrency!) {
          selectedCurrency.value = cur;
          baseCurrency.value = cur;
          isCurrencySelected.value = true;
          // onCurrencyChange(cur);
        }
      }
      for (var cur in currencies) {
        if (cur.id == currencyId) {
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
    List<dynamic>? itemsListDynamic =
        box.read<List<dynamic>>(AppConstants.PAYMENT_TYPE_LIST);
    // Check if the read data is not null
    if (itemsListDynamic != null) {
      // Convert the List<dynamic> to List<Map<String, dynamic>>
      List<Map<String, dynamic>> itemsListMap = itemsListDynamic.map((item) {
        return item as Map<String, dynamic>;
      }).toList();
      List<PaymentTypeModel> list = List<PaymentTypeModel>.from(
          itemsListMap.map((map) => PaymentTypeModel.fromMap(map)));

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

  onChangePaymentType(PaymentTypeModel paymentType, bool multiple) {
    isPaymentTypeSelected.value = true;
    selectedPaymentType.value = paymentType;
    if (!multiple) {
      selectedPaymentTypes.clear();
    }
    selectedPaymentTypes.add(paymentType);
    selectCorrectBank();
  }

  onCurrencyChange(CurrencyModel newValue) {
    isCurrencySelected.value = true;
    selectedCurrency.value = newValue;
    isPaymentTypeSelected.value = false;
    double totalCostInSelCurrency =
        totalCostInBaseCurrency.value * newValue.rate!;
    double totalTaxInSelCurrency =
        totalTaxInBaseCurrency.value * newValue.rate!;
    totalCostInSelectedCurrency.value = totalCostInSelCurrency;
    totalTaxInSelectedCurrency.value = totalTaxInSelCurrency;
    filterPaymentTypes(newValue, selectedCustomer.value!);
    selectCorrectBank();
  }

  void filterPaymentTypes(
      CurrencyModel selectedCurrency, CustomerModel selectedCus) {
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
    if (selectedCus.name != null &&
        selectedCus.name!.toLowerCase() == 'walkin') {
      tempList = tempList.where((type) => !type.isCredit!).toList();
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

  void loadCustomerData(CustomerModel customer) {
    name.value = customer.name ?? '';
    email.value = customer.email ?? '';
    mobilePhone.value = customer.mobilePhone ?? '';
    accountNumber.value = customer.accountNumber ?? '';
    description.value = customer.description ?? '';
    tin.value = customer.tinNumber ?? '';
    vat.value = customer.taxNumber ?? '';
    address.value = customer.street ?? '';
    nfcCardId.value = customer.nfcCardId ?? '';
    nfcCardType.value = customer.nfcCardType ?? '';

    // Update text controllers
    nameEditingController.text = name.value;
    emailEditingController.text = email.value;
    mobileNumberEditingController.text = mobilePhone.value;
    accNoEditingController.text = accountNumber.value;
    descriptionEditingController.text = description.value;
    tinEditingController.text = tin.value;
    vatEditingController.text = vat.value;
    addressEditingController.text = address.value;
  }

  // NFC Methods
  Future<void> addCardToCustomer() async {
    // Check if NFC is available first
    if (!_nfcService.isNfcAvailable.value) {
      showCustomerSelectionDialog();
      return;
    }

    try {
      String? cardId = await _nfcService.readNfcCard();

      if (cardId != null) {
        // Set the card ID as the customer's account number
        accNoEditingController.text = cardId;
        nfcCardId.value = cardId;
        nfcCardType.value = _determineCardType(cardId);

        Get.snackbar(
          'Card Added',
          'NFC card ID has been added to customer account number',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: Duration(seconds: 2),
        );
      } else {
        Get.snackbar(
          'No Card Detected',
          'Please hold your device near the NFC card',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to read NFC card',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  String _determineCardType(String cardId) {
    // Determine card type based on card ID pattern
    if (cardId.startsWith('M1')) {
      return 'M1';
    } else if (cardId.startsWith('0202C1')) {
      return '0202C1';
    } else {
      return 'Unknown';
    }
  }

  void clearNfcData() {
    nfcCardId.value = '';
    nfcCardType.value = '';
  }

  // Alternative customer selection methods for devices without NFC
  void showCustomerSelectionDialog() {
    Get.dialog(
      AlertDialog(
        title: Text('Customer Selection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('NFC is not available on this device.'),
            SizedBox(height: 10),
            Text('Please use one of these alternatives:'),
            SizedBox(height: 10),
            ListTile(
              leading: Icon(Icons.search),
              title: Text('Search Customer'),
              subtitle: Text('Use the search bar above'),
              onTap: () => Get.back(),
            ),
            ListTile(
              leading: Icon(Icons.qr_code_scanner),
              title: Text('Scan Barcode'),
              subtitle: Text('Use camera to scan customer card'),
              onTap: () {
                Get.back();
                // Navigate to barcode scanner
                Get.toNamed(AppRoutes.BARCODE_SCANNER,
                    arguments: {'scanMode': 'customer'});
              },
            ),
            ListTile(
              leading: Icon(Icons.person_add),
              title: Text('Add New Customer'),
              subtitle: Text('Create a new customer'),
              onTap: () {
                Get.back();
                Get.toNamed(AppRoutes.CUSTOMER_FORM);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // Test NFC availability
  Future<void> testNfcAvailability() async {
    try {
      Map<String, dynamic> nfcInfo = await _nfcService.getNfcHardwareInfo();

      String title = 'NFC Hardware Check';
      String message = '';

      if (nfcInfo['available']) {
        if (nfcInfo['enabled']) {
          title = '✅ NFC Working';
          message =
              'NFC is available and enabled on your device.\n\nYou can now use NFC cards for customer selection.';
        } else {
          title = '⚠️ NFC Disabled';
          message =
              'NFC hardware is detected but not enabled.\n\nPlease enable NFC in your device settings:\n\n1. Settings > Connections > NFC\n2. Settings > Connected devices > NFC\n3. Turn ON "NFC and contactless payments"';
        }
      } else {
        title = '❌ NFC Not Available';
        message =
            'Your device does not have NFC hardware or NFC is completely disabled.\n\nThis V2 SE device may not support NFC functionality.\n\nAlternative solutions:\n• Use manual customer search\n• Use barcode scanning\n• Contact your device manufacturer';
      }

      Get.dialog(
        AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Text(message),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      Get.snackbar(
        'NFC Test Error',
        'Error checking NFC availability',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  void onClose() {
    _saveDebouncer?.cancel();
    _paymentDebouncer?.cancel();
    super.onClose();
  }
}
