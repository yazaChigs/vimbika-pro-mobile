import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vimbika_pos_app/src/constants/app_routes.dart';
import 'package:vimbika_pos_app/src/features/customers/controller/customer_controller.dart';
import 'package:vimbika_pos_app/src/shared/controller/inactivity_controller.dart';
import 'package:vimbika_pos_app/src/widgets/nav_drawer_widget.dart';

class CustomerListScreen extends StatelessWidget {

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final InactivityController inactivityController = Get.put(InactivityController());
  final CustomerController customerController = Get.put(CustomerController());



  @override
  Widget build(BuildContext context) {
    String fullName = "${customerController.user.firstName} ${customerController.user
        .lastName}";
    String initials = customerController.user.firstName[0] +
        customerController.user.lastName[0];
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: inactivityController.resetInactivityTimer,
      onPanDown: (_) => inactivityController.resetInactivityTimer(),
      child: Scaffold(
        key: scaffoldKey,

        appBar: AppBar(
          title: Text('CUSTOMERS'),
          leading: IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              scaffoldKey.currentState?.openDrawer();
            },
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () {
                customerController.getCustomers(customerController.user, customerController.box, customerController.user.company!.id!);
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
           Get.toNamed(AppRoutes.CUSTOMER_FORM);
          },
          child: Icon(Icons.add),
          tooltip: 'Add Customer',
        ),
        drawer: NavDrawer(fullName: fullName,
            mobileNumber: customerController.user.mobilePhone ?? "",
            nameInitials: initials),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                onChanged: (p) {
                  customerController.filterCustomers(p);
                },
                decoration: const InputDecoration(
                  labelText: 'Search',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                return ListView.builder(
                  itemCount: customerController.filteredCustomers.length,
                  itemBuilder: (context, index) {
                    var customer = customerController.filteredCustomers[index];
                    return Card(
                      elevation: 4,
                      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customer.name ?? 'Unknown Name',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Customer ID: ${customer.customerId ?? 'N/A'}',
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Mobile Phone: ${customer.mobilePhone ?? 'N/A'}',
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Email: ${customer.email ?? 'N/A'}',
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Branch: ${customer.branch?.name ?? 'N/A'}',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
