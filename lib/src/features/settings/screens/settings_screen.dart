import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vimbika_pos_app/src/constants/app_routes.dart';
import 'package:vimbika_pos_app/src/widgets/app_widgets.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    AppWidgets appWidgets = AppWidgets();
    return Scaffold(
      appBar: AppBar(
        title: const Text('SETTINGS'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            appWidgets.buildSettingButton(
              context,
              title: 'Printer Settings',
              icon: Icons.print,
              onTap: () => Get.toNamed(AppRoutes.PRINTER_SETTINGS),
            ),
            const SizedBox(height: 20),
            appWidgets.buildSettingButton(
              context,
              title: 'Fiscalization Settings',
              icon: Icons.receipt_long,
              onTap: () => Get.toNamed(AppRoutes.DEFAULT_FISCAL_SETTINGS),
            ),
            const SizedBox(height: 20),
            appWidgets.buildSettingButton(
              context,
              title: 'Default Payment Method',
              icon: Icons.payment,
              onTap: () => Get.toNamed(AppRoutes.DEFAULT_PAYMENT_METHOD_SCREEN),
            ),
            const SizedBox(height: 20),
            appWidgets.buildSettingButton(
              context,
              title: 'Default Currency',
              icon: Icons.monetization_on,
              onTap: () => Get.toNamed(AppRoutes.DEFAULT_CURRENCY_SCREEN),
            ),
          ],
        ),
      ),
    );
  }


}
