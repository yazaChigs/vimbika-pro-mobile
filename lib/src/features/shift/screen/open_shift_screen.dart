import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:vimbika_pos_app/src/features/sale/widget/custom_dropdown_widget.dart';
import 'package:vimbika_pos_app/src/features/shift/controller/shift_controller.dart';
import 'package:vimbika_pos_app/src/shared/controller/inactivity_controller.dart';
import 'package:vimbika_pos_app/src/shared/models/currency_model.dart';
import 'package:vimbika_pos_app/src/widgets/nav_drawer_widget.dart';

class OpenShiftScreen extends StatelessWidget {
  var scaffoldKey = GlobalKey<ScaffoldState>();
  final InactivityController inactivityController = Get.put(InactivityController());
  final ShiftController shiftController = Get.put(ShiftController());

  @override
  Widget build(BuildContext context) {
    String fullName = "${shiftController.user.firstName} ${shiftController.user.lastName}";
    String initials = shiftController.user.firstName[0] + shiftController.user.lastName[0];
    GlobalKey<FormState> formKey = GlobalKey<FormState>();
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: inactivityController.resetInactivityTimer,
      onPanDown: (_) => inactivityController.resetInactivityTimer(),
      child: Scaffold(
        key: scaffoldKey,
        appBar: AppBar(
          backgroundColor: Colors.white, // Same as your app theme
          elevation: 1,
          title: Text('SHIFT'),
          leading: IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              scaffoldKey.currentState?.openDrawer();
            },
          ),
        ),
        drawer: NavDrawer(fullName: fullName, mobileNumber: shiftController.user.mobilePhone ?? "", nameInitials: initials),
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
                      'Specify the cash amount in your drawer at the start of the shift',
                      style: TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                Obx(() {
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),  // Prevent internal scrolling
                    itemCount: shiftController.currencyAmountList.length,
                    itemBuilder: (context, index) {
                      final currencyAmount = shiftController.currencyAmountList[index];
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: CustomDropdownWidget<CurrencyModel>(
                                items: shiftController.currencyList,
                                selectedItem: currencyAmount.currency,
                                hint: "Select Currency",
                                isSelected: shiftController.isCurrencySelected,
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
                                  shiftController.updateAmount(index, value);
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
                                shiftController.removeCurrencyAmount(index);
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
                      shiftController.addCurrencyAmount(shiftController.currencyList.first);
                    },
                    child: Text('ADD CURRENCY'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Obx(() => ElevatedButton(
                    onPressed: shiftController.isOpeningShift.value 
                      ? null 
                      : () {
                          if (formKey.currentState!.validate()) {
                            // Handle the logic to save or process multiple currency amounts
                            shiftController.debouncedOpenShift();
                          } else {
                            print("validation error");
                          }
                        },
                    child: Text(
                      shiftController.isOpeningShift.value ? 'OPENING...' : 'OPEN SHIFT'
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: shiftController.isOpeningShift.value
                          ? Colors.grey
                          : null,
                    ),
                  )),
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
