import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:vimbika_pos_app/src/features/sale/widget/custom_dropdown_widget.dart';
import 'package:vimbika_pos_app/src/features/sale_receipts/controller/receipt_controller.dart';
import 'package:vimbika_pos_app/src/services/printer_service.dart';
import 'package:vimbika_pos_app/src/shared/controller/inactivity_controller.dart';
import 'package:vimbika_pos_app/src/shared/models/base_name_model.dart';
import 'package:vimbika_pos_app/src/utils/app_helper.dart';
import 'package:vimbika_pos_app/src/widgets/nav_drawer_widget.dart';

import '../../../constants/app_routes.dart';



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
      child: WillPopScope(
        onWillPop: () async {
        // Navigate to a specific screen when back button is pressed
        Get.offNamed(AppRoutes.SALE); // Replace with your desired route
        return false; // Prevent default back button behavior
      },
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
                icon: Icon(Icons.clear),
                color: Colors.red,
                onPressed: () {
                  receiptController.cancelFilter();
                },
              ),
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo
                      ),
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
                        color: sale!.saleStatus=="REVERSED"?Colors.redAccent[100]:Colors.grey[300],
                        child: ListTile(
                          leading:
                              Text(
                                '${sale!.currency?.symbol ?? ''} ${sale.amountAfterDiscount!.toStringAsFixed(2).toString()}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold,color: Colors.lightGreen),
                              ),
                          title: Text(sale.referenceNumber!,
                            style: TextStyle(
                            fontSize: 20,color: Colors.indigo,fontWeight: FontWeight.bold
                          ),),
                          subtitle: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  Text(sale.paymentTypes!.map((paymentType)=>paymentType.paymentType!.name).join()),
                                  Text(sale.timeIniated!.replaceFirst('T', ' ')),
                                ],
                                  ),
                                Expanded(child:
                              IconButton(onPressed: (){},
                                  icon: saleInfo.syncStatus == true
                                      ?Icon(Icons.check,color: Colors.green,size: 40)
                                      :Icon(Icons.sync_problem_outlined,color: Colors.red,size: 40)
                              )
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${sale.saleStatus ?? 'N/A'}',
                                style: sale.saleStatus!='REVERSED'? TextStyle(fontSize: 12, color: Colors.grey[700]):TextStyle(fontSize: 12, color: Colors.red[700]),
                              ),
                              Expanded(
                                child: Container(
                                  width: 110,
                                  height: double.infinity,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      IconButton(
                                          icon: Icon(Icons.print_outlined,color: Colors.indigoAccent,size: 30),
                                          onPressed: () async {
                                            if(receiptController.isPrintClicked.isFalse) {
                                              receiptController.isPrintClicked.value = true;
                                              sale.saleStatus != 'REVERSED'
                                                  ? receiptController
                                                      .printSale(saleInfo)
                                                  : null;
                                            }
                                          },
                                        ),
                                      Container(
                                        child: sale.saleStatus != 'REVERSED'?IconButton(
                                          enableFeedback: true,
                                          icon: Icon(Icons.delete_forever_outlined,color: Colors.redAccent,size: 30),
                                          onPressed: () {
                                            receiptController.showConfirmDialogToDeleteItem(saleInfo,index);
                                          },
                                        ):SizedBox(),
                                      ),
                                    ],
                                  ),
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
      ),
    );
  }
}
