import 'package:get_storage/get_storage.dart';
import 'package:vimbika_pos_app/src/constants/app_constants.dart';
import 'package:vimbika_pos_app/src/features/authentication/model/user_model.dart';
import 'package:vimbika_pos_app/src/features/printers/model/available_printer_model.dart';
import 'package:vimbika_pos_app/src/features/sale/model/product_full_info_model.dart';
import 'package:vimbika_pos_app/src/features/sale/model/sale_infor_model.dart';
import 'package:vimbika_pos_app/src/features/sale/model/sale_model.dart';
import 'package:vimbika_pos_app/src/features/shift/model/shift_model.dart';
import 'package:vimbika_pos_app/src/features/stock_requests/model/requisition_model.dart';
import 'package:vimbika_pos_app/src/features/stock_requests/model/transfer_history_model.dart';
import 'package:vimbika_pos_app/src/services/sync_service.dart';
import 'package:vimbika_pos_app/src/shared/models/currency_model.dart';
import 'package:vimbika_pos_app/src/shared/models/customer_model.dart';

class LocalStorageService {


  List<T> getOfflineList<T>(String key, T Function(Map<String, dynamic>) fromMap, GetStorage _box) {
    // Read the data as a List<dynamic>
    List<dynamic>? itemsListDynamic = _box.read<List<dynamic>>(key);

    // Check if the read data is not null
    if (itemsListDynamic != null) {
      // Convert the List<dynamic> to List<Map<String, dynamic>>
      List<Map<String, dynamic>> itemsListMap = itemsListDynamic.map((item) {
        return item as Map<String, dynamic>;
      }).toList();

      // Convert the List<Map<String, dynamic>> to List<T>
      List<T> itemsList = itemsListMap.map((map) => fromMap(map)).toList();

      return itemsList;
    } else {
      return [];
    }
  }
  void writeItems<T>(String storageKey, List<T> itemsList, GetStorage box) {
    GetStorage box = GetStorage();
    List<Map<String, dynamic>> itemsListMap = itemsList.map((item) {
      final dynamicItem = item as dynamic;
      return dynamicItem.toMap() as Map<String, dynamic>;
    }).toList();
    box.write(storageKey, itemsListMap);
  }
  CurrencyModel? getBaseCurrency(List<CurrencyModel> currencies){
    for(var cur in currencies)  {
      if(cur.isBaseCurrency!){
        return cur;
      }
    }
    return null;
  }
  bool findPrinterByAddress(List<AvailablePrinterModel> printers, String? address){
    for(var pr in printers)  {
      if(pr.address == address){
        return true;
      }
    }
    return false;
  }

