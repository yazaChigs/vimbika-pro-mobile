import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vimbika_pos_app/src/features/ticket/controller/ticket_controller.dart';
import 'package:vimbika_pos_app/src/features/ticket/widgets/ticket_card.dart';
import 'package:vimbika_pos_app/src/shared/controller/inactivity_controller.dart';

class TicketListScreen extends StatelessWidget {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final InactivityController inactivityController = Get.put(InactivityController());
  final TicketController ticketController = Get.put(TicketController());

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    Orientation orientation = MediaQuery.of(context).orientation;

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
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: context.theme.colorScheme.primary),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: context.theme.colorScheme.primary, width: 2.0),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: context.theme.colorScheme.primary),
                  ),
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: orientation == Orientation.landscape ? 3 : 2,
                    crossAxisSpacing: 3.0,
                    mainAxisSpacing: 3.0,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: ticketController.filteredTickets.length,
                  itemBuilder: (context, index) {
                    var item = ticketController.filteredTickets[index];
                    return TicketCard(ticket: item);
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
