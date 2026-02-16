import 'package:flutter/material.dart';
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';
import 'package:get/get.dart';
import 'package:vimbika_pos_app/src/features/printers/controller/printer_settings_controller.dart';
import 'package:vimbika_pos_app/src/shared/controller/inactivity_controller.dart';
import 'package:vimbika_pos_app/src/widgets/list_tile_widget.dart';
import 'package:vimbika_pos_app/src/widgets/nav_drawer_widget.dart'; // Assuming you have a NavDrawerWidget

class PrinterSettingsScreen extends StatefulWidget {
  @override
  _PrinterSettingsScreenState createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  final PrinterSettingsController _controller =
      Get.put(PrinterSettingsController());
  final InactivityController inactivityController =
      Get.put(InactivityController());
  var scaffoldKeyz = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Reload printers list when screen is shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.refreshAvailablePrinters();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh when screen becomes visible again (defer until after build)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.refreshAvailablePrinters();
    });
  }

  @override
  Widget build(BuildContext context) {
    String fullName =
        "${_controller.user.firstName} ${_controller.user.lastName}";
    String initials =
        _controller.user.firstName[0] + _controller.user.lastName[0];

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: inactivityController.resetInactivityTimer,
      onPanDown: (_) => inactivityController.resetInactivityTimer(),
      child: Scaffold(
        key: scaffoldKeyz,
        appBar: AppBar(
          title: Text('PRINTER SETTINGS'),
          // leading: IconButton(
          //   icon: Icon(Icons.menu),
          //   onPressed: () {
          //     scaffoldKeyz.currentState?.openDrawer();
          //   },
          // ),
        ),
        // drawer: NavDrawer(fullName: fullName, mobileNumber: _controller.user.mobilePhone ?? "", nameInitials: initials),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox
              Obx(() => CheckboxListTile(
                    title: Text(
                      'Always Print',
                      style: TextStyle(fontSize: 16),
                    ),
                    value: _controller.isAlwaysPrintEnabled.value,
                    onChanged: (value) {
                      _controller.toggleDefaultPrintingSettings();
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  )),

              Obx(() => CheckboxListTile(
                    title: Text(
                      'Use KOT Print',
                      style: TextStyle(fontSize: 16),
                    ),
                    value: _controller.useKOT.value,
                    onChanged: (value) {
                      _controller.toggleKOTSettings();
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  )),
              SizedBox(height: 50),
              Expanded(
                child: Obx(() {
                  return ListView.builder(
                    itemCount: _controller.availablePrinters.length,
                    itemBuilder: (context, index) {
                      final printer = _controller.availablePrinters[index];
                      return Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: context.theme.colorScheme.primaryContainer,
                              border: Border.all(
                                  color: context.theme.colorScheme.primary),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTileWidget(
                              printer: printer,
                              onDefaultChanged: (bool? value) {
                                _controller.selectPrinter(printer, value);
                              },
                              onTestPrinter: () {
                                _controller.testPrinter(printer);
                              },
                            ),
                          ),
                          if (index <
                              _controller.availablePrinters.length -
                                  1) // Add space only between items, not after the last item
                            SizedBox(
                              height: 10,
                            ),
                        ],
                      );
                    },
                  );
                }),
              ),
              SizedBox(height: 20),

              SizedBox(height: 20),
              // SizedBox(
              //   width: double.infinity,
              //   child: ElevatedButton(
              //     onPressed: _controller.testPrint,
              //     child: Text('Test Print'),
              //   ),
              // ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _controller.navigateToNetworkPrinter(PrinterType.bluetooth);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        context.theme.colorScheme.primary, // Background color
                    foregroundColor:
                        context.theme.colorScheme.onPrimary, 
                        
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 16),
                    // Text color
              
                  ),
                  child: Text('Search Bluetooth Printers'),
                ),
              ),
              // SizedBox(height: 20),
              // SizedBox(
              //   width: double.infinity,
              //   child: ElevatedButton(
              //     onPressed: (){
              //       _controller.navigateToNetworkPrinter(PrinterType.network);
              //     },
              //     child: Text('Search Ethernet/WiFi Printers'),
              //   ),
              // ),
              SizedBox(height: 20),
              Container(
                width: double.infinity,
                margin: EdgeInsets.only(bottom: 20),
                child: ElevatedButton(
                  // style: ButtonStyle(
                  //   backgroundColor: MaterialStateProperty.all(context.theme.colorScheme.primary),
                  //   padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 20, horizontal: 16)),
                  //   shape: MaterialStateProperty.all(RoundedRectangleBorder(
                  //     borderRadius: BorderRadius.circular(12),
                  //   )),
                  // ),
                  onPressed: () {
                    _controller.navigateToNetworkPrinter(PrinterType.usb);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        context.theme.colorScheme.primary, // Background color
                    foregroundColor:
                        context.theme.colorScheme.onPrimary, // Text color
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 16),
                  ),
                  child: Text('Search USB Printers'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
