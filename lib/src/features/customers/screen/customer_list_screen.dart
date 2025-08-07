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
                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                    // crossAxisSpacing: 3.0,
                    // mainAxisSpacing: 3.0,
                    childAspectRatio: 1.5,
                  ),
                  shrinkWrap: true,
                  itemCount: customerController.filteredCustomers.length,
                  itemBuilder: (context, index) {
                    var customer = customerController.filteredCustomers[index];
                    return Card(
                      color: Colors.pinkAccent[100],
                      // margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                      child: GridTile(

                          child:
                          Column(
                            // mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      customer.name ?? 'Unknown Name',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.indigo,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                    (customer.isLoyalCustomer ?? false) ?
                                    IconButton(
                                      onPressed: (){},
                                      icon: Icon(Icons.check,size: 40,color: Colors.green,)
                                      ,)
                                        : SizedBox(),
                                    PopupMenuButton(
                                        onSelected: (result){
                                        },
                                        itemBuilder: (context) => [
                                          PopupMenuItem(
                                            child: ListTile(
                                                leading: Icon(Icons.edit),
                                                title: Text("Edit")
                                            ),
                                            value: 0,
                                            onTap: () {
                                              customerController.nameEditingController.text = customer.name ??"";
                                              customerController.addressEditingController.text = customer.street ??"";
                                              customerController.emailEditingController.text = customer.email ??"";
                                              customerController.mobileNumberEditingController.text = customer.mobilePhone ??"";
                                              customerController.accNoEditingController.text = customer.accountNumber ??"";
                                              customerController.selectedCustomer.value = customer;
                                              customerController.editCustomer.value = true;
                                              Get.toNamed(AppRoutes.CUSTOMER_FORM);
                                            },
                                          ),
                                          !(customer.isLoyalCustomer ?? false) ? PopupMenuItem(
                                            child: ListTile(
                                                leading: Icon(Icons.account_box),
                                                title: Text("Set AS Loyal Customer")
                                            ),
                                            value: 1,
                                            onTap: () {
                                              customerController.setLoyalCustomer(customer);
                                            },
                                          ):
                                          PopupMenuItem(
                                            child: ListTile(
                                                leading: Icon(Icons.credit_card_outlined),
                                                title: Text("Credit Account")
                                            ),
                                            value: 1,
                                            onTap: () {
                                              customerController.selectedCustomer.value = customer;
                                              Get.toNamed(AppRoutes.PAY_ACC_FORM);
                                            },
                                          ),
                                        ]
                                    ),
                                  ],
                                ),
                                Text(
                                  'Customer No.: ${customer.accountNumber ?? 'N/A'}',
                                  style: TextStyle(fontSize: 16),
                                ),
                                Text(
                                  'Customer Balance: ${customer.currencyBalance?.map((balance)=> (balance.currency.symbol??"") + "${balance.balance}" + ",").join("") ?? 'N/A'}',
                                  style: TextStyle(fontSize: 16),
                                ),
                                Text(
                                  'Branch: ${customer.branch?.name ?? 'N/A'}',
                                  style: TextStyle(fontSize: 16),
                                ),
                            ],
                          ),
                        /*footer:
                        customer.isLoyalCustomer! ?
                        IconButton(
                          onPressed: (){},
                          icon: Icon(Icons.check,size: 40,color: Colors.green,)
                          ,)
                            : SizedBox(),*/
                      )
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
