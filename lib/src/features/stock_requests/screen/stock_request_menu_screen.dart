
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vimbika_pos_app/src/constants/app_routes.dart';
import 'package:vimbika_pos_app/src/widgets/app_widgets.dart';

class StockRequestMenuScreen extends StatelessWidget {
  const StockRequestMenuScreen({super.key});

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
              onTap: () => Get.toNamed(AppRoutes.NEW_STOCK_REQUEST),
            ),
            const SizedBox(height: 20),
            appWidgets.buildSettingButton(
              context,
              title: 'Receive Transfer',
              icon: Icons.handshake,
              onTap: () => Get.toNamed(AppRoutes.DEFAULT_FISCAL_SETTINGS),
            ),
            const SizedBox(height: 20),
            appWidgets.buildSettingButton(
              context,
              title: 'Transfer History',
              icon: Icons.access_time_outlined,
              onTap: () => Get.toNamed(AppRoutes.DEFAULT_PAYMENT_METHOD_SCREEN),
            ),
          ],
        ),
      ),
    );
  }
}
