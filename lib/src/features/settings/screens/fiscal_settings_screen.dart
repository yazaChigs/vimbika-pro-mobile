import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vimbika_pos_app/src/features/settings/controller/settings_controller.dart';

class FiscalSettingsScreen extends StatelessWidget {
  final SettingsController controller = Get.put(SettingsController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fiscal Settings'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            // Text(
            //   'Fiscal Settings',
            //   style: Theme.of(context).textTheme.displayLarge,
            // ),
            // SizedBox(height: 16),

            // Checkbox
            Obx(() => CheckboxListTile(
              title: Text(
                'Always ask for fiscalisation',
                style: TextStyle(fontSize: 16),
              ),
              value: controller.isFiscalisationEnabled.value,
              onChanged: (value) {
                controller.toggleDefaultFiscalSetting();
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            )),

            Spacer(),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Action to save settings
                  controller.saveFiscalSetting();

                },
                child: Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
