import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:ffi';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:vimbika_pos_app/src/constants/app_constants.dart';
import 'package:vimbika_pos_app/src/features/authentication/model/user_model.dart';
import 'package:vimbika_pos_app/src/features/sale/model/sale_infor_model.dart';
import 'package:vimbika_pos_app/src/features/sale/model/sale_item_response_model.dart';
import 'package:vimbika_pos_app/src/features/sale/model/sale_model.dart';
import 'package:vimbika_pos_app/src/features/sale/model/sale_response_model.dart';
import 'package:vimbika_pos_app/src/features/shift/model/shift_currency_response_model.dart';
import 'package:vimbika_pos_app/src/features/shift/model/shift_item_response_model.dart';
import 'package:vimbika_pos_app/src/features/shift/model/shift_model.dart';
import 'package:vimbika_pos_app/src/features/shift/model/shift_response_model.dart';
import 'package:vimbika_pos_app/src/features/stock_requests/model/customer_response_model.dart';
import 'package:vimbika_pos_app/src/features/stock_requests/model/requisition_model.dart';
import 'package:vimbika_pos_app/src/features/stock_requests/model/requisition_response_model.dart';
import 'package:vimbika_pos_app/src/features/stock_requests/model/transfer_history_model.dart';
import 'package:vimbika_pos_app/src/features/stock_requests/model/transfer_history_response_model.dart';
import 'package:vimbika_pos_app/src/features/ticket/model/ticket_model.dart';
import 'package:vimbika_pos_app/src/features/ticket/model/ticket_response_model.dart';
import 'package:vimbika_pos_app/src/services/app_exceptions.dart';
import 'package:vimbika_pos_app/src/services/base_http_client.dart';
import 'package:vimbika_pos_app/src/services/local_storage_service.dart';
import 'package:vimbika_pos_app/src/shared/models/company_model.dart';
import 'package:vimbika_pos_app/src/shared/models/currency_model.dart';
import 'package:vimbika_pos_app/src/shared/models/payment_type_model.dart';
import 'package:vimbika_pos_app/src/utils/app_helper.dart';

import '../features/shift/model/currency_amount.dart';
import '../shared/models/customer_model.dart';


class SyncService {
  // static Future<void> syncOfflineSales(UserModel user, GetStorage box) async {
  //   List<SaleInfoModel> offlineSales = loadSales(box);
  //   List<SaleInfoModel> failedSyncSales = [];
  //   List<SaleModel> saleItems = [];
  //   List<SaleInfoModel> offlineSalesUpdated = [];
  //
  //   for (SaleInfoModel saleInfo in offlineSales) {
  //     if (!saleInfo.syncStatus!) {
  //       try {
  //         failedSyncSales.add(saleInfo);
  //         saleItems.add(saleInfo.sale!);
  //         print(saleInfo.sale!.items!.length);
  //       } catch (e, stackTrace) {
  //         print('Error occurred while processing saleInfo: $e');
  //         print(stackTrace);
  //       }
  //
  //       String jsonSaleItems = json.encode(saleItems.map((sale) => sale.toMap()).toList());
  //       AppHelper.showLoading("Syncing sales....");
  //
  //       var response = await BaseHttpClient()
  //           .postAuthWithCompanyHeader("/sale/sale-mobile", jsonSaleItems, user.companyId!, "POST")
  //           .catchError((onError) {
  //         print(onError);
  //         AppHelper.hideLoading();
  //         if (onError is BadRequestException) {
  //           var apiError = json.decode(onError.message!);
  //           AppHelper.showErroDialog(description: apiError["reason"]);
  //         } else {
  //           AppHelper.handleError(onError);
  //         }
  //         offlineSalesUpdated.addAll(failedSyncSales);
  //       });
  //
  //       if (response != null) {
  //         SaleResponseModel saleResponseModel = SaleResponseModel.fromJson(response);
  //         for (SaleModel saleInfoFromServer in saleResponseModel.sales!) {
  //           if (saleInfo.sale!.posReference == saleInfoFromServer.posReference) {
  //             SaleInfoModel saleInfoMod = SaleInfoModel(sale: saleInfoFromServer, syncStatus: true);
  //             offlineSalesUpdated.add(saleInfoMod);
  //           }
  //         }
  //         AppHelper.hideLoading();
  //         Get.snackbar("Success", "Data synced successfully");
  //       } else {
  //         Get.snackbar("Error", "No response from server");
  //         AppHelper.hideLoading();
  //       }
  //     } else {
  //       offlineSalesUpdated.add(saleInfo);
  //     }
  //   }
  //   writeSaleInfor(box, offlineSalesUpdated);
  // }
  // static void writeSaleInfor(GetStorage box, List<SaleInfoModel> itemsList){
  //   List<Map<String, dynamic>> itemsListMap = itemsList.map((item) =>
  //       item.toMap()).toList();
  //   box.write(AppConstants.SALE_LIST, itemsListMap);
  // }


