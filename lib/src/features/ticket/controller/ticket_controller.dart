import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';
import 'package:vimbika_pos_app/src/constants/app_routes.dart';
import 'package:vimbika_pos_app/src/features/authentication/model/user_model.dart';
import 'package:vimbika_pos_app/src/features/sale/controller/cart_controller.dart';
import 'package:vimbika_pos_app/src/features/sale/controller/sale_controller.dart';
import 'package:vimbika_pos_app/src/features/sale/model/cart_item_model.dart';
import 'package:vimbika_pos_app/src/features/sale/model/product_full_info_model.dart';
import 'package:vimbika_pos_app/src/features/sale/model/sale_infor_model.dart';
import 'package:vimbika_pos_app/src/features/sale/model/sale_item_model.dart';
import 'package:vimbika_pos_app/src/services/connectivity_service.dart';
import 'package:vimbika_pos_app/src/services/local_storage_service.dart';
import 'package:vimbika_pos_app/src/services/sync_service.dart';
import 'package:vimbika_pos_app/src/shared/models/base_name_model.dart';
import 'package:vimbika_pos_app/src/shared/models/branch_model.dart';
import 'package:vimbika_pos_app/src/shared/models/company_model.dart';
import 'package:vimbika_pos_app/src/shared/models/currency_model.dart';
import 'package:vimbika_pos_app/src/utils/app_helper.dart';

import '../../../constants/app_constants.dart';

class TicketController extends GetxController {
  final SaleController saleController = Get.find();
  final CartController cartController = Get.find();
  late UserModel user = UserModel(firstName: "", lastName: "", userName: "");
  final ConnectivityService _connectivityService = ConnectivityService();
  RxList<SaleInfoModel> allTickets = <SaleInfoModel>[].obs;
  RxList<SaleInfoModel> filteredTickets = <SaleInfoModel>[].obs;
  Rx<String> searchQuery = "".obs;
  var isInternetAccess = false.obs;
  late GetStorage box;
  final LocalStorageService _localStorageService = LocalStorageService();
  final TextEditingController ticketNameEditingController = TextEditingController();
  var ticketName = "".obs;
  final TextEditingController ticketCommentEditingController = TextEditingController();
  var ticketComment = "".obs;
  GlobalKey<FormState> ticketFormKeyForm = GlobalKey<FormState>();
  Rx<CurrencyModel?> selectedCurrency = CurrencyModel().obs;
  Rx<BranchModel?> branch = BranchModel().obs;
  Rx<CompanyModel?> company = CompanyModel().obs;
  RxInt openedTicketsCount = 0.obs;
  Timer? _syncTimer; // Add a timer variable

  @override
  Future<void> onInit() async {
    super.onInit();
    box = GetStorage();
    var model = box.read(AppConstants.USER_INFO) ?? {};
    user = UserModel.fromMap(Map<String, dynamic>.from(model));
    isInternetAccess.value =  await _connectivityService.checkServerConnection();

    var branchModel = box.read(AppConstants.SELECTED_BRANCH) ?? {};
    branch.value = BranchModel.fromMap(Map<String, dynamic>.from(branchModel));
    getTickets();
    var companyModel = box.read(AppConstants.ACTIVE_COMPANY) ?? {};
    company.value = CompanyModel.fromMap(Map<String, dynamic>.from(companyModel));
    // Start a periodic timer to sync tickets every 5 seconds
    _syncTimer = Timer.periodic(Duration(seconds: 9), (timer) async {
      getTickets();
    });
  }

  @override
  void onClose() {
    // Cancel the timer when the controller is disposed
    _syncTimer?.cancel();
    super.onClose();
  }

  List<SaleInfoModel> loadItems( GetStorage box) {
    List<SaleInfoModel> tickets = [];
    List<SaleInfoModel> list = _localStorageService.getOfflineList<SaleInfoModel>(
        AppConstants.SALE_LIST,
            (map) => SaleInfoModel.fromMap(map),
        box);
    for(SaleInfoModel sale in list){
      if(sale.sale!.saleStatus == "ON_HOLD" && sale.sale!.active!){
        tickets.add(sale);
      }
    }
    return tickets;
  }
  getTickets()async{
    //AppHelper.showLoading("Loading....");
    bool stat = await _connectivityService.checkServerConnection();
    List<SaleInfoModel> tickets = [];
    if(stat) {
      List<SaleInfoModel>? items =  await SyncService.syncTickets(user, box, company.value!.id!, branch.value!.id!);
      if(items != null){
        for(SaleInfoModel sale in items){
          if(sale.sale!.saleStatus == "ON_HOLD" && sale.sale!.active!){
            tickets.add(sale);
          }
        }
      } else{
        tickets = loadItems(box);
      }
    } else{
      tickets = loadItems(box);
    }

    openedTicketsCount.value = tickets.length;
    allTickets.value = tickets;

    filteredTickets.value = tickets;
    allTickets.refresh();
    filteredTickets.refresh();

    //AppHelper.hideLoading();
  }
  void filterItems(String query) {
    print(query);
    searchQuery.value = query;
    filteredTickets.value = allTickets.where((item) {
      final name = item.sale!.ticketName!.toLowerCase() ?? '';

      final lowerQuery = query.toLowerCase();
      return name.contains(lowerQuery);
    }).toList();
  }
  void showConfirmDialogToSaveItem() {
    saveItem();
  }

