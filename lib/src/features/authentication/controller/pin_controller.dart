import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:vimbika_pos_app/src/constants/app_constants.dart';
import 'package:vimbika_pos_app/src/constants/app_routes.dart';
import 'package:vimbika_pos_app/src/features/authentication/model/user_model.dart';
import 'package:vimbika_pos_app/src/features/shift/model/shift_model.dart';
import 'package:vimbika_pos_app/src/services/connectivity_service.dart';
import 'package:vimbika_pos_app/src/services/local_storage_service.dart';
import 'package:vimbika_pos_app/src/shared/controller/inactivity_controller.dart';

class PinController extends GetxController {
  RxString enteredPin = "".obs;
  RxBool isPinVisible = false.obs;
  var shiftAvailable = false.obs;
  final LocalStorageService _localStorageService = LocalStorageService();
  final ConnectivityService _connectivityService = ConnectivityService();
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
    
    // Check if a shift has already been selected (user clicked on existing shift in modal)
    // If so, don't show the modal again - just wait for PIN entry
    final String? selectedRef = box.read(AppConstants.SELECTED_SHIFT_REF);
    if (selectedRef != null && selectedRef.isNotEmpty) {
      print("PIN Screen: Shift ${selectedRef} already selected, skipping modal - waiting for PIN entry");
      // Verify the selected shift exists and is valid
      List<ShiftModel> tempShiftList = loadShifts(box);
      final selectedShift = tempShiftList.firstWhereOrNull(
        (s) => s.shiftReference == selectedRef &&
               s.userId != null &&
               user.id != null &&
               s.userId == user.id &&
               (s.isShiftClosed == null || s.isShiftClosed == false)
      );
      if (selectedShift != null) {
        shiftAvailable.value = true;
        print("PIN Screen: Confirmed selected shift ${selectedRef} is valid");
        // Don't show modal, just wait for PIN entry
        return;
      } else {
        print("PIN Screen: Selected shift ${selectedRef} not found or invalid, clearing and showing modal");
        box.remove(AppConstants.SELECTED_SHIFT_REF);
      }
    }
    
    // Load shifts and show open-shift picker (local first, optionally server)
    List<ShiftModel> tempShiftList = loadShifts(box);
    await _maybeFetchServerShifts(box, tempShiftList); // merge server shifts if online
    
    // Reload shifts after potential server merge to ensure modal shows all available shifts
    tempShiftList = loadShifts(box);
    _showOpenShiftPicker(tempShiftList);

    // Only check for branch if no shift has been selected yet
    // If a shift is selected, the user is already past branch selection
    var selectedBranch = box.read(AppConstants.SELECTED_BRANCH) ?? null;
    if(selectedBranch == null && (selectedRef == null || selectedRef.isEmpty)){
      print("PIN Screen: No branch selected and no shift selected, navigating to branch selection");
      Get.offNamed(AppRoutes.CHOOSE_BRANCH);
    } else if (selectedBranch == null && selectedRef != null && selectedRef.isNotEmpty) {
      print("PIN Screen: Shift ${selectedRef} selected but no branch - this shouldn't happen, but continuing anyway");
    }

