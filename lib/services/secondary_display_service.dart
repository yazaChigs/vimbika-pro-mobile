import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_presentation_display/flutter_presentation_display.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';
import 'package:vimbika_pro/app_constants/app_constants.dart';
import 'package:vimbika_pro/model/company.dart';
import 'package:vimbika_pro/model/sale_item.dart';
import 'package:vimbika_pro/services/company_service.dart';

class SecondaryDisplayService {
  SecondaryDisplayService._internal();
  static final SecondaryDisplayService instance = SecondaryDisplayService._internal();

  FlutterPresentationDisplay? _displayManager;
  bool _isSecondaryDisplayAvailable = false;
  bool _isShowingSecondaryDisplay = false;

  bool get isSupported => !kIsWeb && Platform.isAndroid;
  bool get isSecondaryDisplayAvailable => _isSecondaryDisplayAvailable;
  bool get isShowingSecondaryDisplay => _isShowingSecondaryDisplay;

  FlutterPresentationDisplay? get displayManager {
    if (!isSupported) return null;
    _displayManager ??= FlutterPresentationDisplay();
    return _displayManager;
  }

  /// Initialize and detect secondary displays
  Future<bool> initializeSecondaryDisplay({String routerName = '/sunmi_lcd'}) async {
    if (!isSupported) return false;

    try {
      final manager = displayManager;
      if (manager == null) return false;

      final displays = await manager.getDisplays();
      if (displays != null && displays.length > 1) {
        _isSecondaryDisplayAvailable = true;
        await manager.showSecondaryDisplay(
          displayId: 1,
          routerName: routerName,
        );
        _isShowingSecondaryDisplay = true;

        // Send initial company/welcome state
        await showWelcomeScreen();
        return true;
      } else {
        _isSecondaryDisplayAvailable = false;
        _isShowingSecondaryDisplay = false;
      }
    } catch (e) {
      debugPrint('SecondaryDisplayService initialize error: $e');
      _isSecondaryDisplayAvailable = false;
      _isShowingSecondaryDisplay = false;
    }
    return false;
  }

  /// Send cart updates to the secondary presentation display
  Future<void> updateCart({
    required List<SaleItem> cartItems,
    required double total,
    required String currency,
    double change = 0.0,
    double subtotal = 0.0,
    double tax = 0.0,
    double discount = 0.0,
    String? statusMessage,
    String? companyName,
    String? logoUrl,
  }) async {
    if (!isSupported) return;

    try {
      final manager = displayManager;
      if (manager == null) return;

      Company? company;
      try {
        company = await CompanyService().getCompany();
      } catch (_) {}

      final resolvedCompanyName = companyName ?? company?.name ?? AppConstants.appName;
      final resolvedLogoUrl = logoUrl ??
          (company?.id != null
              ? '${AppConstants.VIMBIKA_BACKEND_URL}/company/logo/${company!.id}'
              : null);

      final formattedItems = cartItems.map((item) {
        final name = item.inventoryItem.value?.name ?? 'Item';
        final qty = item.quantity;
        final unitPrice = item.sellingPrice;
        final lineTotal = item.total;
        return {
          'name': name,
          'quantity': qty,
          'price': unitPrice,
          'total': lineTotal,
          'description': '$name x${qty.toStringAsFixed(qty.truncateToDouble() == qty ? 0 : 2)} - \$${lineTotal.toStringAsFixed(2)}',
        };
      }).toList();

      final double totalQty = cartItems.fold(0.0, (sum, item) => sum + item.quantity);

      final payload = {
        'companyName': resolvedCompanyName,
        'imageUrl': resolvedLogoUrl ?? '',
        'currency': currency,
        'total': total,
        'subtotal': subtotal,
        'tax': tax,
        'discount': discount,
        'change': change,
        'numberOfItems': totalQty,
        'items': formattedItems,
        'statusMessage': statusMessage ?? (cartItems.isEmpty ? 'Welcome!' : 'Serving Customer'),
      };

      await manager.transferDataToPresentation(payload);

      // Also send basic text updates to Sunmi hardware LCD if supported
      await _updateSunmiHardwareLcd(
        cartItems: cartItems,
        total: total,
        currency: currency,
      );
    } catch (e) {
      debugPrint('SecondaryDisplayService updateCart error: $e');
    }
  }

  /// Show default welcome screen on secondary display
  Future<void> showWelcomeScreen({String? companyName, String? logoUrl}) async {
    if (!isSupported) return;

    try {
      final manager = displayManager;
      if (manager == null) return;

      Company? company;
      try {
        company = await CompanyService().getCompany();
      } catch (_) {}

      final resolvedCompanyName = companyName ?? company?.name ?? AppConstants.appName;
      final resolvedLogoUrl = logoUrl ??
          (company?.id != null
              ? '${AppConstants.VIMBIKA_BACKEND_URL}/company/logo/${company!.id}'
              : null);

      final payload = {
        'companyName': resolvedCompanyName,
        'imageUrl': resolvedLogoUrl ?? '',
        'currency': 'USD',
        'total': 0.00,
        'subtotal': 0.00,
        'tax': 0.00,
        'discount': 0.00,
        'change': 0.00,
        'numberOfItems': 0.0,
        'items': <Map<String, dynamic>>[],
        'statusMessage': 'Welcome! Please tap or present items',
      };

      await manager.transferDataToPresentation(payload);
      await _sendSunmiWelcomeText();
    } catch (e) {
      debugPrint('SecondaryDisplayService showWelcomeScreen error: $e');
    }
  }

  /// Clear the display and reset
  Future<void> clearDisplay() async {
    await showWelcomeScreen();
  }

  /// Helper to send lines to hardware LCD via SunmiPrinter
  Future<void> _updateSunmiHardwareLcd({
    required List<SaleItem> cartItems,
    required double total,
    required String currency,
  }) async {
    if (!isSupported) return;
    try {
      if (cartItems.isEmpty) {
        await _sendSunmiWelcomeText();
        return;
      }

      final lastItem = cartItems.last;
      final name = lastItem.inventoryItem.value?.name ?? 'Item';

      final line1 = name.length > 12 ? name.substring(0, 12) : name.padRight(12);
      final priceStr = '$currency ${lastItem.total.toStringAsFixed(2)}';
      await SunmiPrinter.lcdString('$line1 $priceStr');

      final line2 = 'TOTAL: $currency ${total.toStringAsFixed(2)}';
      await SunmiPrinter.lcdString(line2);
    } catch (_) {
      // Ignored silently if hardware LCD is not present
    }
  }

  Future<void> _sendSunmiWelcomeText() async {
    if (!isSupported) return;
    try {
      await SunmiPrinter.lcdString('   WELCOME!   ');
      await SunmiPrinter.lcdString('  VIMBIKA POS ');
    } catch (_) {
      // Ignored silently
    }
  }
}
