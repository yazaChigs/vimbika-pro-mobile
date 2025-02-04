import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vimbika_pos_app/src/features/stock_requests/controller/stock_request_controller.dart';
import 'package:vimbika_pos_app/src/features/stock_requests/screen/receive_stock_screen.dart';
import 'package:vimbika_pos_app/src/features/stock_requests/model/transfer_item_model.dart';
import 'package:vimbika_pos_app/src/shared/controller/inactivity_controller.dart';

class RequisitionHistoryScreen extends StatelessWidget {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final InactivityController inactivityController = Get.find();
  final StockRequestController stockRequestController = Get.find();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: inactivityController.resetInactivityTimer,
      onPanDown: (_) => inactivityController.resetInactivityTimer(),
      child: Scaffold(
        key: scaffoldKey,
        appBar: AppBar(
          title: Text('HISTORY'),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () {
                stockRequestController.getReqHistory();
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
                  stockRequestController.filterReqHistory(p);
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
                  itemCount: stockRequestController.filteredReqHistory.length,
                  itemBuilder: (context, index) {
                    var item = stockRequestController.filteredReqHistory[index];
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
                                  item.reference ?? 'Unknown Ref',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                Column(
                                  children: [
                                    Text(
                                      item.status ?? 'Unknown Status',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Text(
                                      'ITEMS ${item.transferItems!.length.toString()}',  // Assuming amount is added to the TicketModel
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
                              'Time: ${item.dateTime ?? 'N/A'}',
                              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                            ),

                            SizedBox(height: 4),
                            Text(
                              'Branch From: ${item.fromBranch!.name ?? 'N/A'}',
                              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                            ),
                            SizedBox(height: 4),

                            Text(
                              'Branch To: ${item.toBranch!.name ?? 'N/A'}',
                              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Divider(thickness: 1, height: 20),
                                for (TransferItemModel req in item.transferItems!)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4.0), // Adds spacing between rows
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween, // Ensures spacing between items
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${req.item?.name ?? 'N/A'} x ${req.quantity}',
                                            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            '${'Allocated'} x ${req.allocated ?? 'NIL'}',
                                            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                            textAlign: TextAlign.right, // Aligns text to the right for better readability
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [

                                  ElevatedButton(
                                    onPressed: () {
                                      //ticketController.selectTicketAction(item);
                                      // Get.to(() => ReceiveStockScreen(transferHistory: item));
                                      stockRequestController.printGRV(item);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                                    ),
                                    child: Text('PRINT GRV'),
                                  ),

                              ],
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
