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
                return GridView.builder(gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 3.0,
                    mainAxisSpacing: 3.0,
                    childAspectRatio: 1.5,
                ),
                  itemCount: ticketController.filteredTickets.length,
                  itemBuilder: (context, index) {
                    var item = ticketController.filteredTickets[index];
                    var itemsText = item.sale!.items?.map((element)=>"-"+element.inventoryItem!.name! +" X "+ element.quantity.toString() + "\n");
                    return Card(
                      color:  context.theme.colorScheme.secondaryContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8), // Sharp corners for square card
                      ),
                      elevation: 4,
                      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                      child: Padding(
                        padding: const EdgeInsets.all(0.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          spacing: 0,
                          children: [
                            Flexible(
                              child: Row(
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
                                  Text(
                                    'Opened: ${item.sale!.timeIniated ?? 'N/A'}',
                                    style: TextStyle(fontSize: 14, color:  context.theme.colorScheme.onSurface,),
                                  ),
                                      Text(
                                        '${item.sale!.currency?.symbol} ${item!.sale!.amountPaid!.toStringAsFixed(2) ?? 0} ',  // Assuming amount is added to the TicketModel
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green,
                                        ),
                                      ),
                                  //   ],
                                  // ),
                                ],
                              ),
                            ),

                            Expanded(
                              child: Column(
                                spacing:0,
                              children: List.generate(item.sale!.items!.length,(index){
                                return   Column(
                                  children: [
                                    Text(
                                      "${item.sale!.items![index].inventoryItem!.name} X ${item.sale!.items![index].quantity}",
                                      style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold,fontStyle: FontStyle.italic,color:  context.theme.colorScheme.onSurface,),
                                    ),
                                    if(item.sale!.items![index].notes!=null && item.sale!.items![index].notes!.isNotEmpty)
                                    Text(
                                      "${item.sale!.items![index].notes??""}",
                                      style: TextStyle(fontSize: 12,fontStyle: FontStyle.italic,color: Colors.redAccent),
                                    ),
                                  ],
                                );
                              }),
                                                          ),
                            ),
                            Divider(thickness: 1, height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                //
                                TextButton(
                                  onPressed: () {
                                    // Add delete action here
                                    ticketController.showConfirmDialogToDeleteItem(item.sale!.referenceNumber ?? "", item.sale!.id ?? "");
                                  },
                                  style: ButtonStyle(
                                      shape: MaterialStateProperty.all(RoundedRectangleBorder(
                                          side: BorderSide(
                                            color: Colors.red, // your color here
                                            width: 3,
                                          ),
                                          borderRadius: BorderRadius.circular(8)))),
                                  child: Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.redAccent),
                                  ),
                                ),
                                SizedBox(width: 10),

                                TextButton(
                                  onPressed: () {
                                    // Add delete action here
                                    ticketController.printBill(item);
                                  },
                                  style: ButtonStyle(
                                      shape: MaterialStateProperty.all(RoundedRectangleBorder(
                                          side: BorderSide(
                                            color: Colors.indigo, // your color here
                                            width: 3,
                                          ),
                                          borderRadius: BorderRadius.circular(8)))),
                                  child: Text(
                                    'Print Bill',
                                    style: TextStyle(color: Colors.indigo),
                                  ),
                                ),
                                SizedBox(width: 10),

                                Visibility(
                                  visible:  item.sale!.saleStatus == "ON_HOLD",
                                  child: ElevatedButton(
                                    style:TextButton.styleFrom(
                                        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                                      backgroundColor:  context.theme.colorScheme.secondary,
                                      foregroundColor: Colors.black,
                                      textStyle: TextStyle(
                                          fontSize: 18,
                                          color: context.theme.colorScheme.onSurface,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    onPressed: () {
                                      ticketController.selectTicketAction(item);
                                    },
                                    // style: ElevatedButton.styleFrom(
                                    //   padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                                    // ),
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
