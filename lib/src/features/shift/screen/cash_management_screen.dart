import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:vimbika_pos_app/src/features/sale/widget/custom_dropdown_widget.dart';
import 'package:vimbika_pos_app/src/features/shift/controller/cash_management_controller.dart';
import 'package:vimbika_pos_app/src/shared/controller/inactivity_controller.dart';
import 'package:vimbika_pos_app/src/shared/models/currency_model.dart';
import 'package:pdf/widgets.dart' as pw;


class CashManagementScreen extends StatelessWidget {
  final CashManagementController controller = Get.put(CashManagementController());
  final InactivityController inactivityController = Get.put(InactivityController());

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: inactivityController.resetInactivityTimer,
      onPanDown: (_) => inactivityController.resetInactivityTimer(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('CASH MANAGEMENT'),
        ),
        body: SingleChildScrollView(
          child: Form(
            key: controller.formKeyCashForm,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (controller.formKeyCashForm.currentState!.validate()) {
                              controller.formKeyCashForm.currentState!.save();
                              controller.payInPayOut("CASH_IN");
                            }
                          },
                          child: Text('CASH IN'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (controller.formKeyCashForm.currentState!.validate()) {
                              controller.formKeyCashForm.currentState!.save();

                                controller.payInPayOut("CASH_OUT");
                                // if (controller.shouldViewReceipt.value) {
                                //   controller.viewOrPrintReceipt("CASH_OUT");
                                // }

                            }
                          },
                          child: Text('CASH OUT'),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
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
                      itemBuilder: (CurrencyModel value) => Text(value.name!),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: controller.amountTextEditingController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.money),
                      labelText: "Amount",
                      hintText: "Amount",
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an amount';
                      }
                      try {
                        double.parse(value);
                      } catch (e) {
                        return 'Please enter a valid amount';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      controller.amount.value = double.parse(value!);
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: "Comments",
                      hintText: "Enter your comments",
                      border: OutlineInputBorder(),
                    ),
                    onSaved: (value) {
                      controller.comments.value = value ?? "";
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Obx(() => CheckboxListTile(
                    title: Text("Print Receipt"),
                    value: controller.shouldViewReceipt.value,
                    onChanged: (value) {
                      controller.shouldViewReceipt.value = value!;
                    },
                  )),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


}
