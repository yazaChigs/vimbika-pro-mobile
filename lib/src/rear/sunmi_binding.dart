import 'package:get/get.dart';
import 'package:vimbika_pos_app/src/rear/sunmi_controller.dart';

class SunmiBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SunmiController>(() => SunmiController(), fenix: true);
  }
}