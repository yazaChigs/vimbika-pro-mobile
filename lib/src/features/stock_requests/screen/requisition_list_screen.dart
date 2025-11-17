import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vimbika_pos_app/src/features/stock_requests/controller/stock_request_controller.dart';
import 'package:vimbika_pos_app/src/features/stock_requests/model/requisition_item_model.dart';
import 'package:vimbika_pos_app/src/shared/controller/inactivity_controller.dart';

import '../../../constants/app_routes.dart';

class RequisitionListScreen extends StatelessWidget {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final InactivityController inactivityController = Get.find();
  final StockRequestController stockRequestController = Get.find();

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Navigate to a specific screen when back button is pressed
        Get.offNamed(AppRoutes.STOCK_REQUESTS_MENU); // Replace with your desired route
        return false; // Prevent default back button behavior
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: inactivityController.resetInactivityTimer,
        onPanDown: (_) => inactivityController.resetInactivityTimer(),
        child: Scaffold(
          key: scaffoldKey,
          appBar: AppBar(
            title: Text('REQUISITIONS'),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () {
                  stockRequestController.getRequisitions();
                },
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  onChanged: (p) {
                    stockRequestController.filterItemsRequisition(p);
                  },
                  decoration: InputDecoration(
                    labelText: 'Search',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              Expanded(
                child: Obx(() {
                  return ListView.builder(
                    itemCount: stockRequestController.filteredRequisitions.length,
                    itemBuilder: (context, index) {
                      var item = stockRequestController.filteredRequisitions[index];
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero, // Sharp corners for square card
                        ),
                        elevation: 4,
                        margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    item.referenceNumber ?? 'Unknown Ref',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        item.requisitionStatus ?? 'Unknown Status',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      Text(
                                        'ITEMS ${item.requisitionItems!.length.toString()}',  // Assuming amount is added to the TicketModel
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),

                              Text(
                                'Time: ${item.timeRequested ?? 'N/A'}',
                                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                              ),

                              SizedBox(height: 4),
                              Text(
                                'Branch : ${item.branch!.name ?? 'N/A'}',
                                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                              ),
                              SizedBox(height: 4),

                              Text(
                                'Warehouse : ${item.warehouse!.name ?? 'N/A'}',
                                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                              ),
                              Divider(thickness: 1, height: 20),
                               for(RequisitionItemModel req in item.requisitionItems!)
                                 Text(
                                   '${req.inventoryItem!.name ?? 'N/A'} x ${req.quantity}',
                                   style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                 ),



                              Divider(thickness: 1, height: 20),
                              Visibility(
                                visible:  item.requisitionStatus != "CANCELLED",

                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        // Add delete action here
                                        //  ticketController.showConfirmDialogToDeleteItem(item.sale!.referenceNumber ?? '');
                                        stockRequestController.showConfirmDialogToCancelItem(item);
                                      },
                                      child: Text(
                                        'Cancel',
                                        style: TextStyle(color: Colors.redAccent),
                                      ),
                                    ),
                                    SizedBox(width: 10),

                                     ElevatedButton(
                                        onPressed: () {
                                          stockRequestController.editRequisition(item);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                                        ),
                                        child: Text('Edit'),
                                      ),

                                  ],
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