  AvailablePrinterModel? findActivePrinter(GetStorage box){
    List<AvailablePrinterModel> printers = getOfflineList<AvailablePrinterModel>(AppConstants.AVAILABLE_PRINTERS, (map) => AvailablePrinterModel.fromMap(map), box);
    for(var pr in printers)  {
      if(pr.isDefault!){
        return pr;
      }
    }
    return null;
  }
  List<AvailablePrinterModel>  saveDefaultPrinter(List<AvailablePrinterModel> printers, AvailablePrinterModel printer, bool stat){
    List<AvailablePrinterModel> updatedPrinters = [];
    for(var pr in printers)  {
     // Match by appropriate fields based on printer type
     // USB: match by vendor+product+type, or name+type if vendor/product are null
     // Bluetooth: match by address+type
     // Inbuilt: match by id+type
     bool matches = false;
     if (printer.type == 'usb') {
       matches = pr.type == printer.type &&
         ((printer.vendorId != null && printer.productId != null && 
           pr.vendorId == printer.vendorId && pr.productId == printer.productId) ||
          (printer.vendorId == null && printer.productId == null && 
           pr.vendorId == null && pr.productId == null && 
           pr.name == printer.name));
     } else if (printer.type == 'bluetooth') {
       matches = pr.type == printer.type &&
         pr.address != null && pr.address == printer.address;
     } else {
       // Inbuilt printers (Sunmi/Telpo): match by id+type
       matches = pr.id != null && pr.id == printer.id && pr.type == printer.type;
     }
     
     if(matches) {
         pr.isDefault = stat;
         updatedPrinters.add(pr);
     } else{
       pr.isDefault = false;
       updatedPrinters.add(pr);
     }
    }
    return updatedPrinters;
  }
  Future<ShiftModel?> getActiveShift(List<ShiftModel> shifts, GetStorage box, UserModel user, bool checkShiftFromServer) async {
    // First, honor explicitly selected shift reference if present
    final String? selectedRef = box.read(AppConstants.SELECTED_SHIFT_REF);
    if (selectedRef != null && selectedRef.isNotEmpty) {
      // Try to find the selected shift in the provided list
      var selected = shifts.firstWhere(
        (cur) => !cur.isShiftClosed! && cur.userId != null && user.id != null && cur.userId == user.id && cur.shiftReference == selectedRef,
        orElse: () => ShiftModel(),
      );
      
      // If not found in provided list, reload from storage to ensure we have the latest data
      if (selected.shiftReference == null) {
        print("getActiveShift: SELECTED_SHIFT_REF ${selectedRef} set but shift not found in provided list, reloading from storage");
        List<ShiftModel> reloadedShifts = getOfflineList<ShiftModel>(
            AppConstants.SHIFT_LIST,
            (map) => ShiftModel.fromMap(map),
            box);
        selected = reloadedShifts.firstWhere(
          (cur) => !cur.isShiftClosed! && cur.userId != null && user.id != null && cur.userId == user.id && cur.shiftReference == selectedRef,
          orElse: () => ShiftModel(),
        );
      }
      
      if (selected.shiftReference != null) {
        print("getActiveShift: Found selected shift ${selectedRef} for user ${user.userName}");
        return selected;
      } else {
        print("getActiveShift: SELECTED_SHIFT_REF ${selectedRef} set but shift not found even after reloading - will not check server to avoid returning wrong shift");
        // If SELECTED_SHIFT_REF is set but shift not found locally, don't check server
        // This prevents returning a different shift when a new shift was just opened
        return null;
      }
    }

    // Otherwise, return first open shift for the current user
    for (var cur in shifts) {
      if (!cur.isShiftClosed! && cur.userId != null && user.id != null && cur.userId == user.id) {
        return cur;
      }
    }

    // Optionally check server for open shift (only if no SELECTED_SHIFT_REF is set)
    if (checkShiftFromServer) {
      ShiftModel? sh = await SyncService.getOpenedShift(user, box);
      if (sh != null) {
        int index = shifts.indexWhere((shift) => shift.shiftReference == sh.shiftReference);
        if (index == -1) {
          // New shift from server - add it
          shifts.add(sh);
          writeItems(AppConstants.SHIFT_LIST, shifts, box);
        } else {
          // Shift already exists locally - preserve local opening time if it's newer or if local shift has no id (newly created)
          // This prevents server from overwriting a newly created shift's opening time
          ShiftModel localShift = shifts[index];
          bool shouldPreserveLocalOpeningTime = false;
          
          // Preserve if local shift is newly created (no id) or if local opening time is newer
          if (localShift.id == null) {
            shouldPreserveLocalOpeningTime = true;
            print("Preserving opening time for newly created shift (no id): ${localShift.openingTime}");
          } else if (localShift.openingTime != null && sh.openingTime != null) {
            try {
              DateTime localOpeningTime = DateTime.parse(localShift.openingTime!);
              DateTime serverOpeningTime = DateTime.parse(sh.openingTime!);
              // If local opening time is newer (more recent), preserve it
              if (localOpeningTime.isAfter(serverOpeningTime)) {
                shouldPreserveLocalOpeningTime = true;
                print("Preserving local opening time ${localShift.openingTime} (newer than server: ${sh.openingTime})");
              }
            } catch (e) {
              print("Error comparing opening times: $e");
            }
          }
          
          // Update local shift with server data but preserve opening time if needed
          if (shouldPreserveLocalOpeningTime && localShift.openingTime != null) {
            sh.openingTime = localShift.openingTime;
          }
          shifts[index] = sh;
          writeItems(AppConstants.SHIFT_LIST, shifts, box);
        }
        return sh;
      }
    }
    return null;
  }
  List<ShiftModel>  replaceShift(ShiftModel newShift, List<ShiftModel> shiftList) {
    // Find the index of the shift with the matching shiftReference
    int index = shiftList.indexWhere((shift) => shift.shiftReference == newShift.shiftReference);

    // If the shift is found, replace it with the new shift
    if (index != -1) {
      shiftList[index] = newShift;
    } else {
      // Optionally handle the case where the shift is not found
      print("Shift with reference ${newShift.shiftReference} not found.");
    }
    return shiftList;
  }
  List<RequisitionModel>  replaceRequisition(RequisitionModel newItem, List<RequisitionModel> list) {
    // Find the index of the shift with the matching shiftReference
    int index = list.indexWhere((item) => item.uuid == newItem.uuid);

    // If the shift is found, replace it with the new shift
    if (index != -1) {
      list[index] = newItem;
    } else {
      // Optionally handle the case where the shift is not found
      print("Requisition with uuid ${newItem.uuid} not found.");
    }
    return list;
  }
  List<TransferHistoryModel>  replaceTransfer(TransferHistoryModel newItem, List<TransferHistoryModel> list) {
    // Find the index of the shift with the matching shiftReference
    int index = list.indexWhere((item) => item.reference == newItem.reference);

    // If the shift is found, replace it with the new shift
    if (index != -1) {
      list[index] = newItem;
    } else {
      // Optionally handle the case where the shift is not found
      print("Transfer with reference ${newItem.reference} not found.");
    }
    return list;
  }