  saveItem() async{

    List<SaleInfoModel> tickets = allTickets;

    int count = tickets.length + 1;
    String ref = AppConstants.getDateNowRef("TICKET", count);


    List<CartItemModel> cartItems = List.from(cartController.cartItems);
    cartController.chargeSale("ON_HOLD", true, ref, ticketName.value, ticketComment.value, cartItems, "");
    Get.snackbar("New Ticket", "Ticket Saved Successfully", snackPosition: SnackPosition.BOTTOM);
    ticketNameEditingController.text = "";
    ticketCommentEditingController.text = "";
    clearController();

  }

  clearController(){
    ticketFormKeyForm = GlobalKey<FormState>();
    //Get.delete<TicketController>();
    cartController.cartItems.value = [];
    cartController.calculateTotalAmounts([]);
    //Get.lazyPut(()=>TicketController());
    Get.offNamed(AppRoutes.SALE);

  }

  ticketActionButton(CurrencyModel currency, int cartLength){
    this.selectedCurrency.value = currency;
    print("Length");
    print(cartLength);
    if (cartLength > 0) {
      Get.toNamed(AppRoutes.TICKET_FORM);
    } else {
      Get.toNamed(AppRoutes.TICKET_LIST);
    }
  }
  void showConfirmDialogToDeleteItem(String reference, String saleId) {
    Get.defaultDialog(
      title: "Confirmation",
      middleText: "Are you sure you want to proceed?",
      textCancel: "No",
      textConfirm: "Yes",
      onCancel: () {
        Get.back(); // Close the dialog
      },
      onConfirm: () {
        deleteTicketByReference(reference, saleId);

      },
    );
  }
  // void closeTicket(String reference){
  //   String timeClosed = DateFormat(AppConstants.APP_DATE_TIME_FMT).format(DateTime.now());
  //   String fullName = user.firstName + " " + user.lastName;
  //
  //   allTickets.refresh();
  //   filteredTickets.refresh();
  //   List<Map<String, dynamic>> itemsListMap = allTickets.map((item) => item.toMap()).toList();
  //   box.write(AppConstants.TICKET_LIST, itemsListMap);
  //   Get.snackbar("Ticket", "Ticket Closed Successfully", snackPosition: SnackPosition.BOTTOM);
  //   //Get.back();
  // }
  Future<void> deleteTicketByReference(String reference, String? saleId) async {
    // Find the ticket with the matching reference
    allTickets.removeWhere((ticket) => ticket.sale!.referenceNumber == reference);
    filteredTickets.removeWhere((ticket) => ticket.sale!.referenceNumber  == reference);
    // Update storage with the new list
    List<Map<String, dynamic>> itemsListMap = allTickets.map((item) => item.toMap()).toList();
    box.write(AppConstants.SALE_LIST, itemsListMap);
    Get.snackbar("Ticket", "Ticket Deleted Successfully", snackPosition: SnackPosition.BOTTOM);
    bool stat = await _connectivityService.checkServerConnection();
    if(stat){
      if(saleId != null) {
        SyncService.deleteTicket(user, box, saleId);
      }
    }
    Navigator.of(Get.context!).pop();
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
  void selectTicketAction(SaleInfoModel ticket){
    List<ProductFullInfoModel> products = getProducts();
    List<CartItemModel> saleCartItems = [];
    for(SaleItemModel saleItem in ticket.sale!.items!){
       for(ProductFullInfoModel pr in products){
         if(pr.item!.id ==  saleItem.inventoryItem!.id){
           CartItemModel itemModel = CartItemModel(product:pr, quantity: saleItem.quantity!);
           saleCartItems.add(itemModel);
         }
       }
    }
    print("TOTAL..");
    print(saleCartItems.length);
     cartController.cartItems.value = saleCartItems;
    cartController.cartItems.refresh();
     cartController.selectedCurrency.value = ticket.sale!.currency;
     cartController.isCurrencySelected.value = true;
     cartController.saleTicketId.value = ticket.sale!.id!;
     cartController.calculateTotalAmounts(saleCartItems);
     Get.offNamed(AppRoutes.SALE);
  }
  //
  //  Future<TicketModel?> saveTicket(TicketModel ticket, UserModel user, GetStorage box) async{
  //   AppHelper.showLoading("Saving...");
  //   String jsonSaleItems = ticket.toJson();
  //   var response = await BaseHttpClient().postAuthWithCompanyHeader("/mobile/pos/ticket/save_item", jsonSaleItems, user.companyId!).catchError((onError){
  //     //AppHelper.hideLoading();
  //     if (onError is BadRequestException) {
  //       var apiError = json.decode(onError.message!);
  //       print(apiError);
  //       AppHelper.showErroDialog(description: apiError["reason"]);
  //     } else if (onError is UnAuthorizedException) {
  //       AppHelper.showErroDialog(title: "Error", description: "Unauthorized access");
  //     }
  //     else {
  //       print(onError);
  //       AppHelper.handleError(onError);
  //     }
  //   });
  //   AppHelper.hideLoading();
  //   if(response != null){
  //     TicketItemResponseModel ticketRes = TicketItemResponseModel.fromJson(response);
  //     if(ticketRes.item != null){
  //       return ticketRes.item;
  //     }
  //
  //   }
  //
  //   return null;
  // }
}