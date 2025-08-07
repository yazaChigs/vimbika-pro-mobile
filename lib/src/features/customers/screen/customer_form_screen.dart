import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vimbika_pos_app/src/features/customers/controller/customer_controller.dart';
import 'package:vimbika_pos_app/src/shared/controller/inactivity_controller.dart';

class CustomerFormScreen extends StatelessWidget {
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
          title: Text('CUSTOMER INFO'),
        ),
        body: SingleChildScrollView(
          child: Form(
            key: controller.formKeyForm,
            child: Column(
              children: [
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                            controller: controller.nameEditingController,
                            decoration: const InputDecoration(
                                prefixIcon: Icon(
                                    Icons.person_outline_outlined),
                                labelText: "Name",
                                hintText: "Name"),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Name is required';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              controller.name.value = value!;
                            }
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                            controller: controller.accNoEditingController,
                            decoration: const InputDecoration(
                                prefixIcon: Icon(
                                    Icons.credit_card),
                                labelText: "Account Number",
                                hintText: "Account Number"),
                            onSaved: (value) {
                              controller.accountNumber.value = value!;
                            }
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                            controller: controller.mobileNumberEditingController,
                            decoration: const InputDecoration(
                                prefixIcon: Icon(
                                    Icons.phone),
                                labelText: "Contact Phone",
                                hintText: "Contact Phone"),

                            onSaved: (value) {
                              controller.mobilePhone.value = value!;
                            }
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                            controller: controller.emailEditingController,
                            decoration: const InputDecoration(
                                prefixIcon: Icon(
                                    Icons.email),
                                labelText: "Email",
                                hintText: "Email"),

                            onSaved: (value) {
                              controller.email.value = value!;
                            }
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                            controller: controller.tinEditingController,
                            decoration: const InputDecoration(
                                prefixIcon: Icon(
                                    Icons.accessibility_new_outlined),
                                labelText: "TIN",
                                hintText: "TIN"),

                            onSaved: (value) {
                              controller.tin.value = value!;
                            }
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                            controller: controller.vatEditingController,
                            decoration: const InputDecoration(
                                prefixIcon: Icon(
                                    Icons.add_business),
                                labelText: "VAT",
                                hintText: "VAT"),

                            onSaved: (value) {
                              controller.vat.value = value!;
                            }
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                      controller: controller.addressEditingController,
                      decoration: const InputDecoration(
                          prefixIcon: Icon(
                              Icons.location_on_sharp),
                          labelText: "Address",
                          hintText: "Address"),

                      onSaved: (value) {
                        controller.address.value = value!;
                      }
                  ),
                ),
                const SizedBox(height: 20),


                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    maxLines: 2,  // This sets the TextFormField as a text area with two rows.
                    decoration: const InputDecoration(
                      labelText: "Description",
                      hintText: "Enter description",
                      border: OutlineInputBorder(),
                    ),
                    onSaved: (value) {
                      controller.description.value = value ?? "";
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (controller.formKeyForm.currentState!.validate()) {
                          controller.formKeyForm.currentState!.save(); // Save the form fields
                          if(controller.editCustomer.value)
                            controller.updateCustomerInfo();
                          else
                            controller.saveCustomerInfo();
                        }
                      },
                      child: Text('SAVE CUSTOMER'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                        textStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
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
