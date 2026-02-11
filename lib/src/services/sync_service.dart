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

import '../constants/app_routes.dart';
import '../features/sale/controller/cart_controller.dart';
import '../features/sale/controller/sale_controller.dart';
import '../services/background_service.dart';
import '../features/sale/model/product_full_info_model.dart';
import '../features/shift/model/currency_amount.dart';
import '../shared/models/branch_model.dart';
import '../shared/models/customer_model.dart';


class SyncService {

  final FocusNode _focusNode = FocusNode();
  late  GetStorage box;
  
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
        // AppHelper.showErroDialog(description: apiError["reason"]);
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
          // AppHelper.showErroDialog(description: apiError["reason"]);
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
          // AppHelper.handleError(onError);
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
    print("Syncing payments received...");
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

  static  syncOfflineShifts(UserModel user,  GetStorage box) async {
    List<ShiftModel> shiftInfo = loadShiftInfo(box);
    List<ShiftModel> itemsToBeSynced = [];
    List<ShiftModel> upToDateItems = [];

    if(user.id.isNullOrBlank!){
      var model = box.read(AppConstants.USER_INFO) ?? {};
      user = UserModel.fromMap(Map<String, dynamic>.from(model));
    }

    List<CurrencyAmount> allCurrencyAmountsToSync = [];

    // 1. Separate shifts into those that need syncing and those that are up-to-date.
    for (ShiftModel sh in shiftInfo) {
      // A shift needs syncing if stopSync is false.
      if (sh.stopSync == false) {
        itemsToBeSynced.add(sh);
        // Collect all currency amounts that don't have a server ID yet.
        if (sh.shiftCurrencyAmounts != null) {
          allCurrencyAmountsToSync.addAll(sh.shiftCurrencyAmounts!.where((ca) => ca.id == null));
        }
      } else {
        upToDateItems.add(sh);
      }
    }

    // 2. Sync all new currency amounts in a single batch.
    if (allCurrencyAmountsToSync.isNotEmpty) {
        print("Found ${allCurrencyAmountsToSync.length} currency amounts with null ID to sync.");
        List<CurrencyAmount> syncedCAs = await syncShiftsWithNullID(allCurrencyAmountsToSync, user);
        
        // Create a map for easy lookup of the newly synced currency amounts.
        Map<String, CurrencyAmount> syncedCAMap = { 
            for(var ca in syncedCAs) if(ca.ref != null) ca.ref!: ca 
        };

        // Update the local shift objects with the synced currency amounts (which now have IDs).
        if (syncedCAMap.isNotEmpty) {
            for (var shift in itemsToBeSynced) {
                if (shift.shiftCurrencyAmounts != null) {
                    for (int i = 0; i < shift.shiftCurrencyAmounts!.length; i++) {
                        var localCA = shift.shiftCurrencyAmounts![i];
                        if (localCA.ref != null && syncedCAMap.containsKey(localCA.ref!)) {
                            shift.shiftCurrencyAmounts![i] = syncedCAMap[localCA.ref!]!;
                        }
                    }
                }
            }
        }
    }

    // 3. Sync the shifts themselves.
    if(itemsToBeSynced.isNotEmpty) {
      String jsonShiftItems = json.encode(
          itemsToBeSynced.map((shift) => shift.toMap()).toList());
      
      var response = await BaseHttpClient()
          .postAuthWithCompanyHeader(
          "/mobile/pos/shift/save", jsonShiftItems, user.companyId!, "POST")
          .catchError((onError) {
        print(onError);
        AppHelper.hideLoading();
        if (onError is BadRequestException) {
          var apiError = json.decode(onError.message!);
          // AppHelper.showErroDialog(description: apiError["message"]);
        } else {
          AppHelper.handleError(onError);
        }
      });

      // 4. Merge the server response with local data to prevent data loss.
      if (response != null) {
        ShiftResponseModel saleResponseModel = ShiftResponseModel.fromJson(response);
        List<ShiftModel> syncedShiftsFromServer = saleResponseModel.items ?? [];
        
        // Build a map of ALL local shifts (both synced and up-to-date) to ensure we can merge
        // any shift returned by the server, even if we thought it was up-to-date.
        List<ShiftModel> allLocalShifts = [...itemsToBeSynced, ...upToDateItems];
        Map<String, ShiftModel> allLocalShiftsMap = {
            for (var s in allLocalShifts) if (s.shiftReference != null) s.shiftReference!: s
        };

        Map<String, ShiftModel> finalShiftsMap = {};

        for (var serverShift in syncedShiftsFromServer) {
            if (serverShift.shiftReference != null) {
                if (allLocalShiftsMap.containsKey(serverShift.shiftReference)) {
                    ShiftModel localShift = allLocalShiftsMap[serverShift.shiftReference]!;
                    
                    // MERGE: Preserve local currency amounts
                    serverShift.shiftCurrencyAmounts = localShift.shiftCurrencyAmounts;

                    // Update stopSync status based on server's closed status
                    if (serverShift.isShiftClosed == true) {
                        serverShift.stopSync = true;
                    } else {
                        serverShift.stopSync = false;
                    }
                    
                    finalShiftsMap[serverShift.shiftReference!] = serverShift;
                    allLocalShiftsMap.remove(serverShift.shiftReference); // Mark as processed
                } else {
                    // New shift from server (unexpected but handled)
                    finalShiftsMap[serverShift.shiftReference!] = serverShift;
                }
            }
        }
        
        // Add remaining local shifts that weren't in server response
        // This includes up-to-date shifts that weren't returned, and failed-to-sync shifts
        finalShiftsMap.addAll(allLocalShiftsMap);

        List<Map<String, dynamic>> itemsListMap = finalShiftsMap.values.map((item) => item.toMap()).toList();
        box.write(AppConstants.SHIFT_LIST, itemsListMap);

      } else {
        // No response from server. Local data is preserved and will be retried on the next sync.
        print("Shift sync failed: No response from server.");
      }
    }
  }

