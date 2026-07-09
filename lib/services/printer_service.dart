import 'dart:async'; // Import for StreamSubscription
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:image/image.dart' as img;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sunmi_printer_plus/enums.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';
import 'package:sunmi_printer_plus/sunmi_style.dart';
import 'package:vimbika_pro/app_constants/app_constants.dart';
import 'package:vimbika_pro/model/product_feature.dart';
import 'package:vimbika_pro/model/sale.dart';
import 'package:vimbika_pro/model/sale_item.dart';
import 'package:vimbika_pro/model/mobile_pos_shift.dart';
import 'package:vimbika_pro/model/currency.dart';
import 'package:vimbika_pro/model/company.dart'; // Import the Company model
import 'package:intl/intl.dart';
import 'package:vimbika_pro/services/default_data_service.dart';
import 'package:vimbika_pro/model/payment_received.dart';
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart'; // Import the USB/BT printer plugin
import 'package:esc_pos_utils_plus/esc_pos_utils.dart'; // Corrected import for Generator, PaperSize, PosStyles etc.

enum PrinterTypes { bluetooth, sunmi, usb }

// Class to hold Bluetooth device information
class BluetoothPrinterDeviceModel {
  final String? name;
  final String? address;
  final bool? isBle;
  final bool? autoConnect;

  BluetoothPrinterDeviceModel({this.name, this.address, this.isBle = false, this.autoConnect = true});

  // For saving/loading from SharedPreferences
  Map<String, dynamic> toJson() => {
        'name': name,
        'address': address,
        'isBle': isBle,
        'autoConnect': autoConnect,
      };

  factory BluetoothPrinterDeviceModel.fromJson(Map<String, dynamic> json) => BluetoothPrinterDeviceModel(
        name: json['name'] as String?,
        address: json['address'] as String?,
        isBle: json['isBle'] as bool? ?? false,
        autoConnect: json['autoConnect'] as bool? ?? true,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BluetoothPrinterDeviceModel &&
          runtimeType == other.runtimeType &&
          address == other.address;

  @override
  int get hashCode => address.hashCode;
}

// Class to hold USB device information, similar to BluetoothDevice
class UsbPrinterDevice {
  final int? vendorId;
  final int? productId;
  final String? name;

  UsbPrinterDevice({this.vendorId, this.productId, this.name});

  // For saving/loading from SharedPreferences
  Map<String, dynamic> toJson() => {
        'vendorId': vendorId,
        'productId': productId,
        'name': name,
      };

  factory UsbPrinterDevice.fromJson(Map<String, dynamic> json) => UsbPrinterDevice(
        vendorId: json['vendorId'] as int?,
        productId: json['productId'] as int?,
        name: json['name'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UsbPrinterDevice &&
          runtimeType == other.runtimeType &&
          vendorId == other.vendorId &&
          productId == other.productId;

  @override
  int get hashCode => vendorId.hashCode ^ productId.hashCode;
}

class PrinterService {
  static final PrinterService _instance = PrinterService._internal();

  factory PrinterService() {
    return _instance;
  }

  PrinterService._internal();

  PrinterTypes _printerType = PrinterTypes.bluetooth;
  // Unified Printer Manager from flutter_pos_printer_platform_image_3
  final PrinterManager _printerManager = PrinterManager.instance;
  
  BluetoothPrinterDeviceModel? _selectedBluetoothDevice;
  final List<BluetoothPrinterDeviceModel> _bluetoothDevices = [];
  
  bool _isConnected = false;
  bool _sunmiBound = false;
  bool _alwaysPrintReceipt = true; // Changed default to true
  int _numberOfReceiptsPerSale = 1; // Added for the new setting
  bool _openCashDrawer = false;
  bool _fiscalisationEnabled = false;
  bool _alwaysFiscalize = false;
  bool _waScan = false;

  // USB Printer specific variables
  UsbPrinterDevice? _selectedUsbDevice;
  final List<UsbPrinterDevice> _usbDevices = [];
  StreamSubscription<PrinterDevice>? _usbDiscoverySubscription; // Added StreamSubscription

  // Getters for current printer status
  PrinterTypes get printerType => _printerType;
  bool get isConnected => _isConnected;
  BluetoothPrinterDeviceModel? get selectedBluetoothDevice => _selectedBluetoothDevice;
  List<BluetoothPrinterDeviceModel> get bluetoothDevices => _bluetoothDevices;
  UsbPrinterDevice? get selectedUsbDevice => _selectedUsbDevice;
  List<UsbPrinterDevice> get usbDevices => _usbDevices;

  Future<void> init() async {
    await _loadPrinterSettings();
    await _initPrinters();
  }

  Future<void> _loadPrinterSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedType = prefs.getString(AppConstants.keyPrinterType);
    if (savedType != null) {
      _printerType = PrinterTypes.values.firstWhere(
        (e) => e.toString() == savedType,
        orElse: () => PrinterTypes.bluetooth,
      );
    }
    final savedBluetoothAddress = prefs.getString(AppConstants.keyPrinterMacAddress);
    final savedBluetoothName = prefs.getString(AppConstants.keyPrinterName);

    if (_printerType == PrinterTypes.bluetooth && savedBluetoothAddress != null && savedBluetoothName != null) {
      _selectedBluetoothDevice = BluetoothPrinterDeviceModel(name: savedBluetoothName, address: savedBluetoothAddress);
    }

    final savedUsbDeviceJson = prefs.getString(AppConstants.keyUsbPrinterDevice);
    if (_printerType == PrinterTypes.usb && savedUsbDeviceJson != null) {
      _selectedUsbDevice = UsbPrinterDevice.fromJson(jsonDecode(savedUsbDeviceJson));
    }

    // Load the new settings
    _alwaysPrintReceipt = prefs.getBool(AppConstants.keyAlwaysPrintReceipt) ?? true; // Changed default to true
    _numberOfReceiptsPerSale = prefs.getInt(AppConstants.keyNumberOfReceiptsPerSale) ?? 1;
    _openCashDrawer = prefs.getBool(AppConstants.keyOpenCashDrawer) ?? false;
    _fiscalisationEnabled = prefs.getBool(AppConstants.keyFiscalisationEnabled) ?? false;
    _alwaysFiscalize = prefs.getBool(AppConstants.keyAlwaysFiscalize) ?? false;
    final String? settings = prefs.getString(AppConstants.keyCompanySettings);
    if (settings != null) {
      final json = jsonDecode(settings);
      final productFeature = ProductFeature.fromJson(json as Map<String, dynamic>);
      _waScan = productFeature.enableWaInvReq ?? false;
    }
  }

  Future<void> _savePrinterSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyPrinterType, _printerType.toString());

    // Clear previous printer type settings
    await prefs.remove(AppConstants.keyPrinterMacAddress);
    await prefs.remove(AppConstants.keyPrinterName);
    await prefs.remove(AppConstants.keyUsbPrinterDevice);

    if (_printerType == PrinterTypes.bluetooth && _selectedBluetoothDevice != null) {
      await prefs.setString(AppConstants.keyPrinterMacAddress, _selectedBluetoothDevice!.address!);
      await prefs.setString(AppConstants.keyPrinterName, _selectedBluetoothDevice!.name!);
    } else if (_printerType == PrinterTypes.usb && _selectedUsbDevice != null) {
      await prefs.setString(AppConstants.keyUsbPrinterDevice, jsonEncode(_selectedUsbDevice!.toJson()));
    }
    // Save the new settings
    await prefs.setBool(AppConstants.keyAlwaysPrintReceipt, _alwaysPrintReceipt);
    await prefs.setInt(AppConstants.keyNumberOfReceiptsPerSale, _numberOfReceiptsPerSale);
    await prefs.setBool(AppConstants.keyOpenCashDrawer, _openCashDrawer);
    await prefs.setBool(AppConstants.keyFiscalisationEnabled, _fiscalisationEnabled);
    await prefs.setBool(AppConstants.keyAlwaysFiscalize, _alwaysFiscalize);
  }

  Future<void> _initPrinters() async {
    if (_printerType == PrinterTypes.bluetooth) {
      await _initBluetooth();
    } else if (_printerType == PrinterTypes.sunmi) {
      await _initSunmi();
    } else if (_printerType == PrinterTypes.usb) {
      await _initUsb();
    }
  }

  Future<void> _initBluetooth() async {
    if (Platform.isAndroid || Platform.isIOS) {
      _printerManager.discovery(type: PrinterType.bluetooth).listen((device) {
        final btDevice = BluetoothPrinterDeviceModel(
          name: device.name,
          address: device.address,
        );
        if (!_bluetoothDevices.contains(btDevice)) {
          _bluetoothDevices.add(btDevice);
        }
      });

      if (_selectedBluetoothDevice != null) {
        try {
          _isConnected = await _printerManager.connect(
            type: PrinterType.bluetooth,
            model: BluetoothPrinterInput(
              name: _selectedBluetoothDevice!.name ?? "BT Printer",
              address: _selectedBluetoothDevice!.address ?? "",
              isBle: _selectedBluetoothDevice!.isBle ?? false,
              autoConnect: _selectedBluetoothDevice!.autoConnect ?? true,
            ),
          );
        } catch (e) {
          _isConnected = false;
        }
      }
    } else {
      _isConnected = false;
    }
  }

  Future<void> _initSunmi() async {
    _sunmiBound = (await SunmiPrinter.bindingPrinter()) ?? false;
    _isConnected = _sunmiBound;
  }

  Future<void> _startUsbDiscovery() async {
    if (!(Platform.isWindows || Platform.isAndroid)) {
      return;
    }

    _usbDiscoverySubscription?.cancel(); // Cancel any previous subscription
    _usbDevices.clear(); // Clear existing devices

    _usbDiscoverySubscription = _printerManager.discovery(type: PrinterType.usb).listen((device) {
      if (device.vendorId != null && device.productId != null) {
        final usbDevice = UsbPrinterDevice(
          vendorId: int.tryParse(device.vendorId.toString()),
          productId: int.tryParse(device.productId.toString()),
          name: device.name,
        );
        if (!_usbDevices.contains(usbDevice)) {
          _usbDevices.add(usbDevice);
        }
      }
    });
  }

  Future<void> _stopUsbDiscovery() async {
    await _usbDiscoverySubscription?.cancel();
    _usbDiscoverySubscription = null;
    _usbDevices.clear();
  }

  Future<void> _initUsb() async {
    await _startUsbDiscovery(); // Start discovery when initializing USB
    if (_selectedUsbDevice != null) {
      try {
        _isConnected = await _printerManager.connect(
          type: PrinterType.usb,
          model: UsbPrinterInput(
            name: _selectedUsbDevice!.name ?? "USB Printer",
            vendorId: _selectedUsbDevice!.vendorId?.toString() ?? "",
            productId: _selectedUsbDevice!.productId?.toString() ?? "",
          ),
        );
      } catch (e) {
        _isConnected = false;
      }
    }
  }

  // Public method to refresh USB devices
  Future<void> refreshUsbDevices() async {
    if (_printerType == PrinterTypes.usb) {
      await _stopUsbDiscovery(); // Stop current discovery
      await _startUsbDiscovery(); // Start a new one
    }
  }

  Future<void> setPrinterType(PrinterTypes type) async {
    if (_printerType == type) return;

    await disconnect(); // Disconnect current printer before changing type
    _printerType = type;
    _isConnected = false; // Reset connection status
    _selectedBluetoothDevice = null; // Clear selected BT device
    _selectedUsbDevice = null; // Clear selected USB device

    // Stop USB discovery if changing away from USB
    if (type != PrinterTypes.usb) {
      await _stopUsbDiscovery();
    }

    await _savePrinterSettings();
    await init(); // Re-initialize with new type
  }

