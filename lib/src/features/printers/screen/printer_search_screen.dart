import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vimbika_pos_app/src/features/printers/controller/printer_settings_controller.dart';
import 'package:vimbika_pos_app/src/shared/controller/inactivity_controller.dart';

class NetworkPrintersScreen extends StatelessWidget {
  final PrinterSettingsController printerController = Get.find();
  final InactivityController inactivityController = Get.find();
  GlobalKey<FormState> formKeyNetwork = GlobalKey<FormState>();


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: inactivityController.resetInactivityTimer,
      onPanDown: (_) => inactivityController.resetInactivityTimer(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('ADD PRINTERS'),
        ),
        body: Column(
          children: [
            Obx(() => printerController.isSearching.value
                ? CircularProgressIndicator()
                : SizedBox.shrink()
            ),
            Expanded(
              child: Obx(() => ListView.builder(
                itemCount: printerController.printers.length,
                itemBuilder: (context, index) {
                  var printer = printerController.printers[index];
                  return Card(
                    elevation: 4,
                    margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: ListTile(
                      title: Text(
                        printer.name ?? 'Unknown Printer',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(printer.address ?? 'No address'),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Show 'Connect' button if this printer is not the selected one
                              Obx(() => printerController.selectedPrinter.value == printer
                                  ? SizedBox.shrink() // Hide if this printer is connected
                                  : ElevatedButton(
                                onPressed: () {
                                  printerController.connectToPrinter(printer);
                                },
                                style: ElevatedButton.styleFrom(
                                  minimumSize: Size(80, 35), // Small button
                                ),
                                child: Text('Connect'),
                              ),
                              ),

                              // Show 'Disconnect' button if this printer is the selected one
                              Obx(() => printerController.selectedPrinter.value == printer && printerController.isConnected.isTrue
                                  ? ElevatedButton(
                                onPressed: () {
                                  printerController.disconnectPrinter();
                                },
                                style: ElevatedButton.styleFrom(
                                  minimumSize: Size(80, 35), // Small button
                                  backgroundColor: Colors.redAccent,
                                ),
                                child: Text('Disconnect'),
                              )
                                  : SizedBox.shrink(), // Hide if this printer is not connected
                              ),

                              // Show 'Test Printer' button if this printer is the selected one
                              Obx(() => printerController.selectedPrinter.value == printer && printerController.isConnected.isTrue
                                  ? ElevatedButton(
                                onPressed: () {
                                  printerController.printTestReceipt(printerController.selectedPrinterType.value);
                                },
                                style: ElevatedButton.styleFrom(
                                  minimumSize: Size(80, 35), // Small button
                                  backgroundColor: Colors.blueAccent,
                                ),
                                child: Text('Test'),
                              )
                                  : SizedBox.shrink(), // Hide if this printer is not connected
                              ),

                              // Show 'Save' button if this printer is the selected one
                              Obx(() => printerController.selectedPrinter.value == printer && printerController.isConnected.isTrue
                                  ? IconButton(
                                icon: Icon(Icons.save),
                                onPressed: printerController.isSaving.value
                                    ? null
                                    : () {
                                        printerController.debouncedSaveSelectedPrinter(printer);
                                      },
                                tooltip: printerController.isSaving.value ? 'Saving...' : 'Save',
                              )
                                  : SizedBox.shrink(), // Hide if this printer is not connected
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )),
            ),
          ],
        ),
      ),
    );
  }
}
