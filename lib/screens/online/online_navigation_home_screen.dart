import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:vimbika_pro/custom_drawer/drawer_user_controller.dart';
import 'package:vimbika_pro/custom_drawer/home_drawer.dart';
import 'package:vimbika_pro/screens/offline/settings/help_screen.dart';
import 'package:vimbika_pro/home_screen.dart';
import 'package:vimbika_pro/screens/offline/settings/invite_friend_screen.dart';
import 'package:vimbika_pro/screens/offline/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:vimbika_pro/screens/offline/settings/shift_management_screen.dart';

import '../offline/settings/feedback_screen.dart';

class OnlineNavigationHomeScreen extends StatefulWidget {
  const OnlineNavigationHomeScreen({super.key});

  @override
  State<OnlineNavigationHomeScreen> createState() => _OnlineNavigationHomeScreenState();
}

class _OnlineNavigationHomeScreenState extends State<OnlineNavigationHomeScreen> {
  Widget? screenView;
  DrawerIndex? drawerIndex;

  @override
  void initState() {
    drawerIndex = DrawerIndex.home;
    // For now using MyHomePage, but you might want to create an OnlineMyHomePage
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
        case DrawerIndex.help:
          setState(() {
            screenView = HelpScreen();
          });
          break;
        case DrawerIndex.feedBack:
          setState(() {
            screenView = FeedbackScreen();
          });
          break;
        case DrawerIndex.invite:
          setState(() {
            screenView = InviteFriend();
          });
          break;
        case DrawerIndex.settings:
          setState(() {
            screenView = SettingsScreen();
          });
          break;
        case DrawerIndex.shifts:
          setState(() {
            screenView = const ShiftManagementScreen();
          });
          break;
        // Add more online-specific screens here (e.g., OnlineSalesScreen, OnlineInventoryScreen, etc.)
        default:
          break;
      }
    }
  }
}
