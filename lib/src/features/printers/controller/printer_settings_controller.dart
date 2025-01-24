import 'dart:convert';

import 'package:bluetooth_print/bluetooth_print_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vimbika_pos_app/src/constants/app_constants.dart';
import 'package:vimbika_pos_app/src/constants/app_routes.dart';
import 'package:vimbika_pos_app/src/features/authentication/model/user_model.dart';
import 'package:vimbika_pos_app/src/features/printers/model/available_printer_model.dart';
import 'package:vimbika_pos_app/src/services/local_storage_service.dart';
import 'package:vimbika_pos_app/src/services/printer_service.dart';
import 'package:vimbika_pos_app/src/utils/app_helper.dart';
import 'package:bluetooth_print/bluetooth_print.dart';

class PrinterSettingsController extends GetxController {
  late UserModel user = UserModel(firstName: "", lastName: "", userName: "");
  // late GetStorage box;
  final LocalStorageService _localStorageService = LocalStorageService();
  var printers = <PrinterDevice>[].obs;
  var selectedPrinter = Rx<PrinterDevice?>(null);
  final storage = GetStorage();
  var isSearching = false.obs;
  // PrinterManager _printerManager = PrinterManager.instance;
  var isConnected = false.obs; // Add this to track connection status
  RxList<AvailablePrinterModel> availablePrinters = <AvailablePrinterModel>[].obs;
  Rx<PrinterType> selectedPrinterType = Rx(PrinterType.bluetooth);
  final PrinterService _printerService = Get.put(PrinterService());



  @override
  void onInit() async{
    super.onInit();
    GetStorage box = GetStorage();
    var model = box.read(AppConstants.USER_INFO) ?? {};
    user = UserModel.fromMap(Map<String, dynamic>.from(model));
    List<AvailablePrinterModel> tempList = loadAvailablePrinters(box);
    availablePrinters.value = tempList;

    //WidgetsBinding.instance.addPostFrameCallback((_) => initBluetooth());


  }

