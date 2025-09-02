import 'package:flutter/services.dart';

class CustomerDisplay {
  static const MethodChannel _channel = MethodChannel('vimbika.pos/secondScreen');

  /// Sends HTML content to the rear display
  static Future<void> updateDisplay(String htmlContent) async {
    try {
      await _channel.invokeMethod('updateScreen', {'html': htmlContent});
    } catch (e) {
      print('Error sending to rear screen: $e');
    }
  }

  /// Resets the screen to welcome/default state
  static Future<void> resetDisplay() async {
    try {
      await _channel.invokeMethod('resetScreen');
    } catch (e) {
      print('Error resetting rear screen: $e');
    }
  }
}
