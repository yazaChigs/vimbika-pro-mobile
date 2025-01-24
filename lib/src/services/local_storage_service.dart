import 'package:get_storage/get_storage.dart';
import 'package:vimbika_pos_app/src/constants/app_constants.dart';
import 'package:vimbika_pos_app/src/features/printers/model/available_printer_model.dart';
import 'package:vimbika_pos_app/src/features/shift/model/shift_model.dart';
import 'package:vimbika_pos_app/src/shared/models/currency_model.dart';

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
  bool findPrinterByAddress(List<AvailablePrinterModel> printers, String address){
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
     if(pr.name == printer.name){
         pr.isDefault = stat;
         updatedPrinters.add(pr);
     } else{
       pr.isDefault = false;
       updatedPrinters.add(pr);
     }
    }
    return updatedPrinters;
  }
  ShiftModel? getActiveShift(List<ShiftModel> shifts){
    for(var cur in shifts)  {
      if(!cur.isShiftClosed!){
        return cur;
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


}
