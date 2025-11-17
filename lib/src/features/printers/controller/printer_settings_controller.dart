import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
  RxBool isSearching = false.obs;

  RxBool isAlwaysPrintEnabled = false.obs;
  RxBool useKOT = false.obs;

  // Debouncer for save printer operation
  Timer? _savePrinterDebouncer;
  var isSaving = false.obs;
  bool _isSaving = false;

  PrinterManager _printerManager = PrinterManager.instance;
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
    var print = box.read(AppConstants.ALWAYS_PRINT)??false;
    if(print){
      isAlwaysPrintEnabled.value = true;
    } else{
      isAlwaysPrintEnabled.value = false;
    }

    //WidgetsBinding.instance.addPostFrameCallback((_) => initBluetooth());


  }


  void toggleDefaultPrintingSettings() {
    isAlwaysPrintEnabled.value = !isAlwaysPrintEnabled.value;
    storage.write(AppConstants.ALWAYS_PRINT,isAlwaysPrintEnabled.value);
  }
  void toggleKOTSettings() {
    useKOT.value = !useKOT.value;
    storage.write(AppConstants.USE_KOT,useKOT.value);
  }

  navigateToNetworkPrinter(PrinterType type)async{
     selectedPrinterType.value = type;
     print(type.name);
     searchPrinters(type);
     var result = await Get.toNamed(AppRoutes.NETWORK_PRINTERS);
     // Refresh the available printers list when returning from search screen
     // Always refresh when returning, but use result to determine if a printer was saved
     refreshAvailablePrinters();
  }
  List<AvailablePrinterModel> loadAvailablePrinters( GetStorage box) {
    List<AvailablePrinterModel> list = _localStorageService.getOfflineList<AvailablePrinterModel>(
        AppConstants.AVAILABLE_PRINTERS,
            (map) => AvailablePrinterModel.fromMap(map),
        box);
    return list;
  }
  
  // Method to refresh the available printers list from storage
  void refreshAvailablePrinters() {
    GetStorage box = GetStorage();
    List<AvailablePrinterModel> tempList = loadAvailablePrinters(box);
    availablePrinters.value = tempList;
    availablePrinters.refresh(); // Force UI update
    print("==================== REFRESHED AVAILABLE PRINTERS ====================");
    print("Total printers: ${availablePrinters.length}");
    // Print debug info about each printer
    for (var printer in availablePrinters) {
      print("  - ${printer.name ?? 'Unknown'} (Type: ${printer.type ?? 'Unknown'})");
      print("    Default: ${printer.isDefault}, Address: ${printer.address ?? 'N/A'}, ID: ${printer.id ?? 'N/A'}");
    }
    var defaultPrinter = availablePrinters.firstWhere((p) => p.isDefault == true, orElse: () => AvailablePrinterModel(name: null, address: null, productId: null, vendorId: null, isDefault: false, type: null));
    print("Default printer: ${defaultPrinter.name ?? 'NONE'}");
    print("===============================================================");
  } void searchPrinters(PrinterType type) async {
    printers.clear();
    printers.refresh();

    if(type.name == 'bluetooth'){
      WidgetsBinding.instance.addPostFrameCallback((_) => initBluetooth());
      // Set searching state for Bluetooth too
      isSearching.value = true;
    } else{
      print("searching.....");
      isSearching.value = true;
      PrinterManager.instance.disconnect(type: type);
      await initPlatformState();

      try {
        List<PrinterDevice> usbPrinters = [];

        // Create a subscription to the discovery stream
        var subscription = PrinterManager.instance.discovery(type: type).listen((printer) {
          // Add each discovered printer to the list (avoid duplicates)
          if (!usbPrinters.any((p) => p.address == printer.address)) {
            usbPrinters.add(printer);
            // Update UI immediately as printers are discovered
            printers.value = List.from(usbPrinters);
            printers.refresh();
          }
        }, onError: (error) {
          print('Error during printer discovery: $error');
        }, onDone: () {
          print('Printer discovery completed');
        });

        // Wait for discovery period (5 seconds)
        await Future.delayed(Duration(seconds: 5));

        // Cancel the subscription after discovery period
        await subscription.cancel();

        // Final update with all discovered printers
        printers.value = usbPrinters;
        printers.refresh();
      } catch (e) {
        print('Error searching for printers: $e');
      } finally {
        isSearching.value = false;
        print("Search completed. Found ${printers.length} printers");
      }
    }

  }
  // void searchPrinters(PrinterType type) async {
  //     printers.clear();
  //     printers.refresh();
  //
  //     if(type.name == 'bluetooth'){
  //       WidgetsBinding.instance.addPostFrameCallback((_) => initBluetooth());
  //     } else{
  //       print("searching.....");
  //       isSearching.value = true;
  //       PrinterManager.instance.disconnect(type: type);
  //       //var printerManager = await PrinterManager.instance;
  //      // await initPlatformState(_printerManager);
  //       await initPlatformState();
  //       await Future.delayed(Duration(seconds: 5));
  //       try {
  //         List<PrinterDevice> usbPrinters = [];
  //         var subscription = await PrinterManager.instance.discovery(type: type).listen((printer) {
  //             usbPrinters.add(printer);
  //         },);
  //         printers.value = usbPrinters;
  //         printers.refresh();
  //       } catch (e) {
  //         print('Error searching for printers: $e');
  //       } finally {
  //         isSearching.value = false;
  //         print("finally");
  //         print(isSearching);
  //       }
  //     }
  //
  // }
  Future<void> initPlatformState() async {

    await  PrinterManager.instance.stateUSB.listen((status) {
      if(status ==USBStatus.connecting){
        isConnected.value = false;
        AppHelper.showLoading('Connecting...');
      }
      if (status == USBStatus.connected) {
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
      print(selectedPrinter.value!.address);

      var model = null;
      if(selectedPrinterType.value == PrinterType.bluetooth) {
        if (Platform.isWindows) {
          Get.snackbar('Not Supported', 'Bluetooth printing is not available on Windows');
          return;
        }
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
        var res = await PrinterManager.instance.connect(
            type: PrinterType.usb, model: model);
        isConnected.value = res;
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
        if (Platform.isWindows) {
          Get.snackbar('Not Supported', 'Bluetooth printing is not available on Windows');
          return;
        }
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
      if (Platform.isWindows) {
        Get.snackbar('Not Supported', 'Bluetooth printing is not available on Windows');
        return;
      }
      BluetoothPrint bluetoothPrint = await BluetoothPrint.instance;
      await bluetoothPrint.disconnect();
    } else{
      PrinterManager.instance.disconnect(type: selectedPrinterType.value);
    }

    selectedPrinter.value = null;
    isConnected.value = false; // Set to false when disconnected
    Get.snackbar('Success', 'Printer disconnected successfully');
  }


// Debounced save selected printer method
  void debouncedSaveSelectedPrinter(PrinterDevice printer) {
    _savePrinterDebouncer?.cancel();
    
    if (_isSaving) {
      Get.snackbar("Info", "Save printer operation in progress...",
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    
    _savePrinterDebouncer = Timer(Duration(milliseconds: 500), () {
      _performSaveSelectedPrinter(printer);
    });
  }

  // Internal method that performs the actual save
  Future<void> _performSaveSelectedPrinter(PrinterDevice printer) async {
    if (_isSaving) return;
    
    _isSaving = true;
    isSaving.value = true;
    
    try {
      await saveSelectedPrinter(printer);
    } catch (e) {
      Get.snackbar("Error", "Failed to save printer: ${e.toString()}",
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      _isSaving = false;
      isSaving.value = false;
    }
  }

// Save the selected printer
  Future<void> saveSelectedPrinter(PrinterDevice printer) async {
    print("==================== SAVE PRINTER CALLED ====================");
    print("Printer Name: ${printer.name}");
    print("Printer Address: ${printer.address}");
    print("Printer Type: ${selectedPrinterType.value.name}");
    print("Printer Vendor ID: ${printer.vendorId}");
    print("Printer Product ID: ${printer.productId}");
    
    GetStorage box = GetStorage();
    List<AvailablePrinterModel> tempList = loadAvailablePrinters(box);
    print("Current printers in storage: ${tempList.length}");
    
    // For USB printers, match by vendor+product ID or name+type if IDs are null
    // For Bluetooth, match by address+type
    // For inbuilt, match by id
    bool exist = false;
    if (selectedPrinterType.value == PrinterType.usb) {
      // USB: match by vendor+product+type, or name+type if vendor/product are null
      exist = tempList.any((p) => 
        p.type == selectedPrinterType.value.name &&
        ((printer.vendorId != null && printer.productId != null && 
          p.vendorId == printer.vendorId && p.productId == printer.productId) ||
         (printer.vendorId == null && printer.productId == null && 
          p.vendorId == null && p.productId == null && 
          p.name == printer.name))
      );
    } else if (selectedPrinterType.value == PrinterType.bluetooth) {
      // Bluetooth: match by address+type
      exist = tempList.any((p) => 
        p.type == selectedPrinterType.value.name &&
        p.address == printer.address &&
        p.address != null // Only match if address is not null
      );
    }
    print("Printer exists check: $exist (Type: ${selectedPrinterType.value.name})");
    
    if(!exist) {
      UniqueKey uniqueKey = UniqueKey();

      String uniqueId = uniqueKey.toString();
      AvailablePrinterModel selPr = AvailablePrinterModel(id: uniqueId,
          name: printer.name,
          address: printer.address,
          productId: printer.productId,
          vendorId: printer.vendorId,
          isDefault: false, // Will be set to true after adding to list
          type: selectedPrinterType.value.name);

      print("Created new printer model: ID=$uniqueId, Name=${selPr.name}, Address=${selPr.address}");

      // Add the new printer to the list first
      tempList.add(selPr);
      print("Added to temp list. Temp list count: ${tempList.length}");
      
      // Now set this printer as default (this will clear defaults on all others)
      List<AvailablePrinterModel> updatedList = _localStorageService.saveDefaultPrinter(tempList, selPr, true);
      print("After saveDefaultPrinter. Updated list count: ${updatedList.length}");
      
      _localStorageService.writeItems(
          AppConstants.AVAILABLE_PRINTERS, updatedList, box);
      
      // Verify it was saved
      List<AvailablePrinterModel> verifyList = loadAvailablePrinters(box);
      print("Verification: Printers in storage after save: ${verifyList.length}");
      for (var p in verifyList) {
        print("  - ${p.name} (${p.type}) - Default: ${p.isDefault}, Address: ${p.address}");
      }
      
      availablePrinters.value = updatedList;
      availablePrinters.refresh();
      //_printerManager.disconnect(type: PrinterType.bluetooth);
      print("==================== PRINTER SAVED SUCCESSFULLY ====================");
      print("Saving printer as default: ${printer.name} (Address: ${printer.address}, Type: ${selectedPrinterType.value.name})");
      
      // Force refresh from storage to ensure consistency
      refreshAvailablePrinters();
      
      Get.snackbar('Success', 'Printer saved and set as default');
      
      // Delay the back navigation slightly to ensure state updates
      await Future.delayed(Duration(milliseconds: 100));
      Get.back(result: true); // Pass result so navigateToNetworkPrinter knows to refresh
    } else{
      // Printer exists, update it to default
      print("Printer already exists. Attempting to update to default...");
      // Match by appropriate fields based on printer type
      int printerIndex = -1;
      if (selectedPrinterType.value == PrinterType.usb) {
        // USB: match by vendor+product+type, or name+type if vendor/product are null
        printerIndex = tempList.indexWhere((p) => 
          p.type == selectedPrinterType.value.name &&
          ((printer.vendorId != null && printer.productId != null && 
            p.vendorId == printer.vendorId && p.productId == printer.productId) ||
           (printer.vendorId == null && printer.productId == null && 
            p.vendorId == null && p.productId == null && 
            p.name == printer.name))
        );
      } else if (selectedPrinterType.value == PrinterType.bluetooth) {
        // Bluetooth: match by address+type
        printerIndex = tempList.indexWhere((p) => 
          p.type == selectedPrinterType.value.name &&
          p.address == printer.address &&
          p.address != null
        );
      }
      print("Found printer at index: $printerIndex");
      
      if (printerIndex != -1) {
        AvailablePrinterModel existingPrinter = tempList[printerIndex];
        print("Existing printer: ${existingPrinter.name} (${existingPrinter.type})");
        List<AvailablePrinterModel> updatedList = _localStorageService.saveDefaultPrinter(tempList, existingPrinter, true);
        _localStorageService.writeItems(AppConstants.AVAILABLE_PRINTERS, updatedList, box);
        
        // Verify it was saved
        List<AvailablePrinterModel> verifyList = loadAvailablePrinters(box);
        print("Verification: Printers in storage after update: ${verifyList.length}");
        
        availablePrinters.value = updatedList;
        availablePrinters.refresh();
        print("==================== PRINTER UPDATED TO DEFAULT ====================");
        print("Updated existing printer to default: ${printer.name} (Address: ${printer.address}, Type: ${selectedPrinterType.value.name})");
        
        // Force refresh from storage to ensure consistency
        refreshAvailablePrinters();
        
        Get.snackbar('Success', 'Printer set as default');
        
        // Delay the back navigation slightly to ensure state updates
        await Future.delayed(Duration(milliseconds: 100));
        Get.back(result: true); // Pass result so navigateToNetworkPrinter knows to refresh
      } else {
        print("WARNING: Printer exists by address but not found by address+type match!");
        Get.snackbar('Warning', 'Printer exists but could not be updated', snackPosition: SnackPosition.BOTTOM);
      }
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
    // Bluetooth permissions not needed on Windows
    if (Platform.isWindows) {
      return;
    }
    
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
    // Bluetooth is not available on Windows
    if (Platform.isWindows) {
      print("Bluetooth printing not available on Windows");
      isSearching.value = false;
      AppHelper.hideLoading();
      Get.snackbar('Not Supported', 'Bluetooth printing is not available on Windows. Please use USB or Network printers.');
      return;
    }
    
    try {
      // Check permissions first
      await checkBluetoothPermissions();
      
      AppHelper.showLoading("Searching devices...");
      BluetoothPrint bluetoothPrint = await BluetoothPrint.instance;
      await bluetoothPrint.disconnect();
      
      List<PrinterDevice> devic = [];
      StreamSubscription? scanSubscription;
      
      // Create subscription to scan results stream
      scanSubscription = bluetoothPrint.scanResults.listen((List<BluetoothDevice> devices) {
        for (var device in devices) {
          // Avoid duplicates
          if (!devic.any((p) => p.address == device.address)) {
            PrinterDevice pd = PrinterDevice(name: device.name ?? 'Unknown', address: device.address);
            devic.add(pd);

            print("Device Name: ${device.name}, Device Address: ${device.address}");
            
            // Update UI immediately as devices are discovered
            printers.value = List.from(devic);
            printers.refresh();
          }
        }
      }, onError: (error) {
        print('Error during Bluetooth scan: $error');
      });
      
      // Start scanning (timeout is 4 seconds)
      await bluetoothPrint.startScan(timeout: Duration(seconds: 4));
      
      // Wait for scan to complete
      await Future.delayed(Duration(seconds: 4));
      
      // Stop scanning and cancel subscription
      await bluetoothPrint.stopScan();
      await scanSubscription.cancel();
      
      // Final update with all discovered devices
      printers.value = devic;
      printers.refresh();
      AppHelper.hideLoading();
      
      print("Bluetooth search completed. Found ${printers.length} devices");
    } catch (e) {
      print('Error during Bluetooth search: $e');
      AppHelper.hideLoading();
      Get.snackbar('Error', 'Failed to search for Bluetooth devices: $e');
    } finally {
      isSearching.value = false;
    }
    
    // Set up state listener (this should be done once, not on every search)
    // Only set up on non-Windows platforms
    if (!Platform.isWindows) {
      try {
        BluetoothPrint bluetoothPrint = await BluetoothPrint.instance;
        bluetoothPrint.state.listen((state) {
          switch (state) {
            case BluetoothPrint.CONNECTED:
              print('********* CONNECTED : $state');
              isConnected.value = true;
              break;
            case BluetoothPrint.DISCONNECTED:
              isConnected.value = false;
              break;
            default:
              break;
          }
        });
      } catch (e) {
        print('Error setting up Bluetooth state listener: $e');
      }
    }
  }

  printBlueToothTest() async {
    if (Platform.isWindows) {
      print("Bluetooth printing not available on Windows");
      Get.snackbar('Not Supported', 'Bluetooth printing is not available on Windows');
      return;
    }
    
    BluetoothPrint bluetoothPrint = await BluetoothPrint.instance;
    Map<String, dynamic> config = Map();
    List<LineText> list = [];
    list.add(LineText(linefeed: 1));
    list.add(LineText(type: LineText.TYPE_TEXT, content: '\n\n\n***Test***\n', weight: 1, align: LineText.ALIGN_CENTER,linefeed: 1));
    list.add(LineText(type: LineText.TYPE_TEXT, content: '***Thank you!!***\n\n\n\n', weight: 1, align: LineText.ALIGN_CENTER,linefeed: 1));

    list.add(LineText(linefeed: 1));
    await bluetoothPrint.printReceipt(config, list);
  }

  @override
  void onClose() {
    _savePrinterDebouncer?.cancel();
    super.onClose();
  }

}


