import 'dart:async';
import 'package:get/get.dart';
import 'package:vimbika_pos_app/src/constants/app_routes.dart';
import 'package:vimbika_pos_app/src/features/authentication/screen/pin_screen.dart';

class InactivityController extends GetxController {
  Timer? _inactivityTimer;
  static const _inactivityDuration = Duration(hours: 10);

  @override
  void onInit() {
    super.onInit();
    _startInactivityTimer();
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_inactivityDuration, _onInactivity);
  }

  void _onInactivity() {
    // Navigate to the PIN screen when inactivity is detected
    Get.toNamed(AppRoutes.ENTER_PIN);
  }

  void resetInactivityTimer() {
    _startInactivityTimer();
  }

  @override
  void onClose() {
    _inactivityTimer?.cancel();
    super.onClose();
  }
}
