import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';
import 'package:vimbika_pos_app/src/constants/app_constants.dart';
import 'package:vimbika_pos_app/src/constants/app_routes.dart';
import 'package:vimbika_pos_app/src/features/authentication/model/user_model.dart';
import 'package:vimbika_pos_app/src/features/sale/controller/cart_controller.dart';
import 'package:vimbika_pos_app/src/features/sale/model/product_full_info_model.dart';
import 'package:vimbika_pos_app/src/features/sale/model/sale_infor_model.dart';
import 'package:vimbika_pos_app/src/features/sale/model/sale_model.dart';
import 'package:vimbika_pos_app/src/features/sale_receipts/controller/receipt_controller.dart';
import 'package:vimbika_pos_app/src/services/app_exceptions.dart';
import 'package:vimbika_pos_app/src/services/base_http_client.dart';
import 'package:vimbika_pos_app/src/services/connectivity_service.dart';
import 'package:vimbika_pos_app/src/services/local_storage_service.dart';
import 'package:vimbika_pos_app/src/services/sync_service.dart';
import 'package:vimbika_pos_app/src/shared/models/base_name_model.dart';
import 'package:vimbika_pos_app/src/shared/models/branch_model.dart';
import 'package:vimbika_pos_app/src/shared/models/company_model.dart';
import 'package:vimbika_pos_app/src/shared/models/currency_model.dart';
import 'package:vimbika_pos_app/src/shared/models/dynamic_query_model.dart';
import 'package:vimbika_pos_app/src/shared/models/payment_type_model.dart';
import 'package:vimbika_pos_app/src/shared/models/settings_model.dart';
import 'package:vimbika_pos_app/src/utils/app_helper.dart';

import '../../../services/customer_display.dart';
import '../../../services/printer_service.dart';
import '../../shift/model/currency_amount.dart';
import '../../shift/model/shift_model.dart';

class SaleController extends GetxController {
  late UserModel user = UserModel(firstName: "", lastName: "", userName: "");
  late SettingsModel settingsModel = SettingsModel(sellNilItems: false);
  RxList<ProductFullInfoModel> allProducts = <ProductFullInfoModel>[].obs;
  RxList<ProductFullInfoModel> filteredProducts = <ProductFullInfoModel>[].obs;
  RxList<BaseNameModel> brands = <BaseNameModel>[].obs;
  RxList<BaseNameModel> categories = <BaseNameModel>[].obs;
  bool isItemListScreen = true;
  bool isCartScreen = false;
  RxBool multiple = false.obs;
  RxBool showMultiple = false.obs;
  Rx<int> itemCount = 0.obs;
  Rx<double> price = 0.0.obs;
  Rx<String> searchQuery = "".obs;
  var isSearching = false.obs;
  bool sellNilItems = false;
  List<SaleInfoModel> offlineSales = <SaleInfoModel>[];
  PaymentTypeModel selectedPaymentType = PaymentTypeModel();
  List<PaymentTypeModel> selectedPaymentTypes = <PaymentTypeModel>[].obs;
  RxList<SaleInfoModel> allReceipts = <SaleInfoModel>[].obs;
  RxList<SaleInfoModel> filteredReceipts = <SaleInfoModel>[].obs;
  final CartController cartController = Get.put(CartController());
  bool useSerialNumbers = false;
  var isServerReachable = false.obs;
  var isBrandSelected = false.obs;
  var isCatSelected = false.obs;
  var chargeClicked = false.obs;
  var addAccClicked = false.obs;
  var saveTicketClicked = false.obs;

  final ConnectivityService _connectivityService = ConnectivityService();
  final LocalStorageService _localStorageService = LocalStorageService();
  Rx<BaseNameModel?> selectedBrand = BaseNameModel().obs;
  Rx<BaseNameModel?> selectedCategory = BaseNameModel(id: "All Items", name: "All Items").obs;
  final TextEditingController searchTextEditingController = TextEditingController(text: "");
  late  GetStorage box;
  Timer? _syncTimer; // Add a timer variable
  Rx<CompanyModel?> company = CompanyModel().obs;