  Future<void> setSelectedBluetoothDevice(BluetoothPrinterDeviceModel device) async {
    if (_selectedBluetoothDevice?.address == device.address) return;

    await disconnect();
    _selectedBluetoothDevice = device;
    _printerType = PrinterTypes.bluetooth; // Ensure type is bluetooth
    await _savePrinterSettings();
    await init(); // Attempt to connect
  }

  Future<void> setSelectedUsbDevice(UsbPrinterDevice device) async {
    if (_selectedUsbDevice?.vendorId == device.vendorId && _selectedUsbDevice?.productId == device.productId) return;

    await disconnect();
    _selectedUsbDevice = device;
    _printerType = PrinterTypes.usb; // Ensure type is USB
    await _savePrinterSettings();
    await init(); // Attempt to connect
  }

  Future<void> connectBluetooth(BluetoothPrinterDeviceModel device) async {
    if (!(Platform.isAndroid || Platform.isIOS)) { // Add platform check
      throw Exception('Bluetooth printing is not supported on this platform.');
    }
    try {
      _isConnected = await _printerManager.connect(
        type: PrinterType.bluetooth,
        model: BluetoothPrinterInput(
          name: device.name ?? "BT Printer",
          address: device.address ?? "",
          isBle: device.isBle ?? false,
          autoConnect: device.autoConnect ?? true,
        ),
      );
      if (_isConnected) {
        _selectedBluetoothDevice = device;
        await _savePrinterSettings();
      }
    } catch (e) {
      _isConnected = false;
      rethrow;
    }
  }

  Future<void> connectUsb(UsbPrinterDevice device) async {
    if (!(Platform.isWindows || Platform.isAndroid)) {
      throw Exception('USB printing is not supported on this platform.');
    }
    try {
      _isConnected = await _printerManager.connect(
        type: PrinterType.usb,
        model: UsbPrinterInput(
          name: device.name ?? "USB Printer",
          vendorId: device.vendorId?.toString() ?? "",
          productId: device.productId?.toString() ?? "",
        ),
      );
      if (_isConnected) {
        _selectedUsbDevice = device;
        await _savePrinterSettings();
      } else {
        throw Exception('Failed to connect to USB printer.');
      }
    } catch (e) {
      _isConnected = false;
      rethrow;
    }
  }

  Future<void> disconnect() async {
    if (_printerType == PrinterTypes.bluetooth && _isConnected) {
      if (Platform.isAndroid || Platform.isIOS) { // Add platform check
        await _printerManager.disconnect(type: PrinterType.bluetooth);
      }
      _isConnected = false;
    } else if (_printerType == PrinterTypes.sunmi && _isConnected) {
      // Sunmi doesn't usually require explicit disconnect in this context
      // but we can unbind if necessary, though it's often managed by the system.
      // For now, just update internal state.
      _isConnected = false;
    } else if (_printerType == PrinterTypes.usb && _isConnected) {
      await _printerManager.disconnect(type: PrinterType.usb);
      _isConnected = false;
      await _stopUsbDiscovery(); // Stop discovery on disconnect for USB
    }
    // Do not clear saved settings on disconnect, only on type change
  }

  // New methods for the "Always Print Receipt" setting
  bool getAlwaysPrintReceipt() {
    return _alwaysPrintReceipt;
  }

  Future<void> setAlwaysPrintReceipt(bool value) async {
    _alwaysPrintReceipt = value;
    await _savePrinterSettings();
  }

  // New methods for the "Number of Receipts per Sale" setting
  int getNumberOfReceiptsPerSale() {
    return _numberOfReceiptsPerSale;
  }

  Future<void> setNumberOfReceiptsPerSale(int value) async {
    _numberOfReceiptsPerSale = value;
    await _savePrinterSettings();
  }

  bool getOpenCashDrawer() {
    return _openCashDrawer;
  }

  Future<void> setOpenCashDrawer(bool value) async {
    _openCashDrawer = value;
    await _savePrinterSettings();
  }

  bool getFiscalisationEnabled() {
    return _fiscalisationEnabled;
  }

  Future<void> setFiscalisationEnabled(bool value) async {
    _fiscalisationEnabled = value;
    await _savePrinterSettings();
  }

  bool getAlwaysFiscalize() {
    return _alwaysFiscalize;
  }

  Future<void> setAlwaysFiscalize(bool value) async {
    _alwaysFiscalize = value;
    await _savePrinterSettings();
  }

  Future<void> openDrawer() async {
    try {
      if (_printerType == PrinterTypes.sunmi) {
        await SunmiPrinter.openDrawer();
      } else {
        // For Bluetooth and USB printers, we send the ESC/POS open drawer command.
        final profile = await CapabilityProfile.load();
        final Generator generator = Generator(PaperSize.mm58, profile);
        List<int> bytes = generator.drawer();
        if (_printerType == PrinterTypes.bluetooth) {
          await _printerManager.send(type: PrinterType.bluetooth, bytes: bytes);
        } else if (_printerType == PrinterTypes.usb) {
          await _printerManager.send(type: PrinterType.usb, bytes: bytes);
        }
      }
    } catch (e) {
      print("Error opening drawer: $e");
    }
  }

  Future<void> printPaymentReceipt(PaymentReceived payment) async {
    if (!_isConnected) {
      return;
    }

    if (_openCashDrawer) {
      await openDrawer();
    }

    try {
      final String content = _formatPaymentReceiptContent(payment);
      for (int i = 0; i < _numberOfReceiptsPerSale; i++) {
        if (_printerType == PrinterTypes.bluetooth) {
          await _printBluetoothReceipt(content);
        } else if (_printerType == PrinterTypes.sunmi) {
          await _printSunmiReceipt(content);
        } else if (_printerType == PrinterTypes.usb) {
          await _printUsbReceipt(content);
        }
        if (i < _numberOfReceiptsPerSale - 1) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  String _formatPaymentReceiptContent(PaymentReceived payment) {
    StringBuffer buffer = StringBuffer();

    buffer.writeln('--------------------------------');
    buffer.writeln('          PAYMENT RECEIPT       ');
    buffer.writeln('--------------------------------');
    buffer.writeln('Receipt #: ${payment.id ?? 'N/A'}');
    buffer.writeln('Date: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}');
    if (payment.payer.value != null) {
      buffer.writeln('Received From: ${payment.payer.value!.name}');
    }
    buffer.writeln('Amount: ${payment.currency.value?.symbol ?? ''} ${payment.amount.toStringAsFixed(2)}');
    buffer.writeln('Payment Method: ${payment.paymentType.value?.name ?? 'N/A'}');
    if (payment.bank.value != null) {
      buffer.writeln('Bank: ${payment.bank.value!.name}');
    }
    buffer.writeln('--------------------------------');
    buffer.writeln('  THANK YOU FOR YOUR PAYMENT!');
    buffer.writeln('--------------------------------');
    buffer.writeln('       Powered by Vimbika');
    buffer.writeln('--------------------------------');

    return buffer.toString();
  }

  /// Prints a sale receipt using the Sale model.
  Future<void> printSale(Sale sale) async {
    if (!_isConnected) {
      return;
    }

    if (_openCashDrawer) {
      await openDrawer();
    }

    try {
      for (int i = 0; i < _numberOfReceiptsPerSale; i++) {
        if (_printerType == PrinterTypes.bluetooth) {
          await _printBluetoothSale(sale);
        } else if (_printerType == PrinterTypes.sunmi) {
          await _printSunmiSale(sale);
        } else if (_printerType == PrinterTypes.usb) {
          await _printUsbSale(sale);
        }
        if (i < _numberOfReceiptsPerSale - 1) {
          // Add a small delay between prints for multiple copies
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Prints a Kitchen Order Ticket (KOT).
  Future<void> printKOT(List<SaleItem> items, {String? ticketName, String? orderNumber}) async {
    if (!_isConnected) {
      return;
    }

    try {
      if (_printerType == PrinterTypes.bluetooth) {
        await _printBluetoothKOT(items, ticketName: ticketName, orderNumber: orderNumber);
      } else if (_printerType == PrinterTypes.sunmi) {
        await _printSunmiKOT(items, ticketName: ticketName, orderNumber: orderNumber);
      } else if (_printerType == PrinterTypes.usb) {
        await _printUsbKOT(items, ticketName: ticketName, orderNumber: orderNumber);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _printBluetoothKOT(List<SaleItem> items, {String? ticketName, String? orderNumber}) async {
    if (!(Platform.isAndroid || Platform.isIOS)) return;
    if (_selectedBluetoothDevice == null || !_isConnected) {
      throw Exception('Bluetooth printer not selected or not connected.');
    }

    List<int> bytes = [];
    final profile = await CapabilityProfile.load();
    final Generator generator = Generator(PaperSize.mm58, profile);

    bytes += generator.text("KITCHEN ORDER TICKET", styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
    bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));
    
    if (orderNumber != null) {
      bytes += generator.text("Order #: $orderNumber", styles: const PosStyles(align: PosAlign.left, bold: true));
    }
    if (ticketName != null) {
      bytes += generator.text("Ticket: $ticketName", styles: const PosStyles(align: PosAlign.left, bold: true));
    }
    bytes += generator.text("Date: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}", styles: const PosStyles(align: PosAlign.left));
    bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text("Item", styles: const PosStyles(align: PosAlign.left, bold: true));
    bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));

    for (var item in items) {
      String name = (item.inventoryItem.value?.name ?? "Item");
      String qty = "Qty: ${item.quantity.toStringAsFixed(0)}";
      
      bytes += generator.text(name, styles: const PosStyles(align: PosAlign.left, bold: true));
      bytes += generator.text(qty, styles: const PosStyles(align: PosAlign.left));
      bytes += generator.text(" ", styles: const PosStyles(align: PosAlign.left)); // Spacer
    }

    bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));
    bytes += generator.feed(2);
    bytes += generator.cut();

    await _printerManager.send(type: PrinterType.bluetooth, bytes: bytes);
  }

  Future<void> _printSunmiKOT(List<SaleItem> items, {String? ticketName, String? orderNumber}) async {
    await SunmiPrinter.initPrinter();
    await SunmiPrinter.startTransactionPrint(true);

    await SunmiPrinter.printText('KITCHEN ORDER TICKET\n', style: SunmiStyle(fontSize: SunmiFontSize.XL, align: SunmiPrintAlign.CENTER, bold: true));
    await SunmiPrinter.printText("--------------------------------\n", style: SunmiStyle(align: SunmiPrintAlign.CENTER));

    if (orderNumber != null) {
      await SunmiPrinter.printText("Order #: $orderNumber\n", style: SunmiStyle(align: SunmiPrintAlign.LEFT, bold: true));
    }
    if (ticketName != null) {
      await SunmiPrinter.printText("Ticket: $ticketName\n", style: SunmiStyle(align: SunmiPrintAlign.LEFT, bold: true));
    }
    await SunmiPrinter.printText("Date: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}\n", style: SunmiStyle(align: SunmiPrintAlign.LEFT));
    await SunmiPrinter.printText("--------------------------------\n", style: SunmiStyle(align: SunmiPrintAlign.CENTER));
    await SunmiPrinter.printText("Item\n", style: SunmiStyle(align: SunmiPrintAlign.LEFT, bold: true));
    await SunmiPrinter.printText("--------------------------------\n", style: SunmiStyle(align: SunmiPrintAlign.CENTER));

    for (var item in items) {
      String name = (item.inventoryItem.value?.name ?? "Item");
      String qty = "Qty: ${item.quantity.toStringAsFixed(0)}";
      
      await SunmiPrinter.printText("$name\n", style: SunmiStyle(align: SunmiPrintAlign.LEFT, bold: true, fontSize: SunmiFontSize.LG));
      await SunmiPrinter.printText("$qty\n\n", style: SunmiStyle(align: SunmiPrintAlign.LEFT));
    }

    await SunmiPrinter.printText("--------------------------------\n", style: SunmiStyle(align: SunmiPrintAlign.CENTER));
    await SunmiPrinter.lineWrap(3);
    await SunmiPrinter.exitTransactionPrint(true);
  }

  Future<void> _printUsbKOT(List<SaleItem> items, {String? ticketName, String? orderNumber}) async {
    if (_selectedUsbDevice == null || !_isConnected) {
      throw Exception('USB printer not selected or not connected.');
    }

    List<int> bytes = [];
    final profile = await CapabilityProfile.load();
    final Generator generator = Generator(PaperSize.mm80, profile);

    bytes += generator.text("KITCHEN ORDER TICKET", styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
    bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));
    
    if (orderNumber != null) {
      bytes += generator.text("Order #: $orderNumber", styles: const PosStyles(align: PosAlign.left, bold: true));
    }
    if (ticketName != null) {
      bytes += generator.text("Ticket: $ticketName", styles: const PosStyles(align: PosAlign.left, bold: true));
    }
    bytes += generator.text("Date: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}", styles: const PosStyles(align: PosAlign.left));
    bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text("Item", styles: const PosStyles(align: PosAlign.left, bold: true));
    bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));

    for (var item in items) {
      String name = (item.inventoryItem.value?.name ?? "Item");
      String qty = "Qty: ${item.quantity.toStringAsFixed(0)}";
      
      bytes += generator.text(name, styles: const PosStyles(align: PosAlign.left, bold: true));
      bytes += generator.text(qty, styles: const PosStyles(align: PosAlign.left));
      bytes += generator.text(" ", styles: const PosStyles(align: PosAlign.left)); // Spacer
    }

    bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));
    bytes += generator.feed(2);
    bytes += generator.cut();

    await _printerManager.send(type: PrinterType.usb, bytes: bytes);
  }

