import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vimbika_pos_app/src/features/settings/controller/settings_controller.dart';
import 'package:vimbika_pos_app/src/shared/models/currency_model.dart';


class DefaultCurrencyScreen extends StatelessWidget {
  final SettingsController controller = Get.put(SettingsController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Default Currency'),
      ),
      body: Obx(() {
        if (controller.currencyList.isEmpty) {
          return const Center(child: Text('No currencies available.'));
        }

        return ListView.builder(
          itemCount: controller.currencyList.length,
          itemBuilder: (context, index) {
            CurrencyModel currency = controller.currencyList[index];
            return ListTile(
              title: Text('${currency.name}'),
              subtitle: Text('Rate: ${currency.rate}'),
              trailing: Checkbox(
                value: controller.defaultCurrency.value?.id == currency.id,
                onChanged: (isSelected) {
                  if (isSelected == true) {
                    controller.setDefaultCurrency(currency);
                  }
                },
              ),
              onTap: () {
                controller.setDefaultCurrency(currency);
              },
            );
          },
        );
      }),
    );
  }
}
