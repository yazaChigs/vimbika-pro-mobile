import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_rx/get_rx.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:presentation_displays/displays_manager.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';
import 'package:vimbika_pos_app/src/constants/app_constants.dart';
import 'package:vimbika_pos_app/src/constants/app_routes.dart';
import 'package:vimbika_pos_app/src/features/authentication/model/user_model.dart';
import 'package:vimbika_pos_app/src/features/customers/model/customer_currency_amount.dart';
import 'package:vimbika_pos_app/src/features/printers/model/available_printer_model.dart';
import 'package:vimbika_pos_app/src/features/sale/controller/sale_controller.dart';
import 'package:vimbika_pos_app/src/features/sale/model/cart_item_model.dart';
import 'package:vimbika_pos_app/src/features/sale/model/product_full_info_model.dart';
import 'package:vimbika_pos_app/src/features/sale/model/inventory_item_model.dart';
import 'package:vimbika_pos_app/src/features/sale/model/sale_infor_model.dart';
import 'package:vimbika_pos_app/src/features/sale/model/sale_item_model.dart';
import 'package:vimbika_pos_app/src/features/sale/model/sale_model.dart';
import 'package:vimbika_pos_app/src/features/sale/screen/sale_screen.dart';
import 'package:vimbika_pos_app/src/features/sale_receipts/controller/receipt_controller.dart';
import 'package:vimbika_pos_app/src/features/sale_receipts/screen/pdf_web_view_screen.dart';
import 'package:vimbika_pos_app/src/features/shift/controller/shift_controller.dart';
import 'package:vimbika_pos_app/src/features/shift/model/currency_amount.dart';
import 'package:vimbika_pos_app/src/features/shift/model/shift_model.dart';
import 'package:vimbika_pos_app/src/features/shift/screen/pdf_preview_screen.dart';
import 'package:vimbika_pos_app/src/features/ticket/controller/ticket_controller.dart';
import 'package:vimbika_pos_app/src/services/app_exceptions.dart';
import 'package:vimbika_pos_app/src/services/background_service.dart';
import 'package:vimbika_pos_app/src/services/base_http_client.dart';
import 'package:vimbika_pos_app/src/services/connectivity_service.dart';
import 'package:vimbika_pos_app/src/services/generate_flutter_pdf.dart';
import 'package:vimbika_pos_app/src/services/local_storage_service.dart';
import 'package:vimbika_pos_app/src/services/printer_service.dart';
import 'package:vimbika_pos_app/src/services/sync_lock_service.dart';
import 'package:vimbika_pos_app/src/services/sync_service.dart';
import 'package:vimbika_pos_app/src/shared/models/bank_model.dart';
import 'package:vimbika_pos_app/src/shared/models/base_name_model.dart';
import 'package:vimbika_pos_app/src/shared/models/branch_model.dart';
import 'package:vimbika_pos_app/src/shared/models/company_model.dart';
import 'package:vimbika_pos_app/src/shared/models/currency_model.dart';
import 'package:vimbika_pos_app/src/shared/models/customer_model.dart';
import 'package:vimbika_pos_app/src/shared/models/payment_received_model.dart';
import 'package:vimbika_pos_app/src/shared/models/payment_type_model.dart';
import 'package:vimbika_pos_app/src/utils/app_helper.dart';

import '../../../shared/models/settings_model.dart';
import '../../../services/nfc_service.dart';
import '../../customers/controller/customer_controller.dart';

class CartController extends GetxController {
  var cartItems = <CartItemModel>[].obs;
  var sale = <SaleModel>[].obs;
  var currency = CurrencyModel().obs;
  final ConnectivityService _connectivityService = ConnectivityService();
  Rx<CurrencyModel?> selectedCurrency = CurrencyModel().obs;
  Rx<CurrencyModel?> baseCurrency = CurrencyModel().obs;
  // Only use DisplayManager on non-Windows platforms
  DisplayManager? display = Platform.isWindows ? null : DisplayManager();

  Rx<BranchModel?> branch = BranchModel().obs;
  RxList<CurrencyModel> currencyList = <CurrencyModel>[].obs;
  RxList<UserModel> userList = <UserModel>[].obs;
  List<SaleInfoModel> offlineSales = <SaleInfoModel>[];
  List<SaleInfoModel> allSales = <SaleInfoModel>[];
  RxList<PaymentReceivedModel> paymentReceivedList = <PaymentReceivedModel>[].obs;
  var isCurrencySelected = false.obs;
  var isUserSelected = false.obs;
  var isPrinterAvailable = false.obs;
  RxBool multiple = false.obs;
  final TextEditingController customerSearchController =
      TextEditingController();
  RxString searchText = ''.obs;
  RxString selectedTicketRef = ''.obs;
  RxDouble totalAmountPaid = 0.0.obs;
  // Tracks which monetary input is active for numpad/quick-amount routing: none | amountPaid | tip | amtToAcc
  RxString activeInput = 'none'.obs;

  Rx<PaymentTypeModel?> selectedPaymentType = PaymentTypeModel().obs;
  RxList<PaymentTypeModel> selectedPaymentTypes = <PaymentTypeModel>[].obs;
  Rx<BankModel?> selectedBank = BankModel().obs;
  var isFirstQuickAmountButtonUsed = false.obs;
  RxList<PaymentReceivedModel> paymentTypes = <PaymentReceivedModel>[].obs;
  RxList<PaymentTypeModel> paymentTypesList = <PaymentTypeModel>[].obs;
  RxList<PaymentTypeModel> filteredPaymentTypesList = <PaymentTypeModel>[].obs;
  var isPaymentTypeSelected = false.obs;
  final TextEditingController amountPaidTextEditingController = TextEditingController();
  var hasAmountText = false.obs;
  final TextEditingController amtToAccTextEditingController = TextEditingController();
  final TextEditingController tipAmtTextEditingController = TextEditingController();
  // Track current tip and change-to-account values as observables (for UI rebuilds/validation)
  RxDouble tipValue = 0.0.obs;
  RxDouble amtToAccValue = 0.0.obs;
  
  // Flag to track if amountPaid was manually entered (to preserve it when cart changes)
  var isAmountPaidManuallyEntered = false.obs;

  RxDouble totalCostInBaseCurrency = 0.0.obs;
  RxDouble totalCostInSelectedCurrency = 0.0.obs;
  RxDouble totalTaxInBaseCurrency = 0.0.obs;
  RxDouble totalTaxInSelectedCurrency = 0.0.obs;
  RxDouble amountPaid = 0.0.obs;
  RxDouble paymentTypeAmountPaid = 0.0.obs;
  RxDouble customerAmountPaid = 0.0.obs;
  RxDouble change = 0.0.obs;

  RxList<CustomerModel> allCustomers = <CustomerModel>[].obs;
  Rx<CustomerModel?> selectedCustomer = CustomerModel().obs;
  Rx<UserModel?> user = UserModel(firstName: "", lastName: "", userName: "").obs;
  var isCustomerSelected = false.obs;
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  var activeShift = ShiftModel();
  var shiftAvailable = false.obs;
  RxList<ShiftModel> shiftList = <ShiftModel>[].obs;
  // RxList<BankModel> bankList = <BankModel>[].obs;
  final LocalStorageService _localStorageService = LocalStorageService();
  late GetStorage box;

  bool sellNilItems = false;

  // NFC Service
  final NfcService _nfcService = Get.put(NfcService());
  var isNfcReading = false.obs;
  RxBool isPrintEnabled = false.obs; // Observing the state of the checkbox
  RxBool isKOTEnaabled = false.obs; // Observing the state of the checkbox
  RxBool rearScreenAvailable = false.obs; // Observing the state of the checkbox
  RxBool addAmtToAcc = false.obs; // Observing the state of the checkbox
  late SettingsModel settingsModel = SettingsModel(sellNilItems: false);
  RxBool isFiscaliseReceiptEnabled = false.obs;
  RxBool isCustomerEmailValid = false.obs;
  RxBool emailReceipt = false.obs;
  RxBool fiscalizeReceipt = false.obs;
  RxBool zimraFiscalizeReceipt = false.obs;
  
  // Method to check and update fiscal status from storage (similar to web version)
  void checkFiscalDeviceStatus() {
    final fiscalStatus = box.read(AppConstants.IS_FISCALISATION_ENABLED) ?? false;
    final deviceFiscalSetting = box.read(AppConstants.DEFAULT_FISCAL_SETTING) ?? false;

    // if (fiscalStatus != fiscalizeReceipt.value) {
    //   fiscalizeReceipt.value = fiscalStatus;
    //   if (fiscalStatus && deviceFiscalSetting) {
    //     isFiscaliseReceiptEnabled.value = true;
    //     zimraFiscalizeReceipt.value = true;
    //   } else if (!fiscalStatus) {
    //     isFiscaliseReceiptEnabled.value = false;
    //     zimraFiscalizeReceipt.value = false;
    //   }
    // }
  }
  Rx<CompanyModel?> company = CompanyModel().obs;

  // Debouncer for charge operation
  Timer? _chargeDebouncer;
  var isCharging = false.obs;
  bool _isCharging = false;

  // Text controllers for the add new customer dialog
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();

  final TextEditingController vatEditingController = TextEditingController();
  final TextEditingController tinEditingController = TextEditingController();
  final TextEditingController addressEditingController =
      TextEditingController();
  // Form key to validate the form
  var formKeyAddCustomer = GlobalKey<FormState>();
  final PrinterService _printerService = Get.put(PrinterService());
  final SyncLockService _syncLockService = Get.put(SyncLockService());
  RxList<AvailablePrinterModel> availablePrinters =
      <AvailablePrinterModel>[].obs;
  var saleTicketId = "".obs;
  var accountPayType = "".obs;

  get formKeyAddAmount => null;