  static Future<SaleModel?> saveSale(SaleModel sale, UserModel user, GetStorage box, CompanyModel company) async{
    String jsonSaleItems = sale.toJson();
    var response = await BaseHttpClient().postAuthWithCompanyHeader("/sale/save", jsonSaleItems, company.id!, "POST").catchError((onError){
      //AppHelper.hideLoading();
      if (onError is BadRequestException) {
        var apiError = json.decode(onError.message!);
        print(apiError);
        AppHelper.showErroDialog(description: apiError["reason"]);
      } else if (onError is UnAuthorizedException) {
        AppHelper.showErroDialog(title: "Error", description: "Unauthorized access");
      }
      else {
        print(onError);
        AppHelper.handleError(onError);
      }
    });
    // AppHelper.hideLoading();
    if(response != null){
      SaleItemResponseModel saleResponseModel = SaleItemResponseModel.fromJson(response);

      return saleResponseModel.item;


    } else{
      //failed to save sale
      return null;
    }
  }

  static Future<RequisitionModel?> saveStockRequest(String url, RequisitionModel stockRequest, UserModel user, GetStorage box, String method) async{
    String jsonSaleItems = stockRequest.toJson();

    var response = await BaseHttpClient().postAuthWithCompanyHeader(url, jsonSaleItems, user.companyId!, method).catchError((onError){
      //AppHelper.hideLoading();
      if (onError is BadRequestException) {
        var apiError = json.decode(onError.message!);
        print(apiError);
        AppHelper.showErroDialog(description: apiError["reason"]);
      } else if (onError is UnAuthorizedException) {
        AppHelper.showErroDialog(title: "Error", description: "Unauthorized access");
      }
      else {
        print(onError);
        AppHelper.handleError(onError);
      }
    });
    // AppHelper.hideLoading();
    if(response != null){
      RequisitionResponseModel responseModel = RequisitionResponseModel.fromJson(response);
      return responseModel.item;


    } else{
      //failed to save sale
      return null;
    }
  }
  static Future<TransferHistoryModel?> saveTransfer(TransferHistoryModel transfer, UserModel user, GetStorage box) async{
    print("company");
    print(user.companyId!);
    String jsonSaleItems = transfer.toJson();
    log(jsonSaleItems);
    var response = await BaseHttpClient().postAuthWithCompanyHeader("/transfer-history/transfer", jsonSaleItems, user.companyId!, "POST").catchError((onError){
      //AppHelper.hideLoading();
      if (onError is BadRequestException) {
        var apiError = json.decode(onError.message!);
        print(apiError);
        AppHelper.showErroDialog(description: apiError["reason"]);
      } else if (onError is UnAuthorizedException) {
        AppHelper.showErroDialog(title: "Error", description: "Unauthorized access");
      }
      else {
        print(onError);
        AppHelper.handleError(onError);
      }
    });
    // AppHelper.hideLoading();
    if(response != null){
      TransferHistoryResponseModel responseModel = TransferHistoryResponseModel.fromJson(response);
      return responseModel.item;
    } else{
      //failed to save sale
      return null;
    }
  }

