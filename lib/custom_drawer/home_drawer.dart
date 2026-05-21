import 'package:vimbika_pro/app_constants/app_constants.dart';
import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:vimbika_pro/login/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../model/user.dart';

class HomeDrawer extends StatefulWidget {
  const HomeDrawer(
      {super.key,
      this.screenIndex,
      this.iconAnimationController,
      this.callBackIndex});

  final AnimationController? iconAnimationController;
  final DrawerIndex? screenIndex;
  final Function(DrawerIndex)? callBackIndex;

  @override
  State<HomeDrawer> createState() => _HomeDrawerState();
}

class _HomeDrawerState extends State<HomeDrawer> {
  List<DrawerList>? drawerList;
  User? _currentUser;
  bool _isOfflineMode = true;
  String? _localImagePath;

  @override
  void initState() {
    super.initState();
    _loadUserDataAndMode().then((_) {
      setDrawerListArray();
    });
  }

  Future<void> _loadUserDataAndMode() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool isOfflineMode = prefs.getBool(AppConstants.keyIsOfflineMode) ?? true;
    final String userKey = !isOfflineMode ? AppConstants.keyUserData : AppConstants.keyOfflineUserData;
    final String? userData = prefs.getString(userKey);

    String? localImagePath;
    if (!isOfflineMode) {
      final directory = await getApplicationDocumentsDirectory();
      // Checking for the path used in DefaultDataService
      final path = '${directory.path}/assets/images/company_logo.png';
      if (await File(path).exists()) {
        localImagePath = path;
      } else {
        // Fallback to CompanyService path if DefaultDataService path doesn't exist
        final altPath = '${directory.path}/company_logo.png';
        if (await File(altPath).exists()) {
          localImagePath = altPath;
        }
      }
    }

