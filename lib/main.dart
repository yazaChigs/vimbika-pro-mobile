import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:vimbika_pos_app/src/constants/app_routes.dart';
import 'package:vimbika_pos_app/src/services/background_service.dart';
import 'package:vimbika_pos_app/src/services/http_overrides.dart';
import 'package:vimbika_pos_app/src/services/nfc_service.dart';
import 'package:vimbika_pos_app/src/theme/theme.dart';
import 'package:vimbika_pos_app/src/utils/app_pages.dart';

import 'src/constants/app_constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global =
      MyHttpOverrides(); //CERTIFICATE_VERIFY_FAILED: unable to get local issuer certificate(handshake.cc:393))
  await GetStorage.init();

  // Initialize services
  Get.put(NfcService());

  //Get.put(BackgroundService());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    GetStorage storage = GetStorage();
    var isAuthenticated = storage.read(AppConstants.IS_AUTHENTICATED) ?? false;

    // Initialize NFC check on app startup
    _initializeNfcCheck();

    return GetMaterialApp(
      title: 'Vimbika POS',
      themeMode: ThemeMode.system,
      theme: TAppTheme.lightTheme,
      darkTheme: TAppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      defaultTransition: Transition.leftToRightWithFade,
      transitionDuration: const Duration(milliseconds: 500),
      getPages: AppPages.routes,
      initialRoute: isAuthenticated ? AppRoutes.ENTER_PIN : AppRoutes.LOGIN,
    );
  }

  // Initialize NFC check on app startup
  void _initializeNfcCheck() {
    GetStorage storage = GetStorage();
    bool useNFC  = storage.read(AppConstants.USE_NFC) ?? false;
    // Delay the NFC check to allow app to load first
    if(useNFC)
    Future.delayed(Duration(seconds: 2), () async {
      try {
        final nfcService = Get.find<NfcService>();
        await nfcService.checkNfcOnStartup();
      } catch (e) {
        // Handle NFC check errors silently
        print('NFC startup check error: $e');
      }
    });
  }
}
