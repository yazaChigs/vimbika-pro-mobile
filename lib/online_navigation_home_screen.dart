import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:vimbika_pro/custom_drawer/drawer_user_controller.dart';
import 'package:vimbika_pro/custom_drawer/home_drawer.dart';
import 'package:vimbika_pro/home_screen.dart';
import 'package:vimbika_pro/screens/online/online_reports_screen.dart';
import 'package:vimbika_pro/screens/offline/settings/settings_screen.dart';
import 'package:flutter/material.dart';

class OnlineNavigationHomeScreen extends StatefulWidget {
  final bool isOnline;
  const OnlineNavigationHomeScreen({super.key, this.isOnline = false});

  @override
  State<OnlineNavigationHomeScreen> createState() => _OnlineNavigationHomeScreenState();
}

class _OnlineNavigationHomeScreenState extends State<OnlineNavigationHomeScreen> {
  Widget? screenView;
  DrawerIndex? drawerIndex;

  @override
  void initState() {
    drawerIndex = DrawerIndex.home;
    screenView = const MyHomePage();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.white,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Scaffold(
          backgroundColor: AppTheme.nearlyWhite,
          body: DrawerUserController(
            screenIndex: drawerIndex,
            drawerWidth: MediaQuery.of(context).size.width * 0.75,
            onDrawerCall: (DrawerIndex drawerIndexdata) {
              changeIndex(drawerIndexdata);
            },
            screenView: screenView,
          ),
        ),
      ),
    );
  }

  void changeIndex(DrawerIndex drawerIndexdata) {
    if (drawerIndex != drawerIndexdata) {
      drawerIndex = drawerIndexdata;
      switch (drawerIndex) {
        case DrawerIndex.home:
          setState(() {
            screenView = const MyHomePage();
          });
          break;
        case DrawerIndex.reports:
          setState(() {
            screenView = const OnlineReportsScreen();
          });
          break;
        case DrawerIndex.settings:
          setState(() {
            screenView = SettingsScreen();
          });
          break;
        default:
          setState(() {
            screenView = const MyHomePage();
          });
          break;
      }
    }
  }
}
