import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_rx/get_rx.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:vimbika_pos_app/src/constants/app_constants.dart';
import 'package:vimbika_pos_app/src/constants/app_routes.dart';
import 'package:vimbika_pos_app/src/features/authentication/model/user_model.dart';
import 'package:vimbika_pos_app/src/features/printers/model/available_printer_model.dart';
import 'package:vimbika_pos_app/src/features/sale/controller/sale_controller.dart';
import 'package:vimbika_pos_app/src/features/sale/model/cart_item_model.dart';
import 'package:vimbika_pos_app/src/features/sale/model/product_full_info_model.dart';
import 'package:vimbika_pos_app/src/features/sale/model/inventory_item_model.dart';
import 'package:vimbika_pos_app/src/features/sale/model/sale_infor_model.dart';
import 'package:vimbika_pos_app/src/features/sale/model/sale_item_model.dart';
import 'package:vimbika_pos_app/src/features/sale/model/sale_model.dart';
import 'package:vimbika_pos_app/src/features/sale_receipts/controller/receipt_controller.dart';
import 'package:vimbika_pos_app/src/features/sale_receipts/screen/pdf_web_view_screen.dart';
import 'package:vimbika_pos_app/src/features/shift/controller/shift_controller.dart';
import 'package:vimbika_pos_app/src/features/shift/model/currency_amount.dart';
import 'package:vimbika_pos_app/src/features/shift/model/shift_model.dart';
import 'package:vimbika_pos_app/src/features/shift/screen/pdf_preview_screen.dart';
import 'package:vimbika_pos_app/src/features/ticket/controller/ticket_controller.dart';
import 'package:vimbika_pos_app/src/services/app_exceptions.dart';
import 'package:vimbika_pos_app/src/services/base_http_client.dart';
import 'package:vimbika_pos_app/src/services/connectivity_service.dart';
import 'package:vimbika_pos_app/src/services/generate_flutter_pdf.dart';
import 'package:vimbika_pos_app/src/services/local_storage_service.dart';
import 'package:vimbika_pos_app/src/services/printer_service.dart';
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


class CartController extends GetxController {
  var cartItems = <CartItemModel>[].obs;
  var sale = <SaleModel>[].obs;
  var currency = CurrencyModel().obs;
  final ConnectivityService _connectivityService = ConnectivityService();
  Rx<CurrencyModel?> selectedCurrency = CurrencyModel().obs;
  Rx<CurrencyModel?> baseCurrency = CurrencyModel().obs;

  Rx<BranchModel?> branch = BranchModel().obs;
  RxList<CurrencyModel> currencyList = <CurrencyModel>[].obs;
  RxList<UserModel> userList = <UserModel>[].obs;
  var isCurrencySelected = false.obs;
  var isUserSelected = false.obs;
  var isPrinterAvailable = false.obs;
  final TextEditingController customerSearchController = TextEditingController();
  RxString searchText = ''.obs;

  Rx<PaymentTypeModel?> selectedPaymentType = PaymentTypeModel().obs;
  Rx<BankModel?> selectedBank = BankModel().obs;
  RxList<PaymentTypeModel> paymentTypesList = <PaymentTypeModel>[].obs;
  RxList<PaymentTypeModel> filteredPaymentTypesList = <PaymentTypeModel>[].obs;
  var isPaymentTypeSelected = false.obs;
  final TextEditingController amountPaidTextEditingController = TextEditingController();

  RxDouble totalCostInBaseCurrency = 0.0.obs;
  RxDouble totalCostInSelectedCurrency = 0.0.obs;
  RxDouble totalTaxInBaseCurrency = 0.0.obs;
  RxDouble totalTaxInSelectedCurrency = 0.0.obs;
  RxDouble amountPaid = 0.0.obs;
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
   late  GetStorage box;

  RxBool isPrintEnabled = false.obs; // Observing the state of the checkbox
  RxBool isFiscaliseReceiptEnabled = true.obs;
  RxBool isCustomerEmailValid = false.obs;
  RxBool emailReceipt = false.obs;
  RxBool fiscalizeReceipt = false.obs;
  RxBool zimraFiscalizeReceipt = false.obs;
  Rx<CompanyModel?> company = CompanyModel().obs;