  static Future<CustomerModel?> saveCustomer( UserModel user, GetStorage box) async{
    final LocalStorageService _localStorageService = LocalStorageService();
    List<CustomerModel> customers = _localStorageService.getOfflineList<CustomerModel>(
        AppConstants.CUSTOMER_LIST,
            (map) => CustomerModel.fromMap(map),
        box);
    customers = customers.where((customer) => customer.id == null).toList();
    print(customers.length);
    for(CustomerModel customerModel in customers) {
      String jsonSaleItems = customerModel.toJson();
      var response = await BaseHttpClient()
          .postAuthWithCompanyHeader("/customer/save",
              jsonSaleItems, user.companyId!, "POST")
          .catchError((onError) {
        //AppHelper.hideLoading();
        if (onError is BadRequestException) {
          var apiError = json.decode(onError.message!);
          print(apiError);
          AppHelper.showErroDialog(description: apiError["reason"]);
        } else if (onError is UnAuthorizedException) {
          AppHelper.showErroDialog(
              title: "Error", description: "Unauthorized access");
        } else {
          print(onError);
          AppHelper.handleError(onError);
        }
      });
      // AppHelper.hideLoading();
      if (response != null) {
        CustomerResponseModel responseModel =
        CustomerResponseModel.fromJson(response);
        var index = customers.indexWhere((customer)=>customer.name==responseModel.item?.name);
        if(index!= -1)
        customers[index] = responseModel.item!;
        // return responseModel.item;
      } else {
        //failed to save sale
        return null;
      }
    }
    List<Map<String, dynamic>> itemsListMap = customers.map((item) =>
        item.toMap()).toList();
    box.write(AppConstants.CUSTOMER_LIST, itemsListMap);
    return null;
  }
  static Future<List<SaleInfoModel>?>  syncTickets(UserModel user, GetStorage box, String companyId, String branchId) async{
    LocalStorageService _localStorageService = LocalStorageService();
    //print("Getting tickets...");
    var response = await BaseHttpClient().getAuthWithCompanyHeader("/mobile/pos/ticket/list/" + branchId, companyId).catchError((onError){
      if (onError is BadRequestException) {
        var apiError = json.decode(onError.message!);
        AppHelper.showErroDialog(description: apiError["reason"]);
      } else {
        AppHelper.handleError(onError);
      }
    });
    if(response != null) {
      List<dynamic> list = jsonDecode(response);
      List<SaleModel> itemsListFromServer = List<SaleModel>.from(list.map((i) => SaleModel.fromMap(i)));
      List<SaleInfoModel> fromServer = [];
      List<SaleInfoModel> offlineSaleList = _localStorageService.getOfflineList<SaleInfoModel>(
          AppConstants.SALE_LIST,
              (map) => SaleInfoModel.fromMap(map),
          box);
      for(SaleModel s in itemsListFromServer){
        SaleInfoModel  infoModel = SaleInfoModel(sale: s, syncStatus: true);
        fromServer.add(infoModel);
      }
      offlineSaleList.addAll(fromServer);
      List<SaleInfoModel> processedTickets = processTickets(offlineSaleList);//sort and remove duplicates

      List<Map<String, dynamic>> itemsListMap = processedTickets.map((item) =>
          item.toMap()).toList();
      box.write(AppConstants.SALE_LIST, itemsListMap);
      return processedTickets;
    }
    return null;
  }
  static Future<List<TransferHistoryModel>?>  syncTransferHistory(UserModel user, GetStorage box, String companyId, String branchId) async{
    LocalStorageService _localStorageService = LocalStorageService();
    print("Getting transfer history...");
    var response = await BaseHttpClient().getAuthWithCompanyHeader("/transfer-history/get-transfers/PENDING", companyId).catchError((onError){
      if (onError is BadRequestException) {
        var apiError = json.decode(onError.message!);
        AppHelper.showErroDialog(description: apiError["reason"]);
      } else {
        AppHelper.handleError(onError);
      }
    });
    print("Transfer History");
   // log(response);
    if(response != null) {
      List<dynamic> list = jsonDecode(response);
      List<TransferHistoryModel> itemsListFromServer = List<TransferHistoryModel>.from(list.map((i) => TransferHistoryModel.fromMap(i)));
      // List<TransferHistoryModel> fromServer = [];
      // List<TransferHistoryModel> offlineList = _localStorageService.getOfflineList<TransferHistoryModel>(
      //     AppConstants.TRANSFER_HISTORY_LIST,
      //         (map) => TransferHistoryModel.fromMap(map),
      //     box);
      //offlineList.addAll(itemsListFromServer);
      List<TransferHistoryModel> processed = processTransferHistory(itemsListFromServer);//sort and remove duplicates

      List<Map<String, dynamic>> itemsListMap = processed.map((item) =>
          item.toMap()).toList();
      box.write(AppConstants.TRANSFER_HISTORY_LIST, itemsListMap);
      return processed;
    }
    return null;
  }
  static Future<List<TransferHistoryModel>?>  getReqHistory(UserModel user, GetStorage box, String companyId, String branchId) async{

    print("Getting Req history...");
    var response = await BaseHttpClient().getAuthWithCompanyHeader("/transfer-history/get-transfers/RECEIVED", companyId).catchError((onError){
      if (onError is BadRequestException) {
        var apiError = json.decode(onError.message!);
        AppHelper.showErroDialog(description: apiError["reason"]);
      } else {
        AppHelper.handleError(onError);
      }
    });
    print("Req History");
    // log(response);
    if(response != null) {
      List<dynamic> list = jsonDecode(response);
      List<TransferHistoryModel> itemsListFromServer = List<TransferHistoryModel>.from(list.map((i) => TransferHistoryModel.fromMap(i)));

      List<Map<String, dynamic>> itemsListMap = itemsListFromServer.map((item) =>
          item.toMap()).toList();
      box.write(AppConstants.REQUISITION_HISTORY, itemsListMap);
      return itemsListFromServer;
    }
    return null;
  }
  static Future<List<RequisitionModel>?>  syncRequisitions(UserModel user, GetStorage box, String companyId, String branchId) async{
    LocalStorageService _localStorageService = LocalStorageService();
    print("Getting requisitions...");
    var response = await BaseHttpClient().getAuthWithCompanyHeader("/requisition/get-requisitions", companyId).catchError((onError){
      if (onError is BadRequestException) {
        var apiError = json.decode(onError.message!);
        AppHelper.showErroDialog(description: apiError["reason"]);
      } else {
        AppHelper.handleError(onError);
      }
    });
    if(response != null) {
      List<dynamic> list = jsonDecode(response);
      List<RequisitionModel> itemsListFromServer = List<RequisitionModel>.from(list.map((i) => RequisitionModel.fromMap(i)));
       List<RequisitionModel> notSyncedAndLatestFromServer = [];
      List<RequisitionModel> offlineList = _localStorageService.getOfflineList<RequisitionModel>(
          AppConstants.REQUISITION_LIST,(map) => RequisitionModel.fromMap(map),box);
      for(RequisitionModel s in offlineList){
           bool? sts = s.syncStatus != null ? s.syncStatus : true;
             if (!sts!) {
               notSyncedAndLatestFromServer.add(s);
             }

      }
      notSyncedAndLatestFromServer.addAll(itemsListFromServer);

      List<Map<String, dynamic>> itemsListMap = notSyncedAndLatestFromServer.map((item) =>
          item.toMap()).toList();
      box.write(AppConstants.REQUISITION_LIST, itemsListMap);
      return notSyncedAndLatestFromServer;
    }
    return null;
  }

