import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';

class SunmiRepository {
  /// Binds to the Sunmi printer service. Must be called first.
  Future<bool> bindingPrinter() async {
    final bool? isBound = await SunmiPrinter.bindingPrinter();
    return isBound ?? false;
  }

  /// Initializes the printer and LCD display
  Future<void> initializeHardware() async {
    await SunmiPrinter.initPrinter();
    await SunmiPrinter.lcdInitialize();
    await SunmiPrinter.lcdWakeup();
  }

  /// Sends a line of text to the LCD display
  Future<void> sendTextToLcd(String text) async {
    await SunmiPrinter.lcdString(text);
  }

  /// Clears the LCD display
  Future<void> clearLcd() async {
    await SunmiPrinter.lcdClear();
  }

  /// Unbinds the printer service (cleanup)
  Future<void> unbindService() async {
    await SunmiPrinter.unbindingPrinter();
  }
}