  // Method to refresh shift information for the current user
  // This should be called when the sale screen is accessed to ensure correct shift is loaded
  Future<void> refreshShiftForCurrentUser() async {
    // Reload user to ensure we have the latest user data
    var model = box.read(AppConstants.USER_INFO) ?? {};
    if(model.isNotEmpty){
      user.value = UserModel.fromMap(Map<String, dynamic>.from(model));
      
      // Ensure user.value matches an instance in userList to prevent dropdown errors
      if (user.value != null && user.value!.id != null && userList.isNotEmpty) {
        try {
          UserModel foundUser = userList.firstWhere((u) => u.id == user.value!.id);
          user.value = foundUser; // Use the instance from the list
        } catch (e) {
          // User not found in list, keep current instance
        }
      }
    }
    
    // Reload shifts and get the active shift for the current user
    List<ShiftModel> tempShiftList = loadShifts(box);
    ShiftModel? tempActiveShift = await _localStorageService.getActiveShift(
        tempShiftList, box, user.value!, true);
    
    if (tempActiveShift != null) {
      activeShift = tempActiveShift;
      shiftAvailable.value = true;
      shiftList.value = tempShiftList;
      print("Refreshed shift: ${activeShift.shiftReference} for user ${user.value!.userName} (ID: ${user.value!.id})");
    } else {
      shiftAvailable.value = false;
      shiftList.value = tempShiftList;
      print("No active shift found for user ${user.value!.userName} (ID: ${user.value!.id})");
    }
  }

  @override
  Future<void> onInit() async {
    super.onInit();
    // isInternetAccess.value =  await _connectivityService.checkConnection();
    box = GetStorage();
    var alwaysPrint = box.read(AppConstants.ALWAYS_PRINT) ?? false;
    if (alwaysPrint) {
      isPrintEnabled.value = true;
    } else {
      isPrintEnabled.value = false;
    }
    var printKOT = box.read(AppConstants.USE_KOT) ?? false;
    if (printKOT) {
      isKOTEnaabled.value = true;
    } else {
      isKOTEnaabled.value = false;
    }
    List<SaleInfoModel> sales = getExistingOfflineSales(box);
    List<SaleInfoModel> actualSales = [];
    for (SaleInfoModel s in sales) {
      if (s.sale!.saleStatus == "COMPLETE" || s.sale!.saleStatus == "PENDING") {
        actualSales.add(s);
      }
    }
    actualSales =
        actualSales.where((sale) => sale.syncStatus == false).toList();
    offlineSales = actualSales;
    allSales = actualSales;
    var model = box.read(AppConstants.USER_INFO) ?? {};
    user.value = UserModel.fromMap(Map<String, dynamic>.from(model));
    isUserSelected.value = true;
    var branchModel = box.read(AppConstants.SELECTED_BRANCH) ?? {};
    branch.value = BranchModel.fromMap(Map<String, dynamic>.from(branchModel));

    // syncOfflineSales();
    var fiscalStatus = box.read(AppConstants.IS_FISCALISATION_ENABLED) ?? false;
    var deviceFiscalSetting =
        box.read(AppConstants.DEFAULT_FISCAL_SETTING) ?? false;
    // if(fiscalStatus) {
    //   zimraFiscalizeReceipt.value = branch.value!.alwaysFiscalize ?? false;
    //   isFiscaliseReceiptEnabled.value = deviceFiscalSetting;
    //   if (zimraFiscalizeReceipt.isFalse) {
    //     zimraFiscalizeReceipt.value = deviceFiscalSetting;
    //   }
    // }else{
    //   zimraFiscalizeReceipt.value = false;
    //   isFiscaliseReceiptEnabled.value = false;
    //   fiscalizeReceipt.value = false;
    // }
    tipAmtTextEditingController.text = "0.00";
    amtToAccTextEditingController.text = "0.00";
    List<PaymentReceivedModel> paymentReceiveds = loadPaymentReceived(box);
    paymentReceivedList.value = paymentReceiveds;
    var settings = box.read(AppConstants.COMPANY_SETTINGS) ?? {};
    settingsModel = SettingsModel.fromMap(Map<String, dynamic>.from(settings));
    sellNilItems = settingsModel.sellNilItems ?? false;
    List<UserModel> tempUserList = loadUsers(box);
    userList.value = tempUserList;
    
    // Ensure user.value matches an instance in userList to prevent dropdown errors
    if (user.value != null && user.value!.id != null && userList.isNotEmpty) {
      try {
        UserModel foundUser = userList.firstWhere((u) => u.id == user.value!.id);
        user.value = foundUser; // Use the instance from the list
      } catch (e) {
        // User not found in list, keep current instance
      }
    }
    
    List<ShiftModel> tempShiftList = loadShifts(box);
    var companyModel = box.read(AppConstants.ACTIVE_COMPANY) ?? {};
    company.value =
        CompanyModel.fromMap(Map<String, dynamic>.from(companyModel));

    shiftList.value = tempShiftList;
    ShiftModel? tempActiveShift = await _localStorageService.getActiveShift(
        tempShiftList, box, user.value!, true);

    if (tempActiveShift != null) {
      activeShift = tempActiveShift;
      shiftAvailable.value = true;
    } else {
      shiftAvailable.value = false;
    }
    getOfflineCurrencyList(box);
    List<PaymentTypeModel> tempList = getOfflinePaymentTypeList(box);
    paymentTypesList.value = tempList;
    filteredPaymentTypesList.value = tempList;

    List<CustomerModel> customers = loadCustomers(box);

    allCustomers.value = customers;

    // Use firstWhereOrNull to find a customer with "WalkIn" in their name (case-insensitive)
    CustomerModel? defaultCustomer = customers.firstWhereOrNull(
      (customer) =>
          customer.name != null &&
          customer.name!.toLowerCase().contains('walkin'),
    );

    if (defaultCustomer == null) {
      // If "WalkIn" is not in the list, create and add it
      defaultCustomer = CustomerModel(id: null, name: 'WalkIn', branch: BaseNameModel(id: branch.value!.id, name: branch.value!.name));
      allCustomers.add(defaultCustomer);
    }

    // Preserve existing selection if possible, else use WalkIn
    CustomerModel? preserved = _findMatchIn(allCustomers, selectedCustomer.value);
    selectedCustomer.value = preserved ?? defaultCustomer;
    isCustomerSelected.value = selectedCustomer.value != null;

    // Filter by branch but keep WalkIn and current selection
    // Store original list for fallback
    final List<CustomerModel> originalCustomers = List<CustomerModel>.from(allCustomers);
    
    /*if(branch.value != null) {
      List<CustomerModel> filteredByBranch = allCustomers.where((cus) =>
          (cus.branch != null && cus.branch!.name == branch.value!.name) ||
          cus.name == "WalkIn" ||
          (selectedCustomer.value != null && cus == selectedCustomer.value)
      ).toList();

      // If filtering leaves too few customers compared to available, fall back to original list (offline-friendly)
      if (filteredByBranch.length < 5 && originalCustomers.length > filteredByBranch.length) {
        allCustomers.value = originalCustomers; // Fallback to full list
        print("CartController onInit: Customers after filter (fallback to full list): ${originalCustomers.length}");
      } else {
        allCustomers.value = filteredByBranch;
        print("CartController onInit: Customers after filter: ${filteredByBranch.length}");
      }
    }*/

    _ensureSelectedCustomerInList();
    allCustomers.refresh();
    _rebindSelectedCustomer();
    filterPaymentTypes(selectedCurrency.value!, defaultCustomer);
    List<AvailablePrinterModel> tempPrinterList = loadAvailablePrinters(box);
    availablePrinters.value = tempPrinterList;
    //select default payment method
    var paymentTypeId = box.read(AppConstants.DEFAULT_PAYMENT_METHOD_ID) ?? "";
    for (var cur in tempList) {
      if (cur.id == paymentTypeId) {
        selectedPaymentType.value = cur;
        selectedPaymentTypes.add(cur);
        isPaymentTypeSelected.value = true;
        selectCorrectBank();
      }
    }
    // Only fetch customers from server if online and list is too small
    if(allCustomers.length<3){
      bool isOnline = await _connectivityService.checkServerConnection();
      if(isOnline) {
        await SyncService.getCustomers(user.value!, box, company.value!.id!);
        refreshCustomers();
      } else {
        // Offline: Use same offline loading logic as sale screen refresh fix
        // Try to reload from CustomerController if available (has proper offline handling)
        try {
          final CustomerController customerController = Get.find<CustomerController>();
          await customerController.reloadCustomersFromStorage();
          refreshCustomersFromList(List<CustomerModel>.from(customerController.allCustomers));
        } catch (_) {
          // CustomerController not available (e.g., after cancelSale deletes it)
          // Fallback: ensure we at least have WalkIn customer
          if(allCustomers.isEmpty || !allCustomers.any((c) => c.name?.toLowerCase().contains('walkin') ?? false)) {
            CustomerModel walkInCustomer = CustomerModel(
              id: null, 
              name: 'WalkIn', 
              branch: branch.value != null 
                ? BaseNameModel(id: branch.value!.id, name: branch.value!.name)
                : null
            );
            allCustomers.add(walkInCustomer);
            selectedCustomer.value = walkInCustomer;
            isCustomerSelected.value = true;
            allCustomers.refresh();
          }
        }
      }
    }
    // Only use display manager on non-Windows platforms
    if (display != null) {
      try {
        var displays = await display!.getDisplays();
        if(displays!.length>1) {
          rearScreenAvailable.value = true;
          display!.showSecondaryDisplay(
            displayId: 1,
            routerName: AppRoutes.SUNMI_LCD,
          );
        }
      } catch (e) {
        // Handle display manager errors gracefully
        print('Display manager error: $e');
      }
    }

  }

