import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:vimbika_pos_app/src/constants/app_constants.dart';
import 'package:vimbika_pos_app/src/features/authentication/model/user_model.dart';
import 'package:vimbika_pos_app/src/features/shift/model/shift_model.dart';
import 'package:vimbika_pos_app/src/features/shift/model/shift_response_model.dart';
import 'package:vimbika_pos_app/src/features/shift/model/shift_setting_model.dart';
import 'package:vimbika_pos_app/src/services/app_exceptions.dart';
import 'package:vimbika_pos_app/src/services/base_http_client.dart';
import 'package:vimbika_pos_app/src/services/connectivity_service.dart';
import 'package:vimbika_pos_app/src/services/local_storage_service.dart';
import 'package:vimbika_pos_app/src/services/sync_lock_service.dart';
import 'package:vimbika_pos_app/src/services/sync_service.dart';
import 'package:vimbika_pos_app/src/shared/models/currency_model.dart';
import 'package:vimbika_pos_app/src/utils/app_helper.dart';

import '../features/sale/model/sale_infor_model.dart';
import '../features/sale/model/sale_model.dart';
import '../features/shift/model/currency_amount.dart';
import '../shared/models/company_model.dart';

class BackgroundService extends GetxService {
  final ConnectivityService _connectivityService = ConnectivityService();
  late UserModel user = UserModel(firstName: "", lastName: "", userName: "");
  late ShiftSettingModel shiftSetting = ShiftSettingModel();
  List<SaleInfoModel> offlineSales = <SaleInfoModel>[];
  List<SaleInfoModel> salesNumber = <SaleInfoModel>[];
  List<SaleInfoModel> reversedSales = <SaleInfoModel>[];
  Rx<CompanyModel?> company = CompanyModel().obs;
  late  GetStorage box;

  @override
  void onInit() {
    super.onInit();
    box = GetStorage();
    var model = box.read(AppConstants.USER_INFO) ?? {};
    user = UserModel.fromMap(Map<String, dynamic>.from(model));
    var shiftModel = box.read(AppConstants.SHIFT_SETTING) ?? {};
    shiftSetting = ShiftSettingModel.fromMap(Map<String, dynamic>.from(shiftModel));
    Timer.periodic(Duration(minutes: 5), (timer) async {
      print("Background task running every 30 seconds");
        await syncOfflineSales(true);
      });
    var companyModel = box.read(AppConstants.ACTIVE_COMPANY) ?? {};
    company.value = CompanyModel.fromMap(Map<String, dynamic>.from(companyModel));
    salesNumber = getExistingOfflineSales(box);
  }

  checkShiftStatus(GetStorage box, LocalStorageService _localStorageService) async {
    // Reload user to ensure we have the current logged-in user
    var model = box.read(AppConstants.USER_INFO) ?? {};
    UserModel currentUser = UserModel(firstName: "", lastName: "", userName: "");
    if(model.isNotEmpty){
      currentUser = UserModel.fromMap(Map<String, dynamic>.from(model));
      print("Check Shift Status: Loaded user ${currentUser.userName} with ID ${currentUser.id}");
    }
    
    List<ShiftModel> tempShiftList = loadShifts(box, _localStorageService);
    ShiftModel? tempActiveShift = await _localStorageService.getActiveShift(tempShiftList, box, currentUser, false);
    if(tempActiveShift != null) {
       DateTime openingTime = DateTime.parse(tempActiveShift.openingTime!);
       // DateTime closingTime = openingTime.add(Duration(hours: shiftSetting.shiftDuration??24));


       // DateTime now = DateTime.now();
       // if(now.isAfter(closingTime)){
       //
       //   String closingTi = DateFormat('yyyy-MM-dd HH:mm:ss').format(closingTime);
       //   tempActiveShift.isShiftClosed = true;
       //   tempActiveShift.closingTime = closingTi;
       //   List<ShiftModel> shi =  _localStorageService.replaceShift(tempActiveShift, tempShiftList);
       //   _localStorageService.writeItems(AppConstants.SHIFT_LIST, shi, box);
       //   Get.snackbar("Status", "Your current shift has been closed.", snackPosition: SnackPosition.BOTTOM);
       //
       // }
    }
  }
  List<ShiftModel> loadShifts( GetStorage box, LocalStorageService _localStorageService) {
    List<ShiftModel> list = _localStorageService.getOfflineList<ShiftModel>(
        AppConstants.SHIFT_LIST,
            (map) => ShiftModel.fromMap(map),
        box);
    return list;
  }