  final TextEditingController barCodeTextEditingController = TextEditingController();
  final TextEditingController amountTextEditingController = TextEditingController();
  final TextEditingController discountTextEditingController = TextEditingController();
  final TextEditingController itemNotesTextEditingController = TextEditingController();

  final PrinterService _printerService = Get.put(PrinterService());
  RxInt barCode =0.obs;
  @override
  Future<void> onInit() async {
    super.onInit();

    box = GetStorage();
    var model = box.read(AppConstants.USER_INFO) ?? {};
    user = UserModel.fromMap(Map<String, dynamic>.from(model));
    var settings = box.read(AppConstants.COMPANY_SETTINGS) ?? {};
    settingsModel = SettingsModel.fromMap(Map<String, dynamic>.from(settings));
    sellNilItems= settingsModel.sellNilItems ?? false;
    useSerialNumbers = settingsModel.useSerialNumbers ?? false;

    isServerReachable.value =  await _connectivityService.checkServerConnection();
    List<BaseNameModel> brandList = loadItems(box, AppConstants.BRAND_LIST);
    brands.value = brandList;
    List<BaseNameModel> catList = loadItems(box, AppConstants.CATEGORY_LIST);
    // catList = catList.where((cat) => {filterProducts(category: cat.name!),return filteredProducts.isNotEmpty}).toList();
    List<BaseNameModel> removedList =[];
    for(var cat in catList){
      filterProducts(category: cat.name!);
      if(filteredProducts.isEmpty)
      {
        removedList.remove(cat);
      }
    }
    catList.removeWhere((cat)=> removedList.contains(cat));
    catList.insert(0, BaseNameModel(id: "All Items", name: "All Items"));
    selectedCategory.value = catList[0];
    categories.value = catList;
    categories.refresh();
      getOfflineProducts(box);
    bool? result = await SunmiPrinter.bindingPrinter();
    result = result ?? false;
    if(!result) {
      Get.snackbar('Printer Status', 'Sunmi built in printer not available',
          snackPosition: SnackPosition.BOTTOM);
    }
    var companyModel = box.read(AppConstants.ACTIVE_COMPANY) ?? {};
    company.value = CompanyModel.fromMap(Map<String, dynamic>.from(companyModel));
    // cartController.refreshCustomers();

      final html = '''
              <html>
                <body style="font-family:sans-serif;text-align:center;">
                  <h2>🛒 Sale in Progress</h2>
                  <p>2x Cappuccino</p>
                  <h3>Total: \$5.60</h3>
                </body>
              </html>
              ''';
      CustomerDisplay.updateDisplay(html);
    print("canPrintToDisplay");
    bool canPrintToDisplay = await _printerService.initializeSunmiLCD();
    print("canPrintToDisplay: ${canPrintToDisplay}");
    if(canPrintToDisplay){
      await _printerService.sendTextToLCD();
    }
  }
  @override
  void onClose() {
    // Cancel the timer when the controller is disposed
   // _syncTimer?.cancel();
    super.onClose();
  }



