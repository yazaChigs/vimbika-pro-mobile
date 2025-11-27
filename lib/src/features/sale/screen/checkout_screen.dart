import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:search_choices/search_choices.dart';
import 'package:vimbika_pos_app/src/constants/app_routes.dart';
import 'package:vimbika_pos_app/src/features/authentication/model/user_model.dart';
import 'package:vimbika_pos_app/src/features/sale/controller/cart_controller.dart';
import 'package:vimbika_pos_app/src/features/sale/widget/custom_dropdown_widget.dart';
import 'package:vimbika_pos_app/src/shared/controller/inactivity_controller.dart';
import 'package:vimbika_pos_app/src/shared/models/currency_model.dart';
import 'package:vimbika_pos_app/src/shared/models/customer_model.dart';
import 'package:vimbika_pos_app/src/shared/models/payment_type_model.dart';

class CheckoutScreen extends StatelessWidget {
  final CartController cartController = Get.put(CartController());
  final InactivityController inactivityController = Get.find();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: inactivityController.resetInactivityTimer,
      onPanDown: (_) => inactivityController.resetInactivityTimer(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white, // Same as your app theme
          elevation: 0,
          title: Text('Checkout'),
        ),
        body: Form(
          key: cartController.formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Colors.grey,
                          width: 1.5), // Border color and width
                      borderRadius: BorderRadius.circular(8), // Rounded corners
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    // height: 60,
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            // Get.toNamed(AppRoutes.CUSTOMER_FORM);
                            getCustomerForm();
                          },
                          child: Padding(
                            padding:
                                const EdgeInsets.only(left: 8.0, right: 20),
                            child: Icon(
                              Icons
                                  .person_add, // Change this to the icon you want
                              color: Colors.indigo, // Set icon color
                            ),
                          ),
                        ),
                        Expanded(
                          child: Obx(() {
                            return SearchChoices.single(
                              padding: 0,
                              items: cartController.allCustomers
                                  .map((CustomerModel customer) {
                                return DropdownMenuItem<CustomerModel>(
                                  value: customer,
                                  child: Text(customer.name ?? ''),
                                );
                              }).toList(),
                              value: cartController.selectedCustomer.value,
                              // onTap: cartController.reGetCustomers(),
                              // initial selected value if needed
                              hint: "Select Customer",
                              searchHint:
                                  "Type customer name, phone, ID, customer ID, or account number...",
                              searchFn: (String searchTerm,
                                  List<DropdownMenuItem> items) {
                                // Enhanced search: search by name, phone, ID, customer ID, or account number
                                List<int> matches = [];
                                for (int i = 0; i < items.length; i++) {
                                  CustomerModel customer =
                                      items[i].value as CustomerModel;
                                  bool nameMatch = customer.name != null &&
                                      customer.name!
                                          .toLowerCase()
                                          .contains(searchTerm.toLowerCase());
                                  bool phoneMatch = customer.mobilePhone !=
                                          null &&
                                      customer.mobilePhone!
                                          .toLowerCase()
                                          .contains(searchTerm.toLowerCase());
                                  bool idMatch = customer.id != null &&
                                      customer.id!
                                          .toLowerCase()
                                          .contains(searchTerm.toLowerCase());
                                  bool customerIdMatch = customer.customerId !=
                                          null &&
                                      customer.customerId!
                                          .toLowerCase()
                                          .contains(searchTerm.toLowerCase());
                                  bool accountNumberMatch = customer
                                              .accountNumber !=
                                          null &&
                                      customer.accountNumber!
                                          .toLowerCase()
                                          .contains(searchTerm.toLowerCase());
                                  if (nameMatch ||
                                      phoneMatch ||
                                      idMatch ||
                                      customerIdMatch ||
                                      accountNumberMatch) {
                                    matches.add(i);
                                  }
                                }
                                return matches;
                              },
                              validator: (value) {
                                if (cartController.isCustomerSelected.isFalse) {
                                  return 'Please select a customer';
                                }
                                return null;
                              },
                              onChanged: (CustomerModel selected) {
                                cartController.onCustomerChange(selected);
                              },
                              underline: SizedBox.shrink(),
                              style: TextStyle(
                                  fontSize: 15, color: Colors.black87),
                              isExpanded: true,
                            );
                          }),
                        ),
                        GestureDetector(
                          onTap: () {
                            // Get.toNamed(AppRoutes.CUSTOMER_FORM);
                            cartController.reGetCustomers();
                          },
                          child: Padding(
                            padding:
                                const EdgeInsets.only(left: 8.0, right: 20),
                            child: Icon(
                              Icons.refresh, // Change this to the icon you want
                              color: Colors.deepOrange, // Set icon color
                            ),
                          ),
                        ),
                        Obx(() => GestureDetector(
                              onTap: () {
                                cartController.selectCustomerByNfc();
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets.only(left: 8.0, right: 20),
                                child: cartController.isNfcReading.value
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.blue),
                                        ),
                                      )
                                    : Icon(
                                        Icons.nfc,
                                        color: Colors.blue,
                                      ),
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Obx(() {
                    return CustomDropdownWidget<UserModel>(
                      items: cartController.userList,
                      selectedItem: cartController.user.value,
                      hint: "Select Agent",
                      isSelected: cartController.isUserSelected,
                      selectedValue: cartController.user,
                      icon: Icons.person,
                      onChanged: (UserModel? newValue) {
                        //cartController.onCurrencyChange(newValue!);
                        cartController.user.value = newValue;
                      },
                      validator: (value) {
                        if (cartController.isUserSelected.isFalse) {
                          return 'Please Select Agent';
                        }
                        return null;
                      },
                      itemBuilder: (UserModel value) =>
                          Text(value.firstName! + " " + value.lastName!),
                    );
                  }),
                ),
                const SizedBox(height: 20),

                /*   Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: Obx(() {
                                return CustomDropdownWidget<CurrencyModel>(
                                  items: cartController.currencyList,
                                  selectedItem: cartController.selectedCurrency.value,
                                  hint: "Select Currency",
                                  isSelected: cartController.isCurrencySelected,
                                  selectedValue: cartController.selectedCurrency,
                                  icon: Icons.currency_exchange,
                                  onChanged: (CurrencyModel? newValue) {
                                    cartController.onCurrencyChange(newValue!);
                                  },
                                  validator: (value) {
                                    if (cartController.isCurrencySelected.isFalse) {
                                      return 'Please select a currency';
                                    }
                                    return null;
                                  },
                                  itemBuilder: (CurrencyModel value) => Text(value.name! + " (" + value.rate!.toString() + ")"),
                                );
                              }),
                            ),
                            Expanded(
                              child: Obx(() {
                                return CustomDropdownWidget<PaymentTypeModel>(
                                  items: cartController.filteredPaymentTypesList,
                                  selectedItem: cartController.selectedPaymentType.value,
                                  hint: "Select Payment Type",
                                  isSelected: cartController.isPaymentTypeSelected,
                                  selectedValue: cartController.selectedPaymentType,
                                  icon: Icons.payments,
                                  onChanged: (PaymentTypeModel? newValue) {
                                    cartController.onChangePaymentType(newValue!);
                                  },
                                  validator: (value) {
                                    if (cartController.isPaymentTypeSelected.isFalse) {
                                      return 'Please select a payment type';
                                    }
                                    return null;
                                  },
                                  itemBuilder: (PaymentTypeModel value) =>
                                      Text(value.name!),
                                );
                              }),
                            ),
                            Expanded(
                              child: TextFormField(
                                controller:
                                cartController.amountPaidTextEditingController,
                                keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true),
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d+\.?\d{0,2}')),
                                ],
                                decoration: const InputDecoration(
                                    prefixIcon: Icon(Icons.money),
                                    labelText: "Amount",
                                    hintText: "Amount"),
                                onChanged: (String val) {
                                  if (val.isNotEmpty) {
                                    cartController.amountPaidChange(val);
                                  }
                                },
                                validator: (value) {
                                  if (cartController.totalAmountPaid.value == 0.0) {
                                    return 'Please enter an amount';
                                  }
                                  double enteredAmount;
                                  try {
                                    enteredAmount = cartController.totalAmountPaid.value;
                                  } catch (e) {
                                    return 'Please enter a valid amount';
                                  }

                                  if (enteredAmount <
                                      double.parse(cartController.totalCostInSelectedCurrency.value.toStringAsFixed(2))) {
                                    return 'Amount paid cannot be less than the total amount';
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  cartController.amountPaid.value = cartController.totalAmountPaid.value;
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add,size: 50,color: Colors.blue,),
                              onPressed: () {
                                cartController.addPaymentType();
                                FocusScope.of(context).unfocus();
                                new TextEditingController().clear();
                              },
                            ),
                            // Text('Volume : '),
                            ],
                      ),
                    ),

                SizedBox(height: 200,
                child:
                Expanded(
                  child: Obx(() {
                    return ListView.builder(
                      itemCount: cartController.paymentTypes.length,
                      itemBuilder: (context, index) {
                        final total = cartController.paymentTypes[index];
                        return Card(
                          child: ListTile(
                            tileColor: Colors.lightBlueAccent[100],
                            title: Text(
                              total.paymentType!.name!,
                              style: TextStyle(fontSize: 12),
                            ),
                            subtitle: Text(
                              total.currency!.name!,
                              style: TextStyle(fontSize: 12),
                            ),
                            trailing:
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text( total.currency!.symbol! + " " + total.amount!.toStringAsFixed(2),
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(
                                  width: 100,
                                  // Adjust the width to fit the text
                                  height: 30,
                                  // Adjust the height to make the button smaller
                                  child: IconButton(
                                    icon: const Icon(Icons.delete,size: 35,color: Colors.redAccent,),
                                    onPressed: () {
                                      cartController.removePaymentMethod(index);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.all(5.0),
                                      textStyle: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            shape: RoundedRectangleBorder(
                              side: BorderSide(color: Colors.grey, width: 0.5),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),
                  ),

*/
/*   Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: Obx(() {
                                return CustomDropdownWidget<CurrencyModel>(
                                  items: cartController.currencyList,
                                  selectedItem: cartController.selectedCurrency.value,
                                  hint: "Select Currency",
                                  isSelected: cartController.isCurrencySelected,
                                  selectedValue: cartController.selectedCurrency,
                                  icon: Icons.currency_exchange,
                                  onChanged: (CurrencyModel? newValue) {
                                    cartController.onCurrencyChange(newValue!);
                                  },
                                  validator: (value) {
                                    if (cartController.isCurrencySelected.isFalse) {
                                      return 'Please select a currency';
                                    }
                                    return null;
                                  },
                                  itemBuilder: (CurrencyModel value) => Text(value.name! + " (" + value.rate!.toString() + ")"),
                                );
                              }),
                            ),
                            Expanded(
                              child: Obx(() {
                                return CustomDropdownWidget<PaymentTypeModel>(
                                  items: cartController.filteredPaymentTypesList,
                                  selectedItem: cartController.selectedPaymentType.value,
                                  hint: "Select Payment Type",
                                  isSelected: cartController.isPaymentTypeSelected,
                                  selectedValue: cartController.selectedPaymentType,
                                  icon: Icons.payments,
                                  onChanged: (PaymentTypeModel? newValue) {
                                    cartController.onChangePaymentType(newValue!);
                                  },
                                  validator: (value) {
                                    if (cartController.isPaymentTypeSelected.isFalse) {
                                      return 'Please select a payment type';
                                    }
                                    return null;
                                  },
                                  itemBuilder: (PaymentTypeModel value) =>
                                      Text(value.name!),
                                );
                              }),
                            ),
                            Expanded(
                              child: TextFormField(
                                controller:
                                cartController.amountPaidTextEditingController,
                                keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true),
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d+\.?\d{0,2}')),
                                ],
                                decoration: const InputDecoration(
                                    prefixIcon: Icon(Icons.money),
                                    labelText: "Amount",
                                    hintText: "Amount"),
                                onChanged: (String val) {
                                  if (val.isNotEmpty) {
                                    cartController.amountPaidChange(val);
                                  }
                                },
                                validator: (value) {
                                  if (cartController.totalAmountPaid.value == 0.0) {
                                    return 'Please enter an amount';
                                  }
                                  double enteredAmount;
                                  try {
                                    enteredAmount = cartController.totalAmountPaid.value;
                                  } catch (e) {
                                    return 'Please enter a valid amount';
                                  }

                                  if (enteredAmount <
                                      double.parse(cartController.totalCostInSelectedCurrency.value.toStringAsFixed(2))) {
                                    return 'Amount paid cannot be less than the total amount';
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  cartController.amountPaid.value = cartController.totalAmountPaid.value;
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add,size: 50,color: Colors.blue,),
                              onPressed: () {
                                cartController.addPaymentType();
                                FocusScope.of(context).unfocus();
                                new TextEditingController().clear();
                              },
                            ),
                            // Text('Volume : '),
                            ],
                      ),
                    ),

                SizedBox(height: 200,
                child:
                Expanded(
                  child: Obx(() {
                    return ListView.builder(
                      itemCount: cartController.paymentTypes.length,
                      itemBuilder: (context, index) {
                        final total = cartController.paymentTypes[index];
                        return Card(
                          child: ListTile(
                            tileColor: Colors.lightBlueAccent[100],
                            title: Text(
                              total.paymentType!.name!,
                              style: TextStyle(fontSize: 12),
                            ),
                            subtitle: Text(
                              total.currency!.name!,
                              style: TextStyle(fontSize: 12),
                            ),
                            trailing:
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text( total.currency!.symbol! + " " + total.amount!.toStringAsFixed(2),
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(
                                  width: 100,
                                  // Adjust the width to fit the text
                                  height: 30,
                                  // Adjust the height to make the button smaller
                                  child: IconButton(
                                    icon: const Icon(Icons.delete,size: 35,color: Colors.redAccent,),
                                    onPressed: () {
                                      cartController.removePaymentMethod(index);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.all(5.0),
                                      textStyle: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            shape: RoundedRectangleBorder(
                              side: BorderSide(color: Colors.grey, width: 0.5),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),
                  ),

*/

                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Obx(() {
                    return CustomDropdownWidget<CurrencyModel>(
                      items: cartController.currencyList,
                      selectedItem: cartController.selectedCurrency.value,
                      hint: "Select Currency",
                      isSelected: cartController.isCurrencySelected,
                      selectedValue: cartController.selectedCurrency,
                      icon: Icons.currency_exchange,
                      onChanged: (CurrencyModel? newValue) {
                        cartController.onCurrencyChange(newValue!);
                      },
                      validator: (value) {
                        if (cartController.isCurrencySelected.isFalse) {
                          return 'Please select a currency';
                        }
                        return null;
                      },
                      itemBuilder: (CurrencyModel value) => Text(
                          value.name! + " (" + value.rate!.toString() + ")"),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Obx(() {
                    return CustomDropdownWidget<PaymentTypeModel>(
                      items: cartController.filteredPaymentTypesList,
                      selectedItem: cartController.selectedPaymentType.value,
                      hint: "Select Payment Type",
                      isSelected: cartController.isPaymentTypeSelected,
                      selectedValue: cartController.selectedPaymentType,
                      icon: Icons.payments,
                      onChanged: (PaymentTypeModel? newValue) {
                        cartController.onChangePaymentType(newValue!, false);
                      },
                      validator: (value) {
                        if (cartController.isPaymentTypeSelected.isFalse) {
                          return 'Please select a payment type';
                        }
                        return null;
                      },
                      itemBuilder: (PaymentTypeModel value) =>
                          Text(value.name!),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                // Quick amount buttons for tablet view
                if (MediaQuery.of(context).size.width >= 950.0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildQuickAmountButton(
                            context,
                            '0.5',
                            0.5,
                            cartController,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildQuickAmountButton(
                            context,
                            '1',
                            1.0,
                            cartController,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildQuickAmountButton(
                            context,
                            '2',
                            2.0,
                            cartController,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildQuickAmountButton(
                            context,
                            '5',
                            5.0,
                            cartController,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildQuickAmountButton(
                            context,
                            '10',
                            10.0,
                            cartController,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildQuickAmountButton(
                            context,
                            '20',
                            20.0,
                            cartController,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildClearButton(
                            context,
                            cartController,
                          ),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: cartController.amountPaidTextEditingController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.money),
                        labelText: "Amount",
                        hintText: "Amount"),
                    onChanged: (String val) {
                      if (val.isNotEmpty) {
                        cartController.amountPaidChange(val);
                      }
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

                      if (enteredAmount <
                          double.parse(cartController
                              .totalCostInSelectedCurrency.value
                              .toStringAsFixed(2))) {
                        return 'Amount paid cannot be less than the total amount';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      cartController.amountPaid.value = double.parse(value!);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Obx(() {
                      //   return Text(
                      //     'Total Base Amount Paid : ${cartController.baseCurrency
                      //         .value!.symbol} ${cartController
                      //         .totalAmountPaid.toStringAsFixed(2)}',
                      //     style: const TextStyle(
                      //         fontSize: 20, fontWeight: FontWeight.bold),
                      //   );
                      // }),
                      Obx(() {
                        return Text(
                          'Base Amount : ${cartController.baseCurrency.value!.symbol} ${cartController.totalCostInBaseCurrency.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo),
                        );
                      }),
                      Obx(() {
                        return Text(
                          'Total : ${cartController.selectedCurrency.value!.symbol} ${cartController.totalCostInSelectedCurrency.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo),
                        );
                      }),
                      Obx(() {
                        return Text(
                          'Change : ${cartController.selectedCurrency.value!.symbol} ${cartController.change.value.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo),
                        );
                      }),
                      SizedBox(height: 5),
                      Obx(() => CheckboxListTile(
                            title: Text('Print Receipt'),
                            value: cartController.isPrintEnabled.value,
                            onChanged: (bool? value) {
                              cartController.isPrintEnabled.value =
                                  value ?? false;
                            },
                          )),
                      SizedBox(height: 5),
                      Obx(() {
                        if (cartController.fiscalizeReceipt.value) {
                          return CheckboxListTile(
                            title: Text('Fiscalize Receipt'),
                            value:
                                cartController.isFiscaliseReceiptEnabled.value,
                            onChanged: (bool? value) {
                              cartController.isFiscaliseReceiptEnabled.value =
                                  value ?? false;
                              cartController.zimraFiscalizeReceipt.value =
                                  value!;
                            },
                          );
                        } else {
                          return Container(); // Empty container when email is not valid
                        }
                      }),
                      SizedBox(height: 5),
                      Obx(() {
                        if (cartController.isCustomerEmailValid.value) {
                          return CheckboxListTile(
                            title: Text('Email Receipt'),
                            value: cartController.emailReceipt.value,
                            onChanged: (bool? value) {
                              cartController.emailReceipt.value =
                                  value ?? false;
                            },
                          );
                        } else {
                          return Container(); // Empty container when email is not valid
                        }
                      }),
                      SizedBox(height: 10),
                      Obx(() => ElevatedButton(
                        onPressed: cartController.isCharging.value 
                          ? null 
                          : () {
                              if (cartController.formKey.currentState!.validate()) {
                                cartController.formKey.currentState!
                                    .save(); // Save the form fields
                                cartController.showConfirmDialogChargeSale();
                              }
                            },
                        style: TextButton.styleFrom(
                          backgroundColor: cartController.isCharging.value
                              ? Colors.grey
                              : Colors.lightGreenAccent, // Set button color to red
                          foregroundColor:
                              Colors.black, // Set text color to red
                          textStyle: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold), // Set text size
                        ),
                        child: Text(
                          cartController.isCharging.value ? 'CHARGING...' : 'Charge'
                        ),
                      )),
                      SizedBox(height: 10),
                      ElevatedButton(
                        style: TextButton.styleFrom(
                          backgroundColor:
                              Colors.red[800], // Set button color to red
                          foregroundColor:
                              Colors.black, // Set text color to red
                          textStyle: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold), // Set text size
                        ),
                        onPressed: () {
                          cartController.cancelSale();
                        },
                        child: Text('Cancel Sale'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  getCustomerForm() {
    Get.dialog(
      AlertDialog(
        title: Text("Add New Customer"),
        content: SingleChildScrollView(
          child: Form(
            key: cartController
                .formKeyAddCustomer, // Add a GlobalKey to the form
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: cartController.nameController,
                  decoration: InputDecoration(labelText: "Name"),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 8.0),
                TextFormField(
                  controller: cartController.phoneController,
                  decoration: InputDecoration(labelText: "Phone"),
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: 8.0),
                TextFormField(
                  controller: cartController.emailController,
                  decoration: InputDecoration(labelText: "Email"),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 8.0),
                TextFormField(
                  controller: cartController.tinEditingController,
                  decoration: InputDecoration(labelText: "TIN"),
                ),
                SizedBox(height: 8.0),
                TextFormField(
                  controller: cartController.vatEditingController,
                  decoration: InputDecoration(labelText: "VAT"),
                ),
                SizedBox(height: 8.0),
                TextFormField(
                  controller: cartController.addressEditingController,
                  decoration: InputDecoration(labelText: "Address"),
                ),
                SizedBox(height: 8.0),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red, // Set text color to red
              textStyle:
                  TextStyle(fontSize: 16, color: Colors.white), // Set text size
            ),
            onPressed: () {
              // Close dialog without adding a customer
              Get.back();
            },
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              // Validate the form before adding a new customer
              if (cartController.formKeyAddCustomer.currentState!.validate()) {
                cartController.addNewCustomer();
                Get.back(); // Close the dialog after adding
              }
            },
            child: Text("Add"),
          ),
        ],
      ),
    );
  }

  // Helper widget for quick amount buttons
  Widget _buildQuickAmountButton(
    BuildContext context,
    String label,
    double amount,
    CartController cartController,
  ) {
    return ElevatedButton(
      onPressed: () {
        cartController.addQuickAmount(amount);
        FocusScope.of(context).unfocus();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 2,
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Helper widget for clear button
  Widget _buildClearButton(
    BuildContext context,
    CartController cartController,
  ) {
    return ElevatedButton(
      onPressed: () {
        cartController.clearAmountPaid();
        FocusScope.of(context).unfocus();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 2,
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.clear, size: 18),
          SizedBox(width: 4),
          Text(
            'Clear',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
