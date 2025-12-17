import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:ffi';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:pinput/pinput.dart';
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
import 'package:vimbika_pos_app/src/shared/models/dynamic_query_model.dart';
import 'package:vimbika_pos_app/src/shared/models/payment_received_model.dart';
import 'package:vimbika_pos_app/src/shared/models/payment_type_model.dart';
import 'package:vimbika_pos_app/src/utils/app_helper.dart';
import 'package:vimbika_pos_app/src/features/authentication/model/jwt_request_model.dart';
import 'package:vimbika_pos_app/src/features/authentication/model/jwt_response_model.dart';

import '../features/sale/controller/cart_controller.dart';
import '../services/background_service.dart';
import '../features/sale/model/product_full_info_model.dart';
import '../features/shift/model/currency_amount.dart';
import '../shared/models/branch_model.dart';
import '../shared/models/customer_model.dart';


class SyncService {

  final FocusNode _focusNode = FocusNode();
  
  // Helper function to handle unauthorized errors with token refresh and retry
  static Future<T?> handleUnauthorizedWithRetry<T>(
    Future<T?> Function() operation,
    String operationName,
  ) async {
    try {
      return await operation();
    } catch (onError) {
      if (onError is UnAuthorizedException) {
        print("Unauthorized error in $operationName, attempting to refresh token...");
        bool tokenRefreshed = await refreshAccessToken();
        if (tokenRefreshed) {
          print("Token refreshed, retrying $operationName...");
          try {
            return await operation();
          } catch (retryError) {
            print("Retry failed for $operationName: $retryError");
            AppHelper.showErroDialog(
              title: "Error",
              description: "Failed to complete $operationName after token refresh"
            );
            return null;
          }
        } else {
          AppHelper.showErroDialog(
            title: "Error",
            description: "Unauthorized access. Please login again."
          );
          return null;
        }
      }
      rethrow;
    }
  }
  
  // Refresh access token using stored credentials
  static Future<bool> refreshAccessToken() async {
    GetStorage box = GetStorage();
    var userInfo = box.read(AppConstants.USER_INFO);
    var password = box.read(AppConstants.USER_PASSWORD);
    
    if (userInfo == null || password == null || password.isEmpty) {
      print("Cannot refresh token: Missing user credentials");
      return false;
    }
    
    try {
      UserModel user = UserModel.fromMap(Map<String, dynamic>.from(userInfo));
      // Remove whitespace from username (same as in auth_controller)
      String normalizedUserName = (user.userName ?? "").replaceAll(' ', '').replaceAll('\t', '').replaceAll('\n', '');
      JwtRequestModel jwtRequest = JwtRequestModel(
        userName: normalizedUserName,
        password: password
      );
      var data = jwtRequest.toJson();
      
      var response = await BaseHttpClient().post("/authentication", data).catchError((onError) {
        print("Token refresh failed: $onError");
        return null;
      });
      
      if (response != null) {
        final userResponseModel = JwtResponseModel.fromJson(response);
        box.write(AppConstants.CACHED_ACCESS_TOKEN, userResponseModel.token);
        print("Token refreshed successfully");
        return true;
      }
      return false;
    } catch (e) {
      print("Error refreshing token: $e");
      return false;
    }
  }


  static Future<void>  getCustomers(UserModel user, GetStorage box, String companyId) async{
    var response = await BaseHttpClient().getAuthWithCompanyHeader("/customer/get-all", companyId).catchError((onError){
      if (onError is BadRequestException) {
        var apiError = json.decode(onError.message!);
        AppHelper.showErroDialog(description: apiError["reason"]);
      } else {
        AppHelper.handleError(onError);
      }
    });
    if(response != null) {
      List<dynamic> list = jsonDecode(response);
      if(list !=null && list.isNotEmpty) {
        List<CustomerModel> itemsList =
            List<CustomerModel>.from(list.map((i) => CustomerModel.fromMap(i)));
        // customerList.value = itemsList;
        List<Map<String, dynamic>> itemsListMap =
            itemsList.map((item) => item.toMap()).toList();
        //showSnackBar("Message", "Customers downloaded successfully");
        box.write(AppConstants.CUSTOMER_LIST, itemsListMap);
      }
    }
    AppHelper.hideLoading();
  }

