import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:vimbika_pos_app/src/features/sale/widget/custom_dropdown_widget.dart';
import 'package:vimbika_pos_app/src/features/sale_receipts/controller/receipt_controller.dart';
import 'package:vimbika_pos_app/src/services/printer_service.dart';
import 'package:vimbika_pos_app/src/shared/controller/inactivity_controller.dart';
import 'package:vimbika_pos_app/src/shared/models/base_name_model.dart';
import 'package:vimbika_pos_app/src/widgets/nav_drawer_widget.dart';



class ReceiptScreen extends StatelessWidget {
  var scaffoldKey = GlobalKey<ScaffoldState>();
  final InactivityController inactivityController = Get.put(InactivityController());
  final ReceiptController receiptController = Get.put(ReceiptController());


  @override
  Widget build(BuildContext context) {
    String fullName = "${receiptController.user.firstName} ${receiptController.user.lastName}";
    String initials = receiptController.user.firstName[0] + receiptController.user.lastName[0];

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: inactivityController.resetInactivityTimer,
      onPanDown: (_) => inactivityController.resetInactivityTimer(),
      child: Scaffold(
        key: scaffoldKey,
        appBar: AppBar(
          title: Text('RECEIPTS'),
          leading: IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              scaffoldKey.currentState?.openDrawer();
            },
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () {
                receiptController.refreshFilter();
              },
            ),
          ],
        ),
        drawer: NavDrawer(
          fullName: fullName,
          mobileNumber: receiptController.user.mobilePhone ?? "",
          nameInitials: initials,
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      readOnly: true,
                      controller: receiptController.startDateController,
                      decoration: InputDecoration(
                        labelText: 'Select Start Date',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: () async {
                        DateTime? selectedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (selectedDate != null) {
                          String formattedDate = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").format(selectedDate);
                          receiptController.startDateController.text = DateFormat('yyyy-MM-dd').format(selectedDate);
                          receiptController.startDate.value = formattedDate;
                          //receiptController.getSalesByDate(formattedDate);
                        }
                      },
                    ),
                  ),
                ),
                Expanded(
                    child:Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    readOnly: true,
                    controller: receiptController.endDateController,
                    decoration: InputDecoration(
                      labelText: 'Select End Date',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    onTap: () async {
                      DateTime? selectedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (selectedDate != null) {
                        String formattedDate = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").format(selectedDate);
                        receiptController.endDateController.text = DateFormat('yyyy-MM-dd').format(selectedDate);
                        receiptController.endDate.value = formattedDate;
                      }
                    },
                  ),
                 )
                ),
              ],
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Obx(() {
                      return CustomDropdownWidget<BaseNameModel>(
                        items: receiptController.categories.value,
                        selectedItem: receiptController.selectedCategory.value,
                        hint: "Select Category",
                        isSelected: receiptController.isCatSelected,
                        selectedValue: receiptController.selectedCategory,
                        icon: Icons.shopping_basket_outlined,
                        onChanged: (BaseNameModel? newValue) {
                          print("Selected category: ${newValue?.name}");
                          receiptController.isCatSelected.value = true;
                          receiptController.selectedCategory.value = newValue!;
                        },
                        validator: (value) {
                          return null;
                        },
                        itemBuilder: (BaseNameModel value) =>
                            Text(value.name!),
                      );
                    }),
                  ),
                ),
                Expanded(
                    child:
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      receiptController.searchSales();
                    },
                    child: Text('SEARCH'),
                  ),
                )
                  )
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                onChanged: (p) {
                  receiptController.filterReceipts(p);
                },
                decoration: const InputDecoration(
                  labelText: 'Search',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),


            // Add total amount card here
            Obx(() {
              Map<String, double> totalsByCurrency = receiptController.calculateTotalByCurrency();

              if (totalsByCurrency.isEmpty) {
                return SizedBox.shrink();  // No totals to show, return an empty space
              }

              return Card(
                margin: const EdgeInsets.all(8.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0), // Square corners
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center, // Center the text
                    children: [
                      Text(
                        'Totals by Currency',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 10), // Space between heading and totals
                      ...totalsByCurrency.entries.map((entry) {
                        return Text(
                          '${entry.key}  ${entry.value.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              );
            }),


            Expanded(
              child: Obx(() {
                return ListView.builder(
                  itemCount: receiptController.filteredReceipts.length,
                  itemBuilder: (context, index) {
                    final saleInfo = receiptController.filteredReceipts[index];
                    final sale = saleInfo.sale;

                    return Card(
                      child: ListTile(
                        leading: Text(
                          '${sale!.currency?.symbol ?? ''} ${sale.amountPaid!.toStringAsFixed(2).toString()}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        title: Text(sale.timeIniated!),
                        subtitle: Text(sale.referenceNumber ?? ""),
                        trailing: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${sale.saleStatus ?? 'N/A'}',
                              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                            ),
                            SizedBox(
                              width: 60,
                              height: 24,
                              child: ElevatedButton(
                                onPressed: () async {
                                  // if (saleInfo.syncStatus == true) {
                                  //   // Handle online logic
                                  // } else {
                                  //   Future<Uint8List> pdf = GenerateFlutterPdf.generateReceipt(saleInfo.sale!);
                                  //   Get.to(() => PdfPreviewScreen(pdf: pdf));
                                  // }
                                  receiptController.printSale(saleInfo);

                                },
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  backgroundColor: saleInfo.syncStatus == true
                                      ? Colors.green
                                      : Theme.of(context).primaryColor,
                                  textStyle: TextStyle(fontSize: 10),
                                ),
                                child: Text('Print'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