  static bool hadValidSubscription(){

    var box = GetStorage();
    var renewalDateData = box.read(AppConstants.RENEWAL_DATE);

    if(renewalDateData != null ) {
      DateTime? renewalDate;
      if (renewalDateData is DateTime) {
        renewalDate = renewalDateData;
      } else if (renewalDateData is String) {
        try {
          renewalDate = new DateFormat("dd/MM/yyyy").parse(renewalDateData);
        } catch (e) {
          print("Error parsing renewal date: $e");
          try {
            renewalDate = DateTime.parse(renewalDateData);
          } catch (e2) {
            print("Error parsing renewal date as ISO8601: $e2");
          }
        }
      }

      if (renewalDate != null) {
        print("renewalDate: ${renewalDate}");
        DateTime now = DateTime.now();
        DateTime startOfDay = DateTime(now.year, now.month, now.day);
        var daysRemaining = renewalDate.difference(startOfDay);
        print("days remainig: ${daysRemaining.inDays}");
        if(daysRemaining.inDays > 0){
          if(daysRemaining.inDays < 5 && daysRemaining.inDays >0)
            Get.snackbar("Subscription Expiring Soon",
                "Your subscription will expire in ${daysRemaining.inDays} days",
                snackPosition: SnackPosition.TOP,
                backgroundColor: Colors.redAccent);
            // AppHelper.showErroDialog(title: "Subscription Expiring Soon", description: "Your subscription will expire in ${daysRemaining.inDays} day(s). Please contact your admin to renew your subscription");
          return true;
        } else if(daysRemaining.inDays <= 0) {
          AppHelper.showErroDialog(title: "Subscription Expired", description: "Your subscription has expired. Please contact your admin to renew your subscription");
          logout(box);
        }
      }
    }
    return false;
  }

  static logout(box) async {
    UserModel user = UserModel(id: null, firstName: "", lastName: "", userName: "");
    var model = box.read(AppConstants.USER_INFO) ?? {};
    user = UserModel.fromMap(Map<String, dynamic>.from(model));
    final LocalStorageService _localStorageService = LocalStorageService();
    box.remove(AppConstants.CACHED_ACCESS_TOKEN);
    box.write(AppConstants.IS_AUTHENTICATED, false);
    box.remove(AppConstants.USER_INFO);
    List<ShiftModel> tempShiftList = loadShifts(box, _localStorageService);
    ShiftModel? tempActiveShift = await _localStorageService.getActiveShift(tempShiftList, box, UserModel(firstName: "", lastName: "", userName: ""), false);
    if(tempActiveShift != null) {
      // DateTime now = DateTime.now();
      // String closingTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
      // tempActiveShift.isShiftClosed = true;
      // tempActiveShift.closingTime = closingTime;
      // List<ShiftModel> shi = _localStorageService.replaceShift(
      //     tempActiveShift, tempShiftList);
      // _localStorageService.writeItems(AppConstants.SHIFT_LIST, shi, box);
      SyncService.syncOfflineShifts(user, box);
    }
    Get.delete<SaleController>();
    Get.delete<BackgroundService>();
    Get.offNamed(AppRoutes.LOGIN);
  }


  static List<ShiftModel> loadShifts( GetStorage box, LocalStorageService localStorageService) {
    List<ShiftModel> list = localStorageService.getOfflineList<ShiftModel>(
        AppConstants.SHIFT_LIST,
            (map) => ShiftModel.fromMap(map),
        box);
    return list;
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