  /// Prints a bill for a held sale.
  Future<void> printBill(Sale sale, {List<Currency>? currencies}) async {
    if (!_isConnected) {
      return;
    }

    try {
      if (_printerType == PrinterTypes.bluetooth) {
        await _printBluetoothBill(sale, currencies: currencies);
      } else if (_printerType == PrinterTypes.sunmi) {
        await _printSunmiBill(sale, currencies: currencies);
      } else if (_printerType == PrinterTypes.usb) {
        await _printUsbBill(sale, currencies: currencies);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _printBluetoothBill(Sale sale, {List<Currency>? currencies}) async {
    if (!(Platform.isAndroid || Platform.isIOS)) return;
    if (_selectedBluetoothDevice == null || !_isConnected) {
      throw Exception('Bluetooth printer not selected or not connected.');
    }

    List<int> bytes = [];
    final profile = await CapabilityProfile.load();
    final Generator generator = Generator(PaperSize.mm58, profile);

    // Header
    bytes += generator.text("BILL", styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
    bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));

    bytes += generator.text(sale.company.value?.name ?? "Vimbika Pro", styles: const PosStyles(align: PosAlign.center, bold: true));
    if (sale.branch.value != null) {
      bytes += generator.text(sale.branch.value!.name ?? "", styles: const PosStyles(align: PosAlign.center));
    }
    bytes += generator.text("Date: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}", styles: const PosStyles(align: PosAlign.left));
    if (sale.ticketName != null) {
      bytes += generator.text("Ticket: ${sale.ticketName}", styles: const PosStyles(align: PosAlign.left));
    }
    bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));

    double baseGrandTotal = sale.allItems.fold(0.0, (sum, item) => sum + item.total);
    if (baseGrandTotal == 0 && sale.heldItems.isNotEmpty) {
      baseGrandTotal = sale.ticketTotal;
    }

    String currentSymbol = sale.currency.value?.symbol ?? "";
    double currentRate = sale.currency.value?.rate ?? 1.0;
    
    for (var item in (sale.allItems.isNotEmpty ? sale.allItems : sale.heldItems)) {
      String name = (item.inventoryItem.value?.name ?? "Item");
      bytes += generator.text(name, styles: const PosStyles(align: PosAlign.left));
      String qty = "Qty: ${item.quantity.toStringAsFixed(0)}";
      String total = "$currentSymbol${(item.total * currentRate).toStringAsFixed(2)}";
      bytes += generator.text(_alignLeftRight(qty, total), styles: const PosStyles(align: PosAlign.left));
    }

    bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text(_alignLeftRight("TOTAL:", "$currentSymbol${(baseGrandTotal * currentRate).toStringAsFixed(2)}"), styles: const PosStyles(align: PosAlign.left, bold: true));
    
    if (currencies != null && currencies.isNotEmpty) {
      bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text("Other Currencies:", styles: const PosStyles(align: PosAlign.left, bold: true));
      for (var currency in currencies) {
        if (currency.id == sale.currency.value?.id) continue;
        double convertedTotal = baseGrandTotal * (currency.rate ?? 1.0);
        String symbol = currency.symbol ?? "";
        bytes += generator.text(_alignLeftRight("${currency.name ?? currency.code}:", "$symbol${convertedTotal.toStringAsFixed(2)}"), styles: const PosStyles(align: PosAlign.left));
      }
    }
    
    bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));

    bytes += generator.feed(1);
    bytes += generator.text("Tip: ________________________", styles: const PosStyles(align: PosAlign.left));
    bytes += generator.feed(1);
    bytes += generator.text("Total: ______________________", styles: const PosStyles(align: PosAlign.left));
    bytes += generator.feed(1);
    bytes += generator.text("Signature: __________________", styles: const PosStyles(align: PosAlign.left));
    
    bytes += generator.feed(2);
    bytes += generator.cut();

    await _printerManager.send(type: PrinterType.bluetooth, bytes: bytes);
  }

  Future<void> _printSunmiBill(Sale sale, {List<Currency>? currencies}) async {
    await SunmiPrinter.initPrinter();
    await SunmiPrinter.startTransactionPrint(true);

    await SunmiPrinter.printText('BILL\n', style: SunmiStyle(fontSize: SunmiFontSize.XL, align: SunmiPrintAlign.CENTER, bold: true));
    await SunmiPrinter.printText("--------------------------------\n", style: SunmiStyle(align: SunmiPrintAlign.CENTER));

    await SunmiPrinter.printText("${sale.company.value?.name ?? "Vimbika Pro"}\n", style: SunmiStyle(align: SunmiPrintAlign.CENTER, bold: true));
    if (sale.branch.value != null) {
      await SunmiPrinter.printText("${sale.branch.value!.name ?? ""}\n", style: SunmiStyle(align: SunmiPrintAlign.CENTER));
    }
    await SunmiPrinter.printText("Date: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}\n", style: SunmiStyle(align: SunmiPrintAlign.LEFT));
    if (sale.ticketName != null) {
      await SunmiPrinter.printText("Ticket: ${sale.ticketName}\n", style: SunmiStyle(align: SunmiPrintAlign.LEFT));
    }
    await SunmiPrinter.printText("--------------------------------\n", style: SunmiStyle(align: SunmiPrintAlign.CENTER));

    double baseGrandTotal = sale.allItems.fold(0.0, (sum, item) => sum + item.total);
    if (baseGrandTotal == 0 && sale.heldItems.isNotEmpty) {
      baseGrandTotal = sale.ticketTotal;
    }

    String currentSymbol = sale.currency.value?.symbol ?? "";
    double currentRate = sale.currency.value?.rate ?? 1.0;

    for (var item in (sale.allItems.isNotEmpty ? sale.allItems : sale.heldItems)) {
      String name = (item.inventoryItem.value?.name ?? "Item");
      await SunmiPrinter.printText("$name\n", style: SunmiStyle(align: SunmiPrintAlign.LEFT));
      String qty = "Qty: ${item.quantity.toStringAsFixed(0)}";
      String total = "$currentSymbol${(item.total * currentRate).toStringAsFixed(2)}";
      await SunmiPrinter.printText("${_alignLeftRight(qty, total)}\n", style: SunmiStyle(align: SunmiPrintAlign.LEFT));
    }

    await SunmiPrinter.printText("--------------------------------\n", style: SunmiStyle(align: SunmiPrintAlign.CENTER));
    await SunmiPrinter.printText("${_alignLeftRight("TOTAL:", "$currentSymbol${(baseGrandTotal * currentRate).toStringAsFixed(2)}")}\n", style: SunmiStyle(align: SunmiPrintAlign.LEFT, bold: true));
    
    if (currencies != null && currencies.isNotEmpty) {
      await SunmiPrinter.printText("--------------------------------\n", style: SunmiStyle(align: SunmiPrintAlign.CENTER));
      await SunmiPrinter.printText("Other Currencies:\n", style: SunmiStyle(align: SunmiPrintAlign.LEFT, bold: true));
      for (var currency in currencies) {
        if (currency.id == sale.currency.value?.id) continue;
        double convertedTotal = baseGrandTotal * (currency.rate ?? 1.0);
        String symbol = currency.symbol ?? "";
        await SunmiPrinter.printText("${_alignLeftRight("${currency.name ?? currency.code}:", "$symbol${convertedTotal.toStringAsFixed(2)}")}\n", style: SunmiStyle(align: SunmiPrintAlign.LEFT));
      }
    }

    await SunmiPrinter.printText("--------------------------------\n", style: SunmiStyle(align: SunmiPrintAlign.CENTER));

    await SunmiPrinter.lineWrap(1);
    await SunmiPrinter.printText("Tip: ________________________\n", style: SunmiStyle(align: SunmiPrintAlign.LEFT));
    await SunmiPrinter.lineWrap(1);
    await SunmiPrinter.printText("Total: ______________________\n", style: SunmiStyle(align: SunmiPrintAlign.LEFT));
    await SunmiPrinter.lineWrap(1);
    await SunmiPrinter.printText("Signature: __________________\n", style: SunmiStyle(align: SunmiPrintAlign.LEFT));

    await SunmiPrinter.lineWrap(3);
    await SunmiPrinter.exitTransactionPrint(true);
  }

  Future<void> _printUsbBill(Sale sale, {List<Currency>? currencies}) async {
    if (_selectedUsbDevice == null || !_isConnected) {
      throw Exception('USB printer not selected or not connected.');
    }

    List<int> bytes = [];
    final profile = await CapabilityProfile.load();
    final Generator generator = Generator(PaperSize.mm80, profile);

    // Header
    bytes += generator.text("BILL", styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
    bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));

    bytes += generator.text(sale.company.value?.name ?? "Vimbika Pro", styles: const PosStyles(align: PosAlign.center, bold: true));
    if (sale.branch.value != null) {
      bytes += generator.text(sale.branch.value!.name ?? "", styles: const PosStyles(align: PosAlign.center));
    }
    bytes += generator.text("Date: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}", styles: const PosStyles(align: PosAlign.left));
    if (sale.ticketName != null) {
      bytes += generator.text("Ticket: ${sale.ticketName}", styles: const PosStyles(align: PosAlign.left));
    }
    bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));

    double baseGrandTotal = sale.allItems.fold(0.0, (sum, item) => sum + item.total);
    if (baseGrandTotal == 0 && sale.heldItems.isNotEmpty) {
      baseGrandTotal = sale.ticketTotal;
    }

    String currentSymbol = sale.currency.value?.symbol ?? "";
    double currentRate = sale.currency.value?.rate ?? 1.0;

    for (var item in (sale.allItems.isNotEmpty ? sale.allItems : sale.heldItems)) {
      String name = (item.inventoryItem.value?.name ?? "Item");
      bytes += generator.text(name, styles: const PosStyles(align: PosAlign.left));
      String qty = "Qty: ${item.quantity.toStringAsFixed(0)}";
      String total = "$currentSymbol${(item.total * currentRate).toStringAsFixed(2)}";
      bytes += generator.text(_alignLeftRight(qty, total, width: 48), styles: const PosStyles(align: PosAlign.left));
    }

    bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text(_alignLeftRight("TOTAL:", "$currentSymbol${(baseGrandTotal * currentRate).toStringAsFixed(2)}", width: 48), styles: const PosStyles(align: PosAlign.left, bold: true));
    
    if (currencies != null && currencies.isNotEmpty) {
      bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text("Other Currencies:", styles: const PosStyles(align: PosAlign.left, bold: true));
      for (var currency in currencies) {
        if (currency.id == sale.currency.value?.id) continue;
        double convertedTotal = baseGrandTotal * (currency.rate ?? 1.0);
        String symbol = currency.symbol ?? "";
        bytes += generator.text(_alignLeftRight("${currency.name ?? currency.code}:", "$symbol${convertedTotal.toStringAsFixed(2)}", width: 48), styles: const PosStyles(align: PosAlign.left));
      }
    }

    bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));

    bytes += generator.feed(1);
    bytes += generator.text("Tip: ________________________", styles: const PosStyles(align: PosAlign.left));
    bytes += generator.feed(1);
    bytes += generator.text("Total: ______________________", styles: const PosStyles(align: PosAlign.left));
    bytes += generator.feed(1);
    bytes += generator.text("Signature: __________________", styles: const PosStyles(align: PosAlign.left));
    
    bytes += generator.feed(2);
    bytes += generator.cut();

    await _printerManager.send(type: PrinterType.usb, bytes: bytes);
  }

  Future<void> _printBluetoothSale(Sale sale) async {
    if (!(Platform.isAndroid || Platform.isIOS)) { // Add platform check
      return;
    }
    if (_selectedBluetoothDevice == null || !_isConnected) {
      throw Exception('Bluetooth printer not selected or not connected.');
    }

    List<int> bytes = [];
    final profile = await CapabilityProfile.load();
    final Generator generator = Generator(PaperSize.mm58, profile);

    // Get image
    if (sale.company.value?.id != null) {
      final DefaultDataService defaultDataService = DefaultDataService();
      final File? logoFile = await defaultDataService.getImage(sale.company.value!.id!);
      if (logoFile != null && await logoFile.exists()) {
        try {
          Uint8List imageBytes = await logoFile.readAsBytes();
          img.Image? image = img.decodeImage(imageBytes);
          if (image != null) {
            img.Image resized = img.copyResize(image, width: 200);
            img.Image grayscale = img.grayscale(resized);
            imageBytes = Uint8List.fromList(img.encodePng(grayscale));
            bytes += generator.image(
              img.decodeImage(imageBytes)!,
              align: PosAlign.center,
            );
            await Future.delayed(const Duration(milliseconds: 500));
          }
        } catch (e) {
          // Could not print BT image
        }
      }
    }

    bytes += generator.text(sale.company.value?.name ?? "Vimbika Pro", styles: PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
    if (sale.branch.value != null) {
      bytes += generator.text(sale.branch.value!.name ?? "", styles: PosStyles(align: PosAlign.center));
      bytes += generator.text(sale.branch.value!.address ?? "", styles: PosStyles(align: PosAlign.center));
    }


    // Company Phone Number
    if (sale.company.value?.phoneNumber != null && sale.company.value!.phoneNumber!.isNotEmpty) {
      bytes += generator.text("Tel: ${sale.company.value!.phoneNumber!}", styles: PosStyles(align: PosAlign.center));
    }
    // Company VAT Number (using description as placeholder if vatNumber missing)
    if (sale.company.value?.description != null && sale.company.value!.description!.isNotEmpty) {
      bytes += generator.text("Info: ${sale.company.value!.description!}", styles: PosStyles(align: PosAlign.center));
    }
    // Company TIN Number (removing taxNumber since it doesn't exist)
    
    bytes += generator.text("--------------------------------", styles: PosStyles(align: PosAlign.center));
    bytes += generator.text("Receipt #: ${sale.posReference ?? 'N/A'}", styles: PosStyles(align: PosAlign.left));
    bytes += generator.text("Date: ${sale.timeIniated}", styles: PosStyles(align: PosAlign.left));
    if (sale.cashierFullName != null) {
      bytes += generator.text("Cashier: ${sale.cashierFullName}", styles: PosStyles(align: PosAlign.left));
    }
    if (sale.customer.value != null) {
      bytes += generator.text("Customer: ${sale.customer.value!.name}", styles: PosStyles(align: PosAlign.left));
    }
    bytes += generator.text("--------------------------------", styles: PosStyles(align: PosAlign.center));
    bytes += generator.text("Item", styles: PosStyles(align: PosAlign.left)); // Simpler header
    bytes += generator.text("--------------------------------", styles: PosStyles(align: PosAlign.center));

    String symbol = sale.currency.value?.symbol ?? "";
    num totalItems = 0;
    for (var item in sale.allItems) {
      totalItems += item.quantity;
      String name = (item.inventoryItem.value?.name ?? "Item");
      // Split name into multiple lines if it's too long
      List<String> nameLines = [];
      int chunkSize = 30; // Max characters per line for item name
      for (int i = 0; i < name.length; i += chunkSize) {
        nameLines.add(name.substring(i, (i + chunkSize < name.length) ? i + chunkSize : name.length));
      }
      for (String line in nameLines) {
        bytes += generator.text(line, styles: PosStyles(align: PosAlign.left));
      }
      
      String qty = "Qty: ${item.quantity.toStringAsFixed(0)}";
      String total = "Total: $symbol${item.total.toStringAsFixed(2)}";
      bytes += generator.text(_alignLeftRight(qty, total), styles: PosStyles(align: PosAlign.left));
    }

    bytes += generator.text("--------------------------------", styles: PosStyles(align: PosAlign.center));
    bytes += generator.text("Total Items: \t $totalItems", styles: PosStyles(align: PosAlign.left));
    bytes += generator.text("Net Amount: \t $symbol${(sale.baseSaleAmount ?? 0.0).toStringAsFixed(2)}", styles: PosStyles(align: PosAlign.left));
    bytes += generator.text("VAT Amount: \t $symbol${(sale.totalTaxAmount ?? 0.0).toStringAsFixed(2)}", styles: PosStyles(align: PosAlign.left));
    bytes += generator.text("TOTAL: $symbol${sale.grandTotal.toStringAsFixed(2)}", styles: PosStyles(align: PosAlign.right, bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
    bytes += generator.text("--------------------------------", styles: PosStyles(align: PosAlign.center));

    // Payment Details
    if (sale.allPaymentTypes.isNotEmpty) {
      bytes += generator.text("Payment Details:", styles: PosStyles(align: PosAlign.left));
      for (var payment in sale.allPaymentTypes) {
        String paymentLine = "${payment.paymentType.value?.name ?? 'N/A'}:";
        String amountLine = "$symbol${(payment.amountTendered ?? payment.amount).toStringAsFixed(2)}";
        bytes += generator.text(_alignLeftRight(paymentLine, amountLine), styles: PosStyles(align: PosAlign.left));
      }
      if (sale.amountTendered != null && sale.amountTendered! > 0) {
        bytes += generator.text(_alignLeftRight("Total Tendered:", "$symbol${sale.amountTendered!.toStringAsFixed(2)}"), styles: PosStyles(align: PosAlign.left, bold: true));
      }
      if (sale.change != null && sale.change! > 0) {
        bytes += generator.text(_alignLeftRight("Change:", "$symbol${sale.change!.toStringAsFixed(2)}"), styles: PosStyles(align: PosAlign.left, bold: true));
      }
      if (sale.amtToAcc != null && double.tryParse(sale.amtToAcc!) != null && double.parse(sale.amtToAcc!) > 0) {
        bytes += generator.text(_alignLeftRight("To Account:", "$symbol${double.parse(sale.amtToAcc!).toStringAsFixed(2)}"), styles: PosStyles(align: PosAlign.left, bold: true));
      }
      bytes += generator.text("--------------------------------", styles: PosStyles(align: PosAlign.center));
    }

    Currency? cur = sale.currency.value;
    if((sale.allPaymentTypes.any((pt) => pt.paymentType.value?.name.contains('ACC-') ?? false)) && sale.customer.value != null && sale.customer.value!.currencyBalance.isNotEmpty) {
      final balanceItem = sale.customer.value!.currencyBalance.firstWhere(
        (cb) => cb.currency.value?.id == cur?.id,
        orElse: () => sale.customer.value!.currencyBalance.first,
      );
      bytes += generator.text("Account Balance: ${cur?.symbol ?? ''} ${balanceItem.balance.toStringAsFixed(2)}", styles: PosStyles(align: PosAlign.left));
      bytes += generator.text("--------------------------------", styles: PosStyles(align: PosAlign.center));
    }

    // qr code
    if(sale.receiptQrCode != null){
      final qrValidationResult = QrValidator.validate(
        data: sale.receiptQrCode!,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
      );
      if (qrValidationResult.status == QrValidationStatus.valid) {
        final qrCodeImage = qrValidationResult.qrCode;
        final painter = QrPainter.withQr(
          qr: qrCodeImage!,
          eyeStyle: const QrEyeStyle(
            eyeShape: QrEyeShape.square,
            color: Color(0xFF000000),
          ),
          dataModuleStyle: const QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: Color(0xFF000000),
          ),
          gapless: true,
        );
        final picData = await painter.toImageData(200);
        final img.Image qrImage = img.decodeImage(picData!.buffer.asUint8List())!;
        final img.Image baseSizeImage = img.Image(qrImage.width, qrImage.height);
        img.fill(baseSizeImage, img.getColor(255, 255, 255));
        img.drawImage(baseSizeImage, qrImage);
        final img.Image grayscaleImage = img.grayscale(baseSizeImage);
        final Uint8List qrImageBytes = Uint8List.fromList(img.encodePng(grayscaleImage));

        bytes += generator.image(
          img.decodeImage(qrImageBytes)!,
          align: PosAlign.center,
        );
        bytes += generator.text("Scan the QR Code above", styles: PosStyles(align: PosAlign.center));
        bytes += generator.text(sale.receiptQrData!, styles: PosStyles(align: PosAlign.center));
        bytes += generator.text("You can verify this receipt manually at ", styles: PosStyles(align: PosAlign.center));
        bytes += generator.text(sale.receiptQrCode!, styles: PosStyles(align: PosAlign.center));
      }
    } else if(sale.receiptQrCode==null && _waScan){
      Uint8List waImageBytes = await generateWhatsappQR(sale.referenceNumber!, sale.currency.value!.symbol!, sale.amountAfterDiscount!);
      bytes += generator.image(
        img.decodeImage(waImageBytes)!,
        align: PosAlign.center,
      );
    }

    bytes += generator.text("Thank you for your purchase!", styles: PosStyles(align: PosAlign.center));
    bytes += generator.text("Powered by Vimbika", styles: PosStyles(align: PosAlign.center));
    bytes += generator.feed(2);
    bytes += generator.cut();

    await _printerManager.send(type: PrinterType.bluetooth, bytes: bytes);
  }

  Future<void> _printSunmiSale(Sale sale) async {
    await SunmiPrinter.initPrinter();
    await SunmiPrinter.startTransactionPrint(true);
    
    // Get image
    if (sale.company.value?.id != null) {
      final DefaultDataService defaultDataService = DefaultDataService();
      final File? logoFile = await defaultDataService.getImage(sale.company.value!.id!);
      if (logoFile != null && await logoFile.exists()) {
        try {
          Uint8List bytes = await logoFile.readAsBytes();
          
          // Resize the image before printing
          img.Image? image = img.decodeImage(bytes);
          if (image != null) {
            // Resize to a smaller width, e.g., 200 pixels
            img.Image resized = img.copyResize(image, width: 200);
            bytes = Uint8List.fromList(img.encodePng(resized));
          }

          await SunmiPrinter.printImage(bytes);
        } catch (e) {
          // Could not print SUNMI image
        }
      }
    }
    await SunmiPrinter.printText('\n${sale.company.value?.name??''}', style: SunmiStyle(fontSize: SunmiFontSize.XL, align: SunmiPrintAlign.CENTER, bold: true));
    if (sale.branch.value != null) {
      await SunmiPrinter.printText("${sale.branch.value!.name}\n${sale.branch.value!.address ?? ''}", style: SunmiStyle(align: SunmiPrintAlign.CENTER));
    }

    // Add company/branch contact details
    if (sale.company.value?.phoneNumber != null && sale.company.value!.phoneNumber!.isNotEmpty) {
      await SunmiPrinter.printText("Tel: ${sale.company.value!.phoneNumber!}", style: SunmiStyle(align: SunmiPrintAlign.CENTER));
    }
    if (sale.company.value?.description != null && sale.company.value!.description!.isNotEmpty) {
      await SunmiPrinter.printText("Info: ${sale.company.value!.description!}", style: SunmiStyle(align: SunmiPrintAlign.CENTER));
    }
    // Removing taxNumber access as it might be missing from model

    await SunmiPrinter.lineWrap(1);
    await SunmiPrinter.printText("Receipt #: ${sale.referenceNumber ?? 'N/A'}\nDate: ${sale.timeIniated}", style: SunmiStyle(align: SunmiPrintAlign.LEFT));
    if (sale.cashierFullName != null) {
      await SunmiPrinter.printText("Cashier: ${sale.cashierFullName}", style: SunmiStyle(align: SunmiPrintAlign.LEFT));
    }
    if (sale.customer.value != null) {
      await SunmiPrinter.printText("Customer: ${sale.customer.value!.name}", style: SunmiStyle(align: SunmiPrintAlign.LEFT));
    }
    await SunmiPrinter.printText("--------------------------------", style: SunmiStyle(align: SunmiPrintAlign.CENTER));
    
    String symbol = sale.currency.value?.symbol ?? "";
    num totalItems = 0;
    await SunmiPrinter.printText("Item", style: SunmiStyle(align: SunmiPrintAlign.LEFT)); // Simpler header
    await SunmiPrinter.printText("--------------------------------", style: SunmiStyle(align: SunmiPrintAlign.CENTER));
    for (var item in sale.allItems) {
      totalItems += item.quantity;
      String name = (item.inventoryItem.value?.name ?? "Item");
      // Split name into multiple lines if it's too long
      List<String> nameLines = [];
      int chunkSize = 30; // Max characters per line for item name
      for (int i = 0; i < name.length; i += chunkSize) {
        nameLines.add(name.substring(i, (i + chunkSize < name.length) ? i + chunkSize : name.length));
      }
      for (String line in nameLines) {
        await SunmiPrinter.printText(line, style: SunmiStyle(align: SunmiPrintAlign.LEFT));
      }
      
      String qty = "Qty: ${item.quantity.toStringAsFixed(0)}";
      String total = "Total: $symbol${item.total.toStringAsFixed(2)}";
      await SunmiPrinter.printText(_alignLeftRight(qty, total), style: SunmiStyle(align: SunmiPrintAlign.LEFT));
    }
    
    await SunmiPrinter.printText("--------------------------------", style: SunmiStyle(align: SunmiPrintAlign.CENTER));
    await SunmiPrinter.printText("Total Items: \t $totalItems", style: SunmiStyle(align: SunmiPrintAlign.LEFT));
    await SunmiPrinter.printText("Net Amount: \t $symbol${(sale.baseSaleAmount ?? 0.0).toStringAsFixed(2)}", style: SunmiStyle(align: SunmiPrintAlign.LEFT));
    await SunmiPrinter.printText("VAT Amount: \t $symbol${(sale.totalTaxAmount ?? 0.0).toStringAsFixed(2)}", style: SunmiStyle(align: SunmiPrintAlign.LEFT));
    await SunmiPrinter.printText("TOTAL: $symbol${sale.grandTotal.toStringAsFixed(2)}", style: SunmiStyle(fontSize: SunmiFontSize.LG, align: SunmiPrintAlign.RIGHT, bold: true));
    await SunmiPrinter.printText("--------------------------------", style: SunmiStyle(align: SunmiPrintAlign.CENTER));

    // Payment Details
    if (sale.allPaymentTypes.isNotEmpty) {
      await SunmiPrinter.printText("Payment Details:", style: SunmiStyle(align: SunmiPrintAlign.LEFT));
      for (var payment in sale.allPaymentTypes) {
        String paymentLine = "${payment.paymentType.value?.name ?? 'N/A'}:";
        String amountLine = "$symbol${(payment.amountTendered ?? payment.amount).toStringAsFixed(2)}";
        await SunmiPrinter.printText(_alignLeftRight(paymentLine, amountLine), style: SunmiStyle(align: SunmiPrintAlign.LEFT));
      }
      if (sale.amountTendered != null && sale.amountTendered! > 0) {
        await SunmiPrinter.printText(_alignLeftRight("Total Tendered:", "$symbol${sale.amountTendered!.toStringAsFixed(2)}"), style: SunmiStyle(align: SunmiPrintAlign.LEFT, bold: true));
      }
      if (sale.change != null && sale.change! > 0) {
        await SunmiPrinter.printText(_alignLeftRight("Change:", "$symbol${sale.change!.toStringAsFixed(2)}"), style: SunmiStyle(align: SunmiPrintAlign.LEFT, bold: true));
      }
      if (sale.amtToAcc != null && double.tryParse(sale.amtToAcc!) != null && double.parse(sale.amtToAcc!) > 0) {
        await SunmiPrinter.printText(_alignLeftRight("To Account:", "$symbol${double.parse(sale.amtToAcc!).toStringAsFixed(2)}"), style: SunmiStyle(align: SunmiPrintAlign.LEFT, bold: true));
      }
      await SunmiPrinter.printText("--------------------------------", style: SunmiStyle(align: SunmiPrintAlign.CENTER));
    }

    Currency? cur = sale.currency.value;
    if(sale.allPaymentTypes.any((pt) => pt.paymentType.value?.name.contains('ACC-') ?? false) && sale.customer.value != null && sale.customer.value!.currencyBalance.isNotEmpty)
    {
      final balanceItem = sale.customer.value!.currencyBalance.firstWhere(
        (cb) => cb.currency.value?.id == cur?.id,
        orElse: () => sale.customer.value!.currencyBalance.first,
      );
      await SunmiPrinter.printText(
          "Account Balance: ${cur?.symbol ?? ''} ${balanceItem.balance.toStringAsFixed(2)}");
      await SunmiPrinter.printText("--------------------------------", style: SunmiStyle(align: SunmiPrintAlign.CENTER));
    }
    await SunmiPrinter.printText("\n");


    //qr code

    if(sale.receiptQrCode != null){
      await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
      await SunmiPrinter.printQRCode(sale.receiptQrCode!);
      await SunmiPrinter.printText("Scan the QR Code above");
      await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
      await SunmiPrinter.printText(sale.receiptQrData!);
      await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
      await SunmiPrinter.printText("You can verify this receipt manually at ");
      await SunmiPrinter.printText(sale.receiptQrCode!);
    } else if(sale.receiptQrCode==null
        && _waScan
    ){
      Uint8List waImageBytes = await generateWhatsappQR(sale.referenceNumber!, sale.currency.value!.symbol!, sale.amountAfterDiscount!);
      await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
      await SunmiPrinter.printImage(waImageBytes);
      await SunmiPrinter.printText("\n");
    }

    await SunmiPrinter.lineWrap(1);
    await SunmiPrinter.printText("Thank you for your purchase!", style: SunmiStyle(align: SunmiPrintAlign.CENTER));
    await SunmiPrinter.lineWrap(1);
    await SunmiPrinter.printText("Powered by Vimbika", style: SunmiStyle(align: SunmiPrintAlign.CENTER)); // Powered by Vimbika
    
    await SunmiPrinter.lineWrap(3);
    await SunmiPrinter.cut();
    await SunmiPrinter.submitTransactionPrint();
    await SunmiPrinter.exitTransactionPrint(true);
  }

  Future<void> _printUsbSale(Sale sale) async {
    if (!(Platform.isWindows || Platform.isAndroid)) {
      return;
    }
    if (_selectedUsbDevice == null || !_isConnected) {
      throw Exception('USB printer not selected or not connected.');
    }

    List<int> bytes = [];
    final profile = await CapabilityProfile.load();
    final Generator generator = Generator(PaperSize.mm58, profile);

    // Get image
    if (sale.company.value?.id != null) {
      final DefaultDataService defaultDataService = DefaultDataService();
      final File? logoFile = await defaultDataService.getImage(sale.company.value!.id!);
      if (logoFile != null && await logoFile.exists()) {
        try {
          Uint8List imageBytes = await logoFile.readAsBytes();
          img.Image? image = img.decodeImage(imageBytes);
          if (image != null) {
            img.Image resized = img.copyResize(image, width: 200);
            img.Image grayscale = img.grayscale(resized);
            imageBytes = Uint8List.fromList(img.encodePng(grayscale));
            bytes += generator.image(
              img.decodeImage(imageBytes)!,
              align: PosAlign.center,
            );
            await Future.delayed(const Duration(milliseconds: 1000));
          }
        } catch (e) {
          // Could not print USB image
        }
      }
    }

    bytes += generator.text(sale.company.value?.name ?? "Vimbika Pro", styles: PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
    if (sale.branch.value != null) {
      bytes += generator.text(sale.branch.value!.name ?? "", styles: PosStyles(align: PosAlign.center));
      bytes += generator.text(sale.branch.value!.address ?? "", styles: PosStyles(align: PosAlign.center));
    }

    // Company Phone Number
    if (sale.company.value?.phoneNumber != null && sale.company.value!.phoneNumber!.isNotEmpty) {
      bytes += generator.text("Tel: ${sale.company.value!.phoneNumber!}", styles: PosStyles(align: PosAlign.center));
    }
    // Company VAT Number
    if (sale.company.value?.description != null && sale.company.value!.description!.isNotEmpty) {
      bytes += generator.text("Info: ${sale.company.value!.description!}", styles: PosStyles(align: PosAlign.center));
    }
    // Removing taxNumber since it's not verified to exist

    bytes += generator.text("--------------------------------", styles: PosStyles(align: PosAlign.center));
    bytes += generator.text("Receipt #: ${sale.posReference ?? 'N/A'}", styles: PosStyles(align: PosAlign.left));
    bytes += generator.text("Date: ${sale.timeIniated}", styles: PosStyles(align: PosAlign.left));
    if (sale.cashierFullName != null) {
      bytes += generator.text("Cashier: ${sale.cashierFullName}", styles: PosStyles(align: PosAlign.left));
    }
    if (sale.customer.value != null) {
      bytes += generator.text("Customer: ${sale.customer.value!.name}", styles: PosStyles(align: PosAlign.left));
    }
    bytes += generator.text("--------------------------------", styles: PosStyles(align: PosAlign.center));
    bytes += generator.text("Item", styles: PosStyles(align: PosAlign.left)); // Simpler header
    bytes += generator.text("--------------------------------", styles: PosStyles(align: PosAlign.center));
    
    String symbol = sale.currency.value?.symbol ?? "";
    num totalItems = 0;
    for (var item in sale.allItems) {
      totalItems += item.quantity;
      String name = (item.inventoryItem.value?.name ?? "Item");
      // Split name into multiple lines if it's too long
      List<String> nameLines = [];
      int chunkSize = 30; // Max characters per line for item name
      for (int i = 0; i < name.length; i += chunkSize) {
        nameLines.add(name.substring(i, (i + chunkSize < name.length) ? i + chunkSize : name.length));
      }
      for (String line in nameLines) {
        bytes += generator.text(line, styles: PosStyles(align: PosAlign.left));
      }
      
      String qty = "Qty: ${item.quantity.toStringAsFixed(0)}";
      String total = "Total: $symbol${item.total.toStringAsFixed(2)}";
      bytes += generator.text(_alignLeftRight(qty, total), styles: PosStyles(align: PosAlign.left));
    }
    
    bytes += generator.text("--------------------------------", styles: PosStyles(align: PosAlign.center));
    bytes += generator.text("Total Items: \t $totalItems", styles: PosStyles(align: PosAlign.left));
    bytes += generator.text("Net Amount: \t $symbol${(sale.baseSaleAmount ?? 0.0).toStringAsFixed(2)}", styles: PosStyles(align: PosAlign.left));
    bytes += generator.text("VAT Amount: \t $symbol${(sale.totalTaxAmount ?? 0.0).toStringAsFixed(2)}", styles: PosStyles(align: PosAlign.left));
    bytes += generator.text("TOTAL: $symbol${sale.grandTotal.toStringAsFixed(2)}", styles: PosStyles(align: PosAlign.right, bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
    bytes += generator.text("--------------------------------", styles: PosStyles(align: PosAlign.center));

    // Payment Details
    if (sale.allPaymentTypes.isNotEmpty) {
      bytes += generator.text("Payment Details:", styles: PosStyles(align: PosAlign.left));
      for (var payment in sale.allPaymentTypes) {
        String paymentLine = "${payment.paymentType.value?.name ?? 'N/A'}:";
        String amountLine = "$symbol${(payment.amountTendered ?? payment.amount).toStringAsFixed(2)}";
        bytes += generator.text(_alignLeftRight(paymentLine, amountLine), styles: PosStyles(align: PosAlign.left));
      }
      if (sale.amountTendered != null && sale.amountTendered! > 0) {
        bytes += generator.text(_alignLeftRight("Total Tendered:", "$symbol${sale.amountTendered!.toStringAsFixed(2)}"), styles: PosStyles(align: PosAlign.left, bold: true));
      }
      if (sale.change != null && sale.change! > 0) {
        bytes += generator.text(_alignLeftRight("Change:", "$symbol${sale.change!.toStringAsFixed(2)}"), styles: PosStyles(align: PosAlign.left, bold: true));
      }
      if (sale.amtToAcc != null && double.tryParse(sale.amtToAcc!) != null && double.parse(sale.amtToAcc!) > 0) {
        bytes += generator.text(_alignLeftRight("To Account:", "$symbol${double.parse(sale.amtToAcc!).toStringAsFixed(2)}"), styles: PosStyles(align: PosAlign.left, bold: true));
      }
      bytes += generator.text("--------------------------------", styles: PosStyles(align: PosAlign.center));
    }

    Currency? cur = sale.currency.value;
    if((sale.allPaymentTypes.any((pt) => pt.paymentType.value?.name.contains('ACC-') ?? false)) && sale.customer.value != null && sale.customer.value!.currencyBalance.isNotEmpty) {
      final balanceItem = sale.customer.value!.currencyBalance.firstWhere(
        (cb) => cb.currency.value?.id == cur?.id,
        orElse: () => sale.customer.value!.currencyBalance.first,
      );
      bytes += generator.text("Account Balance: ${cur?.symbol ?? ''} ${balanceItem.balance.toStringAsFixed(2)}", styles: PosStyles(align: PosAlign.left));
      bytes += generator.text("--------------------------------", styles: PosStyles(align: PosAlign.center));
    }

    // qr code
    if(sale.receiptQrCode != null){
      final qrValidationResult = QrValidator.validate(
        data: sale.receiptQrCode!,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
      );
      if (qrValidationResult.status == QrValidationStatus.valid) {
        final qrCodeImage = qrValidationResult.qrCode;
        final painter = QrPainter.withQr(
          qr: qrCodeImage!,
          eyeStyle: const QrEyeStyle(
            eyeShape: QrEyeShape.square,
            color: Color(0xFF000000),
          ),
          dataModuleStyle: const QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: Color(0xFF000000),
          ),
          gapless: true,
        );
        final picData = await painter.toImageData(200);
        final img.Image qrImage = img.decodeImage(picData!.buffer.asUint8List())!;
        final img.Image baseSizeImage = img.Image(qrImage.width, qrImage.height);
        img.fill(baseSizeImage, img.getColor(255, 255, 255));
        img.drawImage(baseSizeImage, qrImage);
        final img.Image grayscaleImage = img.grayscale(baseSizeImage);
        final Uint8List qrImageBytes = Uint8List.fromList(img.encodePng(grayscaleImage));
        
        bytes += generator.image(
          img.decodeImage(qrImageBytes)!,
          align: PosAlign.center,
        );
        bytes += generator.text("Scan the QR Code above", styles: PosStyles(align: PosAlign.center));
        bytes += generator.text(sale.receiptQrData!, styles: PosStyles(align: PosAlign.center));
        bytes += generator.text("You can verify this receipt manually at ", styles: PosStyles(align: PosAlign.center));
        bytes += generator.text(sale.receiptQrCode!, styles: PosStyles(align: PosAlign.center));
      }
    } else if(sale.receiptQrCode==null && _waScan){
      Uint8List waImageBytes = await generateWhatsappQR(sale.referenceNumber!, sale.currency.value!.symbol!, sale.amountAfterDiscount!);
      bytes += generator.image(
        img.decodeImage(waImageBytes)!,
        align: PosAlign.center,
      );
    }

    bytes += generator.text("Thank you for your purchase!", styles: PosStyles(align: PosAlign.center));
    bytes += generator.text("Powered by Vimbika", styles: PosStyles(align: PosAlign.center));
    bytes += generator.feed(2);
    bytes += generator.cut();

    await _printerManager.send(type: PrinterType.usb, bytes: bytes);
  }

  /// Prints a pre-formatted receipt content string to the currently selected printer.
  /// The `receiptContent` should be a string already formatted with line breaks
  /// and any necessary ESC/POS commands for advanced formatting (for Bluetooth printers).
  ///
  /// Throws an [Exception] if the printer is not connected.
  Future<void> printReceipt(String receiptContent) async {
    if (!_isConnected) {
      throw Exception('Printer not connected.');
    }

    if (_openCashDrawer) {
      await openDrawer();
    }

    try {
      for (int i = 0; i < _numberOfReceiptsPerSale; i++) {
        if (_printerType == PrinterTypes.bluetooth) {
          await _printBluetoothReceipt(receiptContent);
        } else if (_printerType == PrinterTypes.sunmi) {
          await _printSunmiReceipt(receiptContent);
        } else if (_printerType == PrinterTypes.usb) {
          await _printUsbReceipt(receiptContent);
        }
        if (i < _numberOfReceiptsPerSale - 1) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
    } catch (e) {
      rethrow;
    }
  }


  Future<Uint8List> generateWhatsappQR(String invoiceNumber, String currencySymbol, double amount) async{
    // Generate QR Code using qr_flutter

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    ProductFeature settingsModel;
    final String? settings = prefs.getString(AppConstants.keyCompanySettings);
    if (settings == null) {
      throw Exception("Company settings not found");
    }else{
      final json = jsonDecode(settings);
      settingsModel = ProductFeature.fromJson(json as Map<String, dynamic>);
    }
    final String? phone = settingsModel.whatsappNumber;

    // Check if WhatsApp number is available
    if (phone == null || phone.isEmpty) {
      throw Exception("WhatsApp number is not configured in company settings");
    }

    final String message = 'Hello, please send me the fiscalised invoice for $invoiceNumber ($currencySymbol $amount)';
    final String encodedMessage = Uri.encodeComponent(message);
    final String waLink = 'https://wa.me/$phone?text=$encodedMessage';
    final qrValidationResult = QrValidator.validate(
      data: waLink,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.L,
    );
    if (qrValidationResult.status != QrValidationStatus.valid) {
      throw Exception("Invalid QR code content");
    }
    final qrCodeImage = qrValidationResult.qrCode;
    // final qrImage = img.Image(width: 300, height: 300); // 300x300 QR code image size
    final painter = QrPainter.withQr(
      qr: qrCodeImage!,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: Color(0xFF000000),
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Color(0xFF000000),
      ),
      gapless: true,
    );

    // Convert QR code to Uint8List
    // ByteData? byteData = await painter.toImageData(300);
    // Uint8List imageBytes = byteData!.buffer.asUint8List();
    final picData = await painter.toImageData(200); // Adjust size if needed
    final img.Image qrImage = img.decodeImage(picData!.buffer.asUint8List())!;
    final img.Image baseSizeImage = img.Image(qrImage.width, qrImage.height);
    img.fill(baseSizeImage, img.getColor(255, 255, 255));
    img.drawImage(baseSizeImage, qrImage);
    final img.Image grayscaleImage = img.grayscale(baseSizeImage);
    final Uint8List qrImageBytes = Uint8List.fromList(img.encodePng(grayscaleImage));
    return qrImageBytes;

  }


  /// Prints a sale receipt using structured sale data.
  /// This method formats the provided `saleData` into a human-readable receipt
  /// and then sends it to the currently selected and connected printer.
  ///
  /// The `saleData` map should contain keys like 'storeName', 'storeAddress',
  /// 'saleDateTime' (as DateTime), 'items' (a List of Maps),
  /// 'subtotal', 'tax', and 'total'.
  /// Each item in 'items' should have 'name', 'quantity', and 'price'.
  ///
  /// Throws an [Exception] if the printer is not connected.
  Future<void> printSaleReceipt(Map<String, dynamic> saleData) async {
    if (!_isConnected) {
      throw Exception('Printer not connected.');
    }

    try {
      final String formattedReceipt = _formatReceiptContent(saleData);
      await printReceipt(formattedReceipt);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _printBluetoothReceipt(String content) async {
    if (!(Platform.isAndroid || Platform.isIOS)) { // Add platform check
      return;
    }
    if (_selectedBluetoothDevice == null || !_isConnected) {
      throw Exception('Bluetooth printer not selected or not connected.');
    }

    List<int> bytes = [];
    final profile = await CapabilityProfile.load();
    final Generator generator = Generator(PaperSize.mm58, profile);

    final lines = content.split('\n');
    for (String line in lines) {
      bytes += generator.text(line, styles: PosStyles(align: PosAlign.left));
    }
    bytes += generator.feed(2);
    bytes += generator.cut();

    await _printerManager.send(type: PrinterType.bluetooth, bytes: bytes);
  }

  Future<void> _printSunmiReceipt(String content) async {
    await SunmiPrinter.initPrinter();
    await SunmiPrinter.startTransactionPrint(true);
    
    final lines = content.split('\n');
    for (String line in lines) {
      if (line.isNotEmpty) {
        // Use LEFT align to respect our spaces
        await SunmiPrinter.printText(line, style: SunmiStyle(align: SunmiPrintAlign.LEFT));
      }
    }
    
    await SunmiPrinter.lineWrap(3);
    await SunmiPrinter.cut();
    await SunmiPrinter.submitTransactionPrint();
    await SunmiPrinter.exitTransactionPrint(true);
  }

  Future<void> _printUsbReceipt(String content) async {
    if (!(Platform.isWindows || Platform.isAndroid)) {
      return;
    }
    if (_selectedUsbDevice == null || !_isConnected) {
      throw Exception('USB printer not selected or not connected.');
    }

    List<int> bytes = [];
    final profile = await CapabilityProfile.load();
    final Generator generator = Generator(PaperSize.mm58, profile);

    final lines = content.split('\n');
    for (String line in lines) {
      bytes += generator.text(line, styles: PosStyles(align: PosAlign.left));
    }
    bytes += generator.feed(2);
    bytes += generator.cut();

    await _printerManager.send(type: PrinterType.usb, bytes: bytes);
  }

  String _formatReceiptContent(Map<String, dynamic> saleData) {
    StringBuffer buffer = StringBuffer();

    // Example formatting - adjust as needed for your specific receipt layout
    buffer.writeln('--------------------------------');
    buffer.writeln('          ${saleData['storeName'] ?? 'Vimbika Pro'}');
    buffer.writeln('          ${saleData['storeAddress'] ?? '123 Main St'}');
    
    // Add company/branch contact details
    final String? branchPhoneNumber = saleData['branchPhoneNumber'] as String?;
    final String? companyPhoneNumber = saleData['companyPhoneNumber'] as String?;
    final String? branchEmail = saleData['branchEmail'] as String?;
    final String? companyEmail = saleData['companyEmail'] as String?;

    if (branchPhoneNumber != null && branchPhoneNumber.isNotEmpty) {
      buffer.writeln('Tel: $branchPhoneNumber');
    } else if (companyPhoneNumber != null && companyPhoneNumber.isNotEmpty) {
      buffer.writeln('Tel: $companyPhoneNumber');
    }
    if (branchEmail != null && branchEmail.isNotEmpty) {
      buffer.writeln('Email: $branchEmail');
    } else if (companyEmail != null && companyEmail.isNotEmpty) {
      buffer.writeln('Email: $companyEmail');
    }

    buffer.writeln('--------------------------------');
    final DateTime? saleDateTime = saleData['saleDateTime'] as DateTime?;
    buffer.writeln('Date: ${saleDateTime != null ? saleDateTime.toLocal().toString().substring(0, 16) : 'N/A'}');
    buffer.writeln('--------------------------------');
    buffer.writeln('Item            Qty   Price     Total');
    buffer.writeln('--------------------------------');

    List<Map<String, dynamic>> items = (saleData['items'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    for (var item in items) {
      final String name = item['name'] ?? '';
      final int quantity = item['quantity'] ?? 0;
      final double price = item['price'] ?? 0.0;
      final double itemTotal = quantity * price;
      buffer.writeln('${name.padRight(15).substring(0, 15)} ${quantity.toString().padLeft(3)} ${price.toStringAsFixed(2).padLeft(7)} ${itemTotal.toStringAsFixed(2).padLeft(7)}');
    }

    buffer.writeln('--------------------------------');
    buffer.writeln('Subtotal:                 ${(saleData['subtotal'] ?? 0.0).toStringAsFixed(2).padLeft(7)}');
    buffer.writeln('Tax:                      ${(saleData['tax'] ?? 0.0).toStringAsFixed(2).padLeft(7)}');
    buffer.writeln('Total:                    ${(saleData['total'] ?? 0.0).toStringAsFixed(2).padLeft(7)}');
    buffer.writeln('--------------------------------');

    // Payment Details
    List<Map<String, dynamic>> payments = (saleData['payments'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    if (payments.isNotEmpty) {
      buffer.writeln('Payment Details:');
      for (var payment in payments) {
        final String paymentType = payment['paymentType'] ?? 'N/A';
        final double amount = payment['amount'] ?? 0.0;
        buffer.writeln('$paymentType: ${amount.toStringAsFixed(2)}');
      }
      buffer.writeln('--------------------------------');
    }

    buffer.writeln('  THANK YOU FOR YOUR PURCHASE!');
    buffer.writeln('--------------------------------');
    buffer.writeln('       Powered by Vimbika');
    buffer.writeln('--------------------------------');


    return buffer.toString();
  }

  // Helper method for aligning labels and figures
  // width changed from 40 to 32 to better fit 58mm thermal printers
  String _alignLeftRight(String left, String right, {int width = 32}) {
    int spaces = width - left.length - right.length;
    if (spaces < 1) return '$left $right';
    return '$left${' ' * spaces}$right';
  }

  // New methods for printing shift reports
  Future<void> printShiftSummary(MobilePosShift shift, List<Currency> availableCurrencies, Company? company) async {
    if (!_isConnected) {
      throw Exception('Printer not connected.');
    }
    final String content = _formatShiftSummaryContent(shift, availableCurrencies, company);
    if (_printerType == PrinterTypes.bluetooth) {
      await _printBluetoothReceipt(content);
    } else if (_printerType == PrinterTypes.sunmi) {
      await _printSunmiReceipt(content);
    } else if (_printerType == PrinterTypes.usb) {
      await _printUsbReceipt(content);
    }
  }

  Future<void> printFullShiftReport(MobilePosShift shift, List<Currency> availableCurrencies, Company? company) async {
    if (!_isConnected) {
      throw Exception('Printer not connected.');
    }
    final String content = _formatFullShiftReportContent(shift, availableCurrencies, company);
    if (_printerType == PrinterTypes.bluetooth) {
      await _printBluetoothReceipt(content);
    } else if (_printerType == PrinterTypes.sunmi) {
      await _printSunmiReceipt(content);
    } else if (_printerType == PrinterTypes.usb) {
      await _printUsbReceipt(content);
    }
  }

  String _formatShiftSummaryContent(MobilePosShift shift, List<Currency> availableCurrencies, Company? company) {
    final StringBuffer buffer = StringBuffer();
    buffer.writeln('--------------------------------');
    buffer.writeln('      SHIFT SUMMARY REPORT');
    buffer.writeln('--------------------------------');
    
    // Company Contact Details
    if (company != null) {
      buffer.writeln(_alignLeftRight('Company:', company.name ?? 'N/A'));
      if (company.phoneNumber != null && company.phoneNumber!.isNotEmpty) {
        buffer.writeln(_alignLeftRight('Tel:', company.phoneNumber!));
      }
      if (company.email != null && company.email!.isNotEmpty) {
        buffer.writeln(_alignLeftRight('Email:', company.email!));
      }
      buffer.writeln('--------------------------------');
    }

    buffer.writeln(_alignLeftRight('Shift Ref:', shift.shiftReference ?? 'N/A'));
    buffer.writeln(_alignLeftRight('Opened by:', shift.userFullName ?? 'N/A'));
    buffer.writeln(_alignLeftRight('Opening Time:', shift.openingTime != null ? DateFormat(AppConstants.APP_DATE_TIME_FMT).format(DateTime.parse(shift.openingTime!)) : 'N/A'));
    buffer.writeln(_alignLeftRight('Closing Time:', shift.closingTime != null ? DateFormat(AppConstants.APP_DATE_TIME_FMT).format(DateTime.parse(shift.closingTime!)) : 'N/A'));
    buffer.writeln('--------------------------------');

    Map<String, Map<String, double>> currencyTotals = {}; // {currencyId: {type: amount}}
    Map<String, Map<String, double>> paymentTypeBreakdown = {}; // {currencyId: {paymentTypeName: totalAmount}}

    if (shift.shiftCurrencyAmounts != null) {
      for (final activity in shift.shiftCurrencyAmounts!) {
        if (activity.currency.id != null) {
          currencyTotals.putIfAbsent(activity.currency.id!, () => {
            'CASH_IN': 0.0,
            'CASH_OUT': 0.0,
            'CASH_PAYMENT': 0.0,
            'OTHER_PAYMENT': 0.0,
            'CASH_ACCOUNT_TOP_UP': 0.0,
            'OTHER_ACCOUNT_TOP_UP': 0.0,
          });

          if (activity.amountType == 'CASH_IN') {
            currencyTotals[activity.currency.id!]!['CASH_IN'] =
                (currencyTotals[activity.currency.id!]!['CASH_IN'] ?? 0.0) + activity.amount;
          } else if (activity.amountType == 'ACCOUNT_TOP_UP') {
            if (activity.isCash == true|| (activity.paymentType?.toLowerCase().startsWith('cash') ?? false)) {
              currencyTotals[activity.currency.id!]!['CASH_ACCOUNT_TOP_UP'] =
                  (currencyTotals[activity.currency.id!]!['CASH_ACCOUNT_TOP_UP'] ?? 0.0) + activity.amount;
            } else {
              currencyTotals[activity.currency.id!]!['OTHER_ACCOUNT_TOP_UP'] =
                  (currencyTotals[activity.currency.id!]!['OTHER_ACCOUNT_TOP_UP'] ?? 0.0) + activity.amount;
            }
          } else if (activity.amountType == 'CASH_OUT') {
            currencyTotals[activity.currency.id!]!['CASH_OUT'] =
                (currencyTotals[activity.currency.id!]!['CASH_OUT'] ?? 0.0) + activity.amount;
          } else if (activity.amountType == 'SALE') {
            if ((activity.isCash ?? false) || activity.paymentType!.toLowerCase().startsWith('cash') ) {
              currencyTotals[activity.currency.id!]!['CASH_PAYMENT'] =
                  (currencyTotals[activity.currency.id!]!['CASH_PAYMENT'] ?? 0.0) + activity.amount;
            } else {
              currencyTotals[activity.currency.id!]!['OTHER_PAYMENT'] =
                  (currencyTotals[activity.currency.id!]!['OTHER_PAYMENT'] ?? 0.0) + activity.amount;
            }

            // Populate paymentTypeBreakdown for 'Payment' activities
            final currencyId = activity.currency.id!;
            final paymentTypeName = activity.paymentType ?? 'Unknown Payment Type';

            paymentTypeBreakdown.putIfAbsent(currencyId, () => {});
            paymentTypeBreakdown[currencyId]!.update(
              paymentTypeName,
              (value) => value + activity.amount,
              ifAbsent: () => activity.amount,
            );
          }
        }
      }
    }

    if (currencyTotals.isEmpty) {
      buffer.writeln('No monetary activities recorded.');
    } else {
      for (final entry in currencyTotals.entries) {
        final currencyId = entry.key;
        final totals = entry.value;
        final currency = availableCurrencies.firstWhere(
          (c) => c.id == currencyId,
          orElse: () => Currency(id: currencyId, name: 'Unknown', symbol: '?'),
        );

        final cashInTotal = totals['CASH_IN'] ?? 0.0;
        final cashAccountTopUpTotal = totals['CASH_ACCOUNT_TOP_UP'] ?? 0.0;
        final otherAccountTopUpTotal = totals['OTHER_ACCOUNT_TOP_UP'] ?? 0.0;
        final cashOutTotal = totals['CASH_OUT'] ?? 0.0;
        final cashPaymentTotal = totals['CASH_PAYMENT'] ?? 0.0;
        final otherPaymentTotal = totals['OTHER_PAYMENT'] ?? 0.0;

        final totalSales = cashPaymentTotal + otherPaymentTotal;
        final totalCash = cashInTotal + cashAccountTopUpTotal - cashOutTotal + cashPaymentTotal;

        buffer.writeln('\n--- ${currency.name} (${currency.symbol}) ---');
        buffer.writeln(_alignLeftRight('Initial Cash:', '${currency.symbol} 0.00')); // TODO: Get initial cash per currency
        buffer.writeln(_alignLeftRight('Total Cash In:', '${currency.symbol} ${cashInTotal.toStringAsFixed(2)}'));
        if (cashAccountTopUpTotal > 0) {
          buffer.writeln(_alignLeftRight('Cash Customer Deposits:', '${currency.symbol} ${cashAccountTopUpTotal.toStringAsFixed(2)}'));
        }
        if (otherAccountTopUpTotal > 0) {
          buffer.writeln(_alignLeftRight('Other Customer Deposits:', '${currency.symbol} ${otherAccountTopUpTotal.toStringAsFixed(2)}'));
        }
        buffer.writeln(_alignLeftRight('Total Cash Out:', '${currency.symbol} ${cashOutTotal.toStringAsFixed(2)}'));
        buffer.writeln(_alignLeftRight('Total Cash Sales:', '${currency.symbol} ${cashPaymentTotal.toStringAsFixed(2)}'));
        buffer.writeln(_alignLeftRight('Total Other Sales:', '${currency.symbol} ${otherPaymentTotal.toStringAsFixed(2)}'));
        buffer.writeln(_alignLeftRight('Total Sales:', '${currency.symbol} ${totalSales.toStringAsFixed(2)}'));
        buffer.writeln(_alignLeftRight('Total Cash:', '${currency.symbol} ${totalCash.toStringAsFixed(2)}'));

        if (paymentTypeBreakdown.containsKey(currencyId) && paymentTypeBreakdown[currencyId]!.isNotEmpty) {
          buffer.writeln('\nSales by Payment Type:');
          for (final ptEntry in paymentTypeBreakdown[currencyId]!.entries) {
            buffer.writeln(_alignLeftRight('${ptEntry.key}:', '${currency.symbol} ${ptEntry.value.toStringAsFixed(2)}'));
          }
        }
      }
    }
    buffer.writeln('--------------------------------');
    buffer.writeln('       Powered by Vimbika');
    buffer.writeln('--------------------------------');
    return buffer.toString();
  }

  String _formatFullShiftReportContent(MobilePosShift shift, List<Currency> availableCurrencies, Company? company) {
    final StringBuffer buffer = StringBuffer();
    buffer.writeln('--------------------------------');
    buffer.writeln('        FULL SHIFT REPORT');
    buffer.writeln('--------------------------------');

    // Company Contact Details
    if (company != null) {
      buffer.writeln(_alignLeftRight('Company:', company.name ?? 'N/A'));
      if (company.phoneNumber != null && company.phoneNumber!.isNotEmpty) {
        buffer.writeln(_alignLeftRight('Tel:', company.phoneNumber!));
      }
      if (company.email != null && company.email!.isNotEmpty) {
        buffer.writeln(_alignLeftRight('Email:', company.email!));
      }
      buffer.writeln('--------------------------------');
    }

    buffer.writeln(_alignLeftRight('Shift Ref:', shift.shiftReference ?? 'N/A'));
    buffer.writeln(_alignLeftRight('Opened by:', shift.userFullName ?? 'N/A'));
    buffer.writeln(_alignLeftRight('Opening Time:', shift.openingTime != null ? DateFormat(AppConstants.APP_DATE_TIME_FMT).format(DateTime.parse(shift.openingTime!)) : 'N/A'));
    buffer.writeln(_alignLeftRight('Closing Time:', shift.closingTime != null ? DateFormat(AppConstants.APP_DATE_TIME_FMT).format(DateTime.parse(shift.closingTime!)) : 'N/A'));
    buffer.writeln('--------------------------------');

    // Summary section (same as shift summary)
    Map<String, Map<String, double>> currencyTotals = {};
    Map<String, Map<String, double>> paymentTypeBreakdown = {};

    if (shift.shiftCurrencyAmounts != null) {
      for (final activity in shift.shiftCurrencyAmounts!) {
        if (activity.currency.id != null) {
          currencyTotals.putIfAbsent(activity.currency.id!, () => {
            'CASH_IN': 0.0,
            'CASH_OUT': 0.0,
            'CASH_PAYMENT': 0.0,
            'OTHER_PAYMENT': 0.0,
            'CASH_ACCOUNT_TOP_UP': 0.0,
            'OTHER_ACCOUNT_TOP_UP': 0.0,
          });

          if (activity.amountType == 'CASH_IN') {
            currencyTotals[activity.currency.id!]!['CASH_IN'] =
                (currencyTotals[activity.currency.id!]!['CASH_IN'] ?? 0.0) + activity.amount;
          } else if (activity.amountType == 'ACCOUNT_TOP_UP') {
            if (activity.isCash == true) {
              currencyTotals[activity.currency.id!]!['CASH_ACCOUNT_TOP_UP'] =
                  (currencyTotals[activity.currency.id!]!['CASH_ACCOUNT_TOP_UP'] ?? 0.0) + activity.amount;
            } else {
              currencyTotals[activity.currency.id!]!['OTHER_ACCOUNT_TOP_UP'] =
                  (currencyTotals[activity.currency.id!]!['OTHER_ACCOUNT_TOP_UP'] ?? 0.0) + activity.amount;
            }
          } else if (activity.amountType == 'CASH_OUT') {
            currencyTotals[activity.currency.id!]!['CASH_OUT'] =
                (currencyTotals[activity.currency.id!]!['CASH_OUT'] ?? 0.0) + activity.amount;
          } else if (activity.amountType == 'SALE') {
            if ((activity.isCash ?? false) || activity.paymentType!.toLowerCase().startsWith('cash') ) {
              currencyTotals[activity.currency.id!]!['CASH_PAYMENT'] =
                  (currencyTotals[activity.currency.id!]!['CASH_PAYMENT'] ?? 0.0) + activity.amount;
            } else {
              currencyTotals[activity.currency.id!]!['OTHER_PAYMENT'] =
                  (currencyTotals[activity.currency.id!]!['OTHER_PAYMENT'] ?? 0.0) + activity.amount;
            }

            final currencyId = activity.currency.id!;
            final paymentTypeName = activity.paymentType ?? 'Unknown Payment Type';

            paymentTypeBreakdown.putIfAbsent(currencyId, () => {});
            paymentTypeBreakdown[currencyId]!.update(
              paymentTypeName,
              (value) => value + activity.amount,
              ifAbsent: () => activity.amount,
            );
          }
        }
      }
    }

    if (currencyTotals.isEmpty) {
      buffer.writeln('No monetary activities recorded.');
    } else {
      for (final entry in currencyTotals.entries) {
        final currencyId = entry.key;
        final totals = entry.value;
        final currency = availableCurrencies.firstWhere(
          (c) => c.id == currencyId,
          orElse: () => Currency(id: currencyId, name: 'Unknown', symbol: '?'),
        );

        final cashInTotal = totals['CASH_IN'] ?? 0.0;
        final cashAccountTopUpTotal = totals['CASH_ACCOUNT_TOP_UP'] ?? 0.0;
        final otherAccountTopUpTotal = totals['OTHER_ACCOUNT_TOP_UP'] ?? 0.0;
        final cashOutTotal = totals['CASH_OUT'] ?? 0.0;
        final cashPaymentTotal = totals['CASH_PAYMENT'] ?? 0.0;
        final otherPaymentTotal = totals['OTHER_PAYMENT'] ?? 0.0;

        final totalSales = cashPaymentTotal + otherPaymentTotal;
        final totalCash = cashInTotal + cashAccountTopUpTotal - cashOutTotal + cashPaymentTotal;

        buffer.writeln('\n--- ${currency.name} (${currency.symbol}) ---');
        buffer.writeln(_alignLeftRight('Initial Cash:', '${currency.symbol} 0.00'));
        buffer.writeln(_alignLeftRight('Total Cash In:', '${currency.symbol} ${cashInTotal.toStringAsFixed(2)}'));
        if (cashAccountTopUpTotal > 0) {
          buffer.writeln(_alignLeftRight('Cash Customer Deposits:', '${currency.symbol} ${cashAccountTopUpTotal.toStringAsFixed(2)}'));
        }
        if (otherAccountTopUpTotal > 0) {
          buffer.writeln(_alignLeftRight('Other Customer Deposits:', '${currency.symbol} ${otherAccountTopUpTotal.toStringAsFixed(2)}'));
        }
        buffer.writeln(_alignLeftRight('Total Cash Out:', '${currency.symbol} ${cashOutTotal.toStringAsFixed(2)}'));
        buffer.writeln(_alignLeftRight('Total Cash Sales:', '${currency.symbol} ${cashPaymentTotal.toStringAsFixed(2)}'));
        buffer.writeln(_alignLeftRight('Total Other Sales:', '${currency.symbol} ${otherPaymentTotal.toStringAsFixed(2)}'));
        buffer.writeln(_alignLeftRight('Total Sales:', '${currency.symbol} ${totalSales.toStringAsFixed(2)}'));
        buffer.writeln(_alignLeftRight('Total Cash:', '${currency.symbol} ${totalCash.toStringAsFixed(2)}'));

        if (paymentTypeBreakdown.containsKey(currencyId) && paymentTypeBreakdown[currencyId]!.isNotEmpty) {
          buffer.writeln('\nSales by Payment Type:');
          for (final ptEntry in paymentTypeBreakdown[currencyId]!.entries) {
            buffer.writeln(_alignLeftRight('${ptEntry.key}:', '${currency.symbol} ${ptEntry.value.toStringAsFixed(2)}'));
          }
        }
      }
    }

    buffer.writeln('\n--------------------------------');
    buffer.writeln('      DETAILED ACTIVITIES');
    buffer.writeln('--------------------------------');

    if (shift.shiftCurrencyAmounts == null || shift.shiftCurrencyAmounts!.isEmpty) {
      buffer.writeln('No detailed activities recorded.');
    } else {
      for (final activity in shift.shiftCurrencyAmounts!) {
        String activityLabel;
        String amountPrefix = '';
        if (activity.amountType == 'CASH_IN') {
          activityLabel = 'Cash In';
        } else if (activity.amountType == 'ACCOUNT_TOP_UP') {
          activityLabel = 'Account Top Up';
        } else if (activity.amountType == 'CASH_OUT') {
          activityLabel = 'Cash Out';
          amountPrefix = '-';
        } else if (activity.amountType == 'SALE') {
          activityLabel = activity.isCash == true ? 'Cash Sale' : 'Other Sale';
        } else {
          activityLabel = activity.amountType;
        }

        buffer.writeln(_alignLeftRight('Time:', activity.timeCreated != null ? DateFormat(AppConstants.APP_DATE_TIME_FMT).format(DateTime.parse(activity.timeCreated!)) : 'N/A'));
        buffer.writeln(_alignLeftRight('Type:', activityLabel));
        buffer.writeln(_alignLeftRight('Amount:', '$amountPrefix${activity.currency.symbol} ${activity.amount.toStringAsFixed(2)}'));
        if (activity.notes != null && activity.notes!.isNotEmpty) {
          buffer.writeln(_alignLeftRight('Notes:', activity.notes!));
        }
        if (activity.posReference != null && activity.posReference!.isNotEmpty) {
          buffer.writeln(_alignLeftRight('Ref:', activity.posReference!));
        }
        buffer.writeln('---');
      }
    }

    buffer.writeln('--------------------------------');
    buffer.writeln('       Powered by Vimbika');
    buffer.writeln('--------------------------------');
    return buffer.toString();
  }

  // Dispose method to clean up resources
  void dispose() {
    _usbDiscoverySubscription?.cancel();
  }
}