  syncOfflineSales(bool returnSales) async{
    print("syncing offline sales...");
    box = GetStorage();
    
    // Reload user to ensure we have the current logged-in user
    // This is critical when a user logs in after another user has logged out
    var model = box.read(AppConstants.USER_INFO) ?? {};
    if(model.isNotEmpty){
      user = UserModel.fromMap(Map<String, dynamic>.from(model));
      print("Sync Offline Sales: Loaded user ${user.userName} with ID ${user.id}");
    }
    var syncing = box.read(AppConstants.SYNCING_IN_PROGRESS)??false;
    if(syncing)
      return;
    
    box.write(AppConstants.SYNCING_IN_PROGRESS, true);
    bool stat = await _connectivityService.checkServerConnection();
    if(stat) {
      List<SaleInfoModel> sales = getExistingOfflineSales(box);
      List<SaleInfoModel> actualSales = [];
      List<SaleInfoModel> reversed = [];
      List<CurrencyAmount> currencyAmounts = [];
      // Load ALL shifts (including closed ones) to ensure sales can be matched to their correct shift
      // This is critical when syncing sales from a closed shift
      List<ShiftModel> shiftList = loadShiftInfo(box);
      print("Sync: Loaded ${shiftList.length} shift(s) (including closed) for matching sales");
      bool synced =  false;
      for(ShiftModel sh in shiftList){
        if(sh.shiftCurrencyAmounts != null && sh.shiftCurrencyAmounts!.isNotEmpty){
          currencyAmounts.addAll(sh.shiftCurrencyAmounts!);
        }
      }
      SaleInfoModel saleInfoModel;
      for(SaleInfoModel s in sales){
        if(s.sale!.saleStatus == "COMPLETE" || s.sale!.saleStatus == "PENDING"){
          actualSales.add(s);
        }
        if(s.sale!.saleStatus == "REVERSED"){
          reversed.add(s);
        }
      }

      // Remove duplicates based on posReference, prioritizing synced sales
      Set<String> syncedPosRefs = actualSales
          .where((s) => s.syncStatus == true && s.sale?.posReference != null)
          .map((s) => s.sale!.posReference!)
          .toSet();

      Set<String> seenPosRefs = {};
      List<SaleInfoModel> dedupedSales = [];

      for (var sale in actualSales) {
        String? posRef = sale.sale?.posReference;

        if (posRef == null) {
          dedupedSales.add(sale);
          continue;
        }

        if (seenPosRefs.contains(posRef)) {
          continue;
        }

        if (sale.syncStatus != true && syncedPosRefs.contains(posRef)) {
          continue;
        }

        seenPosRefs.add(posRef);
        dedupedSales.add(sale);
      }
      actualSales = dedupedSales;

      // actualSales = actualSales.where((sale)=> sale.syncStatus == false).toList();
      actualSales = actualSales.where((sale)=> sale.syncStatus == false).toList();
      offlineSales = actualSales;
      reversedSales = reversed;

      List<SaleInfoModel> syncedSales = [];
      for (SaleInfoModel saleInfo in offlineSales) {
        CurrencyAmount saleCurrencyAmount =  currencyAmounts.firstWhere((test)=> test.posReference==saleInfo.sale!.posReference!, orElse: () => CurrencyAmount(currency: CurrencyModel(), amountType: "", ref: "", timeCreated: "", notes: "", amount: 0.0, shiftReference: null));
        if (!saleInfo.syncStatus!) {
          SaleModel? saleModel = await SyncService.saveSale(
              saleInfo.sale!, user, box, company.value!);
          if (saleModel != null) {
            // synced = true;
            syncedSales.add(saleInfo);
            SaleInfoModel? infoModel = null;
            if(saleModel.branch!.alwaysFiscalize!)
             infoModel = await getSale(saleModel.id!);
            if(infoModel != null){
              saleInfoModel = infoModel;
            } else{
              saleInfoModel = SaleInfoModel(sale: saleModel, syncStatus: true);
            }
            
          /*  // Update shift currency amount with new posReference from server
            // CRITICAL: Use the shiftReference from the synced sale to ensure correct association
            // This works even if the shift is closed - we match by shiftReference regardless of isShiftClosed
            if (saleInfoModel.sale?.shiftReference != null) {
              // Reload shifts to ensure we have the latest state (including changes from concurrent chargeSale)
              List<ShiftModel> currentShiftList = loadShiftInfo(box);
              
              // Find the shift by the exact shiftReference from the sale
              // NOTE: We intentionally don't check isShiftClosed here - closed shifts can still have sales synced to them
              ShiftModel? shift = currentShiftList.firstWhereOrNull(
                (shift) => shift.shiftReference == saleInfoModel.sale!.shiftReference &&
                           shift.userId != null &&
                           user.id != null &&
                           shift.userId == user.id // Ensure shift belongs to current user
              );
              
              if (shift != null && shift.shiftCurrencyAmounts != null) {
                String shiftStatus = shift.isShiftClosed == true ? "CLOSED" : "OPEN";
                print("Sync: Updating ${shiftStatus} shift ${shift.shiftReference} with sale ${saleInfoModel.sale?.posReference}");
                // Find and update the currency amount with new posReference
                int index = shift.shiftCurrencyAmounts!.indexWhere(
                  (ca) => ca.posReference == saleInfo.sale!.posReference || 
                          ca.posReference == saleInfo.sale!.referenceNumber ||
                          (ca.shiftReference == saleInfoModel.sale!.shiftReference && 
                           ca.posReference == null) // Match by shiftReference if posReference not set yet
                );
                if (index != -1) {
                  // Update existing currency amount with new posReference from server
                  shift.shiftCurrencyAmounts![index].posReference = saleInfoModel.sale?.posReference;
                  print("Sync: Updated existing currency amount at index $index");
                } else if (saleCurrencyAmount.shiftReference == saleInfoModel.sale!.shiftReference) {
                  // Only add if the currency amount's shiftReference matches the sale's shiftReference
                  saleCurrencyAmount.posReference = saleInfoModel.sale?.posReference;
                  shift.shiftCurrencyAmounts!.add(saleCurrencyAmount);
                  print("Sync: Added new currency amount to shift ${shift.shiftReference}");
                } else {
                  print("Sync: Warning - Currency amount shiftReference (${saleCurrencyAmount.shiftReference}) doesn't match sale shiftReference (${saleInfoModel.sale!.shiftReference})");
                }
                
                // Persist the updated shift using the fresh list
                int shiftIndex = currentShiftList.indexWhere((s) => s.shiftReference == shift.shiftReference);
                if (shiftIndex != -1) {
                  currentShiftList[shiftIndex] = shift;
                  List<ShiftModel> updatedShifts = LocalStorageService().replaceShift(shift, currentShiftList);
                  LocalStorageService().writeItems(AppConstants.SHIFT_LIST, updatedShifts, box);
                }
              } else {
                print("Sync: Warning - Shift ${saleInfoModel.sale!.shiftReference} not found or doesn't belong to user ${user.id}");
              }
            } else {
              print("Sync: Warning - Sale ${saleInfoModel.sale?.posReference} has no shiftReference");
            }*/
            
            sales = getExistingOfflineSales(box);
            int index = sales.indexWhere((s) => s.sale?.posReference == saleInfo.sale?.posReference);
            if (index != -1) {
              sales[index] = saleInfoModel;
            } else {
              sales.add(saleInfoModel);
            }
            writeSaleInfor(box, sales);
          }
          else{
            print("sale not synced");
          }
        }
      }
      for (SaleInfoModel saleInfo in reversedSales) {
        CurrencyAmount saleCurrencyAmount =  currencyAmounts.firstWhere((test)=> test.posReference==saleInfo.sale!.posReference!, orElse: () => CurrencyAmount(currency: CurrencyModel(), amountType: "", ref: "", timeCreated: "", notes: "", amount: 0.0, shiftReference: null));
        if (!saleInfo.syncStatus!) {
          saleInfo.sale!.timeIniated = saleInfo.sale!.timeIniated!.replaceAll("T", " ");
          saleInfo.sale!.paymentTypes!.forEach((element) {
            element.dateTime = element.dateTime!.replaceAll("T", " ");
          });
          SaleModel? saleModel = await SyncService.reverseSale(
              saleInfo.sale!, user, box, company.value!);
          if (saleModel != null) {
            // synced = true;
            syncedSales.add(saleInfo);
            SaleInfoModel? infoModel = await getSale(saleModel.id!);
            if(infoModel != null){
              saleInfoModel = infoModel;
            } else{
              saleInfoModel = SaleInfoModel(sale: saleModel, syncStatus: true);
            }

            // Update shift currency amount with new posReference from server (for reversed sales)
            // CRITICAL: Use the shiftReference from the synced sale to ensure correct association
            // This works even if the shift is closed - we match by shiftReference regardless of isShiftClosed
            if (saleInfoModel.sale?.shiftReference != null) {
              // Reload shifts to ensure we have the latest state (including changes from concurrent chargeSale)
              List<ShiftModel> currentShiftList = loadShiftInfo(box);
              
              // Find the shift by the exact shiftReference from the sale
              // NOTE: We intentionally don't check isShiftClosed here - closed shifts can still have sales synced to them
              ShiftModel? shift = currentShiftList.firstWhereOrNull(
                (shift) => shift.shiftReference == saleInfoModel.sale!.shiftReference &&
                           shift.userId != null &&
                           user.id != null &&
                           shift.userId == user.id // Ensure shift belongs to current user
              );
              
              if (shift != null && shift.shiftCurrencyAmounts != null) {
                String shiftStatus = shift.isShiftClosed == true ? "CLOSED" : "OPEN";
                print("Sync (Reversed): Updating ${shiftStatus} shift ${shift.shiftReference} with sale ${saleInfoModel.sale?.posReference}");
                // Find and update the currency amount with new posReference
                int index = shift.shiftCurrencyAmounts!.indexWhere(
                  (ca) => ca.posReference == saleInfo.sale!.posReference || 
                          ca.posReference == saleInfo.sale!.referenceNumber ||
                          (ca.shiftReference == saleInfoModel.sale!.shiftReference && 
                           ca.posReference == null) // Match by shiftReference if posReference not set yet
                );
                if (index != -1) {
                  // Update existing currency amount with new posReference from server
                  shift.shiftCurrencyAmounts![index].posReference = saleInfoModel.sale?.posReference;
                  print("Sync (Reversed): Updated existing currency amount at index $index");
                } else if (saleCurrencyAmount.shiftReference == saleInfoModel.sale!.shiftReference) {
                  // Only add if the currency amount's shiftReference matches the sale's shiftReference
                  saleCurrencyAmount.posReference = saleInfoModel.sale?.posReference;
                  shift.shiftCurrencyAmounts!.add(saleCurrencyAmount);
                  print("Sync (Reversed): Added new currency amount to shift ${shift.shiftReference}");
                } else {
                  print("Sync (Reversed): Warning - Currency amount shiftReference (${saleCurrencyAmount.shiftReference}) doesn't match sale shiftReference (${saleInfoModel.sale!.shiftReference})");
                }
                
                // Persist the updated shift using the fresh list
                int shiftIndex = currentShiftList.indexWhere((s) => s.shiftReference == shift.shiftReference);
                if (shiftIndex != -1) {
                  currentShiftList[shiftIndex] = shift;
                  List<ShiftModel> updatedShifts = LocalStorageService().replaceShift(shift, currentShiftList);
                  LocalStorageService().writeItems(AppConstants.SHIFT_LIST, updatedShifts, box);
                }
              } else {
                print("Sync (Reversed): Warning - Shift ${saleInfoModel.sale!.shiftReference} not found or doesn't belong to user ${user.id}");
              }
            } else {
              print("Sync (Reversed): Warning - Sale ${saleInfoModel.sale?.posReference} has no shiftReference");
            }
            
            // Update the sale in the local storage
            sales = getExistingOfflineSales(box);
            int index = sales.indexWhere((s) => s.sale?.posReference == saleInfo.sale?.posReference);
            if (index != -1) {
              sales[index] = saleInfoModel;
            } else {
              sales.add(saleInfoModel);
            }
            writeSaleInfor(box, sales);

          }
        }
      }
      writeSaleInfor(box, sales);
      for(SaleInfoModel saleInfo in syncedSales) {
        // Remove the synced sales from the offline list
        print(offlineSales.remove(saleInfo));
      }

      salesNumber = offlineSales;
      // Shift updates are now handled inside the loop with fresh data

        await SyncService.syncOfflineShifts(user, box);
    }
    box.write(AppConstants.SYNCING_IN_PROGRESS, false);
  }


