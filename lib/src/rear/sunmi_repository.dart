import 'dart:io';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';

class SunmiRepository {
  /// Binds to the Sunmi printer service. Must be called first.
  Future<bool> bindingPrinter() async {
    // Only bind on Android platforms
    if (Platform.isWindows) {
      print("Sunmi printer not available on Windows");
      return false;
    }
    
    final bool? isBound = await SunmiPrinter.bindingPrinter();
    return isBound ?? false;
  }

  /// Initializes the printer and LCD display
  Future<void> initializeHardware() async {
    // Only initialize on Android platforms
    if (Platform.isWindows) {
      print("Sunmi hardware not available on Windows");
      return;
    }
    
    await SunmiPrinter.initPrinter();
    await SunmiPrinter.lcdInitialize();
    await SunmiPrinter.lcdWakeup();
  }

  /// Sends a line of text to the LCD display
  Future<void> sendTextToLcd(String text) async {
    // Only send to LCD on Android platforms
    if (Platform.isWindows) {
      print("Sunmi LCD not available on Windows");
      return;
    }
    
    await SunmiPrinter.lcdString(text);
  }

  /// Clears the LCD display
  Future<void> clearLcd() async {
    // Only clear LCD on Android platforms
    if (Platform.isWindows) {
      return;
    }
    
    await SunmiPrinter.lcdClear();
  }

  /// Unbinds the printer service (cleanup)
  Future<void> unbindService() async {
    // Only unbind on Android platforms
    if (Platform.isWindows) {
      return;
    }
    
    await SunmiPrinter.unbindingPrinter();
  }
}