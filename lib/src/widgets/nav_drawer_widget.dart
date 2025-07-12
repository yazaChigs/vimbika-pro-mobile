
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:vimbika_pos_app/src/constants/app_constants.dart';
import 'package:vimbika_pos_app/src/constants/app_routes.dart';
import 'package:vimbika_pos_app/src/features/authentication/model/user_model.dart';
import 'package:vimbika_pos_app/src/features/sale/controller/sale_controller.dart';
import 'package:vimbika_pos_app/src/features/shift/controller/shift_controller.dart';
import 'package:vimbika_pos_app/src/features/shift/model/shift_model.dart';
import 'package:vimbika_pos_app/src/features/stock_requests/controller/stock_request_controller.dart';
import 'package:vimbika_pos_app/src/services/background_service.dart';
import 'package:vimbika_pos_app/src/services/local_storage_service.dart';
import 'package:vimbika_pos_app/src/services/sync_service.dart';
import 'package:vimbika_pos_app/src/shared/models/company_model.dart';
class NavDrawer extends StatelessWidget {
  final String fullName;
  final String mobileNumber;
  final String nameInitials;
  const NavDrawer({
    Key? key,
    required this.fullName,
    required this.mobileNumber,
    required this.nameInitials,
  }) : super(key: key);


  @override
  Widget build(BuildContext context) {

    return Drawer(
      child: Container(
        child: ListView(
          children: [
            buildDrawerHeader(),
            const Divider(
              color: Colors.grey,
            ),
            buildDrawerItem(
                text: "Sales",
                icon: Icons.card_travel,
                tileColor: Get.currentRoute == "" ? Colors.blue : null,
                textIconColor: Get.currentRoute == "" ? Colors.white : Colors.black,
                onTap: () => navigate(0)
            ),
            buildDrawerItem(
                text: "Receipts",
                icon: Icons.money,
                tileColor: Get.currentRoute == "" ? Colors.blue : null,
                textIconColor: Get.currentRoute == "" ? Colors.white : Colors.black,
                onTap: () => navigate(1)
            ),
            buildDrawerItem(
                text: "Shift",
                icon: Icons.punch_clock,
                tileColor: Get.currentRoute == "" ? Colors.blue : null,
                textIconColor: Get.currentRoute == "" ? Colors.white : Colors.black,
                onTap: () => navigate(2)
            ),
            buildDrawerItem(
                text: "Customers",
                icon: Icons.person_search,
                tileColor: Get.currentRoute == "" ? Colors.blue : null,
                textIconColor: Get.currentRoute == "" ? Colors.white : Colors.black,
                onTap: () => navigate(3)
            ),
            buildDrawerItem(
                text: "Requisition",
                icon: Icons.fire_truck,
                tileColor: Get.currentRoute == "" ? Colors.blue : null,
                textIconColor: Get.currentRoute == "" ? Colors.white : Colors.black,
                onTap: () => navigate(4)
            ),
            buildDrawerItem(
                text: "Settings",
                icon: Icons.settings,
                tileColor: Get.currentRoute == "" ? Colors.blue : null,
                textIconColor: Get.currentRoute == "" ? Colors.white : Colors.black,
                onTap: () => navigate(5)
            ),



            buildDrawerItem(
                text: "Logout",
                icon: Icons.logout,
                tileColor: Get.currentRoute == "" ? Colors.blue : null,
                textIconColor: Get.currentRoute == "" ? Colors.white : Colors.black,
                onTap: () => navigate(6)
            ),

          ],
        ),
      ),
    );
  }
  buildDrawerHeader(){
    GetStorage box = GetStorage();
    var selectedCompany = box.read(AppConstants.ACTIVE_COMPANY) ?? null;
    String? imageUrl = null;
    if(selectedCompany != null) {
      CompanyModel company = CompanyModel.fromMap(selectedCompany);
       imageUrl = "${AppConstants.VIMBIKA_BACKEND_URL}/company/logo/${company.id}";
    }
    //print(imageUrl);


    return UserAccountsDrawerHeader(
      accountName: Text(fullName),
      accountEmail: Text(mobileNumber),
      currentAccountPicture: SizedBox(
        width: 72,
        height: 72,
        child: CircleAvatar(
          backgroundImage: imageUrl !=null ? NetworkImage(imageUrl) :  AssetImage("assets/images/logo/logo.png"), // Use the backend image URL
          onBackgroundImageError: (error, stackTrace) {
            // Fallback if image fails to load
            print("error nav image");
            AssetImage("assets/images/logo/logo.png");
          },
        ),
      ),
      currentAccountPictureSize: const Size.square(72),
      otherAccountsPictures: [
        CircleAvatar(
          backgroundColor: Colors.white,
          child: Text(nameInitials),
        ),
      ],
      otherAccountsPicturesSize: const Size.square(50),
    );
  }

