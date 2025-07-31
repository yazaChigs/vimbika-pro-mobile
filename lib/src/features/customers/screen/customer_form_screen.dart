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
                                prefixIcon: Icon(Icons.person_outline_outlined),
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
                            }),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                            controller: controller.accNoEditingController,
                            decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.credit_card),
                                labelText: "Account Number",
                                hintText: "Account Number"),
                            onSaved: (value) {
                              controller.accountNumber.value = value!;
                            }),
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
                            controller:
                                controller.mobileNumberEditingController,
                            decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.phone),
                                labelText: "Contact Phone",
                                hintText: "Contact Phone"),
                            onSaved: (value) {
                              controller.mobilePhone.value = value!;
                            }),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                            controller: controller.emailEditingController,
                            decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.email),
                                labelText: "Email",
                                hintText: "Email"),
                            onSaved: (value) {
                              controller.email.value = value!;
                            }),
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
                                prefixIcon:
                                    Icon(Icons.accessibility_new_outlined),
                                labelText: "TIN",
                                hintText: "TIN"),
                            onSaved: (value) {
                              controller.tin.value = value!;
                            }),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                            controller: controller.vatEditingController,
                            decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.add_business),
                                labelText: "VAT",
                                hintText: "VAT"),
                            onSaved: (value) {
                              controller.vat.value = value!;
                            }),
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
                          prefixIcon: Icon(Icons.location_on_sharp),
                          labelText: "Address",
                          hintText: "Address"),
                      onSaved: (value) {
                        controller.address.value = value!;
                      }),
                ),
                const SizedBox(height: 20),

                // NFC Card Association Section
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NFC Card Association',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => controller.addCardToCustomer(),
                                icon: Icon(Icons.nfc),
                                label: Text('Add Card To Customer'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Obx(() => controller.nfcCardId.value.isNotEmpty
                            ? Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: Colors.green.withOpacity(0.3)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.check_circle,
                                            color: Colors.green, size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          'Card Added Successfully',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Card ID: ${controller.nfcCardId.value}',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    Text(
                                      'Card Type: ${controller.nfcCardType.value}',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    Text(
                                      'Account Number: ${controller.accNoEditingController.text}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : SizedBox.shrink()),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    maxLines:
                        2, // This sets the TextFormField as a text area with two rows.
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
                          controller.formKeyForm.currentState!
                              .save(); // Save the form fields
                          if (controller.editCustomer.value)
                            controller.updateCustomerInfo();
                          else
                            controller.showConfirmDialogToSaveCustomer();
                        }
                      },
                      child: Text('SAVE CUSTOMER'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pinkAccent,
                          textStyle: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
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
