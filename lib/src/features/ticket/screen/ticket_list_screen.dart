import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vimbika_pos_app/src/features/ticket/controller/ticket_controller.dart';
import 'package:vimbika_pos_app/src/shared/controller/inactivity_controller.dart';

class TicketListScreen extends StatelessWidget {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final InactivityController inactivityController = Get.put(InactivityController());
  final TicketController ticketController = Get.put(TicketController());

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: inactivityController.resetInactivityTimer,
      onPanDown: (_) => inactivityController.resetInactivityTimer(),
      child: Scaffold(
        key: scaffoldKey,
        appBar: AppBar(
          title: Text('TICKETS'),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () {
                 ticketController.getTickets();
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
                  ticketController.filterItems(p);
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
                  itemCount: ticketController.filteredTickets.length,
                  itemBuilder: (context, index) {
                    var item = ticketController.filteredTickets[index];
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
                                  item.sale!.ticketName ?? 'Unknown Name',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                Column(
                                  children: [
                                    Text(
                                      "OPEN",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Text(
                                      '${item.sale!.currency?.symbol} ${item.sale!.amountPaid!.toStringAsFixed(2) ?? 0} ',  // Assuming amount is added to the TicketModel
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
                            // Text(
                            //   'Opened By: ${item.openedBy ?? ''}',
                            //   style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                            // ),
                            // SizedBox(height: 4),
                            Text(
                              'Opened At: ${item.sale!.timeIniated ?? 'N/A'}',
                              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                            ),



                            SizedBox(height: 4),
                            if (item.sale!.ticketComment != null && item.sale!.ticketComment!.isNotEmpty)
                              Text(
                                'Comment: ${item.sale!.ticketComment}',
                                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                              ),

                            SizedBox(height: 4),
                            Text(
                              'Reference: ${item.sale!.referenceNumber ?? 'N/A'}',
                              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                            ),
                            Divider(thickness: 1, height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    // Add delete action here
                                    ticketController.showConfirmDialogToDeleteItem(item.sale!.referenceNumber ?? '');
                                  },
                                  child: Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.redAccent),
                                  ),
                                ),
                                SizedBox(width: 10),

                                Visibility(
                                  visible:  item.sale!.saleStatus == "ON_HOLD",
                                  child: ElevatedButton(
                                    onPressed: () {
                                      ticketController.selectTicketAction(item);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                                    ),
                                    child: Text('Select'),
                                  ),
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
