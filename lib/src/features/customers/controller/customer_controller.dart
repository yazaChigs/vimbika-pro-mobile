import 'dart:async';
import 'dart:convert';
// import 'dart:ffi'; // Removed as Double is not used

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:vimbika_pos_app/src/constants/app_constants.dart';
import 'package:vimbika_pos_app/src/features/authentication/model/user_model.dart';
import 'package:vimbika_pos_app/src/features/customers/model/customer_currency_amount.dart';
import 'package:vimbika_pos_app/src/features/sale/model/sale_item_model.dart';
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

class DebtorStatementProjection {
  DebtorStatementProjection(
  {this.paymentType,
    this.referenceNumber,
    this.items,
    this.dateTime,
    this.currency,
    this.baseCurrency,
    this.balance,
    this.amount,
    this.credit,
    this.debit,
    this.paymentDescription,
    this.saleStatus,
    this.reversed,
    this.cashPayment,
    this.isFromPoints,
  });
  PaymentTypeModel? paymentType;
  String? referenceNumber;
  List<SaleItemModel>? items;
  String? dateTime;
  CurrencyModel? currency;
  CurrencyModel? baseCurrency;
  double? balance; // Changed from Double? to double?
  double? amount; // Changed from Double? to double?
  double? credit;
  double? debit;
  String? paymentDescription;
  String? saleStatus;
  bool? reversed;
  bool? cashPayment;
  bool? isFromPoints;
  factory DebtorStatementProjection.fromMap(Map<String, dynamic> json) => DebtorStatementProjection(
    paymentType: json["paymentType"] != null ? PaymentTypeModel.fromMap(json["paymentType"]) : null,
    referenceNumber: json['referenceNumber'],
    items: json['items'] != null ? List<SaleItemModel>.from(json['items'].map((x) => SaleItemModel.fromMap(x))) : null,
    dateTime: json['dateTime'],
    currency: json['currency'] != null ? CurrencyModel.fromMap(json["currency"]) : null,
    baseCurrency: json['baseCurrency'] != null ? CurrencyModel.fromMap(json["baseCurrency"]) : null,
    balance: json['balance'] != null ? json['balance'].toDouble() :0.00,
    amount: json['amount'] != null ? json['amount'].toDouble() :0.00,
    paymentDescription: json['paymentDescription'],
    saleStatus: json['saleStatus'],
    reversed: json['reversed'],
    cashPayment: json['cashPayment'],
    isFromPoints: json['isFromPoints'],
    debit: json['debit'] != null ? json['debit'].toDouble() :0.00,
    credit: json['credit'] != null ? json['credit'].toDouble() :0.00,
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
    await reloadCustomersFromStorage();
    getOfflineCurrencyList(box);
    List<PaymentTypeModel> tempList = getOfflinePaymentTypeList(box);
    paymentTypesList.value = tempList;
    filteredPaymentTypesList.value = tempList;
    print(filteredPaymentTypesList.map((f) => f.name! + ","));
    onCurrencyChange(selectedCurrency.value!);
  }

