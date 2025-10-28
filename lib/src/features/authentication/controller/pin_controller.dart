import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:vimbika_pos_app/src/constants/app_constants.dart';
import 'package:vimbika_pos_app/src/constants/app_routes.dart';
import 'package:vimbika_pos_app/src/features/authentication/model/user_model.dart';
import 'package:vimbika_pos_app/src/features/shift/model/shift_model.dart';
import 'package:vimbika_pos_app/src/services/local_storage_service.dart';
import 'package:vimbika_pos_app/src/shared/controller/inactivity_controller.dart';

import '../../shift/model/shift_setting_model.dart';

class PinController extends GetxController {
  RxString enteredPin = "".obs;
  RxBool isPinVisible = false.obs;
  var shiftAvailable = false.obs;
  final LocalStorageService _localStorageService = LocalStorageService();
  late UserModel user = UserModel(firstName: "", lastName: "", userName: "");

  @override
  Future<void> onInit() async {
    super.onInit();
    GetStorage box = GetStorage();
    var model = box.read(AppConstants.USER_INFO) ?? {};
    user = UserModel.fromMap(Map<String, dynamic>.from(model));
    List<ShiftModel> tempShiftList = loadShifts(box);
    ShiftModel? tempActiveShift = await _localStorageService.getActiveShift(tempShiftList, box, user, true);
    if(tempActiveShift != null) {
      print("Active Shift Found: ${tempActiveShift.shiftReference}");
      shiftAvailable.value = true;
      DateTime openingTime = DateTime.parse(tempActiveShift.openingTime!);
      if(DateTime.now().day != openingTime.day || DateTime.now().month != openingTime.month){//shift is from a different day
        showConfirmDialog(tempActiveShift,tempShiftList);
      }
    } else{
      shiftAvailable.value = false;
    }

    var selectedBranch = box.read(AppConstants.SELECTED_BRANCH) ?? null;
    //print(selectedBranch);
    if(selectedBranch == null){
      Get.offNamed(AppRoutes.CHOOSE_BRANCH);
    }

  }


  void showConfirmDialog(ShiftModel shift, List<ShiftModel> tempShiftList) {
    DateTime openingTime = DateTime.parse(shift.openingTime!);
    openingTime = openingTime.add(Duration(hours:2)); //ocean digital is 2 hours behind our local time
    Get.defaultDialog(
      title: "Confirmation",
      middleText: "Continue with old shift ${shift.shiftReference} opened on ${openingTime}?",
      textCancel: "No, Close & Open New Shift",
      textConfirm: "Yes, Continue old  with Shift",
      onCancel: () {
        GetStorage box = GetStorage();
       shiftAvailable.value =  false;
       shift.closingTime =  DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
       shift.isShiftClosed = true;
       shift.stopSync =  false;
          List<ShiftModel> shi =  _localStorageService.replaceShift(shift, tempShiftList);
          _localStorageService.writeItems(AppConstants.SHIFT_LIST, shi, box);
      },
      onConfirm: () {
        shiftAvailable.value =  true;
        Get.snackbar("Confirmed", "Shift ${shift.shiftReference} is confirmed");
        Get.back(closeOverlays: true);


      },
    );
  }
  onNumberEntered(int number){
    if (enteredPin.value.length < 6) {
      enteredPin.value += number.toString();
      if(user.pin != null){
        if(enteredPin == user.pin){
          enteredPin.value = "";
          Get.put(InactivityController());
          startSelling();
        }
      } else{
        Get.snackbar("Pin Error", "Pin not found on this user", snackPosition: SnackPosition.BOTTOM);
        enteredPin.value = "";
        Get.put(InactivityController());
        startSelling();
      }

    }
  }
  startSelling(){
    if(shiftAvailable.isFalse) {
      Get.snackbar("Create Shift", "Open a shift to proceed", snackPosition: SnackPosition.BOTTOM);
      Get.offNamed(AppRoutes.OPEN_SHIFT);
    } else{
      Get.toNamed(AppRoutes.SALE);
    }
  }
  List<ShiftModel> loadShifts( GetStorage box) {
    List<ShiftModel> list = _localStorageService.getOfflineList<ShiftModel>(
        AppConstants.SHIFT_LIST,
            (map) => ShiftModel.fromMap(map),
        box);
    return list;
  }

}