import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vimbika_pos_app/src/constants/app_routes.dart';
import 'package:vimbika_pos_app/src/features/shift/controller/shift_controller.dart';
import 'package:vimbika_pos_app/src/shared/controller/inactivity_controller.dart';
import 'package:vimbika_pos_app/src/widgets/nav_drawer_widget.dart';

class ViewShiftScreen extends StatelessWidget {
  // final ShiftController shiftController = Get.put(ShiftController());
  final ShiftController shiftController = Get.find();
  final InactivityController inactivityController = Get.find();
  var scaffoldKeyz = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    String fullName = "${shiftController.user.firstName} ${shiftController.user.lastName}";
    String initials = shiftController.user.firstName[0] + shiftController.user.lastName[0];
    return WillPopScope(
      onWillPop: () async {
        // Navigate to a specific screen when back button is pressed
        Get.offNamed(AppRoutes.SALE); // Replace with your desired route
        return false; // Prevent default back button behavior
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: inactivityController.resetInactivityTimer,
        onPanDown: (_) => inactivityController.resetInactivityTimer(),
        child: Scaffold(
          key: scaffoldKeyz,
          appBar: AppBar(
            backgroundColor: Colors.white, // Same as your app theme
            elevation: 1,
            title: Text('ACTIVE SHIFT'),
            leading: IconButton(
              icon: Icon(Icons.menu),
              onPressed: () {
                scaffoldKeyz.currentState?.openDrawer();
              },
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () {
                  shiftController.shiftInfo();
                },
              ),
            ],
          ),
          drawer: NavDrawer(fullName: fullName, mobileNumber: shiftController.user.mobilePhone  ?? "", nameInitials: initials),

          body: SingleChildScrollView( // Wrapping with SingleChildScrollView to make content scrollable
            child: Column(
              children: [
                SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Get.delete<ShiftController>();
                        Get.toNamed(AppRoutes.CASH_MANAGEMENT);
                      },
                      child: Text('CASH MANAGEMENT'),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Get.delete<ShiftController>();
                        Get.toNamed(AppRoutes.SUBMIT_CASH);
                      },
                      child: Text('SUBMIT CASH'),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        shiftController.showConfirmDialogCloseShift();
                      },
                      child: Text('CLOSE SHIFT'),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                // Display opening time, user full name, and shift reference centered
                Text(
                  'Opening Time: ${shiftController.activeShift.value.openingTime}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'User: ${shiftController.activeShift.value.userFullName}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Reference: ${shiftController.activeShift.value.shiftReference}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),

                // Display the list of currency amounts centered
                Text(
                  'TRANSACTIONS',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(), // Disable scrolling of ListView.builder
                  itemCount: shiftController.activeShift.value.shiftCurrencyAmounts!.length,
                  itemBuilder: (context, index) {
                    final currencyAmount = shiftController.activeShift.value.shiftCurrencyAmounts![index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: ListTile(
                        tileColor: Colors.grey[200],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Left side: timeCreated and ref
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currencyAmount.timeCreated,
                                  style: TextStyle(fontSize: 14),
                                ),
                                // Text(
                                //   currencyAmount.ref!,
                                //   style: TextStyle(fontSize: 14),
                                // ),
                                Text(
                                  currencyAmount.amountType == "CASH_IN" || currencyAmount.amountType == "CASH_OUT"
                                      ? currencyAmount.notes ?? ""
                                      : currencyAmount.ref!,
                                  style: TextStyle(fontSize: 14),
                                ),

                              ],
                            ),
                            // Right side: amount and amount type
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${currencyAmount.currency.symbol} ${currencyAmount.amount.toStringAsFixed(2)}',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  currencyAmount.amountType,
                                  style: TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 16),
                Text(
                  'TOTAL AMOUNTS BY CURRENCY',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(), // Disable scrolling of ListView.builder
                  itemCount: shiftController.totalAmountsByCurrency.length,
                  itemBuilder: (context, index) {
                    final total = shiftController.totalAmountsByCurrency[index];
                    return ListTile(
                      title: Text(
                        total['currencyName'],
                        style: TextStyle(fontSize: 18),
                      ),
                      trailing: Text(
                        '${total['totalAmount'].toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
                SizedBox(height: 20), // Space between sections
                Text(
                  'TOTAL CASH SUBMITTED',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: shiftController.totalCashSubmittedList.length,
                  itemBuilder: (context, index) {
                    final submitted = shiftController.totalCashSubmittedList[index];
                    return ListTile(
                      title: Text(
                        submitted['currencyName'],
                        style: TextStyle(fontSize: 18),
                      ),
                      trailing: Text(
                        '${submitted['totalAmount'].toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          bottomNavigationBar: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Ensures it only takes needed space
              children: [
                SizedBox(
                  width: double.infinity, // Makes the button take full width
                  child: ElevatedButton(
                    onPressed: () {
                      shiftController.printShift(shiftController.activeShift.value);
                    },
                    child: Text('PRINT'),
                  ),
                ),
                SizedBox(height: 10), // Spacing between buttons
                SizedBox(
                  width: double.infinity, // Makes the button take full width
                  child: ElevatedButton(
                    onPressed: () {
                      Get.offNamed(AppRoutes.SALE);
                    },
                    child: Text('POS'),
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

