import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:vimbika_pos_app/src/features/sale/widget/custom_dropdown_widget.dart';
import 'package:vimbika_pos_app/src/features/shift/controller/submit_cash_controller.dart';
import 'package:vimbika_pos_app/src/shared/controller/inactivity_controller.dart';
import 'package:vimbika_pos_app/src/shared/models/currency_model.dart';


class SubmitCashScreen extends StatelessWidget {
  final SubmitCashController controller = Get.put(SubmitCashController());
  final InactivityController inactivityController = Get.put(InactivityController());
  var scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    GlobalKey<FormState> formKey = GlobalKey<FormState>();
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: inactivityController.resetInactivityTimer,
      onPanDown: (_) => inactivityController.resetInactivityTimer(),
      child: Scaffold(
        key: scaffoldKey,
        appBar: AppBar(
          title: Text('SUBMIT CASH'),
        ),

          body: Form(
            key: formKey,
            child: SingleChildScrollView(  // Wrap the Column in SingleChildScrollView
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 10),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Submit available cash for this shift',
                        style: TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  Obx(() {
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),  // Prevent internal scrolling
                      itemCount: controller.currencyAmountList.length,
                      itemBuilder: (context, index) {
                        final currencyAmount = controller.currencyAmountList[index];
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: CustomDropdownWidget<CurrencyModel>(
                                  items: controller.currencyList,
                                  selectedItem: currencyAmount.currency,
                                  hint: "Select Currency",
                                  isSelected: controller.isCurrencySelected,
                                  selectedValue: currencyAmount.selectedCurrency, // Use the Rx<CurrencyModel?> here
                                  icon: Icons.currency_exchange,
                                  onChanged: (CurrencyModel? newValue) {
                                    // currencyAmount.selectedCurrency.value = newValue;
                                    currencyAmount.currency = newValue!;
                                  },
                                  validator: (value) {
                                    if (value == null) {
                                      return 'Please select a currency';
                                    }
                                    return null;
                                  },
                                  itemBuilder: (CurrencyModel value) => Text(value.name!),
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: <TextInputFormatter>[
                                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                  ],
                                  decoration: const InputDecoration(
                                    prefixIcon: Icon(Icons.money),
                                    labelText: "Amount",
                                    hintText: "Amount",
                                  ),
                                  onChanged: (value) {
                                    controller.updateAmount(index, value);
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter an amount';
                                    }
                                    double enteredAmount;
                                    try {
                                      enteredAmount = double.parse(value);
                                    } catch (e) {
                                      return 'Please enter a valid amount';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.remove_circle),
                                onPressed: () {
                                  controller.removeCurrencyAmount(index);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: () {
                        controller.addCurrencyAmount(controller.currencyList.first);
                      },
                      child: Text('ADD CURRENCY'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          controller.showConfirmDialog();
                        } else {
                          print("validation error");
                        }
                      },
                      child: Text('SUBMIT CASH'),
                    ),
                  ),
                  SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),

    );
  }


}