  navigateToNetworkPrinter(PrinterType type)async{
     selectedPrinterType.value = type;
     print(type.name);
     searchPrinters(type);
     Get.toNamed(AppRoutes.NETWORK_PRINTERS);
  }
  List<AvailablePrinterModel> loadAvailablePrinters( GetStorage box) {
    List<AvailablePrinterModel> list = _localStorageService.getOfflineList<AvailablePrinterModel>(
        AppConstants.AVAILABLE_PRINTERS,
            (map) => AvailablePrinterModel.fromMap(map),
        box);
    return list;
  }
  void searchPrinters(PrinterType type) async {
      printers.clear();
      printers.refresh();

      if(type.name == 'bluetooth'){
        WidgetsBinding.instance.addPostFrameCallback((_) => initBluetooth());
      } else{
        print("searching.....");
        isSearching.value = true;
        PrinterManager.instance.disconnect(type: type);
        //var printerManager = await PrinterManager.instance;
       // await initPlatformState(_printerManager);
        await initPlatformState();
        await Future.delayed(Duration(seconds: 5));
        try {
          List<PrinterDevice> usbPrinters = [];
          await PrinterManager.instance.discovery(type: type).listen((printer) {
              usbPrinters.add(printer);
          },);
          printers.value = usbPrinters;
          printers.refresh();
        } catch (e) {
          print('Error searching for printers: $e');
        } finally {
          isSearching.value = false;
          print("finally");
        }
      }

  }
  Future<void> initPlatformState() async {

    await  PrinterManager.instance.stateUSB.listen((status) {
      if(status ==USBStatus.connecting){
        isConnected.value = false;
        AppHelper.showLoading('Connecting...');
      }
      if (status == USBStatus.connected) {
        //printTestReceipt(PrinterType.usb);
        isConnected.value = true;
        print("connected");
        AppHelper.hideLoading();
      }
      if(status ==USBStatus.none){
        isConnected.value = false;
        selectedPrinter.value = null;
        print("nothing found");
        AppHelper.hideLoading();
      }
      print('USB status: $status');
      // AppHelper.hideLoading();
    });




  }
  // Method to connect to the printer
  Future<void> connectToPrinter(PrinterDevice printer) async {


    try {
      selectedPrinter.value = printer; // Set the selected printer

      var model = null;
      if(selectedPrinterType.value == PrinterType.bluetooth) {
        BluetoothPrint bluetoothPrint = await BluetoothPrint.instance;
        BluetoothDevice bt = BluetoothDevice();
        bt.name = printer.name;
        bt.address = printer.address;
        await bluetoothPrint.connect(bt);
        Get.snackbar('Success', 'Printer connected successfully');
      }
      else if(selectedPrinterType.value == PrinterType.usb) {
        PrinterManager.instance.disconnect(type: selectedPrinterType.value);
        model = UsbPrinterInput(name: printer.name, vendorId: printer.vendorId, productId: printer.productId);
        await PrinterManager.instance.connect(
            type: PrinterType.usb, model: model);
        Get.snackbar('Success', 'Printer connected successfully');
      }

    } catch (e) {
      selectedPrinter.value = null; // Reset if the connection fails
      isConnected.value = false;
      print('Error connecting to printer: $e');
      Get.snackbar('Error', 'Failed to connect to printer');
    }
  }
  testPrinter(AvailablePrinterModel printer) async{

    try {
      if(printer.type == 'SUNMI_INBUILT_PRINTER') {
        await _printerService.testPrinter();
      }
      else if(printer.type == 'TELPO_INBUILT_PRINTER') {
        await _printerService.printTestWithQRCode();
      }
      else if(printer.type == PrinterType.bluetooth.name) {
        print("testing....");
        BluetoothPrint bluetoothPrint = await BluetoothPrint.instance;
        await bluetoothPrint.disconnect();
        BluetoothDevice bt = BluetoothDevice();
        bt.name = printer.name;
        bt.address = printer.address;
        print(bt.address);
        await bluetoothPrint.connect(bt);
        await Future.delayed(Duration(seconds: 3));
        await printBlueToothTest();
      }
      else if(printer.type == PrinterType.usb) {
        PrinterType? pt = _printerService.parsePrinterType(printer.type!);
        var model = UsbPrinterInput(name: printer.name, vendorId: printer.vendorId, productId: printer.productId);
         await PrinterManager.instance.connect(type: pt!, model: model);
      }


    } catch (e) {
      selectedPrinter.value = null; // Reset if the connection fails
      isConnected.value = false;
      print('Error connecting to printer: $e');
      Get.snackbar('Error', 'Failed to connect to printer');
    }
  }
  // Method to disconnect from the printer
  Future<void> disconnectPrinter() async {
    if(selectedPrinterType.value.name == "bluetooth"){
      BluetoothPrint bluetoothPrint = await BluetoothPrint.instance;
      await bluetoothPrint.disconnect();
    } else{
      PrinterManager.instance.disconnect(type: selectedPrinterType.value);
    }

    selectedPrinter.value = null;
    isConnected.value = false; // Set to false when disconnected
    Get.snackbar('Success', 'Printer disconnected successfully');
  }


// Save the selected printer
  void saveSelectedPrinter(PrinterDevice printer) {
    GetStorage box = GetStorage();
    List<AvailablePrinterModel> tempList = loadAvailablePrinters(box);
    bool exist = _localStorageService.findPrinterByAddress(tempList, printer.address!);
    if(!exist) {
      UniqueKey uniqueKey = UniqueKey();

      String uniqueId = uniqueKey.toString();
      AvailablePrinterModel selPr = AvailablePrinterModel(id: uniqueId,
          name: printer.name,
          address: printer.address,
          productId: printer.productId,
          vendorId: printer.vendorId,
          isDefault: false,
          type: selectedPrinterType.value.name);

      tempList.add(selPr);
      _localStorageService.writeItems(
          AppConstants.AVAILABLE_PRINTERS, tempList, box);
      availablePrinters.value = tempList;
      //_printerManager.disconnect(type: PrinterType.bluetooth);
      print("Saving default printer.. ${printer.name}");
      Get.snackbar('Success', 'Printer saved successfully');
      Get.back();
    } else{
      Get.snackbar('Success', 'Printer already exist!!!', snackPosition: SnackPosition.BOTTOM);
    }

  }
  Future<void> printTestReceipt(PrinterType pt) async {
    // if (selPrinter != null) {
      try {
        // Generate the ESC/POS commands for a simple test receipt
        if(pt.name == "bluetooth"){

           printBlueToothTest();
        } else{
          List<int> receiptData = await getReceiptData();
          // Send the raw ESC/POS data to the printer with the required 'type'
          await PrinterManager.instance.send(
            bytes: receiptData, // Data to be printed
            type: pt,
          );

          Get.snackbar('Success', 'Test receipt printed successfully');
        }

      } catch (e) {
        print('Error printing test receipt: $e');
        Get.snackbar('Error', 'Failed to print test receipt');
      }
    }
    Future<List<int>>  getReceiptData() async{
      List<int> receiptData = [];

      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile);
      receiptData += generator.text('TEST PRINTING\n\n', styles: PosStyles(bold: true, align: PosAlign.center));
      receiptData += generator.text('Thank you!\n\n', styles: PosStyles(align: PosAlign.center));
      receiptData += generator.feed(2);
      receiptData += generator.cut();
      return receiptData;
    }
    selectPrinter(AvailablePrinterModel pr, bool? stat){
      GetStorage box = GetStorage();
      List<AvailablePrinterModel> tempList = loadAvailablePrinters(box);
      List<AvailablePrinterModel> updatedPrinters =  _localStorageService.saveDefaultPrinter(tempList, pr,stat!);

      availablePrinters.value = updatedPrinters;
      _localStorageService.writeItems(AppConstants.AVAILABLE_PRINTERS, updatedPrinters, box);

    }
  Future<void> checkBluetoothPermissions() async {
    if (await Permission.bluetoothScan.isGranted &&
        await Permission.bluetoothConnect.isGranted &&
        await Permission.locationWhenInUse.isGranted) {
      // Permissions are granted
    } else {
      await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,  // You may need location permissions as well
      ].request();
    }
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initBluetooth() async {
    AppHelper.showLoading("Searching devices...");
    BluetoothPrint bluetoothPrint = await BluetoothPrint.instance;
    await bluetoothPrint.disconnect();
    await bluetoothPrint.startScan(timeout: Duration(seconds: 4));
    List<PrinterDevice> devic = [];
    await bluetoothPrint.scanResults.listen((List<BluetoothDevice> devices) {
      for (var device in devices) {
        PrinterDevice pd = PrinterDevice(name: device.name!, address: device.address);
        devic.add(pd);

        print("Device Name: ${device.name}, Device Address: ${device.address}");
      }
    });
    printers.value = devic;
    printers.refresh();
    AppHelper.hideLoading();
    await bluetoothPrint.state.listen((state) async {
      switch (state) {

        case BluetoothPrint.CONNECTED:
          print('********* CONNECTED : $state');
          //printTestReceipt(PrinterType.bluetooth);

          isConnected.value = true;
          //await printBlueToothTest();


          break;
        case BluetoothPrint.DISCONNECTED:

          isConnected.value = false;

          break;
        default:
          break;
      }
    });


  }

  printBlueToothTest() async {
    BluetoothPrint bluetoothPrint = await BluetoothPrint.instance;
    Map<String, dynamic> config = Map();
    List<LineText> list = [];
    list.add(LineText(linefeed: 1));
    list.add(LineText(type: LineText.TYPE_TEXT, content: '\n\n\n***Test***\n', weight: 1, align: LineText.ALIGN_CENTER,linefeed: 1));
    list.add(LineText(type: LineText.TYPE_TEXT, content: '***Thank you!!***\n\n\n\n', weight: 1, align: LineText.ALIGN_CENTER,linefeed: 1));

    list.add(LineText(linefeed: 1));
    await bluetoothPrint.printReceipt(config, list);
  }

  }


