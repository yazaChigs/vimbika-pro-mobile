import 'dart:convert';
import 'package:vimbika_pro/model/user.dart';
import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:vimbika_pro/app_constants/app_constants.dart';
import 'package:vimbika_pro/screens/online/online_reports_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vimbika_pro/services/sale_sync_service.dart';
import 'login/login_screen.dart';
import 'model/homelist.dart';
import 'package:vimbika_pro/services/default_data_service.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  List<HomeList> homeList = [];
  AnimationController? animationController;
  bool multiple = true;
  bool _isOfflineMode = true;

  @override
  void initState() {
    SaleSyncService().startSyncTimer();
    animationController = AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this);
    super.initState();
    _loadModeAndData();
  }

  Future<void> _loadModeAndData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool isOfflineMode = prefs.getBool(AppConstants.keyIsOfflineMode) ?? true;


    // Check for subscription days remaining
    final int? daysRemaining = prefs.getInt(AppConstants.keySubscriptionDaysRemaining);
    if (daysRemaining != null && daysRemaining <= 5 && daysRemaining > 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "Your subscription will expire in $daysRemaining days. Please renew to avoid service interruption."),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 10),
          ),
        );
      }
    }
    else if(daysRemaining != null && daysRemaining < 1 ){
      // Logout if subscription has expired
      String usersKey = isOfflineMode ? AppConstants.keyOfflineUserData : AppConstants.keyOnlineUserData;
      await prefs.remove(usersKey); // Clear user data
      await prefs.remove(AppConstants.keySubscriptionDaysRemaining); // Clear subscription days remaining
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Your subscription has expired. Please log in again."),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()), // Navigate to login screen
        );
      }
      return; // Stop further processing if logged out
    }
    
    // User role check
    final String? userDataJson = prefs.getString(AppConstants.keyOnlineUserData);
    User? currentUser;
    if (userDataJson != null) {
      currentUser = User.fromJson(jsonDecode(userDataJson));
    }
    
    final bool isSuperAdmin = currentUser?.userRoles?.any((role) => role.name == 'ROLE_SUPER_ADMIN') ?? false;

    if (mounted) {
      setState(() {
        _isOfflineMode = isOfflineMode;
        
        List<HomeList> allItems = List.from(HomeList.homeList);
        if (!_isOfflineMode) {
          // Hide Inventory, Expenses, and Purchases when in online mode
          allItems.removeWhere((item) => 
            item.title.toLowerCase() == 'inventory' ||
            item.title.toLowerCase() == 'expenses' ||
            item.title.toLowerCase() == 'purchases');
          
          // Change Reports navigation to OnlineReportsScreen
          int reportsIndex = allItems.indexWhere((item) => item.title.toLowerCase() == 'reports');
          if (reportsIndex != -1) {
            allItems[reportsIndex].navigateScreen = const OnlineReportsScreen();
          }

          // Conditionally remove reports if not super admin
          if (!isSuperAdmin) {
            allItems.removeWhere((item) => item.title.toLowerCase() == 'reports');
          }
        }
        homeList = allItems;
      });
    }
  }

  Future<bool> getData() async {
    await Future<dynamic>.delayed(const Duration(milliseconds: 0));
    return true;
  }

  @override
  void dispose() {
    animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var brightness = MediaQuery.of(context).platformBrightness;
    bool isLightMode = brightness == Brightness.light;
    return Scaffold(
      backgroundColor:
          isLightMode == true ? AppTheme.white : AppTheme.nearlyBlack,
      body: FutureBuilder<bool>(
        future: getData(),
        builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
          if (!snapshot.hasData || homeList.isEmpty) {
            return const SizedBox();
          } else {
            return Padding(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  appBar(),
                  Expanded(
                    child: FutureBuilder<bool>(
                      future: getData(),
                      builder:
                          (BuildContext context, AsyncSnapshot<bool> snapshot) {
                        if (!snapshot.hasData) {
                          return const SizedBox();
                        } else {
                          return GridView(
                            padding: const EdgeInsets.only(
                                top: 0, left: 12, right: 12),
                            physics: const BouncingScrollPhysics(),
                            scrollDirection: Axis.vertical,
                            children: List<Widget>.generate(
                              homeList.length,
                              (int index) {
                                final int count = homeList.length;
                                final Animation<double> animation =
                                    Tween<double>(begin: 0.0, end: 1.0).animate(
                                  CurvedAnimation(
                                    parent: animationController!,
                                    curve: Interval((1 / count) * index, 1.0,
                                        curve: Curves.fastOutSlowIn),
                                  ),
                                );
                                animationController?.forward();
                                return HomeListView(
                                  animation: animation,
                                  animationController: animationController,
                                  listData: homeList[index],
                                  callBack: () {
                                    Navigator.push<dynamic>(
                                      context,
                                      MaterialPageRoute<dynamic>(
                                        builder: (BuildContext context) =>
                                            homeList[index].navigateScreen!,
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : (multiple ? 2 : 1),
                              mainAxisSpacing: 12.0,
                              crossAxisSpacing: 12.0,
                              childAspectRatio: 1.5,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget appBar() {
    var brightness = MediaQuery.of(context).platformBrightness;
    bool isLightMode = brightness == Brightness.light;
    return SizedBox(
      height: AppBar().preferredSize.height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 8),
            child: Container(
              width: AppBar().preferredSize.height - 8,
              height: AppBar().preferredSize.height - 8,
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Vimbika POS',
                  style: TextStyle(
                    fontSize: 22,
                    color: isLightMode ? AppTheme.darkText : AppTheme.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8, right: 8),
            child: Container(
              width: AppBar().preferredSize.height - 8,
              height: AppBar().preferredSize.height - 8,
              color: isLightMode ? Colors.white : AppTheme.nearlyBlack,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius:
                      BorderRadius.circular(AppBar().preferredSize.height),
                  child: Icon(
                    multiple ? Icons.dashboard : Icons.view_agenda,
                    color: isLightMode ? AppTheme.darkGrey : AppTheme.white,
                  ),
                  onTap: () {
                    setState(() {
                      multiple = !multiple;
                    });
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeListView extends StatelessWidget {
  const HomeListView(
      {Key? key,
      this.listData,
      this.callBack,
      this.animationController,
      this.animation})
      : super(key: key);

  final HomeList? listData;
  final VoidCallback? callBack;
  final AnimationController? animationController;
  final Animation<double>? animation;

  IconData _getIconForTitle(String title) {
    switch (title.toLowerCase()) {
      case 'inventory':
        return Icons.inventory_2;
      case 'pos':
        return Icons.point_of_sale;
      case 'sales':
        return Icons.trending_up;
      case 'purchases':
        return Icons.shopping_cart;
      case 'expenses':
        return Icons.money_off_rounded;
      case 'reports':
        return Icons.bar_chart_rounded;
      case 'customers':
        return Icons.people;
      case 'settings':
        return Icons.settings;
      case 'shifts': // Added case for 'Shifts'
        return Icons.access_time; // Example icon for shifts
      default:
        return Icons.apps;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController!,
      builder: (BuildContext context, Widget? child) {
        return FadeTransition(
          opacity: animation!,
          child: Transform(
            transform: Matrix4.translationValues(
                0.0, 50 * (1.0 - animation!.value), 0.0),
            child: AspectRatio(
              aspectRatio: 1.5,
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(12.0)),
                child: Stack(
                  alignment: AlignmentDirectional.center,
                  children: <Widget>[
                    Positioned.fill(
                      child: listData!.imagePath.isNotEmpty 
                        ? Image.asset(
                            listData!.imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: AppTheme.vimbikaBlue.withAlpha(25),
                              child: Icon(
                                _getIconForTitle(listData!.title),
                                size: 48,
                                color: AppTheme.vimbikaBlue,
                              ),
                            ),
                          )
                        : Container(
                            color: AppTheme.vimbikaBlue.withAlpha(25),
                            child: Icon(
                              _getIconForTitle(listData!.title),
                              size: 48,
                              color: AppTheme.vimbikaBlue,
                            ),
                          ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Text(
                        listData!.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        splashColor: Colors.grey.withOpacity(0.2),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(12.0)),
                        onTap: callBack,
                      ),
                    ),
                  ],
                ),
                ),
            ),
          ),
        );
      },
    );
  }
}