  // buildDrawerHeader(){
  //   String imageUrl =  "${AppConstants.VIMBIKA_BACKEND_URL}/company/logo/${companyId}";
  //   return UserAccountsDrawerHeader(
  //     accountName: Text(fullName),
  //     accountEmail: Text(mobileNumber),
  //     currentAccountPicture: const CircleAvatar(
  //       backgroundImage: AssetImage("assets/images/logo/logo.png"),
  //     ),
  //     currentAccountPictureSize: Size.square(72),
  //     otherAccountsPictures: [
  //       CircleAvatar(backgroundColor: Colors.white,
  //           child: Text(nameInitials)
  //       ),
  //
  //     ],
  //     otherAccountsPicturesSize: Size.square(50),
  //   );
  // }

  Widget buildDrawerItem({
    required String text,
    required IconData icon,
    required Color textIconColor,
    required Color? tileColor,
    required VoidCallback onTap
  }){
    return ListTile(
      leading: Icon(icon, color: textIconColor),
      title: Text(text,style: TextStyle( color: textIconColor),),
      tileColor: tileColor,
      onTap: onTap,
    );
  }
  navigate(int index) async {
    final LocalStorageService _localStorageService = LocalStorageService();
    GetStorage box = GetStorage();
    UserModel user = UserModel(id: null, firstName: "", lastName: "", userName: "");
    var model = box.read(AppConstants.USER_INFO) ?? {};
    user = UserModel.fromMap(Map<String, dynamic>.from(model));
    switch(index){
      case 0:
        // Get.toNamed(AppRoutes.SALE);
        LocalStorageService localStorageService = LocalStorageService();

        List<ShiftModel> shiftList = loadShifts(box, localStorageService);
        ShiftModel? tempActiveShift = await localStorageService.getActiveShift(shiftList, box, user, true);
        if(tempActiveShift != null) {
          Get.toNamed(AppRoutes.SALE);
        } else{
          Get.toNamed(AppRoutes.OPEN_SHIFT);
        }
        break;
      case 1:
         Get.toNamed(AppRoutes.SALE_RECEIPTS);
        break;
      case 2 :
         Get.put(ShiftController());
         LocalStorageService localStorageService = LocalStorageService();
        //GetStorage box = GetStorage();
        List<ShiftModel> shiftList = loadShifts(box, localStorageService);
        ShiftModel? tempActiveShift = await localStorageService.getActiveShift(shiftList, box, user, true);
        if(tempActiveShift != null) {
          Get.toNamed(AppRoutes.VIEW_SHIFT);
        } else{
          Get.toNamed(AppRoutes.OPEN_SHIFT);
        }
        break;
      case 3:
        Get.toNamed(AppRoutes.CUSTOMER_LIST);
      case 4:
        Get.put(StockRequestController());
        Get.toNamed(AppRoutes.STOCK_REQUESTS_MENU);
        break;
      case 5:
        Get.toNamed(AppRoutes.SETTINGS_SCREEN);
        break;
      case 6 :
       // GetStorage box = GetStorage();
        box.remove(AppConstants.CACHED_ACCESS_TOKEN);
        box.write(AppConstants.IS_AUTHENTICATED, false);
       // box.remove(AppConstants.USER_INFO);
        List<ShiftModel> tempShiftList = loadShifts(box, _localStorageService);
        ShiftModel? tempActiveShift = await _localStorageService.getActiveShift(tempShiftList, box, UserModel(firstName: "", lastName: "", userName: ""), false);
        if(tempActiveShift != null) {
          // DateTime now = DateTime.now();
          // String closingTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
          // tempActiveShift.isShiftClosed = true;
          // tempActiveShift.closingTime = closingTime;
          // List<ShiftModel> shi = _localStorageService.replaceShift(
          //     tempActiveShift, tempShiftList);
          // _localStorageService.writeItems(AppConstants.SHIFT_LIST, shi, box);
          SyncService.syncOfflineShifts(user, box);
        }
        Get.delete<SaleController>();
        Get.delete<BackgroundService>();
        Get.offNamed(AppRoutes.LOGIN);
        break;
      default:
        //Get.toNamed(AppRoutes.R_DRIVER_HOME_MAP);
    }
  }

  List<ShiftModel> loadShifts( GetStorage box, LocalStorageService localStorageService) {
    List<ShiftModel> list = localStorageService.getOfflineList<ShiftModel>(
        AppConstants.SHIFT_LIST,
            (map) => ShiftModel.fromMap(map),
        box);
    return list;
  }


}