    if (mounted) {
      setState(() {
        if (userData != null) {
          _currentUser = User.fromJson(jsonDecode(userData));
        }
        _isOfflineMode = isOfflineMode;
        _localImagePath = localImagePath;
      });
    }
  }

  void setDrawerListArray() {
    List<DrawerList> allDrawerItems = <DrawerList>[
      DrawerList(
        index: DrawerIndex.home,
        labelName: 'Home',
        icon: const Icon(Icons.home),
      ),
      DrawerList(
        index: DrawerIndex.pos,
        labelName: 'POS',
        icon: const Icon(Icons.point_of_sale_outlined),
      ),
      DrawerList(
        index: DrawerIndex.shifts,
        labelName: 'Shifts',
        icon: const Icon(Icons.access_time),
      ),
      DrawerList(
        index: DrawerIndex.inventory,
        labelName: 'Inventory',
        icon: const Icon(Icons.inventory_2_outlined),
      ),
      DrawerList(
        index: DrawerIndex.sales,
        labelName: 'Sales',
        icon: const Icon(Icons.receipt_long_outlined),
      ),
      DrawerList(
        index: DrawerIndex.purchases,
        labelName: 'Purchases',
        icon: const Icon(Icons.shopping_cart_outlined),
      ),
      DrawerList(
        index: DrawerIndex.expenses,
        labelName: 'Expenses',
        icon: const Icon(Icons.money_off_rounded),
      ),
      DrawerList(
        index: DrawerIndex.reports,
        labelName: 'Reports',
        icon: const Icon(Icons.bar_chart_rounded),
      ),
      DrawerList(
        index: DrawerIndex.customers,
        labelName: 'Customers',
        icon: const Icon(Icons.people_outline),
      ),
      DrawerList(
        index: DrawerIndex.suppliers,
        labelName: 'Suppliers',
        icon: const Icon(Icons.local_shipping_outlined),
      ),
      DrawerList(
        index: DrawerIndex.settings,
        labelName: 'Settings',
        icon: const Icon(Icons.settings),
      ),
    ];

    if (!_isOfflineMode) {
      // Filter out items for online mode
      allDrawerItems.removeWhere((item) => 
        item.index == DrawerIndex.inventory ||
        item.index == DrawerIndex.expenses ||
        item.index == DrawerIndex.purchases ||
        item.index == DrawerIndex.suppliers || // Added for online mode
        item.index == DrawerIndex.reports); // Added for online mode
    }

    if (mounted) {
      setState(() {
        drawerList = allDrawerItems;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var brightness = MediaQuery.of(context).platformBrightness;
    bool isLightMode = brightness == Brightness.light;
    return Scaffold(
      backgroundColor: AppTheme.notWhite.withValues(alpha: 0.5),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 40.0),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  AnimatedBuilder(
                    animation: widget.iconAnimationController!,
                    builder: (BuildContext context, Widget? child) {
                      return ScaleTransition(
                        scale: AlwaysStoppedAnimation<double>(1.0 -
                            (widget.iconAnimationController!.value) * 0.2),
                        child: RotationTransition(
                          turns: AlwaysStoppedAnimation<double>(Tween<double>(
                                      begin: 0.0, end: 24.0)
                                  .animate(CurvedAnimation(
                                      parent: widget.iconAnimationController!,
                                      curve: Curves.fastOutSlowIn))
                                  .value /
                              360),
                          child: Container(
                            height: 120,
                            width: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                    color: AppTheme.grey.withValues(alpha: 0.6),
                                    offset: const Offset(2.0, 4.0),
                                    blurRadius: 8),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(60.0)),
                              child: _localImagePath != null
                                  ? Image.file(
                                      File(_localImagePath!),
                                      fit: BoxFit.cover,
                                    )
                                  : _currentUser?.profilePicture != null
                                      ? Image.memory(
                                          base64Decode(_currentUser!.profilePicture!),
                                          fit: BoxFit.cover,
                                        )
                                      : Image.asset('assets/images/userImage.png'),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Text(
                      _currentUser?.firstName != null && _currentUser!.firstName!.isNotEmpty
                          ? '${_currentUser!.firstName} ${_currentUser!.lastName ?? ''}'
                          : (_currentUser?.userName ?? 'Guest'),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isLightMode ? AppTheme.grey : AppTheme.white,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Text(
                      _currentUser?.role ?? 'Role Not Set',
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        color: isLightMode ? AppTheme.darkText : AppTheme.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 4,
          ),
          Divider(
            height: 1,
            color: AppTheme.grey.withValues(alpha: 0.6),
          ),
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(0.0),
              itemCount: drawerList?.length ?? 0,
              itemBuilder: (BuildContext context, int index) {
                return inkwell(drawerList![index]);
              },
            ),
          ),
          Divider(
            height: 1,
            color: AppTheme.grey.withValues(alpha: 0.6),
          ),
          Column(
            children: <Widget>[
              ListTile(
                title: const Text(
                  'Sign Out',
                  style: TextStyle(
                    fontFamily: AppTheme.fontName,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppTheme.darkText,
                  ),
                  textAlign: TextAlign.left,
                ),
                trailing: const Icon(
                  Icons.power_settings_new,
                  color: Colors.red,
                ),
                onTap: () {
                  _logout(context);
                },
              ),
              SizedBox(
                height: MediaQuery.of(context).padding.bottom,
              )
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out?'),
        content: const Text('Are you sure you want to sign out of your current session?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.keyUserData);
      await prefs.setBool(AppConstants.keyHasUser, false);
      await prefs.setBool(AppConstants.keyHasLoggedIn, false); // Clear logged in status
      await prefs.setBool(AppConstants.keyIsOfflineMode, true);
      
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context, 
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    }
  }

  Widget inkwell(DrawerList listData) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        splashColor: Colors.grey.withValues(alpha: 0.1),
        highlightColor: Colors.transparent,
        onTap: () {
          navigationtoScreen(listData.index!);
        },
        child: Stack(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Row(
                children: <Widget>[
                  const SizedBox(
                    width: 6.0,
                    height: 46.0,
                  ),
                  const Padding(
                    padding: EdgeInsets.all(4.0),
                  ),
                  listData.isAssetsImage
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: Image.asset(listData.imageName,
                              color: widget.screenIndex == listData.index
                                  ? AppTheme.vimbikaBlue
                                  : AppTheme.nearlyBlack),
                        )
                      : Icon(listData.icon?.icon,
                          color: widget.screenIndex == listData.index
                              ? AppTheme.vimbikaBlue
                              : AppTheme.nearlyBlack),
                  const Padding(
                    padding: EdgeInsets.all(4.0),
                  ),
                  Text(
                    listData.labelName,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: widget.screenIndex == listData.index
                          ? Colors.black
                          : AppTheme.nearlyBlack,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ],
              ),
            ),
            widget.screenIndex == listData.index
                ? AnimatedBuilder(
                    animation: widget.iconAnimationController!,
                    builder: (BuildContext context, Widget? child) {
                      return Transform(
                        transform: Matrix4.translationValues(
                            (MediaQuery.of(context).size.width * 0.75 - 64) *
                                (1.0 -
                                    widget.iconAnimationController!.value -
                                    1.0),
                            0.0,
                            0.0),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 8),
                          child: Container(
                            width:
                                MediaQuery.of(context).size.width * 0.75 - 64,
                            height: 46,
                            decoration: BoxDecoration(
                              color: AppTheme.vimbikaBlue.withValues(alpha: 0.2),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(0),
                                topRight: Radius.circular(28),
                                bottomLeft: Radius.circular(0),
                                bottomRight: Radius.circular(28),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  )
                : const SizedBox()
          ],
        ),
      ),
    );
  }

  Future<void> navigationtoScreen(DrawerIndex indexScreen) async {
    widget.callBackIndex!(indexScreen);
  }
}

enum DrawerIndex {
  home,
  feedBack,
  help,
  share,
  about,
  invite,
  settings,
  customers,
  suppliers,
  pos,
  sales,
  inventory,
  purchases,
  expenses,
  reports,
  shifts,
  testing,
}

class DrawerList {
  DrawerList({
    this.isAssetsImage = false,
    this.labelName = '',
    this.icon,
    this.index,
    this.imageName = '',
  });

  String labelName;
  Icon? icon;
  bool isAssetsImage;
  String imageName;
  DrawerIndex? index;
}
