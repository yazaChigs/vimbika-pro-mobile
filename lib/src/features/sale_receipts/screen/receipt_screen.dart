import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:vimbika_pos_app/src/features/sale/widget/custom_dropdown_widget.dart';
import 'package:vimbika_pos_app/src/features/sale_receipts/controller/receipt_controller.dart';
import 'package:vimbika_pos_app/src/features/shift/model/shift_model.dart';
import 'package:vimbika_pos_app/src/services/printer_service.dart';
import 'package:vimbika_pos_app/src/shared/controller/inactivity_controller.dart';
import 'package:vimbika_pos_app/src/shared/models/base_name_model.dart';
import 'package:vimbika_pos_app/src/utils/app_helper.dart';
import 'package:vimbika_pos_app/src/widgets/nav_drawer_widget.dart';

import '../../../constants/app_routes.dart';

class ReceiptScreen extends StatelessWidget {
  var scaffoldKey = GlobalKey<ScaffoldState>();
  final InactivityController inactivityController =
      Get.put(InactivityController());
  final ReceiptController receiptController = Get.put(ReceiptController());

  // Format date header (Today, Yesterday, or full date)
  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else {
      // Format as "Monday, January 15, 2024"
      return DateFormat('EEEE, MMMM d, yyyy').format(date);
    }
  }

  // Build day divider widget
  Widget _buildDayDivider(String dateText) {
    return Container(
      margin: EdgeInsets.only(top: 16, bottom: 8, left: 8, right: 8),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border(
          bottom: BorderSide(color: Colors.blue[200]!, width: 2),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today, color: Colors.blue[700], size: 20),
          SizedBox(width: 8),
          Text(
            dateText,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue[900],
            ),
          ),
        ],
      ),
    );
  }

  // Get shift by reference
  ShiftModel? _getShiftByReference(String? shiftReference) {
    if (shiftReference == null ||
        shiftReference.isEmpty ||
        receiptController.shifts.isEmpty) {
      return null;
    }
    try {
      // Use firstWhereOrNull to safely find the shift
      final shift = receiptController.shifts.firstWhereOrNull(
        (shift) => shift.shiftReference == shiftReference,
      );
      return shift;
    } catch (e) {
      print("Error finding shift: $e");
      return null;
    }
  }

  // Format shift header text
  String _formatShiftHeader(ShiftModel? shift, String? shiftReference) {
    if (shift == null) {
      return 'Shift: ${shiftReference ?? 'Unknown'}';
    }

    String shiftRef = shift.shiftReference ?? 'Unknown';
    List<String> parts = ['Shift: $shiftRef'];

    // Format opening time
    String openingTime = '';
    if (shift.openingTime != null && shift.openingTime!.isNotEmpty) {
      try {
        DateTime? openTime;
        if (shift.openingTime!.contains('T')) {
          openTime = DateTime.parse(shift.openingTime!);
        } else {
          openTime = DateTime.tryParse(shift.openingTime!);
        }

        if (openTime != null) {
          openingTime = DateFormat('h:mm a').format(openTime);
        } else {
          openingTime = shift.openingTime!;
        }
      } catch (e) {
        openingTime = shift.openingTime!;
      }
    }

    if (openingTime.isNotEmpty) {
      parts.add('Opened: $openingTime');
    }

    // Format closing time (Option 1)
    String closingTime = '';
    if (shift.closingTime != null && shift.closingTime!.isNotEmpty) {
      try {
        DateTime? closeTime;
        if (shift.closingTime!.contains('T')) {
          closeTime = DateTime.parse(shift.closingTime!);
        } else {
          closeTime = DateTime.tryParse(shift.closingTime!);
        }

        if (closeTime != null) {
          closingTime = DateFormat('h:mm a').format(closeTime);
        } else {
          closingTime = shift.closingTime!;
        }
      } catch (e) {
        closingTime = shift.closingTime!;
      }
    }

    if (closingTime.isNotEmpty) {
      parts.add('Closed: $closingTime');
    }

    // Add shift status (Option 2)
    String status = shift.isShiftClosed == true ? 'Closed' : 'Active';
    parts.add('Status: $status');

    // Add cashier name if available
    if (shift.userFullName != null && shift.userFullName!.isNotEmpty) {
      parts.add('Cashier: ${shift.userFullName}');
    }

    return parts.join(' | ');
  }

  // Build shift divider widget
  Widget _buildShiftDivider(String shiftText) {
    return Container(
      margin: EdgeInsets.only(top: 8, bottom: 8, left: 8, right: 8),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border(
          bottom: BorderSide(color: Colors.green[200]!, width: 1.5),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time, color: Colors.green[700], size: 18),
          SizedBox(width: 8),
          Text(
            shiftText,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.green[900],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String fullName =
        "${receiptController.user.firstName} ${receiptController.user.lastName}";
    String initials = receiptController.user.firstName[0] +
        receiptController.user.lastName[0];

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: inactivityController.resetInactivityTimer,
      onPanDown: (_) => inactivityController.resetInactivityTimer(),
      child: WillPopScope(
        onWillPop: () async {
          // Navigate to a specific screen when back button is pressed
          Get.offNamed(AppRoutes.SALE); // Replace with your desired route
          return false; // Prevent default back button behavior
        },
        child: Scaffold(
          key: scaffoldKey,
          appBar: AppBar(
            title: Text('RECEIPTS'),
            leading: IconButton(
              icon: Icon(Icons.menu),
              onPressed: () {
                scaffoldKey.currentState?.openDrawer();
              },
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.clear,
                  size: 30,
                ),
                color: Colors.red,
                onPressed: () {
                  receiptController.cancelFilter();
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.refresh,
                  color: context.theme.colorScheme.primary,
                  size: 30,
                ),
                onPressed: () {
                  receiptController.refreshFilter();
                },
              ),
            ],
          ),
          drawer: NavDrawer(
            fullName: fullName,
            mobileNumber: receiptController.user.mobilePhone ?? "",
            nameInitials: initials,
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        readOnly: true,
                        controller: receiptController.startDateController,
                        decoration: InputDecoration(
                          labelText: 'Select Start Date',
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
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        onTap: () async {
                          DateTime? selectedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (selectedDate != null) {
                            String formattedDate =
                                DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
                                    .format(selectedDate);
                            receiptController.startDateController.text =
                                DateFormat('yyyy-MM-dd').format(selectedDate);
                            receiptController.startDate.value = formattedDate;
                            //receiptController.getSalesByDate(formattedDate);
                          }
                        },
                      ),
                    ),
                  ),
                  Expanded(
                      child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      readOnly: true,
                      controller: receiptController.endDateController,
                      decoration: InputDecoration(
                        labelText: 'Select End Date',
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
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: () async {
                        DateTime? selectedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (selectedDate != null) {
                          String formattedDate =
                              DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
                                  .format(selectedDate);
                          receiptController.endDateController.text =
                              DateFormat('yyyy-MM-dd').format(selectedDate);
                          receiptController.endDate.value = formattedDate;
                        }
                      },
                    ),
                  )),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Obx(() {
                        return CustomDropdownWidget<BaseNameModel>(
                          //add boader color
                          items: receiptController.categories.value,
                          selectedItem:
                              receiptController.selectedCategory.value,
                          hint: "Select Category",
                          isSelected: receiptController.isCatSelected,
                          selectedValue: receiptController.selectedCategory,
                          icon: Icons.shopping_basket_outlined,
                          onChanged: (BaseNameModel? newValue) {
                            print("Selected category: ${newValue?.name}");
                            receiptController.isCatSelected.value = true;
                            receiptController.selectedCategory.value =
                                newValue!;
                          },
                          validator: (value) {
                            return null;
                          },
                          itemBuilder: (BaseNameModel value) =>
                              Text(value.name!),
                        );
                      }),
                    ),
                  ),
                  Expanded(
                      child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.theme.colorScheme.primary,
                      ),
                      onPressed: () {
                        receiptController.searchSales();
                      },
                      child: Text('SEARCH'),
                    ),
                  ))
                ],
              ),
