import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import this for input formatters
import 'package:get/get.dart';
import 'package:vimbika_pos_app/src/features/stock_requests/controller/receive_stock_controller.dart';
import 'package:vimbika_pos_app/src/features/stock_requests/model/transfer_history_model.dart';

class ReceiveStockScreen extends StatelessWidget {
  final ReceiveStockController controller = Get.put(ReceiveStockController());
  final TransferHistoryModel transferHistory;

  ReceiveStockScreen({required this.transferHistory}) {
    controller.setTransferHistory(transferHistory);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Receive Stock"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blueGrey[900],
      ),
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
        child: Column(
          children: [
            _buildHeader(context),
            SizedBox(height: 10),
            Obx(() => _buildReceiveAllToggle()),
            SizedBox(height: 10),
            Expanded(child: Obx(() => _buildItemList())),
            SizedBox(height: 20),
            _buildReceiveButton(),
          ],
        ),
      ),
    );
  }

  /// Header Card with Reference ID & Date
  Widget _buildHeader(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.blueGrey[900],
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Transfer Reference: ${transferHistory.reference ?? 'N/A'}",
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(
              "Status: ${transferHistory.status ?? 'Pending'}",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  /// Toggle Switch for "Receive All"
  Widget _buildReceiveAllToggle() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: SwitchListTile(
          title: Text(
            "Receive All Items?",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          value: controller.allSelected.value,
          activeColor: Colors.green,
          onChanged: (value) => controller.toggleReceiveAll(value),
        ),
      ),
    );
  }

  /// List of Items with Number-Only Validation
  Widget _buildItemList() {
    return ListView.builder(
      itemCount: controller.transferHistory.value.transferItems?.length ?? 0,
      itemBuilder: (context, index) {
        final item = controller.transferHistory.value.transferItems![index];

        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.symmetric(vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.item?.name ?? "Unknown Item",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Required: ${item.quantity}",
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Only numbers
                            controller: controller.textControllers[index],
                            decoration: InputDecoration(
                              labelText: "Received",
                              prefixIcon: Icon(Icons.inventory_2, color: Colors.blueGrey[700]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[200],
                            ),
                            onChanged: (value) {
                              controller.validateAndUpdateQuantity(index, value);
                            },
                          ),
                          Obx(() {
                            final error = controller.errorMessages[index];
                            return error != null
                                ? Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                error,
                                style: TextStyle(color: Colors.red, fontSize: 12),
                              ),
                            )
                                : SizedBox.shrink();
                          }),
                        ],
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
  }

  /// Modern Receive Button
  Widget _buildReceiveButton() {
    return ElevatedButton(
      onPressed: controller.showConfirmDialogToReceiveStock,
      style: ElevatedButton.styleFrom(
        elevation: 5,
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        backgroundColor: Colors.green,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check, color: Colors.white),
          SizedBox(width: 8),
          Text(
            "Receive Transfer",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
