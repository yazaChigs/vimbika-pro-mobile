import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vimbika_pos_app/src/features/customers/controller/customer_controller.dart';
import 'package:vimbika_pos_app/src/shared/controller/inactivity_controller.dart';

import '../../../shared/models/currency_model.dart';
import '../../../shared/models/payment_type_model.dart';
import '../../sale/widget/custom_dropdown_widget.dart';

class PayAccountFormScreen extends StatelessWidget {
  final CustomerController controller = Get.put(CustomerController());
  final InactivityController inactivityController = Get.find();


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: inactivityController.resetInactivityTimer,
      onPanDown: (_) => inactivityController.resetInactivityTimer(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Pay Account for ${controller.selectedCustomer.value!.name}'),
        ),
        body: SingleChildScrollView(
          child: Form(
            key: controller.formKeyForm,
            child: Column(
              children: [
                Row(
                  children: [

                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Obx(() {
                          return CustomDropdownWidget<CurrencyModel>(
                            items: controller.currencyList,
                            selectedItem: controller.selectedCurrency.value,
                            hint: "Select Currency",
                            isSelected: controller.isCurrencySelected,
                            selectedValue: controller.selectedCurrency,
                            icon: Icons.currency_exchange,
                            onChanged: (CurrencyModel? newValue) {
                              controller.onCurrencyChange(newValue!);
                            },
                            validator: (value) {
                              if (controller.isCurrencySelected.isFalse) {
                                return 'Please select a currency';
                              }
                              return null;
                            },
                            itemBuilder: (CurrencyModel value) => Text(value.name! + " (" + value.rate!.toString() + ")"),
                          );
                        }),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                            controller: controller.payAccAmtEditingController,
                            decoration: const InputDecoration(
                                prefixIcon: Icon(
                                    Icons.person_outline_outlined),
                                labelText: "Amount",
                                hintText: "Amount"),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'amount is required';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              controller.payAccAMt.value = double.parse(value);
                            }
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (controller.selectedCurrency!=null && controller.payAccAmtEditingController.text.isNotEmpty) {
                          // controller.formKeyForm.currentState!.save(); // Save the form fields
                          controller.savePayment();
                        }
                      },
                      child: Text('SAVE'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        textStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
