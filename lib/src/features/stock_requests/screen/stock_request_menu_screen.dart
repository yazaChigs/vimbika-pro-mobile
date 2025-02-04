
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vimbika_pos_app/src/constants/app_routes.dart';
import 'package:vimbika_pos_app/src/features/stock_requests/controller/stock_request_controller.dart';
import 'package:vimbika_pos_app/src/features/stock_requests/model/requisition_model.dart';
import 'package:vimbika_pos_app/src/widgets/app_widgets.dart';

class StockRequestMenuScreen extends StatelessWidget {
  final StockRequestController stockRequestController = Get.find();


  @override
  Widget build(BuildContext context) {
    AppWidgets appWidgets = AppWidgets();
    return Scaffold(
      appBar: AppBar(
        title: const Text('REQUISITION'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            appWidgets.buildSettingButton(
              context,
              title: 'New Stock Request',
              icon: Icons.fire_truck,
              onTap: () {

                stockRequestController.selectedReq.value = RequisitionModel();
                Get.toNamed(AppRoutes.NEW_STOCK_REQUEST);
              }
            ),
            const SizedBox(height: 20),
            appWidgets.buildSettingButton(
              context,
              title: 'Requisitions',
              icon: Icons.handshake,
              onTap: () {
                stockRequestController.getRequisitions();
                Get.toNamed(AppRoutes.REQUISITION_LIST_SCREEN);
              }
            ),
            const SizedBox(height: 20),
            appWidgets.buildSettingButton(
              context,
              title: 'Transfers',
              icon: Icons.bus_alert_sharp,
              onTap: () {
                stockRequestController.getTransferHistory();
                Get.toNamed(AppRoutes.TRANSFER_HISTORY_SCREEN);
              }
            ),
            const SizedBox(height: 20),
            appWidgets.buildSettingButton(
                context,
                title: 'History',
                icon: Icons.access_time,
                onTap: () {
                  stockRequestController.getReqHistory();
                  Get.toNamed(AppRoutes.REQUISITION_HISTORY_SCREEN);
                }
            ),
          ],
        ),
      ),
    );
  }
}
