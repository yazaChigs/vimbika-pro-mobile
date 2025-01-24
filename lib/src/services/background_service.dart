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
import 'package:vimbika_pos_app/src/services/sync_service.dart';
import 'package:vimbika_pos_app/src/shared/models/currency_model.dart';
import 'package:vimbika_pos_app/src/utils/app_helper.dart';

class BackgroundService extends GetxService {
  final ConnectivityService _connectivityService = ConnectivityService();
  late UserModel user = UserModel(firstName: "", lastName: "", userName: "");
  late ShiftSettingModel shiftSetting = ShiftSettingModel();
  @override
  void onInit() {
    super.onInit();
    // Schedule the task to run every 5 minutes
    GetStorage box = GetStorage();
    LocalStorageService _localStorageService = LocalStorageService();
    var model = box.read(AppConstants.USER_INFO) ?? {};
    user = UserModel.fromMap(Map<String, dynamic>.from(model));
    var shiftModel = box.read(AppConstants.SHIFT_SETTING) ?? {};
    shiftSetting = ShiftSettingModel.fromMap(Map<String, dynamic>.from(shiftModel));
    Timer.periodic(Duration(minutes: 1), (timer) async {
      checkShiftStatus(box, _localStorageService);
      await postDataToBackend();


    });
  }

  checkShiftStatus(GetStorage box, LocalStorageService _localStorageService){
    List<ShiftModel> tempShiftList = loadShifts(box, _localStorageService);
    ShiftModel? tempActiveShift = _localStorageService.getActiveShift(tempShiftList);
    print("Opening time..");
    print(tempActiveShift?.openingTime);
    if(tempActiveShift != null) {
       DateTime openingTime = DateTime.parse(tempActiveShift.openingTime!);
       DateTime closingTime = openingTime.add(Duration(hours: shiftSetting.shiftDuration!));


       DateTime now = DateTime.now();
       print(closingTime.toString());
       if(now.isAfter(closingTime)){

         String closingTi = DateFormat('yyyy-MM-dd HH:mm:ss').format(closingTime);
         tempActiveShift.isShiftClosed = true;
         tempActiveShift.closingTime = closingTi;
         List<ShiftModel> shi =  _localStorageService.replaceShift(tempActiveShift, tempShiftList);
         _localStorageService.writeItems(AppConstants.SHIFT_LIST, shi, box);
         Get.snackbar("Status", "Your current shift has been closed.", snackPosition: SnackPosition.BOTTOM);

       }
    }
  }
  List<ShiftModel> loadShifts( GetStorage box, LocalStorageService _localStorageService) {
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
      postData(user, box);
    }
  }
  Future<void> postData(UserModel user, GetStorage box) async {
    await SyncService.syncOfflineSales(user, box);
    // await SyncService.syncOfflineTickets(user, box);
    await SyncService.getCurrencies(user, box);
    await SyncService.getPaymentTypes(user, box);
    await SyncService.syncOfflineShifts(user, box);


  }










}
