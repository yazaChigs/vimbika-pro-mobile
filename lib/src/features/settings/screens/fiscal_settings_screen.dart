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
            // Checkbox
            Container(
              decoration: BoxDecoration(
                color: context.theme.colorScheme.primaryContainer,
                border: Border.all(color: context.theme.colorScheme.primary),
              ),
              child: Obx(() => CheckboxListTile(
                title: Text(
                  'Enable tax',
                  style: TextStyle(fontSize: 16),
                ),
                value: controller.isFiscalisationEnabled.value,
                onChanged: (value) {
                  controller.toggleDefaultFiscalSetting();
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              )),
            ),
        
            Spacer(),
        
            // Save Button
            SizedBox(
              width: double.infinity,
              child: Obx(() => ElevatedButton(
                onPressed: controller.isSaving.value 
                  ? null 
                  : () {
                      // Action to save settings
                      controller.debouncedSaveFiscalSetting();
                    },
                child: Text(
                  controller.isSaving.value ? 'SAVING...' : 'Save'
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: controller.isSaving.value
                      ? Colors.grey
                      : null,
                ),
              )),
            ),
          ],
        ),
      ),
    );
  }
}
