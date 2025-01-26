import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';
import 'package:vimbika_pos_app/src/constants/app_constants.dart';
import 'package:vimbika_pos_app/src/constants/app_routes.dart';
import 'package:vimbika_pos_app/src/features/authentication/model/user_model.dart';
import 'package:vimbika_pos_app/src/features/sale/model/product_full_info_model.dart';
import 'package:vimbika_pos_app/src/services/app_exceptions.dart';
import 'package:vimbika_pos_app/src/services/base_http_client.dart';
import 'package:vimbika_pos_app/src/services/connectivity_service.dart';
import 'package:vimbika_pos_app/src/services/local_storage_service.dart';
import 'package:vimbika_pos_app/src/services/sync_service.dart';
import 'package:vimbika_pos_app/src/shared/models/base_name_model.dart';
import 'package:vimbika_pos_app/src/shared/models/branch_model.dart';
import 'package:vimbika_pos_app/src/shared/models/dynamic_query_model.dart';
import 'package:vimbika_pos_app/src/utils/app_helper.dart';

class SaleController extends GetxController {
  late UserModel user = UserModel(firstName: "", lastName: "", userName: "");
  RxList<ProductFullInfoModel> allProducts = <ProductFullInfoModel>[].obs;
  RxList<ProductFullInfoModel> filteredProducts = <ProductFullInfoModel>[].obs;
  RxList<BaseNameModel> brands = <BaseNameModel>[].obs;
  RxList<BaseNameModel> categories = <BaseNameModel>[].obs;
  bool isItemListScreen = true;
  bool isCartScreen = false;
  Rx<int> itemCount = 0.obs;
  Rx<double> price = 0.0.obs;
  Rx<String> searchQuery = "".obs;
  var isSearching = false.obs;
  var isServerReachable = false.obs;
  var isBrandSelected = false.obs;
  var isCatSelected = false.obs;

  final ConnectivityService _connectivityService = ConnectivityService();
  final LocalStorageService _localStorageService = LocalStorageService();
  Rx<BaseNameModel?> selectedBrand = BaseNameModel().obs;
  Rx<BaseNameModel?> selectedCategory = BaseNameModel(id: "All Items", name: "All Items").obs;
  final TextEditingController searchTextEditingController = TextEditingController(text: "");
  late  GetStorage box;
  @override
  Future<void> onInit() async {
    super.onInit();

    box = GetStorage();
    var model = box.read(AppConstants.USER_INFO) ?? {};
    user = UserModel.fromMap(Map<String, dynamic>.from(model));


    isServerReachable.value =  await _connectivityService.checkServerConnection();
    List<BaseNameModel> brandList = loadItems(box, AppConstants.BRAND_LIST);
    brands.value = brandList;
    List<BaseNameModel> catList = loadItems(box, AppConstants.CATEGORY_LIST);
    catList.insert(0, BaseNameModel(id: "All Items", name: "All Items"));
    selectedCategory.value = catList[0];
    categories.value = catList;
    getBranchStock(box);
    bool? result = await SunmiPrinter.bindingPrinter();
    result = result ?? false;
    if(!result) {
      Get.snackbar('Printer Status', 'Sunmi built in printer not available',
          snackPosition: SnackPosition.BOTTOM);
    }
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
    print("syncing sales..");
     await SyncService.syncOfflineSales(user, box);
    print("syncing products..");
    getBranchStock(box);
    print("syncing tickets..");
     //await SyncService.syncOfflineTickets(user, box);
    print("syncing shifts..");
    await SyncService.syncOfflineShifts(user, box);
    print("syncing currencies..");
    await SyncService.getCurrencies(user, box);
    print("syncing payments..");
    await SyncService.getPaymentTypes(user, box);
    AppHelper.hideLoading();
  }
  void clearFilters() {
    selectedCategory.value = BaseNameModel();
    isCatSelected.value = false;
    selectedBrand.value = BaseNameModel();;
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

          getOfflineProducts(box);
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
          print("RES..");
         // log(response);
          if (response != null) {
            //AppHelper.hideLoading();

            List<dynamic> list = jsonDecode(response);
            List<ProductFullInfoModel> itemsList = List<ProductFullInfoModel>.from(list.map((i) => ProductFullInfoModel.fromMap(i)));
            print("ALL ITEMS..");
            print(itemsList.length);
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
        } else {
          getOfflineProducts(box);
        }
      } else{
        Get.offNamed(AppRoutes.CHOOSE_BRANCH);
      }

    } else{
      Get.offNamed(AppRoutes.CHOOSE_BRANCH);
    }
  }
  getOfflineProducts(GetStorage box){
    List<ProductFullInfoModel> storageProductList = _localStorageService.getProductList(box, false);
    allProducts.value = storageProductList;
    filteredProducts.value = storageProductList;
  }



  void filterProducts({String query = '', String? category}) {
    searchQuery.value = query.trim().toLowerCase();
    final lowerCategory = category?.toLowerCase();

    // Case 1: All items and no query (reset filter)
    if (lowerCategory == 'all items' && searchQuery.value.isEmpty) {
      filteredProducts.value = allProducts.value;
      return;
    }

    // Case 2: Category only (no query)
    if (lowerCategory != 'all items' && searchQuery.value.isEmpty) {
      filteredProducts.value = allProducts.value.where((product) {
        final categoryName = product.item?.category?.id?.toLowerCase() ?? '';
        print(categoryName + ' VS '+ lowerCategory!);

        // return categoryName == lowerCategory;
        return categoryName.contains(lowerCategory);
      }).toList();
      return;
    }

    // Case 3: Query only (no category filter)
    if (lowerCategory == 'all items' && searchQuery.value.isNotEmpty) {
      filteredProducts.value = allProducts.value.where((product) {
        final productName = product.item?.name?.toLowerCase() ?? '';
        final brandName = product.item?.brand?.name?.toLowerCase() ?? '';
        final categoryName = product.item?.category?.name?.toLowerCase() ?? '';
        return productName.contains(searchQuery.value) || brandName.contains(searchQuery.value) || categoryName.contains(searchQuery.value);
      }).toList();
      return;
    }

    // Case 4: Both category and query filters
    filteredProducts.value = allProducts.value.where((product) {
      final productName = product.item?.name?.toLowerCase() ?? '';
      final brandName = product.item?.brand?.name?.toLowerCase() ?? '';
      final categoryName = product.item?.category?.name?.toLowerCase() ?? '';

      final matchesCategory = categoryName == lowerCategory;
      final matchesSearch = productName.contains(searchQuery.value) || brandName.contains(searchQuery.value) || categoryName.contains(searchQuery.value);

      return matchesCategory && matchesSearch;
    }).toList();
  }



  List<BaseNameModel> loadItems( GetStorage box, String itemType) {
    List<BaseNameModel> list = _localStorageService.getOfflineList<BaseNameModel>(
        itemType,
            (map) => BaseNameModel.fromMap(map),
        box);
    return list;
  }

}