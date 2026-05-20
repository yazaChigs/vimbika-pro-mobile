import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sunmi_printer_plus/enums.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';
import 'package:sunmi_printer_plus/sunmi_style.dart';
import 'package:vimbika_pro/app_constants/app_constants.dart';
import 'package:vimbika_pro/model/sale.dart';

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
  }

  Future<void> _initPrinters() async {
    if (_printerType == PrinterTypes.bluetooth) {
      await _initBluetooth();
    } else if (_printerType == PrinterTypes.sunmi) {
      await _initSunmi();
    }
  }

  Future<void> _initBluetooth() async {
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
      await _bluetooth.disconnect();
      _isConnected = false;
    } else if (_printerType == PrinterTypes.sunmi && _isConnected) {
      // Sunmi doesn't usually require explicit disconnect in this context
      // but we can unbind if necessary, though it's often managed by the system.
      // For now, just update internal state.
      _isConnected = false;
    }
    // Do not clear saved settings on disconnect, only on type change
  }

  /// Prints a sale receipt using the Sale model.
  Future<void> printSale(Sale sale) async {
    if (!_isConnected) {
      print('Printer not connected. Cannot print sale receipt.');
      return;
    }

    try {
      if (_printerType == PrinterTypes.bluetooth) {
        await _printBluetoothSale(sale);
      } else if (_printerType == PrinterTypes.sunmi) {
        await _printSunmiSale(sale);
      }
    } catch (e) {
      print('Error printing sale receipt: $e');
      rethrow;
    }
  }

  Future<void> _printBluetoothSale(Sale sale) async {
    _bluetooth.printNewLine();
    _bluetooth.printCustom(sale.company?.name ?? "Vimbika Pro", 3, 1);
    _bluetooth.printCustom(sale.branch?.name ?? "", 1, 1);
    _bluetooth.printCustom(sale.branch?.address ?? "", 1, 1);
    _bluetooth.printNewLine();
    _bluetooth.printCustom("Receipt #: ${sale.posReference ?? sale.posReference}", 1, 0);
    _bluetooth.printCustom("Date: ${sale.timeIniated}", 1, 0);
    if (sale.customer != null) {
      _bluetooth.printCustom("Customer: ${sale.customer!.name}", 1, 0);
    }
    _bluetooth.printCustom("--------------------------------", 1, 1);
    _bluetooth.printCustom("Item            Qty    Total", 1, 0);
    _bluetooth.printCustom("--------------------------------", 1, 1);
    
    for (var item in sale.items) {
      String name = (item.inventoryItem?.name ?? "Item").padRight(15).substring(0, 15);
      String qty = item.quantity.toStringAsFixed(0).padLeft(3);
      String total = item.total.toStringAsFixed(2).padLeft(10);
      _bluetooth.printCustom("$name $qty $total", 1, 0);
    }
    
    _bluetooth.printCustom("--------------------------------", 1, 1);
    _bluetooth.printCustom("TOTAL: ${sale.grandTotal.toStringAsFixed(2)}", 2, 2);
    _bluetooth.printCustom("--------------------------------", 1, 1);
    _bluetooth.printNewLine();
    _bluetooth.printCustom("Thank you for your purchase!", 1, 1);
    _bluetooth.printNewLine();
    _bluetooth.printNewLine();
    _bluetooth.paperCut();
  }

  Future<void> _printSunmiSale(Sale sale) async {
    await SunmiPrinter.initPrinter();
    await SunmiPrinter.startTransactionPrint(true);
    
    await SunmiPrinter.printText(sale.company?.name ?? "Vimbika Pro", style: SunmiStyle(fontSize: SunmiFontSize.XL, align: SunmiPrintAlign.CENTER, bold: true));
    if (sale.branch != null) {
      await SunmiPrinter.printText("${sale.branch!.name}\n${sale.branch!.address ?? ''}", style: SunmiStyle(align: SunmiPrintAlign.CENTER));
    }
    await SunmiPrinter.lineWrap(1);
    await SunmiPrinter.printText("Receipt #: ${sale.id?.substring(0, 8).toUpperCase() ?? 'N/A'}\nDate: ${sale.timeIniated}", style: SunmiStyle(align: SunmiPrintAlign.LEFT));
    if (sale.customer != null) {
      await SunmiPrinter.printText("Customer: ${sale.customer!.name}", style: SunmiStyle(align: SunmiPrintAlign.LEFT));
    }
    await SunmiPrinter.printText("--------------------------------", style: SunmiStyle(align: SunmiPrintAlign.CENTER));
    
    for (var item in sale.items) {
      String name = (item.inventoryItem?.name ?? "Item").padRight(15).substring(0, 15);
      String qty = "x${item.quantity.toStringAsFixed(0)}".padLeft(5);
      String total = item.total.toStringAsFixed(2).padLeft(10);
      await SunmiPrinter.printText("$name$qty$total");
    }
    
    await SunmiPrinter.printText("--------------------------------", style: SunmiStyle(align: SunmiPrintAlign.CENTER));
    await SunmiPrinter.printText("TOTAL: ${sale.grandTotal.toStringAsFixed(2)}", style: SunmiStyle(fontSize: SunmiFontSize.LG, align: SunmiPrintAlign.RIGHT, bold: true));
    await SunmiPrinter.printText("--------------------------------", style: SunmiStyle(align: SunmiPrintAlign.CENTER));
    await SunmiPrinter.lineWrap(1);
    await SunmiPrinter.printText("Thank you for your purchase!", style: SunmiStyle(align: SunmiPrintAlign.CENTER));
    
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
      if (_printerType == PrinterTypes.bluetooth) {
        await _printBluetoothReceipt(receiptContent);
      } else if (_printerType == PrinterTypes.sunmi) {
        await _printSunmiReceipt(receiptContent);
      }
    } catch (e) {
      print('Error printing receipt: $e');
      rethrow;
    }
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
    // Basic implementation, you'll need to format `content` properly
    // for ESC/POS commands if you need more advanced formatting.
    await _bluetooth.printCustom(content, 1, 1); // Size 1, Align 1 (center)
    await _bluetooth.printNewLine();
    await _bluetooth.printNewLine();
    await _bluetooth.paperCut();
  }

  Future<void> _printSunmiReceipt(String content) async {
    await SunmiPrinter.initPrinter();
    await SunmiPrinter.startTransactionPrint(true);
    await SunmiPrinter.printText(content, style: SunmiStyle(align: SunmiPrintAlign.CENTER));
    await SunmiPrinter.lineWrap(3);
    await SunmiPrinter.cut();
    await SunmiPrinter.submitTransactionPrint();
    await SunmiPrinter.exitTransactionPrint(true);
  }

  String _formatReceiptContent(Map<String, dynamic> saleData) {
    StringBuffer buffer = StringBuffer();

    // Example formatting - adjust as needed for your specific receipt layout
    buffer.writeln('----------------------------------------');
    buffer.writeln('          ${saleData['storeName'] ?? 'Vimbika Pro'}');
    buffer.writeln('          ${saleData['storeAddress'] ?? '123 Main St'}');
    buffer.writeln('----------------------------------------');
    final DateTime? saleDateTime = saleData['saleDateTime'] as DateTime?;
    buffer.writeln('Date: ${saleDateTime != null ? saleDateTime.toLocal().toString().substring(0, 16) : 'N/A'}');
    buffer.writeln('----------------------------------------');
    buffer.writeln('Item            Qty   Price     Total');
    buffer.writeln('----------------------------------------');

    List<Map<String, dynamic>> items = (saleData['items'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    for (var item in items) {
      final String name = item['name'] ?? '';
      final int quantity = item['quantity'] ?? 0;
      final double price = item['price'] ?? 0.0;
      final double itemTotal = quantity * price;
      buffer.writeln('${name.padRight(15).substring(0, 15)} ${quantity.toString().padLeft(3)} ${price.toStringAsFixed(2).padLeft(7)} ${itemTotal.toStringAsFixed(2).padLeft(7)}');
    }

    buffer.writeln('----------------------------------------');
    buffer.writeln('Subtotal:                 ${(saleData['subtotal'] ?? 0.0).toStringAsFixed(2).padLeft(7)}');
    buffer.writeln('Tax:                      ${(saleData['tax'] ?? 0.0).toStringAsFixed(2).padLeft(7)}');
    buffer.writeln('Total:                    ${(saleData['total'] ?? 0.0).toStringAsFixed(2).padLeft(7)}');
    buffer.writeln('----------------------------------------');
    buffer.writeln('        THANK YOU FOR YOUR PURCHASE!');
    buffer.writeln('----------------------------------------');

    return buffer.toString();
  }
}