  // static  syncOfflineTickets(UserModel user,  GetStorage box) async {
  //   List<TicketModel> tickets = loadTickets(box);
  //   List<TicketModel> itemsToBeSynced = [];
  //   List<TicketModel> upToDateItems = [];
  //   List<TicketModel> updateItems = [];
  //   print("Syncing tickets " + tickets.length.toString());
  //
  //   for (TicketModel sh in tickets) {
  //     print("sync status");
  //     print(!sh.synced!);
  //     if (!sh.synced!) {
  //       itemsToBeSynced.add(sh);
  //     } else {
  //       upToDateItems.add(sh);
  //     }
  //   }
  //   String jsonItems = json.encode(
  //       itemsToBeSynced.map((shift) => shift.toMap()).toList());
  //   var response = await BaseHttpClient()
  //       .postAuthWithCompanyHeader(
  //       "/mobile/pos/ticket/save", jsonItems, user.companyId!)
  //       .catchError((onError) {
  //     print(onError);
  //     AppHelper.hideLoading();
  //     if (onError is BadRequestException) {
  //       var apiError = json.decode(onError.message!);
  //       AppHelper.showErroDialog(description: apiError["reason"]);
  //     } else {
  //       AppHelper.handleError(onError);
  //     }
  //   });
  //   if (response != null) {
  //     TicketResponseModel ticketResponseModel = TicketResponseModel.fromJson(response);
  //     updateItems.addAll(ticketResponseModel.items ?? []);
  //     updateItems.addAll(upToDateItems);
  //     List<TicketModel> processedTickets = processTickets(updateItems);//sort and remove duplicates
  //     List<Map<String, dynamic>> itemsListMap = processedTickets.map((item) =>
  //         item.toMap()).toList();
  //     box.write(AppConstants.TICKET_LIST, itemsListMap);
  //   } else {
  //     Get.snackbar("Error", "No response from server");
  //
  //   }
  // }
  static  syncOfflineShifts(UserModel user,  GetStorage box) async {
    List<ShiftModel> shiftInfo = loadShiftInfo(box);
    List<ShiftModel> itemsToBeSynced = [];
    List<CurrencyAmount> currencyItemsToBeSynced = [];
    List<ShiftModel> upToDateItems = [];
    List<ShiftModel> updateItems = [];
    List<CurrencyAmount> updateCurrencyItems = [];
    print("Syncing shifts " + shiftInfo.length.toString());

    for (ShiftModel sh in shiftInfo) {
      print(sh.toJson());
      if (!sh.stopSync! && !sh.isShiftClosed!) {
        itemsToBeSynced.add(sh);
        if (sh.shiftCurrencyAmounts != null && sh.shiftCurrencyAmounts!.isNotEmpty) {
          for (CurrencyAmount ca in sh.shiftCurrencyAmounts!) {
            print(ca.toJson());
            ca.active=true;
              currencyItemsToBeSynced.add(ca);
          }
        }
      } else {
        upToDateItems.add(sh);
      }
    }
    debugPrint("Items to be synced " + currencyItemsToBeSynced.toString());
    if(currencyItemsToBeSynced.isNotEmpty) {
      String jsonShiftCurrencyItems = json.encode(
          currencyItemsToBeSynced.map((shift) => shift.toMap()).toList());
      debugPrint("Shift currency items to be synced " + jsonShiftCurrencyItems);
      var shiftCurrencyResponse = await BaseHttpClient()
          .postAuthWithCompanyHeader("/mobile/pos/shift/save-currency-amounts",
              jsonShiftCurrencyItems, user.companyId!, "POST")
          .catchError((onError) {
        print(onError);
        AppHelper.hideLoading();
        if (onError is BadRequestException) {
          var apiError = json.decode(onError.message!);
          AppHelper.showErroDialog(description: apiError["reason"]);
        } else {
          AppHelper.handleError(onError);
        }
      });
      if (shiftCurrencyResponse != null) {
        debugPrint("Shift currency response " + shiftCurrencyResponse.toString());
        ShiftCurrencyResponseModel saleResponseModel =
            ShiftCurrencyResponseModel.fromJson(shiftCurrencyResponse);
        debugPrint("Shift currency items " + saleResponseModel.items.toString());
        updateCurrencyItems.addAll(saleResponseModel.items ?? []);
      }
    }
    debugPrint("Items to be synced " + itemsToBeSynced.toString());

    for (ShiftModel sh in itemsToBeSynced) {
      if (sh.shiftCurrencyAmounts != null && sh.shiftCurrencyAmounts!.isNotEmpty) {
        for (CurrencyAmount ca in updateCurrencyItems) {
          if(ca.shiftReference == sh.shiftReference){
            sh.shiftCurrencyAmounts?.remove(sh.shiftCurrencyAmounts?.firstWhere((element) => element.ref==ca.ref));
            sh.shiftCurrencyAmounts?.add(ca);
          }
        }
      }
    }
    debugPrint("Currency items to be synced " + itemsToBeSynced.toString());

      String jsonShiftItems = json.encode(
        itemsToBeSynced.map((shift) => shift.toMap()).toList());
      debugPrint("Shift items to be synced " + jsonShiftItems);
    debugPrint("Syncing shifts " + jsonShiftItems);
    var response = await BaseHttpClient()
        .postAuthWithCompanyHeader(
        "/mobile/pos/shift/save", jsonShiftItems, user.companyId!, "POST")
        .catchError((onError) {
      print(onError);
      AppHelper.hideLoading();
      if (onError is BadRequestException) {
        var apiError = json.decode(onError.message!);
        AppHelper.showErroDialog(description: apiError["reason"]);
      } else {
        AppHelper.handleError(onError);
      }
    });
    if (response != null) {
      ShiftResponseModel saleResponseModel = ShiftResponseModel.fromJson(response);
      updateItems.addAll(saleResponseModel.items ?? []);
      updateItems.addAll(upToDateItems);
      //List<ShiftModel> items =  saleResponseModel.items ?? [];

      List<Map<String, dynamic>> itemsListMap = updateItems.map((item) =>
          item.toMap()).toList();
      box.write(AppConstants.SHIFT_LIST, itemsListMap);

      // Get.snackbar("Success", "Shifts synced successfully");
    } else {
      //Get.snackbar("Error", "No response from server");

    }
  }
  static Future<ShiftModel?> getOpenedShift(UserModel user, GetStorage box) async{
    var response = await BaseHttpClient().getAuthWithCompanyHeader("/mobile/pos/shift/opened_shift/" + user.id!, user.companyId!).catchError((onError){
      if (onError is BadRequestException) {
        var apiError = json.decode(onError.message!);
        AppHelper.showErroDialog(description: apiError["reason"]);
      } else {
        // AppHelper.handleError(onError);
      }
    });
    // print("Opended shift ");
    // log(response);
    if(response != null) {
      ShiftItemResponseModel shiftResponseModel = ShiftItemResponseModel.fromJson(response);
      if (shiftResponseModel.available!) {
        return shiftResponseModel.item;
      }
    }
     return null;
  }
  static deleteTicket(UserModel user, GetStorage box, String saleId) async{
    var response = await BaseHttpClient().getAuthWithCompanyHeader("/mobile/pos/ticket/delete/" + saleId, user.companyId!).catchError((onError){
      if (onError is BadRequestException) {
        var apiError = json.decode(onError.message!);
        AppHelper.showErroDialog(description: apiError["reason"]);
      } else {
        // AppHelper.handleError(onError);
      }
    });
     print("Delete Ticket");
     log(response);
  }
  static List<ShiftModel> loadShiftInfo(GetStorage box) {
    LocalStorageService _localStorageService = LocalStorageService();
    List<ShiftModel> list = _localStorageService.getOfflineList<ShiftModel>(
        AppConstants.SHIFT_LIST,
            (map) => ShiftModel.fromMap(map),
        box);
    return list;
  }
  static List<CurrencyAmount> loadShiftCurrencyInfo(GetStorage box) {
    List<CurrencyAmount> currencyAmounts = [];
    LocalStorageService _localStorageService = LocalStorageService();
    List<ShiftModel> list = _localStorageService.getOfflineList<ShiftModel>(
        AppConstants.SHIFT_LIST,
            (map) => ShiftModel.fromMap(map),
        box);
    for(ShiftModel sh in list){
      if(sh.shiftCurrencyAmounts != null && sh.shiftCurrencyAmounts!.isNotEmpty){
        currencyAmounts.addAll(sh.shiftCurrencyAmounts!);
      }
    }
    return currencyAmounts;
  }
  static List<TicketModel> loadTickets( GetStorage box) {
    LocalStorageService _localStorageService = LocalStorageService();
    List<TicketModel> list = _localStorageService.getOfflineList<TicketModel>(
        AppConstants.TICKET_LIST,
            (map) => TicketModel.fromMap(map),
        box);
    return list;
  }
  static Future<void> getCurrencies(UserModel user, GetStorage box) async{
    print("updating currencies..");
    var response = await BaseHttpClient().getAuthWithCompanyHeader("/currency/get-all", user.companyId!).catchError((onError){
      if (onError is BadRequestException) {
        var apiError = json.decode(onError.message!);
        AppHelper.showErroDialog(description: apiError["reason"]);
      } else {
       // AppHelper.handleError(onError);
      }
    });
    if(response != null) {
      List<dynamic> list = jsonDecode(response);
      List<CurrencyModel> itemsList = List<CurrencyModel>.from(list.map((i) => CurrencyModel.fromMap(i)));
      List<Map<String, dynamic>> itemsListMap = itemsList.map((item) =>
          item.toMap()).toList();
      box.write(AppConstants.CURRENCY_LIST, itemsListMap);
    }
  }

