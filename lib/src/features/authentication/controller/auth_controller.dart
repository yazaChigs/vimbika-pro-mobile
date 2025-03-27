import 'dart:convert';
import 'dart:ui';


import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';
import 'package:vimbika_pos_app/src/constants/app_constants.dart';
import 'package:vimbika_pos_app/src/constants/app_routes.dart';
import 'package:vimbika_pos_app/src/features/authentication/model/jwt_request_model.dart';
import 'package:vimbika_pos_app/src/features/authentication/model/jwt_response_model.dart';
import 'package:vimbika_pos_app/src/features/authentication/model/user_model.dart';
import 'package:vimbika_pos_app/src/features/printers/model/available_printer_model.dart';
import 'package:vimbika_pos_app/src/services/app_exceptions.dart';
import 'package:vimbika_pos_app/src/services/base_http_client.dart';
import 'package:vimbika_pos_app/src/services/connectivity_service.dart';
import 'package:vimbika_pos_app/src/services/local_storage_service.dart';
import 'package:vimbika_pos_app/src/utils/app_helper.dart';



class AuthController extends GetxController {
  final ConnectivityService _connectivityService = ConnectivityService();

  final GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();
  var greeting = ''.obs;
  late GetStorage box;


  RxBool isPasswordVisible = true.obs;
  var isInternetAccess = false.obs;
  var isServerAccessible = false.obs;
  /// TextField Controllers to get data from TextFields
  // final TextEditingController usernameTextEditingController = TextEditingController(text: "demo@vimbika.net");
  //  final TextEditingController passwordTextEditingController = TextEditingController(text: "Demo@2024");
  // final TextEditingController usernameTextEditingController = TextEditingController(text: "yaza@totalit.org");
  // final TextEditingController passwordTextEditingController = TextEditingController(text: "ELIyaza@25");
  // final TextEditingController usernameTextEditingController = TextEditingController(text: "shop@vimbika.demo");
  // final TextEditingController passwordTextEditingController = TextEditingController(text: "pass1234");

  // final TextEditingController usernameTextEditingController = TextEditingController(text: "nyakudya@farmdistributors.co.zw");
  // final TextEditingController passwordTextEditingController = TextEditingController(text: "Nyakudya25");

// final TextEditingController usernameTextEditingController = TextEditingController(text: "user1@mash.co.zw");
//   final TextEditingController passwordTextEditingController = TextEditingController(text: "pass1234");

  // final TextEditingController usernameTextEditingController = TextEditingController(text: "shinje@farmdis.co.zw");
  // final TextEditingController passwordTextEditingController = TextEditingController(text: "VIMBIKA1014");
   final TextEditingController usernameTextEditingController = TextEditingController(text: "");
   final TextEditingController passwordTextEditingController = TextEditingController(text: "");


  var userName = '';
  var password = '';

  final LocalStorageService _localStorageService = LocalStorageService();



  @override
  Future<void> onInit() async {
    super.onInit();
    requestPermissions();
    box = GetStorage();
    updateGreeting();

    isServerAccessible.value =  await _connectivityService.checkServerConnection();
    isInternetAccess.value = await _connectivityService.checkInternetConnection();
    bool? result = await SunmiPrinter.bindingPrinter();
    result = result ?? false;


      List<AvailablePrinterModel> tempList = loadAvailablePrinters(box);
      if (tempList.isEmpty) {
        AvailablePrinterModel defaultPrinter = AvailablePrinterModel(
            id: "SUNMIPPT8525",
            name: 'Sunmi Pegasus',
            isDefault: true,
            type: 'SUNMI_INBUILT_PRINTER',
            address: null,
            productId: null,
            vendorId: null);
        AvailablePrinterModel defaultPrinter1 = AvailablePrinterModel(
            id: "TELPO",
            name: 'TELPO',
            isDefault: false,
            type: 'TELPO_INBUILT_PRINTER',
            address: null,
            productId: null,
            vendorId: null);
        tempList.add(defaultPrinter);
        tempList.add(defaultPrinter1);
        _localStorageService.writeItems(
            AppConstants.AVAILABLE_PRINTERS, tempList, box);
      }




   // //_printData(_telpoFlutterChannel);
   //  await TelpoM8().
   //  await printQRCode("https://chatgpt.com/c/6741d059-f26c-800c-b6d2-7b14022cc7dc");


  }




