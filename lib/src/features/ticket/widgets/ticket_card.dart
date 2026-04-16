import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vimbika_pos_app/src/features/sale/model/sale_infor_model.dart';
import 'package:vimbika_pos_app/src/features/ticket/controller/ticket_controller.dart';

class TicketCard extends StatelessWidget {
  final SaleInfoModel ticket;
  final TicketController ticketController = Get.find();

  TicketCard({Key? key, required this.ticket}) : super(key: key);
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 950.0;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: context.theme.colorScheme.surfaceVariant,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: !isMobile(context)?  Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.sale!.ticketName ?? 'Unknown Ticket',
                        style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Opened: ${ticket.sale!.timeIniated ?? 'N/A'}',
                        style: context.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${ticket.sale!.currency?.symbol ?? ''} ${ticket.sale!.amountPaid?.toStringAsFixed(2) ?? '0.00'}',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            // const Divider(height: 20),
            const SizedBox(height: 10),
            // Body: List of items
            Container(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: ticket.sale!.items?.map((saleItem) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 0.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${saleItem.inventoryItem?.name ?? 'N/A'} x ${saleItem.quantity}",
                                style: TextStyle(color: context.theme.colorScheme.secondary, fontWeight: FontWeight.bold,fontStyle: FontStyle.italic),
                              ),
                              if (saleItem.notes != null && saleItem.notes!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2.0, left: 8.0),
                                  child: Text(
                                    "Notes: ${saleItem.notes}",
                                    style: context.textTheme.bodySmall?.copyWith(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList() ??
                      [],
                ),
              ),
            ),
            const Divider(height: 20),


            // Footer: Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    ticketController.showConfirmDialogToDeleteItem(
                        ticket.sale!.referenceNumber ?? "", ticket.sale!.id ?? "");
                  },
                  child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                ),
                const SizedBox(width: 4),

                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        ticketController.printBill(ticket);
                      },
                      child: Text('Print Bill', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                    ),

                const SizedBox(width: 4),
                if (ticket.sale!.saleStatus == "ON_HOLD")
                  ElevatedButton(
                    onPressed: () {
                      ticketController.selectTicketAction(ticket);
                    },
                    child: const Text('Select'),
                  ),
                  ],
                ),
              ],
            ),
          ],
        ): Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.sale!.ticketName ?? 'Unknown Ticket',
                        style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Opened: ${ticket.sale!.timeIniated ?? 'N/A'}',
                        style: context.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${ticket.sale!.currency?.symbol ?? ''} ${ticket.sale!.amountPaid?.toStringAsFixed(2) ?? '0.00'}',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            // const Divider(height: 20),
            const SizedBox(height: 10),
            // Body: List of items
            Container(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: ticket.sale!.items?.map((saleItem) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 0.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${saleItem.inventoryItem?.name ?? 'N/A'} x ${saleItem.quantity}",
                            style: TextStyle(color: context.theme.colorScheme.secondary, fontWeight: FontWeight.bold,fontStyle: FontStyle.italic),
                          ),
                          if (saleItem.notes != null && saleItem.notes!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2.0, left: 8.0),
                              child: Text(
                                "Notes: ${saleItem.notes}",
                                style: context.textTheme.bodySmall?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList() ??
                      [],
                ),
              ),
            ),
            const Divider(height: 20),


            // Footer: Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    ticketController.showConfirmDialogToDeleteItem(
                        ticket.sale!.referenceNumber ?? "", ticket.sale!.id ?? "");
                  },
                  child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                ),
                const SizedBox(width: 4),

                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        ticketController.printBill(ticket);
                      },
                      child: Text('Print Bill', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                    ),

                    const SizedBox(width: 4),
                    if (ticket.sale!.saleStatus == "ON_HOLD")
                      ElevatedButton(
                        onPressed: () {
                          ticketController.selectTicketAction(ticket);
                        },
                        child: const Text('Select'),
                      ),
                  ],
                ),
              ],
            ),
          ],
        )
      ),
    );
  }
}