  static Future<void> getBranchStock(GetStorage box,UserModel user) async{

    var selectedBranch = box.read(AppConstants.SELECTED_BRANCH) ?? null;
    //print(selectedBranch);
    if(selectedBranch != null) {
      BranchModel branch = BranchModel.fromMap(selectedBranch);
      if(branch.id != null){
        DynamicQueryModel dynamicQueryModel = DynamicQueryModel();
        dynamicQueryModel.branch = branch;
        var branchData = dynamicQueryModel.toJson();

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
            itemsList.sort((a, b) => b.item!.name!.compareTo(a.item!.name!));
            List<Map<String, dynamic>> itemsListMap = itemsList.map((item) =>
                item.toMap()).toList();
            box.write(AppConstants.BRANCH_PRODUCTS, itemsListMap);
            print("Server customers; ${itemsList.length}");
          } else {
            // AppHelper.hideLoading();
            print("Failed to retrieve products");
          }
        }
      }


  }




  static Future<SaleModel?> saveSale(SaleModel sale, UserModel user, GetStorage box, CompanyModel company) async{
    String jsonSaleItems = sale.toJson();
    print("Company ID ${company.id}");
    if(company.id==null){
      var companyModel = box.read(AppConstants.ACTIVE_COMPANY) ?? {};
      company = CompanyModel.fromMap(Map<String, dynamic>.from(companyModel));
    }
    var response = await BaseHttpClient().postAuthWithCompanyHeader("/sale/save", jsonSaleItems, company.id!, "POST").catchError((onError) async {
      //AppHelper.hideLoading();
      if (onError is BadRequestException) {
        var apiError = json.decode(onError.message!);
        print(apiError);
        AppHelper.showErroDialog(description: apiError["reason"]);
      } else if (onError is UnAuthorizedException) {
        // Try to refresh token and retry
        print("Unauthorized error, attempting to refresh token...");
        bool tokenRefreshed = await refreshAccessToken();
        if (tokenRefreshed) {
          print("Token refreshed, retrying sale save...");
          // Retry the operation - return raw string response, not parsed model
          try {
            var retryResponse = await BaseHttpClient().postAuthWithCompanyHeader("/sale/save", jsonSaleItems, company.id!, "POST");
            return retryResponse; // Return raw string, let the code below parse it
          } catch (retryError) {
            print("Retry failed: $retryError");
            AppHelper.showErroDialog(title: "Error", description: "Failed to sync sale after token refresh");
          }
        } else {
          AppHelper.showErroDialog(title: "Error", description: "Unauthorized access. Please login again.");
        }
      }
      else {
        print(onError);
        AppHelper.handleError(onError);
      }
      return null;
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
  static Future<SaleModel?> reverseSale(SaleModel sale, UserModel user, GetStorage box, CompanyModel company) async{
    String jsonSaleItems = sale.toJson();
    print(jsonSaleItems);
    if(company.id==null){
      var companyModel = box.read(AppConstants.ACTIVE_COMPANY) ?? {};
      company = CompanyModel.fromMap(Map<String, dynamic>.from(companyModel));
    }
    var response = await BaseHttpClient().postAuthWithCompanyHeader("/sale/reverse", jsonSaleItems, company.id!, "POST").catchError((onError) async {
      //AppHelper.hideLoading();
      if (onError is BadRequestException) {
        var apiError = json.decode(onError.message!);
        print(apiError);
        AppHelper.showErroDialog(description: apiError["reason"]);
      } else if (onError is UnAuthorizedException) {
        // Try to refresh token and retry
        print("Unauthorized error, attempting to refresh token...");
        bool tokenRefreshed = await refreshAccessToken();
        if (tokenRefreshed) {
          print("Token refreshed, retrying sale reverse...");
          try {
            var retryResponse = await BaseHttpClient().postAuthWithCompanyHeader("/sale/reverse", jsonSaleItems, company.id!, "POST");
            return retryResponse; // Return raw string, let the code below parse it
          } catch (retryError) {
            print("Retry failed: $retryError");
            AppHelper.showErroDialog(title: "Error", description: "Failed to reverse sale after token refresh");
          }
        } else {
          AppHelper.showErroDialog(title: "Error", description: "Unauthorized access. Please login again.");
        }
      }
      else {
        print(onError);
        AppHelper.handleError(onError);
      }
      return null;
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

    var response = await BaseHttpClient().postAuthWithCompanyHeader(url, jsonSaleItems, user.companyId!, method).catchError((onError) async {
      //AppHelper.hideLoading();
      if (onError is BadRequestException) {
        var apiError = json.decode(onError.message!);
        print(apiError);
        AppHelper.showErroDialog(description: apiError["reason"]);
      } else if (onError is UnAuthorizedException) {
        // Try to refresh token and retry
        print("Unauthorized error, attempting to refresh token...");
        bool tokenRefreshed = await refreshAccessToken();
        if (tokenRefreshed) {
          print("Token refreshed, retrying stock request save...");
          try {
            var retryResponse = await BaseHttpClient().postAuthWithCompanyHeader(url, jsonSaleItems, user.companyId!, method);
            return retryResponse; // Return raw string, let the code below parse it
          } catch (retryError) {
            print("Retry failed: $retryError");
            AppHelper.showErroDialog(title: "Error", description: "Failed to save stock request after token refresh");
          }
        } else {
          AppHelper.showErroDialog(title: "Error", description: "Unauthorized access. Please login again.");
        }
      }
      else {
        print(onError);
        AppHelper.handleError(onError);
      }
      return null;
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
    String jsonSaleItems = transfer.toJson();
    log(jsonSaleItems);
    var response = await BaseHttpClient().postAuthWithCompanyHeader("/transfer-history/transfer", jsonSaleItems, user.companyId!, "POST").catchError((onError) async {
      //AppHelper.hideLoading();
      if (onError is BadRequestException) {
        var apiError = json.decode(onError.message!);
        print(apiError);
        AppHelper.showErroDialog(description: apiError["reason"]);
      } else if (onError is UnAuthorizedException) {
        // Try to refresh token and retry
        print("Unauthorized error, attempting to refresh token...");
        bool tokenRefreshed = await refreshAccessToken();
        if (tokenRefreshed) {
          print("Token refreshed, retrying transfer save...");
          try {
            var retryResponse = await BaseHttpClient().postAuthWithCompanyHeader("/transfer-history/transfer", jsonSaleItems, user.companyId!, "POST");
            return retryResponse; // Return raw string, let the code below parse it
          } catch (retryError) {
            print("Retry failed: $retryError");
            AppHelper.showErroDialog(title: "Error", description: "Failed to save transfer after token refresh");
          }
        } else {
          AppHelper.showErroDialog(title: "Error", description: "Unauthorized access. Please login again.");
        }
      }
      else {
        print(onError);
        AppHelper.handleError(onError);
      }
      return null;
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
    // Load all customers
    List<CustomerModel> allCustomers = _localStorageService.getOfflineList<CustomerModel>(
        AppConstants.CUSTOMER_LIST,
        (map) => CustomerModel.fromMap(map),
        box);

    // Work on pending (new or updated)
    List<CustomerModel> pending = allCustomers.where((customer) => customer.id == null || (customer.updated ?? false)).toList();

    // Helper to generate a stable key
    String keyFor(CustomerModel c) {
      if (c.id != null && c.id!.isNotEmpty) return "id:${c.id}";
      if (c.customerId != null && c.customerId!.isNotEmpty) return "cid:${c.customerId}";
      if (c.accountNumber != null && c.accountNumber!.isNotEmpty) return "acc:${c.accountNumber}";
      final branchKey = c.branch?.id ?? c.branch?.name ?? '';
      return "name:${c.name}|branch:$branchKey";
    }

    // Start merged map with all existing customers
    Map<String, CustomerModel> merged = {
      for (final c in allCustomers) keyFor(c): c
    };

    for(CustomerModel customerModel in pending) {
      var url = "";
      var method = "";
      final String oldKey = keyFor(customerModel);
      if((customerModel.updated ?? false) && customerModel.id != null) {
        url = "/customer/update";
        method ="PUT";
      } else {
        url = "/customer/save";
        method ="POST";
      }
      String jsonSaleItems = customerModel.toJson();
      var response = await BaseHttpClient()
          .postAuthWithCompanyHeader(url,
              jsonSaleItems, user.companyId!, method)
          .catchError((onError) async {
        //AppHelper.hideLoading();
        if (onError is BadRequestException) {
          var apiError = json.decode(onError.message!);
          print(apiError);
          AppHelper.showErroDialog(description: apiError["reason"]);
        } else if (onError is UnAuthorizedException) {
          // Try to refresh token and retry
          print("Unauthorized error, attempting to refresh token...");
          bool tokenRefreshed = await refreshAccessToken();
          if (tokenRefreshed) {
            print("Token refreshed, retrying customer save...");
            try {
              var retryResponse = await BaseHttpClient().postAuthWithCompanyHeader(url, jsonSaleItems, user.companyId!, method);
              return retryResponse;
            } catch (retryError) {
              print("Retry failed: $retryError");
              AppHelper.showErroDialog(title: "Error", description: "Failed to save customer after token refresh");
            }
          } else {
            AppHelper.showErroDialog(title: "Error", description: "Unauthorized access. Please login again.");
          }
        } else {
          print(onError);
          AppHelper.handleError(onError);
        }
        return null;
      });
      // AppHelper.hideLoading();
      if (response != null) {
        CustomerResponseModel responseModel =
        CustomerResponseModel.fromJson(response);
        if (responseModel.item != null) {
          // Mark as synced
          responseModel.item!.updated = false;
          final String newKey = keyFor(responseModel.item!);
          // Remove the old pending key to prevent duplicates, then upsert the new one
          merged.remove(oldKey);
          merged[newKey] = responseModel.item!;
        }
      } else {
        //failed to save sale
        return null;
      }
    }
    // Write merged customers back to storage (deduped)
    List<Map<String, dynamic>> itemsListMap = merged.values.map((item) =>
        item.toMap()).toList();
    box.write(AppConstants.CUSTOMER_LIST, itemsListMap);
    return null;
  }

  static Future<PaymentReceivedModel?> savePaymentReceived( UserModel user, GetStorage box) async{
    final LocalStorageService _localStorageService = LocalStorageService();
    List<PaymentReceivedModel> savedPayments = [];
    List<PaymentReceivedModel> payments = _localStorageService.getOfflineList<PaymentReceivedModel>(
        AppConstants.PAYMENT_RECEIVED_LIST,
            (map) => PaymentReceivedModel.fromMap(map),
        box);
    payments = payments.where((payment) => payment.id == null).toList();
    for(PaymentReceivedModel paymentsModel in payments) {
      String jsonSaleItems = paymentsModel.toJson();
      var response = await BaseHttpClient()
          .postAuthWithCompanyHeader("/payments/received/receive-payment",
              jsonSaleItems, user.companyId!, "POST")
          .catchError((onError) async {
        //AppHelper.hideLoading();
        if (onError is BadRequestException) {
          var apiError = json.decode(onError.message!);
          print(apiError);
          AppHelper.showErroDialog(description: apiError["reason"]);
        } else if (onError is UnAuthorizedException) {
          // Try to refresh token and retry
          print("Unauthorized error, attempting to refresh token...");
          bool tokenRefreshed = await refreshAccessToken();
          if (tokenRefreshed) {
            print("Token refreshed, retrying payment received save...");
            try {
              var retryResponse = await BaseHttpClient().postAuthWithCompanyHeader("/payments/received/receive-payment", jsonSaleItems, user.companyId!, "POST");
              return retryResponse;
            } catch (retryError) {
              print("Retry failed: $retryError");
              AppHelper.showErroDialog(title: "Error", description: "Failed to save payment after token refresh");
            }
          } else {
            AppHelper.showErroDialog(title: "Error", description: "Unauthorized access. Please login again.");
          }
        } else {
          print(onError);
          AppHelper.handleError(onError);
        }
        return null;
      });
      // AppHelper.hideLoading();
      if (response != null) {
        savedPayments.add(paymentsModel);
        // return responseModel.item;
      } else {
        //failed to save sale
        return null;
      }
    }
    payments.removeWhere((payment)=> savedPayments.contains(payment));
    List<Map<String, dynamic>> itemsListMap = payments.map((item) =>
        item.toMap()).toList();
    box.write(AppConstants.PAYMENT_RECEIVED_LIST, itemsListMap);
    return null;
  }


  static Future<List<SaleInfoModel>?>  syncTickets(UserModel user, GetStorage box, String companyId, String branchId) async{
    LocalStorageService _localStorageService = LocalStorageService();
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
    // Always reload user to ensure we have the current logged-in user
    // This is critical when a user logs in after another user has logged out
    var model = box.read(AppConstants.USER_INFO) ?? {};
    if(model.isNotEmpty){
      user = UserModel.fromMap(Map<String, dynamic>.from(model));
      print("Sync Offline Shifts: Loaded user ${user.userName} with ID ${user.id}");
    } else if(user.id.isNullOrBlank!){
      print("Sync Offline Shifts: User is null and no USER_INFO found");
      return; // Cannot sync without user info
    }
    
    List<ShiftModel> shiftInfo = loadShiftInfo(box);
    RxList itemsToBeSynced = [].obs;
    List<ShiftModel> upToDateItems = [];
    List<ShiftModel> updateItems = [];
    List<CurrencyAmount> updateCurrencyItems = [];

    for (ShiftModel sh in shiftInfo) {
      // Only process shifts that belong to the current user
      if (sh.userId == null || user.id == null || sh.userId != user.id) {
        continue; // Skip shifts that don't belong to current user
      }
      
      // Null-safe checks for stopSync and isShiftClosed
      bool stopSync = sh.stopSync ?? false;
      bool isShiftClosed = sh.isShiftClosed ?? false;
      
      // Log shift details for debugging
      print("Sync Offline Shifts: Checking shift ${sh.shiftReference}: isShiftClosed=$isShiftClosed, stopSync=$stopSync, id=${sh.id}");
      
      // Original flow from commit 3efe079
      if (!stopSync && !isShiftClosed) {
        // Open shift that needs syncing
        if (sh.shiftCurrencyAmounts != null && sh.shiftCurrencyAmounts!.isNotEmpty) {
          if(sh.shiftCurrencyAmounts!.any((currencyAMount)=>currencyAMount.id==null)){
           updateCurrencyItems = await syncShiftsWithNullID(sh.shiftCurrencyAmounts!,user);
          }
          updateCurrencyItems.forEach((element) {
            var index = sh.shiftCurrencyAmounts!.indexWhere((test)=>test.ref==element.ref);
            print("index: $index");
            if(index!= -1){
              sh.shiftCurrencyAmounts![index] = element;
            }
          });
        }
        itemsToBeSynced.add(sh);
        itemsToBeSynced.refresh();
      } else {
        // For closed shifts: Ensure stopSync=false before syncing, then set to true after successful sync
        if(isShiftClosed) {
          if (!stopSync) {
            // Closed shift with stopSync=false - ensure it's false and add to sync list
            sh.stopSync = false;
            print("Sync Offline Shifts: Ensuring stopSync=false for closed shift ${sh.shiftReference} before syncing");
            itemsToBeSynced.add(sh);
          } else {
            // Closed shift with stopSync=true - already synced, skip
            print("Sync Offline Shifts: Skipping closed shift ${sh.shiftReference} (already synced, stopSync=true, id=${sh.id})");
            upToDateItems.add(sh);
          }
        } else {
          // Open shift with stopSync=true - add to upToDateItems
          upToDateItems.add(sh);
        }
      }
    }
/*    print("currencyItemsToBeSynced: ${currencyItemsToBeSynced.isNotEmpty} " );
    if(currencyItemsToBeSynced.isNotEmpty) {
      String jsonShiftCurrencyItems = json.encode(
          currencyItemsToBeSynced.map((shift) => shift.toMap()).toList());
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
    }*/

  /*  for (ShiftModel sh in itemsToBeSynced) {
      if (sh.shiftCurrencyAmounts != null && sh.shiftCurrencyAmounts!.isNotEmpty) {
        for (CurrencyAmount ca in updateCurrencyItems) {
          if(ca.shiftReference == sh.shiftReference){
            sh.shiftCurrencyAmounts?.remove(sh.shiftCurrencyAmounts?.firstWhere((element) => element.ref==ca.ref));
            sh.shiftCurrencyAmounts?.add(ca);
          }
        }
      }
    }*/

    if(itemsToBeSynced.isNotEmpty) {
      print("Sync Offline Shifts: Attempting to sync ${itemsToBeSynced.length} shift(s)");
      for (ShiftModel sh in itemsToBeSynced) {
        print("  - Shift ${sh.shiftReference}: isShiftClosed=${sh.isShiftClosed}, stopSync=${sh.stopSync}, id=${sh.id}");
      }
      
      // CRITICAL: Preserve local opening times for newly created shifts before syncing
      // This prevents server from overwriting the correct opening time with an old one
      Map<String, String> localOpeningTimes = {};
      
      // Validate shifts before sending - ensure required fields are present
      // Create copies to avoid modifying the original objects in itemsToBeSynced
      List<ShiftModel> validShiftsToSync = [];
      for (ShiftModel localShift in itemsToBeSynced) {
        // Validate required fields
        if (localShift.shiftReference == null || localShift.shiftReference!.isEmpty) {
          print("Sync Offline Shifts: WARNING - Skipping shift with null/empty shiftReference");
          continue;
        }
        if (localShift.company == null) {
          print("Sync Offline Shifts: WARNING - Skipping shift ${localShift.shiftReference} with null company");
          continue;
        }
        if (localShift.userId == null || localShift.userId!.isEmpty) {
          print("Sync Offline Shifts: WARNING - Skipping shift ${localShift.shiftReference} with null/empty userId");
          continue;
        }
        
        // Filter currency amounts to only include OPENING_AMOUNT
        // SALE amounts should be synced separately via the currency amounts endpoint
        // The server rejects shifts with SALE amounts that have id=null
        List<CurrencyAmount> openingAmounts = [];
        if (localShift.shiftCurrencyAmounts != null) {
          openingAmounts = localShift.shiftCurrencyAmounts!
              .where((ca) => ca.amountType == "OPENING_AMOUNT")
              .toList();
          int filteredOut = localShift.shiftCurrencyAmounts!.length - openingAmounts.length;
          if (filteredOut > 0) {
            print("Sync Offline Shifts: Filtered out $filteredOut SALE currency amount(s) from shift ${localShift.shiftReference} (keeping ${openingAmounts.length} OPENING_AMOUNT)");
          }
        }
        
        // Set default values for required fields if they're null
        DateTime now = DateTime.now();
        String? dateCreated = localShift.dateCreated;
        if (dateCreated == null || dateCreated.isEmpty) {
          dateCreated = DateFormat('yyyy-MM-dd').format(now);
        }
        
        String? createdByName = localShift.createdByName;
        if (createdByName == null || createdByName.isEmpty) {
          // Use userName or construct from firstName and lastName
          createdByName = user.userName ?? 
            (user.firstName != null && user.lastName != null 
              ? "${user.firstName} ${user.lastName}" 
              : "");
        }
        
        // Create a copy of the shift to avoid modifying the original
        // CRITICAL: For closed shifts, ensure active=false
        bool shiftActive = localShift.active ?? true;
        if (localShift.isShiftClosed == true) {
          shiftActive = false; // Closed shifts must have active=false
        }
        
        ShiftModel shiftCopy = ShiftModel(
          id: localShift.id,
          userId: localShift.userId,
          isShiftClosed: localShift.isShiftClosed ?? false,
          userFullName: localShift.userFullName ?? "",
          shiftCurrencyAmounts: openingAmounts, // Only include OPENING_AMOUNT
          company: localShift.company,
          openingTime: localShift.openingTime,
          closingTime: localShift.closingTime,
          shiftReference: localShift.shiftReference,
          synced: localShift.synced ?? false,
          stopSync: localShift.stopSync ?? false,
          kotNumber: localShift.kotNumber ?? 0,
          createdByName: createdByName, // Set default if null
          dateCreated: dateCreated, // Set default if null
          active: shiftActive, // false for closed shifts, true for open shifts
        );
        
        if (shiftCopy.shiftReference != null && shiftCopy.openingTime != null) {
          // Store opening time for shifts that are being synced (newly created or updated)
          // This ensures we preserve the correct opening time even if server returns an old one
          localOpeningTimes[shiftCopy.shiftReference!] = shiftCopy.openingTime!;
          print("Preserving local opening time for shift ${shiftCopy.shiftReference}: ${shiftCopy.openingTime}");
        }
        
        validShiftsToSync.add(shiftCopy);
      }
      
      if (validShiftsToSync.isEmpty) {
        print("Sync Offline Shifts: No valid shifts to sync after validation");
        return;
      }
      
      // Log the shift data being sent for debugging
      for (ShiftModel shift in validShiftsToSync) {
        Map<String, dynamic> shiftMap = shift.toMap();
        print("Sync Offline Shifts: Shift ${shift.shiftReference} data: id=${shiftMap['id']}, isShiftClosed=${shiftMap['isShiftClosed']}, stopSync=${shiftMap['stopSync']}, company=${shiftMap['company'] != null ? 'present' : 'null'}, currencyAmounts=${shift.shiftCurrencyAmounts?.length ?? 0}");
      }
      
      // Sync all shifts together (as originally designed)
      // The server expects an array of shifts
      String jsonShiftItems = json.encode(
          validShiftsToSync.map((shift) => shift.toMap()).toList());
      print("Sync Offline Shifts: Sending POST to /mobile/pos/shift/save with ${validShiftsToSync.length} shift(s) (${itemsToBeSynced.length - validShiftsToSync.length} filtered out due to validation)");
      print("Sync Offline Shifts: JSON payload length: ${jsonShiftItems.length} characters");
      
      // Log first 1000 chars of JSON for debugging
      if (jsonShiftItems.length > 1000) {
        print("Sync Offline Shifts: JSON preview: ${jsonShiftItems.substring(0, 1000)}...");
      } else {
        print("Sync Offline Shifts: JSON payload: $jsonShiftItems");
      }
      
      var response = await BaseHttpClient()
          .postAuthWithCompanyHeader(
          "/mobile/pos/shift/save", jsonShiftItems, user.companyId!, "POST")
          .catchError((onError) {
        print("Sync Offline Shifts: Error syncing shifts: $onError");
        if (onError is BadRequestException) {
          try {
            var apiError = json.decode(onError.message!);
            print("Sync Offline Shifts: Server error details: ${apiError.toString()}");
            // Try to get more details if available
            if (apiError.containsKey("message") && apiError["message"] != null && apiError["message"].toString().isNotEmpty) {
              print("Sync Offline Shifts: Server error message: ${apiError["message"]}");
            }
          } catch (e) {
            print("Sync Offline Shifts: Could not parse error message: $e");
            print("Sync Offline Shifts: Raw error message: ${onError.message}");
          }
        }
        AppHelper.hideLoading();
      });
      if (response != null) {
        print("Sync Offline Shifts: Received response from server");
        ShiftResponseModel saleResponseModel = ShiftResponseModel.fromJson(
            response);
        
        print("Sync Offline Shifts: Server returned ${saleResponseModel.items?.length ?? 0} shift(s)");
        
        // Preserve local opening times for shifts that were just created/updated
        for (ShiftModel serverShift in saleResponseModel.items ?? []) {
          if (serverShift.shiftReference != null && 
              localOpeningTimes.containsKey(serverShift.shiftReference)) {
            // Use the local opening time instead of server's (which might be from an old shift)
            String preservedOpeningTime = localOpeningTimes[serverShift.shiftReference!]!;
            serverShift.openingTime = preservedOpeningTime;
            print("Preserved local opening time ${preservedOpeningTime} for shift ${serverShift.shiftReference} (server had: ${serverShift.openingTime})");
          }
          // Log detailed information about synced shift for debugging
          print("  - Synced shift ${serverShift.shiftReference}: id=${serverShift.id}, isShiftClosed=${serverShift.isShiftClosed}, active=${serverShift.active}, openingTime=${serverShift.openingTime}, closingTime=${serverShift.closingTime}, userId=${serverShift.userId}, company=${serverShift.company?.name ?? 'null'}");
          
          // For closed shifts, verify all required fields are present
          if (serverShift.isShiftClosed == true) {
            List<String> missingFields = [];
            if (serverShift.id == null || serverShift.id!.isEmpty) missingFields.add("id");
            if (serverShift.openingTime == null || serverShift.openingTime!.isEmpty) missingFields.add("openingTime");
            if (serverShift.closingTime == null || serverShift.closingTime!.isEmpty) missingFields.add("closingTime");
            if (serverShift.userId == null || serverShift.userId!.isEmpty) missingFields.add("userId");
            if (serverShift.company == null) missingFields.add("company");
            
            if (missingFields.isNotEmpty) {
              print("  WARNING: Closed shift ${serverShift.shiftReference} is missing required fields: ${missingFields.join(', ')}");
            } else {
              print("  ✓ Closed shift ${serverShift.shiftReference} has all required fields");
            }
          }
        }
        
        // After successful sync: Set stopSync=true for closed shifts
        // This marks them as successfully synced so they won't be retried
        // CRITICAL: The server response might not include stopSync, so we must set it explicitly
        for (ShiftModel syncedShift in saleResponseModel.items ?? []) {
          if (syncedShift.isShiftClosed == true) {
            // Set stopSync=true after successful sync
            // This ensures closed shifts are marked as synced and won't be retried
            syncedShift.stopSync = true;
            print("Sync Offline Shifts: Set stopSync=true for closed shift ${syncedShift.shiftReference} after successful sync (id=${syncedShift.id})");
            
            // Also update in itemsToBeSynced for consistency (though we use syncedShift when saving)
            int index = itemsToBeSynced.indexWhere((s) => s.shiftReference == syncedShift.shiftReference);
            if (index != -1) {
              itemsToBeSynced[index].stopSync = true;
              print("Sync Offline Shifts: Updated stopSync=true in itemsToBeSynced for ${syncedShift.shiftReference}");
            }
          } else {
            // For open shifts, ensure stopSync is false (they should continue syncing)
            if (syncedShift.stopSync == true) {
              syncedShift.stopSync = false;
              print("Sync Offline Shifts: Reset stopSync=false for open shift ${syncedShift.shiftReference} (open shifts should continue syncing)");
            }
          }
        }
        
        // CRITICAL: Start with ALL shifts from storage (including other users' shifts)
        // Then update only the ones we synced
        List<ShiftModel> allShifts = List.from(shiftInfo);
        List<String> syncedShiftReferences = (saleResponseModel.items ?? [])
            .map((s) => s.shiftReference ?? "")
            .where((ref) => ref.isNotEmpty)
            .toList();
        
        // Update or add synced shifts
        // CRITICAL: Use the synced shift objects which have stopSync=true set for closed shifts
        for (ShiftModel syncedShift in saleResponseModel.items ?? []) {
          int index = allShifts.indexWhere((s) => s.shiftReference == syncedShift.shiftReference);
          if (index != -1) {
            // Update existing shift with synced version
            // The syncedShift object already has stopSync=true for closed shifts (set above)
            allShifts[index] = syncedShift;
            print("Sync Offline Shifts: Updated existing shift ${syncedShift.shiftReference} with synced version (id=${syncedShift.id}, isShiftClosed=${syncedShift.isShiftClosed}, stopSync=${syncedShift.stopSync}, active=${syncedShift.active}, openingTime=${syncedShift.openingTime}, closingTime=${syncedShift.closingTime})");
            
            // For closed shifts, log full details to help debug backend visibility issues
            if (syncedShift.isShiftClosed == true) {
              print("Sync Offline Shifts: CLOSED SHIFT DETAILS - ${syncedShift.shiftReference}: id=${syncedShift.id}, userId=${syncedShift.userId}, company=${syncedShift.company?.name ?? 'null'}, openingTime=${syncedShift.openingTime}, closingTime=${syncedShift.closingTime}, active=${syncedShift.active}, dateCreated=${syncedShift.dateCreated}, createdByName=${syncedShift.createdByName}");
            }
          } else {
            // Add new synced shift (shouldn't happen, but handle it)
            allShifts.add(syncedShift);
            print("Sync Offline Shifts: Added new synced shift ${syncedShift.shiftReference} (id=${syncedShift.id}, isShiftClosed=${syncedShift.isShiftClosed}, stopSync=${syncedShift.stopSync})");
          }
        }
        
        // Add upToDateItems that weren't just synced (these are shifts that didn't need syncing)
        // CRITICAL: Don't overwrite shifts that were just synced - they already have the correct stopSync values
        for (ShiftModel upToDateShift in upToDateItems) {
          // Only add if this shift wasn't just synced and doesn't already exist
          if (upToDateShift.shiftReference != null && 
              !syncedShiftReferences.contains(upToDateShift.shiftReference!)) {
            int index = allShifts.indexWhere((s) => s.shiftReference == upToDateShift.shiftReference);
            if (index == -1) {
              // Shift doesn't exist, add it
              allShifts.add(upToDateShift);
              print("Sync Offline Shifts: Added upToDateItem ${upToDateShift.shiftReference} (wasn't in allShifts)");
            } else {
              // Shift exists in allShifts - check if it was synced in a previous run
              // If the existing shift has an ID and stopSync=true (for closed), keep it (it was synced before)
              // If the existing shift has no ID or stopSync=false, it might need syncing, but we're not syncing it now
              ShiftModel existingShift = allShifts[index];
              if (existingShift.id != null && existingShift.isShiftClosed == true && existingShift.stopSync == true) {
                // This shift was already synced in a previous run - keep the synced version
                print("Sync Offline Shifts: Keeping existing synced shift ${upToDateShift.shiftReference} (id=${existingShift.id}, stopSync=${existingShift.stopSync}) - not overwriting with upToDateItem");
              } else {
                // Shift exists but might not be fully synced - keep existing version (might be from another user or partial sync)
                print("Sync Offline Shifts: Keeping existing shift ${upToDateShift.shiftReference} (id=${existingShift.id}, isShiftClosed=${existingShift.isShiftClosed}, stopSync=${existingShift.stopSync}) - not synced in this run");
              }
            }
          } else if (upToDateShift.shiftReference != null && 
                     syncedShiftReferences.contains(upToDateShift.shiftReference!)) {
            print("Sync Offline Shifts: Skipping upToDateItem ${upToDateShift.shiftReference} (was just synced, using synced version instead)");
          }
        }

        // Verify stopSync values before saving
        for (String ref in syncedShiftReferences) {
          ShiftModel? savedShift = allShifts.firstWhereOrNull((s) => s.shiftReference == ref);
          if (savedShift != null) {
            print("Sync Offline Shifts: VERIFY - Shift $ref in final list: id=${savedShift.id}, isShiftClosed=${savedShift.isShiftClosed}, stopSync=${savedShift.stopSync}");
          }
        }
        
        List<Map<String, dynamic>> itemsListMap = allShifts.map((item) =>
            item.toMap()).toList();
        box.write(AppConstants.SHIFT_LIST, itemsListMap);
        print("Sync Offline Shifts: Successfully synced and saved ${saleResponseModel.items?.length ?? 0} shift(s) to storage (total ${allShifts.length} shifts in storage, including other users)");
        
        // Verify stopSync was persisted correctly by reloading from storage
        List<ShiftModel> verifyShifts = loadShiftInfo(box);
        for (String ref in syncedShiftReferences) {
          ShiftModel? verifiedShift = verifyShifts.firstWhereOrNull((s) => s.shiftReference == ref);
          if (verifiedShift != null) {
            print("Sync Offline Shifts: VERIFY PERSISTED - Shift $ref after reload: id=${verifiedShift.id}, isShiftClosed=${verifiedShift.isShiftClosed}, stopSync=${verifiedShift.stopSync}");
          } else {
            print("Sync Offline Shifts: WARNING - Shift $ref not found in storage after save!");
          }
        }

        // After successfully syncing shifts, check if there are unsynced sales
        // This is especially important for closed shifts that were closed offline
        // The sales need to sync after the shift is synced so they can be properly associated
        try {
          List<SaleInfoModel> allSales = LocalStorageService().getOfflineList<SaleInfoModel>(
            AppConstants.SALE_LIST,
            (map) => SaleInfoModel.fromMap(map),
            box
          );
          List<SaleInfoModel> unsyncedSales = allSales.where((sale) => sale.syncStatus == false).toList();
          
          // Check if any of the synced shifts were closed and have unsynced sales
          bool hasClosedShiftWithUnsyncedSales = false;
          for (ShiftModel syncedShift in saleResponseModel.items ?? []) {
            if (syncedShift.isShiftClosed == true) {
              // Check if this closed shift has unsynced sales
              bool shiftHasUnsyncedSales = unsyncedSales.any((sale) => 
                sale.sale?.shiftReference == syncedShift.shiftReference
              );
              if (shiftHasUnsyncedSales) {
                hasClosedShiftWithUnsyncedSales = true;
                print("Sync Offline Shifts: Closed shift ${syncedShift.shiftReference} has unsynced sales, triggering sales sync");
                break;
              }
            }
          }
          
          // If there are unsynced sales (especially from closed shifts), trigger sales sync
          if (unsyncedSales.isNotEmpty && hasClosedShiftWithUnsyncedSales) {
            print("Sync Offline Shifts: Triggering sales sync for ${unsyncedSales.length} unsynced sale(s) after shift sync");
            await BackgroundService().syncOfflineSales(false);
            print("Sync Offline Shifts: Sales sync completed after shift sync");
          }
        } catch (e) {
          print("Sync Offline Shifts: Error checking/triggering sales sync: $e");
          // Don't fail the shift sync if sales sync check fails
        }

        // Get.snackbar("Success", "Shifts synced successfully");
      } else {
        // Sync failed - DON'T set stopSync=true for closed shifts
        // We only set stopSync=true after successful sync
        // This ensures closed shifts with stopSync=false will retry on next sync
        print("Sync Offline Shifts: Sync failed - NOT setting stopSync=true for closed shifts (they will retry on next sync)");
        
        // Persist the current state - shifts in itemsToBeSynced should have stopSync=false
        // so they will retry on next sync
        List<ShiftModel> allShifts = List.from(shiftInfo);
        
        // Update shifts from itemsToBeSynced to ensure stopSync=false is preserved
        for (ShiftModel failedShift in itemsToBeSynced) {
          int index = allShifts.indexWhere((s) => s.shiftReference == failedShift.shiftReference);
          if (index != -1) {
            // Ensure stopSync=false is preserved for failed syncs
            allShifts[index].stopSync = false;
            print("Sync Offline Shifts: Preserved stopSync=false for failed shift ${failedShift.shiftReference} (will retry)");
          }
        }
        
        // Also add upToDateItems back
        for (ShiftModel upToDateShift in upToDateItems) {
          int index = allShifts.indexWhere((s) => s.shiftReference == upToDateShift.shiftReference);
          if (index == -1) {
            allShifts.add(upToDateShift);
          } else {
            allShifts[index] = upToDateShift;
          }
        }
        
        List<Map<String, dynamic>> itemsListMap = allShifts.map((item) =>
            item.toMap()).toList();
        box.write(AppConstants.SHIFT_LIST, itemsListMap);
        print("Sync Offline Shifts: Sync failed - persisted current shift state (stopSync unchanged, shifts will retry on next sync)");
        //Get.snackbar("Error", "No response from server");

      }
    } else {
      // No shifts to sync, but ensure all shifts are persisted
      List<ShiftModel> allShifts = List.from(shiftInfo);
      List<Map<String, dynamic>> itemsListMap = allShifts.map((item) =>
          item.toMap()).toList();
      box.write(AppConstants.SHIFT_LIST, itemsListMap);
    }
  }

  static Future<List<CurrencyAmount>> syncShiftsWithNullID(List<CurrencyAmount> currencyAmountsWithNullId, UserModel user,) async {
    List<CurrencyAmount> updateCurrencyItems = [];
    if(currencyAmountsWithNullId.isNotEmpty) {
      String jsonShiftCurrencyItems = json.encode(
          currencyAmountsWithNullId.map((shift) => shift.toMap()).toList());
      var shiftCurrencyResponse = await BaseHttpClient()
          .postAuthWithCompanyHeader("/mobile/pos/shift/save-currency-amounts",
          jsonShiftCurrencyItems, user.companyId!, "POST")
          .catchError((onError) async {
        print(onError);
        AppHelper.hideLoading();
        if (onError is BadRequestException) {
          var apiError = json.decode(onError.message!);
          AppHelper.showErroDialog(description: apiError["reason"]);
        } else if (onError is UnAuthorizedException) {
          // Try to refresh token and retry
          print("Unauthorized error, attempting to refresh token...");
          bool tokenRefreshed = await refreshAccessToken();
          if (tokenRefreshed) {
            print("Token refreshed, retrying currency amounts save...");
            try {
              var retryResponse = await BaseHttpClient().postAuthWithCompanyHeader("/mobile/pos/shift/save-currency-amounts", jsonShiftCurrencyItems, user.companyId!, "POST");
              return retryResponse;
            } catch (retryError) {
              print("Retry failed: $retryError");
              AppHelper.showErroDialog(title: "Error", description: "Failed to save currency amounts after token refresh");
            }
          } else {
            AppHelper.showErroDialog(title: "Error", description: "Unauthorized access. Please login again.");
          }
        } else {
          AppHelper.handleError(onError);
        }
        return null;
      });
      if (shiftCurrencyResponse != null) {
        ShiftCurrencyResponseModel saleResponseModel =
        ShiftCurrencyResponseModel.fromJson(shiftCurrencyResponse);
        updateCurrencyItems.addAll(saleResponseModel.items ?? []);
      }
    }
    return updateCurrencyItems;
  }


  Future<bool> showAuthenticationDialog(BuildContext context) async {
    final TextEditingController _pinController = TextEditingController();
    bool userExists = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Enter Admin PIN'),
          content: Pinput(
            length: 4, // Specify the length of the PIN
            useNativeKeyboard: true,
            obscureText: true,
            controller: _pinController,
            keyboardType: TextInputType.number,
            focusNode: _focusNode,
            closeKeyboardWhenCompleted: true,
            onCompleted: (pin) {
              // Handle the completed PIN input

              List<UserModel> tempUserList = loadUsers();
               userExists = tempUserList.any((element) => element.pin == pin && element.userRoles!.any((role) => role.name == "ROLE_SUPER_ADMIN" || role.name == "ROLE_MANAGER"));
              if(userExists) {
                Navigator.of(dialogContext).pop(); // Close the dialog
                // _focusNode.dispose();
              }
              else {
                _pinController.clear();
                Get.snackbar("Error", "Invalid PIN or user does not have required role",
                    colorText: Colors.red,
                    icon: Icon(Icons.error, color: Colors.red),
                    backgroundColor: Colors.white70);
              }
            },
            // Customize the appearance of the Pinput fields
            defaultPinTheme: PinTheme(
              width: 80,
              height: 56,
              textStyle: const TextStyle(fontSize: 20, color: Colors.black),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
    return userExists;
  }


  List<UserModel> loadUsers() {
    GetStorage box = GetStorage();
    // Rx<UserModel?> user = UserModel(firstName: "", lastName: "", userName: "").obs;
    LocalStorageService _localStorageService = LocalStorageService();
    List<UserModel> list = _localStorageService.getOfflineList<UserModel>(
        AppConstants.USER_LIST, (map) => UserModel.fromMap(map), box);
    // list.add(user.value!);
    return list;
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
        print("shift found");
        print(shiftResponseModel.item!.shiftCurrencyAmounts!.length);
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
      itemsList = itemsList.where((pt)=>pt.isEnabled!).toList();
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
