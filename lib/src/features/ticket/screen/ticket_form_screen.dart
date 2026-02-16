import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vimbika_pos_app/src/features/ticket/controller/ticket_controller.dart';
import 'package:vimbika_pos_app/src/shared/controller/inactivity_controller.dart';

class TicketFormScreen extends StatelessWidget {
  final TicketController controller = Get.put(TicketController());
  final InactivityController inactivityController = Get.find();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: inactivityController.resetInactivityTimer,
      onPanDown: (_) => inactivityController.resetInactivityTimer(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('NEW TICKET'),
        ),
        body: SingleChildScrollView(
          child: Form(
            key: controller.ticketFormKeyForm,
            child: Column(
              children: [
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                      controller: controller.ticketNameEditingController,
                      decoration: InputDecoration(
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: context.theme.colorScheme.primary),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: context.theme.colorScheme.primary,
                                width: 2.0),
                          ),
                          border: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: context.theme.colorScheme.primary)),
                          prefixIcon: Icon(Icons.receipt_long),
                          labelText: "Name",
                          hintText: "Name"),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ticket name is required';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        controller.ticketName.value = value!;
                      }),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    maxLines:
                        2, // This sets the TextFormField as a text area with two rows.
                    decoration: InputDecoration(
                      labelText: "Comments",
                      hintText: "Enter Comments",
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: context.theme.colorScheme.primary),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: context.theme.colorScheme.primary,
                            width: 2.0),
                      ),
                      border: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: context.theme.colorScheme.primary)),
                    ),
                    onSaved: (value) {
                      controller.ticketComment.value = value ?? "";
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: Obx(() => ElevatedButton(
                          onPressed: controller.isSaving.value
                              ? null
                              : () {
                                  if (controller.ticketFormKeyForm.currentState!
                                      .validate()) {
                                    controller.ticketFormKeyForm.currentState!
                                        .save(); // Save the form fields
                                    controller.showConfirmDialogToSaveItem();
                                  }
                                },
                          child: Text(controller.isSaving.value
                              ? 'SAVING...'
                              : 'SAVE TICKET'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                !controller.isSaving.value ? context.theme.colorScheme.primary : null,
                          ),
                        )),
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
