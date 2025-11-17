import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:vimbika_pos_app/src/constants/app_constants.dart';
import 'package:vimbika_pos_app/src/constants/app_routes.dart';
import 'package:vimbika_pos_app/src/features/authentication/model/user_model.dart';
import 'package:vimbika_pos_app/src/features/printers/model/available_printer_model.dart';
import 'package:vimbika_pos_app/src/features/sale/controller/cart_controller.dart';
import 'package:vimbika_pos_app/src/features/sale/controller/sale_controller.dart';
import 'package:vimbika_pos_app/src/features/sale/model/cart_item_model.dart';
import 'package:vimbika_pos_app/src/features/sale/model/inventory_item_model.dart';
import 'package:vimbika_pos_app/src/features/sale/model/product_full_info_model.dart';
import 'package:vimbika_pos_app/src/features/stock_requests/model/requisition_item_model.dart';
import 'package:vimbika_pos_app/src/features/stock_requests/model/requisition_model.dart';
import 'package:vimbika_pos_app/src/features/stock_requests/model/transfer_history_model.dart';
import 'package:vimbika_pos_app/src/services/app_exceptions.dart';
import 'package:vimbika_pos_app/src/services/base_http_client.dart';

import 'package:vimbika_pos_app/src/services/connectivity_service.dart';
import 'package:vimbika_pos_app/src/services/local_storage_service.dart';
import 'package:vimbika_pos_app/src/services/printer_service.dart';
import 'package:vimbika_pos_app/src/services/sync_service.dart';
import 'package:vimbika_pos_app/src/shared/models/base_name_model.dart';
import 'package:vimbika_pos_app/src/shared/models/branch_model.dart';
import 'package:vimbika_pos_app/src/shared/models/company_model.dart';
import 'package:vimbika_pos_app/src/shared/models/dynamic_query_model.dart';
import 'package:vimbika_pos_app/src/utils/app_helper.dart';
import 'package:uuid/uuid.dart';


class StockRequestController extends GetxController {
  RxList<ProductFullInfoModel> allProducts = <ProductFullInfoModel>[].obs;
  RxList<ProductFullInfoModel> filteredProducts = <ProductFullInfoModel>[].obs;
  RxList<BaseNameModel> brands = <BaseNameModel>[].obs;
  RxList<BaseNameModel> categories = <BaseNameModel>[].obs;
  late UserModel user = UserModel(firstName: "", lastName: "", userName: "");
  final ConnectivityService _connectivityService = ConnectivityService();
  Rx<String> searchQuery = "".obs;
  var isSearching = false.obs;
  var isInternetAccess = false.obs;
  late GetStorage box;
  final LocalStorageService _localStorageService = LocalStorageService();
  Rx<BranchModel?> branch = BranchModel().obs;
  Rx<CompanyModel?> company = CompanyModel().obs;
  var isBrandSelected = false.obs;
  var isCatSelected = false.obs;

  // Debouncer for save request operation
  Timer? _saveRequestDebouncer;
  var isSaving = false.obs;
  bool _isSaving = false;
  Rx<BaseNameModel?> selectedBrand = BaseNameModel().obs;
  Rx<BaseNameModel?> selectedCategory = BaseNameModel(id: "All Items", name: "All Items").obs;
  final TextEditingController searchTextEditingController = TextEditingController(text: "");
  var cartItems = <CartItemModel>[].obs;
  var isBranchSelected = false.obs;
  RxList<BranchModel> branchList = <BranchModel>[].obs;
  Rx<BranchModel?> selectedBranch = BranchModel().obs;

  Rx<RequisitionModel?> selectedReq = RequisitionModel().obs;
  RxList<TransferHistoryModel> allTransferHistory = <TransferHistoryModel>[].obs;
  RxList<TransferHistoryModel> filteredTransferHistory = <TransferHistoryModel>[].obs;
  // Rx<String> searchQueryTransferHistory = "".obs;

  RxList<RequisitionModel> allRequisitions = <RequisitionModel>[].obs;
  RxList<RequisitionModel> filteredRequisitions = <RequisitionModel>[].obs;

  RxList<TransferHistoryModel> allReqHistory = <TransferHistoryModel>[].obs;
  RxList<TransferHistoryModel> filteredReqHistory = <TransferHistoryModel>[].obs;
  final PrinterService _printerService = Get.put(PrinterService());
  RxList<AvailablePrinterModel> availablePrinters = <AvailablePrinterModel>[].obs;