  // Method to reload customers from storage - can be called explicitly
  Future<void> reloadCustomersFromStorage() async {
    box = GetStorage();
    var model = box.read(AppConstants.USER_INFO) ?? {};
    var rowBranch = box.read(AppConstants.SELECTED_BRANCH);
    
    if(model.isNotEmpty) {
      user = UserModel.fromMap(Map<String, dynamic>.from(model));
    }
    
    if(rowBranch != null) {
      branch = BranchModel.fromMap(Map<String, dynamic>.from(rowBranch));
    }
    
    isInternetAccess.value = await _connectivityService.checkServerConnection();
    List<CustomerModel> customers = loadCustomers(box);
    
    print("Loaded ${customers.length} customer(s) from storage");
    
    // Ensure WalkIn customer exists if list is empty
    if(customers.isEmpty || !customers.any((c) => c.name?.toLowerCase().contains('walkin') ?? false)) {
      CustomerModel walkInCustomer = CustomerModel(
        id: null, 
        name: 'WalkIn', 
        branch: branch != null 
          ? BaseNameModel(id: branch!.id, name: branch!.name)
          : null
      );
      customers.add(walkInCustomer);
      print("Added WalkIn customer");
    }
    
    allCustomers.value = customers;
    /*if(branch != null) {
      print("Filtering customers by branch: ${branch!.name}");
      print("Customers before filter: ${customers.length}");
      // Filter by branch but always include WalkIn
      List<CustomerModel> filteredByBranch = customers.where((cus) => 
        (cus.branch != null && cus.branch!.name == branch!.name) || cus.name == "WalkIn"
      ).toList();
      
      // If filtering leaves too few customers compared to available, fall back to original list (offline-friendly)
      if (filteredByBranch.length < 5 && customers.length > filteredByBranch.length) {
        filteredCustomers.value = customers; // Fallback to full list
        print("Customers after filter (fallback to full list): ${customers.length}");
      } else {
        filteredCustomers.value = filteredByBranch;
        print("Customers after filter: ${filteredCustomers.length}");
      }
    } else {
      filteredCustomers.value = customers;
    }*/
    filteredCustomers.value = customers;
    
    allCustomers.refresh();
    filteredCustomers.refresh();
    
    // Ensure customers are written to storage after reload
    // This ensures they persist even if controllers are deleted
    if(customers.isNotEmpty) {
      try {
        List<Map<String, dynamic>> customersListMap = customers.map((item) => item.toMap()).toList();
        box.write(AppConstants.CUSTOMER_LIST, customersListMap);
        print("Written ${customers.length} customer(s) to storage after reload");
      } catch (e) {
        print("Error writing customers to storage after reload: $e");
      }
    }
  }

