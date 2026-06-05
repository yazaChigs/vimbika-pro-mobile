import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:blue_thermal_printer/blue_thermal_printer.dart';
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

enum PrinterTypes { bluetooth, sunmi }

class PrinterService {
  static final PrinterService _instance = PrinterService._internal();

  factory PrinterService() {
    return _instance;
  }

  PrinterService._internal();

  PrinterTypes _printerType = PrinterTypes.bluetooth;
  BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;
  BluetoothDevice? _selectedBluetoothDevice;
  bool _isConnected = false;
  bool _sunmiBound = false;
  bool _alwaysPrintReceipt = true; // Changed default to true
  int _numberOfReceiptsPerSale = 1; // Added for the new setting
  bool _waScan = false;

  // Getters for current printer status
  PrinterTypes get printerType => _printerType;
  bool get isConnected => _isConnected;
  BluetoothDevice? get selectedBluetoothDevice => _selectedBluetoothDevice;

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
      _selectedBluetoothDevice = BluetoothDevice(savedBluetoothName, savedBluetoothAddress);
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
    if (_printerType == PrinterTypes.bluetooth && _selectedBluetoothDevice != null) {
      await prefs.setString(AppConstants.keyPrinterMacAddress, _selectedBluetoothDevice!.address!);
      await prefs.setString(AppConstants.keyPrinterName, _selectedBluetoothDevice!.name!);
    } else {
      await prefs.remove(AppConstants.keyPrinterMacAddress);
      await prefs.remove(AppConstants.keyPrinterName);
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
    }
  }

  Future<void> _initBluetooth() async {
    if (Platform.isAndroid || Platform.isIOS) { // Add platform check
      bool? isAvailable = await _bluetooth.isAvailable;
      if (isAvailable == true && _selectedBluetoothDevice != null) {
        try {
          _isConnected = (await _bluetooth.isConnected) ?? false;
          if (!_isConnected) {
            await _bluetooth.connect(_selectedBluetoothDevice!);
            _isConnected = true;
          }
        } catch (e) {
          print('Bluetooth auto-connect failed: $e');
          _isConnected = false;
        }
      } else {
        _isConnected = false;
      }
    } else {
      // For unsupported platforms, ensure _isConnected is false
      _isConnected = false;
      print('Bluetooth printing is not supported on this platform.');
    }
  }

  Future<void> _initSunmi() async {
    _sunmiBound = (await SunmiPrinter.bindingPrinter()) ?? false;
    _isConnected = _sunmiBound;
  }

  Future<void> setPrinterType(PrinterTypes type) async {
    if (_printerType == type) return;

    await disconnect(); // Disconnect current printer before changing type
    _printerType = type;
    _isConnected = false; // Reset connection status
    _selectedBluetoothDevice = null; // Clear selected BT device

    await _savePrinterSettings();
    await init(); // Re-initialize with new type
  }

  Future<void> setSelectedBluetoothDevice(BluetoothDevice device) async {
    if (_selectedBluetoothDevice?.address == device.address) return;

    await disconnect();
    _selectedBluetoothDevice = device;
    _printerType = PrinterTypes.bluetooth; // Ensure type is bluetooth
    await _savePrinterSettings();
    await init(); // Attempt to connect
  }

  Future<void> connectBluetooth(BluetoothDevice device) async {
    if (!(Platform.isAndroid || Platform.isIOS)) { // Add platform check
      print('Bluetooth printing is not supported on this platform.');
      throw Exception('Bluetooth printing is not supported on this platform.');
    }
    try {
      await _bluetooth.connect(device);
      _selectedBluetoothDevice = device;
      _isConnected = true;
      await _savePrinterSettings();
    } catch (e) {
      print('Bluetooth connection failed: $e');
      _isConnected = false;
      rethrow;
    }
  }

  Future<void> disconnect() async {
    if (_printerType == PrinterTypes.bluetooth && _isConnected) {
      if (Platform.isAndroid || Platform.isIOS) { // Add platform check
        await _bluetooth.disconnect();
      }
      _isConnected = false;
    } else if (_printerType == PrinterTypes.sunmi && _isConnected) {
      // Sunmi doesn't usually require explicit disconnect in this context
      // but we can unbind if necessary, though it's often managed by the system.
      // For now, just update internal state.
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
    // Get image
    if (sale.company?.id != null) {
      final DefaultDataService defaultDataService = DefaultDataService();
      final File? logoFile = await defaultDataService.getImage(sale.company!.id!);
      if (logoFile != null && await logoFile.exists()) {
        try {
          // Most BlueThermalPrinter versions use printImage for local file paths.
          // For thermal printers, adding a clear line and small delay helps avoid buffer issues.
          // Using printImageBytes can sometimes be more reliable than path if the plugin has issues reading the file.
           _bluetooth.printNewLine();
           await Future.delayed(const Duration(milliseconds: 200));
           Uint8List imageBytes = await logoFile.readAsBytes();
           
           try {
             // Resize and convert to grayscale to ensure compatibility with most thermal printers
             img.Image? image = img.decodeImage(imageBytes);
             if (image != null) {
               // Standard thermal printer width is often 384 pixels for 58mm printers
               // We resize to 200 to be even safer and ensure it fits well
               img.Image resized = img.copyResize(image, width: 200);
               // Convert to grayscale/black and white for better thermal printing
               img.Image grayscale = img.grayscale(resized);
               // Use PNG instead of JPG as it's often more reliably decoded by the Android plugin
               imageBytes = Uint8List.fromList(img.encodePng(grayscale));
             }
           } catch (imageError) {
             print('Error processing image: $imageError');
             // Fallback to original bytes if processing fails
           }

           // Use printImageBytes after processing.
           // Note: printImageBytes decodes the bytes into a Bitmap on Android,
           // then converts that Bitmap to ESC/POS commands (GS v 0).
           _bluetooth.printImageBytes(imageBytes); 
           await Future.delayed(const Duration(milliseconds: 1000));
        } catch (e) {
           print('Could not print BT image $e');
        }
      }
    }
    _bluetooth.printNewLine();
    _bluetooth.printCustom(sale.company?.name ?? "Vimbika Pro", 3, 1);
    await Future.delayed(const Duration(milliseconds: 200));
    _bluetooth.printCustom(sale.branch?.name ?? "", 1, 1);
    await Future.delayed(const Duration(milliseconds: 100));
    _bluetooth.printCustom(sale.branch?.address ?? "", 1, 1);
    
    // Add company/branch contact details
    if (sale.branch?.phoneNumber != null && sale.branch!.phoneNumber!.isNotEmpty) {
      _bluetooth.printCustom("Tel: ${sale.branch!.phoneNumber!}", 1, 1);
    } else if (sale.company?.phoneNumber != null && sale.company!.phoneNumber!.isNotEmpty) {
      _bluetooth.printCustom("Tel: ${sale.company!.phoneNumber!}", 1, 1);
    }
    if (sale.branch?.email != null && sale.branch!.email!.isNotEmpty) {
      _bluetooth.printCustom("Email: ${sale.branch!.email!}", 1, 1);
    } else if (sale.company?.email != null && sale.company!.email!.isNotEmpty) {
      _bluetooth.printCustom("Email: ${sale.company!.email!}", 1, 1);
    }

    _bluetooth.printNewLine();
    _bluetooth.printCustom("Receipt #: ${sale.posReference ?? sale.posReference}", 1, 0);
    _bluetooth.printCustom("Date: ${sale.timeIniated}", 1, 0);
    if (sale.customer != null) {
      _bluetooth.printCustom("Customer: ${sale.customer!.name}", 1, 0);
    }
    _bluetooth.printCustom("--------------------------------", 1, 1);
    _bluetooth.printCustom("Item            Qty    Total", 1, 0);
    _bluetooth.printCustom("--------------------------------", 1, 1);
    
    String symbol = sale.currency?.symbol ?? "";
    num totalItems = 0;
    for (var item in sale.items) {
      totalItems += item.quantity;
      String name = (item.inventoryItem?.name ?? "Item").padRight(15).substring(0, 15);
      String qty = item.quantity.toStringAsFixed(0).padLeft(3);
      String total = "$symbol${item.total.toStringAsFixed(2)}".padLeft(10);
      _bluetooth.printCustom("$name $qty $total", 1, 0);
    }
    
    _bluetooth.printCustom("--------------------------------", 1, 1);
    _bluetooth.printCustom("Total Items: \t $totalItems", 1, 0);
    _bluetooth.printCustom("Net Amount: \t $symbol${(sale.baseSaleAmount ?? 0.0).toStringAsFixed(2)}", 1, 0);
    _bluetooth.printCustom("VAT Amount: \t $symbol${(sale.totalTaxAmount ?? 0.0).toStringAsFixed(2)}", 1, 0);
    _bluetooth.printCustom("TOTAL: $symbol${sale.grandTotal.toStringAsFixed(2)}", 2, 2);
    _bluetooth.printCustom("--------------------------------", 1, 1);

    // Payment Details
    if (sale.paymentTypes != null && sale.paymentTypes!.isNotEmpty) {
      _bluetooth.printCustom("Payment Details:", 1, 0);
      for (var payment in sale.paymentTypes!) {
        _bluetooth.printCustom("${payment.paymentType?.name ?? 'N/A'}: $symbol${payment.amount.toStringAsFixed(2)}", 1, 0);
      }
      _bluetooth.printCustom("--------------------------------", 1, 1);
    }

    Currency? cur = sale.currency;
    // Account Balance (if ACC- payment type is used) - unique to Sunmi, now added to Telpo
    if(sale.paymentTypes!.any((pt) => pt.paymentType?.name!.contains('ACC-') ?? false) && sale.customer != null && sale.customer!.currencyBalance != null && sale.customer!.currencyBalance!.isNotEmpty) {
      _bluetooth.printCustom("Account Balance: ${cur?.symbol ?? ''} ${sale.customer!.currencyBalance!.firstWhere((cb) => cb.currency?.id == cur?.id, orElse: () => sale.customer!.currencyBalance!.first).balance!.toStringAsFixed(2)}",1,0);
      _bluetooth.printCustom("--------------------------------\n", 1, 1);
    }

    // qr code
    if(sale.receiptQrCode != null){
      _bluetooth.printQRcode(sale.receiptQrCode!, 200, 200, 1);
      _bluetooth.printCustom("Scan the QR Code above", 1, 1);
      _bluetooth.printCustom(sale.receiptQrData!, 1, 1);
      _bluetooth.printCustom("You can verify this receipt manually at ", 1, 1);
      _bluetooth.printCustom(sale.receiptQrCode!, 1, 1);
    } else if(sale.receiptQrCode==null && _waScan){
      Uint8List waImageBytes = await generateWhatsappQR(sale.referenceNumber!, sale.currency!.symbol!, sale.amountAfterDiscount!);
      _bluetooth.printImageBytes(waImageBytes);
      _bluetooth.printNewLine();
    }

    _bluetooth.printNewLine();
    _bluetooth.printCustom("Thank you for your purchase!", 1, 1);
    _bluetooth.printNewLine();
    _bluetooth.printCustom("Powered by Vimbika", 1, 1); // Powered by Vimbika
    _bluetooth.printNewLine();
    _bluetooth.printNewLine();
    await Future.delayed(const Duration(milliseconds: 300));
    _bluetooth.paperCut();
    await Future.delayed(const Duration(milliseconds: 500));
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
      color: const Color(0xFF000000),
      emptyColor: const Color(0xFFFFFFFF),
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
    await _bluetooth.printNewLine();
    await Future.delayed(const Duration(milliseconds: 200));
    
    // Instead of printing the whole chunk at once (which might cause issues with center alignment
    // trying to center the block instead of interpreting spaces), print line by line
    final lines = content.split('\n');
    for (String line in lines) {
      // If a line is empty, skip printing or print new line,
      // here we just use printCustom which handles basic strings
      if (line.isNotEmpty) {
        // Size 1, Align 0 (Left) to respect the spaces we added for right-alignment
        await _bluetooth.printCustom(line, 1, 0); 
      } else {
        await _bluetooth.printNewLine();
      }
    }
    
    await _bluetooth.printNewLine();
    await _bluetooth.printNewLine();
    await Future.delayed(const Duration(milliseconds: 300));
    await _bluetooth.paperCut();
    await Future.delayed(const Duration(milliseconds: 500));
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
