import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:vimbika_pos_app/src/constants/app_constants.dart';
import 'package:vimbika_pos_app/src/constants/app_routes.dart';
import 'package:vimbika_pos_app/src/features/sale/controller/cart_controller.dart';
import 'package:vimbika_pos_app/src/features/sale/controller/sale_controller.dart';
import 'package:vimbika_pos_app/src/features/sale/model/product_full_info_model.dart';
import 'package:vimbika_pos_app/src/features/sale/screen/product_description_screen.dart';
import 'package:vimbika_pos_app/src/features/sale/widget/custom_dropdown_widget.dart';
import 'package:vimbika_pos_app/src/features/sale/widget/product_list_widget.dart';
import 'package:vimbika_pos_app/src/features/sale_receipts/controller/receipt_controller.dart';
import 'package:vimbika_pos_app/src/features/shift/controller/shift_controller.dart';
import 'package:vimbika_pos_app/src/features/ticket/controller/ticket_controller.dart';
import 'package:vimbika_pos_app/src/services/background_service.dart';
import 'package:vimbika_pos_app/src/services/printer_service.dart';
import 'package:vimbika_pos_app/src/shared/controller/inactivity_controller.dart';
import 'package:vimbika_pos_app/src/shared/models/base_name_model.dart';
import 'package:vimbika_pos_app/src/shared/models/currency_model.dart';
import 'package:vimbika_pos_app/src/widgets/nav_drawer_widget.dart';
import 'package:vimbika_pos_app/src/widgets/badge_widget.dart';

class SaleScreen extends GetView {
  var scaffoldKey = GlobalKey<ScaffoldState>();
  final SaleController saleController = Get.put(SaleController());
  final CartController cartController = Get.put(CartController());
  final ShiftController shiftController = Get.put(ShiftController());
  final TicketController ticketController = Get.put(TicketController());
  final InactivityController inactivityController = Get.put(
      InactivityController());
  final BackgroundService bb = Get.put(BackgroundService());
  final ReceiptController receiptController = Get.put(ReceiptController());

  SaleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    String fullName = "${saleController.user.firstName} ${saleController.user
        .lastName}";
    String initials = saleController.user.firstName[0] +
        saleController.user.lastName[0];
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: inactivityController.resetInactivityTimer,
      onPanDown: (_) => inactivityController.resetInactivityTimer(),
      child: Scaffold(
        key: scaffoldKey,
        appBar: AppBar(
          title: Row(
            children: [
              GestureDetector(
                onTap: () {
                  // Define the action when "Ticket" is clicked
                  // Get.toNamed(AppRoutes.OPEN_TICKETS);
                },
                child: Text(
                  'Ticket',
                  style: TextStyle(color: Colors.black),
                ),
              ),
              SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  // Define the action when the count is clicked
                  //  Get.toNamed(AppRoutes.OPEN_TICKETS);
                },
                child: Obx(() {
                  final count = ticketController.openedTicketsCount;
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      // Set the background color for the count
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      count.toString(),
                      style: TextStyle(color: Colors.white,
                          fontSize: 10), // Text color
                    ),
                  );
                }),
              ),
              SizedBox(width: 6),
              Obx(() {
                CurrencyModel? cur =  cartController.selectedCurrency.value;
                // Check if the selected currency exists in the list
                if (!cartController.currencyList.contains(cur) && cartController.currencyList.isNotEmpty) {
                  cur = cartController.currencyList.first;
                  cartController.selectedCurrency.value = cur; // Set a default currency if not found
                }
                return DropdownButton<CurrencyModel>(
                  value: cur,
                  isExpanded: false,
                  // Make the dropdown take full width
                  items: cartController.currencyList.map((cur) {
                    return DropdownMenuItem<CurrencyModel>(

                      value: cur,
                      child: Text(cur.symbol!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    // Filter based on selected currency
                    cartController.onCurrencyChange(value!);

                  },
                  hint: Text("Currency"),
                );
              }),
              SizedBox(width: 3),
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () {
                  //Get.toNamed(AppRoutes.CUSTOMER_FORM);
                  saleController.syncData();
                },
              ),
            ],
          ),
          leading: IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              scaffoldKey.currentState?.openDrawer();
            },
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.person_add),
              onPressed: () {
                 Get.toNamed(AppRoutes.CUSTOMER_FORM);
              },
            ),

          ],
        ),


        drawer: NavDrawer(fullName: fullName,
            mobileNumber: saleController.user.mobilePhone ?? "",
            nameInitials: initials),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // OPEN TICKETS button
                  Expanded(
                    child: Obx(() {
                      return ElevatedButton(
                        onPressed: () {
                          ticketController.getTickets();
                          ticketController.ticketActionButton(cartController.selectedCurrency.value!, cartController.cartItems.length);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14.0),
                          textStyle: TextStyle(fontSize: 12),
                        ),

                        child: Text(
                          cartController.cartItems.length > 0
                              ? 'SAVE'
                              : 'OPEN TICKETS',
                          style: TextStyle(color: Colors.white, fontSize: 16),

                        ),
                      );
                    }),
                  ),
                  SizedBox(width: 8.0),
                  // CHARGE button
                  // Expanded(
                  //   child: ElevatedButton(
                  //     onPressed: () {
                  //       // Define action for charge
                  //       // e.g., open checkout or payment screen
                  //       Get.toNamed(AppRoutes.CART);
                  //     },
                  //
                  //     style: ElevatedButton.styleFrom(
                  //       padding: EdgeInsets.symmetric(vertical: 14.0),
                  //       textStyle: TextStyle(fontSize: 12),
                  //     ),
                  //     child: Obx(() =>
                  //         Text(
                  //          'CHARGE : ${cartController.selectedCurrency.value?.symbol ?? ''} ${cartController.totalCostInSelectedCurrency.toStringAsFixed(2)}',
                  //           style: TextStyle(color: Colors.white, fontSize: 16),
                  //         )),
                  //   ),
                  // ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Define action for charge
                        // e.g., open checkout or payment screen
                        Get.toNamed(AppRoutes.CART);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14.0),
                        textStyle: TextStyle(fontSize: 12),
                      ),
                      child: Obx(() {
                        // Check if totalCostInSelectedCurrency is a number
                        final totalCost = cartController.totalCostInSelectedCurrency;
                        final formattedCost = totalCost != null
                            ? totalCost.toStringAsFixed(2) // Convert to 2 decimal places
                            : '0.00';

                        return Text(
                          'CHARGE : ${cartController.selectedCurrency.value?.symbol ?? ''} $formattedCost',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        );
                      }),
                    ),
                  ),

                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16.0, vertical: 8.0),
              child: Obx(() {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Conditionally show either the DropdownButton or the Search TextField
                    saleController.isSearching.value
                        ? Expanded(
                      child: TextField(
                        controller: saleController.searchTextEditingController,
                        decoration: InputDecoration(
                          hintText: 'Search Items...',
                          border: OutlineInputBorder(),
                          prefixIcon: IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () {
                              saleController.searchTextEditingController
                                  .clear();
                              saleController.isSearching.value =
                              false; // Hide search field

                              final allItemsCategory = saleController.categories
                                  .firstWhere(
                                    (category) => category.id == "All Items",
                                orElse: () => saleController.categories.first,
                              );
                              saleController.selectedCategory.value =
                                  allItemsCategory;


                              saleController.filterProducts(query: '',
                                  category: saleController.selectedCategory
                                      .value?.id);
                            },
                          ),
                        ),
                        onChanged: (query) {
                          // saleController.filterProducts(query);
                          saleController.filterProducts(query: query,
                              category: saleController.selectedCategory.value
                                  ?.name); // Filter based on search query and category
                        },
                      ),
                    )
                        : Expanded(
                      child: DropdownButton<BaseNameModel>(
                        value: saleController.selectedCategory.value,
                        isExpanded: true,
                        // Make the dropdown take full width
                        items: saleController.categories.map((category) {
                          return DropdownMenuItem<BaseNameModel>(
                            value: category,
                            child: Text(category.name!),
                          );
                        }).toList(),
                        onChanged: (value) {
                          saleController.isCatSelected.value = true;
                          saleController.selectedCategory.value = value!;
                          // saleController.filterProducts(value.name!);
                          saleController.filterProducts(category: value
                              .id!); // Filter based on selected category

                        },
                        hint: Text("Select Category"),
                      ),
                    ),
                    // Search Icon
                    if (!saleController.isSearching
                        .value) // Show search icon only when not searching
                      IconButton(
                        icon: Icon(Icons.search),
                        onPressed: () {
                          saleController.isSearching.value =
                          true; // Show search field
                          saleController.selectedCategory.value =
                              BaseNameModel(id: "All Items", name: "All Items");
                          saleController.filterProducts(query: '',
                              category: saleController.selectedCategory.value
                                  ?.id);
                        },
                      ),

                  
                  ],
                );
              }),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextFormField(
                controller: saleController.barCodeTextEditingController,
                keyboardType: TextInputType.number, // Allow only numbers
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly, // Only allow digits (no decimals)
                ],
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.document_scanner_sharp),
                  labelText: "Bar Code",
                  hintText: "Bar Code",
                ),
                onChanged: (String val) {
                  if (val.isNotEmpty) {
                    String exp =  val;

                    if(exp.length>=12) {
                      String chackCode = exp.length > 2 ? exp.substring(0, 2) : '';
                      String productCode = exp.length > 6 ? exp.substring(2, 6) : '';
                      String categoryCode = exp.length > 7 ? exp.substring(6, 7) : '';
                      String weight = exp.length > 12 ? exp.substring(7, 12) : '0';

                      double kgs = double.parse(weight)/1000;
                      double roundedValue = double.parse(kgs.toStringAsFixed(3));
                      if(kgs > 0) {
                        // print(weight);
                        // print(kgs);
                        // print(roundedValue);
                        var index = saleController.allProducts.indexWhere((
                            item) => item.item?.itemCode == productCode);
                        if (index != -1) {

                          ProductFullInfoModel foundItem = saleController.allProducts[index];
                          var indexC = cartController.cartItems.indexWhere((item) => item.product.item?.id == foundItem.item?.id);
                          if(indexC != -1){
                            // Get.snackbar("Info",
                            //     "Product already added !!!",
                            //     snackPosition: SnackPosition.BOTTOM);
                            cartController.addToCart(foundItem, roundedValue);
                            saleController.barCodeTextEditingController.clear();
                          } else {
                            Get.snackbar("Info",
                                "Product added to cart !!!",
                                snackPosition: SnackPosition.BOTTOM);
                            cartController.addToCart(foundItem, roundedValue);
                            saleController.barCodeTextEditingController.clear();

                          }
                        } else {
                          // Item not found, handle this case
                          Get.snackbar("Not Found",
                              "Product with item  code " + productCode +
                                  " is not found!!!",
                              snackPosition: SnackPosition.BOTTOM);
                        }
                      }
                    }
                  }
                },
                validator: (value) {
                  // if (value == null || value.isEmpty) {
                  //   return 'Please enter an amount';
                  // }
                  // int enteredAmount;
                  // try {
                  //   enteredAmount = int.parse(value); // Parse as integer (no decimals)
                  // } catch (e) {
                  //   return 'Please enter a valid whole number';
                  // }
                  //
                  // if (enteredAmount < cartController.totalCostInSelectedCurrency.value) {
                  //   return 'Amount paid cannot be less than the total amount';
                  // }
                  return null;
                },
                onSaved: (value) {
                 // cartController.amountPaid.value = int.parse(value!); // Store as integer
                },
              ),
            ),


            const SizedBox(height: 10),
            // Padding(
            //   padding: const EdgeInsets.all(8.0),
            //   child: Obx(() {
            //     return CustomDropdownWidget<BaseNameModel>(
            //       items: saleController.categories.value,
            //       selectedItem: saleController.selectedCategory.value,
            //       hint: "Select Category",
            //       isSelected: saleController.isCatSelected,
            //       selectedValue: saleController.selectedCategory,
            //       icon: Icons.shopping_basket_outlined,
            //       onChanged: (BaseNameModel? newValue) {
            //         print("Selected category: ${newValue?.name}");
            //         saleController.isCatSelected.value = true;
            //         saleController.selectedCategory.value = newValue!;
            //         saleController.filterProducts(newValue.name!);
            //       },
            //       validator: (value) {
            //         return null;
            //       },
            //       itemBuilder: (BaseNameModel value) =>
            //           Text(value.name!),
            //     );
            //   }),
            // ),
            // const SizedBox(height: 10),
            // Padding(
            //   padding: const EdgeInsets.all(8.0),
            //   child: Obx(() {
            //     return CustomDropdownWidget<BaseNameModel>(
            //       items: saleController.brands.value,
            //       selectedItem: saleController.selectedBrand.value,
            //       hint: "Select Brand",
            //       isSelected: saleController.isBrandSelected,
            //       selectedValue: saleController.selectedBrand,
            //       icon: Icons.breakfast_dining_rounded,
            //       onChanged: (BaseNameModel? newValue) {
            //         saleController.isBrandSelected.value = true;
            //         saleController.selectedBrand.value = newValue!;
            //         print(newValue.name!);
            //         saleController.filterProducts(newValue.name!);
            //       },
            //       validator: (value) {
            //         return null;
            //       },
            //       itemBuilder: (BaseNameModel value) =>
            //           Text(value.name!),
            //     );
            //   }),
            // ),
            // const SizedBox(height: 10),
            // Padding(
            //   padding: const EdgeInsets.all(8.0),
            //   child: ElevatedButton(
            //     onPressed: () {
            //       saleController.clearFilters(); // Clear category dropdown
            //     },
            //     style: ElevatedButton.styleFrom(
            //       padding: EdgeInsets.all(8.0),
            //       textStyle: TextStyle(fontSize: 15),
            //     ),
            //     child: Text('Clear Filters'),
            //   ),
            // ),
            const SizedBox(height: 10),
            Expanded(
              child: Obx(() {
                return ListView.builder(
                  itemCount: saleController.filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = saleController.filteredProducts[index];
                    String name = product.item!.name ?? 'no name';
                    String brand = product.item!.brand?.name ?? '';
                    String fullName = "${name}  ${brand}";
                    String imageUrl = product.item!.images!.isNotEmpty
                        ? "${AppConstants
                        .VIMBIKA_BACKEND_URL}/inventory/image?name=${product
                        .item!
                        .images!.first}"
                        : "https://placehold.co/50x50?text=No+Image";
                    return Card(
                        child:
                        ListTile(
                          leading: CachedNetworkImage(
                            imageUrl: imageUrl,
                            placeholder: (context, url) =>
                                CircularProgressIndicator(),


                            errorWidget: (context, url, error) {
                              debugPrint('Image load failed: $error');
                              return Image.asset(
                                'assets/images/dummy/dummy.png',
                                // Path to your error image
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                          title: Text(fullName),
                          subtitle: Text(product.item!.category?.name ??
                              'No brand'),
                          trailing: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                  "\$${product.item!.sellingPrice
                                      .toStringAsFixed(
                                      2)}"),
                              SizedBox(
                                height: 4, // Space between price and button
                              ),
                              SizedBox(
                                width: 100,
                                // Adjust the width to fit the text
                                height: 30,
                                // Adjust the height to make the button smaller
                                child: ElevatedButton(
                                  onPressed: () {
                                    Get.to(() =>
                                        ProductDescriptionScreen(
                                            productFullInfo: product));
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.all(5.0),
                                    textStyle: TextStyle(fontSize: 14),
                                  ),
                                  child: Text('View' + '(' + product.stock!.toInt().toString() + ')'),
                                ),
                              ),
                            ],
                          ),
                          isThreeLine: true,

                          onTap: () {
                            if(product.stock! > 0) {
                              cartController.addToCart(product, 1);
                            }else if(product.item?.itemType == 'SERVICE'){
                              cartController.addToCart(product, 1);
                            }else{
                              Get.snackbar("Check your stock", "Stock not available!!!", snackPosition: SnackPosition.BOTTOM);
                            }
                          },
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