  Future<SaleInfoModel?> getSale(String saleId) async{
    await Future.delayed(Duration(seconds: 2));
    var response = await BaseHttpClient().getAuthWithCompanyHeader("/sale/get-item/" + saleId, user.companyId!).catchError((onError){
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

  addPaymentType(){}


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
  List<SaleInfoModel> loadSales() {
    LocalStorageService _localStorageService = LocalStorageService();
    List<SaleInfoModel> sales = _localStorageService.getOfflineList<SaleInfoModel>(
        AppConstants.SALE_LIST,
            (map) => SaleInfoModel.fromMap(map),
        box);
    List<SaleInfoModel> list = [];
    for (SaleInfoModel sale in sales) {
      if(sale.sale!.active ?? false){
        list.add(sale);
      }
      else{
        print(sale);
      }
    }
    return sales;
  }


  static List<ShiftModel> loadShiftInfo(GetStorage box) {
    List<CurrencyAmount> currencyAmounts = [];
    LocalStorageService _localStorageService = LocalStorageService();
    List<ShiftModel> list = _localStorageService.getOfflineList<ShiftModel>(
        AppConstants.SHIFT_LIST,
            (map) => ShiftModel.fromMap(map),
        box);
    return list;
  }

  countAllItems() {
    itemCount.value = 0;
    for (var element in allProducts) {
      itemCount.value += element.count;
    }
  }


  calculatePrice() {
    price.value = 0.0;
    for (var element in allProducts) {
      if (element.count > 0) {
        price.value = (element.item!.sellingPrice * element.count) + price.value;
      }
    }
  }

  Future<void> syncData() async {
    AppHelper.showLoading("Syncing....");
    print("syncing products..");
    getBranchStock(box);
    // print("syncing offline sales..");
    // await syncOfflineSales();
    // print("syncing tickets..");
     //await SyncService.syncOfflineTickets(user, box);
    print("syncing new Customers..");
    await SyncService.saveCustomer(user, box);
    await SyncService.savePaymentReceived(user, box);
    print("syncing shifts..");
    await SyncService.syncOfflineShifts(user, box);
    print("syncing currencies..");
    await SyncService.getCurrencies(user, box);
    print("syncing payments..");
    await SyncService.getPaymentTypes(user, box);
    print("syncing new Payments..");
    await SyncService.getCustomers(user, box,user.companyId!);
    print("hiding loading");
    AppHelper.hideLoading();
    cartController.refreshCustomers();
  }
  void clearFilters() {
    selectedCategory.value = BaseNameModel();
    isCatSelected.value = false;
    selectedBrand.value = BaseNameModel();
    isBrandSelected.value = false;
    searchQuery.value = "";
    filteredProducts.value = allProducts.value;
  }

  Future<bool> navigateToListItemScreen() async {
    isCartScreen = false;
    isItemListScreen = true;
    return true;
  }

  void increase(int index) {
    allProducts[index].count++;
    allProducts.refresh();
    countAllItems();
    calculatePrice();
  }

  void decrease(int index) {
    if (allProducts[index].count > 0) {
      allProducts[index].count--;
      allProducts.refresh();
      countAllItems();
      calculatePrice();
    }
  }

  void removeItems(){
    for(var item in allProducts) {
      item.count = 0;
    }
    allProducts.refresh();
    itemCount.value = 0;
    calculatePrice();
  }



  Future<void> getBranchStock(GetStorage box) async{

    var selectedBranch = box.read(AppConstants.SELECTED_BRANCH) ?? null;
    //print(selectedBranch);
    if(selectedBranch != null) {
      BranchModel branch = BranchModel.fromMap(selectedBranch);
      if(branch.id != null){
        DynamicQueryModel dynamicQueryModel = DynamicQueryModel();
        dynamicQueryModel.branch = branch;
        var branchData = dynamicQueryModel.toJson();
        isServerReachable.value =  await _connectivityService.checkServerConnection();
        print("Server status...");
        print(user.companyId!);
        print(isServerReachable.value);
        if (isServerReachable.value) {

          // getOfflineProducts(box);
          print("Fetching products...");
          var response = await BaseHttpClient()
              .postAuthWithCompanyHeader(
              "/inventory/branch-stock-by-branch-mini", branchData, user.companyId!, "POST")
              .catchError((onError) {
            print("INSIDE FETCH..");
            AppHelper.hideLoading();
            print(onError);
            if (onError is BadRequestException) {
              var apiError = json.decode(onError.message!);
              AppHelper.showErroDialog(description: apiError["reason"]);
            } else {
              AppHelper.handleError(onError);
            }
          });
          if (response != null) {
            //AppHelper.hideLoading();

            List<dynamic> list = jsonDecode(response);
            List<ProductFullInfoModel> itemsList = List<ProductFullInfoModel>.from(list.map((i) => ProductFullInfoModel.fromMap(i)));
            itemsList.sort((a, b) => b.stock!.compareTo(a.stock!));


            allProducts.value = itemsList;
            filteredProducts.value = itemsList;
            List<Map<String, dynamic>> itemsListMap = itemsList.map((item) =>
                item.toMap()).toList();
            box.write(AppConstants.BRANCH_PRODUCTS, itemsListMap);
          } else {
           // AppHelper.hideLoading();
            print("Failed to retrieve products");
          }
        }
        // else {
        //   getOfflineProducts(box);
        // }
      } else{
        Get.offNamed(AppRoutes.CHOOSE_BRANCH);
      }

    } else{
      Get.offNamed(AppRoutes.CHOOSE_BRANCH);
    }
  }
  getOfflineProducts(GetStorage box){
    // AppHelper.showLoading();
    List<ProductFullInfoModel> storageProductList = _localStorageService.getProductList(box, false);
    storageProductList.sort((a, b) => a.item!.name!.trim().compareTo(b.item!.name!.trim()));
    allProducts.value = storageProductList;
    filteredProducts.value = storageProductList;

    if(allProducts.isEmpty) {
      getBranchStock(box);
    }
  }


  getSales() {
    // GetStorage box = GetStorage();
    List<SaleInfoModel> sales = getExistingOfflineSales(box);
    List<SaleInfoModel> actualSales = [];
    for(SaleInfoModel s in sales){
      if(s.sale!.saleStatus == "COMPLETE" || s.sale!.saleStatus == "PENDING"){
        actualSales.add(s);
      }
    }
    allReceipts.value = actualSales;
    filteredReceipts.value = actualSales;
    print(actualSales.map((e) => !e.syncStatus!,));
    print("All Receipts: ${allReceipts.length}");
  }

  void filterProducts({String query = '', String? category}) {
    searchQuery.value = query.trim().toLowerCase();
    final lowerCategory = category?.toLowerCase();

    // Case 1: All items and no query (reset filter)
    if (lowerCategory == 'all items' && searchQuery.value.isEmpty) {
      filteredProducts.value = allProducts.value;
      filteredProducts.value.sort((a, b) => a.item!.name!.trim().compareTo(b.item!.name!.trim()));
      return;
    }

    // Case 2: Category only (no query)
    if (lowerCategory != 'all items' && searchQuery.value.isEmpty) {
      filteredProducts.value = allProducts.value.where((product) {
        final categoryName = product.item?.category?.id?.toLowerCase() ?? '';
        return categoryName.contains(lowerCategory!);
      }).toList();
      filteredProducts.value.sort((a, b) => a.item!.name!.trim().compareTo(b.item!.name!.trim()));
      return;
    }

    // Case 3: Query only (no category filter)
    if (lowerCategory == 'all items' && searchQuery.value.isNotEmpty) {
      filteredProducts.value = allProducts.value.where((product) {
        final productName = product.item?.name?.toLowerCase() ?? '';
        final brandName = product.item?.brand?.name?.toLowerCase() ?? '';
        final categoryName = product.item?.category?.name?.toLowerCase() ?? '';
        final itemCode = product.item?.itemCode?.toLowerCase() ?? '';
        return productName.contains(searchQuery.value) || brandName.contains(searchQuery.value) || categoryName.contains(searchQuery.value) || itemCode.contains(searchQuery.value);
      }).toList();
      filteredProducts.value.sort((a, b) => a.item!.name!.trim().compareTo(b.item!.name!.trim()));
      return;
    }

    // Case 4: Both category and query filters
    filteredProducts.value = allProducts.value.where((product) {
      final productName = product.item?.name?.toLowerCase() ?? '';
      final brandName = product.item?.brand?.name?.toLowerCase() ?? '';
      final categoryName = product.item?.category?.name?.toLowerCase() ?? '';
      final itemCode = product.item?.itemCode?.toLowerCase() ?? '';

      final matchesCategory = categoryName == lowerCategory;
      final matchesSearch = productName.contains(searchQuery.value) || brandName.contains(searchQuery.value) || categoryName.contains(searchQuery.value) || itemCode.contains(searchQuery.value);

      return matchesCategory && matchesSearch;
    }).toList();
    filteredProducts.value.sort((a, b) => a.item!.name!.trim().compareTo(b.item!.name!.trim()));
  }



  List<BaseNameModel> loadItems( GetStorage box, String itemType) {
    List<BaseNameModel> list = _localStorageService.getOfflineList<BaseNameModel>(
        itemType,
            (map) => BaseNameModel.fromMap(map),
        box);
    return list;
  }



}