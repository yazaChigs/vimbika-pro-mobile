import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:bluetooth_print/bluetooth_print.dart';
import 'package:bluetooth_print/bluetooth_print_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sunmi_printer_plus/enums.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';
import 'package:telpo_m8/telpo_m8.dart';
import 'package:vimbika_pos_app/src/features/printers/model/available_printer_model.dart';
import 'package:vimbika_pos_app/src/features/sale/model/cart_item_model.dart';
import 'package:vimbika_pos_app/src/features/sale/model/sale_infor_model.dart';
import 'package:vimbika_pos_app/src/features/sale/model/sale_model.dart';
import 'package:vimbika_pos_app/src/features/shift/controller/shift_controller.dart';
import 'package:vimbika_pos_app/src/features/shift/model/currency_amount.dart';
import 'package:vimbika_pos_app/src/features/shift/model/shift_model.dart';
import 'package:vimbika_pos_app/src/features/stock_requests/model/transfer_history_model.dart';
import 'package:vimbika_pos_app/src/services/local_storage_service.dart';
import 'package:vimbika_pos_app/src/shared/models/currency_model.dart';
import 'package:image/image.dart' as img;
import 'package:vimbika_pos_app/src/shared/models/customer_model.dart';
import 'package:vimbika_pos_app/src/shared/models/payment_received_model.dart';

import '../constants/app_constants.dart';
import '../features/customers/controller/customer_controller.dart';
import '../shared/models/settings_model.dart';

class PrinterService extends GetxService {


  List<CurrencyModel> getOfflineCurrencyList(GetStorage box) {
    // Read the data as a List<dynamic>
    List<dynamic>? itemsListDynamic =
    box.read<List<dynamic>>(AppConstants.CURRENCY_LIST);
    // Check if the read data is not null
    if (itemsListDynamic != null) {
      // Convert the List<dynamic> to List<Map<String, dynamic>>
      List<Map<String, dynamic>> itemsListMap = itemsListDynamic.map((item) {
        return item as Map<String, dynamic>;
      }).toList();
      List<CurrencyModel> currencies = List<CurrencyModel>.from(
          itemsListMap.map((map) => CurrencyModel.fromMap(map)));
      return currencies;
    } else {
      return [];
    }
  }
  Future<void> printCurrentSale(SaleInfoModel saleInfo, GetStorage box,  LocalStorageService _localStorageService) async {
    AvailablePrinterModel? prin = _localStorageService.findActivePrinter(box);
        if (prin != null) {
          var box = GetStorage();
          SettingsModel settingsModel;
          var settings = box.read(AppConstants.COMPANY_SETTINGS) ?? {};
          settingsModel = SettingsModel.fromMap(Map<String, dynamic>.from(settings));
          if(prin.type == 'SUNMI_INBUILT_PRINTER') {
            await printSunmiSaleReceipt(saleInfo.sale!, settingsModel.enableWaInvReq??false);
          }
          if(prin.type == 'TELPO_INBUILT_PRINTER') {
            await printTelpoSaleReceipt(saleInfo.sale!, settingsModel.enableWaInvReq??false);
          }
          if (prin.type == 'bluetooth') {
            await generateBluetoothReceipt(saleInfo.sale!, prin, settingsModel.enableWaInvReq??false);
          }
          if (prin.type == 'usb') {
            await generateUSBReceipt(saleInfo.sale!, prin, settingsModel.enableWaInvReq??false);
          }
        } else {
          Get.snackbar('Error', 'Default Printer Not Found. Please add printer.',
              snackPosition: SnackPosition.BOTTOM);
          print("Default Printer Not Found. Please add printer.");
        }

  }
  Future<void> printKOT(SaleInfoModel saleInfo,String orderNum, GetStorage box,  LocalStorageService _localStorageService) async {
    print('[UI] printKOT invoked | orderNum=$orderNum | items=${saleInfo.sale?.items?.length ?? 0}');
    AvailablePrinterModel? prin = _localStorageService.findActivePrinter(box);
        if (prin != null) {
          print('[UI] default printer: type=${prin.type}, name=${prin.name}, vid=${prin.vendorId}, pid=${prin.productId}');
          if(prin.type == 'SUNMI_INBUILT_PRINTER') {
            await printSunmiKOT(saleInfo.sale!, orderNum);
          }
          if(prin.type == 'TELPO_INBUILT_PRINTER') {
            await printTelpoSaleReceipt(saleInfo.sale!, false);
          }
          if (prin.type == 'bluetooth') {
            await generateBluetoothReceipt(saleInfo.sale!, prin, false);
          }
          if (prin.type == 'usb') {
            await printKOTUsb(saleInfo.sale!, orderNum, prin);
          }
        } else {
          Get.snackbar('Error', 'Default Printer Not Found. Please add printer.',
              snackPosition: SnackPosition.BOTTOM);
          print("Default Printer Not Found. Please add printer.");
        }

  }
  Future<void> printBill(SaleInfoModel saleInfo, GetStorage box,  LocalStorageService _localStorageService) async {
    AvailablePrinterModel? prin = _localStorageService.findActivePrinter(box);

        if (prin != null) {
          if(prin.type == 'SUNMI_INBUILT_PRINTER') {
            await printSunmiSaleBill(saleInfo.sale!,getOfflineCurrencyList(box));
          }
          if(prin.type == 'TELPO_INBUILT_PRINTER') {
            await printTelpoSaleReceipt(saleInfo.sale!, false);
          }
          if (prin.type == 'bluetooth') {
            await generateBluetoothReceipt(saleInfo.sale!, prin, false);
          }
          if (prin.type == 'usb') {
            await generateUSBReceipt(saleInfo.sale!, prin ,false);
          }
        } else {
          Get.snackbar('Error', 'Default Printer Not Found. Please add printer.',
              snackPosition: SnackPosition.BOTTOM);
          print("Default Printer Not Found. Please add printer.");
        }

  }
  Future<void> printCashIn(PaymentReceivedModel payment,String? cashier, GetStorage box,  LocalStorageService _localStorageService) async {
    AvailablePrinterModel? prin = _localStorageService.findActivePrinter(box);
        if (prin != null) {
          if(prin.type == 'SUNMI_INBUILT_PRINTER') {
            await printSunmiCashIn(payment,cashier);
          }
         /* if(prin.type == 'TELPO_INBUILT_PRINTER') {
            await printTelpoSaleReceipt(saleInfo.sale!);
          }
          if (prin.type == 'bluetooth') {
            await generateBluetoothReceipt(saleInfo.sale!, prin);
          }
          if (prin.type == 'usb') {
            await generateUSBReceipt(saleInfo.sale!, prin);
          }*/
        } else {
          Get.snackbar('Error', 'Default Printer Not Found. Please add printer.',
              snackPosition: SnackPosition.BOTTOM);
          print("Default Printer Not Found. Please add printer.");
        }

  }
  Future<void> printCustomerStatement(CustomerModel customer,List<CustomerProjectionModel> customerProjections, GetStorage box,  LocalStorageService _localStorageService, {String? dateRangeDescription}) async {
    AvailablePrinterModel? prin = _localStorageService.findActivePrinter(box);
        if (prin != null) {
          if(prin.type == 'SUNMI_INBUILT_PRINTER') {
            await printSunmiCustomerStatement(customer,customerProjections, dateRangeDescription: dateRangeDescription);
          } else if(prin.type == 'usb') {
            await generateUSBCustomerStatement(customer, customerProjections, prin, dateRangeDescription: dateRangeDescription);
          }
         /* if(prin.type == 'TELPO_INBUILT_PRINTER') {
            await printTelpoSaleReceipt(saleInfo.sale!);
          }
          if (prin.type == 'bluetooth') {
            await generateBluetoothReceipt(saleInfo.sale!, prin);
          }*/
        } else {
          Get.snackbar('Error', 'Default Printer Not Found. Please add printer.',
              snackPosition: SnackPosition.BOTTOM);
          print("Default Printer Not Found. Please add printer.");
        }

  }
  Future<void> printQuickKOT(List<CartItemModel> items,String? cashier, String customer, String reference, GetStorage box,  LocalStorageService _localStorageService) async {
    print('[UI] printQuickKOT invoked | items=${items.length} | cashier=$cashier | customer=$customer | ref=$reference');
    AvailablePrinterModel? prin = _localStorageService.findActivePrinter(box);
        if (prin != null) {
          print('[UI] default printer: type=${prin.type}, name=${prin.name}, vid=${prin.vendorId}, pid=${prin.productId}');
          if(prin.type == 'SUNMI_INBUILT_PRINTER') {
            await printSunmiQuickKOT(items, cashier, customer, reference);
          }
          if (prin.type == 'usb') {
            await printQuickKOTUsb(items, cashier, customer, reference, prin);
          }
          /*if(prin.type == 'TELPO_INBUILT_PRINTER') {
            await printTelpoSaleReceipt(saleInfo.sale!);
          }
          if (prin.type == 'bluetooth') {
            await generateBluetoothReceipt(saleInfo.sale!, prin);
          }
          */
        } else {
          Get.snackbar('Error', 'Default Printer Not Found. Please add printer.',
              snackPosition: SnackPosition.BOTTOM);
          print("Default Printer Not Found. Please add printer.");
        }

  }
  Future<void> printCurrentGRV(TransferHistoryModel transfer, GetStorage box,  LocalStorageService _localStorageService) async {
    AvailablePrinterModel? prin = _localStorageService.findActivePrinter(box);
    if (prin != null) {
      if(prin.type == 'SUNMI_INBUILT_PRINTER') {
      await printSunmiGRV(transfer);
      }
      if(prin.type == 'TELPO_INBUILT_PRINTER') {
       // await printTelpoSaleReceipt(saleInfo.sale!);
      }
      if (prin.type == 'bluetooth') {
        await generateBluetoothGoodsReceivedVoucher(transfer, prin);
      }
      if (prin.type == 'usb') {
       // await generateUSBReceipt(saleInfo.sale!, prin);
      }
    } else {
      Get.snackbar('Error', 'Default Printer Not Found. Please add printer.',
          snackPosition: SnackPosition.BOTTOM);
      print("Default Printer Not Found. Please add printer.");
    }

  }

  generateBluetoothReceipt(SaleModel sale, AvailablePrinterModel printer, bool waScan) async {
    BluetoothPrint bluetoothPrint = await BluetoothPrint.instance;
    await bluetoothPrint.disconnect();
    Uint8List imageBytes = await readLocalFileBytes();

    // Encode the image to base64 string
    String logoBase64 = base64Encode(imageBytes);
    BluetoothDevice bt = BluetoothDevice();
    bt.name = printer.name;
    bt.address = printer.address;
    await bluetoothPrint.connect(bt);
    await Future.delayed(Duration(seconds: 3));
    List<LineText> receiptData = [];
    CurrencyModel? cur = sale.currency;
    var box = GetStorage();
    
    // Get Fiscal Device information (from backend format)
    String? vatNumber;
    String? deviceSerialNo;
    int? deviceId;
    try {
      var fiscalDeviceModel = box.read(AppConstants.FISCAL_DEVICE);
      if (fiscalDeviceModel != null && fiscalDeviceModel is Map) {
        vatNumber = fiscalDeviceModel["vatNumber"]?.toString();
        deviceSerialNo = fiscalDeviceModel["deviceSerialNo"]?.toString();
        deviceId = fiscalDeviceModel["deviceId"] != null ? int.tryParse(fiscalDeviceModel["deviceId"].toString()) : null;
      }
    } catch (e) {
      print("Error reading fiscal device: $e");
    }
    
    receiptData.add(LineText(type: LineText.TYPE_TEXT, content: '\n\n', weight: 1, align: LineText.ALIGN_CENTER,linefeed: 1));

    // Header

   // Add the logo to the receipt
    print("print logo ..");
    receiptData.add(LineText(
      type: LineText.TYPE_IMAGE,
      content: logoBase64,
      height: 200,
      width: 200,
      align: LineText.ALIGN_CENTER,
      linefeed: 1,
    ));
    
    // Fiscal Device VAT Number (from backend format - after logo, before RECEIPT)
    if (vatNumber != null && vatNumber.isNotEmpty) {
      receiptData.add(LineText(
        type: LineText.TYPE_TEXT,
        content: 'VAT No: $vatNumber',
        align: LineText.ALIGN_LEFT,
        linefeed: 1,
      ));
    }
    
    receiptData.add(LineText(
      type: LineText.TYPE_TEXT,
      content: 'RECEIPT',
      size: 2,
      align: LineText.ALIGN_CENTER,
      weight: 2, // Bold
      linefeed: 1,
    ));

    receiptData.add(LineText(
      type: LineText.TYPE_TEXT,
      content: 'Cashier: ${sale.cashierFullName}',
      align: LineText.ALIGN_LEFT,
      linefeed: 1,
    ));

    receiptData.add(LineText(
      type: LineText.TYPE_TEXT,
      content: 'Date: ${sale.timeIniated}',
      align: LineText.ALIGN_LEFT,
      linefeed: 1,
    ));

    // Invoice No (from backend format)
    receiptData.add(LineText(
      type: LineText.TYPE_TEXT,
      content: 'Invoice No: ${sale.referenceNumber}',
      align: LineText.ALIGN_LEFT,
      linefeed: 1,
    ));

    // Customer Information (if any)
    if (sale.customer != null) {
      receiptData.add(LineText(
        type: LineText.TYPE_TEXT,
        content: 'Customer: ${sale.customer!.name}',
        align: LineText.ALIGN_LEFT,
        linefeed: 1,
      ));
      // Customer company name (from backend format)
      if (sale.customer!.companyName != null && sale.customer!.companyName!.isNotEmpty) {
        receiptData.add(LineText(
          type: LineText.TYPE_TEXT,
          content: '${sale.customer!.companyName}',
          align: LineText.ALIGN_LEFT,
          linefeed: 1,
        ));
      }
      // Customer tax number (from backend format)
      if (sale.customer!.taxNumber != null && sale.customer!.taxNumber!.isNotEmpty) {
        receiptData.add(LineText(
          type: LineText.TYPE_TEXT,
          content: 'TIN: ${sale.customer!.taxNumber}',
          align: LineText.ALIGN_LEFT,
          linefeed: 1,
        ));
      }
      // Customer email (from backend format)
      if (sale.customer!.email != null && sale.customer!.email!.isNotEmpty) {
        receiptData.add(LineText(
          type: LineText.TYPE_TEXT,
          content: '${sale.customer!.email}',
          align: LineText.ALIGN_LEFT,
          linefeed: 1,
        ));
      }
      // Customer ref number (from backend format)
      if (sale.customer!.customerId != null && sale.customer!.customerId!.isNotEmpty) {
        receiptData.add(LineText(
          type: LineText.TYPE_TEXT,
          content: 'Customer reference No: ${sale.customer!.customerId}',
          align: LineText.ALIGN_LEFT,
          linefeed: 1,
        ));
      }
    }

    // Separator
    receiptData.add(LineText(
      type: LineText.TYPE_TEXT,
      content: '--------------------------------',
      align: LineText.ALIGN_CENTER,
      linefeed: 1,
    ));

    // Items
    for (var item in sale.items!) {
      String itemName = item.inventoryItem?.name ?? 'Item';
      double quantity = item.quantity ?? 0;
      double price = item.sellingPrice ?? 0;
      double total = item.total ?? 0;
      total = total * cur!.rate!;
      price = price * cur!.rate!;

      // Product Name in Bold and Large Text
      receiptData.add(LineText(
        type: LineText.TYPE_TEXT,
        content: itemName,
        align: LineText.ALIGN_LEFT,
        weight: 2, // Bold
        size: 1,   // Larger text size
        linefeed: 1,
      ));

      // Quantity and Price on the same line
      String qtyPriceLine = 'Qty: ${quantity}    Price: ${cur!.symbol} ${price.toStringAsFixed(2)}';

      receiptData.add(LineText(
        type: LineText.TYPE_TEXT,
        content: qtyPriceLine,
        align: LineText.ALIGN_LEFT,
        linefeed: 1,
      ));

      // Total
      receiptData.add(LineText(
        type: LineText.TYPE_TEXT,
        content: 'Total: ${cur!.symbol} ${total.toStringAsFixed(2)}',
        align: LineText.ALIGN_LEFT,
        linefeed: 1,
      ));

      // Underline below each item
      receiptData.add(LineText(
        type: LineText.TYPE_TEXT,
        content: '--------------------------------',
        align: LineText.ALIGN_CENTER,
        linefeed: 1,
      ));
    }

    // Totals
    // Calculate net and gross amounts (from backend format)
    double netAmount = (sale.amountAfterDiscount ?? 0.0) - (sale.totalTaxAmount ?? 0.0);
    double grossAmount = sale.amountAfterDiscount ?? 0.0;
    
    // Net Amount (from backend format)
    receiptData.add(LineText(
      type: LineText.TYPE_TEXT,
      content: 'Net Amount: ${cur!.symbol} ${netAmount.toStringAsFixed(2)}',
      align: LineText.ALIGN_LEFT,
      linefeed: 1,
    ));
    
    // VAT (if > 0 - from backend format)
    if (sale.totalTaxAmount != null && sale.totalTaxAmount! > 0) {
      receiptData.add(LineText(
        type: LineText.TYPE_TEXT,
        content: 'VAT: ${cur.symbol} ${sale.totalTaxAmount!.toStringAsFixed(2)}',
        align: LineText.ALIGN_LEFT,
        linefeed: 1,
      ));
    }
    
    // Gross Amount (from backend format)
    receiptData.add(LineText(
      type: LineText.TYPE_TEXT,
      content: 'Gross Amount: ${cur.symbol} ${grossAmount.toStringAsFixed(2)}',
      align: LineText.ALIGN_LEFT,
      linefeed: 1,
    ));

    // Payment Methods (like Sunmi)
    receiptData.add(LineText(
      type: LineText.TYPE_TEXT,
      content: 'Amount Paid: ${cur.symbol} ${sale.amountPaid?.toStringAsFixed(2)} \t\t${sale.paymentTypes!.map((pt)=>pt.paymentType!.name!).join(', ')}',
      align: LineText.ALIGN_RIGHT,
      linefeed: 1,
    ));

    receiptData.add(LineText(
      type: LineText.TYPE_TEXT,
      content: 'Change: ${cur.symbol} ${sale.change?.toStringAsFixed(2)}',
      align: LineText.ALIGN_RIGHT,
      linefeed: 1,
    ));

    // Tip (if present) - missing feature added
    if(sale.tipAmount != null && sale.tipAmount! > 0) {
      receiptData.add(LineText(
        type: LineText.TYPE_TEXT,
        content: 'Tip: ${cur.symbol} ${sale.tipAmount!.toStringAsFixed(2)}',
        align: LineText.ALIGN_RIGHT,
        linefeed: 1,
      ));
    }

    // Account Balance (if ACC- payment type is used) - unique to Sunmi, now added to Bluetooth
    if(sale.paymentTypes!.any((pt) => pt.paymentType?.name!.contains('ACC-') ?? false) && sale.customer != null && sale.customer!.currencyBalance != null && sale.customer!.currencyBalance!.isNotEmpty) {
      receiptData.add(LineText(
        type: LineText.TYPE_TEXT,
        content: 'Account Balance: ${cur.symbol} ${sale.customer!.currencyBalance!.firstWhere((cb) => cb.currency?.id == cur?.id, orElse: () => sale.customer!.currencyBalance!.first).balance!.toStringAsFixed(2)}',
        align: LineText.ALIGN_RIGHT,
        linefeed: 1,
      ));
    }

    // Fiscal Device details (from backend format - if fiscalized)
    if (sale.fiscalized == true) {
      if (deviceSerialNo != null && deviceSerialNo.isNotEmpty) {
        receiptData.add(LineText(
          type: LineText.TYPE_TEXT,
          content: 'Device Serial No: $deviceSerialNo',
          align: LineText.ALIGN_LEFT,
          linefeed: 1,
        ));
      }
      if (deviceId != null) {
        receiptData.add(LineText(
          type: LineText.TYPE_TEXT,
          content: 'Device ID: $deviceId',
          align: LineText.ALIGN_LEFT,
          linefeed: 1,
        ));
      }
    }

    receiptData.add(LineText(
      type: LineText.TYPE_TEXT,
      content: '\n',
      align: LineText.ALIGN_CENTER,
      linefeed: 1,
    ));

    // QR Code
    if(sale.receiptQrCode != null) {

      print("Printing qr code..");
      Uint8List imageBytes = await generateBlueToothQR(sale.receiptQrCode!);
      String qrCode = base64Encode(imageBytes);
      receiptData.add(LineText(
        type: LineText.TYPE_IMAGE,
        content: qrCode,
        align: LineText.ALIGN_CENTER,
        width: 200,
        height: 200
      ));
      receiptData.add(LineText(
        type: LineText.TYPE_TEXT,
        content: sale.receiptQrData!,
        align: LineText.ALIGN_CENTER,
        linefeed: 1,
      ));
      receiptData.add(LineText(
        type: LineText.TYPE_TEXT,
        content: 'You can verify this receipt manually at',
        align: LineText.ALIGN_CENTER,
        linefeed: 1,
      ));
      receiptData.add(LineText(
        type: LineText.TYPE_TEXT,
        content: sale.receiptQrCode!,
        align: LineText.ALIGN_CENTER,
        linefeed: 1,
      ));
    } else if(sale.receiptQrCode==null && waScan){
      Uint8List waImageBytes = await generateWhatsappQR(sale.referenceNumber!, sale.currency!.symbol!, sale.amountAfterDiscount!);
      String waQrCode = base64Encode(waImageBytes);
      receiptData.add(LineText(
          type: LineText.TYPE_IMAGE,
          content: waQrCode,
          align: LineText.ALIGN_CENTER,
          width: 200,
          height: 200
      ));
    }

    // Footer
    receiptData.add(LineText(
      type: LineText.TYPE_TEXT,
      content: 'Thank you for your purchase!',
      align: LineText.ALIGN_CENTER,
      linefeed: 1,
      weight: 1,
    ));
    receiptData.add(LineText(type: LineText.TYPE_TEXT, content: '\n\n\n\n', weight: 1, align: LineText.ALIGN_CENTER,linefeed: 1));

    receiptData.add(LineText(linefeed: 1));
    Map<String, dynamic> config = Map();
    await bluetoothPrint.printReceipt(config, receiptData);
  }



