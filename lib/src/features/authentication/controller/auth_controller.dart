import 'dart:convert';
import 'dart:io';
import 'dart:ui';


import 'package:flutter/material.dart';
import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:presentation_displays/displays_manager.dart';
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

import '../../../rear/sunmi_binding.dart';
import '../../../rear/sunmi_controller.dart';
import '../../../rear/sunmi_lcd_screen.dart';
import '../../../services/customer_display.dart';
import '../../../services/printer_service.dart';
import '../../../utils/app_pages.dart';
import '../../printers/controller/printer_settings_controller.dart';
import '../../sale/model/cart_item_model.dart';



class AuthController extends GetxController {
  final ConnectivityService _connectivityService = ConnectivityService();

  final GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();
  var greeting = ''.obs;
  late GetStorage box;
  // Only use DisplayManager on non-Windows platforms
  DisplayManager? display = Platform.isWindows ? null : DisplayManager();

 /* @pragma('vm:entry-point')
  void secondaryDisplayMain() {
    runApp(const MySecondApp());
  }
*/

  final SunmiController saleController = Get.put(SunmiController());

  RxBool isPasswordVisible = true.obs;
  var isInternetAccess = false.obs;
  var isServerAccessible = false.obs;
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
    // Only use display manager on non-Windows platforms
    if (display != null) {
      try {
        var displays = await display!.getDisplays();
        if(displays!.length>1) {
          display!.showSecondaryDisplay(
            displayId: 1,
            routerName: AppRoutes.SUNMI_LCD,
          );
          List<CartItemModel> cartItems = [];
          final cartData = {
            'companyName': "VIMBIKA POS",
            'total': 00.00,
            'items': cartItems,
          };
          await display!.transferDataToPresentation(cartData);
        }
      } catch (e) {
        // Handle display manager errors gracefully
        print('Display manager error: $e');
      }
    }

    isServerAccessible.value =  await _connectivityService.checkServerConnection();
    isInternetAccess.value = await _connectivityService.checkInternetConnection();
    
    // Only initialize Sunmi printer on Android platforms
    bool? result = false;
    if (!Platform.isWindows) {
      try {
        result = await SunmiPrinter.bindingPrinter();
        result = result ?? false;
      } catch (e) {
        print('Sunmi printer error: $e');
        result = false;
      }
    }


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

/*    final html = '''
              <html>
                <body style="font-family:sans-serif;text-align:center;">
                  <h2>🛒 Sale in Progress</h2>
                  <p>2x Cappuccino</p>
                  <h3>Total: \$5.60</h3>
                </body>
              </html>
              ''';
    CustomerDisplay.updateDisplay(html);
    print("canPrintToDisplay");
    bool canPrintToDisplay = await _printerService.initializeSunmiLCD();
    print("canPrintToDisplay: ${canPrintToDisplay}");
    if(canPrintToDisplay){
      await _printerService.sendTextToLCD();
    }
    saleController.displayWelcome();*/

    // Get.to(SunmiLcdScreen(), binding: SunmiBinding());


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
        // Normalize username comparison (remove whitespace) to match online login behavior
        String normalizedEnteredUserName = userName.removeAllWhitespace;
        String normalizedStoredUserName = (user.userName ?? "").removeAllWhitespace;
        if(normalizedStoredUserName == normalizedEnteredUserName && password == pass){
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

class MySecondApp extends StatelessWidget {
  const MySecondApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      // onGenerateRoute: generateRoute,
      getPages: AppPages.routes,
      initialRoute: AppRoutes.SUNMI_LCD,
    );
  }
}