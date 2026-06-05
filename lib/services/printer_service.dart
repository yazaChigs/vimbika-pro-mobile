import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:blue_thermal_printer/blue_thermal_printer.dart' as bt;
import 'package:image/image.dart' as img;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sunmi_printer_plus/enums.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';
import 'package:sunmi_printer_plus/sunmi_style.dart';
import 'package:vimbika_pro/app_constants/app_constants.dart';
import 'package:vimbika_pro/model/product_feature.dart';
import 'package:vimbika_pro/model/sale.dart';
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
  bool _waScan = false;

  // USB Printer specific variables
  UsbPrinterDevice? _selectedUsbDevice;
  final List<UsbPrinterDevice> _usbDevices = [];

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
          print('Bluetooth auto-connect failed: $e');
          _isConnected = false;
        }
      }
    } else {
      _isConnected = false;
      print('Bluetooth printing is not supported on this platform.');
    }
  }

  Future<void> _initSunmi() async {
    _sunmiBound = (await SunmiPrinter.bindingPrinter()) ?? false;
    _isConnected = _sunmiBound;
  }

  Future<void> _initUsb() async {
    if (Platform.isWindows || Platform.isAndroid) {
      _printerManager.discovery(type: PrinterType.usb).listen((device) {
        if (device.vendorId != null && device.productId != null) {
          final usbDevice = UsbPrinterDevice(
            vendorId: device.vendorId as int?,
            productId: device.productId as int?,
            name: device.name,
          );
          if (!_usbDevices.contains(usbDevice)) {
            _usbDevices.add(usbDevice);
          }
        }
      });

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
          print('USB auto-connect failed: $e');
          _isConnected = false;
        }
      }
    } else {
      _isConnected = false;
      print('USB printing is not supported on this platform.');
    }
  }

  Future<void> setPrinterType(PrinterTypes type) async {
    if (_printerType == type) return;

    await disconnect(); // Disconnect current printer before changing type
    _printerType = type;
    _isConnected = false; // Reset connection status
    _selectedBluetoothDevice = null; // Clear selected BT device
    _selectedUsbDevice = null; // Clear selected USB device

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
      print('Bluetooth printing is not supported on this platform.');
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
      print('Bluetooth connection failed: $e');
      _isConnected = false;
      rethrow;
    }
  }

  Future<void> connectUsb(UsbPrinterDevice device) async {
    if (!(Platform.isWindows || Platform.isAndroid)) {
      print('USB printing is not supported on this platform.');
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
      print('USB connection failed: $e');
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

  Future<void> printPaymentReceipt(PaymentReceived payment) async {
    if (!_isConnected) {
      print('Printer not connected. Cannot print payment receipt.');
      return;
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
      print('Error printing payment receipt: $e');
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
    if (payment.payer != null) {
      buffer.writeln('Received From: ${payment.payer!.name}');
    }
    buffer.writeln('Amount: ${payment.currency?.symbol ?? ''} ${payment.amount.toStringAsFixed(2)}');
    buffer.writeln('Payment Method: ${payment.paymentType?.name ?? 'N/A'}');
    if (payment.bank != null) {
      buffer.writeln('Bank: ${payment.bank!.name}');
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
      print('Printer not connected. Cannot print sale receipt.');
      return;
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
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
    } catch (e) {
      print('Error printing sale receipt: $e');
      rethrow;
    }
  }

  Future<void> _printBluetoothSale(Sale sale) async {
    if (!(Platform.isAndroid || Platform.isIOS)) { // Add platform check
      print('Bluetooth printing is not supported on this platform.');
      return;
    }
    if (_selectedBluetoothDevice == null || !_isConnected) {
      throw Exception('Bluetooth printer not selected or not connected.');
    }

    List<int> bytes = [];
    final profile = await CapabilityProfile.load();
    final Generator generator = Generator(PaperSize.mm58, profile);

    // Get image
    if (sale.company?.id != null) {
      final DefaultDataService defaultDataService = DefaultDataService();
      final File? logoFile = await defaultDataService.getImage(sale.company!.id!);
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
          print('Could not print BT image $e');
        }
      }
    }

    bytes += generator.text(sale.company?.name ?? "Vimbika Pro", styles: PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
    bytes += generator.text(sale.branch?.name ?? "", styles: PosStyles(align: PosAlign.center));
    bytes += generator.text(sale.branch?.address ?? "", styles: PosStyles(align: PosAlign.center));

    if (sale.branch?.phoneNumber != null && sale.branch!.phoneNumber!.isNotEmpty) {
      bytes += generator.text("Tel: ${sale.branch!.phoneNumber!}", styles: PosStyles(align: PosAlign.center));
    } else if (sale.company?.phoneNumber != null && sale.company!.phoneNumber!.isNotEmpty) {
      bytes += generator.text("Tel: ${sale.company!.phoneNumber!}", styles: PosStyles(align: PosAlign.center));
    }
    if (sale.branch?.email != null && sale.branch!.email!.isNotEmpty) {
      bytes += generator.text("Email: ${sale.branch!.email!}", styles: PosStyles(align: PosAlign.center));
    } else if (sale.company?.email != null && sale.company!.email!.isNotEmpty) {
      bytes += generator.text("Email: ${sale.company!.email!}", styles: PosStyles(align: PosAlign.center));
    }

    bytes += generator.text("--------------------------------", styles: PosStyles(align: PosAlign.center));
    bytes += generator.text("Receipt #: ${sale.posReference ?? sale.posReference}", styles: PosStyles(align: PosAlign.left));
    bytes += generator.text("Date: ${sale.timeIniated}", styles: PosStyles(align: PosAlign.left));
    if (sale.customer != null) {
      bytes += generator.text("Customer: ${sale.customer!.name}", styles: PosStyles(align: PosAlign.left));
    }
    bytes += generator.text("--------------------------------", styles: PosStyles(align: PosAlign.center));
    bytes += generator.text("Item            Qty    Total", styles: PosStyles(align: PosAlign.left));
    bytes += generator.text("--------------------------------", styles: PosStyles(align: PosAlign.center));

    String symbol = sale.currency?.symbol ?? "";
    num totalItems = 0;
    for (var item in sale.items) {
      totalItems += item.quantity;
      String name = (item.inventoryItem?.name ?? "Item").padRight(15).substring(0, 15);
      String qty = item.quantity.toStringAsFixed(0).padLeft(3);
      String total = "$symbol${item.total.toStringAsFixed(2)}".padLeft(10);
      bytes += generator.text("$name $qty $total", styles: PosStyles(align: PosAlign.left));
    }

    bytes += generator.text("--------------------------------", styles: PosStyles(align: PosAlign.center));
    bytes += generator.text("Total Items: \t $totalItems", styles: PosStyles(align: PosAlign.left));
    bytes += generator.text("Net Amount: \t $symbol${(sale.baseSaleAmount ?? 0.0).toStringAsFixed(2)}", styles: PosStyles(align: PosAlign.left));
    bytes += generator.text("VAT Amount: \t $symbol${(sale.totalTaxAmount ?? 0.0).toStringAsFixed(2)}", styles: PosStyles(align: PosAlign.left));
    bytes += generator.text("TOTAL: $symbol${sale.grandTotal.toStringAsFixed(2)}", styles: PosStyles(align: PosAlign.right, bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
    bytes += generator.text("--------------------------------", styles: PosStyles(align: PosAlign.center));

    // Payment Details
    if (sale.paymentTypes != null && sale.paymentTypes!.isNotEmpty) {
      bytes += generator.text("Payment Details:", styles: PosStyles(align: PosAlign.left));
      for (var payment in sale.paymentTypes!) {
        bytes += generator.text("${payment.paymentType?.name ?? 'N/A'}: $symbol${payment.amount.toStringAsFixed(2)}", styles: PosStyles(align: PosAlign.left));
      }
      bytes += generator.text("--------------------------------", styles: PosStyles(align: PosAlign.center));
    }

    Currency? cur = sale.currency;
    if(sale.paymentTypes!.any((pt) => pt.paymentType?.name!.contains('ACC-') ?? false) && sale.customer != null && sale.customer!.currencyBalance != null && sale.customer!.currencyBalance!.isNotEmpty) {
      bytes += generator.text("Account Balance: ${cur?.symbol ?? ''} ${sale.customer!.currencyBalance!.firstWhere((cb) => cb.currency?.id == cur?.id, orElse: () => sale.customer!.currencyBalance!.first).balance!.toStringAsFixed(2)}", styles: PosStyles(align: PosAlign.left));
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
        final img.Image baseSizeImage = img.decodeImage(picData!.buffer.asUint8List())!;
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
      Uint8List waImageBytes = await generateWhatsappQR(sale.referenceNumber!, sale.currency!.symbol!, sale.amountAfterDiscount!);
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
    if (sale.company?.id != null) {
      final DefaultDataService defaultDataService = DefaultDataService();
      final File? logoFile = await defaultDataService.getImage(sale.company!.id!);
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
          print('Could not print SUNMI image $e');
        }
      }
    }
    await SunmiPrinter.printText(sale.company?.name ?? "Vimbika Pro", style: SunmiStyle(fontSize: SunmiFontSize.XL, align: SunmiPrintAlign.CENTER, bold: true));
    if (sale.branch != null) {
      await SunmiPrinter.printText("${sale.branch!.name}\n${sale.branch!.address ?? ''}", style: SunmiStyle(align: SunmiPrintAlign.CENTER));
    }

    // Add company/branch contact details
    if (sale.branch?.phoneNumber != null && sale.branch!.phoneNumber!.isNotEmpty) {
      await SunmiPrinter.printText("Tel: ${sale.branch!.phoneNumber!}", style: SunmiStyle(align: SunmiPrintAlign.CENTER));
    } else if (sale.company?.phoneNumber != null && sale.company!.phoneNumber!.isNotEmpty) {
      await SunmiPrinter.printText("Tel: ${sale.company!.phoneNumber!}", style: SunmiStyle(align: SunmiPrintAlign.CENTER));
    }
    if (sale.branch?.email != null && sale.branch!.email!.isNotEmpty) {
      await SunmiPrinter.printText("Email: ${sale.branch!.email!}", style: SunmiStyle(align: SunmiPrintAlign.CENTER));
    } else if (sale.company?.email != null && sale.company!.email!.isNotEmpty) {
      await SunmiPrinter.printText("Email: ${sale.company!.email!}", style: SunmiStyle(align: SunmiPrintAlign.CENTER));
    }

    await SunmiPrinter.lineWrap(1);
    await SunmiPrinter.printText("Receipt #: ${sale.id?.substring(0, 8).toUpperCase() ?? 'N/A'}\nDate: ${sale.timeIniated}", style: SunmiStyle(align: SunmiPrintAlign.LEFT));
    if (sale.customer != null) {
      await SunmiPrinter.printText("Customer: ${sale.customer!.name}", style: SunmiStyle(align: SunmiPrintAlign.LEFT));
    }
    await SunmiPrinter.printText("--------------------------------", style: SunmiStyle(align: SunmiPrintAlign.CENTER));
    
    String symbol = sale.currency?.symbol ?? "";
    num totalItems = 0;
    for (var item in sale.items) {
      totalItems += item.quantity;
      String name = (item.inventoryItem?.name ?? "Item").padRight(15).substring(0, 15);
      String qty = "x${item.quantity.toStringAsFixed(0)}".padLeft(5);
      String total = "$symbol${item.total.toStringAsFixed(2)}".padLeft(10);
      await SunmiPrinter.printText("$name$qty$total");
    }
    
    await SunmiPrinter.printText("--------------------------------", style: SunmiStyle(align: SunmiPrintAlign.CENTER));
    await SunmiPrinter.printText("Total Items: \t $totalItems", style: SunmiStyle(align: SunmiPrintAlign.LEFT));
    await SunmiPrinter.printText("Net Amount: \t $symbol${(sale.baseSaleAmount ?? 0.0).toStringAsFixed(2)}", style: SunmiStyle(align: SunmiPrintAlign.LEFT));
    await SunmiPrinter.printText("VAT Amount: \t $symbol${(sale.totalTaxAmount ?? 0.0).toStringAsFixed(2)}", style: SunmiStyle(align: SunmiPrintAlign.LEFT));
    await SunmiPrinter.printText("TOTAL: $symbol${sale.grandTotal.toStringAsFixed(2)}", style: SunmiStyle(fontSize: SunmiFontSize.LG, align: SunmiPrintAlign.RIGHT, bold: true));
    await SunmiPrinter.printText("--------------------------------", style: SunmiStyle(align: SunmiPrintAlign.CENTER));

    // Payment Details
    if (sale.paymentTypes != null && sale.paymentTypes!.isNotEmpty) {
      await SunmiPrinter.printText("Payment Details:", style: SunmiStyle(align: SunmiPrintAlign.LEFT));
      for (var payment in sale.paymentTypes!) {
        await SunmiPrinter.printText("${payment.paymentType?.name ?? 'N/A'}: $symbol${payment.amount.toStringAsFixed(2)}", style: SunmiStyle(align: SunmiPrintAlign.LEFT));
      }
      await SunmiPrinter.printText("--------------------------------", style: SunmiStyle(align: SunmiPrintAlign.CENTER));
    }

    Currency? cur = sale.currency;
    if(sale.paymentTypes!.any((pt) => pt.paymentType?.name!.contains('ACC-') ?? false))
    {
      await SunmiPrinter.printText(
          "Account Balance: ${cur?.symbol ?? ''} ${sale.customer!
              .currencyBalance!
              .firstWhere((cb) => cb.currency == cur)
              .balance!
              .toStringAsFixed(2)}");
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
      Uint8List waImageBytes = await generateWhatsappQR(sale.referenceNumber!, sale.currency!.symbol!, sale.amountAfterDiscount!);
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
      print('USB printing is not supported on this platform.');
      return;
    }
    if (_selectedUsbDevice == null || !_isConnected) {
      throw Exception('USB printer not selected or not connected.');
    }

    List<int> bytes = [];
    final profile = await CapabilityProfile.load();
    final Generator generator = Generator(PaperSize.mm58, profile);

    // Get image
    if (sale.company?.id != null) {
      final DefaultDataService defaultDataService = DefaultDataService();
      final File? logoFile = await defaultDataService.getImage(sale.company!.id!);
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
          print('Could not print USB image $e');
        }
      }
    }

    bytes += generator.text(sale.company?.name ?? "Vimbika Pro", styles: PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
    bytes += generator.text(sale.branch?.name ?? "", styles: PosStyles(align: PosAlign.center));
    bytes += generator.text(sale.branch?.address ?? "", styles: PosStyles(align: PosAlign.center));

    if (sale.branch?.phoneNumber != null && sale.branch!.phoneNumber!.isNotEmpty) {
      bytes += generator.text("Tel: ${sale.branch!.phoneNumber!}", styles: PosStyles(align: PosAlign.center));
    } else if (sale.company?.phoneNumber != null && sale.company!.phoneNumber!.isNotEmpty) {
      bytes += generator.text("Tel: ${sale.company!.phoneNumber!}", styles: PosStyles(align: PosAlign.center));
    }
    if (sale.branch?.email != null && sale.branch!.email!.isNotEmpty) {
      bytes += generator.text("Email: ${sale.branch!.email!}", styles: PosStyles(align: PosAlign.center));
    } else if (sale.company?.email != null && sale.company!.email!.isNotEmpty) {
      bytes += generator.text("Email: ${sale.company!.email!}", styles: PosStyles(align: PosAlign.center));
    }

    bytes += generator.text("--------------------------------", styles: PosStyles(align: PosAlign.center));
    bytes += generator.text("Receipt #: ${sale.posReference ?? sale.posReference}", styles: PosStyles(align: PosAlign.left));
    bytes += generator.text("Date: ${sale.timeIniated}", styles: PosStyles(align: PosAlign.left));
    if (sale.customer != null) {
      bytes += generator.text("Customer: ${sale.customer!.name}", styles: PosStyles(align: PosAlign.left));
    }
    bytes += generator.text("--------------------------------", styles: PosStyles(align: PosAlign.center));
    bytes += generator.text("Item            Qty    Total", styles: PosStyles(align: PosAlign.left));
    bytes += generator.text("--------------------------------", styles: PosStyles(align: PosAlign.center));
    
    String symbol = sale.currency?.symbol ?? "";
    num totalItems = 0;
    for (var item in sale.items) {
      totalItems += item.quantity;
      String name = (item.inventoryItem?.name ?? "Item").padRight(15).substring(0, 15);
      String qty = item.quantity.toStringAsFixed(0).padLeft(3);
      String total = "$symbol${item.total.toStringAsFixed(2)}".padLeft(10);
      bytes += generator.text("$name $qty $total", styles: PosStyles(align: PosAlign.left));
    }
    
    bytes += generator.text("--------------------------------", styles: PosStyles(align: PosAlign.center));
    bytes += generator.text("Total Items: \t $totalItems", styles: PosStyles(align: PosAlign.left));
    bytes += generator.text("Net Amount: \t $symbol${(sale.baseSaleAmount ?? 0.0).toStringAsFixed(2)}", styles: PosStyles(align: PosAlign.left));
    bytes += generator.text("VAT Amount: \t $symbol${(sale.totalTaxAmount ?? 0.0).toStringAsFixed(2)}", styles: PosStyles(align: PosAlign.left));
    bytes += generator.text("TOTAL: $symbol${sale.grandTotal.toStringAsFixed(2)}", styles: PosStyles(align: PosAlign.right, bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
    bytes += generator.text("--------------------------------", styles: PosStyles(align: PosAlign.center));

    // Payment Details
    if (sale.paymentTypes != null && sale.paymentTypes!.isNotEmpty) {
      bytes += generator.text("Payment Details:", styles: PosStyles(align: PosAlign.left));
      for (var payment in sale.paymentTypes!) {
        bytes += generator.text("${payment.paymentType?.name ?? 'N/A'}: $symbol${payment.amount.toStringAsFixed(2)}", styles: PosStyles(align: PosAlign.left));
      }
      bytes += generator.text("--------------------------------", styles: PosStyles(align: PosAlign.center));
    }

    Currency? cur = sale.currency;
    if(sale.paymentTypes!.any((pt) => pt.paymentType?.name!.contains('ACC-') ?? false) && sale.customer != null && sale.customer!.currencyBalance != null && sale.customer!.currencyBalance!.isNotEmpty) {
      bytes += generator.text("Account Balance: ${cur?.symbol ?? ''} ${sale.customer!.currencyBalance!.firstWhere((cb) => cb.currency?.id == cur?.id, orElse: () => sale.customer!.currencyBalance!.first).balance!.toStringAsFixed(2)}", styles: PosStyles(align: PosAlign.left));
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
        final img.Image baseSizeImage = img.decodeImage(picData!.buffer.asUint8List())!;
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
      Uint8List waImageBytes = await generateWhatsappQR(sale.referenceNumber!, sale.currency!.symbol!, sale.amountAfterDiscount!);
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
      print('Printer not connected. Cannot print receipt.');
      throw Exception('Printer not connected.');
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
          await Future.delayed(const Duration(milliseconds: 500)); // Small delay between prints
        }
      }
    } catch (e) {
      print('Error printing receipt: $e');
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
    final img.Image baseSizeImage = img.decodeImage(picData!.buffer.asUint8List())!;
    final img.Image grayscaleImage = img.grayscale(baseSizeImage);
    final Uint8List qrImageBytes = Uint8List.fromList(img.encodePng(grayscaleImage));
    return qrImageBytes;

  }


  /// Prints a sale receipt using structured sale data.
  /// This method formats the provided `saleData` into a human-readable receipt
  /// and then sends it to the currently selected and connected printer.
  ///
  /// The `saleData` map should contain keys like 'storeName', 'storeAddress',
  /// 'saleDateTime' (as DateTime), 'items' (List<Map<String, dynamic>>),
  /// 'subtotal', 'tax', and 'total'.
  /// Each item in 'items' should have 'name', 'quantity', and 'price'.
  ///
  /// Throws an [Exception] if the printer is not connected.
  Future<void> printSaleReceipt(Map<String, dynamic> saleData) async {
    if (!_isConnected) {
      print('Printer not connected. Cannot print sale receipt.');
      throw Exception('Printer not connected.');
    }

    try {
      final String formattedReceipt = _formatReceiptContent(saleData);
      await printReceipt(formattedReceipt);
    } catch (e) {
      print('Error printing sale receipt: $e');
      rethrow;
    }
  }

  Future<void> _printBluetoothReceipt(String content) async {
    if (!(Platform.isAndroid || Platform.isIOS)) { // Add platform check
      print('Bluetooth printing is not supported on this platform.');
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
      print('USB printing is not supported on this platform.');
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

    shift.shiftCurrencyAmounts?.forEach((activity) {
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
    });

    if (currencyTotals.isEmpty) {
      buffer.writeln('No monetary activities recorded.');
    } else {
      currencyTotals.entries.forEach((entry) {
        final currencyId = entry.key;
        final totals = entry.value;
        final currency = availableCurrencies.firstWhere((c) => c.id == currencyId);

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
          paymentTypeBreakdown[currencyId]!.entries.forEach((ptEntry) {
            buffer.writeln(_alignLeftRight('${ptEntry.key}:', '${currency.symbol} ${ptEntry.value.toStringAsFixed(2)}'));
          });
        }
      });
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

    shift.shiftCurrencyAmounts?.forEach((activity) {
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
    });

    if (currencyTotals.isEmpty) {
      buffer.writeln('No monetary activities recorded.');
    } else {
      currencyTotals.entries.forEach((entry) {
        final currencyId = entry.key;
        final totals = entry.value;
        final currency = availableCurrencies.firstWhere((c) => c.id == currencyId);

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
          paymentTypeBreakdown[currencyId]!.entries.forEach((ptEntry) {
            buffer.writeln(_alignLeftRight('${ptEntry.key}:', '${currency.symbol} ${ptEntry.value.toStringAsFixed(2)}'));
          });
        }
      });
    }

    buffer.writeln('\n--------------------------------');
    buffer.writeln('      DETAILED ACTIVITIES');
    buffer.writeln('--------------------------------');

    if (shift.shiftCurrencyAmounts == null || shift.shiftCurrencyAmounts!.isEmpty) {
      buffer.writeln('No detailed activities recorded.');
    } else {
      shift.shiftCurrencyAmounts!.forEach((activity) {
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
      });
    }

    buffer.writeln('--------------------------------');
    buffer.writeln('       Powered by Vimbika');
    buffer.writeln('--------------------------------');
    return buffer.toString();
  }
}