/*
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  onChanged: (p) {
                    receiptController.filterReceipts(p);
                  },
                  decoration: const InputDecoration(
                    labelText: 'Search',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),*/

              // Add total amount card here
              Obx(() {
                Map<String, double> totalsByCurrency =
                    receiptController.calculateTotalByCurrency();

                if (totalsByCurrency.isEmpty) {
                  return SizedBox
                      .shrink(); // No totals to show, return an empty space
                }

                return Card(
                  margin: const EdgeInsets.all(8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(0), // Square corners
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.center, // Center the text
                      children: [
                        Text(
                          'Totals by Currency',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: context.theme.colorScheme.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 5), // Space between heading and totals
                        ...totalsByCurrency.entries.map((entry) {
                          return Text(
                            '${entry.key}  ${entry.value.toStringAsFixed(2)}',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: context.theme.colorScheme.onSurface),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                );
              }),

              Expanded(
                child: Obx(() {
                  if (receiptController.filteredReceipts.isEmpty) {
                    return Center(
                      child: Text(
                        'No receipts found',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: receiptController.filteredReceipts.length,
                    itemBuilder: (context, index) {
                      final saleInfo =
                          receiptController.filteredReceipts[index];
                      final sale = saleInfo.sale;

                      // Get current receipt date (convert to local to bucket correctly)
                      String? currentDateStr = sale?.timeIniated;
                      DateTime? currentDate;
                      if (currentDateStr != null && currentDateStr.isNotEmpty) {
                        try {
                          currentDate =
                              DateTime.parse(currentDateStr).toLocal();
                        } catch (e) {
                          currentDate = null;
                        }
                      }

                      // Get previous receipt date to check if we need a divider (convert to local)
                      String? previousDateStr;
                      DateTime? previousDate;
                      if (index > 0) {
                        previousDateStr = receiptController
                            .filteredReceipts[index - 1].sale?.timeIniated;
                        if (previousDateStr != null &&
                            previousDateStr.isNotEmpty) {
                          try {
                            previousDate =
                                DateTime.parse(previousDateStr).toLocal();
                          } catch (e) {
                            previousDate = null;
                          }
                        }
                      }

                      // Get current receipt shift reference
                      String? currentShiftRef = sale?.shiftReference;

                      // Get previous receipt shift reference
                      String? previousShiftRef;
                      if (index > 0) {
                        previousShiftRef = receiptController
                            .filteredReceipts[index - 1].sale?.shiftReference;
                      }

                      // Check if we need to show a day divider
                      bool showDayDivider = false;
                      String dayDividerText = "";
                      if (currentDate != null) {
                        if (index == 0) {
                          // Always show divider for first item
                          showDayDivider = true;
                        } else if (previousDate != null) {
                          // Check if date changed
                          if (currentDate.year != previousDate.year ||
                              currentDate.month != previousDate.month ||
                              currentDate.day != previousDate.day) {
                            showDayDivider = true;
                          }
                        }

                        if (showDayDivider) {
                          dayDividerText = _formatDateHeader(currentDate);
                        }
                      }

                      // Check if we need to show a shift divider
                      bool showShiftDivider = false;
                      String shiftDividerText = "";
                      if (currentShiftRef != null &&
                          currentShiftRef.isNotEmpty) {
                        if (index == 0) {
                          // Always show shift divider for first item if it has a shift
                          showShiftDivider = true;
                        } else {
                          // Check if shift changed (within same day or across days)
                          if (currentShiftRef != previousShiftRef) {
                            showShiftDivider = true;
                          }
                        }

                        if (showShiftDivider) {
                          ShiftModel? shift =
                              _getShiftByReference(currentShiftRef);
                          shiftDividerText =
                              _formatShiftHeader(shift, currentShiftRef);
                        }
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showDayDivider) _buildDayDivider(dayDividerText),
                          if (showShiftDivider)
                            _buildShiftDivider(shiftDividerText),
                          Card(
                            color: sale!.saleStatus == "REVERSED"
                                ? Colors.redAccent[100]
                                : context.theme.colorScheme.primaryContainer,
                            child: ListTile(
                              leading: Text(
                                '${sale!.currency?.symbol ?? ''} ${sale.amountAfterDiscount!.toStringAsFixed(2).toString()}',
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.lightGreen),
                              ),
                              title: Text(
                                sale.referenceNumber!,
                                style: TextStyle(
                                    fontSize: 20,
                                    color: context.theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Column(
                                    children: [
                                      Text(sale.paymentTypes!
                                          .map((paymentType) =>
                                              paymentType.paymentType!.name)
                                          .join()),
                                      Text(sale.timeIniated!
                                          .replaceFirst('T', ' ')),
                                    ],
                                  ),
                                  Expanded(
                                      child: IconButton(
                                          onPressed: () async {
                                            if(saleInfo.syncStatus == false && !receiptController.isSingleClickCLicked.value && await receiptController.internetAccess()){
                                              receiptController.isSingleClickCLicked.value = true;
                                              var synced =  receiptController.syncSale(saleInfo, index);
                                              if(await synced){
                                                receiptController.filteredReceipts[index].syncStatus = true;
                                                receiptController.filteredReceipts.refresh();
                                                receiptController.isSingleClickCLicked.value = false;
                                              }
                                            }
                                          },
                                          icon: saleInfo.syncStatus == true
                                              ? Icon(Icons.check,
                                                  color: Colors.green, size: 40)
                                              : Icon(
                                                  Icons.sync_problem_outlined,
                                                  color: Colors.red,
                                                  size: 40))),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${sale.saleStatus ?? 'N/A'}',
                                    style: sale.saleStatus != 'REVERSED'
                                        ? TextStyle(
                                            fontSize: 12,
                                            color: context.theme.colorScheme
                                                .primaryContainer)
                                        : TextStyle(
                                            fontSize: 12,
                                            color: Colors.red[700]),
                                  ),
                                  Expanded(
                                    child: Container(
                                      width: 150,
                                      height: double.infinity,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.print_outlined,
                                                color: context
                                                    .theme.colorScheme.primary,
                                                size: 30),
                                            onPressed: () async {
                                              if (receiptController
                                                  .isPrintClicked.isFalse) {
                                                receiptController.isPrintClicked
                                                    .value = true;
                                                sale.saleStatus != 'REVERSED'
                                                    ? receiptController
                                                        .printSale(saleInfo)
                                                    : null;
                                              }
                                            },
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.receipt_long_outlined,
                                                color: context
                                                    .theme.colorScheme.secondary,
                                                size: 30),
                                            onPressed: () {
                                              receiptController.showReceiptDialog(saleInfo);
                                            },
                                          ),
                                          Container(
                                            child: sale.saleStatus != 'REVERSED'
                                                ? IconButton(
                                                    enableFeedback: true,
                                                    icon: Icon(
                                                        Icons
                                                            .delete_forever_outlined,
                                                        color: Colors.redAccent,
                                                        size: 30),
                                                    onPressed: () {
                                                      receiptController
                                                          .showConfirmDialogToDeleteItem(
                                                              saleInfo, index);
                                                    },
                                                  )
                                                : SizedBox(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
