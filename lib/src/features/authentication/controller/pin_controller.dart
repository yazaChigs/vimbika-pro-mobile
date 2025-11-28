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
    // Always reload USER_INFO to ensure we have the correct logged-in user
    // This is important when multiple users log in/out
    var model = box.read(AppConstants.USER_INFO) ?? {};
    if(model.isEmpty){
      // If USER_INFO is empty, redirect back to login
      Get.offNamed(AppRoutes.LOGIN);
      return;
    }
    user = UserModel.fromMap(Map<String, dynamic>.from(model));
    print("PIN Screen: Loaded user ${user.userName} with ID ${user.id}");
    
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
  Future<void> onNumberEntered(int number) async {
    if (enteredPin.value.length < 6) {
      enteredPin.value += number.toString();
      
      // Only check PIN when 6 digits are entered (or if user has a PIN shorter than 6)
      int pinLength = user.pin?.length ?? 6;
      if (enteredPin.value.length >= pinLength) {
        // Reload user info to ensure we have the latest user data
        GetStorage box = GetStorage();
        var model = box.read(AppConstants.USER_INFO) ?? {};
        if(model.isNotEmpty){
          user = UserModel.fromMap(Map<String, dynamic>.from(model));
        }
        
        if(user.pin != null && user.pin!.isNotEmpty){
          // Compare entered PIN value (not the RxString object) with user's PIN
          if(enteredPin.value == user.pin){
            enteredPin.value = "";
            print("PIN validated for user: ${user.userName} with ID: ${user.id}");
            
            // Re-check shifts for this user after PIN validation to ensure correct authorization
            // This ensures the user only accesses their own shifts
            await _recheckUserShifts(box);
            
            Get.put(InactivityController());
            startSelling();
          } else{
            // PIN doesn't match, clear and show error
            Get.snackbar("Pin Error", "Incorrect PIN", snackPosition: SnackPosition.BOTTOM);
            enteredPin.value = "";
          }
        } else{
          // No PIN set for this user, allow access anyway (for backward compatibility)
          Get.snackbar("Pin Info", "No PIN set for this user", snackPosition: SnackPosition.BOTTOM);
          enteredPin.value = "";
          
          // Re-check shifts for this user even without PIN validation
          await _recheckUserShifts(box);
          
          Get.put(InactivityController());
          startSelling();
        }
      }
    }
  }
  // Re-check shifts for the current user to ensure they only access their own shifts
  Future<void> _recheckUserShifts(GetStorage box) async {
    // Reload user to ensure we have the latest user data
    var model = box.read(AppConstants.USER_INFO) ?? {};
    if(model.isNotEmpty){
      user = UserModel.fromMap(Map<String, dynamic>.from(model));
    }
    
    // Reload shifts and check for active shift belonging to this user
    List<ShiftModel> tempShiftList = loadShifts(box);
    ShiftModel? tempActiveShift = await _localStorageService.getActiveShift(tempShiftList, box, user, true);
    
    if(tempActiveShift != null) {
      print("After PIN validation: Active shift found for user ${user.userName} (ID: ${user.id}): ${tempActiveShift.shiftReference}");
      print("Shift belongs to user ID: ${tempActiveShift.userId}");
      
      // Verify the shift belongs to the current user
      if(tempActiveShift.userId != null && user.id != null && tempActiveShift.userId == user.id){
        shiftAvailable.value = true;
        print("Shift authorization confirmed: User ${user.userName} authorized for shift ${tempActiveShift.shiftReference}");
      } else {
        shiftAvailable.value = false;
        print("Shift authorization failed: Shift ${tempActiveShift.shiftReference} belongs to user ${tempActiveShift.userId}, not ${user.id}");
      }
    } else{
      shiftAvailable.value = false;
      print("After PIN validation: No active shift found for user ${user.userName} (ID: ${user.id})");
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