  // Text controllers for the add new customer dialog
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();

  final TextEditingController vatEditingController = TextEditingController();
  final TextEditingController tinEditingController = TextEditingController();
  final TextEditingController addressEditingController = TextEditingController();
  // Form key to validate the form
  var formKeyAddCustomer = GlobalKey<FormState>();
  final PrinterService _printerService = Get.put(PrinterService());
  RxList<AvailablePrinterModel> availablePrinters = <AvailablePrinterModel>[].obs;
  var saleTicketId = "".obs;

  @override
  Future<void> onInit() async {
    super.onInit();
   // isInternetAccess.value =  await _connectivityService.checkConnection();
     box = GetStorage();
    var model = box.read(AppConstants.USER_INFO) ?? {};
     user.value = UserModel.fromMap(Map<String, dynamic>.from(model));
    isUserSelected.value = true;

    var fiscalStatus = box.read(AppConstants.IS_FISCALISATION_ENABLED) ?? false;
    if(fiscalStatus){
      fiscalizeReceipt.value = true;
    }

    var branchModel = box.read(AppConstants.SELECTED_BRANCH) ?? {};
    branch.value = BranchModel.fromMap(Map<String, dynamic>.from(branchModel));
    List<UserModel> tempUserList = loadUsers(box);
    userList.value = tempUserList;
    List<ShiftModel> tempShiftList = loadShifts(box);
    var companyModel = box.read(AppConstants.ACTIVE_COMPANY) ?? {};
    company.value = CompanyModel.fromMap(Map<String, dynamic>.from(companyModel));

    shiftList.value = tempShiftList;
    ShiftModel? tempActiveShift = await _localStorageService.getActiveShift(tempShiftList, box, user.value!, true);

    if(tempActiveShift != null) {
      activeShift = tempActiveShift;
      shiftAvailable.value = true;
    } else{
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
          (customer) => customer.name != null && customer.name!.toLowerCase().contains('walkin'),
    );

    if (defaultCustomer == null) {
      // If "WalkIn" is not in the list, create and add it
      defaultCustomer = CustomerModel(id: null, name: 'WalkIn');
      allCustomers.add(defaultCustomer);
    }

    // Set "WalkIn" as the default selected customer
    selectedCustomer.value = defaultCustomer;
    isCustomerSelected.value = true;
    filterPaymentTypes(selectedCurrency.value!, defaultCustomer);
    List<AvailablePrinterModel> tempPrinterList = loadAvailablePrinters(box);
    availablePrinters.value = tempPrinterList;
    //select default payment method
    var paymentTypeId = box.read(AppConstants.DEFAULT_PAYMENT_METHOD_ID) ?? "";
    for(var cur in tempList) {
      if (cur.id == paymentTypeId) {
        selectedPaymentType.value = cur;
        isPaymentTypeSelected.value = true;
        selectCorrectBank();
      }
    }

  }
  List<ShiftModel> loadShifts( GetStorage box) {
    List<ShiftModel> list = _localStorageService.getOfflineList<ShiftModel>(
        AppConstants.SHIFT_LIST,
            (map) => ShiftModel.fromMap(map),
        box);
    return list;
  }
  List<BankModel> loadBanks( GetStorage box) {
    List<BankModel> list = _localStorageService.getOfflineList<BankModel>(
        AppConstants.BANK_LIST,
            (map) => BankModel.fromMap(map),
        box);
    return list;
  }
  List<AvailablePrinterModel> loadAvailablePrinters( GetStorage box) {
    List<AvailablePrinterModel> list = _localStorageService.getOfflineList<AvailablePrinterModel>(
        AppConstants.AVAILABLE_PRINTERS,
            (map) => AvailablePrinterModel.fromMap(map),
        box);
    return list;
  }