   static Future<void>  getPaymentTypes(UserModel user, GetStorage box) async{
    var response = await BaseHttpClient().getAuthWithCompanyHeader("/payment-method/get-all", user.companyId!).catchError((onError){
      if (onError is BadRequestException) {
        var apiError = json.decode(onError.message!);
        AppHelper.showErroDialog(description: apiError["reason"]);
      } else {
        AppHelper.handleError(onError);
      }
    });
    if(response != null) {
      List<dynamic> list = jsonDecode(response);
      List<PaymentTypeModel> itemsList = List<PaymentTypeModel>.from(list.map((i) => PaymentTypeModel.fromMap(i)));
      List<Map<String, dynamic>> itemsListMap = itemsList.map((item) =>
          item.toMap()).toList();
      box.write(AppConstants.PAYMENT_TYPE_LIST, itemsListMap);
    }
  }
  static List<SaleInfoModel> processTickets(List<SaleInfoModel> upToDateItems) {
    // Remove duplicates by using a Map to keep only the last occurrence of each unique ID
    Map<String?, SaleInfoModel> uniqueItems = {};
    for (var item in upToDateItems) {
      uniqueItems[item.sale!.id] = item;  // The last occurrence will overwrite the previous one
    }

    // Convert the map back to a list
    List<SaleInfoModel> uniqueTicketList = uniqueItems.values.toList();

    // Define the date format to parse the timeInitiated field
    DateFormat dateFormat = DateFormat(AppConstants.APP_DATE_TIME_FMT);

    // Sort by timeInitiated in descending order (latest time first)
    // uniqueTicketList.sort((a, b) {
    //   DateTime dateA = a.sale!.timeIniated != null ? dateFormat.parse(a.sale!.timeIniated!) : DateTime(0);
    //   DateTime dateB = b.sale!.timeIniated != null ? dateFormat.parse(b.sale!.timeIniated!) : DateTime(0);
    //   return dateB.compareTo(dateA);  // Descending order
    // });
   return uniqueTicketList;
  }
  static List<TransferHistoryModel> processTransferHistory(List<TransferHistoryModel> upToDateItems) {
    Map<String?, TransferHistoryModel> uniqueItems = {};
    for (var item in upToDateItems) {
      uniqueItems[item.id] = item;  // The last occurrence will overwrite the previous one
    }

    List<TransferHistoryModel> uniqueList = uniqueItems.values.toList();
    // DateFormat dateFormat = DateFormat(AppConstants.APP_DATE_TIME_FMT);
    // uniqueList.sort((a, b) {
    //   print("Date Time Transfer History");
    //   print(a.dateTime);
    //   DateTime dateA = a.dateTime != null ? dateFormat.parse(a.dateTime!) : DateTime(0);
    //   DateTime dateB = b.dateTime != null ? dateFormat.parse(b.dateTime!) : DateTime(0);
    //   return dateB.compareTo(dateA);  // Descending order
    // });
    return uniqueList;
  }

}
