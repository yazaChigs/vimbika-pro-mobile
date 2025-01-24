import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:vimbika_pos_app/src/constants/app_routes.dart';
import 'package:vimbika_pos_app/src/services/background_service.dart';
import 'package:vimbika_pos_app/src/services/http_overrides.dart';
import 'package:vimbika_pos_app/src/theme/theme.dart';
import 'package:vimbika_pos_app/src/utils/app_pages.dart';

import 'src/constants/app_constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides(); //CERTIFICATE_VERIFY_FAILED: unable to get local issuer certificate(handshake.cc:393))
  await GetStorage.init();
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

}

