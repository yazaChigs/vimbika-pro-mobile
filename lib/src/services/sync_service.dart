import 'dart:convert';
import 'dart:ffi';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:vimbika_pos_app/src/constants/app_constants.dart';
import 'package:vimbika_pos_app/src/features/authentication/model/user_model.dart';
import 'package:vimbika_pos_app/src/features/sale/model/sale_infor_model.dart';
import 'package:vimbika_pos_app/src/features/sale/model/sale_item_response_model.dart';
import 'package:vimbika_pos_app/src/features/sale/model/sale_model.dart';
import 'package:vimbika_pos_app/src/features/sale/model/sale_response_model.dart';
import 'package:vimbika_pos_app/src/features/shift/model/shift_model.dart';
import 'package:vimbika_pos_app/src/features/shift/model/shift_response_model.dart';
import 'package:vimbika_pos_app/src/features/ticket/model/ticket_model.dart';
import 'package:vimbika_pos_app/src/features/ticket/model/ticket_response_model.dart';
import 'package:vimbika_pos_app/src/services/app_exceptions.dart';
import 'package:vimbika_pos_app/src/services/base_http_client.dart';
import 'package:vimbika_pos_app/src/services/local_storage_service.dart';
import 'package:vimbika_pos_app/src/shared/models/currency_model.dart';
import 'package:vimbika_pos_app/src/shared/models/payment_type_model.dart';
import 'package:vimbika_pos_app/src/utils/app_helper.dart';


class SyncService {
  static Future<void> syncOfflineSales(UserModel user, GetStorage box) async {
    List<SaleInfoModel> offlineSales = loadSales(box);
    List<SaleInfoModel> failedSyncSales = [];
    List<SaleModel> saleItems = [];
    List<SaleInfoModel> offlineSalesUpdated = [];

    for (SaleInfoModel saleInfo in offlineSales) {
      if (!saleInfo.syncStatus!) {
        try {
          failedSyncSales.add(saleInfo);
          saleItems.add(saleInfo.sale!);
          print(saleInfo.sale!.items!.length);
        } catch (e, stackTrace) {
          print('Error occurred while processing saleInfo: $e');
          print(stackTrace);
        }

        String jsonSaleItems = json.encode(saleItems.map((sale) => sale.toMap()).toList());
        AppHelper.showLoading("Syncing sales....");

        var response = await BaseHttpClient()
            .postAuthWithCompanyHeader("/sale/sale-mobile", jsonSaleItems, user.companyId!)
            .catchError((onError) {
          print(onError);
          AppHelper.hideLoading();
          if (onError is BadRequestException) {
            var apiError = json.decode(onError.message!);
            AppHelper.showErroDialog(description: apiError["reason"]);
          } else {
            AppHelper.handleError(onError);
          }
          offlineSalesUpdated.addAll(failedSyncSales);
        });

        if (response != null) {
          SaleResponseModel saleResponseModel = SaleResponseModel.fromJson(response);
          for (SaleModel saleInfoFromServer in saleResponseModel.sales!) {
            if (saleInfo.sale!.posReference == saleInfoFromServer.posReference) {
              SaleInfoModel saleInfoMod = SaleInfoModel(sale: saleInfoFromServer, syncStatus: true);
              offlineSalesUpdated.add(saleInfoMod);
            }
          }
          AppHelper.hideLoading();
          Get.snackbar("Success", "Data synced successfully");
        } else {
          Get.snackbar("Error", "No response from server");
          AppHelper.hideLoading();
        }
      } else {
        offlineSalesUpdated.add(saleInfo);
      }
    }
    writeSaleInfor(box, offlineSalesUpdated);
  }
  static void writeSaleInfor(GetStorage box, List<SaleInfoModel> itemsList){
    List<Map<String, dynamic>> itemsListMap = itemsList.map((item) =>
        item.toMap()).toList();
    box.write(AppConstants.SALE_LIST, itemsListMap);
  }
  static List<SaleInfoModel> loadSales(GetStorage box) {
    LocalStorageService _localStorageService = LocalStorageService();
    List<SaleInfoModel> sales = _localStorageService.getOfflineList<SaleInfoModel>(
        AppConstants.SALE_LIST,
            (map) => SaleInfoModel.fromMap(map),
        box);
    return sales;
  }

  static Future<SaleModel?> saveSale(SaleModel sale, UserModel user, GetStorage box) async{
    String jsonSaleItems = sale.toJson();
    var response = await BaseHttpClient().postAuthWithCompanyHeader("/sale/save", jsonSaleItems, user.companyId!).catchError((onError){
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

  static Future<void>  syncTickets(UserModel user, GetStorage box, String companyId, String branchId) async{
    LocalStorageService _localStorageService = LocalStorageService();
    print("Getting tickets...");
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
    }
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
    List<ShiftModel> upToDateItems = [];
    List<ShiftModel> updateItems = [];
    print("Syncing shifts " + shiftInfo.length.toString());

    for (ShiftModel sh in shiftInfo) {
      print("Currencies " + sh.shiftCurrencyAmounts!.length.toString());
      print(sh.toJson());
      if (!sh.synced! && sh.isShiftClosed!) {
        itemsToBeSynced.add(sh);
      } else {
        upToDateItems.add(sh);
      }
    }
    String jsonShiftItems = json.encode(
        itemsToBeSynced.map((shift) => shift.toMap()).toList());
    var response = await BaseHttpClient()
        .postAuthWithCompanyHeader(
        "/mobile/pos/shift/save", jsonShiftItems, user.companyId!)
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
      List<Map<String, dynamic>> itemsListMap = updateItems.map((item) =>
          item.toMap()).toList();
      box.write(AppConstants.SHIFT_LIST, itemsListMap);

      // Get.snackbar("Success", "Shifts synced successfully");
    } else {
      Get.snackbar("Error", "No response from server");

    }
  }
  static List<ShiftModel> loadShiftInfo(GetStorage box) {
    LocalStorageService _localStorageService = LocalStorageService();
    List<ShiftModel> list = _localStorageService.getOfflineList<ShiftModel>(
        AppConstants.SHIFT_LIST,
            (map) => ShiftModel.fromMap(map),
        box);
    return list;
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
        AppHelper.handleError(onError);
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
    uniqueTicketList.sort((a, b) {
      DateTime dateA = a.sale!.timeIniated != null ? dateFormat.parse(a.sale!.timeIniated!) : DateTime(0);
      DateTime dateB = b.sale!.timeIniated != null ? dateFormat.parse(b.sale!.timeIniated!) : DateTime(0);
      return dateB.compareTo(dateA);  // Descending order
    });
   return uniqueTicketList;
  }
}
