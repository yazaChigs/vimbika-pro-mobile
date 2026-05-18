import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vimbika_pos_app/src/constants/app_routes.dart';
import 'package:vimbika_pos_app/src/widgets/app_widgets.dart';

import '../controller/settings_controller.dart';

import '../../../services/sync_service.dart';

class SettingsScreen extends StatelessWidget {
  final SettingsController controller = Get.put(SettingsController());
  // final SyncService syncService = Get.find<SyncService>();
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
            const SizedBox(height: 20),
            appWidgets.buildSettingButton(
              context,
              title: 'Backed Up Files',
              icon: Icons.backup,
              onTap: () async {
                bool isAuthenticated = await SyncService().showAuthenticationDialog(context);
                if (isAuthenticated) {
                  Get.toNamed(AppRoutes.BACKED_UP_SALES);
                }
              },
            ),
            const SizedBox(height: 20),
            Obx(() => CheckboxListTile(
              title: Text(
                'Use NFC',
                style: TextStyle(fontSize: 16),
              ),
              value: controller.useNfc.value,
              onChanged: (value) {
                controller.toggleUseNfcSetting();
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            )),
            const SizedBox(height: 10),
            Obx(() => CheckboxListTile(
              title: Text(
                'Dark Mode',
                style: TextStyle(fontSize: 16),
              ),
              value: controller.isDarkModeEnabled.value,
              onChanged: (value) {
                controller.toggleDarkMode();
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            )),
            const SizedBox(height: 20),
            Obx(() => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Number of Receipts', style: TextStyle(fontSize: 16)),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove_circle_outline),
                      onPressed: () {
                        if (controller.numberOfReceipts.value > 1) {
                          controller.setNumberOfReceipts(controller.numberOfReceipts.value - 1);
                        }
                      },
                    ),
                    Text(controller.numberOfReceipts.value.toString(), style: TextStyle(fontSize: 16)),
                    IconButton(
                      icon: Icon(Icons.add_circle_outline),
                      onPressed: () {
                        controller.setNumberOfReceipts(controller.numberOfReceipts.value + 1);
                      },
                    ),
                  ],
                ),
              ],
            )),
            Spacer(),
          ],
        ),
      ),
    );
  }


}