  @override
  Future<void> onInit() async {
    super.onInit();
    box = GetStorage();
    var model = box.read(AppConstants.USER_INFO) ?? {};
    user = UserModel.fromMap(Map<String, dynamic>.from(model));
    isInternetAccess.value =  await _connectivityService.checkServerConnection();

    var branchModel = box.read(AppConstants.SELECTED_BRANCH) ?? {};
    branch.value = BranchModel.fromMap(Map<String, dynamic>.from(branchModel));
    var companyModel = box.read(AppConstants.ACTIVE_COMPANY) ?? {};
    company.value = CompanyModel.fromMap(Map<String, dynamic>.from(companyModel));

    List<BranchModel> branchListItems = loadItemsBranch(box, AppConstants.BRANCH_LIST);
    branchList.value = branchListItems;
    List<BaseNameModel> brandList = loadItems(box, AppConstants.BRAND_LIST);
    brands.value = brandList;
    List<BaseNameModel> catList = loadItems(box, AppConstants.CATEGORY_LIST);
    catList.insert(0, BaseNameModel(id: "All Items", name: "All Items"));
    selectedCategory.value = catList[0];
    categories.value = catList;
    getBranchStock(box);
    getTransferHistory();
    getRequisitions();
    getReqHistory();

  }

  @override
  void onClose() {
    _saveRequestDebouncer?.cancel();
    super.onClose();
  }
  List<BaseNameModel> loadItems( GetStorage box, String itemType) {
    List<BaseNameModel> list = _localStorageService.getOfflineList<BaseNameModel>(
        itemType,
            (map) => BaseNameModel.fromMap(map),
        box);
    return list;
  }
  List<BranchModel> loadItemsBranch( GetStorage box, String itemType) {
    List<BranchModel> list = _localStorageService.getOfflineList<BranchModel>(
        itemType,
            (map) => BranchModel.fromMap(map),
        box);
    return list;
  }

