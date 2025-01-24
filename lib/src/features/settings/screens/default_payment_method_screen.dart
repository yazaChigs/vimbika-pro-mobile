import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vimbika_pos_app/src/features/settings/controller/settings_controller.dart';
import 'package:vimbika_pos_app/src/shared/models/currency_model.dart';
import 'package:vimbika_pos_app/src/shared/models/payment_type_model.dart';


class DefaultPaymentMethodScreen extends StatelessWidget {
  final SettingsController controller = Get.put(SettingsController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Default Payment Method'),
      ),
      body: Obx(() {
        if (controller.currencyList.isEmpty) {
          return const Center(child: Text('No payment methods available.'));
        }

        return ListView.builder(
          itemCount: controller.paymentTypesList.length,
          itemBuilder: (context, index) {
            PaymentTypeModel paymentMethod = controller.paymentTypesList[index];
            return ListTile(
              title: Text('${paymentMethod.name}'),
              subtitle: Text('${paymentMethod.currency!.name}'),
              trailing: Checkbox(
                value: controller.defaultPaymentMethod.value?.id == paymentMethod.id,
                onChanged: (isSelected) {
                  if (isSelected == true) {
                    controller.setDefaultPaymentMethod(paymentMethod);
                  }
                },
              ),
              onTap: () {
                controller.setDefaultPaymentMethod(paymentMethod);
              },
            );
          },
        );
      }),
    );
  }
}