  void filterCustomers(String query) {
    print(query);
    searchQuery.value = query;
    print("allCustomers.length: ${allCustomers.length}");
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
      return name.contains(lowerQuery) ;
          // || mobilePhone.contains(lowerQuery) || accNo.contains(lowerQuery);
    }).toList();
    filteredCustomers.forEach((element) => print(element.toJson()));
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
      if (editCustomer.value) {
        await updateCustomerInfo();
      } else {
        await saveCustomerInfo();
      }
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
    final String newName = name.value.trim().toLowerCase();

    final bool nameExists = newName.isNotEmpty && allCustomers.any(
        (c) => c.name?.trim().toLowerCase() == newName
    );

    if (nameExists) {
        Get.snackbar("Error", "A customer with the same name already exists.",
          snackPosition: SnackPosition.BOTTOM);
    } else {
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

      isInternetAccess.value = await _connectivityService.checkServerConnection();
      List<CustomerModel> customers = _localStorageService.getCustomers(box);
      customers.add(customerModel);
      allCustomers.value = customers;
      filteredCustomers.value = customers;
      allCustomers.refresh();
      filteredCustomers.refresh();
      _localStorageService.writeItems(AppConstants.CUSTOMER_LIST, customers, box);
      clearForm();
      if(isInternetAccess.value){
        await SyncService.saveCustomer(user, box);
      }
      Get.snackbar("New Customer", "Customer Saved Successfully",
          snackPosition: SnackPosition.BOTTOM);
      Navigator.of(Get.overlayContext!).pop();
      Get.back();
      // Reload from CustomerController to ensure proper offline handling (same as sale screen refresh fix)
      await reloadCustomersFromStorage();
      cartController.refreshCustomersFromList(List<CustomerModel>.from(allCustomers));
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
                  _fetchAndShowStatement(customer, startDate: sevenDaysAgo, endDate: now, description: 'Last 7 days');
                },
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.calendar_today),
                title: Text('Last 30 Days'),
                onTap: () {
                  Get.back();
                  _fetchAndShowStatement(customer, startDate: thirtyDaysAgo, endDate: now, description: 'Last 30 days');
                },
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.calendar_today),
                title: Text('Last 90 Days'),
                onTap: () {
                  Get.back();
                  _fetchAndShowStatement(customer, startDate: ninetyDaysAgo, endDate: now, description: 'Last 90 days');
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
                          _fetchAndShowStatement(customer, startDate: selectedStartDate.value, endDate: selectedEndDate.value, description: 'Custom range');
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

  // Internal method to show statement preview dialog
  void _showStatementPreview(
      CustomerModel customer,
      List<DebtorStatementProjection> items,
      String description,
      double totalCredit,
      double totalDebit,
      double openingBalance,
      double closingBalance,
      ) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Container(
          width: Get.width * 0.95,
          height: Get.height * 0.85,
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Statement: ${customer.name}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Get.back(),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Opening Balance: ${openingBalance.toStringAsFixed(2)}'),
                  Text('Period: $description', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
              SizedBox(height: 10),
              Divider(height: 1),
              Expanded(
                child: items.isEmpty
                    ? Center(child: Text("No transactions found"))
                    : Column(
                        children: [
                          // Header Row
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                            child: Row(
                              children: const [
                                Expanded(flex: 2, child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                                Expanded(flex: 2, child: Text('Payment Type', style: TextStyle(fontWeight: FontWeight.bold))),
                                Expanded(flex: 2, child: Text('Reference No.', style: TextStyle(fontWeight: FontWeight.bold))),
                                Expanded(flex: 3, child: Text('Description', style: TextStyle(fontWeight: FontWeight.bold))),
                                Expanded(flex: 1, child: Text('Currency', style: TextStyle(fontWeight: FontWeight.bold))),
                                Expanded(flex: 1, child: Text('Debit', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                                Expanded(flex: 1, child: Text('Credit', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red))),
                                Expanded(flex: 1, child: Text('Balance', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                            ),
                          ),
                          Divider(height: 1),
                          Expanded(
                            child: ListView.builder(
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                final item = items[index];
                                var debitAmount = item.debit ?? 0.0;
                                var creditAmount = item.credit ?? 0.0;

                                // Main transaction details row
                                Widget transactionDetailsRow = Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                                  child: Row(
                                    children: [
                                      Expanded(flex: 2, child: Text(item.dateTime?.substring(0, 10) ?? 'N/A')),
                                      Expanded(flex: 2, child: Text(item.paymentType?.name ?? '')),
                                      Expanded(flex: 2, child: Text(item.referenceNumber ?? 'N/A')),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          item.paymentDescription ?? '',
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                        ),
                                      ),
                                      Expanded(flex: 1, child: Text('${item.currency?.name} ${item.currency?.symbol} '?? '')),
                                      Expanded(flex: 1, child: Text(debitAmount > 0 ? debitAmount.toStringAsFixed(2) : '-', style: TextStyle(color: Colors.green))),
                                      Expanded(flex: 1, child: Text(creditAmount > 0 ? creditAmount.toStringAsFixed(2) : '-', style: TextStyle(color: Colors.red))),
                                      Expanded(flex: 1, child: Text(item.balance?.toStringAsFixed(2) ?? '0.00')),
                                    ],
                                  ),
                                );

                                return Card(
                                  margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 0.0),
                                  child: ExpansionTile(
                                    tilePadding: EdgeInsets.zero, // Remove default padding
                                    title: transactionDetailsRow,
                                    // Conditionally hide the trailing icon if no items
                                    trailing: (item.items != null && item.items!.isNotEmpty) ? null : const SizedBox.shrink(),
                                    children: (item.items != null && item.items!.isNotEmpty)
                                        ? [
                                            Padding(
                                              padding: const EdgeInsets.only(left: 20.0, right: 8.0, top: 8.0, bottom: 4.0),
                                              child: Row(
                                                children: const [
                                                  Expanded(flex: 4, child: Text('Item', style: TextStyle(fontWeight: FontWeight.bold))),
                                                  Expanded(flex: 1, child: Text('Qty', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                                                  Expanded(flex: 2, child: Text('Price', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold))),
                                                ],
                                              ),
                                            ),
                                            Divider(height: 1, indent: 20, endIndent: 8),
                                            ...item.items!.map((saleItem) {
                                              return Padding(
                                                padding: const EdgeInsets.only(left: 20.0, right: 8.0, top: 4.0, bottom: 4.0), // Indent sale items
                                                child: Row(
                                                  children: [
                                                    Expanded(flex: 4, child: Text(saleItem.inventoryItem!.name ?? 'N/A', style: TextStyle(fontStyle: FontStyle.italic))),
                                                    Expanded(flex: 1, child: Text(saleItem.quantity?.toStringAsFixed(0) ?? '0', textAlign: TextAlign.center, style: TextStyle(fontStyle: FontStyle.italic))),
                                                    Expanded(flex: 2, child: Text(saleItem.sellingPrice?.toStringAsFixed(2) ?? '0.00', textAlign: TextAlign.right, style: TextStyle(fontStyle: FontStyle.italic))),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          ]
                                        : [], // Empty list if no items
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
              ),
              Divider(height: 1),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Debit:', style: TextStyle(color: Colors.green)),
                  Text(totalDebit.toStringAsFixed(2), style: TextStyle(color: Colors.green)),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Credit:', style: TextStyle(color: Colors.red)),
                  Text(totalCredit.toStringAsFixed(2), style: TextStyle(color: Colors.red)),
                ],
              ),
              SizedBox(height: 5),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Closing balance', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      (closingBalance).toStringAsFixed(2),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.print),
                  label: Text('Print Statement'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Get.back(); // Close preview dialog
                    _printerService.printCustomerStatement(
                        customer, items, box, _localStorageService,
                        dateRangeDescription: description);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Internal method to fetch data and show statement
  Future<void> _fetchAndShowStatement(
    CustomerModel customer, {
    DateTime? startDate,
    DateTime? endDate,
    String? description,
  }) async {
    var connection = await _connectivityService.checkServerConnection();
    if(connection){
      try {
        AppHelper.showLoading();
        // Use provided dates or default to last 30 days
        final DateTime now = endDate ?? DateTime.now();
        final DateTime thirtyDaysAgo = startDate ?? now.subtract(Duration(days: 30));
        final String fromDate = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").format(thirtyDaysAgo);
        final String toDate = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").format(now);
        final String currency ='';

        // Log the actual dates for debugging
        print("==================== ACCOUNT STATEMENT FILTER ====================");
        print("Customer: ${customer.name}");
        print("Filter Period: ${description ?? 'Last 30 days'}");
        print("From Date: $fromDate");
        print("To Date: $toDate");
        print("========================================================");
        
        // Add query parameters for date filtering
        final String endpoint = "/sale/customer-statement-mobile/?id=${customer.id!}&startDate=$fromDate&endDate=$toDate&currency=$currency";
        
        print("API Endpoint: $endpoint");
        
        var response = await BaseHttpClient().getAuthWithCompanyHeader(
            endpoint, user.companyId!).catchError((
            onError) {
          print("ERROR: $onError");
          if (onError is BadRequestException) {
            var apiError = json.decode(onError.message!);
            AppHelper.showErroDialog(description: apiError["reason"]);
          } else {
            AppHelper.handleError(onError);
          }
        });

        AppHelper.hideLoading();

        if (response != null) {
          var res = jsonDecode(response);
          print("RESPONSE: ${res['items']}");
          List<dynamic> list = res['items'];
          double openingBalance =  res['openingBalance'];
          double closingBalance =  res['closingBalance'];
          List<DebtorStatementProjection> itemsList = List<DebtorStatementProjection>.from(list.map((i) => DebtorStatementProjection.fromMap(i)));

          print("==================== FETCHED TRANSACTIONS (${description ?? 'Last 30 Days'}) ====================");
          print("Total records fetched: ${itemsList.length}");
          
          double totalDebit = 0.0;
          double totalCredit = 0.0;
          
          if (itemsList.isNotEmpty) {
            for (var item in itemsList) {
              totalCredit += item.credit ?? 0.0;
              totalDebit += item.debit ?? 0.0;
            }
          }
          
          // Show preview dialog
          _showStatementPreview(
            customer, 
            itemsList, 
            description ?? 'Last 30 days', 
            totalCredit, 
            totalDebit,
            openingBalance,
              closingBalance
          );
        }
      } catch (e) {
        AppHelper.hideLoading();
        Get.snackbar('Error', 'Failed to fetch sales: $e',
            snackPosition: SnackPosition.BOTTOM);
      }
    }else{
      Get.snackbar("Error", "Failed to connect to server",
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  // Default method that shows the date range dialog for viewing statement
  Future<void> viewStatement(CustomerModel customer) async {
    await showDateRangeDialog(customer);
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
    var index =allCustomers
        .indexWhere((c) => c.name == customer.name || c.name == name.value);
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
    // Reload from CustomerController to ensure proper offline handling (same as sale screen refresh fix)
    await reloadCustomersFromStorage();
    cartController.refreshCustomersFromList(List<CustomerModel>.from(allCustomers));
    List<PaymentReceivedModel> paymentTypes =[];
    paymentReceivedModel.payer = customer;
    paymentTypes.add(paymentReceivedModel);
    // Get the active shift reference for this payment (not associated with a sale)
    String? shiftRef = cartController.activeShift.shiftReference;
    cartController.updateShiftWithNewSale(ref, paymentReceivedModel.dateTime!, paymentReceivedModel.amount!, isInternetAccess.value,
        customer.name!, paymentTypes,"CASH_IN",customer.name!, false, shiftRef);
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

  Future<void> setLoyalCustomer(CustomerModel customer) async {
    List<CustomerModel> customers = allCustomers.value;
    GetStorage bb = GetStorage();
    print('customer: ${customer.name}');
    int? index  = allCustomers
          .indexWhere((c) => c.name == customer.name || c.name == name.value);

    print('index: $index ');
    customer.isLoyalCustomer = true;
    customer.updated = true;
    print('customer: ${customers[index].name}');
    allCustomers[index] = customer;
    allCustomers.refresh();
    filteredCustomers = allCustomers;
    filteredCustomers.refresh();
    // allCustomers.value = customers;
    // filteredCustomers.value = customers;
    List<Map<String, dynamic>> itemsListMap =
        allCustomers.map((item) => item.toMap()).toList();
    bb.write(AppConstants.CUSTOMER_LIST, itemsListMap);
    // Reload from CustomerController to ensure proper offline handling (same as sale screen refresh fix)
    await reloadCustomersFromStorage();
    cartController.refreshCustomersFromList(List<CustomerModel>.from(allCustomers));
    allCustomers.refresh();
    filteredCustomers.refresh();
    Get.snackbar("Edit Customer", "Customer updated Successfully",
        snackPosition: SnackPosition.BOTTOM);
    clearForm();
  }

  Future<void> updateCustomerInfo() async {
    GetStorage bb = GetStorage();
    final CustomerModel? selected = selectedCustomer.value;
    // Try to locate the customer using stable identifiers first
    int index = -1;
     if (selected != null) {
      index = filteredCustomers.indexWhere((c) =>
          (selected.id != null && selected.id!.isNotEmpty && c.id == selected.id) ||
          (selected.customerId != null && selected.customerId!.isNotEmpty && c.customerId == selected.customerId) ||
          (selected.accountNumber != null && selected.accountNumber!.isNotEmpty &&
              c.accountNumber == selected.accountNumber));
    }
    // Fallback to matching by current or previous name
    if (index == -1) {
      index = allCustomers
          .indexWhere((c) => c.name == selected?.name || c.name == name.value);
    }

    if (index == -1) {
      Get.snackbar("Error", "Could not find customer to update",
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    CustomerModel customer = allCustomers[index];
    customer.name = name.value;
    customer.accountNumber = accountNumber.value;
    customer.taxNumber = vat.value;
    customer.tinNumber = tin.value;
    customer.email = email.value;
    customer.mobilePhone = mobilePhone.value;
    customer.nfcCardId = nfcCardId.value;
    customer.nfcCardType = nfcCardType.value;
    customer.street = address.value;
    customer.description = description.value;
    customer.updated = true;

    allCustomers[index] = customer;
    List<CustomerModel> customers = allCustomers.value;
    allCustomers.value = customers;
    filteredCustomers.value = customers;
    allCustomers.refresh();
    filteredCustomers.refresh();
    List<Map<String, dynamic>> itemsListMap =
        customers.map((item) => item.toMap()).toList();
    bb.write(AppConstants.CUSTOMER_LIST, itemsListMap);
    // Reload from CustomerController to ensure proper offline handling (same as sale screen refresh fix)
    await reloadCustomersFromStorage();
    cartController.refreshCustomersFromList(List<CustomerModel>.from(allCustomers));
    Get.snackbar("Edit Customer", "Customer updated Successfully",
        snackPosition: SnackPosition.BOTTOM);
    Navigator.of(Get.overlayContext!).pop();
    editCustomer.value = false;
    selectedCustomer.value = CustomerModel();
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
      onConfirm: () async {
        print("CLICKED");
        await saveCustomerInfo();
        // saveCustomerInfo() already reloads and refreshes customers, so this is redundant but safe
        Navigator.of(Get.overlayContext!).pop();
       Get.back();
      },
    );
  }


  Future<void>  getCustomers(UserModel user, GetStorage box, String companyId) async{
    // Check connectivity first
    bool isOnline = await _connectivityService.checkServerConnection();
    isInternetAccess.value = isOnline;
    
    if(isOnline) {
      // Online: Try to fetch from server
      List<CustomerModel> newCustomer = _localStorageService.getCustomers(box);
      newCustomer = newCustomer.where((cust)=>cust.updated ?? false).toList();
      
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
        
        // Merge server + locally updated customers without duplicating counts
        Map<String, CustomerModel> merged = {};

        String keyFor(CustomerModel c) {
          if (c.id != null && c.id!.isNotEmpty) return "id:${c.id}";
          if (c.customerId != null && c.customerId!.isNotEmpty) return "cid:${c.customerId}";
          if (c.accountNumber != null && c.accountNumber!.isNotEmpty) return "acc:${c.accountNumber}";
          final branchKey = c.branch?.id ?? c.branch?.name ?? '';
          return "name:${c.name}|branch:$branchKey";
        }

        // Prefer server versions first
        for (final c in itemsList) {
          merged[keyFor(c)] = c;
        }
        // Override with locally updated records (authoritative)
        for (final c in newCustomer) {
          merged[keyFor(c)] = c;
        }

        List<CustomerModel> mergedList = merged.values.toList();
        allCustomers.value = mergedList;
        List<Map<String, dynamic>> itemsListMap =
            mergedList.map((item) => item.toMap()).toList();
        // showSnackBar("Message", "Customers downloaded successfully");
        box.write(AppConstants.CUSTOMER_LIST, itemsListMap);
      } else {
        // Response is null (server error but still online) - fall back to offline storage
        print("CustomerController getCustomers: Server response is null, falling back to offline storage");
        await reloadCustomersFromStorage();
        return; // reloadCustomersFromStorage already handles filtering and refresh
      }
    } else {
      // Offline: Use reloadCustomersFromStorage which has proper offline handling
      await reloadCustomersFromStorage();
      return; // reloadCustomersFromStorage already handles filtering and refresh
    }
    
    // Ensure WalkIn customer exists before filtering
    if(allCustomers.isEmpty || !allCustomers.any((c) => c.name?.toLowerCase().contains('walkin') ?? false)) {
      CustomerModel walkInCustomer = CustomerModel(
        id: null, 
        name: 'WalkIn', 
        branch: branch != null 
          ? BaseNameModel(id: branch!.id, name: branch!.name)
          : null
      );
      allCustomers.add(walkInCustomer);
      print("CustomerController getCustomers: Added WalkIn customer before filtering");
    }
    
    // Filter by branch but always include WalkIn (only if online and got response)
    /*if(branch != null) {
      print("Filtering customers by branch: ${branch!.name}");
      print("Customers before filter: ${allCustomers.length}");
      // Filter by branch but always include WalkIn
      List<CustomerModel> filteredByBranch = allCustomers.value.where((cus) => 
        (cus.branch != null && cus.branch!.name == branch!.name) || cus.name == "WalkIn"
      ).toList();
      
      // If filtering leaves too few customers compared to available, fall back to original list (offline-friendly)
      if (filteredByBranch.length < 5 && allCustomers.length > filteredByBranch.length) {
        filteredCustomers.value = allCustomers.value; // Fallback to full list
        print("Customers after filter (fallback to full list): ${allCustomers.length}");
      } else {
        filteredCustomers.value = filteredByBranch;
        print("Customers after filter: ${filteredCustomers.length}");
      }
    } else {
      filteredCustomers.value = allCustomers.value;
    }*/
    filteredCustomers.value = allCustomers.value;
    
    allCustomers.refresh();
    filteredCustomers.refresh();
    
    // Ensure customers are written to storage after refresh
    if(allCustomers.isNotEmpty) {
      try {
        List<Map<String, dynamic>> customersListMap = allCustomers.map((item) => item.toMap()).toList();
        box.write(AppConstants.CUSTOMER_LIST, customersListMap);
        print("Written ${allCustomers.length} customer(s) to storage after refresh");
      } catch (e) {
        print("Error writing customers to storage after refresh: $e");
      }
    }
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
    editCustomer.value = false;
    selectedCustomer.value = CustomerModel();
    nfcCardId.value = "";
    nfcCardType.value = "";
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
    // Exclude ACC- and CREDIT- payment types when crediting customer account (can't use account/credit to add money to account)
    tempList = tempList.where((type) => 
      !type.name!.startsWith("ACC-") && 
      !(type.isCredit! && type.name!.startsWith("CREDIT-"))
    ).toList();
    
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