  Future<void> getBranchStock(GetStorage box) async{


    if(branch.value != null) {

        DynamicQueryModel dynamicQueryModel = DynamicQueryModel();
        dynamicQueryModel.branch = branch.value;
        var branchData = dynamicQueryModel.toJson();
        isInternetAccess.value =  await _connectivityService.checkServerConnection();
        if (isInternetAccess.value) {

          getOfflineProducts(box);
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

            List<dynamic> list = jsonDecode(response);
            List<ProductFullInfoModel> itemsList = List<ProductFullInfoModel>.from(list.map((i) => ProductFullInfoModel.fromMap(i)));
            print("ALL ITEMS..");
            print(itemsList.length);
            itemsList.sort((a, b) => a.stock!.compareTo(b.stock!));


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
  }
  getOfflineProducts(GetStorage box){
    List<ProductFullInfoModel> storageProductList =_localStorageService.getProductList(box, true);
    allProducts.value = storageProductList;
    filteredProducts.value = storageProductList;
  }



  List<ProductFullInfoModel> getProducts(){
    List<ProductFullInfoModel> list = _localStorageService.getOfflineList<ProductFullInfoModel>(
        AppConstants.BRANCH_PRODUCTS,
            (map) => ProductFullInfoModel.fromMap(map),
        box);
    if(list != null){
      return list;
    } else{
      return [];
    }
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

  void addToCart(ProductFullInfoModel product) {
    var index = cartItems.indexWhere((item) => item.product.id == product.id);
    if (index != -1) {
      cartItems[index].quantity++;
    } else {
      cartItems.add(CartItemModel(product: product, quantity: 1));
    }
    //calculateTotalAmounts(cartItems);
  }

  void printGRV(TransferHistoryModel transfer) async {
      _printerService.printCurrentGRV(transfer, box, _localStorageService);
  }

  void removeFromCart(CartItemModel cartItem) {
    cartItems.remove(cartItem);
    //calculateTotalAmounts(cartItems);
  }

  void incrementQuantity(CartItemModel cartItem) {
    cartItem.quantity++;
    //calculateTotalAmounts(cartItems);
    cartItems.refresh();
  }

  void decrementQuantity(CartItemModel cartItem) {
    if (cartItem.quantity > 1) {
      cartItem.quantity--;
    } else {
      removeFromCart(cartItem);
    }
    //calculateTotalAmounts(cartItems);
    cartItems.refresh();
  }

  // Debounced save request method
  void debouncedSaveRequest() {
    _saveRequestDebouncer?.cancel();
    
    if (_isSaving) {
      Get.snackbar("Info", "Save operation in progress...",
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    
    _saveRequestDebouncer = Timer(Duration(milliseconds: 500), () {
      _performSaveRequest();
    });
  }

  // Internal method that performs the actual save
  Future<void> _performSaveRequest() async {
    if (_isSaving) return;
    
    _isSaving = true;
    isSaving.value = true;
    
    try {
      await saveRequest();
    } catch (e) {
      Get.snackbar("Error", "Failed to save request: ${e.toString()}",
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      _isSaving = false;
      isSaving.value = false;
    }
  }

  saveRequest() async{
    BranchModel br = selectedBranch.value!;
    if(br.id == null){
      Get.snackbar("Select Branch", "Branch is required!", snackPosition: SnackPosition.BOTTOM);
      return;
    }
    AppHelper.showLoading("Saving New Requisition..");
    RequisitionModel val = selectedReq.value!;
    String? uuidV1;
    String url;
    String method;
    if(val.id != null){
      uuidV1 = val.uuid;
      url  = "/requisition/update";
      method = "PUT";
    } else{
      var uuid = Uuid();
      uuidV1 = uuid.v1();
      url  = "/requisition/save";
      method = "POST";
    }

    bool connectionAvailable = await _connectivityService.checkServerConnection();
    List<RequisitionItemModel> requisitionItems = [];
    double quantities = 0;
    for (var cartItem in cartItems) {
      quantities = quantities + cartItem.quantity;
      InventoryItemModel productItem = cartItem.product.item!;
      RequisitionItemModel item = RequisitionItemModel(name: "", whQtyRequest: 0, allocated: 0, quantity: cartItem.quantity, status: "REQUESTED", inventoryItem: productItem, branchQty: cartItem.product.stock, warehouseQty: 0);
      requisitionItems.add(item);
    }

    RequisitionModel requisition = RequisitionModel(id:selectedReq.value!.id, uuid: uuidV1, createdByName: selectedReq.value!.createdByName, dateCreated: selectedReq.value!.dateCreated, referenceNumber: selectedReq.value!.referenceNumber,
        timeRequested: selectedReq.value!.timeRequested,  requisitionStatus: "REQUESTED", branch: branch.value, warehouse: selectedBranch.value, requisitionItems: requisitionItems, quantities: quantities, syncStatus: false);
    //log(requisition.toJson());
    List<RequisitionModel> existingReqs = _localStorageService.getRequisitions(box);
    if(connectionAvailable){

      RequisitionModel? responseMo = await SyncService.saveStockRequest(url,requisition, user, box, method);
      print("Response from server ..");

      if(responseMo != null){
        log(responseMo.toJson());
        requisition = responseMo;
        requisition.syncStatus = true;
        bool exists = _localStorageService.requisitionExists(requisition, existingReqs);
        if(exists){
          existingReqs = _localStorageService.replaceRequisition(requisition, existingReqs);
        } else{
          existingReqs.add(requisition);
        }
      }
    } else{
      requisition.syncStatus = false;
      existingReqs.add(requisition);
    }

    List<Map<String, dynamic>> itemsListMap = existingReqs.map((item) =>
        item.toMap()).toList();
    box.write(AppConstants.REQUISITION_LIST, itemsListMap);
    cartItems.value = [];
    cartItems.refresh();
    selectedReq.value = RequisitionModel();
    AppHelper.hideLoading();
    Get.snackbar("Requisition Status", "Requisition saved successfully", snackPosition: SnackPosition.BOTTOM);
    getRequisitions();
    Get.offNamed(AppRoutes.REQUISITION_LIST_SCREEN);
  }
  void filterItemsRequisition(String query) {
    searchQuery.value = query;
    filteredRequisitions.value = allRequisitions.where((item) {
      final name = item.referenceNumber!.toLowerCase() ?? '';

      final lowerQuery = query.toLowerCase();
      return name.contains(lowerQuery);
    }).toList();
  }

  void filterItemsTransferHistory(String query) {
    searchQuery.value = query;
    filteredTransferHistory.value = allTransferHistory.where((item) {
      final name = item.reference!.toLowerCase() ?? '';

      final lowerQuery = query.toLowerCase();
      return name.contains(lowerQuery);
    }).toList();
  }

  void filterReqHistory(String query) {
    searchQuery.value = query;
    filteredReqHistory.value = allReqHistory.where((item) {
      var name = '';
      if(item.reference != null){
        name = item.reference!.toLowerCase() ?? '';
      }


      final lowerQuery = query.toLowerCase();
      return name.contains(lowerQuery);
    }).toList();
  }

  getReqHistory()async{
    bool stat = await _connectivityService.checkServerConnection();
    List<TransferHistoryModel> tickets = [];
    if(stat) {
      List<TransferHistoryModel>? items =  await SyncService.getReqHistory(user, box, company.value!.id!, branch.value!.id!);
      if(items != null){
        tickets = items;
      } else{
        tickets = loadTransfers(box,  AppConstants.REQUISITION_HISTORY);
      }
    } else{
      tickets = loadTransfers(box, AppConstants.REQUISITION_HISTORY);
    }
    allReqHistory.value = tickets;
    filteredReqHistory.value = tickets;
    allReqHistory.refresh();
    filteredReqHistory.refresh();
  }

  getTransferHistory()async{
    bool stat = await _connectivityService.checkServerConnection();
    List<TransferHistoryModel> tickets = [];
    if(stat) {
      List<TransferHistoryModel>? items =  await SyncService.syncTransferHistory(user, box, company.value!.id!, branch.value!.id!);
      if(items != null){
        tickets = items;
      } else{
        tickets = loadTransfers(box, AppConstants.TRANSFER_HISTORY_LIST);
      }
    } else{
      tickets = loadTransfers(box, AppConstants.TRANSFER_HISTORY_LIST);
    }


    allTransferHistory.value = tickets;

    filteredTransferHistory.value = tickets;
    allTransferHistory.refresh();
    filteredTransferHistory.refresh();
  }
  List<TransferHistoryModel> loadTransfers( GetStorage box, String appCon) {
    List<TransferHistoryModel> list = _localStorageService.getOfflineList<TransferHistoryModel>(
        appCon,
            (map) => TransferHistoryModel.fromMap(map),
        box);

    return list;
  }


  getRequisitions()async{
    bool stat = await _connectivityService.checkServerConnection();
    List<RequisitionModel> tickets = [];
    if(stat) {
      List<RequisitionModel>? items =  await SyncService.syncRequisitions(user, box, company.value!.id!, branch.value!.id!);
      if(items != null){
        tickets = items;
      } else{
        tickets = loadRequisitions(box);
      }
    } else{
      tickets = loadRequisitions(box);
    }

    allRequisitions.value = tickets;

    filteredRequisitions.value = tickets;
    allRequisitions.refresh();
    filteredRequisitions.refresh();
  }
  List<RequisitionModel> loadRequisitions( GetStorage box) {
    List<RequisitionModel> list = _localStorageService.getOfflineList<RequisitionModel>(
        AppConstants.REQUISITION_LIST,
            (map) => RequisitionModel.fromMap(map),
        box);

    return list;
  }


  editRequisition(RequisitionModel item){
    List<ProductFullInfoModel> products = getProducts();
    List<CartItemModel> items = [];
    for(RequisitionItemModel reqItem in item.requisitionItems!){
      for(ProductFullInfoModel pr in products){
        if(pr.item!.id ==  reqItem.inventoryItem!.id){
          CartItemModel itemModel = CartItemModel(product:pr, quantity: reqItem.quantity!);
          items.add(itemModel);
        }
      }
    }
    selectedReq.value = item;
    // selectedBranch.value = item.warehouse;
    // isBranchSelected.value = true;

    cartItems.value = items;
    cartItems.refresh();
    Get.offNamed(AppRoutes.NEW_STOCK_REQUEST);

  }

  void showConfirmDialogToCancelItem(RequisitionModel item) {
    cancelRequest(item);
    // Get.defaultDialog(
    //   title: "Confirmation",
    //   middleText: "Are you sure you want to proceed?",
    //   textCancel: "No",
    //   textConfirm: "Yes",
    //   onCancel: () {
    //     Get.back(); // Close the dialog
    //   },
    //   onConfirm: () {
    //
    //
    //   },
    // );
  }

  cancelRequest(RequisitionModel item) async{
    AppHelper.showLoading("Cancelling Requisition..");
    for(RequisitionItemModel req in item.requisitionItems!){
      req.inventoryItem!.images = [];
      req.inventoryItem!.productImages = [];
    }
    item.requisitionStatus = "CANCELLED";
    List<RequisitionModel> existingReqs = _localStorageService.getRequisitions(box);
    RequisitionModel? responseMo = await SyncService.saveStockRequest("/requisition/update",item, user, box, "PUT");
    AppHelper.hideLoading();

    if(responseMo != null){
      existingReqs = _localStorageService.replaceRequisition(responseMo, existingReqs);
      filteredRequisitions.value = existingReqs;
      allRequisitions.value = existingReqs;
      filteredRequisitions.refresh();
      allRequisitions.refresh();
      List<Map<String, dynamic>> itemsListMap = existingReqs.map((item) =>
          item.toMap()).toList();
      box.write(AppConstants.REQUISITION_LIST, itemsListMap);
      Get.snackbar("Requisition Status", "Requisition cancelled successfully", snackPosition: SnackPosition.BOTTOM);

    } else{
      Get.snackbar("Requisition Status", "Failed to cancel request!", snackPosition: SnackPosition.BOTTOM);
    }

  }
}