  Future<void> generateBluetoothGoodsReceivedVoucher(TransferHistoryModel transfer, AvailablePrinterModel printer) async {
    BluetoothPrint bluetoothPrint = await BluetoothPrint.instance;
    await bluetoothPrint.disconnect();
    Uint8List imageBytes = await readLocalFileBytes();

    // Encode the image to base64 string
    String logoBase64 = base64Encode(imageBytes);
    BluetoothDevice bt = BluetoothDevice();
    bt.name = printer.name;
    bt.address = printer.address;
    await bluetoothPrint.connect(bt);
    await Future.delayed(Duration(seconds: 3));

    List<LineText> receiptData = [];
    String todayDate = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

    // Add the logo
    receiptData.add(LineText(
      type: LineText.TYPE_IMAGE,
      content: logoBase64,
      height: 200,
      width: 200,
      align: LineText.ALIGN_CENTER,
      linefeed: 1,
    ));

    // Title: GOODS RECEIVED VOUCHER
    receiptData.add(LineText(
      type: LineText.TYPE_TEXT,
      content: 'GOODS RECEIVED VOUCHER',
      size: 2,
      align: LineText.ALIGN_CENTER,
      weight: 2, // Bold
      linefeed: 1,
    ));

    // Transfer Details
    receiptData.add(LineText(
      type: LineText.TYPE_TEXT,
      content: 'Reference: ${transfer.reference ?? "N/A"}',
      align: LineText.ALIGN_LEFT,
      linefeed: 1,
    ));

    receiptData.add(LineText(
      type: LineText.TYPE_TEXT,
      content: 'Date: ${transfer.dateTime ?? "N/A"}',
      align: LineText.ALIGN_LEFT,
      linefeed: 1,
    ));

    receiptData.add(LineText(
      type: LineText.TYPE_TEXT,
      content: 'From Branch: ${transfer.fromBranch?.name ?? "N/A"}',
      align: LineText.ALIGN_LEFT,
      linefeed: 1,
    ));

    receiptData.add(LineText(
      type: LineText.TYPE_TEXT,
      content: 'To Branch: ${transfer.toBranch?.name ?? "N/A"}',
      align: LineText.ALIGN_LEFT,
      linefeed: 1,
    ));

    // Separator
    receiptData.add(LineText(
      type: LineText.TYPE_TEXT,
      content: '--------------------------------',
      align: LineText.ALIGN_CENTER,
      linefeed: 1,
    ));

// Separator
    receiptData.add(LineText(type: LineText.TYPE_TEXT, content: '--------------------------------', align: LineText.ALIGN_CENTER, linefeed: 1));

    // Items List with separate sections
    for (var item in transfer.transferItems ?? []) {
      String itemName = item.item?.name ?? 'Unknown Item';
      String quantity = item.quantity?.toStringAsFixed(2) ?? "0.00";
      String allocated = item.allocated?.toStringAsFixed(2) ?? "0.00";

      // Item Section
      receiptData.add(LineText(type: LineText.TYPE_TEXT, content: 'Item: $itemName', align: LineText.ALIGN_LEFT, weight: 2, linefeed: 1));
      receiptData.add(LineText(type: LineText.TYPE_TEXT, content: 'Quantity: $quantity', align: LineText.ALIGN_LEFT, linefeed: 1));
      receiptData.add(LineText(type: LineText.TYPE_TEXT, content: 'Allocated: $allocated', align: LineText.ALIGN_LEFT, linefeed: 1));

      // Divider between items
      receiptData.add(LineText(type: LineText.TYPE_TEXT, content: '--------------------------------', align: LineText.ALIGN_CENTER, linefeed: 1));
    }

      // Signature Sections
    receiptData.add(LineText(
      type: LineText.TYPE_TEXT,
      content: 'Received By: _______________________',
      align: LineText.ALIGN_LEFT,
      linefeed: 2,
    ));

    receiptData.add(LineText(
      type: LineText.TYPE_TEXT,
      content: 'Signature: _________________________',
      align: LineText.ALIGN_LEFT,
      linefeed: 2,
    ));

    receiptData.add(LineText(
      type: LineText.TYPE_TEXT,
      content: 'Delivered By: ______________________',
      align: LineText.ALIGN_LEFT,
      linefeed: 2,
    ));

    receiptData.add(LineText(
      type: LineText.TYPE_TEXT,
      content: 'Signature: _________________________',
      align: LineText.ALIGN_LEFT,
      linefeed: 2,
    ));

    // Footer with Date
    receiptData.add(LineText(
      type: LineText.TYPE_TEXT,
      content: 'Date: $todayDate',
      align: LineText.ALIGN_LEFT,
      linefeed: 1,
    ));

    // Thank you message

    receiptData.add(LineText(
      type: LineText.TYPE_TEXT,
      content: 'THANK YOU',
      size: 2,
      align: LineText.ALIGN_CENTER,
      weight: 1, // Bold
      linefeed: 1,
    ));

    receiptData.add(LineText(type: LineText.TYPE_TEXT, content: '\n\n\n\n', weight: 1, align: LineText.ALIGN_CENTER, linefeed: 1));

    receiptData.add(LineText(linefeed: 1));
    Map<String, dynamic> config = Map();
    await bluetoothPrint.printReceipt(config, receiptData);
  }