  List<ShiftModel> loadShifts(GetStorage box) {
    List<ShiftModel> list = _localStorageService.getOfflineList<ShiftModel>(
        AppConstants.SHIFT_LIST, (map) => ShiftModel.fromMap(map), box);
    return list;
  }

  List<BankModel> loadBanks(GetStorage box) {
    List<BankModel> list = _localStorageService.getOfflineList<BankModel>(
        AppConstants.BANK_LIST, (map) => BankModel.fromMap(map), box);
    return list;
  }

  List<AvailablePrinterModel> loadAvailablePrinters(GetStorage box) {
    List<AvailablePrinterModel> list =
        _localStorageService.getOfflineList<AvailablePrinterModel>(
            AppConstants.AVAILABLE_PRINTERS,
            (map) => AvailablePrinterModel.fromMap(map),
            box);
    return list;
  }

  refreshCustomers() {
    List<CustomerModel> customers = loadCustomers(box);
    final List<CustomerModel> original = List<CustomerModel>.from(customers);
    _refreshCustomersInternal(customers, original);
  }

  /// Apply refresh logic to a provided list (used when another controller already loaded customers)
  void refreshCustomersFromList(List<CustomerModel> customers) {
    final List<CustomerModel> original = List<CustomerModel>.from(customers);
    _refreshCustomersInternal(customers, original);
  }

  void _refreshCustomersInternal(List<CustomerModel> customers, List<CustomerModel> original) {

    // Ensure WalkIn customer exists if list is empty
    if(customers.isEmpty || !customers.any((c) => c.name?.toLowerCase().contains('walkin') ?? false)) {
      CustomerModel walkInCustomer = CustomerModel(
        id: null, 
        name: 'WalkIn', 
        branch: branch.value != null 
          ? BaseNameModel(id: branch.value!.id, name: branch.value!.name)
          : null
      );
      customers.add(walkInCustomer);
    }

    allCustomers.value = customers;

    // Use firstWhereOrNull to find a customer with "WalkIn" in their name (case-insensitive)
    CustomerModel? defaultCustomer = customers.firstWhereOrNull(
      (customer) =>
          customer.name != null &&
          customer.name!.toLowerCase().contains('walkin'),
    );

    if (defaultCustomer == null) {
      // If "WalkIn" is not in the list, create and add it
      defaultCustomer = CustomerModel(
        id: null, 
        name: 'WalkIn', 
        branch: branch.value != null 
          ? BaseNameModel(id: branch.value!.id, name: branch.value!.name)
          : null
      );
      allCustomers.add(defaultCustomer);
    }

    // Preserve existing selection if possible, else use WalkIn
    CustomerModel? preserved = _findMatchIn(customers, selectedCustomer.value);
    selectedCustomer.value = preserved ?? defaultCustomer;
    isCustomerSelected.value = selectedCustomer.value != null;
    
    // Filter by branch but always include WalkIn and the current selection
    /*if(branch.value != null) {
      List<CustomerModel> filteredByBranch = customers.where((cus) => 
        (cus.branch != null && cus.branch!.name == branch.value!.name) || 
        cus.name == "WalkIn" ||
        (selectedCustomer.value != null && cus == selectedCustomer.value)
      ).toList();

      // If filtering leaves too few customers compared to available, fall back to original list (offline-friendly)
      if (filteredByBranch.length < 5 && original.length > filteredByBranch.length) {
        customers = original;
      } else {
        customers = filteredByBranch;
      }
    }*/
    
    allCustomers.value = customers;
    _ensureSelectedCustomerInList();
    allCustomers.refresh();
    // Rebind selectedCustomer to the instance inside allCustomers to satisfy dropdown equality
    _rebindSelectedCustomer();
  }

  /// Ensure selectedCustomer points to the same instance contained in allCustomers.
  /// This is required because the dropdown compares by object identity.
  void _rebindSelectedCustomer() {
    if (allCustomers.isEmpty) return;
    CustomerModel? match;
    // Prefer match by id when available, otherwise by name.
    if (selectedCustomer.value?.id != null) {
      match = allCustomers.firstWhereOrNull((c) => c.id == selectedCustomer.value!.id);
    }
    if (match == null && selectedCustomer.value?.customerId != null) {
      match = allCustomers.firstWhereOrNull((c) => c.customerId == selectedCustomer.value!.customerId);
    }
    if (match == null && selectedCustomer.value?.accountNumber != null) {
      match = allCustomers.firstWhereOrNull((c) => c.accountNumber == selectedCustomer.value!.accountNumber);
    }
    match ??= allCustomers.firstWhereOrNull(
        (c) => c.name != null && c.name == selectedCustomer.value?.name);

    // If still no match and a branch-filter removed it, fallback to first entry
    match ??= allCustomers.firstOrNull;

    if (match != null) {
      selectedCustomer.value = match;
      isCustomerSelected.value = true;
    }
  }

  /// Ensure the currently selected customer exists in the displayed list.
  /// If the selected customer is filtered out, add it back to keep the dropdown selectable.
  void _ensureSelectedCustomerInList() {
    if (selectedCustomer.value == null) return;
    if (!allCustomers.any((c) => c == selectedCustomer.value)) {
      allCustomers.add(selectedCustomer.value!);
    }
  }

  /// Find a matching customer in a list using id -> customerId -> accountNumber -> name.
  CustomerModel? _findMatchIn(List<CustomerModel> list, CustomerModel? target) {
    if (target == null) return null;
    if (target.id != null) {
      final m = list.firstWhereOrNull((c) => c.id == target.id);
      if (m != null) return m;
    }
    if (target.customerId != null) {
      final m = list.firstWhereOrNull((c) => c.customerId == target.customerId);
      if (m != null) return m;
    }
    if (target.accountNumber != null) {
      final m = list.firstWhereOrNull((c) => c.accountNumber == target.accountNumber);
      if (m != null) return m;
    }
    return list.firstWhereOrNull((c) => c.name == target.name);
  }

  Future<void> reGetCustomers() async {
    // Check connectivity first
    bool isOnline = await _connectivityService.checkServerConnection();
    
    if (isOnline) {
      // Online: Try to get fresh customers from server via CustomerController
      try {
        CustomerController? customerController = Get.find<CustomerController>();
        if (customerController != null && customerController.user.company != null) {
          await customerController.getCustomers(
            customerController.user, 
            box, 
            customerController.user.company!.id!
          );
          // After getting customers, refresh our local list
          refreshCustomers();
        } else {
          // Fallback to refreshCustomers if CustomerController not available
          refreshCustomers();
        }
      } catch (e) {
        print("Error getting customers from server: $e");
        // Fallback to refreshCustomers on error
        refreshCustomers();
      }
    } else {
      // Offline: Just reload from local storage
      refreshCustomers();
    }
  }

