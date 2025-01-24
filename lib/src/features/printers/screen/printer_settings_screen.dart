import 'package:flutter/material.dart';
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';
import 'package:get/get.dart';
import 'package:vimbika_pos_app/src/features/printers/controller/printer_settings_controller.dart';
import 'package:vimbika_pos_app/src/shared/controller/inactivity_controller.dart';
import 'package:vimbika_pos_app/src/widgets/list_tile_widget.dart';
import 'package:vimbika_pos_app/src/widgets/nav_drawer_widget.dart'; // Assuming you have a NavDrawerWidget

class PrinterSettingsScreen extends StatelessWidget {
  final PrinterSettingsController _controller = Get.put(PrinterSettingsController());
  final InactivityController inactivityController = Get.put(
      InactivityController());
  var scaffoldKeyz = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    String fullName = "${_controller.user.firstName} ${_controller.user.lastName}";
    String initials = _controller.user.firstName[0] + _controller.user.lastName[0];

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
              Expanded(
                child: Obx(() {
                  return ListView.builder(
                    itemCount: _controller.availablePrinters.length,
                    itemBuilder: (context, index) {
                      final printer = _controller.availablePrinters[index];
                      return Column(
                        children: [
                          ListTileWidget(
                            printer: printer,
                            onDefaultChanged: (bool? value) {
                              _controller.selectPrinter(printer, value);
                            },
                            onTestPrinter: () {
                              _controller.testPrinter(printer);
                            },
                          ),
                          if (index < _controller.availablePrinters.length - 1) // Add space only between items, not after the last item
                            SizedBox(height: 10),
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
                  onPressed: (){
                    _controller.navigateToNetworkPrinter(PrinterType.bluetooth);
                  },
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (){
                    _controller.navigateToNetworkPrinter(PrinterType.usb);
                  },
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