  generateUSBReceipt(SaleModel sale,  AvailablePrinterModel printer, bool waScan) async {
     print("=== USB RECEIPT DEBUG: Function called ===");
     print("USB RECEIPT DEBUG: Sale Reference: ${sale.referenceNumber}");
     print("USB RECEIPT DEBUG: Printer Name: ${printer.name}");
     print("USB RECEIPT DEBUG: Printer Vendor ID: ${printer.vendorId}");
     print("USB RECEIPT DEBUG: Printer Product ID: ${printer.productId}");
     print("USB RECEIPT DEBUG: WA Scan: $waScan");
     
     final profile = await CapabilityProfile.load();
     final generator = Generator(PaperSize.mm80, profile);

     List<int> receiptData = [];

     CurrencyModel? cur = sale.currency;
     var box = GetStorage();
     print("USB RECEIPT DEBUG: Currency: ${cur?.symbol ?? 'N/A'}");
     
     // Get Fiscal Device information (from backend format)
     String? vatNumber;
     String? deviceSerialNo;
     int? deviceId;
     try {
       var fiscalDeviceModel = box.read(AppConstants.FISCAL_DEVICE);
       if (fiscalDeviceModel != null && fiscalDeviceModel is Map) {
         vatNumber = fiscalDeviceModel["vatNumber"]?.toString();
         deviceSerialNo = fiscalDeviceModel["deviceSerialNo"]?.toString();
         deviceId = fiscalDeviceModel["deviceId"] != null ? int.tryParse(fiscalDeviceModel["deviceId"].toString()) : null;
       }
     } catch (e) {
       print("USB RECEIPT DEBUG: Error reading fiscal device: $e");
     }
     print("USB RECEIPT DEBUG: VAT Number: $vatNumber");
     print("USB RECEIPT DEBUG: Device Serial No: $deviceSerialNo");
     print("USB RECEIPT DEBUG: Device ID: $deviceId");

     // Load company logo
     print("USB RECEIPT DEBUG: Loading company logo...");
     try {
       Uint8List imageBytes = await readLocalFileBytes();
       print("USB RECEIPT DEBUG: Logo loaded, bytes: ${imageBytes.length}");
       
       if (imageBytes.isNotEmpty) {
         // Convert image to ESC/POS compatible format
         try {
           final img.Image? image = img.decodeImage(imageBytes);
           if (image != null) {
             // Resize image to fit receipt width (max 384 pixels for 80mm paper)
             final img.Image resized = img.copyResize(image, width: 200);
             receiptData += generator.image(resized);
             receiptData += generator.feed(1);
             print("USB RECEIPT DEBUG: Logo image added to receipt");
           } else {
             print("USB RECEIPT DEBUG: ⚠️ Could not decode logo image, continuing without logo");
           }
         } catch (e) {
           print("USB RECEIPT DEBUG: ⚠️ Error processing logo image: $e, continuing without logo");
         }
       } else {
         print("USB RECEIPT DEBUG: ⚠️ Logo file is empty, continuing without logo");
       }
     } catch (e) {
       print("USB RECEIPT DEBUG: ⚠️ Error loading logo file: $e, continuing without logo");
       // Continue without logo - don't crash the receipt printing
     }

     // Fiscal Device VAT Number (from backend format - after logo, before RECEIPT)
     if (vatNumber != null && vatNumber.isNotEmpty) {
       receiptData += generator.text('VAT No: $vatNumber',
           styles: PosStyles(align: PosAlign.left));
     }

     // Header
     receiptData += generator.text('RECEIPT',
         styles: PosStyles(
           align: PosAlign.center,
           bold: true,
           height: PosTextSize.size2,
           width: PosTextSize.size2,
         ));
     receiptData += generator.text('Cashier: ${sale.cashierFullName}',
         styles: PosStyles(align: PosAlign.left));
     receiptData += generator.text('Date: ${sale.timeIniated}',
         styles: PosStyles(align: PosAlign.left));
     // Invoice No (from backend format)
     receiptData += generator.text('Invoice No: ${sale.referenceNumber}',
         styles: PosStyles(align: PosAlign.left));

     // Customer Information (if any)
     if (sale.customer != null) {
       receiptData += generator.text('Customer: ${sale.customer!.name}',
           styles: PosStyles(align: PosAlign.left));
       // Customer company name (from backend format)
       if (sale.customer!.companyName != null && sale.customer!.companyName!.isNotEmpty) {
         receiptData += generator.text('${sale.customer!.companyName}',
             styles: PosStyles(align: PosAlign.left));
       }
       // Customer tax number (from backend format)
       if (sale.customer!.taxNumber != null && sale.customer!.taxNumber!.isNotEmpty) {
         receiptData += generator.text('TIN: ${sale.customer!.taxNumber}',
             styles: PosStyles(align: PosAlign.left));
       }
       // Customer email (from backend format)
       if (sale.customer!.email != null && sale.customer!.email!.isNotEmpty) {
         receiptData += generator.text('${sale.customer!.email}',
             styles: PosStyles(align: PosAlign.left));
       }
       // Customer ref number (from backend format)
       if (sale.customer!.customerId != null && sale.customer!.customerId!.isNotEmpty) {
         receiptData += generator.text('Customer reference No: ${sale.customer!.customerId}',
             styles: PosStyles(align: PosAlign.left));
       }
     }

     // Separator
     receiptData += generator.text('--------------------------------',
         styles: PosStyles(align: PosAlign.center));

     // Items
     print("USB RECEIPT DEBUG: Processing ${sale.items?.length ?? 0} items...");
     for (var item in sale.items!) {
       String itemName = item.inventoryItem?.name ?? 'Item';
       double quantity = item.quantity ?? 0;
       double price = item.sellingPrice ?? 0;
       double total = item.total ?? 0;

       // Product Name in Bold
       receiptData += generator.text(itemName,
           styles: PosStyles(align: PosAlign.left, bold: true));

       // Quantity and Price on the same line
       String qtyPriceLine = 'Qty: ${quantity}    Price: ${price.toStringAsFixed(2)}';
       receiptData += generator.text(qtyPriceLine, styles: PosStyles(align: PosAlign.left));

       // Total
       receiptData += generator.text('Total: ${total.toStringAsFixed(2)}',
           styles: PosStyles(align: PosAlign.left));

       // Separator for each item
       receiptData += generator.text('--------------------------------',
           styles: PosStyles(align: PosAlign.center));
     }

    // Calculate net and gross amounts (from backend format)
    double netAmount = (sale.amountAfterDiscount ?? 0.0) - (sale.totalTaxAmount ?? 0.0);
    double grossAmount = sale.amountAfterDiscount ?? 0.0;
    
    // Net Amount (from backend format)
    receiptData += generator.text('Net Amount: ${cur?.symbol ?? ''} ${netAmount.toStringAsFixed(2)}',
        styles: PosStyles(align: PosAlign.left));
    
    // VAT (if > 0 - from backend format)
    if (sale.totalTaxAmount != null && sale.totalTaxAmount! > 0) {
      receiptData += generator.text('VAT: ${cur?.symbol ?? ''} ${sale.totalTaxAmount!.toStringAsFixed(2)}',
          styles: PosStyles(align: PosAlign.left));
    }
    
    // Gross Amount (from backend format)
    receiptData += generator.text('Gross Amount: ${cur?.symbol ?? ''} ${grossAmount.toStringAsFixed(2)}',
        styles: PosStyles(align: PosAlign.left));

    print("USB RECEIPT DEBUG: Receipt data built, total bytes: ${receiptData.length}");
    print("USB RECEIPT DEBUG: Net Amount: $netAmount, Gross Amount: $grossAmount");

    // Payment Methods (like Sunmi)
    receiptData += generator.text('Amount Paid: ${cur?.symbol} ${sale.amountPaid?.toStringAsFixed(2)} \t\t${sale.paymentTypes!.map((pt)=>pt.paymentType!.name!).join(', ')}',
        styles: PosStyles(align: PosAlign.right));

    // Change
    receiptData += generator.text('Change: ${cur?.symbol} ${sale.change?.toStringAsFixed(2)}',
        styles: PosStyles(align: PosAlign.right));

    // Tip (if present) - missing feature added
    if(sale.tipAmount != null && sale.tipAmount! > 0) {
      receiptData += generator.text('Tip: ${cur?.symbol} ${sale.tipAmount!.toStringAsFixed(2)}',
          styles: PosStyles(align: PosAlign.right));
    }

    // Account Balance (if ACC- payment type is used) - unique to Sunmi, now added to USB
    if(sale.paymentTypes!.any((pt) => pt.paymentType?.name!.contains('ACC-') ?? false) && sale.customer != null && sale.customer!.currencyBalance != null && sale.customer!.currencyBalance!.isNotEmpty) {
      receiptData += generator.text('Account Balance: ${cur?.symbol} ${sale.customer!.currencyBalance!.firstWhere((cb) => cb.currency?.id == cur?.id, orElse: () => sale.customer!.currencyBalance!.first).balance!.toStringAsFixed(2)}',
          styles: PosStyles(align: PosAlign.right));
    }
     // Fiscal Device details (from backend format - if fiscalized)
     if (sale.fiscalized == true) {
       if (deviceSerialNo != null && deviceSerialNo.isNotEmpty) {
         receiptData += generator.text('Device Serial No: $deviceSerialNo',
             styles: PosStyles(align: PosAlign.left));
       }
       if (deviceId != null) {
         receiptData += generator.text('Device ID: $deviceId',
             styles: PosStyles(align: PosAlign.left));
       }
     }
     
     // Footer
     receiptData += generator.text('Thank you for your purchase!',
         styles: PosStyles(align: PosAlign.center));
     receiptData += generator.feed(1);
      if(waScan) {
        // Load whatsapp qr
        Uint8List waImageBytes = await generateWhatsappQR(
            sale.referenceNumber!, sale.currency!.symbol!, sale.amountAfterDiscount!);
        // Convert image to ESC/POS compatible format
        try {
          final img.Image? waImage = img.decodeImage(waImageBytes);
          if (waImage != null) {
            // Resize image to fit receipt width (max 384 pixels for 80mm paper)
            final img.Image resized = img.copyResize(waImage, width: 200);
            receiptData += generator.image(resized);
            receiptData += generator.feed(1);
          }
        } catch (e) {
          print('Error processing logo image: $e');
        }
      }
     receiptData += generator.feed(2); // Feed lines for spacing
     receiptData += generator.cut(); // Cut the paper
     
     print("USB RECEIPT DEBUG: Final receipt data size: ${receiptData.length} bytes");
     print("USB RECEIPT DEBUG: Creating USB printer input model...");
     
     // Validate printer IDs
     if (printer.vendorId == null || printer.productId == null) {
       print("USB RECEIPT DEBUG: ❌ ERROR: Vendor ID or Product ID is null!");
       print("USB RECEIPT DEBUG: Vendor ID: ${printer.vendorId}, Product ID: ${printer.productId}");
       Get.snackbar('Error', 'Invalid printer configuration: Missing Vendor ID or Product ID',
           snackPosition: SnackPosition.BOTTOM);
       return;
     }
     
     var model = UsbPrinterInput(name: printer.name, vendorId: printer.vendorId, productId: printer.productId);
     
     try {
       print("USB RECEIPT DEBUG: === Attempting to connect to printer ===");
       print("USB RECEIPT DEBUG: Printer Name: ${printer.name}");
       print("USB RECEIPT DEBUG: Vendor ID: ${printer.vendorId}");
       print("USB RECEIPT DEBUG: Product ID: ${printer.productId}");
       
       bool connected = await PrinterManager.instance.connect(type: PrinterType.usb, model: model);
       
       print("USB RECEIPT DEBUG: Connection result: $connected");
       
       if (!connected) {
         print("USB RECEIPT DEBUG: ❌ Connection FAILED");
         Get.snackbar('Error', 'Failed to connect to printer',
             snackPosition: SnackPosition.BOTTOM);
         return;
       }
       
       print("USB RECEIPT DEBUG: ✅ Connected successfully!");
       print("USB RECEIPT DEBUG: Sending ${receiptData.length} bytes of data to printer...");
       
       await PrinterManager.instance.send(
         bytes: receiptData, // Data to be printed
         type: PrinterType.usb,
       );
       
       print("USB RECEIPT DEBUG: ✅ Data sent successfully!");
       print("USB RECEIPT DEBUG: === USB Print Complete ===");
       
       // Note: Don't disconnect for receipts to keep connection for multiple prints
     } catch (e, stackTrace) {
       print("USB RECEIPT DEBUG: ❌ ERROR during printing: $e");
       print("USB RECEIPT DEBUG: Stack trace: $stackTrace");
       Get.snackbar('Error', 'Failed to print receipt: $e',
           snackPosition: SnackPosition.BOTTOM);
     }
   }

  // Generate USB Customer Statement
  Future<void> generateUSBCustomerStatement(CustomerModel customer, List<CustomerProjectionModel>? projectionsa, AvailablePrinterModel printer, {String? dateRangeDescription}) async {
    print("==================== PRINTING ACCOUNT STATEMENT (USB) ====================");
    print("Customer: ${customer.name}");
    print("Total transactions to print: ${projectionsa?.length ?? 0}");
    
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> receiptData = [];

    // Load company logo
    Uint8List imageBytes = await readLocalFileBytes();
    
    // Convert image to ESC/POS compatible format
    try {
      final img.Image? image = img.decodeImage(imageBytes);
      if (image != null) {
        final img.Image resized = img.copyResize(image, width: 200);
        receiptData += generator.image(resized);
      }
    } catch (e) {
      print('Error processing logo image: $e');
    }

    // Header
    receiptData += generator.text('ACCOUNT STATEMENT',
        styles: PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ));
    receiptData += generator.text('Date: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
        styles: PosStyles(align: PosAlign.left));
    
    // Date Range (if provided)
    if (dateRangeDescription != null && dateRangeDescription.isNotEmpty) {
      receiptData += generator.text('Period: $dateRangeDescription',
          styles: PosStyles(align: PosAlign.left));
    }
    
    // Separator
    receiptData += generator.text('--------------------------------',
        styles: PosStyles(align: PosAlign.center));

    // Customer Information
    receiptData += generator.text('Customer: ${customer.name}',
        styles: PosStyles(align: PosAlign.left, bold: true));

    // Separator
    receiptData += generator.text('--------------------------------',
        styles: PosStyles(align: PosAlign.center));

    // Transaction items
    if (projectionsa != null && projectionsa.isNotEmpty) {
      for (var payment in projectionsa) {
        String date = payment.paymentReceived!.dateTime!.substring(0, 10);
        String reference = payment.reference ?? 'N/A';
        String description = payment.paymentReceived!.paymentDescription ?? '';
        String type = payment.paymentReceived!.paymentType!.isCredit! ? 'CR' : 'DR';
        String currencySymbol = payment.paymentReceived!.currency?.symbol ?? '\$';
        double amount = payment.paymentReceived!.amount ?? 0.0;
        double balance = payment.paymentReceived!.accountBalance ?? 0.0;

        // Date and Reference
        receiptData += generator.text('$date  Ref: $reference',
            styles: PosStyles(align: PosAlign.left, bold: true));
        
        // Description and Payment Method on same line
        String paymentMethod = payment.paymentReceived?.paymentType?.name ?? '';
        String combinedLine = '$description';
        if (paymentMethod.isNotEmpty) {
          combinedLine += ' | $paymentMethod';
        }
        receiptData += generator.text(combinedLine,
            styles: PosStyles(align: PosAlign.left));
        
        // Amount and Type on own line
        receiptData += generator.text('$type  $currencySymbol ${amount.toStringAsFixed(2)}',
            styles: PosStyles(align: PosAlign.left));
        
        // Balance
        receiptData += generator.text('Balance: $currencySymbol ${balance.toStringAsFixed(2)}',
            styles: PosStyles(align: PosAlign.right));
      }
    } else {
      receiptData += generator.text('No transactions found.',
          styles: PosStyles(align: PosAlign.center));
    }

    // Final Balance
    receiptData += generator.text('Final Balance: ${customer.accountBalance?.toStringAsFixed(2) ?? '0.00'}',
        styles: PosStyles(align: PosAlign.right, bold: true));

    // Footer
    receiptData += generator.text('--------------------------------',
        styles: PosStyles(align: PosAlign.center));
    receiptData += generator.text('Thank you',
        styles: PosStyles(align: PosAlign.center));
    receiptData += generator.feed(1);
    receiptData += generator.cut();