  List<AvailablePrinterModel> loadAvailablePrinters( GetStorage box) {
    List<AvailablePrinterModel> list = _localStorageService.getOfflineList<AvailablePrinterModel>(
        AppConstants.AVAILABLE_PRINTERS,
            (map) => AvailablePrinterModel.fromMap(map),
        box);
    return list;
  }

  void updateGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) {
      greeting.value = 'Good Morning';
    } else if (hour < 17) {
      greeting.value = 'Good Afternoon';
    } else {
      greeting.value = 'Good Evening';
    }
  }


  Future<void> authenticateUser() async {
    GetStorage box = GetStorage();
    JwtRequestModel jwtRequest = JwtRequestModel(userName: userName.removeAllWhitespace, password: password);
    var data = jwtRequest.toJson();

    isServerAccessible.value =  await _connectivityService.checkServerConnection();
    isInternetAccess.value = await _connectivityService.checkInternetConnection();

    if(isServerAccessible.value){
      AppHelper.showLoading('Authenticating user...');
      var response = await BaseHttpClient().post("/authentication", data).catchError((onError){
        AppHelper.hideLoading();
        if (onError is BadRequestException) {
          var apiError = json.decode(onError.message!);
          print(apiError);
          AppHelper.showErroDialog(description: apiError["reason"]);
        } else if (onError is UnAuthorizedException) {
          AppHelper.showErroDialog(title: "Incorrect Credentials", description: "Please check your login details");
        }
        else {
          print(onError);
          AppHelper.handleError(onError);
        }
      });
      AppHelper.hideLoading();
      if(response != null){

        final userResponseModel = JwtResponseModel.fromJson(response);

        box.write(AppConstants.CACHED_ACCESS_TOKEN, userResponseModel.token);
        box.write(AppConstants.IS_AUTHENTICATED, true);
        box.write(AppConstants.IS_USER_INITIALLY_AUTHENTICATED, true);
        box.write(AppConstants.USER_PASSWORD, password);
        userResponseModel.token = null;
        box.write(AppConstants.USER_INFO, userResponseModel.user!.toMap());
        Get.offNamed(AppRoutes.CHOOSE_BRANCH);
      } else{
        Get.snackbar("Login Failed", "Invalid credentials", snackPosition: SnackPosition.BOTTOM);
      }
    } else{
      AppHelper.hideLoading();
      var isInitialAuthenticated = box.read(AppConstants.IS_USER_INITIALLY_AUTHENTICATED) ?? false;
      if(isInitialAuthenticated){
        var userInfo = box.read(AppConstants.USER_INFO) ?? {};
        var pass = box.read(AppConstants.USER_PASSWORD) ?? "";
        UserModel user = UserModel.fromMap(Map<String, dynamic>.from(userInfo));
        if(user.userName == userName && password == pass){
          Get.offNamed(AppRoutes.CHOOSE_BRANCH);
        } else{
          Get.snackbar("Login Failed", "Incorrect Credentials", snackPosition: SnackPosition.BOTTOM);
        }

      } else{
        if(!isServerAccessible.value && isInternetAccess.value) {
          Get.snackbar("Login Failed", "Internet available but server not reachable",
              snackPosition: SnackPosition.BOTTOM);
        }
        if(!isServerAccessible.value && !isInternetAccess.value) {
          Get.snackbar("Login Failed", "No internet access and server not reachable",
              snackPosition: SnackPosition.BOTTOM);
        }
      }

    }

  }


  @override
  void onClose() {
    usernameTextEditingController.dispose();
    passwordTextEditingController.dispose();
  }

  bool checkValidation() {
    final isValid = loginFormKey.currentState!.validate();
    loginFormKey.currentState!.save();
    if (!isValid) {
      return false;
    }
    return true;
  }
  void changePasswordVisibleStatus() {

    isPasswordVisible.toggle();
    print(isPasswordVisible.value);
  }
  Future<void> requestPermissions() async {
    if (await Permission.bluetooth.isDenied || await Permission.bluetooth.isPermanentlyDenied) {
      await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ].request();
    }

    if (await Permission.bluetoothConnect.isDenied || await Permission.bluetoothConnect.isPermanentlyDenied) {
      // await Permission.bluetoothConnect.request();
      await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ].request();
    }

    if (await Permission.bluetoothScan.isDenied || await Permission.bluetoothScan.isPermanentlyDenied) {
      // await Permission.bluetoothScan.request();
      await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ].request();
    }


    if (await Permission.locationWhenInUse.isDenied) {
      await Permission.locationWhenInUse.request();
    }
  }


}