    box = GetStorage();
    box.write(AppConstants.SYNCING_IN_PROGRESS, false);

  }


  Future<void> _maybeFetchServerShifts(GetStorage box, List<ShiftModel> tempShiftList) async {
    // Only check server if online to avoid confusion and delays
    final bool isOnline = await _connectivityService.checkServerConnection();
    if (!isOnline) {
      print("Offline: Skipping server shift check, using local shifts only");
      return;
    }
    
    try {
      print("Online: Checking server for open shifts");
      ShiftModel? serverShift = await _localStorageService.getActiveShift(tempShiftList, box, user, true);
      if (serverShift != null) {
        print("Active Shift Found (server): ${serverShift.shiftReference}");
        // If newly added, tempShiftList already updated via writeItems in getActiveShift
      }
    } catch (e) {
      print("Error checking server for shift: $e");
    }
  }

  void _showOpenShiftPicker(List<ShiftModel> allShifts) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final GetStorage box = GetStorage();
      final List<ShiftModel> openShifts = allShifts.where((s) =>
        s.userId != null &&
        user.id != null &&
        s.userId == user.id &&
        (s.isShiftClosed == null || s.isShiftClosed == false)
      ).toList();

      if (openShifts.isEmpty) {
        // No open shifts: proceed to open shift flow
        shiftAvailable.value = false;
        return;
      }

      Get.defaultDialog(
        title: "Select Open Shift",
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...openShifts.map((shift) {
                final openingTime = DateTime.tryParse(shift.openingTime ?? "") ?? DateTime.now();
                return ListTile(
                  title: Text("Shift ${shift.shiftReference ?? ''}"),
                  subtitle: Text("Opened: $openingTime"),
                  onTap: () {
                    // Mark selected shift
                    _persistSelectedShift(shift, allShifts, box);
                    shiftAvailable.value = true;
                    Get.back();
                    print("Selected existing shift ${shift.shiftReference} - waiting for PIN validation");
                    // Note: Navigation will happen after PIN validation in onNumberEntered -> startSelling()
                  },
                );
              }).toList(),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text("Open New Shift"),
                onTap: () {
                  // Clear selected ref so new shift flow can run
                  box.remove(AppConstants.SELECTED_SHIFT_REF);
                  shiftAvailable.value = false;
                  Get.back();
                  Get.offNamed(AppRoutes.OPEN_SHIFT);
                },
              ),
            ],
          ),
        ),
        barrierDismissible: false,
      );
    });
  }

  void _persistSelectedShift(ShiftModel selected, List<ShiftModel> allShifts, GetStorage box) {
    print("_persistSelectedShift: Persisting shift ${selected.shiftReference} for user ${user.userName}");
    
    // Mark selected as active, keep others unchanged (they may remain open)
    for (var i = 0; i < allShifts.length; i++) {
      if (allShifts[i].shiftReference == selected.shiftReference) {
        allShifts[i].active = true;
        allShifts[i].isShiftClosed = false;
        print("_persistSelectedShift: Marked shift ${allShifts[i].shiftReference} as active");
      }
    }
    // Persist list and the selected ref
    _localStorageService.writeItems(AppConstants.SHIFT_LIST, allShifts, box);
    box.write(AppConstants.SELECTED_SHIFT_REF, selected.shiftReference);
    print("_persistSelectedShift: Set SELECTED_SHIFT_REF to ${selected.shiftReference} and persisted ${allShifts.length} shifts");
    
    // Verify the shift was saved correctly
    final String? savedRef = box.read(AppConstants.SELECTED_SHIFT_REF);
    print("_persistSelectedShift: Verification - SELECTED_SHIFT_REF in storage is: $savedRef");
  }

  Future<void> onNumberEntered(int number) async {
    if (enteredPin.value.length < 6) {
      enteredPin.value += number.toString();
      await validatePin();
    }
  }

  Future<void> validatePin() async {
    // Only check PIN when 6 digits are entered (or if user has a PIN shorter than 6)
    int pinLength = user.pin?.length ?? 4;
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

  // Re-check shifts for the current user to ensure they only access their own shifts
  Future<void> _recheckUserShifts(GetStorage box) async {
    // Reload user to ensure we have the latest user data
    var model = box.read(AppConstants.USER_INFO) ?? {};
    if(model.isNotEmpty){
      user = UserModel.fromMap(Map<String, dynamic>.from(model));
    }
    
    // Check connectivity to determine if we should check server
    final bool isOnline = await _connectivityService.checkServerConnection();
    
    // Check if a shift was explicitly selected (e.g., from modal)
    final String? selectedRef = box.read(AppConstants.SELECTED_SHIFT_REF);
    
    // Reload shifts and check for active shift belonging to this user
    List<ShiftModel> tempShiftList = loadShifts(box);
    print("After PIN validation: Loaded ${tempShiftList.length} shifts from storage");
    
    ShiftModel? tempActiveShift;
    
    // If a shift was explicitly selected, prioritize finding that specific shift
    if (selectedRef != null && selectedRef.isNotEmpty) {
      print("After PIN validation: Looking for explicitly selected shift: $selectedRef (${isOnline ? 'Online' : 'Offline'})");
      print("After PIN validation: Available shift references: ${tempShiftList.map((s) => s.shiftReference).join(', ')}");
      tempActiveShift = tempShiftList.firstWhere(
        (cur) => cur.shiftReference == selectedRef &&
                 cur.userId != null &&
                 user.id != null &&
                 cur.userId == user.id &&
                 (cur.isShiftClosed == null || cur.isShiftClosed == false),
        orElse: () => ShiftModel(),
      );
      
      // If found, verify and use it; otherwise fall back to getActiveShift
      if (tempActiveShift.shiftReference != null) {
        // Double-check: verify the shift belongs to the current user
        if (tempActiveShift.userId != null && user.id != null && tempActiveShift.userId == user.id) {
          print("After PIN validation: Found and verified selected shift ${tempActiveShift.shiftReference} for user ${user.userName} (${isOnline ? 'Online' : 'Offline'})");
          shiftAvailable.value = true;
          // Don't return early - let the flow continue to startSelling()
          return;
        } else {
          print("After PIN validation: Selected shift $selectedRef found but belongs to different user (${tempActiveShift.userId} vs ${user.id})");
          // Clear invalid selected ref
          box.remove(AppConstants.SELECTED_SHIFT_REF);
          tempActiveShift = null;
        }
      } else {
        print("After PIN validation: Selected shift $selectedRef not found in local list (loaded ${tempShiftList.length} shifts), trying getActiveShift");
        // Don't clear SELECTED_SHIFT_REF yet - let getActiveShift try to find it (it will reload from storage)
        // If getActiveShift also fails, it will handle clearing
      }
    }
    
    // If no explicit selection or selected shift not found, use standard getActiveShift
    // Only check server if online to avoid confusion and delays when offline
    final bool shouldCheckServer = isOnline;
    print("After PIN validation: Using getActiveShift (${shouldCheckServer ? 'will check server' : 'local only'})");
    tempActiveShift = await _localStorageService.getActiveShift(tempShiftList, box, user, shouldCheckServer);
    
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