  onCustomerChange(CustomerModel? newValue) {
    if (newValue == null) return;
    print("onCustomerChange -> incoming: ${newValue.name}, id: ${newValue.id}, customerId: ${newValue.customerId}, acc: ${newValue.accountNumber}");
    // Rebind to instance in allCustomers to satisfy dropdown identity checks
    CustomerModel? match;
    if (newValue.id != null) {
      match = allCustomers.firstWhereOrNull((c) => c.id == newValue.id);
    }
    if (match == null && newValue.customerId != null) {
      match = allCustomers.firstWhereOrNull((c) => c.customerId == newValue.customerId);
    }
    if (match == null && newValue.accountNumber != null) {
      match = allCustomers.firstWhereOrNull((c) => c.accountNumber != null && c.accountNumber == newValue.accountNumber);
    }
    match ??= allCustomers.firstWhereOrNull((c) => c.name == newValue.name);

    // If not found in current list (e.g., filtered out), add it and use that instance
    if (match == null) {
      allCustomers.add(newValue);
      match = newValue;
      print("onCustomerChange -> added missing customer to list: ${newValue.name}");
    }

    selectedCustomer.value = match;
    isCustomerSelected.value = true;
    print("onCustomerChange -> selected: ${selectedCustomer.value?.name}, id: ${selectedCustomer.value?.id}, acc: ${selectedCustomer.value?.accountNumber}");
    validateEmail(selectedCustomer.value?.email);
    _ensureSelectedCustomerInList();
    allCustomers.refresh();
    print("onCustomerChange -> allCustomers length: ${allCustomers.length}, contains selected: ${allCustomers.contains(selectedCustomer.value)}");
    filterPaymentTypes(selectedCurrency.value!, selectedCustomer.value!);
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
    if((!(selectedCus.isLoyalCustomer??false)) && (selectedCus.currencyBalance?.isNotEmpty??false)){
      tempList = tempList.where((type)=>!type.name!.startsWith("ACC-")).toList();
    }

    // Check if "Add to Account" button is active (amountPaid > 0, cart is empty, customer is loyal)
    bool isAddToAccountMode = amountPaid.value > 0 && 
                               cartItems.value.isEmpty && 
                               (selectedCus.isLoyalCustomer ?? false);
    
    // Exclude ACC- and CREDIT- payment types when adding to account (can't use account/credit to add money to account)
    if (isAddToAccountMode) {
      tempList = tempList.where((type) => 
        !type.name!.startsWith("ACC-") && 
        !(type.isCredit! && type.name!.startsWith("CREDIT-"))
      ).toList();
    }

    // Exclude ACC- and CREDIT- payment types when both amount paid and change to account are present
    // (can't use account/credit payment when paying money AND adding money to account simultaneously)
    double amtToAccValue = 0.0;
    if (amtToAccTextEditingController.text.isNotEmpty) {
      try {
        amtToAccValue = double.parse(amtToAccTextEditingController.text);
      } catch (e) {
        amtToAccValue = 0.0;
      }
    }
    if (amountPaid.value > 0 && amtToAccValue > 0) {
      tempList = tempList.where((type) => 
        !type.name!.startsWith("ACC-") && 
        !(type.isCredit! && type.name!.startsWith("CREDIT-"))
      ).toList();
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

  Future<void> addToCart(ProductFullInfoModel product, double quantity) async {
    var index = cartItems.indexWhere((item) => item.product.id == product.id);
    if (index != -1 && cartItems[index].quantity + 1 > product.stock!.toDouble() && !sellNilItems) {
      Get.snackbar("Check your Quantity",
          "Quantity can not be greater than stock available!!!",
          snackPosition: SnackPosition.BOTTOM);
    } else {
      if (quantity == 0.001) {
        quantity = 1.00;
      }
      if (index != -1) {
        CartItemModel item = cartItems[index];
        item.quantity = item.quantity + quantity;
      } else {
        cartItems.add(CartItemModel(product: product, quantity: quantity));
      }
      cartItems.refresh();
      calculateTotalAmounts(cartItems);
      // Refresh payment types when cart items change (affects "Add to Account" mode)
      if (selectedCurrency.value != null && selectedCustomer.value != null) {
        filterPaymentTypes(selectedCurrency.value!, selectedCustomer.value!);
      }
    }
  }

  postToRearScreen() async {
    final cartData = {
      'companyName': user.value!.companyName??"VIMBIKA POS",
      'total': totalCostInSelectedCurrency.value,
      'change': change.value,
      'currency': selectedCurrency.value!.name,
      'imageUrl': '${AppConstants.VIMBIKA_BACKEND_URL}/company/logo/${company.value!.id}',
      'items': cartItems.isNotEmpty
          ? List<String>.from(cartItems.map((x) =>  '${x.product.item!.name} X ${x.quantity}\t\t [${selectedCurrency.value!.symbol} ${x.product.item!.sellingPrice*x.quantity} ]'))
          : [],
      'numberOfItems':cartItems.fold(0.0, (previousValue, element) => previousValue + element.quantity)
    };
    if (display != null) {
      try {
        await display!.transferDataToPresentation(cartData);
      } catch (e) {
        print('Display manager error: $e');
      }
    }
  }

  void addToCartWithBarCode(
      ProductFullInfoModel product, double quantity, String usedCode) {
    Set<String> itemCodes = {};
    var index = cartItems.indexWhere((item) => item.product.id == product.id);
    if (index != -1 &&
        cartItems[index].quantity + 1 > product.stock!.toDouble() &&
        !sellNilItems) {
      Get.snackbar("Check your Quantity",
          "Quantity can not be greater than stock available!!!",
          snackPosition: SnackPosition.BOTTOM);
    } else {
      if (quantity == 0.001) {
        quantity = 1.00;
      }
      if (index != -1) {
        CartItemModel item = cartItems[index];
        item.quantity = item.quantity + quantity;
        item.usedCodes.add(usedCode);
        itemCodes = item.usedCodes;
        // cartItems[index].quantity++;
      } else {
        itemCodes.add(usedCode);
        cartItems.add(CartItemModel(
            product: product, quantity: quantity, usedCodes: itemCodes));
      }
      calculateTotalAmounts(cartItems);
    }
  }

  void removeFromCart(CartItemModel cartItem) {
    cartItems.remove(cartItem);
    calculateTotalAmounts(cartItems);
    // Refresh payment types when cart items change (affects "Add to Account" mode)
    if (selectedCurrency.value != null && selectedCustomer.value != null) {
      filterPaymentTypes(selectedCurrency.value!, selectedCustomer.value!);
    }
  }

  void incrementQuantity(CartItemModel cartItem) {
    cartItem.quantity++;
    if (cartItem.quantity > cartItem.product.stock!.toDouble() &&
        !sellNilItems) {
      Get.snackbar("Check your Quantity",
          "Quantity can not be greater than stock available!!!",
          snackPosition: SnackPosition.BOTTOM);
      cartItem.quantity = cartItem.product.stock!.toDouble();
    } else {
      calculateTotalAmounts(cartItems);
      cartItems.refresh();
    }
  }

  void decrementQuantity(CartItemModel cartItem) {
    if (cartItem.quantity > 1) {
      cartItem.quantity--;
    } else {
      removeFromCart(cartItem);
    }
    calculateTotalAmounts(cartItems);
    cartItems.refresh();
  }

  calculateTotalAmounts(List<CartItemModel> items) {
    double totalCostInBCurrency =
        items.fold(0.0, (sum, item) => sum + item.totalPrice);
    double? rate = selectedCurrency.value?.rate ?? 1;
    totalCostInBaseCurrency.value = totalCostInBCurrency;
    totalCostInSelectedCurrency.value = totalCostInBCurrency * rate;
    totalTaxInBaseCurrency.value =
        items.fold(0, (sum, item) => sum + item.totalTaxAmount);
    
    // Preserve manual amountPaid entry (Option A)
    // Only auto-fill if amountPaid was NOT manually entered
    if (!isAmountPaidManuallyEntered.value) {
      amountPaidTextEditingController.text =
          totalCostInSelectedCurrency.value.toStringAsFixed(2);
      hasAmountText.value = true;
      amountPaid.value = totalCostInSelectedCurrency.value;
      customerAmountPaid.value = totalCostInSelectedCurrency.value;
    }
    // If manually entered, preserve the existing amountPaid and just recalculate change
    
    if (selectedPaymentType.value != null  && !multiple.value) {
      selectedPaymentType.value!.amount = totalCostInSelectedCurrency.value;
    }
    if (selectedPaymentTypes.isNotEmpty && !multiple.value) {
      selectedPaymentTypes.first.amount = totalCostInSelectedCurrency.value;
    }
    
    // Recalculate change after totals update (preserves manual amountPaid)
    _recalculateChange();
    
    if(rearScreenAvailable.value){
      postToRearScreen();
    }
  }
  
  /// Recalculate change based on current amountPaid, totalCost, tip, and amtToAcc
  void _recalculateChange() {
    final tipAmount = tipValue.value;
    final amtToAcc = amtToAccValue.value;

    if (amountPaid.value >= totalCostInSelectedCurrency.value) {
      change.value = amountPaid.value - totalCostInSelectedCurrency.value - amtToAcc - tipAmount;
    } else {
      change.value = 0.0;
    }
  }

  void validateEmail(String? value) {
    if (value != null) {
      if (value.isEmpty) {
        isCustomerEmailValid.value = false;
      } else if (!GetUtils.isEmail(value)) {
        isCustomerEmailValid.value = false;
      } else {
        isCustomerEmailValid.value = true;
      }
    } else {
      isCustomerEmailValid.value = false;
    }
  }

  // double get totalAmount => cartItems.fold(0, (sum, item) => sum + item.totalPrice);
  // double get totalTaxAmount => cartItems.fold(0, (sum, item) => sum + item.totalTaxAmount);

  Future<void> checkout() async {
    if (shiftAvailable.isFalse) {
      openShift();
    } else {
      if (activeShift != null && activeShift.isShiftClosed == false) {
        Get.toNamed(AppRoutes.CHECKOUT);
      } else {
        List<ShiftModel> tempShiftList = loadShifts(box);
        shiftList.value = tempShiftList;
        ShiftModel? tempActiveShift = await _localStorageService.getActiveShift(
            tempShiftList, box, user.value!, true);
        if (tempActiveShift != null) {
          activeShift = tempActiveShift;
          Get.toNamed(AppRoutes.CHECKOUT);
        } else {
          openShift();
        }
      }
    }
  }

  openShift() {
    Get.snackbar("Create Shift", "Open a shift to proceed",
        snackPosition: SnackPosition.BOTTOM);
    Get.delete<CartController>();
    Get.delete<SaleController>();
    Get.offNamed(AppRoutes.OPEN_SHIFT);
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
      
      // First, find and set the base currency (needed for calculations)
      for (var cur in currencies) {
        if (cur.isBaseCurrency!) {
          baseCurrency.value = cur;
          // Set base currency as fallback if no default currency is set
          if (currencyId.isEmpty) {
            selectedCurrency.value = cur;
            isCurrencySelected.value = true;
          }
        }
      }
      
      // Then, prioritize default currency from settings if it exists
      if (currencyId.isNotEmpty) {
        for (var cur in currencies) {
          if (cur.id == currencyId) {
            selectedCurrency.value = cur;
            isCurrencySelected.value = true;
            break; // Found default currency, no need to continue
          }
        }
      }
      
      // If no currency is selected yet (shouldn't happen, but safety check)
      if (!isCurrencySelected.value && currencies.isNotEmpty) {
        selectedCurrency.value = currencies.first;
        isCurrencySelected.value = true;
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

  List<UserModel> loadUsers(GetStorage box) {
    List<UserModel> list = _localStorageService.getOfflineList<UserModel>(
        AppConstants.USER_LIST, (map) => UserModel.fromMap(map), box);
    
    // Deduplicate users by ID to prevent dropdown errors
    Map<String, UserModel> uniqueUsers = {};
    for (UserModel userModel in list) {
      if (userModel.id != null && !uniqueUsers.containsKey(userModel.id)) {
        uniqueUsers[userModel.id!] = userModel;
      }
    }
    
    // Add current user if not already in the list
    if (user.value != null && user.value!.id != null) {
      if (!uniqueUsers.containsKey(user.value!.id)) {
        uniqueUsers[user.value!.id!] = user.value!;
      }
    }
    
    return uniqueUsers.values.toList();
  }

  amountPaidChange(String val) {
    double amountPaid = double.parse(val);
    customerAmountPaid.value = amountPaid;
    this.amountPaid.value = amountPaid;
    
    // Mark as manually entered when user types in the field
    isAmountPaidManuallyEntered.value = true;
    
    // Recalculate change using helper method
    _recalculateChange();
    
    // Refresh payment types when amount changes (affects "Add to Account" mode)
    if (selectedCurrency.value != null && selectedCustomer.value != null) {
      filterPaymentTypes(selectedCurrency.value!, selectedCustomer.value!);
    }
  }

  tipAmountChange(String val) {
    // Only update the change calculation when tip changes
    // Don't modify amountPaid or customerAmountPaid
    double parsed = 0.0;
    if (val.isNotEmpty) {
      try {
        parsed = double.parse(val);
      } catch (_) {
        parsed = 0.0;
      }
    }
    tipValue.value = parsed;
    _recalculateChange();
  }

  amtToAccChange(String val) {
    // Update change calculation when "Change to Account" amount changes
    double parsed = 0.0;
    if (val.isNotEmpty) {
      try {
        parsed = double.parse(val);
      } catch (_) {
        parsed = 0.0;
      }
    }
    amtToAccValue.value = parsed;
    _recalculateChange();
    
    // Refresh payment types when change to account changes
    // This ensures ACC- and CREDIT- payment types are hidden when both amountPaid and amtToAcc are present
    if (selectedCurrency.value != null && selectedCustomer.value != null) {
      filterPaymentTypes(selectedCurrency.value!, selectedCustomer.value!);
    }
  }

  // Add quick amount to current amount paid (for tablet quick buttons)
  void addQuickAmount(double amount) {
    // If no active input, do nothing
    if (activeInput.value == 'none') {
      return;
    }

    // Helper to add amount to a controller and recalc via callback
    void _apply(
      TextEditingController controller,
      void Function(String) onChange,
    ) {
      String currentText = controller.text;
      double currentAmount = 0.0;
      if (currentText.isNotEmpty) {
        try {
          currentAmount = double.parse(currentText);
        } catch (_) {
          currentAmount = 0.0;
        }
      }
      double newAmount = currentAmount + amount;
      String newAmountText = newAmount.toStringAsFixed(2);
      controller.text = newAmountText;
      onChange(newAmountText);
    }

    if (activeInput.value == 'amountPaid') {
      // Clear field on first button use for amount paid
      if (!isFirstQuickAmountButtonUsed.value) {
        amountPaidTextEditingController.clear();
        amountPaid.value = 0.0;
        customerAmountPaid.value = 0.0;
        change.value = 0.0;
        hasAmountText.value = false;
        isFirstQuickAmountButtonUsed.value = true;
        isAmountPaidManuallyEntered.value = false; // Reset flag when cleared
      }
      _apply(amountPaidTextEditingController, (val) {
        isAmountPaidManuallyEntered.value = true;
        hasAmountText.value = true;
        amountPaid.value = double.tryParse(val) ?? 0.0;
        customerAmountPaid.value = amountPaid.value;
        amountPaidChange(val);
      });
    } else if (activeInput.value == 'tip') {
      _apply(tipAmtTextEditingController, (val) {
        tipAmountChange(val);
      });
    } else if (activeInput.value == 'amtToAcc') {
      _apply(amtToAccTextEditingController, (val) {
        amtToAccChange(val);
      });
    }

    // Refresh payment types
    if (selectedCurrency.value != null && selectedCustomer.value != null) {
      filterPaymentTypes(selectedCurrency.value!, selectedCustomer.value!);
    }
  }

  // Clear amount paid field (for tablet clear button)
  void clearAmountPaid() {
    amountPaidTextEditingController.clear();
    amountPaid.value = 0.0;
    customerAmountPaid.value = 0.0;
    change.value = 0.0;
    hasAmountText.value = false;
    isFirstQuickAmountButtonUsed.value = false; // Reset flag when cleared
    isAmountPaidManuallyEntered.value = false; // Reset flag when cleared
    // Refresh payment types when amount is cleared (affects "Add to Account" mode)
    if (selectedCurrency.value != null && selectedCustomer.value != null) {
      filterPaymentTypes(selectedCurrency.value!, selectedCustomer.value!);
    }
  }

  void showConfirmDialogChargeSale() {
    debouncedChargeSale();
  }

  // Debounced charge method to prevent double-clicks
  void debouncedChargeSale() {
    _chargeDebouncer?.cancel();
    
    if (_isCharging) {
      Get.snackbar("Info", "Charge operation in progress...",
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    
    _chargeDebouncer = Timer(Duration(milliseconds: 500), () {
      _performCharge();
    });
  }

  // Internal method that performs the actual charge
  Future<void> _performCharge() async {
    if (_isCharging) return;
    
    _isCharging = true;
    isCharging.value = true;
    
    try {
      // Validate payment before charging
      double tipAmount = tipValue.value;
      double amtToAcc = amtToAccValue.value;
      
      double requiredAmount = totalCostInSelectedCurrency.value + tipAmount + amtToAcc;
      
      // Validation: amountPaid must be >= (totalCost + tipAmount + amtToAcc)
      if (amountPaid.value < requiredAmount) {
        Get.snackbar(
          "Insufficient Payment",
          "Amount paid (${amountPaid.value.toStringAsFixed(2)}) must be at least ${requiredAmount.toStringAsFixed(2)} (Total: ${totalCostInSelectedCurrency.value.toStringAsFixed(2)} + Tip: ${tipAmount.toStringAsFixed(2)} + Change to Account: ${amtToAcc.toStringAsFixed(2)})",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: Duration(seconds: 4),
        );
        return; // Don't proceed with charge
      }
      
      chargeSale("COMPLETE", false, "", "", "", cartItems, saleTicketId.value);
    } catch (e) {
      Get.snackbar("Error", "Failed to charge: ${e.toString()}",
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      _isCharging = false;
      isCharging.value = false;
    }
  }

  List<SaleItemModel> cartItemsToSaleItems(List<CartItemModel> saleCartItems){
    double totalSaleQuantity = 0;
    List<SaleItemModel> saleItems = [];
      for (var cartItem in saleCartItems) {
        InventoryItemModel productItem = cartItem.product.item!;
        totalSaleQuantity = totalSaleQuantity + cartItem.quantity;
        productItem.quantity = cartItem.quantity;
        productItem.total = cartItem.totalPrice;
        var rate = selectedCurrency.value?.rate ?? 1.0;
        SaleItemModel saleItem = SaleItemModel(
        sellingPrice: (cartItem.totalPrice/cartItem.quantity) * rate,
        notes: cartItem.notes,
        baseCurrencySellingPrice: productItem.sellingPrice,
        quantity: cartItem.quantity,
        total: cartItem.totalPrice * rate,
        baseCurrencyTotal: cartItem.totalPrice,
        taxAmount: double.parse((cartItem.totalTaxAmount * rate).toStringAsFixed(2)),
        baseTaxAmount:double.parse(cartItem.totalTaxAmount.toStringAsFixed(2)),
        inventoryItem: productItem,
        branch: branch.value,
        usedCodesString: cartItem.usedCodes);
        saleItem.id = saleCartItems.indexOf(cartItem).toString();
        if (saleItem.inventoryItem != null) {
        if (saleItem.inventoryItem!.productImages != null) {
            saleItem.inventoryItem!.productImages = [];
          }
          if (saleItem.inventoryItem!.image != null) {
            saleItem.inventoryItem!.image = "";
          }
        }
        saleItems.add(saleItem);
      }
      return saleItems;
  }

  chargeSale(
      String saleStatus,
      bool isOnHold,
      String ref,
      String ticketName,
      String ticketComment,
      List<CartItemModel> saleCartItems,
      String saleId) async {
    await _syncLockService.acquireChargeLock();
  try {
    bool stat = await _connectivityService.checkServerConnection();
    CustomerModel? customer;
    bool breakage =  cartItems.any((item) => item.breakage);
    calculateTotalAmounts(saleCartItems);
    double totalSaleQuantity = 0;
    List<SaleItemModel> saleItems = [];
    String timeInit =
        DateFormat(AppConstants.APP_DATE_TIME_FMT).format(DateTime.now());
    List<SaleInfoModel> infos = getExistingOfflineSales(box);
    int count = infos.length + 1;
    if (!isOnHold) {
      ref = AppConstants.getDateNowRef("OFF", count);
    }
    AppHelper.showLoading("Saving new sale..");

    // Reload user and shift information to ensure we have the current user's shift
    // This is critical when a user logs in after another user has logged out
    var model = box.read(AppConstants.USER_INFO) ?? {};
    if(model.isNotEmpty){
      user.value = UserModel.fromMap(Map<String, dynamic>.from(model));
    }
    
    // Reload shifts and get the active shift for the current user
    // CRITICAL: Reload from storage to ensure we have the latest shifts including any newly opened ones
    List<ShiftModel> tempShiftList = loadShifts(box);
    
    // Check if SELECTED_SHIFT_REF is set (indicates a shift was explicitly chosen/opened)
    final String? selectedRef = box.read(AppConstants.SELECTED_SHIFT_REF);
    if (selectedRef != null && selectedRef.isNotEmpty) {
      print("Charge Sale: SELECTED_SHIFT_REF is ${selectedRef}, will prioritize this shift");
    }
    
    ShiftModel? tempActiveShift = await _localStorageService.getActiveShift(
        tempShiftList, box, user.value!, true);
    
    if (tempActiveShift != null) {
      // Verify the shift matches SELECTED_SHIFT_REF if it's set
      if (selectedRef != null && selectedRef.isNotEmpty && tempActiveShift.shiftReference != selectedRef) {
        print("Charge Sale: WARNING - getActiveShift returned shift ${tempActiveShift.shiftReference} but SELECTED_SHIFT_REF is ${selectedRef}");
        // Try to find the selected shift directly
        ShiftModel? selectedShift = tempShiftList.firstWhereOrNull(
          (shift) => shift.shiftReference == selectedRef &&
                     shift.userId != null &&
                     user.value!.id != null &&
                     shift.userId == user.value!.id &&
                     (shift.isShiftClosed == null || shift.isShiftClosed == false)
        );
        if (selectedShift != null) {
          print("Charge Sale: Found selected shift ${selectedRef} directly, using it instead");
          tempActiveShift = selectedShift;
        }
      }
      
      activeShift = tempActiveShift;
      shiftAvailable.value = true;
      print("Charge Sale: Using shift ${activeShift.shiftReference} for user ${user.value!.userName} (ID: ${user.value!.id})");
    } else {
      shiftAvailable.value = false;
      print("Charge Sale: No active shift found for user ${user.value!.userName} (ID: ${user.value!.id})");
    }

    saleTicketId.value = saleId;

    saleItems = cartItemsToSaleItems(saleCartItems);
    bool isWalkIn =
        selectedCustomer.value!.name!.contains("WalkIn") ? true : false;
    List<PaymentReceivedModel> paymentTypes = [];
    for (PaymentTypeModel paymentType in selectedPaymentTypes) {
      PaymentReceivedModel paymentReceivedModel = PaymentReceivedModel(
          id: selectedPaymentTypes.indexOf(paymentType).toString(),
          amount: paymentType.amount,
          amountPaid: paymentType.amount,
          balance:paymentType.isCredit!?paymentType.amount:0.0,
          paymentType: paymentType,
          paymentDescription: !breakage?"SALE":"BREAKAGE",
          isPaid: true,
          isMobile: true,
          currency: selectedCurrency.value,
          bank: selectedBank.value,
        payer: selectedCustomer.value,
        branch: branch.value
      );
      paymentTypes.add(paymentReceivedModel);
      if (isOnHold) {
        paymentTypes = [];
      }
    }
    var totalTaxInSelectedCurrency =
        saleItems.fold<double>(0.0, (sum, item) => sum + item.taxAmount!);
    String fullName = user.value!.firstName + " " + user.value!.lastName;
    var saleTotal =
        saleItems.fold<double>(0.0, (sum, item) => sum + item.total!);
    if(amtToAccTextEditingController.text.isEmpty)
      amtToAccTextEditingController.text = "0.00";
    if(tipAmtTextEditingController.text.isEmpty)
      tipAmtTextEditingController.text = "0.00";
    SaleModel sale = SaleModel(
        id: saleTicketId.value.length > 2 ? saleTicketId.value : null,
        active: true,
        createdByName: user.value!.userName,
        cashierFullName: fullName,
        paymentTypes: paymentTypes,
        saleStatus: saleStatus,
        onHold: isOnHold,
        taxAmount: totalTaxInSelectedCurrency,
        amountPaid: amountPaid.value,
        totalQuantity: totalSaleQuantity,
        saleCost: 0.0,
        totalTaxAmount: totalTaxInSelectedCurrency,
        baseSaleAmount: saleTotal,
        referenceNumber: ref,
        change: change.value,
        customerAmountPaid: customerAmountPaid.value,
        timeIniated: timeInit,
        timeInit: timeInit,
        currency: selectedCurrency.value,
        baseCurrency: baseCurrency.value,
        paymentType: isOnHold ? null : selectedPaymentType.value,
        items: saleItems,
        branch: branch.value,
        amountAfterDiscount: saleTotal,
        shiftReference: activeShift.shiftReference,
        posReference: ref,
        customer: isWalkIn ? null : selectedCustomer.value,
        isWalkInCustomer: isWalkIn,
        taxInvoice: zimraFiscalizeReceipt.value,
        fiscalized: zimraFiscalizeReceipt.value,
        emailReceipt: emailReceipt.value,
        totalDiscount: 0,
        ticketName: ticketName,
        ticketComment: ticketComment,
        accountPayType: accountPayType.value,
        pointsUsed: null,
        customerAccPayType: "CASH-${selectedCurrency.value?.name}",
        customerAccBankType: "Cash-${selectedCurrency.value?.name}",
        amtToAcc: double.parse(amtToAccTextEditingController.text??"0")??0.00,
        tipAmount: double.parse(tipAmtTextEditingController.text??"0")??0.00,
    );
    SaleInfoModel saleInfoModel;
    if (isOnHold) {
      saleId = "";
      saleInfoModel = SaleInfoModel(sale: sale, syncStatus: true);
      infos.add(saleInfoModel);
      writeSaleInfor(box, infos);
      String ref  = generateOrderNumber();
      printTicket(saleInfoModel, ref);
    }
    if (stat && isFiscaliseReceiptEnabled.value && !isOnHold) {
      SaleModel? responseFromServerSale =
          await SyncService.saveSale(sale, user.value!, box, company.value!);
      if (responseFromServerSale != null) {
        if (isOnHold) {
          saleInfoModel =
              SaleInfoModel(sale: responseFromServerSale, syncStatus: true);
        } else {
          SaleInfoModel? infoModel;
          if(isFiscaliseReceiptEnabled.value) {
            infoModel = await getSale(responseFromServerSale.id!);
          }
          if (infoModel != null) {
            saleInfoModel = infoModel;
          } else {
            saleInfoModel =
                SaleInfoModel(sale: responseFromServerSale, syncStatus: true);
          }
        }
      } else {
        saleInfoModel = SaleInfoModel(sale: sale, syncStatus: false);
      }
    } else {
      saleInfoModel = SaleInfoModel(sale: sale, syncStatus: false);
    }
    if (!isOnHold) {
      infos = getExistingOfflineSales(box);
      infos.add(saleInfoModel);
      writeSaleInfor(box, infos);
      deductStock();
      if(double.parse(amtToAccTextEditingController.text)>0){
        PaymentReceivedModel paymentReceivedModel = PaymentReceivedModel(
            amount: double.parse(amtToAccTextEditingController.text),
            paymentType:saleInfoModel.sale!.paymentTypes!.first.paymentType,
            isPaid: true
        );
        List<PaymentReceivedModel> accList = [];
        accList.add(paymentReceivedModel);
        // Use the shiftReference from the sale to ensure consistency
        updateShiftWithNewSale(ref, timeInit, saleTotal,
            stat, saleInfoModel.sale!.referenceNumber!,  accList, "CASH_IN", selectedCustomer.value?.name ?? "", breakage, saleInfoModel.sale!.shiftReference);
      }
      // Use the shiftReference from the sale to ensure consistency
      updateShiftWithNewSale(ref, timeInit, saleTotal,
          stat, saleInfoModel.sale!.referenceNumber!,  paymentTypes, "SALE", selectedCustomer.value?.name ?? "", breakage, saleInfoModel.sale!.shiftReference);
      if (selectedTicketRef.isNotEmpty) {
        infos.removeWhere((ticket) =>
            ticket.sale!.referenceNumber == selectedTicketRef.value);
        selectedTicketRef.value = '';
        writeSaleInfor(box, infos);
      }
      if((sale.customer !=null) && (double.parse(amtToAccTextEditingController.text)>0)) {
        CustomerModel customer = allCustomers.firstWhere((cust) =>
        cust.name == sale.customer!.name);
        if (customer != null) {
          var index = allCustomers.indexOf(customer);
          if (customer.currencyBalance == null ||
              customer.currencyBalance!.isEmpty) {
            CustomerCurrencyAmount currencyAmount = CustomerCurrencyAmount(
              currency: selectedCurrency.value!, balance: double.parse(amtToAccTextEditingController.text),
            );
            customer.currencyBalance!.add(currencyAmount);
          } else {
            var prev = customer.currencyBalance!.firstWhere((cd) =>
            cd.currency.id == selectedCurrency.value!.id).balance;
            customer.currencyBalance!.firstWhere((cd) =>
            cd.currency.id == selectedCurrency.value!.id).balance =
            (prev! + double.parse(amtToAccTextEditingController.text));
          }
          saleInfoModel.sale!.customer = customer;
          allCustomers[index] = customer;
          List<CustomerModel> customers = allCustomers.value;
          List<Map<String, dynamic>> customersListMap =
          customers.map((item) => item.toMap()).toList();
          box.write(AppConstants.CUSTOMER_LIST, customersListMap);
          // Reload from CustomerController to ensure proper offline handling (same as sale screen refresh fix)
          try {
            final CustomerController customerController = Get.find<CustomerController>();
            await customerController.reloadCustomersFromStorage();
            refreshCustomersFromList(List<CustomerModel>.from(customerController.allCustomers));
          } catch (_) {
            // Fallback: at least refresh from storage
            refreshCustomers();
          }
        }
      }
      if((sale.customer !=null) && (double.parse(amtToAccTextEditingController.text)==0.00 &&
              paymentTypes.any((pt) => pt.paymentType!.name!.startsWith("ACC-") || pt.paymentType!.name!.startsWith("CREDIT-")))){
         customer = allCustomers.firstWhere((cust)=>cust.name == sale.customer!.name);
        if(customer!=null){
          var index = allCustomers.indexOf(customer);
          if(customer.currencyBalance!=null && !customer.currencyBalance!.isEmpty) {
            var prev = customer.currencyBalance!.firstWhere((cd)=>cd.currency.id == selectedCurrency.value!.id).balance;
            // Handle both ACC- and CREDIT- payment types
            var creditPaymentType = paymentTypes.firstWhereOrNull((pt) => 
                pt.paymentType!.name!.startsWith("ACC-") || pt.paymentType!.name!.startsWith("CREDIT-"));
            if (creditPaymentType != null) {
              customer.currencyBalance!.firstWhere((cd)=>cd.currency.id == selectedCurrency.value!.id).balance = (prev! -
                  creditPaymentType.amount!);
            }
          }else{
            CustomerCurrencyAmount currencyAmount = CustomerCurrencyAmount(
            currency: selectedCurrency.value!, balance: (0 - amountPaid.value),
            );
            customer.currencyBalance!.add(currencyAmount);
          }
          customer.accountBalance = customer.accountBalance??0.00 - (amountPaid.value/selectedCurrency.value!.rate!);
          customer.updated = true;
          allCustomers[index] = customer;
          List<CustomerModel> customers = allCustomers.value;
          List<Map<String, dynamic>> customersListMap =
          customers.map((item) => item.toMap()).toList();
          box.write(AppConstants.CUSTOMER_LIST, customersListMap);
          if(stat) {
            await SyncService.saveCustomer(user.value!, box);
          }
          // Reload from CustomerController to ensure proper offline handling (same as sale screen refresh fix)
          try {
            final CustomerController customerController = Get.find<CustomerController>();
            await customerController.reloadCustomersFromStorage();
            refreshCustomersFromList(List<CustomerModel>.from(customerController.allCustomers));
          } catch (_) {
            // Fallback: at least refresh from storage
            refreshCustomers();
          }
        }
      }
      saleInfoModel.sale!.customer = customer;
      printCurrentSale(saleInfoModel, box);
      cancelSale();
      AppHelper.hideLoading();
      Get.snackbar(
        "Success",
        "Sale saved Successfully",
      );
    } else{

      cancelSale();
      AppHelper.hideLoading();
    }
  } finally {
    _syncLockService.releaseChargeLock();
  }
  }

  List<SaleInfoModel> getExistingOfflineSales2(GetStorage box) {
    List<SaleInfoModel> sales =
        _localStorageService.getOfflineList<SaleInfoModel>(
            AppConstants.SALE_LIST, (map) => SaleInfoModel.fromMap(map), box);
    return sales;
  }



  removePaymentMethod(index) {
    totalAmountPaid.value = totalAmountPaid.value - selectedPaymentTypes[index].amount!;
    selectedPaymentTypes.removeAt(index);
    selectedPaymentTypes.refresh();
  }

  void deductStock() {
    List<ProductFullInfoModel> storageProductList = getProductList(box);
    for (CartItemModel cart in cartItems) {
      for (ProductFullInfoModel pro in storageProductList) {
        if (cart.product.id == pro.id) {
          double qty = pro.stock! - cart.quantity;
          pro.stock = qty;
        }
      }
    }
    List<Map<String, dynamic>> itemsListMap =
        storageProductList.map((item) => item.toMap()).toList();
    box.write(AppConstants.BRANCH_PRODUCTS, itemsListMap);
  }

  List<ProductFullInfoModel> getProductList(GetStorage box) {
    // Read the data as a List<dynamic>
    List<dynamic>? itemsListDynamic =
        box.read<List<dynamic>>(AppConstants.BRANCH_PRODUCTS);

    // Check if the read data is not null
    if (itemsListDynamic != null) {
      // Convert the List<dynamic> to List<Map<String, dynamic>>
      List<Map<String, dynamic>> itemsListMap = itemsListDynamic.map((item) {
        return item as Map<String, dynamic>;
      }).toList();

      // Convert List<Map<String, dynamic>> to List<ProductFullInfoModel>
      return List<ProductFullInfoModel>.from(
          itemsListMap.map((map) => ProductFullInfoModel.fromMap(map)));
    } else {
      return [];
    }
  }

  void printCurrentSale(SaleInfoModel saleInfo, GetStorage box) async {
    if (isPrintEnabled.isTrue) {
      _printerService.printCurrentSale(saleInfo, box, _localStorageService);
    }
  }
  void printTicket(SaleInfoModel saleInfo, String orderNum) async {
      _printerService.printKOT(saleInfo, orderNum, box, _localStorageService);
  }
  void printCashIn(PaymentReceivedModel payment, String cashier) async {
      _printerService.printCashIn(payment,cashier, box, _localStorageService);
  }
  void printQuickTicket() async {
    String ref  = generateOrderNumber();
      _printerService.printQuickKOT(cartItems,user.value!.firstName,selectedCustomer.value!.name!,ref, box, _localStorageService);
  }

  String generateOrderNumber() {
    final NumberFormat formatter = NumberFormat('000');
    final NumberFormat dateFormatter = NumberFormat('00');
    var kotNumber = box.read(AppConstants.KOT_NUMBER);
    String ref  = "${dateFormatter.format(DateTime.now().day)}${formatter.format((kotNumber??0)+1)}";
    kotNumber==null?kotNumber = 0:kotNumber++;
    box.write(AppConstants.KOT_NUMBER, kotNumber);
    return ref;
  }

  Future<SaleInfoModel?> getSale(String saleId) async {
    await Future.delayed(Duration(seconds: 2));
    var response = await BaseHttpClient()
        .getAuthWithCompanyHeader(
            "/sale/get-item/" + saleId, user.value!.companyId!)
        .catchError((onError) {
      if (onError is BadRequestException) {
        var apiError = json.decode(onError.message!);
        AppHelper.showErroDialog(description: apiError["reason"]);
      } else {
        AppHelper.handleError(onError);
      }
    });
    if (response != null) {
      SaleModel itemConverted = SaleModel.fromJson(json.decode(response));
      SaleInfoModel saleInfoModel =
          SaleInfoModel(sale: itemConverted, syncStatus: true);
      return saleInfoModel;
    }
    return null;
  }

  updateShiftWithNewSale(
      String ref,
      String timeCreated,
      double amt,
      bool stat,
      String posReference,
      List<PaymentReceivedModel> paymentTypes, String type, String customerName ,bool breakage, String? saleShiftReference) async {
    // Reload user to ensure we have the current logged-in user
    // This is critical when a user logs in after another user has logged out
    var model = box.read(AppConstants.USER_INFO) ?? {};
    if(model.isNotEmpty){
      user.value = UserModel.fromMap(Map<String, dynamic>.from(model));
    }
    
    // CRITICAL: Use the shiftReference from the sale to ensure sales and shifts stay synchronized
    // This prevents sales from being associated with the wrong shift when multiple shifts are open
    ShiftModel? tempActiveShift;
    List<ShiftModel> allShifts = loadShifts(box);
    
    if (saleShiftReference != null && saleShiftReference.isNotEmpty) {
      // Find the exact shift that was used when creating the sale
      // NOTE: We intentionally don't check isShiftClosed here - we need to update shifts even if they're closed
      // because the sale was created when the shift was open, and we need to update that shift
      tempActiveShift = allShifts.firstWhereOrNull(
        (shift) => shift.shiftReference == saleShiftReference &&
                   shift.userId != null &&
                   user.value!.id != null &&
                   shift.userId == user.value!.id
      );
      
      if (tempActiveShift != null) {
        print("Update Shift: Using sale's shiftReference ${saleShiftReference} for user ${user.value!.userName}");
      } else {
        print("Update Shift: Sale's shiftReference ${saleShiftReference} not found, falling back to getActiveShift");
      }
    }
    
    // Fallback to getActiveShift only if sale's shiftReference not found
    if (tempActiveShift == null) {
      tempActiveShift = await _localStorageService.getActiveShift(
          allShifts, box, user.value!, true);
    }
    
    if (tempActiveShift != null) {
      activeShift = tempActiveShift;
      shiftAvailable.value = true;
      print("before shift currency");
      print(activeShift.toJson());
      for (PaymentReceivedModel paymentTypeModel in paymentTypes) {
        var isCash = paymentTypeModel.paymentType!.name!.startsWith("CASH");
        int count = activeShift.shiftCurrencyAmounts!.length + 1;
        String ref = AppConstants.getDateNowRef("SL_", count);
        CurrencyAmount currencyAmount = CurrencyAmount(
            currency: selectedCurrency.value!,
            amountType: type,
            ref: paymentTypeModel.branch==null?ref + "_" +customerName.replaceAll(" ", "_"):ref,
            timeCreated: timeCreated,
            notes: "",
            amount:paymentTypeModel.amount!,
            shiftReference: activeShift.shiftReference,
            posReference: posReference,
            isCash: isCash,
            paymentType: paymentTypeModel.paymentType!.name!);
        if(breakage){
          currencyAmount.amountType = "BREAKAGE";
          currencyAmount.paymentType = "BREAKAGE";
          currencyAmount.ref = "BR_" + count.toString();
        }
        activeShift.shiftCurrencyAmounts!.add(currencyAmount);
      }
      if(paymentTypes.any((pt)=> pt.paymentType!.name!.startsWith("CASH-"))) {
        openCashDrawer();
      }
      
      // Update the shift in the list and persist
      int shiftIndex = allShifts.indexWhere((s) => s.shiftReference == activeShift.shiftReference);
      if (shiftIndex != -1) {
        allShifts[shiftIndex] = activeShift;
        List<ShiftModel> updatedShifts =
            _localStorageService.replaceShift(activeShift, allShifts);
        _localStorageService.writeItems(
            AppConstants.SHIFT_LIST, updatedShifts, box);
      }
      
      if(type == "CASH_IN") {
        printCashIn(paymentTypes[0], activeShift.userFullName!); 
      }
      // was causing some shifts to be missing
      // if (stat) {
        // SyncService.syncOfflineShifts(user.value!, box);
      // }
    } else {
      shiftAvailable.value = false;
    }
  }
  Future<void> openCashDrawer() async {
    try {
      await SunmiPrinter.openDrawer();
    } catch (e) {
      debugPrint("Error opening cash drawer: $e");
    }
  }

  List<SaleInfoModel> getExistingOfflineSales(GetStorage box) {
    List<dynamic>? itemsListDynamic =
        box.read<List<dynamic>>(AppConstants.SALE_LIST);
    if (itemsListDynamic != null) {
      List<Map<String, dynamic>> itemsListMap = itemsListDynamic.map((item) {
        return item as Map<String, dynamic>;
      }).toList();
      List<SaleInfoModel> infos = List<SaleInfoModel>.from(
          itemsListMap.map((map) => SaleInfoModel.fromMap(map)));
      return infos;
    } else {
      List<SaleInfoModel> itemsList = <SaleInfoModel>[];
      return itemsList;
    }
  }

  void writeSaleInfor(GetStorage box, List<SaleInfoModel> itemsList) {
    _localStorageService.writeItems(AppConstants.SALE_LIST, itemsList, box);
  }

  cancelSale() {
    cartItems.value = [];
    selectedPaymentTypes.value = [];
    selectedPaymentTypes.clear();
    totalCostInBaseCurrency.value = 0.0;
    totalCostInSelectedCurrency.value = 0.0;
    totalTaxInBaseCurrency.value = 0.0;
    totalTaxInSelectedCurrency.value = 0.0;
    amountPaid.value = 0.0;
    change.value = 0.0;
    accountPayType.value = "";
    amountPaidTextEditingController.clear();
    hasAmountText.value = false;
    isFirstQuickAmountButtonUsed.value = false; // Reset flag for next sale
    postToRearScreen();
    resetFormKey();
    Get.delete<SaleController>();
    Get.delete<CartController>();
    Get.delete<ShiftController>();
    Get.delete<ReceiptController>();
    Get.delete<TicketController>();
    Get.delete<CustomerController>();
    Navigator.pushReplacement(Get.context!,
        MaterialPageRoute(builder: (BuildContext context) => SaleScreen()));
    Get.reload();
  }

  void resetFormKey() {
    formKey = GlobalKey<FormState>();
  }

  onChangePaymentType(PaymentTypeModel paymentType, bool multiple) {
    isPaymentTypeSelected.value = true;
    if(paymentType.name!.startsWith("ACC-")) {
      accountPayType.value = "account";
    }
    paymentType.amount = totalCostInSelectedCurrency.value;
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
    
    // Preserve manual amountPaid entry (Option A)
    // Only auto-fill if amountPaid was NOT manually entered
    if (!isAmountPaidManuallyEntered.value) {
      amountPaidTextEditingController.text = totalCostInSelCurrency.toStringAsFixed(2);
      hasAmountText.value = true;
      amountPaid.value = totalCostInSelCurrency;
      customerAmountPaid.value = totalCostInSelCurrency;
    }
    // If manually entered, preserve the existing amountPaid and just recalculate change
    
    double totalTaxInSelCurrency =
        totalTaxInBaseCurrency.value * newValue.rate!;
    totalCostInSelectedCurrency.value = totalCostInSelCurrency;
    totalTaxInSelectedCurrency.value = totalTaxInSelCurrency;
    currencyList.refresh();
    filterPaymentTypes(newValue, selectedCustomer.value!);
    selectCorrectBank();
    
    // Recalculate totals and change (preserves manual amountPaid)
    calculateTotalAmounts(cartItems);
  }

  void selectCorrectBank() {
    if (selectedCurrency.value != null && selectedPaymentType.value != null) {
      final paymentType = selectedPaymentType.value;
      final currency = selectedCurrency.value;

      if (paymentType?.banks != null) {
        for (BankModel bank in paymentType!.banks!) {
          if (bank.currency?.id == currency!.id) {
            selectedBank.value = bank;
          }
        }
      } else {
        print('No banks associated with the selected payment type.');
      }
    } else {
      print('Either selectedCurrency or selectedPaymentType is null.');
    }
  }

  List<CustomerModel> loadCustomers(GetStorage box) {
    List<CustomerModel> list =
        _localStorageService.getOfflineList<CustomerModel>(
            AppConstants.CUSTOMER_LIST,
            (map) => CustomerModel.fromMap(map),
            box);
    return list;
  }

  void addNewCustomer() {
    String name = nameController.text.trim();
    String phone = phoneController.text.trim();
    String email = emailController.text.trim();

    String taxNumber = vatEditingController.text.trim();
    String tin = tinEditingController.text.trim();
    String address = addressEditingController.text;

    CustomerModel newCustomer = CustomerModel(
        id: null,
        name: name,
        mobilePhone: phone,
        email: email,
        taxNumber: taxNumber,
        tinNumber: tin,
        street: address);
    allCustomers.add(newCustomer);
    selectedCustomer.value = newCustomer;
    List<CustomerModel> itemsList = allCustomers;
    List<Map<String, dynamic>> itemsListMap =
        itemsList.map((item) => item.toMap()).toList();
    // showSnackBar("Message", "Customers downloaded successfully");
    box.write(AppConstants.CUSTOMER_LIST, itemsListMap);

    // Clear the text controllers after adding
    nameController.clear();
    phoneController.clear();
    emailController.clear();
    formKeyAddCustomer = GlobalKey<FormState>();
  }

  savePayment() async {
    CustomerModel customer = selectedCustomer.value!;
    GetStorage bb = GetStorage();
    var ref = AppConstants.getDateNowRef("OFF", 1);
    selectCorrectBank();
    PaymentReceivedModel paymentReceivedModel = PaymentReceivedModel(
        id: null,
        dateTime: DateFormat(AppConstants.APP_DATE_TIME_FMT).format(DateTime.now()),
        amount: amountPaid.value,
        amountPaid: amountPaid.value,
        paymentType: selectedPaymentType.value,
        isPaid: true,
        payer: customer,
        currency: selectedCurrency.value,
        bank: selectedBank.value,
      branch: branch.value,
      paymentDescription: 'PAY_ACCOUNT',
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
      CustomerCurrencyAmount currencyAmount = CustomerCurrencyAmount(currency: selectedCurrency.value!, balance: amountPaid.value,);
      customer.currencyBalance!.add(currencyAmount);
    } else{
      var prev = customer.currencyBalance!.firstWhere((cd)=>cd.currency.id == selectedCurrency.value!.id).balance;
      customer.currencyBalance!.firstWhere((cd)=>cd.currency.id == selectedCurrency.value!.id).balance = (prev! + amountPaid.value);
    }
    customer.accountBalance = (customer.accountBalance??0.0) + amountPaid.value;
    allCustomers[index] = customer;
    List<CustomerModel> customers = allCustomers.value;
    List<Map<String, dynamic>> customersListMap =
    customers.map((item) => item.toMap()).toList();
    box.write(AppConstants.CUSTOMER_LIST, customersListMap);
    // Reload from CustomerController to ensure proper offline handling (same as sale screen refresh fix)
    try {
      final CustomerController customerController = Get.find<CustomerController>();
      await customerController.reloadCustomersFromStorage();
      refreshCustomersFromList(List<CustomerModel>.from(customerController.allCustomers));
    } catch (_) {
      // Fallback: at least refresh from storage
      refreshCustomers();
    }
    List<PaymentReceivedModel> paymentTypes =[];
    paymentTypes.add(paymentReceivedModel);
    bool networkAvailable = await _connectivityService.checkServerConnection();
    // Get the active shift reference for this payment (not associated with a sale)
    String? shiftRef = activeShift.shiftReference;
    if (shiftRef == null) {
      // Fallback: try to get active shift if not already set
      List<ShiftModel> tempShiftList = loadShifts(box);
      ShiftModel? tempActiveShift = await _localStorageService.getActiveShift(
          tempShiftList, box, user.value!, false); // Don't check server for payment received
      shiftRef = tempActiveShift?.shiftReference;
    }
    updateShiftWithNewSale(ref, paymentReceivedModel.dateTime!, paymentReceivedModel.amount!, networkAvailable,
        customer.name!, paymentTypes,"CASH_IN",customer.name!, false, shiftRef);
    if(networkAvailable){
      await SyncService.savePaymentReceived(user.value!, box);
    }
    Navigator.of(Get.overlayContext!).pop();
    allCustomers.refresh();
    // selectedCustomer;
    // amountPaidTextEditingController.clear();
    cancelSale();
  }


  List<PaymentReceivedModel> loadPaymentReceived( GetStorage box) {
    List<PaymentReceivedModel> list = _localStorageService.getOfflineList<PaymentReceivedModel>(
        AppConstants.PAYMENT_RECEIVED_LIST,
            (map) => PaymentReceivedModel.fromMap(map),
        box);
    return list;
  }

  void addAmount() {
    if (formKeyAddAmount.currentState!.validate()) {
      double amount = double.parse(vatEditingController.text);
      if (amount > 0) {
        selectedPaymentType.value!.amount = amount;
        selectedPaymentTypes.add(selectedPaymentType.value!);
        isPaymentTypeSelected.value = true;
        vatEditingController.clear();
        // formKeyAddAmount = GlobalKey<FormState>();
      } else {
        Get.snackbar(
            "Invalid Amount", "Please enter a valid amount greater than zero.",
            snackPosition: SnackPosition.BOTTOM);
      }
    }
  }

  // NFC Customer Selection
  Future<void> selectCustomerByNfc() async {
    if (!_nfcService.isNfcAvailable.value) {
      Get.snackbar(
        'NFC Not Available',
        'NFC is not available on this device',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    isNfcReading.value = true;

    try {
      String? cardId = await _nfcService.readNfcCard();

      if (cardId != null) {
        // Find customer with this NFC card ID
        CustomerModel? customer = allCustomers.firstWhereOrNull(
          (customer) => customer.nfcCardId == cardId,
        );

        if (customer != null) {
          selectedCustomer.value = customer;
          isCustomerSelected.value = true;
          customerSearchController.text = customer.name ?? '';

          Get.snackbar(
            'Customer Selected',
            'Customer ${customer.name} selected via NFC',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } else {
          Get.snackbar(
            'Customer Not Found',
            'No customer found with this NFC card',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
        }
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
    } finally {
      isNfcReading.value = false;
    }
  }

  @override
  void onClose() {
    _chargeDebouncer?.cancel();
    super.onClose();
  }
}