  Future<SaleInfoModel?> getSale(String saleId) async{
    if(user.id.isNullOrBlank!){
      box = GetStorage();
      var model = box.read(AppConstants.USER_INFO) ?? {};
      user = UserModel.fromMap(Map<String, dynamic>.from(model));
    }
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



  writeSaleInfor(GetStorage box, List<SaleInfoModel> itemsList){
    List<Map<String, dynamic>> itemsListMap = itemsList.map((item) =>
        item.toMap()).toList();
    box.write(AppConstants.SALE_LIST, itemsListMap);
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





  Future<void> postDataToBackend() async {
    print("CHECKING INTERNET AND POSTING DATA");
    bool networkStat = await _connectivityService.checkServerConnection();
    if (networkStat) {
      final box = GetStorage();
      var model = box.read(AppConstants.USER_INFO) ?? {};
      UserModel user = UserModel.fromMap(Map<String, dynamic>.from(model));
      print("Network is available, getting branchStock...");
      SyncService.getBranchStock(box, user);
      SyncService.getCustomers(user, box, user.companyId!);
      // postData(user, box);
    }
  }
  Future<void> postData(UserModel user, GetStorage box) async {
   // await SyncService.syncOfflineSales(user, box);
    await SyncService.getCurrencies(user, box);
    await SyncService.getPaymentTypes(user, box);
  }










}