    // Send to printer
    try {
      print("Connecting to USB printer: ${printer.name}");
      var model = UsbPrinterInput(name: printer.name, vendorId: printer.vendorId, productId: printer.productId);
      bool connected = await PrinterManager.instance.connect(type: PrinterType.usb, model: model);
      
      if (!connected) {
        print("ERROR: Failed to connect to USB printer");
        Get.snackbar('Error', 'Failed to connect to printer',
            snackPosition: SnackPosition.BOTTOM);
        return;
      }
      
      print("USB printer connected successfully. Sending data...");
      print("Receipt data size: ${receiptData.length} bytes");
      
      // Small delay to ensure printer is ready
      await Future.delayed(Duration(milliseconds: 100));
      
      await PrinterManager.instance.send(
        bytes: receiptData,
        type: PrinterType.usb,
      );
      
      print("✓ Data sent to printer successfully");
      
      // Wait for printer to finish processing before disconnecting
      // Statements may be longer, so give more time
      await Future.delayed(Duration(milliseconds: 1000));
      
      // Disconnect after printing statement (unlike receipts which stay connected)
      await PrinterManager.instance.disconnect(type: PrinterType.usb);
      print("✓ Disconnected from printer");
      
      Get.snackbar('Success', 'Account statement printed successfully',
          snackPosition: SnackPosition.BOTTOM);
      
      print("==================== ACCOUNT STATEMENT PRINTED (USB) ====================");
    } catch (e, stackTrace) {
      print("ERROR printing account statement: $e");
      print("Stack trace: $stackTrace");
      Get.snackbar('Error', 'Failed to print account statement: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

   PrinterType? parsePrinterType(String value) {
     switch (value.toLowerCase()) {
       case "bluetooth":
         return PrinterType.bluetooth;
       case "usb":
         return PrinterType.usb;
       case "network":
         return PrinterType.network;
       default:
         return null;
     }
   }


  Future<bool> initializeSunmiLCD() async {
    // Only initialize Sunmi on Android platforms
    if (Platform.isWindows) {
      print("Sunmi LCD not available on Windows");
      return false;
    }
    
    try {
      // 1. Bind to the native Sunmi service - MOST IMPORTANT STEP
      bool? isBound = await SunmiPrinter.bindingPrinter();
      if (isBound != true) {
        print("Failed to bind to printer service");
        return false;
      }

      // 2. Initialize the printer (required for LCD too)
      await SunmiPrinter.initPrinter();

      // 3. Power on and prepare the LCD display
      await SunmiPrinter.lcdInitialize();
      await SunmiPrinter.lcdWakeup(); // Ensure it's not in sleep mode

      print("Sunmi LCD is ready for commands.");
      return true;

    } catch (e) {
      print("Initialization error: $e");
      return false;
    }
  }

  Future<void>  sendTextToLCD() async {
    try {
      await SunmiPrinter.lcdString("Hello");
      await SunmiPrinter.lcdString("World!");
    } catch (e) {
      print("Failed to send text to LCD: $e");
    }
  }

  Future<void> _showSaleOnLCD(String itemName, double price) async {
    try {
      // Format the first line: Left-aligned item, right-aligned price
      // We have 20 characters total. Let's use 14 for the name, 6 for the price.
      String formattedLine1 = itemName.padRight(14).substring(0, 14) +
          '\$${price.toStringAsFixed(2)}'.padLeft(6);
      await SunmiPrinter.lcdString(formattedLine1);

      // Format the second line: A separator or a message
      String formattedLine2 = '--------------------'; // 20 dashes
      // or
      // String formattedLine2 = 'Please pay...'.padLeft(16); // Roughly center

      await SunmiPrinter.lcdString(formattedLine2);

    } catch (e) {
      print("Error displaying sale: $e");
    }
  }

    printShiftDetailsBluetooth(ShiftModel shift,  AvailablePrinterModel printer,  List<Map<String, dynamic>> totalAmountsByCurrency) async {
     BluetoothPrint bluetoothPrint = await BluetoothPrint.instance;
     BluetoothDevice bt = BluetoothDevice();
     bt.name = printer.name;
     bt.address = printer.address;
     await bluetoothPrint.connect(bt);
     await Future.delayed(Duration(seconds: 3));
     List<LineText> list = [];

     // Adding shift details
     list.add(LineText(type: LineText.TYPE_TEXT, content: 'Shift Details\n', weight: 2, align: LineText.ALIGN_CENTER, linefeed: 1));

     list.add(LineText(type: LineText.TYPE_TEXT, content: 'User: ${shift.userFullName ?? ''}\n', linefeed: 1));
     list.add(LineText(type: LineText.TYPE_TEXT, content: 'OT: ${shift.openingTime ?? ''}\n', linefeed: 1));
     list.add(LineText(type: LineText.TYPE_TEXT, content: 'CT: ${shift.closingTime ?? ''}\n', linefeed: 1));

     // Adding currency amounts
     if (shift.shiftCurrencyAmounts != null && shift.shiftCurrencyAmounts!.isNotEmpty) {
       list.add(LineText(type: LineText.TYPE_TEXT, content: '\nTransactions:\n', weight: 2, align: LineText.ALIGN_LEFT, linefeed: 1));

       shift.shiftCurrencyAmounts!.forEach((currencyAmount) {
         list.add(LineText(
           type: LineText.TYPE_TEXT,
           content: 'Ref: ${currencyAmount.ref}\nTime: ${currencyAmount.timeCreated}\nCurrency: ${currencyAmount.currency.name}\nAmount: ${currencyAmount.amount.toString()}\nType: ${currencyAmount.amountType ?? ''}\n\n',
           linefeed: 1,
         ));
       });
     } else {
       list.add(LineText(type: LineText.TYPE_TEXT, content: 'No transactions available.\n', linefeed: 1));
     }

     if (totalAmountsByCurrency.isNotEmpty) {
       list.add(LineText(type: LineText.TYPE_TEXT,
           content: '\nAmounts by Currency:\n',
           weight: 2,
           align: LineText.ALIGN_LEFT,
           linefeed: 1));
       totalAmountsByCurrency.forEach((total) {
         list.add(LineText(
           type: LineText.TYPE_TEXT,
           content: 'Currency: ${total['currencyName']}\nAmount: ${total['totalAmount']}\n\n',
           linefeed: 1,
         ));
       });
     }

     // Final message
     list.add(LineText(type: LineText.TYPE_TEXT, content: '***Thank you!!***\n\n\n', weight: 1, align: LineText.ALIGN_CENTER, linefeed: 1));
     list.add(LineText(type: LineText.TYPE_TEXT, content: '\n\n\n\n', weight: 1, align: LineText.ALIGN_CENTER,linefeed: 1));

     // Config for the printer (if needed)
     Map<String, dynamic> config = Map();

     // Sending the data to the printer
     await bluetoothPrint.printReceipt(config, list);
   }

   // Print Sale Receipt
   Future<void> printSunmiSaleReceipt(SaleModel sale, bool waScan) async {
     // Only print on Android platforms
     if (Platform.isWindows) {
       print("Sunmi printer not available on Windows");
       return;
     }
     
     CurrencyModel? cur = sale.currency;
     var box = GetStorage();
     
     // Get Fiscal Device information (from backend format)
     String? vatNumber;
     String? deviceSerialNo;
     int? deviceId;
     try {
       var fiscalDeviceModel = box.read(AppConstants.FISCAL_DEVICE);
       if (fiscalDeviceModel != null && fiscalDeviceModel is Map) {
         vatNumber = fiscalDeviceModel["vatNumber"]?.toString();
         deviceSerialNo = fiscalDeviceModel["deviceSerialNo"]?.toString();
         deviceId = fiscalDeviceModel["deviceId"] != null ? int.tryParse(fiscalDeviceModel["deviceId"].toString()) : null;
       }
     } catch (e) {
       print("Error reading fiscal device: $e");
     }

     Uint8List imageBytes = await readLocalFileBytes();

     await SunmiPrinter.initPrinter();
     await SunmiPrinter.startTransactionPrint(true);

     // Header
     await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
     await SunmiPrinter.printImage(imageBytes); // Directly print the image bytes

     // Fiscal Device VAT Number (from backend format - after logo, before RECEIPT)
     if (vatNumber != null && vatNumber.isNotEmpty) {
       await SunmiPrinter.setAlignment(SunmiPrintAlign.LEFT);
       await SunmiPrinter.printText("VAT No: $vatNumber");
     }

     await SunmiPrinter.setFontSize(SunmiFontSize.XL);
     await SunmiPrinter.printText("\n");
     await SunmiPrinter.printText("RECEIPT");
     await SunmiPrinter.resetFontSize();

     await SunmiPrinter.setAlignment(SunmiPrintAlign.LEFT);
     await SunmiPrinter.printText("Cashier: ${sale.cashierFullName}");
     await SunmiPrinter.printText("Date: ${sale.timeIniated}");
     // Invoice No (from backend format)
     await SunmiPrinter.printText("Invoice No: ${sale.referenceNumber}");

     // Customer Information
     if (sale.customer != null) {
       await SunmiPrinter.printText("Customer: ${sale.customer!.name}");
       // Customer company name (from backend format)
       if (sale.customer!.companyName != null && sale.customer!.companyName!.isNotEmpty) {
         await SunmiPrinter.printText("${sale.customer!.companyName}");
       }
       // Customer tax number (from backend format)
       if (sale.customer!.taxNumber != null && sale.customer!.taxNumber!.isNotEmpty) {
         await SunmiPrinter.printText("TIN: ${sale.customer!.taxNumber}");
       }
       // Customer email (from backend format)
       if (sale.customer!.email != null && sale.customer!.email!.isNotEmpty) {
         await SunmiPrinter.printText("${sale.customer!.email}");
       }
       // Customer ref number (from backend format)
       if (sale.customer!.customerId != null && sale.customer!.customerId!.isNotEmpty) {
         await SunmiPrinter.printText("Customer reference No: ${sale.customer!.customerId}");
       }
     }

     // Separator
     await SunmiPrinter.printText("--------------------------------");

     // Items
     for (var item in sale.items!) {
       String itemName = item.inventoryItem?.name ?? "Item";
       double quantity = item.quantity ?? 0;
       double price = item.sellingPrice ?? 0;
       double total = item.total ?? 0;
       total = total * cur!.rate!;
       price = price * cur!.rate!;
       await SunmiPrinter.printText("$itemName");
       await SunmiPrinter.printText("Qty: $quantity  Price: ${cur.symbol ?? ''} ${price.toStringAsFixed(2)}");
       await SunmiPrinter.printText("Total: ${cur.symbol ?? ''} ${total.toStringAsFixed(2)}");
       // await SunmiPrinter.printText("--------------------------------");
     }

     // Separator
     await SunmiPrinter.printText("--------------------------------");
     // Calculate net and gross amounts (from backend format)
     double netAmount = (sale.amountAfterDiscount ?? 0.0) - (sale.totalTaxAmount ?? 0.0);
     double grossAmount = sale.amountAfterDiscount ?? 0.0;
     
     // Net Amount (from backend format)
     await SunmiPrinter.printText("Net Amount: ${cur?.symbol ?? ''} ${netAmount.toStringAsFixed(2)}");
     
     // VAT (if > 0 - from backend format)
     if (sale.totalTaxAmount != null && sale.totalTaxAmount! > 0) {
       await SunmiPrinter.printText("VAT: ${cur?.symbol ?? ''} ${sale.totalTaxAmount!.toStringAsFixed(2)}");
     }
     
     // Gross Amount (from backend format)
     await SunmiPrinter.printText("Gross Amount: ${cur?.symbol ?? ''} ${grossAmount.toStringAsFixed(2)}");
     
     // Totals
     await SunmiPrinter.printText("Amount Paid: ${cur?.symbol ?? ''} ${sale.amountPaid?.toStringAsFixed(2)} \t\t${sale.paymentTypes!.map((pt)=>pt.paymentType!.name!).join(', ')}");
     await SunmiPrinter.printText("Change: ${cur?.symbol ?? ''} ${sale.change?.toStringAsFixed(2)}\n");
     if(sale.paymentTypes!.any((pt) => pt.paymentType?.name!.contains('ACC-') ?? false))
       {
         await SunmiPrinter.printText(
             "Account Balance: ${cur?.symbol ?? ''} ${sale.customer!
                 .currencyBalance!
                 .firstWhere((cb) => cb.currency == cur)
                 .balance!
                 .toStringAsFixed(2)}");
       }



     //qr code

     if(sale.receiptQrCode != null){
       await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
       await SunmiPrinter.printQRCode(sale.receiptQrCode!);
       await SunmiPrinter.printText("Scan the QR Code above");
       await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
       await SunmiPrinter.printText(sale.receiptQrData! + "");
       await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
       await SunmiPrinter.printText("You can verify this receipt manually at ");
       await SunmiPrinter.printText(sale.receiptQrCode! + "");
     } else if(sale.receiptQrCode==null && waScan){
       Uint8List waImageBytes = await generateWhatsappQR(sale.referenceNumber!, sale.currency!.symbol!, sale.amountAfterDiscount!);
       await SunmiPrinter.printImage(waImageBytes);
     }

     // Fiscal Device details (from backend format - if fiscalized)
     if (sale.fiscalized == true) {
       if (deviceSerialNo != null && deviceSerialNo.isNotEmpty) {
         await SunmiPrinter.setAlignment(SunmiPrintAlign.LEFT);
         await SunmiPrinter.printText("Device Serial No: $deviceSerialNo");
       }
       if (deviceId != null) {
         await SunmiPrinter.setAlignment(SunmiPrintAlign.LEFT);
         await SunmiPrinter.printText("Device ID: $deviceId");
       }
     }

     // Footer
     await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
     await SunmiPrinter.printText("*** Thank you for your purchase! ***");
     await SunmiPrinter.printText("\n\n\n");
     await SunmiPrinter.submitTransactionPrint();
     await SunmiPrinter.exitTransactionPrint(true);
   }
  Future<void> printSunmiSaleBill(SaleModel sale,List<CurrencyModel> currencies) async {
    // Only print on Android platforms
    if (Platform.isWindows) {
      print("Sunmi printer not available on Windows");
      return;
    }
    
    CurrencyModel? cur = sale.currency;
    currencies.removeWhere((c) => c.id == cur!.id);

     Uint8List imageBytes = await readLocalFileBytes();

     await SunmiPrinter.initPrinter();
     await SunmiPrinter.startTransactionPrint(true);



     // Header
     await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
     await SunmiPrinter.printImage(imageBytes); // Directly print the image bytes

     await SunmiPrinter.setFontSize(SunmiFontSize.XL);
     await SunmiPrinter.printText("\n");
     await SunmiPrinter.printText("RECEIPT");
     await SunmiPrinter.resetFontSize();

     await SunmiPrinter.setAlignment(SunmiPrintAlign.LEFT);
     await SunmiPrinter.printText("Cashier: ${sale.cashierFullName}");
     await SunmiPrinter.printText("Date: ${sale.timeIniated}");
     await SunmiPrinter.printText("Reference: ${sale.referenceNumber}");

     // Customer Information
     if (sale.customer != null) {
       await SunmiPrinter.printText("Customer: ${sale.customer!.name}");
     }

     // Separator
     await SunmiPrinter.printText("--------------------------------");

     // Items
     for (var item in sale.items!) {
       String itemName = item.inventoryItem?.name ?? "Item";
       double quantity = item.quantity ?? 0;
       double price = item.sellingPrice ?? 0;
       double total = item.total ?? 0;
       total = total * cur!.rate!;
       price = price * cur!.rate!;
       await SunmiPrinter.printText("$itemName");
       await SunmiPrinter.printText("Qty: $quantity  Price: ${cur?.symbol ?? ''} ${price.toStringAsFixed(2)}");
       await SunmiPrinter.printText("Total: ${cur?.symbol ?? ''} ${total.toStringAsFixed(2)}");
       // await SunmiPrinter.printText("--------------------------------");
     }

     // Separator
     await SunmiPrinter.printText("--------------------------------");
     // Totals
     await SunmiPrinter.printText("Subtotal: ${cur?.symbol ?? ''} ${sale.amountPaid?.toStringAsFixed(2)}");
     for(var currency in currencies){
       await SunmiPrinter.printText("${currency.name} Amount: ${(sale.amountPaid!*currency.rate!).toStringAsFixed(2)}");
     }
    // Tip (if present)
    if(sale.tipAmount != null && sale.tipAmount! > 0) {
      await SunmiPrinter.printText("\nTip: ${cur?.symbol ?? ''} ${sale.tipAmount!.toStringAsFixed(2)}");
    } else {
      await SunmiPrinter.printText("\nTip:.........................");
    }
    if(sale.paymentTypes!.any((pt) => pt.paymentType?.name!.contains('ACC-') ?? false))
       {
         await SunmiPrinter.printText(
             "Account Balance: ${cur?.symbol ?? ''} ${sale.customer!
                 .currencyBalance!
                 .firstWhere((cb) => cb.currency == cur)
                 .balance!
                 .toStringAsFixed(2)}");
       }



     //qr code

     if(sale.receiptQrCode != null){
       await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
       await SunmiPrinter.printQRCode(sale.receiptQrCode!);
       await SunmiPrinter.printText("Scan the QR Code above");
       await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
       await SunmiPrinter.printText(sale.receiptQrData! + "");
       await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
       await SunmiPrinter.printText("You can verify this receipt manually at ");
       await SunmiPrinter.printText(sale.receiptQrCode! + "");
     }

     // Footer
     await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
     await SunmiPrinter.printText("*** Thank you for your purchase! ***");
     await SunmiPrinter.printText("\n\n\n");
     await SunmiPrinter.submitTransactionPrint();
     await SunmiPrinter.exitTransactionPrint(true);
   }

   // Print KOT
   Future<void> printSunmiKOT(SaleModel sale, String orderNum) async {
    print('[KOT][Sunmi] start | orderNum=$orderNum | items=${sale.items?.length ?? 0} | cashier=${sale.cashierFullName}');
     // Only print on Android platforms
     if (Platform.isWindows) {
      print("[KOT][Sunmi] skipped on Windows: Sunmi printer not available");
       return;
     }
     
     CurrencyModel? cur = sale.currency;

    // Print company logo if available
    try {
      final Uint8List imageBytes = await readLocalFileBytes();
      await SunmiPrinter.printImage(imageBytes);
    } catch (e) {
      print('[KOT][Sunmi] logo error: $e');
    }

     await SunmiPrinter.initPrinter();
     await SunmiPrinter.startTransactionPrint(true);

     await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
     await SunmiPrinter.setFontSize(SunmiFontSize.XL);
     await SunmiPrinter.printText("KOT");
     await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
     await SunmiPrinter.setFontSize(SunmiFontSize.XL);
     await SunmiPrinter.printText(orderNum);
     // await SunmiPrinter.resetFontSize();

     await SunmiPrinter.setAlignment(SunmiPrintAlign.LEFT);
     await SunmiPrinter.setFontSize(SunmiFontSize.XL);
     await SunmiPrinter.printText("Cashier: ${sale.cashierFullName}");
     /*await SunmiPrinter.setFontSize(SunmiFontSize.XL);
     await SunmiPrinter.printText("Date: ${sale.timeIniated}");
     await SunmiPrinter.setFontSize(SunmiFontSize.XL);
     await SunmiPrinter.printText("Reference: ${sale.referenceNumber}");*/

     // Customer Information
     await SunmiPrinter.setFontSize(SunmiFontSize.XL);
       await SunmiPrinter.printText("Customer: ${sale.customer?.name ?? sale.ticketName!} \t\t  Sit-in");
       if(sale.ticketComment != null && sale.ticketComment!.isNotEmpty) {
         await SunmiPrinter.setFontSize(SunmiFontSize.XL);
          await SunmiPrinter.printText("Comments: ${sale.ticketComment!}");
    }

    // Separator
     await SunmiPrinter.printText("--------------------------------");

     // Items
     for (var item in sale.items!) {
       String itemName = item.inventoryItem?.name ?? "Item";
       await SunmiPrinter.setFontSize(SunmiFontSize.XL);
       await SunmiPrinter.printText("$itemName x ${item.quantity}");
       await SunmiPrinter.setFontSize(SunmiFontSize.XL);
       await SunmiPrinter.printText("${item.notes ?? ''}");
       // await SunmiPrinter.printText("--------------------------------");
     }

     // Separator
     await SunmiPrinter.printText("--------------------------------");

     //qr code
     // Footer
     await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
     await SunmiPrinter.printText("\n\n\n");
     await SunmiPrinter.submitTransactionPrint();
     await SunmiPrinter.exitTransactionPrint(true);
   }
  // Print Quick KOT
  Future<void> printSunmiQuickKOT(List<CartItemModel> items, String? cashier, String? customer, String? reference) async {

    // Print company logo if available
    try {
      final Uint8List imageBytes = await readLocalFileBytes();
      await SunmiPrinter.printImage(imageBytes);
    } catch (e) {
      print('[KOT-QUICK][Sunmi] logo error: $e');
    }
    String todayDate = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

    print('[KOT][Sunmi] init printer');
    await SunmiPrinter.initPrinter();
    await SunmiPrinter.startTransactionPrint(true);

    await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
    await SunmiPrinter.setFontSize(SunmiFontSize.XL);
    await SunmiPrinter.printText(reference!);
    // await SunmiPrinter.resetFontSize();

    await SunmiPrinter.setAlignment(SunmiPrintAlign.LEFT);
    await SunmiPrinter.setFontSize(SunmiFontSize.XL);
    // await SunmiPrinter.printText("Cashier: $cashier");
    // await SunmiPrinter.printText("Date: ${todayDate}");
    // await SunmiPrinter.printText("Reference: $reference");

    // Customer Information
    await SunmiPrinter.printText("Customer: $customer \t\t Take-away");

    // Separator
    await SunmiPrinter.printText("--------------------------------");

    // Items
    for (var item in items) {
      String itemName = item.product?.item!.name ?? "Item";
      await SunmiPrinter.setFontSize(SunmiFontSize.XL);
      await SunmiPrinter.printText("$itemName x ${item.quantity}");
      await SunmiPrinter.setFontSize(SunmiFontSize.XL);
      await SunmiPrinter.printText("${item.notes ?? ''}");
      // await SunmiPrinter.printText("--------------------------------");
    }

    // Separator
    await SunmiPrinter.printText("--------------------------------");

    //qr code
    // Footer
    await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
    await SunmiPrinter.printText("\n\n\n");
    print('[KOT][Sunmi] submit');
    await SunmiPrinter.submitTransactionPrint();
    await SunmiPrinter.exitTransactionPrint(true);
    print('[KOT][Sunmi] done');
  }
  
  // Print KOT via USB (ESC/POS)
  Future<void> printKOTUsb(SaleModel sale, String orderNum, AvailablePrinterModel printer) async {
    print('[KOT][USB] start | orderNum=$orderNum | items=${sale.items?.length ?? 0} | cashier=${sale.cashierFullName}');
    print('[KOT][USB] printer: name=${printer.name}, vid=${printer.vendorId}, pid=${printer.productId}');
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    // Company logo
    try {
      final Uint8List imageBytes = await readLocalFileBytes();
      final img.Image? image = img.decodeImage(imageBytes);
      if (image != null) {
        final img.Image resized = img.copyResize(image, width: 200);
        bytes += generator.image(resized);
        bytes += generator.feed(1);
      }
    } catch (e) {
      print('[KOT][USB] logo error: $e');
    }

    // Header
    bytes += generator.text('KOT',
        styles: PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ));
    bytes += generator.text(orderNum,
        styles: PosStyles(align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size2));

    // Meta
    bytes += generator.text('Cashier: ${sale.cashierFullName}', styles: PosStyles(align: PosAlign.left));
    final String customerName = sale.customer?.name ?? (sale.ticketName ?? '');
    if (customerName.isNotEmpty) {
      bytes += generator.text('Customer: $customerName   Sit-in', styles: PosStyles(align: PosAlign.left));
    }
    if ((sale.ticketComment ?? '').isNotEmpty) {
      bytes += generator.text('Comments: ${sale.ticketComment}', styles: PosStyles(align: PosAlign.left));
    }
    bytes += generator.text('--------------------------------', styles: PosStyles(align: PosAlign.center));

    // Items
    for (var item in sale.items ?? []) {
      final String itemName = item.inventoryItem?.name ?? 'Item';
      final String qty = (item.quantity ?? 0).toString();
      bytes += generator.text('$itemName x $qty',
          styles: PosStyles(align: PosAlign.left, height: PosTextSize.size2));
      final String notes = item.notes ?? '';
      if (notes.isNotEmpty) {
        bytes += generator.text(notes, styles: PosStyles(align: PosAlign.left));
      }
    }

    bytes += generator.text('--------------------------------', styles: PosStyles(align: PosAlign.center));
    bytes += generator.feed(2);
    bytes += generator.cut();

    // Send
    try {
      var model = UsbPrinterInput(name: printer.name, vendorId: printer.vendorId, productId: printer.productId);
      print('[KOT][USB] connecting...');
      bool connected = await PrinterManager.instance.connect(type: PrinterType.usb, model: model);
      print('[KOT][USB] connected=$connected');
      if (!connected) {
        Get.snackbar('Error', 'Failed to connect to printer', snackPosition: SnackPosition.BOTTOM);
        return;
      }
      print('[KOT][USB] sending ${bytes.length} bytes');
      await PrinterManager.instance.send(bytes: bytes, type: PrinterType.usb);
      print('[KOT][USB] disconnect');
      await PrinterManager.instance.disconnect(type: PrinterType.usb);
      Get.snackbar('Success', 'KOT printed successfully', snackPosition: SnackPosition.BOTTOM);
      print('[KOT][USB] done');
    } catch (e, st) {
      print('[KOT][USB] error: $e');
      print(st);
      Get.snackbar('Error', 'Failed to print KOT: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }

  // Print Quick KOT via USB (ESC/POS) — items only
  Future<void> printQuickKOTUsb(List<CartItemModel> items, String? cashier, String? customer, String? reference, AvailablePrinterModel printer) async {
    print('[KOT-QUICK][USB] start | items=${items.length} | cashier=$cashier | customer=${customer ?? ''} | ref=${reference ?? ''}');
    print('[KOT-QUICK][USB] printer: name=${printer.name}, vid=${printer.vendorId}, pid=${printer.productId}');
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    // Company logo
    try {
      final Uint8List imageBytes = await readLocalFileBytes();
      final img.Image? image = img.decodeImage(imageBytes);
      if (image != null) {
        final img.Image resized = img.copyResize(image, width: 200);
        bytes += generator.image(resized);
        bytes += generator.feed(1);
      }
    } catch (e) {
      print('[KOT-QUICK][USB] logo error: $e');
    }

    // Header
    bytes += generator.text('KOT',
        styles: PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ));
    if ((reference ?? '').isNotEmpty) {
      bytes += generator.text(reference!, styles: PosStyles(align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size2));
    }

    // Meta
    if ((cashier ?? '').isNotEmpty) {
      bytes += generator.text('Cashier: $cashier', styles: PosStyles(align: PosAlign.left));
    }
    if ((customer ?? '').isNotEmpty) {
      bytes += generator.text('Customer: $customer   Sit-in', styles: PosStyles(align: PosAlign.left));
    }
    bytes += generator.text('--------------------------------', styles: PosStyles(align: PosAlign.center));

    // Items
    for (var item in items) {
      final String itemName = item.product.item?.name ?? 'Item';
      final String qty = (item.quantity).toString();
      bytes += generator.text('$itemName x $qty',
          styles: PosStyles(align: PosAlign.left, height: PosTextSize.size2));
      final String notes = item.notes;
      if (notes.isNotEmpty) {
        bytes += generator.text(notes, styles: PosStyles(align: PosAlign.left));
      }
    }

    bytes += generator.text('--------------------------------', styles: PosStyles(align: PosAlign.center));
    bytes += generator.feed(2);
    bytes += generator.cut();

    // Send
    try {
      var model = UsbPrinterInput(name: printer.name, vendorId: printer.vendorId, productId: printer.productId);
      print('[KOT-QUICK][USB] connecting...');
      bool connected = await PrinterManager.instance.connect(type: PrinterType.usb, model: model);
      print('[KOT-QUICK][USB] connected=$connected');
      if (!connected) {
        Get.snackbar('Error', 'Failed to connect to printer', snackPosition: SnackPosition.BOTTOM);
        return;
      }
      print('[KOT-QUICK][USB] sending ${bytes.length} bytes');
      await PrinterManager.instance.send(bytes: bytes, type: PrinterType.usb);
      print('[KOT-QUICK][USB] disconnect');
      await PrinterManager.instance.disconnect(type: PrinterType.usb);
      Get.snackbar('Success', 'KOT printed successfully', snackPosition: SnackPosition.BOTTOM);
      print('[KOT-QUICK][USB] done');
    } catch (e, st) {
      print('[KOT-QUICK][USB] error: $e');
      print(st);
      Get.snackbar('Error', 'Failed to print KOT: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }

   // Print cash in Receipt
   Future<void> printSunmiCashIn(PaymentReceivedModel payment, String? cashier) async {
     // Only print on Android platforms
     if (Platform.isWindows) {
       print("Sunmi printer not available on Windows");
       return;
     }
     
     CurrencyModel? cur = payment.currency;

     Uint8List imageBytes = await readLocalFileBytes();
     //print(imageBytes);

     await SunmiPrinter.initPrinter();
     await SunmiPrinter.startTransactionPrint(true);

     // Header
     await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
     await SunmiPrinter.printImage(imageBytes); // Directly print the image bytes

     await SunmiPrinter.setFontSize(SunmiFontSize.XL);
     // await SunmiPrinter.printText("\n");
     // await SunmiPrinter.printText("KOT");
     await SunmiPrinter.resetFontSize();

     await SunmiPrinter.setAlignment(SunmiPrintAlign.LEFT);
     await SunmiPrinter.printText("Cashier: $cashier}");
     await SunmiPrinter.printText("Date: ${payment.dateTime}");
     await SunmiPrinter.printText("Reference: DEPOSIT");

     // Customer Information
       await SunmiPrinter.printText("Customer: ${payment.payer?.name}");

     // Separator
     await SunmiPrinter.printText("--------------------------------");

     // Items
     // for (var item in payment.items!) {
       await SunmiPrinter.printText("Amount: ${cur?.symbol ?? ''} ${payment.amount?.toStringAsFixed(2)} ( ${payment.paymentType!.name})");
       await SunmiPrinter.printText("New Balance: ${cur?.symbol ?? ''} ${payment.payer!.currencyBalance!.firstWhere((cb) => cb.currency.id == payment.currency?.id).balance?.toStringAsFixed(2)}");
       // await SunmiPrinter.printText("${item.notes ?? ''}");
       // await SunmiPrinter.printText("--------------------------------");
     // }

     // Separator
     await SunmiPrinter.printText("--------------------------------");

     //qr code
     // Footer
     await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
     await SunmiPrinter.printText("\n\n\n");
     await SunmiPrinter.submitTransactionPrint();
     await SunmiPrinter.exitTransactionPrint(true);
   }

    // Print Customer Statement
   Future<void> printSunmiCustomerStatement(CustomerModel customer, List<CustomerProjectionModel>? projectionsa, {String? dateRangeDescription}) async {
     // Only print on Android platforms
     if (Platform.isWindows) {
       print("==================== PRINT PREVIEW (Windows - Printing Disabled) ====================");
       print("Would print account statement for: ${customer.name}");
       print("Would print ${projectionsa?.length ?? 0} transactions");
       print("========================================================");
       return;
     }

     print("==================== PRINTING ACCOUNT STATEMENT ====================");
     print("Customer: ${customer.name}");
     print("Total transactions to print: ${projectionsa?.length ?? 0}");
     print("Date range: Last 30 days");
     
     if (projectionsa != null && projectionsa.isNotEmpty) {
       print("\n--- Print Data Preview ---");
       for (var i = 0; i < projectionsa.length && i < 5; i++) {
         var payment = projectionsa[i];
         print("Line ${i + 1}: ${payment.paymentReceived!.dateTime!.substring(0,10)} - ${payment.paymentReceived!.paymentDescription}");
         print("         Amount: ${payment.paymentReceived!.currency!.symbol ?? '\$'} ${payment.paymentReceived!.amount?.toStringAsFixed(2)}");
         print("         Balance: ${payment.paymentReceived!.currency!.symbol ?? '\$'}${payment.paymentReceived!.accountBalance?.toStringAsFixed(2)}");
       }
       if (projectionsa.length > 5) {
         print("         ... (${projectionsa.length - 5} more lines to print)");
       }
       print("\nFinal Balance: ${customer.accountBalance?.toStringAsFixed(2) ?? '0.00'}");
     } else {
       print("No transactions to print.");
     }
     print("========================================================");

     // CurrencyModel? cur = payment.currency;

     Uint8List imageBytes = await readLocalFileBytes();

     await SunmiPrinter.initPrinter();
     await SunmiPrinter.startTransactionPrint(true);
     //
     // Header
     await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
     await SunmiPrinter.printImage(imageBytes); // Directly print the image bytes

     await SunmiPrinter.setFontSize(SunmiFontSize.XL);
     // await SunmiPrinter.printText("\n");
     // await SunmiPrinter.printText("KOT");
     await SunmiPrinter.resetFontSize();

    await SunmiPrinter.setAlignment(SunmiPrintAlign.LEFT);
    await SunmiPrinter.printText("ACCOUNT STATEMENT");
    await SunmiPrinter.printText("Date: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}");
    
    // Date Range (if provided)
    if (dateRangeDescription != null && dateRangeDescription.isNotEmpty) {
      await SunmiPrinter.printText("Period: $dateRangeDescription");
    }
    
    // Separator
    await SunmiPrinter.printText("--------------------------------");

     // Customer Information
       await SunmiPrinter.printText("Customer: ${customer.name}");


     // Items
     for (var payment in projectionsa!) {
       await SunmiPrinter.printText("${payment.paymentReceived!.dateTime!.substring(0,10)}:${payment.reference}:(${payment.paymentReceived!.paymentDescription})[${payment.paymentReceived!.paymentType!.isCredit! ? 'CR' : 'DR'}] "
           " ${payment.paymentReceived!.currency!.symbol ?? '\$'} ${payment.paymentReceived!.amount?.toStringAsFixed(2)} bal: ${payment.paymentReceived!.currency!.symbol ?? '\$'}${payment.paymentReceived!.accountBalance?.toStringAsFixed(2)} ");
       // await SunmiPrinter.printText("New Balance: ${cur?.symbol ?? ''} ${payment.payer!.currencyBalance!.firstWhere((cb) => cb.currency.id == payment.currency?.id).balance?.toStringAsFixed(2)}");
       // await SunmiPrinter.printText("${item.notes ?? ''}");
       // await SunmiPrinter.printText("--------------------------------");
     }

     // Separator
     await SunmiPrinter.printText("--------------------------------");
     await SunmiPrinter.printText("New Balance: ${customer.accountBalance?.toStringAsFixed(2) ?? '' }");

     //qr code
     // Footer
     await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
     await SunmiPrinter.printText("\n\n\n");
     await SunmiPrinter.submitTransactionPrint();
     await SunmiPrinter.exitTransactionPrint(true);
   }



  Future<void> printSunmiGRV(TransferHistoryModel transfer) async {
    // Only print on Android platforms
    if (Platform.isWindows) {
      print("Sunmi printer not available on Windows");
      return;
    }
    
    Uint8List imageBytes = await readLocalFileBytes();
    String todayDate = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

    await SunmiPrinter.initPrinter();
    await SunmiPrinter.startTransactionPrint(true);

    // Print Logo (if Sunmi printer supports images)
    await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
    await SunmiPrinter.printImage(imageBytes);

    // Title: GOODS RECEIVED VOUCHER
    await SunmiPrinter.setFontSize(SunmiFontSize.XL);
    await SunmiPrinter.printText("\nGOODS RECEIVED VOUCHER\n");
    await SunmiPrinter.resetFontSize();

    // Transfer Details
    await SunmiPrinter.setAlignment(SunmiPrintAlign.LEFT);
    await SunmiPrinter.printText("Reference: ${transfer.reference ?? "N/A"}\n");
    await SunmiPrinter.printText("Date: ${transfer.dateTime ?? todayDate}\n");
    await SunmiPrinter.printText("From: ${transfer.fromBranch?.name ?? "N/A"}\n");
    await SunmiPrinter.printText("To: ${transfer.toBranch?.name ?? "N/A"}\n");

    // Separator
    await SunmiPrinter.printText("--------------------------------\n");

    // Print Items as Separate Sections
    for (var item in transfer.transferItems ?? []) {
      String itemName = item.item?.name ?? 'Unknown Item';
      String quantity = item.quantity?.toStringAsFixed(2) ?? "0.00";
      String allocated = item.allocated?.toStringAsFixed(2) ?? "0.00";

      await SunmiPrinter.setFontSize(SunmiFontSize.LG);
      await SunmiPrinter.printText("Item: $itemName\n");
      await SunmiPrinter.resetFontSize();

      await SunmiPrinter.printText("Quantity: $quantity\n");
      await SunmiPrinter.printText("Allocated: $allocated\n");

      // Divider between items
      await SunmiPrinter.printText("--------------------------------\n");
    }

    // Signature Sections
    await SunmiPrinter.printText("\nReceived By: ______________________\n");
    await SunmiPrinter.printText("Signature: ________________________\n\n");

    await SunmiPrinter.printText("Delivered By: _____________________\n");
    await SunmiPrinter.printText("Signature: ________________________\n\n");

    // Footer with Date
    await SunmiPrinter.printText("Date: $todayDate\n");
    await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
    await SunmiPrinter.printText("*** Thank you for using our service! ***\n");

    // Finish Printing
    await SunmiPrinter.printText("\n\n\n");
    await SunmiPrinter.submitTransactionPrint();
    await SunmiPrinter.exitTransactionPrint(true);
  }

  // USB: Cash In Receipt
  Future<void> printCashInUsb(PaymentReceivedModel payment, String? cashier, AvailablePrinterModel printer) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> data = [];

    final CurrencyModel? cur = payment.currency;

    // Logo
    try {
      final Uint8List imageBytes = await readLocalFileBytes();
      final img.Image? image = img.decodeImage(imageBytes);
      if (image != null) {
        final img.Image resized = img.copyResize(image, width: 200);
        data += generator.image(resized);
        data += generator.feed(1);
      }
    } catch (_) {}

    // Header
    data += generator.text('CASH IN',
        styles: PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
    data += generator.text('Cashier: ${cashier ?? ''}', styles: PosStyles(align: PosAlign.left));
    data += generator.text('Date: ${payment.dateTime ?? ''}', styles: PosStyles(align: PosAlign.left));
    data += generator.text('Reference: DEPOSIT', styles: PosStyles(align: PosAlign.left));

    // Customer
    if (payment.payer?.name != null) {
      data += generator.text('Customer: ${payment.payer!.name}', styles: PosStyles(align: PosAlign.left));
    }

    data += generator.text('--------------------------------', styles: PosStyles(align: PosAlign.center));

    // Amounts
    data += generator.text('Amount: ${cur?.symbol ?? ''} ${((payment.amount) ?? 0).toStringAsFixed(2)} (${payment.paymentType?.name ?? ''})',
        styles: PosStyles(align: PosAlign.left));
    if (payment.accountBalance != null) {
      data += generator.text('New Balance: ${cur?.symbol ?? ''} ${payment.accountBalance!.toStringAsFixed(2)}',
          styles: PosStyles(align: PosAlign.left));
    }

    data += generator.text('--------------------------------', styles: PosStyles(align: PosAlign.center));
    data += generator.feed(2);
    data += generator.cut();

    try {
      var model = UsbPrinterInput(name: printer.name, vendorId: printer.vendorId, productId: printer.productId);
      bool connected = await PrinterManager.instance.connect(type: PrinterType.usb, model: model);
      if (!connected) { Get.snackbar('Error', 'Failed to connect to printer'); return; }
      await PrinterManager.instance.send(bytes: data, type: PrinterType.usb);
      await PrinterManager.instance.disconnect(type: PrinterType.usb);
      Get.snackbar('Success', 'Cash In printed');
    } catch (e) { Get.snackbar('Error', 'Failed to print Cash In: $e'); }
  }

  // USB: Cash Management Receipt
  Future<void> printCashManagementReceiptUsb(String transactionType, CurrencyModel currency, double amount, String comments, AvailablePrinterModel printer) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> data = [];

    data += generator.text(transactionType.toUpperCase(),
        styles: PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
    data += generator.text('Currency: ${currency.name ?? ''}', styles: PosStyles(align: PosAlign.left));
    data += generator.text('Amount: ${currency.symbol ?? ''} ${amount.toStringAsFixed(2)}', styles: PosStyles(align: PosAlign.left));
    if (comments.isNotEmpty) {
      data += generator.text('Comments: $comments', styles: PosStyles(align: PosAlign.left));
    }
    data += generator.text('--------------------------------', styles: PosStyles(align: PosAlign.center));
    data += generator.feed(2);
    data += generator.cut();

    try {
      var model = UsbPrinterInput(name: printer.name, vendorId: printer.vendorId, productId: printer.productId);
      bool connected = await PrinterManager.instance.connect(type: PrinterType.usb, model: model);
      if (!connected) { Get.snackbar('Error', 'Failed to connect to printer'); return; }
      await PrinterManager.instance.send(bytes: data, type: PrinterType.usb);
      await PrinterManager.instance.disconnect(type: PrinterType.usb);
      Get.snackbar('Success', 'Cash management printed');
    } catch (e) { Get.snackbar('Error', 'Failed to print cash management: $e'); }
  }

  // USB: Cash Submit Receipt
  Future<void> printCashSubmitReceiptUsb(String transactionType, List<CurrencyAmount> currencyAmounts, AvailablePrinterModel printer) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> data = [];

    data += generator.text('CASH SUBMIT',
        styles: PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
    for (var ca in currencyAmounts) {
      data += generator.text('${ca.currency.name}: ${ca.currency.symbol ?? ''} ${ca.amount.toStringAsFixed(2)}', styles: PosStyles(align: PosAlign.left));
    }
    data += generator.text('--------------------------------', styles: PosStyles(align: PosAlign.center));
    data += generator.feed(2);
    data += generator.cut();

    try {
      var model = UsbPrinterInput(name: printer.name, vendorId: printer.vendorId, productId: printer.productId);
      bool connected = await PrinterManager.instance.connect(type: PrinterType.usb, model: model);
      if (!connected) { Get.snackbar('Error', 'Failed to connect to printer'); return; }
      await PrinterManager.instance.send(bytes: data, type: PrinterType.usb);
      await PrinterManager.instance.disconnect(type: PrinterType.usb);
      Get.snackbar('Success', 'Cash submit printed');
    } catch (e) { Get.snackbar('Error', 'Failed to print cash submit: $e'); }
  }

  // USB: GRV (Goods Received Voucher)
  Future<void> printGRVUsb(TransferHistoryModel transfer, AvailablePrinterModel printer) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> data = [];

    // Logo
    try {
      final Uint8List imageBytes = await readLocalFileBytes();
      final img.Image? image = img.decodeImage(imageBytes);
      if (image != null) {
        final img.Image resized = img.copyResize(image, width: 200);
        data += generator.image(resized);
        data += generator.feed(1);
      }
    } catch (_) {}

    data += generator.text('GOODS RECEIVED VOUCHER',
        styles: PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2));

    final String todayDate = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    data += generator.text('Reference: ${transfer.reference ?? 'N/A'}', styles: PosStyles(align: PosAlign.left));
    data += generator.text('Date: ${transfer.dateTime ?? todayDate}', styles: PosStyles(align: PosAlign.left));
    data += generator.text('From: ${transfer.fromBranch?.name ?? 'N/A'}', styles: PosStyles(align: PosAlign.left));
    data += generator.text('To: ${transfer.toBranch?.name ?? 'N/A'}', styles: PosStyles(align: PosAlign.left));
    data += generator.text('--------------------------------', styles: PosStyles(align: PosAlign.center));

    for (var item in transfer.transferItems ?? []) {
      final String itemName = item.item?.name ?? 'Unknown Item';
      final String quantity = item.quantity?.toStringAsFixed(2) ?? '0.00';
      final String allocated = item.allocated?.toStringAsFixed(2) ?? '0.00';
      data += generator.text('Item: $itemName', styles: PosStyles(align: PosAlign.left, height: PosTextSize.size2));
      data += generator.text('Quantity: $quantity', styles: PosStyles(align: PosAlign.left));
      data += generator.text('Allocated: $allocated', styles: PosStyles(align: PosAlign.left));
      data += generator.text('--------------------------------', styles: PosStyles(align: PosAlign.center));
    }

    data += generator.text('Received By: ______________________', styles: PosStyles(align: PosAlign.left));
    data += generator.text('Signature:  ______________________', styles: PosStyles(align: PosAlign.left));
    data += generator.feed(2);
    data += generator.cut();

    try {
      var model = UsbPrinterInput(name: printer.name, vendorId: printer.vendorId, productId: printer.productId);
      bool connected = await PrinterManager.instance.connect(type: PrinterType.usb, model: model);
      if (!connected) { Get.snackbar('Error', 'Failed to connect to printer'); return; }
      await PrinterManager.instance.send(bytes: data, type: PrinterType.usb);
      await PrinterManager.instance.disconnect(type: PrinterType.usb);
      Get.snackbar('Success', 'GRV printed');
    } catch (e) { Get.snackbar('Error', 'Failed to print GRV: $e'); }
  }

  // USB: Sale Bill (estimate)
  Future<void> printSaleBillUsb(SaleModel sale, List<CurrencyModel> currencies, AvailablePrinterModel printer) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> data = [];

    final CurrencyModel? cur = sale.currency;

    // Header
    data += generator.text('SALE BILL',
        styles: PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
    data += generator.text('Date: ${sale.timeIniated ?? ''}', styles: PosStyles(align: PosAlign.left));
    data += generator.text('Reference: ${sale.referenceNumber ?? ''}', styles: PosStyles(align: PosAlign.left));
    if (sale.customer != null) {
      data += generator.text('Customer: ${sale.customer!.name}', styles: PosStyles(align: PosAlign.left));
    }
    data += generator.text('--------------------------------', styles: PosStyles(align: PosAlign.center));

    for (var item in sale.items ?? []) {
      final String itemName = item.inventoryItem?.name ?? 'Item';
      final double qty = item.quantity ?? 0;
      final double price = item.sellingPrice ?? 0;
      final double total = item.total ?? 0;
      data += generator.text(itemName, styles: PosStyles(align: PosAlign.left, bold: true));
      data += generator.text('Qty: ${qty.toStringAsFixed(2)}    Price: ${price.toStringAsFixed(2)}', styles: PosStyles(align: PosAlign.left));
      data += generator.text('Total: ${total.toStringAsFixed(2)}', styles: PosStyles(align: PosAlign.left));
      data += generator.text('--------------------------------', styles: PosStyles(align: PosAlign.center));
    }

    data += generator.text('Subtotal: ${cur?.symbol ?? ''} ${sale.amountAfterDiscount?.toStringAsFixed(2) ?? '0.00'}',
        styles: PosStyles(align: PosAlign.right));
    data += generator.text('Amount Paid: ${cur?.symbol ?? ''} ${sale.amountPaid?.toStringAsFixed(2) ?? '0.00'}', styles: PosStyles(align: PosAlign.right));
    data += generator.text('Change: ${cur?.symbol ?? ''} ${sale.change?.toStringAsFixed(2) ?? '0.00'}', styles: PosStyles(align: PosAlign.right));
    if ((sale.tipAmount ?? 0) > 0) {
      data += generator.text('Tip: ${cur?.symbol ?? ''} ${sale.tipAmount!.toStringAsFixed(2)}', styles: PosStyles(align: PosAlign.right));
    }
    data += generator.text('--------------------------------', styles: PosStyles(align: PosAlign.center));
    data += generator.feed(2);
    data += generator.cut();

    try {
      var model = UsbPrinterInput(name: printer.name, vendorId: printer.vendorId, productId: printer.productId);
      bool connected = await PrinterManager.instance.connect(type: PrinterType.usb, model: model);
      if (!connected) { Get.snackbar('Error', 'Failed to connect to printer'); return; }
      await PrinterManager.instance.send(bytes: data, type: PrinterType.usb);
      await PrinterManager.instance.disconnect(type: PrinterType.usb);
      Get.snackbar('Success', 'Sale bill printed');
    } catch (e) { Get.snackbar('Error', 'Failed to print sale bill: $e'); }
  }

  // USB: Simple test print
  Future<void> testPrinterUsb(AvailablePrinterModel printer) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> data = [];
    data += generator.text('TEST PRINT', styles: PosStyles(align: PosAlign.center, bold: true));
    data += generator.text('USB connection OK', styles: PosStyles(align: PosAlign.center));
    data += generator.feed(1);
    data += generator.cut();
    try {
      var model = UsbPrinterInput(name: printer.name, vendorId: printer.vendorId, productId: printer.productId);
      bool connected = await PrinterManager.instance.connect(type: PrinterType.usb, model: model);
      if (!connected) { Get.snackbar('Error', 'Failed to connect to printer'); return; }
      await PrinterManager.instance.send(bytes: data, type: PrinterType.usb);
      await PrinterManager.instance.disconnect(type: PrinterType.usb);
      Get.snackbar('Success', 'Test printed');
    } catch (e) { Get.snackbar('Error', 'Failed to print test: $e'); }
  }


// Read the image from local storage
  Future<Uint8List> readLocalFileBytes() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/company_logo.png';
    try {
      final file = File(path);
      if (await file.exists()) {
        Uint8List log =  await file.readAsBytes(); // Read and return the image bytes
        
        // Check if file is empty
        if (log.isEmpty) {
          print("USB RECEIPT DEBUG: Logo file exists but is empty");
          throw Exception("Logo file is empty");
        }

        // Decode the image
        img.Image? image = img.decodeImage(log);
        if (image == null) {
          print("USB RECEIPT DEBUG: Could not decode the image");
          throw Exception("Could not decode the image");
        }

        // Resize the image to the desired width and height
        img.Image resizedImage = img.copyResize(image, width: 300, height: 300);


        // Convert the resized image back to Uint8List (in PNG format)
        Uint8List resizedImageBytes = await Uint8List.fromList(img.encodePng(resizedImage));
        return resizedImageBytes;

      } else {
        print("USB RECEIPT DEBUG: Logo file does not exist at: $path");
        throw Exception("File does not exist");
      }
    } catch (e) {
      print("USB RECEIPT DEBUG: Error reading logo file: $e");
      rethrow;
    }
  }
  Future<void> printTelpoSaleReceipt(SaleModel sale, bool waScan) async {
    // Only print on Android platforms
    if (Platform.isWindows) {
      print("Telpo printer not available on Windows");
      return;
    }
    
    try {
      CurrencyModel? cur = sale.currency;

      // Consolidate receipt content into a single string
      StringBuffer receiptBuffer = StringBuffer();

      // Header
      receiptBuffer.writeln("********** RECEIPT **********");
      receiptBuffer.writeln("Cashier: ${sale.cashierFullName}");
      receiptBuffer.writeln("Date: ${sale.timeIniated}");
      receiptBuffer.writeln("Reference: ${sale.referenceNumber}");

      // Customer Information
      if (sale.customer != null) {
        receiptBuffer.writeln("Customer: ${sale.customer!.name}");
      }

      // Separator
      receiptBuffer.writeln("--------------------------------");

      // Items
      for (var item in sale.items!) {
        String itemName = item.inventoryItem?.name ?? "Item";
        double quantity = item.quantity ?? 0;
        double price = item.sellingPrice ?? 0;
        double total = item.total ?? 0;

        receiptBuffer.writeln("$itemName");
        receiptBuffer.writeln("Qty: $quantity | Price: ${price.toStringAsFixed(2)} | Total: ${total.toStringAsFixed(2)}");
        receiptBuffer.writeln("--------------------------------");
      }

      // Totals (updated to match Sunmi)
      receiptBuffer.writeln("Subtotal: ${cur?.symbol ?? ''} ${sale.amountAfterDiscount?.toStringAsFixed(2)}");
      receiptBuffer.writeln("Amount Paid: ${cur?.symbol ?? ''} ${sale.amountPaid?.toStringAsFixed(2)} \t\t${sale.paymentTypes!.map((pt)=>pt.paymentType!.name!).join(', ')}");
      receiptBuffer.writeln("Change: ${cur?.symbol ?? ''} ${sale.change?.toStringAsFixed(2)}");

      // Tip (if present) - missing feature added
      if(sale.tipAmount != null && sale.tipAmount! > 0) {
        receiptBuffer.writeln("Tip: ${cur?.symbol ?? ''} ${sale.tipAmount!.toStringAsFixed(2)}");
      }

      // Account Balance (if ACC- payment type is used) - unique to Sunmi, now added to Telpo
      if(sale.paymentTypes!.any((pt) => pt.paymentType?.name!.contains('ACC-') ?? false) && sale.customer != null && sale.customer!.currencyBalance != null && sale.customer!.currencyBalance!.isNotEmpty) {
        receiptBuffer.writeln("Account Balance: ${cur?.symbol ?? ''} ${sale.customer!.currencyBalance!.firstWhere((cb) => cb.currency?.id == cur?.id, orElse: () => sale.customer!.currencyBalance!.first).balance!.toStringAsFixed(2)}");
      }

      receiptBuffer.writeln("--------------------------------");

      // Footer
      receiptBuffer.writeln("Thank you for your purchase!");

      // Print consolidated text
      await TelpoM8().printWithThermalPrinter(receiptBuffer.toString());

      if (sale.receiptQrCode != null) {
        final qrValidationResult = QrValidator.validate(
          data: sale.receiptQrCode!,
          version: QrVersions.auto,
          errorCorrectionLevel: QrErrorCorrectLevel.L,
        );

        if (qrValidationResult.status == QrValidationStatus.error) {
          throw Exception('QR Code generation failed');
        }

        final qrCode = qrValidationResult.qrCode!;
        final painter = QrPainter.withQr(
          qr: qrCode,
          color: const Color(0xFF000000),
          emptyColor: const Color(0xFFFFFFFF),
          gapless: true,
        );

        final picData = await painter.toImageData(200); // Adjust size if needed
        final img.Image baseSizeImage = img.decodeImage(picData!.buffer.asUint8List())!;
        final img.Image grayscaleImage = img.grayscale(baseSizeImage);
        final Uint8List qrImageBytes = Uint8List.fromList(img.encodePng(grayscaleImage));

        // Print QR Code Image
        await TelpoM8().printImageWithThermalPrinter(qrImageBytes);

        // Print QR Code Information
        await TelpoM8().printWithThermalPrinter(
            "Scan the QR Code above\n"
                "${sale.receiptQrData!}\n"
                "Verify this receipt at:\n"
                "${sale.receiptQrCode!}\n"
        );
      }

      // Footer


    } catch (e) {
      debugPrint('Error printing Telpo receipt: $e');
    }
  }

  Future<Uint8List> generateWhatsappQR(String invoiceNumber, String currencySymbol, double amount) async{
    // Generate QR Code using qr_flutter
    var box = GetStorage();
    SettingsModel settingsModel;
    var settings = box.read(AppConstants.COMPANY_SETTINGS) ?? {};
    settingsModel = SettingsModel.fromMap(Map<String, dynamic>.from(settings));
    final String phone = settingsModel.whatsappNumber!; // Replace with your number
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

  Future<Uint8List> generateBlueToothQR(String qrContent) async{
    // Generate QR Code using qr_flutter
    final qrValidationResult = QrValidator.validate(
      data: qrContent,
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




  // Print Shift Details
   Future<void> printShiftDetails(ShiftModel shift,RxList<SaleInfoModel> allReceipts, List<Map<String, dynamic>> totalAmountsByCurrency, List<Map<String, dynamic>> totalAmountsByPaymentType,
       List<Map<String, dynamic>> totalCashIn, List<Map<String, dynamic>> totalCashOut, List<Map<String, dynamic>> totalSubmitted, List<Map<String, dynamic>> totalSales,
       List<Map<String, dynamic>> totalTips, List<Map<String, dynamic>> breakages, List<Map<String, dynamic>> refunds) async {
     await SunmiPrinter.initPrinter();
     await SunmiPrinter.startTransactionPrint(true);

     // Header
     await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
     await SunmiPrinter.setFontSize(SunmiFontSize.LG);
     await SunmiPrinter.printText("SHIFT DETAILS\n");
     await SunmiPrinter.resetFontSize();

     // Shift Details
     await SunmiPrinter.setAlignment(SunmiPrintAlign.LEFT);
     await SunmiPrinter.printText("User: ${shift.userFullName ?? ''}");
     await SunmiPrinter.printText("OT: ${shift.openingTime ?? ''}");
     await SunmiPrinter.printText("CT: ${shift.closingTime ?? ''}");

     // Transactions
     if (shift.shiftCurrencyAmounts != null && shift.shiftCurrencyAmounts!.isNotEmpty) {
       await SunmiPrinter.printText("\nTransactions:\n");
       for (var currencyAmount in shift.shiftCurrencyAmounts!) {
         var sale = allReceipts.firstWhere((receipt) => receipt.sale!.posReference == currencyAmount.posReference || receipt.sale!.referenceNumber == currencyAmount.posReference
             , orElse: () => SaleInfoModel(sale: null,syncStatus: false));
         await SunmiPrinter.printText("Type:${currencyAmount.amountType ?? ''}\t\t\tRef: ${currencyAmount.ref}");
         await SunmiPrinter.printText("Time: ${currencyAmount.timeCreated}");
        await SunmiPrinter.printText("Amount: ${currencyAmount.currency.name} ${currencyAmount.amount.toString()}\t\t\t\ ${sale.sale?.paymentTypes!.firstWhereOrNull((element) => element.paymentType!.name == currencyAmount.paymentType)!.paymentType!.name ??currencyAmount.paymentType}");
        if (sale.sale != null && (sale.sale!.tipAmount ?? 0) > 0) {
          await SunmiPrinter.printText("Tip: ${currencyAmount.currency.symbol ?? ''} ${sale.sale!.tipAmount!.toStringAsFixed(2)}");
        }
         await SunmiPrinter.printText("--------------------------------");
       }
     } else {
       await SunmiPrinter.printText("No transactions available.\n");
     }
     // Amounts by PaymentType
     if (totalAmountsByPaymentType.isNotEmpty) {
       await SunmiPrinter.printText("\nAmounts by Payment Method:\n");
       for (var total in totalAmountsByPaymentType) {
         await SunmiPrinter.printText(" ${total['paymentTypeName']}:\t\t\t\t${total['currencySymbol']}${total['totalAmount']}");
       }
       await SunmiPrinter.printText("--------------------------------");
     }

     // Amounts by total sales
     if (totalAmountsByPaymentType.isNotEmpty) {
       await SunmiPrinter.printText("Total Sales:");
       for (var total in totalSales) {
         await SunmiPrinter.printText(" ${total['currencyName']}:\t\t\t\t${total['totalAmount']}");
       }
       await SunmiPrinter.printText("--------------------------------");
     }

      // Cash In
      if (totalCashIn.isNotEmpty) {
        await SunmiPrinter.printText("Cash In:");
        for (var total in totalCashIn) {
          await SunmiPrinter.printText(
              " ${total['currencyName']}:\t\t\t\t${total['totalAmount']}");
        }
        await SunmiPrinter.printText("--------------------------------");
      }

      // Cash Out
      if (totalCashOut.isNotEmpty) {
        await SunmiPrinter.printText("Cash Out:");
        for (var total in totalCashOut) {
          await SunmiPrinter.printText(
              " ${total['currencyName']}:\t\t\t\t${total['totalAmount']}");
        }
        await SunmiPrinter.printText("--------------------------------");
      }

      // Total Submitted
      if (totalSubmitted.isNotEmpty) {
        await SunmiPrinter.printText("Total Submitted:");
        for (var total in totalSubmitted) {
          await SunmiPrinter.printText(
              " ${total['currencyName']}:\t\t\t\t${total['totalAmount']}");
        }
        await SunmiPrinter.printText("--------------------------------");
      }

     // Amounts by Currency
     if (totalAmountsByCurrency.isNotEmpty) {
       await SunmiPrinter.printText("Cash by Currency:");
       for (var total in totalAmountsByCurrency) {
         await SunmiPrinter.printText(" ${total['currencyName']}:\t\t\t\t${total['totalAmount']}");
       }
       await SunmiPrinter.printText("--------------------------------");
     }


     // tips by Currency
     if (totalTips.isNotEmpty) {
       await SunmiPrinter.printText("Tips by Currency:\n");
       for (var total in totalTips) {
         await SunmiPrinter.printText(" ${total['currencyName']}:\t\t\t\t${total['totalAmount']}");
       }
       await SunmiPrinter.printText("--------------------------------");
     }

     // refunds by Currency
     if (refunds.isNotEmpty) {
       await SunmiPrinter.printText("Refunds by Currency:\n");
       for (var total in refunds) {
         await SunmiPrinter.printText(" ${total['currencyName']}:\t\t\t\t${total['totalAmount']}");
       }
       await SunmiPrinter.printText("--------------------------------");
     }
     // breakages
     if (breakages.isNotEmpty) {
       await SunmiPrinter.printText("Breakages:\n");
       for (var total in breakages) {
         await SunmiPrinter.printText(" ${total['name']}:\t\t${total['qty']}");
       }
       await SunmiPrinter.printText("--------------------------------");
     }


     // Footer
     await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
     await SunmiPrinter.printText("*** Thank you! ***");

     await SunmiPrinter.submitTransactionPrint();
     await SunmiPrinter.exitTransactionPrint(true);
   }

  // Print Shift Details
   Future<void> printShiftSummary(ShiftModel shift,RxList<SaleInfoModel> allReceipts, List<Map<String, dynamic>> totalAmountsByCurrency, List<Map<String, dynamic>> totalAmountsByPaymentType,
       List<Map<String, dynamic>> totalCashIn, List<Map<String, dynamic>> totalCashOut, List<Map<String, dynamic>> totalSubmitted, List<Map<String, dynamic>> totalSales, List<Map<String,
           dynamic>> totalTips,List<Map<String, dynamic>> breakages, List<Map<String, dynamic>> refunds) async {
     // Only print on Android platforms
     if (Platform.isWindows) {
       print("Sunmi printer not available on Windows");
       return;
     }
     
     await SunmiPrinter.initPrinter();
     await SunmiPrinter.startTransactionPrint(true);

     // Header
     await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
     await SunmiPrinter.setFontSize(SunmiFontSize.LG);
     await SunmiPrinter.printText("SHIFT SUMMARY\n");
     await SunmiPrinter.resetFontSize();

     // Shift Details
     await SunmiPrinter.setAlignment(SunmiPrintAlign.LEFT);
     await SunmiPrinter.printText("User: ${shift.userFullName ?? ''}");
     await SunmiPrinter.printText("OT: ${shift.openingTime ?? ''}");
     await SunmiPrinter.printText("CT: ${shift.closingTime ?? ''}");

     // Amounts by PaymentType
     if (totalAmountsByPaymentType.isNotEmpty) {
       await SunmiPrinter.printText("\nAmounts by Payment Method:\n");
       for (var total in totalAmountsByPaymentType) {
         await SunmiPrinter.printText(" ${total['paymentTypeName']}:\t\t\t\t${total['currencySymbol']}${total['totalAmount']}");
       }
       await SunmiPrinter.printText("--------------------------------");
     }

     // Amounts by total sales
     if (totalAmountsByPaymentType.isNotEmpty) {
       await SunmiPrinter.printText("\nTotal Sales:\n");
       for (var total in totalSales) {
         await SunmiPrinter.printText(" ${total['currencyName']}:\t\t\t\t${total['totalAmount']}");
       }
       await SunmiPrinter.printText("--------------------------------");
     }

      // Cash In
      if (totalCashIn.isNotEmpty) {
        await SunmiPrinter.printText("\nCash In:\n");
        for (var total in totalCashIn) {
          await SunmiPrinter.printText(
              " ${total['currencyName']}:\t\t\t\t${total['totalAmount']}");
        }
        await SunmiPrinter.printText("--------------------------------");
      }

      // Cash Out
      if (totalCashOut.isNotEmpty) {
        await SunmiPrinter.printText("\nCash Out:\n");
        for (var total in totalCashOut) {
          await SunmiPrinter.printText(
              " ${total['currencyName']}:\t\t\t\t${total['totalAmount']}");
        }
        await SunmiPrinter.printText("--------------------------------");
      }

      // Total Submitted
      if (totalSubmitted.isNotEmpty) {
        await SunmiPrinter.printText("\nTotal Submitted:\n");
        for (var total in totalSubmitted) {
          await SunmiPrinter.printText(
              " ${total['currencyName']}:\t\t\t\t${total['totalAmount']}");
        }
        await SunmiPrinter.printText("--------------------------------");
      }

     // Amounts by Currency
     if (totalAmountsByCurrency.isNotEmpty) {
       await SunmiPrinter.printText("Cash by Currency:\n");
       for (var total in totalAmountsByCurrency) {
         await SunmiPrinter.printText(" ${total['currencyName']}:\t\t\t\t${total['totalAmount']}");
       }
       await SunmiPrinter.printText("--------------------------------");
     }

     // tips by Currency
     if (totalTips.isNotEmpty) {
       await SunmiPrinter.printText("Tips by Currency:\n");
       for (var total in totalTips) {
         await SunmiPrinter.printText(" ${total['currencyName']}:\t\t\t\t${total['totalAmount']}");
       }
       await SunmiPrinter.printText("--------------------------------");
     }
     // refunds by Currency
     if (refunds.isNotEmpty) {
       await SunmiPrinter.printText("Refunds by Currency:\n");
       for (var total in refunds) {
         await SunmiPrinter.printText(" ${total['currencyName']}:\t\t\t\t${total['totalAmount']}");
       }
       await SunmiPrinter.printText("--------------------------------");
     }
     // breakages
     if (breakages.isNotEmpty) {
       await SunmiPrinter.printText("Breakages:\n");
       for (var total in breakages) {
         await SunmiPrinter.printText(" ${total['name']}:\t\t${total['qty']}");
       }
       await SunmiPrinter.printText("--------------------------------");
     }

     // Footer
     await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
     await SunmiPrinter.printText("*** Thank you! ***");

     await SunmiPrinter.submitTransactionPrint();
     await SunmiPrinter.exitTransactionPrint(true);
   }

  // Print USB Shift Details (with transactions) - matches Sunmi printShiftDetails
  Future<void> printShiftDetailsUsb(ShiftModel shift, RxList<SaleInfoModel> allReceipts, List<Map<String, dynamic>> totalAmountsByCurrency, List<Map<String, dynamic>> totalAmountsByPaymentType,
      List<Map<String, dynamic>> totalCashIn, List<Map<String, dynamic>> totalCashOut, List<Map<String, dynamic>> totalSubmitted, List<Map<String, dynamic>> totalSales,
      List<Map<String, dynamic>> totalTips, List<Map<String, dynamic>> breakages, List<Map<String, dynamic>> refunds, AvailablePrinterModel printer) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> receiptData = [];

    // Load company logo
    Uint8List imageBytes = await readLocalFileBytes();
    
    // Convert image to ESC/POS compatible format
    try {
      final img.Image? image = img.decodeImage(imageBytes);
      if (image != null) {
        // Resize image to fit receipt width (max 384 pixels for 80mm paper)
        final img.Image resized = img.copyResize(image, width: 200);
        receiptData += generator.image(resized);
        receiptData += generator.feed(1);
      }
    } catch (e) {
      print('Error processing logo image: $e');
    }

    // Header
    receiptData += generator.text('SHIFT DETAILS',
        styles: PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ));

    // Shift Details
    receiptData += generator.text('User: ${shift.userFullName ?? ''}',
        styles: PosStyles(align: PosAlign.left));
    receiptData += generator.text('OT: ${shift.openingTime ?? ''}',
        styles: PosStyles(align: PosAlign.left));
    receiptData += generator.text('CT: ${shift.closingTime ?? ''}',
        styles: PosStyles(align: PosAlign.left));

    // Transactions
    if (shift.shiftCurrencyAmounts != null && shift.shiftCurrencyAmounts!.isNotEmpty) {
      receiptData += generator.text('\nTransactions:',
          styles: PosStyles(align: PosAlign.left, bold: true));
      for (var currencyAmount in shift.shiftCurrencyAmounts!) {
        var sale = allReceipts.firstWhere((receipt) => receipt.sale!.posReference == currencyAmount.posReference || receipt.sale!.referenceNumber == currencyAmount.posReference
            , orElse: () => SaleInfoModel(sale: null,syncStatus: false));
        receiptData += generator.text('Type:${currencyAmount.amountType ?? ''}\t\tRef: ${currencyAmount.ref}',
            styles: PosStyles(align: PosAlign.left));
        receiptData += generator.text('Time: ${currencyAmount.timeCreated}',
            styles: PosStyles(align: PosAlign.left));
        receiptData += generator.text('Amount: ${currencyAmount.currency.name} ${currencyAmount.amount.toString()}\t\t${sale.sale?.paymentTypes!.firstWhereOrNull((element) => element.paymentType!.name == currencyAmount.paymentType)?.paymentType?.name ??currencyAmount.paymentType}',
            styles: PosStyles(align: PosAlign.left));
        if (sale.sale != null && (sale.sale!.tipAmount ?? 0) > 0) {
          receiptData += generator.text('Tip: ${currencyAmount.currency.symbol ?? ''} ${sale.sale!.tipAmount!.toStringAsFixed(2)}',
              styles: PosStyles(align: PosAlign.left));
        }
        receiptData += generator.text('--------------------------------',
            styles: PosStyles(align: PosAlign.center));
      }
    } else {
      receiptData += generator.text('No transactions available.',
          styles: PosStyles(align: PosAlign.left));
    }

    // Amounts by PaymentType
    if (totalAmountsByPaymentType.isNotEmpty) {
      receiptData += generator.text('\nAmounts by Payment Method:',
          styles: PosStyles(align: PosAlign.left, bold: true));
      for (var total in totalAmountsByPaymentType) {
        receiptData += generator.text(' ${total['paymentTypeName']}:\t\t${total['currencySymbol']}${total['totalAmount']}',
            styles: PosStyles(align: PosAlign.left));
      }
      receiptData += generator.text('--------------------------------',
          styles: PosStyles(align: PosAlign.center));
    }

    // Amounts by total sales
    if (totalSales.isNotEmpty) {
      receiptData += generator.text('Total Sales:',
          styles: PosStyles(align: PosAlign.left, bold: true));
      for (var total in totalSales) {
        receiptData += generator.text(' ${total['currencyName']}:\t\t${total['totalAmount']}',
            styles: PosStyles(align: PosAlign.left));
      }
      receiptData += generator.text('--------------------------------',
          styles: PosStyles(align: PosAlign.center));
    }

    // Cash In
    if (totalCashIn.isNotEmpty) {
      receiptData += generator.text('Cash In:',
          styles: PosStyles(align: PosAlign.left, bold: true));
      for (var total in totalCashIn) {
        receiptData += generator.text(' ${total['currencyName']}:\t\t${total['totalAmount']}',
            styles: PosStyles(align: PosAlign.left));
      }
      receiptData += generator.text('--------------------------------',
          styles: PosStyles(align: PosAlign.center));
    }

    // Cash Out
    if (totalCashOut.isNotEmpty) {
      receiptData += generator.text('Cash Out:',
          styles: PosStyles(align: PosAlign.left, bold: true));
      for (var total in totalCashOut) {
        receiptData += generator.text(' ${total['currencyName']}:\t\t${total['totalAmount']}',
            styles: PosStyles(align: PosAlign.left));
      }
      receiptData += generator.text('--------------------------------',
          styles: PosStyles(align: PosAlign.center));
    }

    // Total Submitted
    if (totalSubmitted.isNotEmpty) {
      receiptData += generator.text('Total Submitted:',
          styles: PosStyles(align: PosAlign.left, bold: true));
      for (var total in totalSubmitted) {
        receiptData += generator.text(' ${total['currencyName']}:\t\t${total['totalAmount']}',
            styles: PosStyles(align: PosAlign.left));
      }
      receiptData += generator.text('--------------------------------',
          styles: PosStyles(align: PosAlign.center));
    }

    // Amounts by Currency
    if (totalAmountsByCurrency.isNotEmpty) {
      receiptData += generator.text('Cash by Currency:',
          styles: PosStyles(align: PosAlign.left, bold: true));
      for (var total in totalAmountsByCurrency) {
        receiptData += generator.text(' ${total['currencyName']}:\t\t${total['totalAmount']}',
            styles: PosStyles(align: PosAlign.left));
      }
      receiptData += generator.text('--------------------------------',
          styles: PosStyles(align: PosAlign.center));
    }

    // tips by Currency
    if (totalTips.isNotEmpty) {
      receiptData += generator.text('Tips by Currency:',
          styles: PosStyles(align: PosAlign.left, bold: true));
      for (var total in totalTips) {
        receiptData += generator.text(' ${total['currencyName']}:\t\t${total['totalAmount']}',
            styles: PosStyles(align: PosAlign.left));
      }
      receiptData += generator.text('--------------------------------',
          styles: PosStyles(align: PosAlign.center));
    }

    // refunds by Currency
    if (refunds.isNotEmpty) {
      receiptData += generator.text('Refunds by Currency:',
          styles: PosStyles(align: PosAlign.left, bold: true));
      for (var total in refunds) {
        receiptData += generator.text(' ${total['currencyName']}:\t\t${total['totalAmount']}',
            styles: PosStyles(align: PosAlign.left));
      }
      receiptData += generator.text('--------------------------------',
          styles: PosStyles(align: PosAlign.center));
    }

    // breakages
    if (breakages.isNotEmpty) {
      receiptData += generator.text('Breakages:',
          styles: PosStyles(align: PosAlign.left, bold: true));
      for (var total in breakages) {
        receiptData += generator.text(' ${total['name']}:\t\t${total['qty']}',
            styles: PosStyles(align: PosAlign.left));
      }
      receiptData += generator.text('--------------------------------',
          styles: PosStyles(align: PosAlign.center));
    }

    // Footer
    receiptData += generator.text('*** Thank you! ***',
        styles: PosStyles(align: PosAlign.center));
    receiptData += generator.feed(2);
    receiptData += generator.cut();

    // Send to printer
    try {
      var model = UsbPrinterInput(name: printer.name, vendorId: printer.vendorId, productId: printer.productId);
      bool connected = await PrinterManager.instance.connect(type: PrinterType.usb, model: model);
      if (!connected) {
        Get.snackbar('Error', 'Failed to connect to printer',
            snackPosition: SnackPosition.BOTTOM);
        return;
      }
      await PrinterManager.instance.send(bytes: receiptData, type: PrinterType.usb);
      await PrinterManager.instance.disconnect(type: PrinterType.usb);
      Get.snackbar('Success', 'Shift details printed successfully',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to print shift details: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  // Print USB Shift Summary (without transactions) - matches Sunmi printShiftSummary
  Future<void> printShiftSummaryUsb(ShiftModel shift, RxList<SaleInfoModel> allReceipts, List<Map<String, dynamic>> totalAmountsByCurrency, List<Map<String, dynamic>> totalAmountsByPaymentType,
      List<Map<String, dynamic>> totalCashIn, List<Map<String, dynamic>> totalCashOut, List<Map<String, dynamic>> totalSubmitted, List<Map<String, dynamic>> totalSales,
      List<Map<String, dynamic>> totalTips, List<Map<String, dynamic>> breakages, List<Map<String, dynamic>> refunds, AvailablePrinterModel printer) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> receiptData = [];

    // Load company logo
    Uint8List imageBytes = await readLocalFileBytes();
    
    // Convert image to ESC/POS compatible format
    try {
      final img.Image? image = img.decodeImage(imageBytes);
      if (image != null) {
        // Resize image to fit receipt width (max 384 pixels for 80mm paper)
        final img.Image resized = img.copyResize(image, width: 200);
        receiptData += generator.image(resized);
        receiptData += generator.feed(1);
      }
    } catch (e) {
      print('Error processing logo image: $e');
    }

    // Header
    receiptData += generator.text('SHIFT SUMMARY',
        styles: PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ));

    // Shift Details
    receiptData += generator.text('User: ${shift.userFullName ?? ''}',
        styles: PosStyles(align: PosAlign.left));
    receiptData += generator.text('OT: ${shift.openingTime ?? ''}',
        styles: PosStyles(align: PosAlign.left));
    receiptData += generator.text('CT: ${shift.closingTime ?? ''}',
        styles: PosStyles(align: PosAlign.left));

    // Amounts by PaymentType
    if (totalAmountsByPaymentType.isNotEmpty) {
      receiptData += generator.text('\nAmounts by Payment Method:',
          styles: PosStyles(align: PosAlign.left, bold: true));
      for (var total in totalAmountsByPaymentType) {
        receiptData += generator.text(' ${total['paymentTypeName']}:\t\t${total['currencySymbol']}${total['totalAmount']}',
            styles: PosStyles(align: PosAlign.left));
      }
      receiptData += generator.text('--------------------------------',
          styles: PosStyles(align: PosAlign.center));
    }

    // Amounts by total sales
    if (totalSales.isNotEmpty) {
      receiptData += generator.text('\nTotal Sales:',
          styles: PosStyles(align: PosAlign.left, bold: true));
      for (var total in totalSales) {
        receiptData += generator.text(' ${total['currencyName']}:\t\t${total['totalAmount']}',
            styles: PosStyles(align: PosAlign.left));
      }
      receiptData += generator.text('--------------------------------',
          styles: PosStyles(align: PosAlign.center));
    }

    // Cash In
    if (totalCashIn.isNotEmpty) {
      receiptData += generator.text('\nCash In:',
          styles: PosStyles(align: PosAlign.left, bold: true));
      for (var total in totalCashIn) {
        receiptData += generator.text(' ${total['currencyName']}:\t\t${total['totalAmount']}',
            styles: PosStyles(align: PosAlign.left));
      }
      receiptData += generator.text('--------------------------------',
          styles: PosStyles(align: PosAlign.center));
    }

    // Cash Out
    if (totalCashOut.isNotEmpty) {
      receiptData += generator.text('Cash Out:',
          styles: PosStyles(align: PosAlign.left, bold: true));
      for (var total in totalCashOut) {
        receiptData += generator.text(' ${total['currencyName']}:\t\t${total['totalAmount']}',
            styles: PosStyles(align: PosAlign.left));
      }
      receiptData += generator.text('--------------------------------',
          styles: PosStyles(align: PosAlign.center));
    }

    // Total Submitted
    if (totalSubmitted.isNotEmpty) {
      receiptData += generator.text('Total Submitted:',
          styles: PosStyles(align: PosAlign.left, bold: true));
      for (var total in totalSubmitted) {
        receiptData += generator.text(' ${total['currencyName']}:\t\t${total['totalAmount']}',
            styles: PosStyles(align: PosAlign.left));
      }
      receiptData += generator.text('--------------------------------',
          styles: PosStyles(align: PosAlign.center));
    }

    // Amounts by Currency
    if (totalAmountsByCurrency.isNotEmpty) {
      receiptData += generator.text('Cash by Currency:',
          styles: PosStyles(align: PosAlign.left, bold: true));
      for (var total in totalAmountsByCurrency) {
        receiptData += generator.text(' ${total['currencyName']}:\t\t${total['totalAmount']}',
            styles: PosStyles(align: PosAlign.left));
      }
      receiptData += generator.text('--------------------------------',
          styles: PosStyles(align: PosAlign.center));
    }

    // tips by Currency
    if (totalTips.isNotEmpty) {
      receiptData += generator.text('Tips by Currency:',
          styles: PosStyles(align: PosAlign.left, bold: true));
      for (var total in totalTips) {
        receiptData += generator.text(' ${total['currencyName']}:\t\t${total['totalAmount']}',
            styles: PosStyles(align: PosAlign.left));
      }
      receiptData += generator.text('--------------------------------',
          styles: PosStyles(align: PosAlign.center));
    }

    // refunds by Currency
    if (refunds.isNotEmpty) {
      receiptData += generator.text('Refunds by Currency:',
          styles: PosStyles(align: PosAlign.left, bold: true));
      for (var total in refunds) {
        receiptData += generator.text(' ${total['currencyName']}:\t\t${total['totalAmount']}',
            styles: PosStyles(align: PosAlign.left));
      }
      receiptData += generator.text('--------------------------------',
          styles: PosStyles(align: PosAlign.center));
    }

    // breakages
    if (breakages.isNotEmpty) {
      receiptData += generator.text('Breakages:',
          styles: PosStyles(align: PosAlign.left, bold: true));
      for (var total in breakages) {
        receiptData += generator.text(' ${total['name']}:\t\t${total['qty']}',
            styles: PosStyles(align: PosAlign.left));
      }
      receiptData += generator.text('--------------------------------',
          styles: PosStyles(align: PosAlign.center));
    }

    // Footer
    receiptData += generator.text('*** Thank you! ***',
        styles: PosStyles(align: PosAlign.center));
    receiptData += generator.feed(2);
    receiptData += generator.cut();

    // Send to printer
    try {
      var model = UsbPrinterInput(name: printer.name, vendorId: printer.vendorId, productId: printer.productId);
      bool connected = await PrinterManager.instance.connect(type: PrinterType.usb, model: model);
      if (!connected) {
        Get.snackbar('Error', 'Failed to connect to printer',
            snackPosition: SnackPosition.BOTTOM);
        return;
      }
      await PrinterManager.instance.send(bytes: receiptData, type: PrinterType.usb);
      await PrinterManager.instance.disconnect(type: PrinterType.usb);
      Get.snackbar('Success', 'Shift summary printed successfully',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to print shift summary: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }


   Future<void> testPrinter() async {
     // Only print on Android platforms
     if (Platform.isWindows) {
       print("Sunmi printer not available on Windows");
       return;
     }
     
     try {
       await SunmiPrinter.initPrinter();
       // Start a transaction
       await SunmiPrinter.startTransactionPrint(true);

       // Test Alignments
       await SunmiPrinter.setAlignment(SunmiPrintAlign.LEFT);
       await SunmiPrinter.printText("Test Align Left\n");
       await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
       await SunmiPrinter.printText("Test Align Center\n");
       await SunmiPrinter.setAlignment(SunmiPrintAlign.RIGHT);
       await SunmiPrinter.printText("Test Align Right\n");

       // Test Font Sizes
       await SunmiPrinter.setFontSize(SunmiFontSize.SM);
       await SunmiPrinter.printText("Small Font Size\n");
       await SunmiPrinter.setFontSize(SunmiFontSize.MD);
       await SunmiPrinter.printText("Medium Font Size\n");
       await SunmiPrinter.setFontSize(SunmiFontSize.LG);
       await SunmiPrinter.printText("Large Font Size\n");
       await SunmiPrinter.setFontSize(SunmiFontSize.XL);
       await SunmiPrinter.printText("Extra Large Font Size\n");
       await SunmiPrinter.resetFontSize();

       // Test Line Wraps
       await SunmiPrinter.printText("Line Wrap Test Below:\n");
       await SunmiPrinter.lineWrap(2);

       // Test QR Code
       await SunmiPrinter.printQRCode("https://example.com");
       await SunmiPrinter.printText("QR Code Printed Above\n");

       // Test Barcode
       await SunmiPrinter.printBarCode(
         "123456789012",
         barcodeType: SunmiBarcodeType.CODE128,
         textPosition: SunmiBarcodeTextPos.TEXT_UNDER,
         height: 100,
       );
       await SunmiPrinter.printText("Barcode Printed Above\n");

       // Separator Line
       await SunmiPrinter.printText("--------------------------------\n");

       // Test Custom Font Size
       await SunmiPrinter.setCustomFontSize(12);
       await SunmiPrinter.printText("Custom Font Size Test\n");
       await SunmiPrinter.resetFontSize();

       // Footer
       await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
       await SunmiPrinter.printText("*** End of Test ***\n");

       // Submit Transaction
       await SunmiPrinter.submitTransactionPrint();

       // Exit Transaction
       await SunmiPrinter.exitTransactionPrint(true);

       print("Test Print Completed Successfully");
     } catch (e) {
       print("Test Print Failed: $e");
     }
   }

  Future<void> printTestWithQRCode() async {
    // Only print on Android platforms
    if (Platform.isWindows) {
      print("Sunmi printer not available on Windows");
      return;
    }
    
    try {
      const dummyUrl = 'https://example.com'; // Dummy URL for the QR Code

      // Step 1: Generate QR Code
      final qrValidationResult = QrValidator.validate(
        data: dummyUrl,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
      );

      if (qrValidationResult.status == QrValidationStatus.error) {
        throw Exception('QR Code generation failed');
      }

      final qrCode = qrValidationResult.qrCode!;

      // Create an image from the QR code
      final painter = QrPainter.withQr(
        qr: qrCode,
        color: const Color(0xFF000000),
        emptyColor: const Color(0xFFFFFFFF),
        gapless: true,
      );

      final picData = await painter.toImageData(200); // Adjust size as needed
      final img.Image baseSizeImage = img.decodeImage(picData!.buffer.asUint8List())!;
      final img.Image grayscaleImage = img.grayscale(baseSizeImage);
      final Uint8List qrImageBytes = Uint8List.fromList(img.encodePng(grayscaleImage));

      // Step 2: Print Header
      await TelpoM8().printWithThermalPrinter(
          "********** TEST PRINT **********\n"
              "Company Name: Demo Corp\n"
              "Address: 123 Test Street\n"
              "Contact: +1-800-555-5555\n\n"
      );

      // Step 3: Print QR Code
      await TelpoM8().printImageWithThermalPrinter(qrImageBytes);

      // Step 4: Print Dummy Transaction Info
      await TelpoM8().printWithThermalPrinter(
          "\nTransaction Details\n"
              "----------------------------\n"
              "Date: 2024-01-01 12:34 PM\n"
              "Transaction ID: TX1234567890\n"
              "Amount: \$100.00\n"
              "Payment Method: Cash\n"
              "----------------------------\n\n"
              "Scan the QR Code above to visit our website!\n"
              "********** END OF TEST **********\n\n"
      );

      // Step 5: Finalize Print
      await TelpoM8().printWithThermalPrinter("Thank you!\n");
    } catch (e) {
      debugPrint('Error during test print: $e');
    }
  }

  Future<void> printSunmiCashSubmitReceipt(String transactionType, List<CurrencyAmount> curAmounts) async {
    // Initialize the printer
    await SunmiPrinter.initPrinter();
    await SunmiPrinter.startTransactionPrint(true);

    // Header
    await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
    await SunmiPrinter.setFontSize(SunmiFontSize.XL);
    await SunmiPrinter.printText("RECEIPT\n");
    await SunmiPrinter.resetFontSize();

    // Transaction Type
    await SunmiPrinter.setAlignment(SunmiPrintAlign.LEFT);
    await SunmiPrinter.printText("Transaction Type: $transactionType\n");
    for (CurrencyAmount element in curAmounts) {
      await SunmiPrinter.printText("Currency: ${element.currency.name?? 'N/A'}\n");
      await SunmiPrinter.printText("Amount: ${element.amount}\n");
    }
    // Separator
    await SunmiPrinter.printText("--------------------------------\n");

    // Footer
    await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
    await SunmiPrinter.printText("*** Thank you for using our service! ***\n");

    // End the transaction
    await SunmiPrinter.submitTransactionPrint();
    await SunmiPrinter.exitTransactionPrint(true);
  }
  Future<void> printSunmiCashManagementReceipt(String transactionType, CurrencyModel selectedCurrency, double amount, String comments) async {

    // Initialize the printer
    await SunmiPrinter.initPrinter();
    await SunmiPrinter.startTransactionPrint(true);

    // Header
    await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
    await SunmiPrinter.setFontSize(SunmiFontSize.XL);
    await SunmiPrinter.printText("RECEIPT\n");
    await SunmiPrinter.resetFontSize();

    // Transaction Type
    await SunmiPrinter.setAlignment(SunmiPrintAlign.LEFT);
    await SunmiPrinter.printText("Transaction Type: $transactionType\n");

    // Currency and Amount
    await SunmiPrinter.printText("Currency: ${selectedCurrency.name ?? 'N/A'}\n");
    await SunmiPrinter.printText("Amount: ${amount}\n");

    // Comments
    await SunmiPrinter.printText("Comments: ${comments}\n");

    // Separator
    await SunmiPrinter.printText("--------------------------------\n");

    // Footer
    await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
    await SunmiPrinter.printText("*** Thank you for using our service! ***\n");

    // End the transaction
    await SunmiPrinter.submitTransactionPrint();
    await SunmiPrinter.exitTransactionPrint(true);
  }



}
