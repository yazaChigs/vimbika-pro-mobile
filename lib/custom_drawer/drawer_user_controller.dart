import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:vimbika_pro/custom_drawer/home_drawer.dart';
import 'package:flutter/material.dart';

// Define a GlobalKey for DrawerUserControllerState
final GlobalKey<_DrawerUserControllerState> drawerUserControllerKey = GlobalKey<_DrawerUserControllerState>();

class DrawerUserController extends StatefulWidget {
  const DrawerUserController({
    Key? key,
    this.drawerWidth = 250,
    this.onDrawerCall,
    this.screenView,
    this.drawerIsOpen,
    this.screenIndex,
  }) : super(key: key);

  final double drawerWidth;
  final Function(DrawerIndex)? onDrawerCall;
  final Widget? screenView;
  final Function(bool)? drawerIsOpen;
  final DrawerIndex? screenIndex;

  @override
  _DrawerUserControllerState createState() => _DrawerUserControllerState();
}

class _DrawerUserControllerState extends State<DrawerUserController>
    with TickerProviderStateMixin {
  ScrollController? scrollController;
  AnimationController? iconAnimationController;
  AnimationController? animationController;

  double scrolloffset = 0.0;

  @override
  void initState() {
    animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    iconAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 0),
    );
    iconAnimationController?..animateTo(
      1.0,
      duration: const Duration(milliseconds: 0),
      curve: Curves.fastOutSlowIn,
    );
    scrollController = ScrollController(
      initialScrollOffset: widget.drawerWidth,
    );
    scrollController!..addListener(() {
      if (scrollController!.offset <= 0) { // Drawer is open
        if (scrolloffset != 1.0) {
          setState(() {
            scrolloffset = 1.0;
            try {
              widget.drawerIsOpen!(true);
            } catch (_) {}
          });
        }
        iconAnimationController?.animateTo(
          0.0,
          duration: const Duration(milliseconds: 0),
          curve: Curves.fastOutSlowIn,
        );
      } else if (scrollController!.offset > 0 &&
          scrollController!.offset < widget.drawerWidth.floor()) { // Drawer is partially open/closing
        iconAnimationController?.animateTo(
          (scrollController!.offset * 100 / (widget.drawerWidth)) / 100,
          duration: const Duration(milliseconds: 0),
          curve: Curves.fastOutSlowIn,
        );
      } else { // Drawer is closed
        if (scrolloffset != 0.0) {
          setState(() {
            scrolloffset = 0.0;
            try {
              widget.drawerIsOpen!(false);
            } catch (_) {}
          });
        }
        iconAnimationController?.animateTo(
          1.0,
          duration: const Duration(milliseconds: 0),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => getInitState());
    super.initState();
  }

  Future<bool> getInitState() async {
    scrollController?.jumpTo(widget.drawerWidth);
    return true;
  }

  // Public method to toggle the drawer
  Future<void> toggleDrawer() async {
    if (scrollController!.offset != 0.0) { // Drawer is closed, animate to open
      await scrollController?.animateTo(
        0.0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.fastOutSlowIn,
      );
    } else { // Drawer is open, animate to close
      await scrollController?.animateTo(
        widget.drawerWidth,
        duration: const Duration(milliseconds: 400),
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var brightness = MediaQuery.of(context).platformBrightness;
    bool isLightMode = brightness == Brightness.light;
    return Scaffold(
      backgroundColor: isLightMode ? AppTheme.white : AppTheme.nearlyBlack,
      body: SingleChildScrollView(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        physics: const PageScrollPhysics(parent: ClampingScrollPhysics()),
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width + widget.drawerWidth,
          child: Row(
            children: <Widget>[
              SizedBox(
                width: widget.drawerWidth,
                height: MediaQuery.of(context).size.height,
                child: AnimatedBuilder(
                  animation: iconAnimationController!,
                  builder: (BuildContext context, Widget? child) {
                    return Transform(
                      transform: Matrix4.translationValues(
                        scrollController!.offset,
                        0.0,
                        0.0,
                      ),
                      child: HomeDrawer(
                        screenIndex: widget.screenIndex == null
                            ? DrawerIndex.home
                            : widget.screenIndex,
                        iconAnimationController: iconAnimationController,
                        callBackIndex: (DrawerIndex indexType) async {
                          await toggleDrawer(); // Call the public toggleDrawer
                          widget.onDrawerCall!(indexType);
                        },
                      ),
                    );
                  },
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: AppTheme.grey.withOpacity(0.6),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: <Widget>[
                      // Corrected IgnorePointer logic: ignore when drawer is OPEN (scrolloffset == 1.0)
                      IgnorePointer(
                        ignoring: scrolloffset == 1.0,
                        child: widget.screenView,
                      ),
                      // Overlay to close the drawer by tapping outside, only visible when drawer is OPEN
                      if (scrolloffset == 1.0)
                        InkWell(
                          onTap: () {
                            toggleDrawer(); // Call the public toggleDrawer
                          },
                        ),
                      // REMOVED THE INTERFERING DRAWER ICON FROM HERE
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