  onCustomerChange(CustomerModel? newValue){
    isCustomerSelected.value = true;
    selectedCustomer.value = newValue!;
    validateEmail(newValue.email);
    //filterPaymentTypesForCustomer(newValue);
    filterPaymentTypes(selectedCurrency.value!, newValue);

  }
  // filterPaymentTypesForCustomer(CustomerModel? newValue, ){
  //   if(newValue!.name == 'WalkIn'){
  //     filteredPaymentTypesList.value = paymentTypesList
  //         .where((type) => !type.name!.toLowerCase().contains('credit'))
  //         .toList();
  //   } else{
  //     filteredPaymentTypesList.value = paymentTypesList;
  //   }
  // }

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

      // tempList = tempList
      //     .where((type) => !type.name!.toLowerCase().contains('credit'))
      //     .toList();
      tempList = tempList
          .where((type) => !type.isCredit!)
          .toList();
    }

    // Assign the filtered results to the reactive list
    filteredPaymentTypesList.value = tempList;
    filteredPaymentTypesList.refresh();
  }



  void addToCart(ProductFullInfoModel product, double quantity) {
    var index = cartItems.indexWhere((item) => item.product.id == product.id);
    if(quantity==0.001){
      quantity = 1.00;
    }
    if (index != -1) {
      CartItemModel item = cartItems[index];
      item.quantity = item.quantity + quantity;
     // cartItems[index].quantity++;
    } else {
      cartItems.add(CartItemModel(product: product, quantity: quantity));
    }
    calculateTotalAmounts(cartItems);
  }

  void removeFromCart(CartItemModel cartItem) {
    cartItems.remove(cartItem);
    calculateTotalAmounts(cartItems);
  }

  void incrementQuantity(CartItemModel cartItem) {
    cartItem.quantity++;
    calculateTotalAmounts(cartItems);
    cartItems.refresh();
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
    double totalCostInBCurrency = items.fold(0.0, (sum, item) => sum + item.totalPrice);
    double? rate = selectedCurrency.value?.rate! ?? 1;
    totalCostInBaseCurrency.value =  totalCostInBCurrency;
    totalCostInSelectedCurrency.value = totalCostInBCurrency * rate;
    totalTaxInBaseCurrency.value = items.fold(0, (sum, item) => sum + item.totalTaxAmount);
  }

  void validateEmail(String? value) {
    if(value != null) {
      if (value.isEmpty) {
        isCustomerEmailValid.value = false;
      } else if (!GetUtils.isEmail(value)) {
        isCustomerEmailValid.value = false;
      } else {
        isCustomerEmailValid.value = true;
      }
    } else{
      isCustomerEmailValid.value = false;
    }
  }

  // double get totalAmount => cartItems.fold(0, (sum, item) => sum + item.totalPrice);
  // double get totalTaxAmount => cartItems.fold(0, (sum, item) => sum + item.totalTaxAmount);
  
  Future<void> checkout() async {
    if(shiftAvailable.isFalse){
      openShift();
    } else{
      List<ShiftModel> tempShiftList = loadShifts(box);
      shiftList.value = tempShiftList;
      ShiftModel? tempActiveShift = await _localStorageService.getActiveShift(tempShiftList, box, user.value!, true);
      if(tempActiveShift != null) {
        activeShift = tempActiveShift;
        Get.toNamed(AppRoutes.CHECKOUT);
      }else{
        openShift();
      }

    }

  }
  openShift(){
    Get.snackbar("Create Shift", "Open a shift to proceed", snackPosition: SnackPosition.BOTTOM);
    Get.delete<CartController>();
    Get.delete<SaleController>();
    Get.offNamed(AppRoutes.OPEN_SHIFT);
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

  List<UserModel> loadUsers( GetStorage box) {
    List<UserModel> list = _localStorageService.getOfflineList<UserModel>(
        AppConstants.USER_LIST,
            (map) => UserModel.fromMap(map),
        box);
     list.add(user.value!);
    return list;
  }


  amountPaidChange(String val){
     double amountPaid =  double.parse(val);
     customerAmountPaid.value = amountPaid;
     if(amountPaid>=totalCostInSelectedCurrency.value){
       change.value = amountPaid - totalCostInSelectedCurrency.value;
     } else{
       change.value = 0.0;
     }
  }

  void showConfirmDialogChargeSale() {
    chargeSale("COMPLETE", false, "", "", "", cartItems, saleTicketId.value);
    // Get.defaultDialog(
    //   title: "Confirmation",
    //   middleText: "Are you sure you want to proceed?",
    //   textCancel: "No",
    //   textConfirm: "Yes",
    //   onCancel: () {
    //     Get.back(); // Close the dialog
    //   },
    //   onConfirm: () {
    //     chargeSale();
    //
    //   },
    // );
  }




  chargeSale(String saleStatus, bool isOnHold, String ref, String ticketName, String ticketComment, List<CartItemModel> saleCartItems, String saleId) async{
    bool stat = await _connectivityService.checkServerConnection();
    calculateTotalAmounts(saleCartItems);
    double totalSaleQuantity = 0;
    List<SaleItemModel> saleItems = [];
    String timeInit = DateFormat(AppConstants.APP_DATE_TIME_FMT).format(DateTime.now());
    List<SaleInfoModel> infos = getExistingOfflineSales(box);
    int count = infos.length + 1;
    if(!isOnHold){
      ref = AppConstants.getDateNowRef("OFF", count);
    }



    AppHelper.showLoading("Saving new sale..");


    saleTicketId.value = saleId;

    for (var cartItem in saleCartItems) {
      InventoryItemModel productItem = cartItem.product.item!;
      totalSaleQuantity = totalSaleQuantity + cartItem.quantity;
      productItem.quantity = cartItem.quantity;
      productItem.total = cartItem.totalPrice;
      SaleItemModel saleItem = SaleItemModel(sellingPrice: productItem.sellingPrice, baseCurrencySellingPrice: productItem.sellingPrice, quantity:  cartItem.quantity, total: cartItem.totalPrice, baseCurrencyTotal: cartItem.totalPrice, taxAmount: cartItem.totalTaxAmount, baseTaxAmount: cartItem.totalTaxAmount, inventoryItem: productItem, branch: branch.value);
      saleItem.id = productItem.id;
      if(saleItem.inventoryItem != null){
        if(saleItem.inventoryItem!.productImages != null){
          saleItem.inventoryItem!.productImages = [];
        }
        if(saleItem.inventoryItem!.images != null){
          saleItem.inventoryItem!.images = [];
        }
      }

      saleItems.add(saleItem);
    }
    bool isWalkIn = selectedCustomer.value!.name!.contains("WalkIn") ? true : false;
    PaymentReceivedModel paymentReceivedModel = PaymentReceivedModel(amount: totalCostInSelectedCurrency.value, paymentType: selectedPaymentType.value, paymentDescription: "SALE", isPaid: true, currency: selectedCurrency.value, bank: selectedBank.value);
    List<PaymentReceivedModel> paymentTypes = [];
    paymentTypes.add(paymentReceivedModel);
    if(isOnHold){
      paymentTypes = [];
    }
    String fullName = user.value!.firstName + " " + user.value!.lastName;


    SaleModel sale = SaleModel(id: saleTicketId.value.length > 2 ? saleTicketId.value: null, active: true, createdByName: user.value!.userName, cashierFullName: fullName, paymentTypes: paymentTypes, saleStatus: saleStatus, onHold: isOnHold, amountPaid: totalCostInSelectedCurrency.value, totalQuantity: totalSaleQuantity, saleCost: 0.0, totalTaxAmount: totalTaxInSelectedCurrency.value, baseSaleAmount: totalCostInBaseCurrency.value, referenceNumber: ref, change: change.value, customerAmountPaid: customerAmountPaid.value, timeIniated: timeInit, timeInit: timeInit, currency: selectedCurrency.value, baseCurrency: baseCurrency.value, paymentType: isOnHold? null : selectedPaymentType.value, items: saleItems, branch: branch.value, amountAfterDiscount: totalCostInSelectedCurrency.value, shiftReference: activeShift.shiftReference,
        posReference: ref, customer: isWalkIn ? null :  selectedCustomer.value, isWalkInCustomer: isWalkIn, taxInvoice: fiscalizeReceipt.value, fiscalized: zimraFiscalizeReceipt.value, emailReceipt: emailReceipt.value, totalDiscount: 0, ticketName: ticketName, ticketComment: ticketComment);

    SaleInfoModel saleInfoModel;
    if(stat) {
      print("SAVING SALE..");
      SaleModel? responseFromServerSale = await SyncService.saveSale(sale, user.value!, box, company.value!);
      if(responseFromServerSale != null) {

        print("QR LINK1");
        print(responseFromServerSale.receiptQrCode);
        if(isOnHold){
          saleInfoModel = SaleInfoModel(sale: responseFromServerSale, syncStatus: true);
        } else{
          SaleInfoModel? infoModel = await getSale(responseFromServerSale.id!);
          if(infoModel != null){
            saleInfoModel = infoModel;
            print("QR LINK2");
            print(saleInfoModel.sale!.receiptQrCode);
          } else{
            saleInfoModel = SaleInfoModel(sale: responseFromServerSale, syncStatus: true);
          }
        }
      } else {
        saleInfoModel = SaleInfoModel(sale: sale, syncStatus: false);
      }
    } else{
      saleInfoModel = SaleInfoModel(sale: sale, syncStatus: false);
    }
    if(!isOnHold) {
      deductStock();
      updateShiftWithNewSale(ref, timeInit, totalCostInSelectedCurrency.value, stat);
      infos.add(saleInfoModel);
      writeSaleInfor(box, infos);
      printCurrentSale(saleInfoModel, box);
      AppHelper.hideLoading();
      cancelSale();
    }

  }
  void deductStock(){
    List<ProductFullInfoModel> storageProductList = getProductList(box);
    for(CartItemModel cart in cartItems){
       for(ProductFullInfoModel pro in storageProductList){
         if(cart.product.id == pro.id){
           double qty = pro.stock! - cart.quantity;
           pro.stock = qty;
         }
       }
    }
    List<Map<String, dynamic>> itemsListMap = storageProductList.map((item) =>
        item.toMap()).toList();
    box.write(AppConstants.BRANCH_PRODUCTS, itemsListMap);
  }
  List<ProductFullInfoModel> getProductList(GetStorage box) {
    // Read the data as a List<dynamic>
    List<dynamic>? itemsListDynamic = box.read<List<dynamic>>(AppConstants.BRANCH_PRODUCTS);

    // Check if the read data is not null
    if (itemsListDynamic != null) {
      // Convert the List<dynamic> to List<Map<String, dynamic>>
      List<Map<String, dynamic>> itemsListMap = itemsListDynamic.map((item) {
        return item as Map<String, dynamic>;
      }).toList();

      // Convert List<Map<String, dynamic>> to List<ProductFullInfoModel>
      return List<ProductFullInfoModel>.from(itemsListMap.map((map) => ProductFullInfoModel.fromMap(map)));
    } else {
      return [];
    }
  }
  void printCurrentSale(SaleInfoModel saleInfo, GetStorage box) async {
    if(isPrintEnabled.isTrue) {
      _printerService.printCurrentSale(saleInfo, box, _localStorageService);
    }
  }
  Future<SaleInfoModel?> getSale(String saleId) async{
    await Future.delayed(Duration(seconds: 2));
    var response = await BaseHttpClient().getAuthWithCompanyHeader("/sale/get-item/" + saleId, user.value!.companyId!).catchError((onError){
      if (onError is BadRequestException) {
        var apiError = json.decode(onError.message!);
        AppHelper.showErroDialog(description: apiError["reason"]);
      } else {
        AppHelper.handleError(onError);
      }
    });
    if(response != null) {
      print("Fetched sale..");
      print(response);
      // SaleModel itemConverted = SaleModel.fromJson(response);
      SaleModel itemConverted = SaleModel.fromJson(json.decode(response));

      SaleInfoModel saleInfoModel = SaleInfoModel(sale: itemConverted, syncStatus: true);
      return saleInfoModel;
    }
    return null;
  }
  updateShiftWithNewSale(String ref, String timeCreated, double amt, bool stat){
    int count = activeShift.shiftCurrencyAmounts!.length + 1;
    String ref = AppConstants.getDateNowRef("SL_", count);
    CurrencyAmount currencyAmount = CurrencyAmount(currency: selectedCurrency.value!, amountType: "SALE", ref: ref, timeCreated: timeCreated, notes: "", amount: amt, shiftReference: activeShift.shiftReference);
    activeShift.shiftCurrencyAmounts!.add(currencyAmount);
    List<ShiftModel> updatedShifts = _localStorageService.replaceShift(activeShift, shiftList);
    _localStorageService.writeItems(AppConstants.SHIFT_LIST, updatedShifts, box);
    if(stat){
      SyncService.syncOfflineShifts(user.value!, box);
    }
  }

  List<SaleInfoModel> getExistingOfflineSales(GetStorage box){
    List<dynamic>? itemsListDynamic = box.read<List<dynamic>>(AppConstants.SALE_LIST);
    if(itemsListDynamic != null) {
      List<Map<String, dynamic>> itemsListMap = itemsListDynamic.map((item) {
        return item as Map<String, dynamic>;
      }).toList();
      List<SaleInfoModel> infos = List<SaleInfoModel>.from(
          itemsListMap.map((map) => SaleInfoModel.fromMap(map)));
      return infos;
    } else{
      List<SaleInfoModel> itemsList = <SaleInfoModel>[];
      return itemsList;
    }
  }

  writeSaleInfor(GetStorage box, List<SaleInfoModel> itemsList){
    List<Map<String, dynamic>> itemsListMap = itemsList.map((item) =>
        item.toMap()).toList();
    box.write(AppConstants.SALE_LIST, itemsListMap);
  }
  cancelSale(){
    cartItems.value = [];
    totalCostInBaseCurrency == 0.0;
    totalCostInSelectedCurrency == 0.0;
    totalTaxInBaseCurrency == 0.0;
    totalTaxInSelectedCurrency == 0.0;
    amountPaid.value = 0.0;
    change.value = 0.0;
    resetFormKey();
    Get.delete<SaleController>();
     Get.delete<CartController>();
     Get.delete<ShiftController>();
    Get.delete<ReceiptController>();
    Get.delete<TicketController>();

    Get.offNamed(AppRoutes.SALE);
  }

  void resetFormKey() {
    formKey = GlobalKey<FormState>();
  }

  onChangePaymentType(PaymentTypeModel paymentType){
    isPaymentTypeSelected.value = true;
    selectedPaymentType.value = paymentType!;
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
    selectCorrectBank();

  }
  void selectCorrectBank() {
    if (selectedCurrency.value != null && selectedPaymentType.value != null) {
      // Debugging to verify values
      print('Selected Currency: ${selectedCurrency.value}');
      print('Selected Payment Type: ${selectedPaymentType.value}');

      final paymentType = selectedPaymentType.value;
      final currency = selectedCurrency.value;

      if (paymentType?.banks != null) {
        for (BankModel bank in paymentType!.banks!) {
          if (bank.currency?.id == currency!.id) {
            selectedBank.value = bank;
            print('Selected Bank: ${bank}');
          }
        }
      } else {
        print('No banks associated with the selected payment type.');
      }
    } else {
      print('Either selectedCurrency or selectedPaymentType is null.');
    }
  }




  List<CustomerModel> loadCustomers( GetStorage box) {
    List<CustomerModel> list = _localStorageService.getOfflineList<CustomerModel>(
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

    CustomerModel newCustomer = CustomerModel(id: null, name: name, mobilePhone: phone, email: email, taxNumber: taxNumber, tinNumber: tin, street: address);
    allCustomers.add(newCustomer);
    selectedCustomer.value = newCustomer;

    // Clear the text controllers after adding
    nameController.clear();
    phoneController.clear();
    emailController.clear();
    formKeyAddCustomer = GlobalKey<FormState>();
  }
}