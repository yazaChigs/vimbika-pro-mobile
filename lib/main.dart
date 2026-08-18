import 'dart:io';
import 'package:vimbika_pro/services/company_service.dart';
import 'package:vimbika_pro/model/company.dart';
import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:vimbika_pro/app_constants/app_constants.dart';
import 'package:vimbika_pro/online_navigation_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'login/login_screen.dart';
import 'create_company_screen.dart';
import 'navigation_home_screen.dart';
import 'model/user_role.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:vimbika_pro/services/sale_sync_service.dart'; // Import Sync Service

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Removed explicit orientation lock to allow landscape mode
  // await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
  //   DeviceOrientation.portraitUp,
  //   DeviceOrientation.portraitDown,
  // ]);
  
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  
  // Initialize default roles if they don't exist
  await _initializeDefaultRoles(prefs);

  runApp(const MyApp(hasUser: false, hasCompany: false,));
}

Future<void> _initializeDefaultRoles(SharedPreferences prefs) async {
  if (!prefs.containsKey(AppConstants.keyUserRoles)) {
    final List<UserRole> defaultRoles = [
      UserRole(name: 'ROLE_SUPER_ADMIN', description: 'Full system access'),
      UserRole(name: 'ROLE_SALES', description: 'Sales and inventory access'),
    ];

    final List<String> rolesJson = defaultRoles
        .map((role) => jsonEncode(role.toJson()))
        .toList();
    
    await prefs.setStringList(AppConstants.keyUserRoles, rolesJson);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key, required bool hasUser, required bool hasCompany}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: !kIsWeb && Platform.isAndroid
            ? Brightness.dark
            : Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    return MaterialApp(
      navigatorKey: AppConstants.navigatorKey,
      title: 'Vimbika POS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: AppTheme.textTheme,
        platform: TargetPlatform.iOS,
        dividerTheme: const DividerThemeData(color: Color(0xFFE0E0E0)),
      ),
      home: const InitialRouteHandler(),
    );
  }
}

class InitialRouteHandler extends StatefulWidget {
  const InitialRouteHandler({super.key});

  @override
  State<InitialRouteHandler> createState() => _InitialRouteHandlerState();
}

class _InitialRouteHandlerState extends State<InitialRouteHandler> {
  @override
  void initState() {
    super.initState();
    _checkInitialRoute();
  }

  Future<void> _checkInitialRoute() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool isOffline = prefs.getBool(AppConstants.keyIsOfflineMode) ?? true;
    final Company? company = await CompanyService().getCompany();
    final bool hasCompany = company != null;
    final bool hasUser = prefs.getBool(AppConstants.keyHasUser) ?? false;
    final bool hasLoggedIn = prefs.getBool(AppConstants.keyHasLoggedIn) ?? false;

    if (!mounted) return;

    if (hasUser && hasLoggedIn) {
      // Navigate to their last used home screen (Online vs Offline)
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(
          builder: (context) => isOffline 
              ? NavigationHomeScreen() 
              : const OnlineNavigationHomeScreen()
        )
      );
    } else {
      // Default to login screen whether company/user exists or not
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => const LoginScreen())
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class HexColor extends Color {
  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));

  static int _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF' + hexColor;
    }
    return int.parse(hexColor, radix: 16);
  }
}