  /// Safely adds or updates a list of sales in local storage to prevent race conditions.
  ///
  /// This method reads the current list of sales, merges the provided sales
  /// by updating existing ones or adding new ones, and then writes the
  /// entire updated list back to storage.
  void addOrUpdateSales(List<SaleInfoModel> salesToUpdate, GetStorage box) {
    // 1. Read the most current list of sales from storage.
    final existingSales = getOfflineList<SaleInfoModel>(
        AppConstants.SALE_LIST, (map) => SaleInfoModel.fromMap(map), box);

    // 2. Create a map for efficient lookup using a unique reference.
    final salesMap = {
      for (var sale in existingSales) sale.sale!.referenceNumber: sale
    };

    // 3. Iterate through the sales to be updated and merge them into the map.
    for (final saleInfo in salesToUpdate) {
      if (saleInfo.sale?.referenceNumber != null) {
        salesMap[saleInfo.sale!.referenceNumber!] = saleInfo;
      }
    }

    // 4. Convert the map values back to a list.
    final updatedSalesList = salesMap.values.toList();

    // 5. Write the fully updated list back to storage.
    final itemsListMap =
    updatedSalesList.map((item) => item.toMap()).toList();
    box.write(AppConstants.SALE_LIST, itemsListMap);
  }


  List<SaleInfoModel>  replaceSale(SaleInfoModel newItem, List<SaleInfoModel> list) {
    // Find the index of the shift with the matching shiftReference
    int index = list.indexWhere((item) => item.sale!.posReference == newItem.sale!.posReference);

    // If the shift is found, replace it with the new shift
    if (index != -1) {
      print("Sale with reference ${newItem.sale!.posReference} replaced successfully");
      list[index] = newItem;
    } else {
      // Optionally handle the case where the shift is not found
      print("Sale with reference ${newItem.sale!.posReference} not found.");
      list.add(newItem);
    }
    return list;
  }


  bool requisitionExists(RequisitionModel newItem, List<RequisitionModel> list) {
    int index = list.indexWhere((item) => item.uuid == newItem.uuid);
    if (index != -1) {
      return true;
    } else {
      return false;
    }

  }
  List<ProductFullInfoModel> getProductList(GetStorage box, bool leastOnTop) {
    // Read the data as a List<dynamic>
    List<dynamic>? itemsListDynamic = box.read<List<dynamic>>(AppConstants.BRANCH_PRODUCTS);

    // Check if the read data is not null
    if (itemsListDynamic != null) {
      // Convert the List<dynamic> to List<Map<String, dynamic>>
      List<Map<String, dynamic>> itemsListMap = itemsListDynamic.map((item) {
        return item as Map<String, dynamic>;
      }).toList();

      // Convert List<Map<String, dynamic>> to List<ProductFullInfoModel>
      List<ProductFullInfoModel> items =  List<ProductFullInfoModel>.from(itemsListMap.map((map) => ProductFullInfoModel.fromMap(map)));
      if(leastOnTop){
        items.sort((a, b) => a.stock!.compareTo(b.stock!));
      } else{
        items.sort((a, b) => b.stock!.compareTo(a.stock!));
      }

      return items;
    } else {
      return [];
    }
  }

  List<RequisitionModel> getRequisitions(GetStorage box){
    List<dynamic>? itemsListDynamic = box.read<List<dynamic>>(AppConstants.REQUISITION_LIST);
    if(itemsListDynamic != null) {
      List<Map<String, dynamic>> itemsListMap = itemsListDynamic.map((item) {
        return item as Map<String, dynamic>;
      }).toList();
      List<RequisitionModel> infos = List<RequisitionModel>.from(
          itemsListMap.map((map) => RequisitionModel.fromMap(map)));
      return infos;
    } else{
      List<RequisitionModel> itemsList = <RequisitionModel>[];
      return itemsList;
    }
  }
  List<CustomerModel> getCustomers(GetStorage box){
    List<dynamic>? itemsListDynamic = box.read<List<dynamic>>(AppConstants.CUSTOMER_LIST);
    if(itemsListDynamic != null) {
      List<Map<String, dynamic>> itemsListMap = itemsListDynamic.map((item) {
        return item as Map<String, dynamic>;
      }).toList();
      List<CustomerModel> infos = List<CustomerModel>.from(
          itemsListMap.map((map) => CustomerModel.fromMap(map)));
      return infos;
    } else{
      List<CustomerModel> itemsList = <CustomerModel>[];
      return itemsList;
    }
  }


}
