import 'dart:developer';
import 'dart:ffi';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:search_choices/search_choices.dart';
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
import 'package:vimbika_pos_app/src/shared/models/payment_type_model.dart';
import 'package:vimbika_pos_app/src/widgets/nav_drawer_widget.dart';
import 'package:vimbika_pos_app/src/widgets/badge_widget.dart';

import '../../../shared/models/customer_model.dart';

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

  // const Responsive({required this.mobile, required this.tablet, required this.desktop, super.key});

  late Widget mobile;
  late Widget tablet;
  double screenSize = 0.00;

  static bool isMobile(BuildContext context) =>
      MediaQuery
          .of(context)
          .size
          .width < 950.0;

  static bool isTablet(BuildContext context) =>
      MediaQuery
          .of(context)
          .size
          .width >= 950.0;


  SaleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    screenSize = MediaQuery
        .of(context)
        .size
        .width;
    String fullName = "${saleController.user.firstName} ${saleController.user
        .lastName}";
    String initials = saleController.user.firstName[0] +
        saleController.user.lastName[0];
    if (isMobile(context)) {
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: inactivityController.resetInactivityTimer,
        onPanDown: (_) => inactivityController.resetInactivityTimer(),
        child: Scaffold(
          key: scaffoldKey,
          appBar: AppBar(
            backgroundColor: Colors.white,
            // Same as your app theme
            elevation: 0,
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
                  CurrencyModel? cur = cartController.selectedCurrency.value;
                  // Check if the selected currency exists in the list
                  if (!cartController.currencyList.contains(cur) &&
                      cartController.currencyList.isNotEmpty) {
                    cur = cartController.currencyList.first;
                    cartController.selectedCurrency.value =
                        cur; // Set a default currency if not found
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
                            // ticketController.getTickets();
                            ticketController.ticketActionButton(
                                cartController.selectedCurrency.value!,
                                cartController.cartItems.length);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyan,
                            padding: EdgeInsets.symmetric(vertical: 14.0),
                            textStyle: TextStyle(fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
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
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Define action for charge
                          // e.g., open checkout or payment screen
                          Get.toNamed(AppRoutes.CART);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(vertical: 14.0),
                          textStyle: TextStyle(fontSize: 12, color: Colors
                              .white, fontWeight: FontWeight.bold),
                        ),
                        child: Obx(() {
                          // Check if totalCostInSelectedCurrency is a number
                          final totalCost = cartController
                              .totalCostInSelectedCurrency;
                          final formattedCost = totalCost != null
                              ? totalCost.toStringAsFixed(
                              2) // Convert to 2 decimal places
                              : '0.00';

                          return Text(
                            'CHARGE : ${cartController.selectedCurrency.value
                                ?.symbol ?? ''} $formattedCost',
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
                          controller: saleController
                              .searchTextEditingController,
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

                                final allItemsCategory = saleController
                                    .categories
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
                                BaseNameModel(
                                    id: "All Items", name: "All Items");
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
                  autofocus: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.document_scanner_sharp),
                    labelText: "Bar Code",
                    hintText: "Bar Code",
                  ),
                  onChanged: (String val) {
                    if (val.isNotEmpty) {
                      String exp = val;

                      if (saleController.useSerialNumbers) {
                        var index = saleController.allProducts.indexWhere((
                            item) => item.barCodes?.contains(exp) == true);
                        if (index != -1) {
                          ProductFullInfoModel foundItem = saleController
                              .allProducts[index];
                          var indexC = cartController.cartItems.indexWhere((
                              item) =>
                          item.product.item?.id == foundItem.item?.id);
                          if (indexC != -1) {
                            // Get.snackbar("Info",
                            //     "Product already added !!!",
                            //     snackPosition: SnackPosition.BOTTOM);
                            cartController.addToCartWithBarCode(
                                foundItem, 1, exp);
                            saleController.barCodeTextEditingController.clear();
                          } else {
                            Get.snackbar("Info",
                                "Product added to cart !!!",
                                snackPosition: SnackPosition.BOTTOM);
                            cartController.addToCartWithBarCode(
                                foundItem, 1, exp);
                            saleController.barCodeTextEditingController.clear();
                          }
                        } else {
                          var index = saleController.allProducts.indexWhere((
                              item) => item.item?.itemCode == exp);
                          if (index != -1) {
                            ProductFullInfoModel foundItem = saleController
                                .allProducts[index];
                            var indexC = cartController.cartItems.indexWhere((
                                item) =>
                            item.product.item?.id == foundItem.item?.id);
                            if (indexC != -1) {
                              // Get.snackbar("Info",
                              //     "Product already added !!!",
                              //     snackPosition: SnackPosition.BOTTOM);
                              cartController.addToCart(foundItem, 1);
                              saleController.barCodeTextEditingController
                                  .clear();
                            } else {
                              Get.snackbar("Info",
                                  "Product added to cart !!!",
                                  snackPosition: SnackPosition.BOTTOM);
                              cartController.addToCart(foundItem, 1);
                              saleController.barCodeTextEditingController
                                  .clear();
                            }
                          } else {
                            // Item not found, handle this case
                            Get.snackbar("Not Found",
                                "Product with item  code " + exp +
                                    " is not found!!!",
                                snackPosition: SnackPosition.BOTTOM);
                          }
                        }
                      } else if (exp.length >= 12) {
                        String chackCode = exp.length > 2
                            ? exp.substring(0, 2)
                            : '';
                        String productCode = exp.length > 6 ? exp.substring(
                            2, 6) : '';
                        String categoryCode = exp.length > 7 ? exp.substring(
                            6, 7) : '';
                        String weight = exp.length > 12
                            ? exp.substring(7, 12)
                            : '0';

                        double kgs = double.parse(weight) / 1000;
                        double roundedValue = double.parse(kgs.toStringAsFixed(
                            3));
                        if (kgs > 0) {
                          // print(weight);
                          // print(kgs);
                          // print(roundedValue);
                          var index = saleController.allProducts.indexWhere((
                              item) => item.item?.itemCode == productCode);
                          if (index != -1) {
                            ProductFullInfoModel foundItem = saleController
                                .allProducts[index];
                            var indexC = cartController.cartItems.indexWhere((
                                item) =>
                            item.product.item?.id == foundItem.item?.id);
                            if (indexC != -1) {
                              // Get.snackbar("Info",
                              //     "Product already added !!!",
                              //     snackPosition: SnackPosition.BOTTOM);
                              cartController.addToCart(foundItem, roundedValue);
                              saleController.barCodeTextEditingController
                                  .clear();
                            } else {
                              Get.snackbar("Info",
                                  "Product added to cart !!!",
                                  snackPosition: SnackPosition.BOTTOM);
                              cartController.addToCart(foundItem, roundedValue);
                              saleController.barCodeTextEditingController
                                  .clear();
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
                    return null;
                  },
                  onSaved: (value) {
                    // cartController.amountPaid.value = int.parse(value!); // Store as integer
                  },
                ),
              ),
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
                      String category = product.item!.category?.name ?? '';
                      String itemName = fullName + ' ' + category;
                      return Card(
                          child:
                          ListTile(
                            tileColor: Colors.blue[100],
                            /*  leading: CachedNetworkImage(
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
                            ),*/
                            title: Text(itemName),
                            subtitle: Text('Available units ' + '(' +
                                product.stock!.toInt().toString() + ')'),
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
                                /*SizedBox(
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
                                      backgroundColor: Colors.indigo,
                                      padding: EdgeInsets.all(5.0),
                                      textStyle: TextStyle(
                                          fontSize: 14, color: Colors.white),
                                    ),
                                    child: Text('View'),
                                  ),
                                ),*/
                              ],
                            ),
                            isThreeLine: true,

                            onTap: () {
                              if (product.item?.itemType == 'SERVICE') {
                                cartController.addToCart(product, 1);
                              } else if (product.stock! > 0 ||
                                  saleController.sellNilItems) {
                                cartController.addToCart(product, 1);
                              } else {
                                Get.snackbar("Check your stock",
                                    "Stock not available!!!",
                                    snackPosition: SnackPosition.BOTTOM);
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
    } else {
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: inactivityController.resetInactivityTimer,
        onPanDown: (_) => inactivityController.resetInactivityTimer(),
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          key: scaffoldKey,
          appBar: AppBar(
            backgroundColor: Colors.white,
            // Same as your app theme
            elevation: 0,
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
                Expanded(child:
                  Container(
                      child: Obx(() {
                        return  GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cartController.currencyList.length,
                            mainAxisSpacing: 10.0,
                            crossAxisSpacing: 2.0,
                            // childAspectRatio: 2.0, // Adjust aspect ratio as needed
                            mainAxisExtent: 40.0, // Adjust height of each item
                          ),
                          // scrollDirection: Axis.horizontal,
                          physics:  PageScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: cartController.currencyList.length,
                          itemBuilder: (context, index) {
                            final currency = cartController.currencyList[index];
                            return Container(
                              decoration:
                              BoxDecoration(
                                color: cartController.isCurrencySelected.value && cartController.selectedCurrency.value?.id == currency.id
                                    ? Colors.purple[200]
                                    : Colors.white,
                                border: Border.all(
                                  color: Colors.indigo,
                                  width: 2.0,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              // width: 100,
                              child: InkWell(
                                onTap: () {
                                  cartController.isCurrencySelected.value = true;
                                  cartController.selectedCurrency.value = currency;
                                  cartController.onCurrencyChange(currency);
                                },
                                child: Center(
                                  child: Text(
                                    currency.name!,
                                    style: TextStyle(fontSize: 12.0, color: Colors.black, fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      })
                  )
                ),
                SizedBox(width: 20),
                Container(
                  width: screenSize * 0.4,
                  child: Obx(() {
                    return Row(
                      children: [

                        saleController.isSearching.value
                            ? Expanded(
                          child: Container(
                            child: TextField(
                              controller: saleController
                                  .searchTextEditingController,
                              decoration: InputDecoration(
                                hintText: 'Search Items...',
                                border: OutlineInputBorder(),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: BorderSide(
                                    color: Colors.indigo,
                                    width: 2.0,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: const BorderSide(
                                    color: Colors.pinkAccent,
                                    width: 2.0,
                                  ),
                                ),
                                prefixIcon: IconButton(
                                  icon: Icon(Icons.close),
                                  onPressed: () {
                                    saleController.searchTextEditingController
                                        .clear();
                                    saleController.isSearching.value =
                                    false; // Hide search field

                                    final allItemsCategory = saleController
                                        .categories
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
                          ),
                        )
                            :
                        Expanded(
                          child:  Container(
                    width: screenSize * 0.4 * 0.7,
                            child: TextFormField(
                              controller: saleController
                                  .barCodeTextEditingController,
                              decoration: InputDecoration(
                                iconColor: Colors.indigo,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: const BorderSide(
                                    color: Colors.indigo,
                                    width: 2.0,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: const BorderSide(
                                    color: Colors.pinkAccent,
                                    width: 2.0,
                                  ),
                                ),
                                prefixIcon: const Icon(
                                    Icons.document_scanner_sharp),
                                labelText: "Bar Code",
                                hintText: "Bar Code",
                              ),
                              onChanged: (String val) {
                                if (val.isNotEmpty) {
                                  String exp = val;

                                  if (saleController.useSerialNumbers) {
                                    var index = saleController.allProducts
                                        .indexWhere((item) =>
                                    item.barCodes?.contains(exp) == true);
                                    if (index != -1) {
                                      ProductFullInfoModel foundItem = saleController
                                          .allProducts[index];
                                      var indexC = cartController.cartItems
                                          .indexWhere((item) =>
                                      item.product.item?.id == foundItem.item?.id);
                                      if (indexC != -1) {
                                        // Get.snackbar("Info",
                                        //     "Product already added !!!",
                                        //     snackPosition: SnackPosition.BOTTOM);
                                        cartController.addToCartWithBarCode(
                                            foundItem, 1, exp);
                                        saleController.barCodeTextEditingController
                                            .clear();
                                      } else {
                                        Get.snackbar("Info",
                                            "Product added to cart !!!",
                                            snackPosition: SnackPosition.BOTTOM);
                                        cartController.addToCartWithBarCode(
                                            foundItem, 1, exp);
                                        saleController.barCodeTextEditingController
                                            .clear();
                                      }
                                    } else {
                                      var index = saleController.allProducts
                                          .indexWhere((item) =>
                                      item.item?.itemCode == exp);
                                      if (index != -1) {
                                        ProductFullInfoModel foundItem = saleController
                                            .allProducts[index];
                                        var indexC = cartController.cartItems
                                            .indexWhere((item) =>
                                        item.product.item?.id ==
                                            foundItem.item?.id);
                                        if (indexC != -1) {
                                          // Get.snackbar("Info",
                                          //     "Product already added !!!",
                                          //     snackPosition: SnackPosition.BOTTOM);
                                          cartController.addToCart(foundItem, 1);
                                          saleController
                                              .barCodeTextEditingController
                                              .clear();
                                        } else {
                                          Get.snackbar("Info",
                                              "Product added to cart !!!",
                                              snackPosition: SnackPosition.BOTTOM);
                                          cartController.addToCart(foundItem, 1);
                                          saleController
                                              .barCodeTextEditingController
                                              .clear();
                                        }
                                      } else {
                                        // Item not found, handle this case
                                        Get.snackbar("Not Found",
                                            "Product with item  code " + exp +
                                                " is not found!!!",
                                            snackPosition: SnackPosition.BOTTOM);
                                      }
                                    }
                                  }
                                  else if (exp.length >= 12) {
                                    String chackCode = exp.length > 2
                                        ? exp.substring(0, 2)
                                        : '';
                                    String productCode = exp.length > 6 ? exp
                                        .substring(
                                        2, 6) : '';
                                    String categoryCode = exp.length > 7 ? exp
                                        .substring(
                                        6, 7) : '';
                                    String weight = exp.length > 12
                                        ? exp.substring(7, 12)
                                        : '0';

                                    double kgs = double.parse(weight) / 1000;
                                    double roundedValue = double.parse(
                                        kgs.toStringAsFixed(
                                            3));
                                    if (kgs > 0) {
                                      // print(weight);
                                      // print(kgs);
                                      // print(roundedValue);
                                      var index = saleController.allProducts
                                          .indexWhere((item) =>
                                      item.item?.itemCode == productCode);
                                      if (index != -1) {
                                        ProductFullInfoModel foundItem = saleController
                                            .allProducts[index];
                                        var indexC = cartController.cartItems
                                            .indexWhere((item) =>
                                        item.product.item?.id ==
                                            foundItem.item?.id);
                                        if (indexC != -1) {
                                          // Get.snackbar("Info",
                                          //     "Product already added !!!",
                                          //     snackPosition: SnackPosition.BOTTOM);
                                          cartController.addToCart(
                                              foundItem, roundedValue);
                                          saleController
                                              .barCodeTextEditingController
                                              .clear();
                                        } else {
                                          Get.snackbar("Info",
                                              "Product added to cart !!!",
                                              snackPosition: SnackPosition.BOTTOM);
                                          cartController.addToCart(
                                              foundItem, roundedValue);
                                          saleController
                                              .barCodeTextEditingController
                                              .clear();
                                        }
                                      } else {
                                        // Item not found, handle this case
                                        Get.snackbar("Not Found",
                                            "Product with item  code " +
                                                productCode +
                                                " is not found!!!",
                                            snackPosition: SnackPosition.BOTTOM);
                                      }
                                    }
                                  }
                                }
                              },
                              validator: (value) {
                                return null;
                              },
                              onSaved: (value) {
                                // cartController.amountPaid.value = int.parse(value!); // Store as integer
                              },
                            ),
                          ),
                        ),
                        Container(
                          child: CupertinoButton(
                            minSize: 20,
                            padding: const EdgeInsets.all(0),
                            // remove button padding
                            color: CupertinoColors.white.withOpacity(0),
                            // use this to make default color to transparent
                            child: Container( // wrap the text/widget using container
                              padding: const EdgeInsets.all(10), // add padding
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.indigo,
                                  width: 2,
                                ),
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(10)), // radius as you wish
                              ),
                              child: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: const [
                                  Icon(
                                    CupertinoIcons.search, color: Colors.indigo,
                                    size: 30,),
                                  Text(" Search item",
                                    style: TextStyle(color: Colors.indigo,fontSize: 12),)
                                ],
                              ),
                            ),
                            onPressed: () {
                              // on press action
                              saleController.isSearching.value =
                              true; // Show search field
                              saleController.selectedCategory.value =
                                  BaseNameModel(
                                      id: "All Items", name: "All Items");
                              saleController.filterProducts(query: '',
                                  category: saleController.selectedCategory.value
                                      ?.id);
                            },
                          ),
                        ),
                      ],
                    );
                  }),
                ),
                SizedBox(
                  width: 5,
                ),
                Expanded(
                  child: Container(
                    decoration:
                    BoxDecoration(
                      color: Colors.pink[50],
                      border: Border.all(color: Colors.pinkAccent, width: 5.0),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Obx(() {
                      return SearchChoices.single(
                        padding: 0,
                        items: cartController.allCustomers.map((
                            CustomerModel customer) {
                          return DropdownMenuItem<CustomerModel>(
                            value: customer,
                            child: Text(customer.name ?? ''),
                          );
                        }).toList(),
                        value: cartController.selectedCustomer.value,
                        // onTap: cartController.reGetCustomers(),
                        // initial selected value if needed
                        hint: "Select Customer",
                        searchHint: "Search Customer",
                        menuBackgroundColor: Colors.pink[50],
                        searchFn: (String searchTerm,
                            List<DropdownMenuItem> items) {
                          // Filter by customer name, returning the indices of matching items
                          List<int> matches = [];
                          for (int i = 0; i < items.length; i++) {
                            CustomerModel customer = items[i]
                                .value as CustomerModel;
                            if (customer.name != null &&
                                customer.name!.toLowerCase().contains(
                                    searchTerm.toLowerCase())) {
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
                        style: TextStyle(fontSize: 15, color: Colors.black87,),
                        isExpanded: true,
                      );
                    }),
                  ),
                ),

                SizedBox(width: 3),
                IconButton(
                  icon: Icon(Icons.refresh,),
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
                    horizontal: 2.0, vertical: 2.0),
                        child:
                        Container(
                          width: screenSize ,
                            child: Obx(() {
                          return  GridView.builder(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: (saleController.categories.length/2).round(),
                              mainAxisSpacing: 10.0,
                              crossAxisSpacing: 2.0,
                              // childAspectRatio: 2.0, // Adjust aspect ratio as needed
                              mainAxisExtent: 40.0, // Adjust height of each item
                            ),
                            shrinkWrap: true,
                            itemCount: saleController.categories.length,
                            itemBuilder: (context, index) {
                              final category = saleController.categories[index];
                              return Container(
                                decoration:
                                BoxDecoration(
                                  color: saleController.isCatSelected.value && saleController.selectedCategory.value?.id == category.id
                                      ? Colors.purple
                                      : Colors.deepOrange[300],
                                  border: Border.all(
                                    color: Colors.indigo,
                                    width: 2.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    saleController.isCatSelected.value = true;
                                    saleController.selectedCategory.value = category;
                                    saleController.filterProducts(category: category.id!);
                                  },
                                  child: Center(
                                    child: Text(
                                      category.name!,
                                      style: TextStyle(fontSize: 12.0, color: Colors.black, fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        })
                        ),
              ),

              const SizedBox(height: 10),
              Expanded(child:
              Obx(() {
                return Row(
                  children: [
                    Container(
                      decoration:
                      BoxDecoration(
                        border: Border.all(color: Colors.indigo, width: 1.0),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      width: 0.6 * screenSize,
                      alignment: Alignment.topLeft,
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 1.0,
                          mainAxisSpacing: 1.0,
                          childAspectRatio: 2.0, // Adjust aspect ratio as needed
                        ),
                        itemCount: saleController.filteredProducts.length,
                        itemBuilder: (context, index) =>
                            Card(
                              color: Colors.blue[100],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: InkWell(
                                onTap: () {
                                  if (saleController.filteredProducts[index]
                                      .item?.itemType == 'SERVICE') {
                                    cartController.addToCart(
                                        saleController.filteredProducts[index],
                                        1);
                                  } else
                                  if (saleController.filteredProducts[index]
                                      .stock! > 0 ||
                                      saleController.sellNilItems) {
                                    cartController.addToCart(
                                        saleController.filteredProducts[index],
                                        1);
                                    cartController
                                        .amountPaidTextEditingController.text =
                                        cartController
                                            .totalCostInSelectedCurrency.value
                                            .toStringAsFixed(2);
                                    cartController.amountPaid.value =
                                        cartController
                                            .totalCostInSelectedCurrency.value;
                                    cartController.customerAmountPaid.value =
                                        cartController
                                            .totalCostInSelectedCurrency.value;
                                  } else {
                                    Get.snackbar("Check your stock",
                                        "Stock not available!!!",
                                        snackPosition: SnackPosition.BOTTOM);
                                  }
                                },
                                child: GridTile(
                                    header: Container(
                                      padding: EdgeInsets.all(0.0),
                                      // color: Colors.white,
                                      child: Text(
                                        saleController.filteredProducts[index]
                                            .item!
                                            .category?.name ?? '',
                                        style: TextStyle(
                                            fontSize: 14, color: Colors.black),
                                        textAlign: TextAlign.left,
                                      ),
                                    ),
                                    footer: Container(
                                      padding: EdgeInsets.all(8.0),
                                      // color: Colors.white,
                                      child: Text(
                                        "\$" + saleController
                                            .filteredProducts[index].item!
                                            .sellingPrice.toStringAsFixed(2) ??
                                            'No Name',
                                        style: TextStyle(
                                          fontSize: 14, color: Colors.black,),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),

                                    child:
                                    InkWell(
                                      borderRadius: BorderRadius.circular(8.0),
                                      splashColor: Colors.blue.withAlpha(30),
                                      child: Center(
                                        child: Text(
                                          saleController.filteredProducts[index]
                                              .item!
                                              .name ?? 'No Name',
                                          style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    )
                                ),
                              ),
                            ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Container(
                              height: 500,
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.indigo, width: 3.0),
                                        borderRadius: BorderRadius.circular(8.0),
                                      ),
                                      height: 300,
                                      child: Obx(() {
                                        if (cartController.cartItems.isEmpty) {
                                          return Center(
                                              child: Column(
                                                children: [
                                                  SizedBox(height: 30),
                                                  Text('Your cart is empty'),
                                                  SizedBox(height: 10),
                                                  IconButton(
                                                    icon: Icon(
                                                      Icons.warning_amber, size: 50,),
                                                    color: Colors.grey,
                                                    onPressed: () {},
                                                  ),
                                                ],
                                              )
                                          );
                                        }
                                        return ListView.builder(
                                          itemCount: cartController.cartItems.length,
                                          itemBuilder: (context, index) {
                                            final cartItem = cartController
                                                .cartItems[index];
                                            return Card(
                                              child: ListTile(
                                                minTileHeight: 30,
                                                title: Text(
                                                  cartItem.product.item!.name ??
                                                      'No Name',
                                                  style: TextStyle(fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.indigo,
                                                      fontStyle: FontStyle.italic)
                                                  ,),
                                                subtitle: Text('Qty: ${cartItem
                                                    .quantity} Price: \$${cartItem
                                                    .product.item!.sellingPrice
                                                    .toStringAsFixed(2)}'),
                                                trailing:
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      icon: Icon(Icons.remove),
                                                      onPressed: () =>
                                                          cartController
                                                              .decrementQuantity(
                                                              cartItem),
                                                    ),
                                                    Text("\$${cartItem.totalPrice
                                                        .toStringAsFixed(2)}",
                                                      style: TextStyle(fontSize: 22,
                                                          color: Colors.indigo,
                                                          fontWeight: FontWeight.bold),
                                                    ),
                                                    IconButton(
                                                      icon: Icon(Icons.add,
                                                        color: Colors.indigoAccent,),
                                                      onPressed: () =>
                                                          cartController
                                                              .incrementQuantity(
                                                              cartItem),
                                                    ),
                                                    IconButton(
                                                      icon: Icon(Icons.delete,
                                                        color: Colors.red,),
                                                      onPressed: () =>
                                                          cartController.removeFromCart(
                                                              cartItem),
                                                    ),
                                                  ],
                                                ),
                                                onTap: () {
                                                  // Get.to(() => CartDetailsScreen(cartItem: cartItem));
                                                },
                                              ),
                                            );
                                          },
                                        );
                                      }),
                                    ),
                                    SizedBox(height: 10),
                                    Container(
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Column(
                                                children: [
                                                  TextFormField(
                                                    controller:
                                                    cartController
                                                        .amountPaidTextEditingController,
                                                    keyboardType: const TextInputType
                                                        .numberWithOptions(
                                                        decimal: true),
                                                    inputFormatters: <TextInputFormatter>[
                                                      FilteringTextInputFormatter.allow(
                                                          RegExp(r'^\d+\.?\d{0,2}')),
                                                    ],
                                                    decoration: InputDecoration(
                                                        enabledBorder: OutlineInputBorder(
                                                          borderRadius: BorderRadius
                                                              .circular(8.0),
                                                          borderSide: const BorderSide(
                                                            color: Colors.indigo,
                                                            width: 3.0,
                                                          ),
                                                        ),
                                                        focusedBorder: OutlineInputBorder(
                                                          borderRadius: BorderRadius
                                                              .circular(8.0),
                                                          borderSide: const BorderSide(
                                                            color: Colors.pinkAccent,
                                                            width: 3.0,
                                                          ),
                                                        ),
                                                        prefixIcon: const Icon(
                                                            Icons.money),
                                                        labelText: "Amount Paid",
                                                        hintText: "Amount Paid"),
                                                    onChanged: (String val) {
                                                      if (val.isNotEmpty) {
                                                        cartController.amountPaidChange(
                                                            val);
                                                        cartController.amountPaid.value =
                                                            double.parse(val);
                                                        cartController.customerAmountPaid
                                                            .value = double.parse(val);
                                                      }
                                                    },
                                                    validator: (value) {
                                                      if (value == null ||
                                                          value.isEmpty) {
                                                        return 'Please enter an amount';
                                                      }
                                                      double enteredAmount;
                                                      try {
                                                        enteredAmount =
                                                            double.parse(value);
                                                      } catch (e) {
                                                        return 'Please enter a valid amount';
                                                      }

                                                      if (enteredAmount <
                                                          double.parse(cartController
                                                              .totalCostInSelectedCurrency
                                                              .value.toStringAsFixed(
                                                              2))) {
                                                        return 'Amount paid cannot be less than the total amount';
                                                      }
                                                      return null;
                                                    },
                                                    onSaved: (value) {
                                                      cartController.amountPaid.value =
                                                          double.parse(value!);
                                                      cartController.customerAmountPaid
                                                          .value = double.parse(value!);
                                                    },
                                                  ),
                                                  Column(
                                                    children: [
                                                      Text(
                                                        'Total: ${cartController
                                                            .selectedCurrency.value!
                                                            .symbol} ${cartController
                                                            .totalCostInSelectedCurrency
                                                            .toStringAsFixed(2)}',
                                                        style: TextStyle(fontSize: 20,
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.indigo),
                                                      ),
                                                      Text(
                                                        'Change: ${cartController
                                                            .selectedCurrency.value!
                                                            .symbol} ${cartController
                                                            .change.toStringAsFixed(2)}',
                                                        style: TextStyle(fontSize: 20,
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.orange),
                                                      ),
                                                    ],
                                                  ),
                                                  Column(
                                                    mainAxisAlignment: MainAxisAlignment
                                                        .spaceBetween,
                                                    children: [
                                                      Container(
                                                        height: 30,
                                                        child: Obx(() =>
                                                            CheckboxListTile(
                                                              title: Text(
                                                                  'Print Receipt'),
                                                              value: cartController
                                                                  .isPrintEnabled.value,
                                                              onChanged: (bool? value) {
                                                                cartController
                                                                    .isPrintEnabled
                                                                    .value =
                                                                    value ?? false;
                                                              },
                                                            )
                                                        ),
                                                      ),
                                                      Container(
                                                        // height: 30,
                                                        child: Obx(() {
                                                          if (cartController
                                                              .fiscalizeReceipt.value) {
                                                            return CheckboxListTile(
                                                              title: Text(
                                                                  'Fiscalize Receipt'),
                                                              value: cartController
                                                                  .isFiscaliseReceiptEnabled
                                                                  .value,
                                                              onChanged: (bool? value) {
                                                                cartController
                                                                    .isFiscaliseReceiptEnabled
                                                                    .value =
                                                                    value ?? false;
                                                                cartController
                                                                    .zimraFiscalizeReceipt
                                                                    .value = value!;
                                                              },
                                                            );
                                                          } else {
                                                            return Container(); // Empty container when email is not valid
                                                          }
                                                        }),
                                                      ),
                                                      Container(
                                                        // height: 30,
                                                        child: Obx(() {
                                                          if (cartController
                                                              .isCustomerEmailValid
                                                              .value) {
                                                            return CheckboxListTile(
                                                              title: Text(
                                                                  'Email Receipt'),
                                                              value: cartController
                                                                  .emailReceipt.value,
                                                              onChanged: (bool? value) {
                                                                cartController
                                                                    .emailReceipt.value =
                                                                    value ?? false;
                                                              },
                                                            );
                                                          } else {
                                                            return Container(); // Empty container when email is not valid
                                                          }
                                                        }),
                                                      ),
                                                    ],
                                                  )
                                                ],
                                              ),
                                            ),
                                          ),
                                          Expanded(child:
                                          Column(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(0.0),
                                                height: 40,
                                                child: Obx(() =>
                                                    CheckboxListTile(
                                                      title: Text('Select Multiple'),
                                                      value: saleController.multiple
                                                          .value,
                                                      onChanged: (bool? value) {
                                                        saleController.multiple.value =
                                                            value ?? false;
                                                        saleController.showMultiple
                                                            .value =
                                                            value ?? false;
                                                        if (saleController.multiple
                                                            .value == true) {
                                                          cartController
                                                              .amountPaidTextEditingController
                                                              .clear();
                                                          cartController
                                                              .amountPaidTextEditingController
                                                              .text =
                                                              0.00.toStringAsFixed(2);
                                                          cartController.amountPaid
                                                              .value = 0.00;
                                                          cartController
                                                              .customerAmountPaid.value =
                                                          0.00;
                                                        }
                                                      },
                                                    )
                                                ),
                                              ),
                                              Container(
                                                child:
                                                Obx(() {
                                                  return GridView.builder(
                                                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                                          crossAxisCount: 3),
                                                      shrinkWrap: true,
                                                      itemCount: cartController
                                                          .filteredPaymentTypesList
                                                          .length,
                                                      itemBuilder: (context, index) =>
                                                          Container(
                                                              margin: EdgeInsets.all(4.0),
                                                              child: ElevatedButton(
                                                                onPressed: () {
                                                                  var paymentType = cartController
                                                                      .filteredPaymentTypesList[index];
                                                                  saleController
                                                                      .selectedPaymentType =
                                                                      paymentType;
                                                                  if (saleController
                                                                      .multiple.value ==
                                                                      false) {
                                                                    saleController
                                                                        .selectedPaymentTypes
                                                                        .clear();
                                                                    // cartController.selectedPaymentTypes[index].amount = cartController.totalCostInSelectedCurrency.value;
                                                                  }
                                                                  if (saleController
                                                                      .selectedPaymentTypes
                                                                      .any((element) =>
                                                                  element.id ==
                                                                      paymentType.id)) {
                                                                    saleController
                                                                        .selectedPaymentTypes
                                                                        .removeWhere((
                                                                        element) =>
                                                                    element.id ==
                                                                        paymentType.id);
                                                                  }
                                                                  else {
                                                                    if (saleController
                                                                        .multiple.value ==
                                                                        false)
                                                                      paymentType.amount =
                                                                          cartController
                                                                              .totalCostInSelectedCurrency
                                                                              .value;
                                                                    saleController
                                                                        .selectedPaymentTypes
                                                                        .add(paymentType);
                                                                    cartController
                                                                        .onChangePaymentType(
                                                                        paymentType,
                                                                        saleController
                                                                            .multiple
                                                                            .value);
                                                                  }
                                                                  cartController
                                                                      .filteredPaymentTypesList
                                                                      .refresh();
                                                                  cartController
                                                                      .selectedPaymentTypes
                                                                      .refresh();
                                                                },
                                                                style: ElevatedButton
                                                                    .styleFrom(
                                                                  backgroundColor: saleController
                                                                      .selectedPaymentTypes
                                                                      .contains(
                                                                      cartController
                                                                          .filteredPaymentTypesList[index])
                                                                      ?
                                                                  Colors.pinkAccent
                                                                      : Colors.indigo,
                                                                  // backgroundColor: Colors.indigo,
                                                                  padding: EdgeInsets.all(
                                                                      8.0),
                                                                  textStyle: TextStyle(
                                                                      fontSize: 14,
                                                                      color: Colors
                                                                          .black),
                                                                ),
                                                                child: Text(cartController
                                                                    .filteredPaymentTypesList[index]
                                                                    .name ?? 'No Name',
                                                                  style: TextStyle(
                                                                      fontSize: 14,
                                                                      color: Colors
                                                                          .lightGreen[200]),),
                                                              )
                                                          )
                                                  );
                                                }),

                                              ),
                                            ],
                                          ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    Container(
                                      color: Colors.pinkAccent[50],
                                      height: saleController.showMultiple.value
                                          ? 200
                                          : 10,
                                      decoration:
                                      saleController.showMultiple.value ? BoxDecoration(
                                        border: Border.all(
                                            color: Colors.lightGreenAccent, width: 2.0),
                                        borderRadius: BorderRadius.circular(8.0),
                                      ) : BoxDecoration(),
                                      child: Obx(() {
                                        if (saleController.showMultiple.value ==
                                            false) {
                                          return Container();
                                        }
                                        else {
                                          return ListView.builder(
                                            itemCount: cartController
                                                .selectedPaymentTypes.length,
                                            itemBuilder: (context, index) {
                                              final paymentType = cartController
                                                  .selectedPaymentTypes[index];
                                              return Card(
                                                child: ListTile(

                                                  title: Text(
                                                      paymentType.name ??
                                                          'No Name',
                                                      style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                          FontWeight.bold,
                                                          color: Colors.indigo,
                                                          fontStyle:
                                                          FontStyle.italic)
                                                  ),
                                                  subtitle: Text(
                                                      'Amount: \$${paymentType.amount!
                                                          .toStringAsFixed(2)}',
                                                      style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.black54)
                                                  ),
                                                  trailing: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      ElevatedButton(
                                                        onPressed: () async {
                                                          final amount = await addAmount(
                                                              index);
                                                        }, child:
                                                      Text("Add AMount", style:
                                                      TextStyle(color: Colors.indigo,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 14),
                                                      ),
                                                        style: TextButton.styleFrom(
                                                          padding: EdgeInsets.all(8.0),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius
                                                                .circular(8.0),
                                                          ),
                                                          backgroundColor: Colors
                                                              .transparent,
                                                          // Set button color to red
                                                          foregroundColor: Colors
                                                              .black, // Set text color to red
                                                        ),

                                                      ),
                                                      IconButton(
                                                        icon: Icon(
                                                          Icons.delete,
                                                          color: Colors.red,
                                                        ),
                                                        onPressed: () {
                                                          cartController
                                                              .removePaymentMethod(
                                                              index);
                                                          saleController
                                                              .selectedPaymentTypes
                                                              .removeAt(index);
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        }
                                      }),
                                    ),

                                    Container(
                                      height: 50,
                                      width: double.infinity,
                                      // child: Positioned(
                                      //   bottom: 2.0,
                                      //   right: 2.0,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            if (cartController.cartItems.isEmpty) {
                                              Get.snackbar("Error", "Your cart is empty.",
                                                  snackPosition: SnackPosition.TOP);
                                              return;
                                            }
                                            if (cartController.selectedPaymentType
                                                .value == null ||
                                                cartController.selectedPaymentType.value!
                                                    .id == null) {
                                              Get.snackbar("Error",
                                                  "Please select a payment type.",
                                                  snackPosition: SnackPosition.TOP);
                                              return;
                                            }
                                            if (cartController.amountPaid.value <= 0 ||
                                                cartController.amountPaid.value <
                                                    cartController
                                                        .totalCostInSelectedCurrency
                                                        .value) {
                                              Get.snackbar("Error",
                                                  "Please enter a valid amount paid.",
                                                  snackPosition: SnackPosition.TOP);
                                              return;
                                            }
                                            cartController.showConfirmDialogChargeSale();
                                          },

                                          style: TextButton.styleFrom(
                                            backgroundColor: Colors.lightGreenAccent[400],
                                            // Set button color to red
                                            foregroundColor: Colors.black,
                                            // Set text color to red
                                            textStyle: TextStyle(fontSize: 18,
                                                color: Colors.white,
                                                fontWeight: FontWeight
                                                    .bold), // Set text size
                                          ),
                                          child:
                                          Text('Charge'),
                                        ),
                                      // ),
                                    ),

                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // )
                  ],
                );
              }),
              ),
            ],
          ),
        ),
      );
    }
  }


  Future<Double?> addAmount(int index) =>
      showDialog<Double>(
        context: Get.context!,
        builder: (context) {
          return AlertDialog(
            title: Text("Add Amount"),
            content:
            TextField(
              autofocus: true,
              controller: saleController.amountTextEditingController,
              decoration: InputDecoration(
                labelText: "Enter Amount",
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true),
              onChanged: (String val) {
                if (val.isNotEmpty) {
                  // cartController.amountPaidChange(val);
                  print("Amount Changed: $val");
                  print(index);
                  cartController.paymentTypeAmountPaid.value =
                      double.parse(val);
                  cartController.selectedPaymentTypes[index].amount =
                      double.parse(val);
                }
              },
            ),

            actions: [
              TextButton(
                onPressed: () {
                  saleController.amountTextEditingController.clear();
                  Get.back(); // Close dialog without adding an amount
                },
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  print("Amount: ${saleController.amountTextEditingController
                      .text}");
                  if (saleController.amountTextEditingController.text
                      .isNotEmpty) {
                    double amount = double.parse(
                        saleController.amountTextEditingController.text);
                    if (amount <= 0) {
                      Get.snackbar("Error", "Amount must be greater than zero.",
                          snackPosition: SnackPosition.TOP);
                      return;
                    }
                    cartController.amountPaid.value +=
                    cartController.selectedPaymentTypes[index].amount!;
                    cartController.customerAmountPaid.value +=
                    cartController.selectedPaymentTypes[index].amount!;
                    cartController.amountPaidTextEditingController.text =
                        cartController.amountPaid.value.toStringAsFixed(2);
                    cartController.selectedPaymentTypes.refresh();
                    saleController.amountTextEditingController.clear();
                    Get.back(); // Close the dialog after adding
                  }
                },
                child: Text("Add"),
              ),
            ],
          );
        },
      );

  getCustomerForm() {
    Get.dialog(
      AlertDialog(
        title: Text("Add New Customer"),
        content: SingleChildScrollView(
          child: Form(
            key: cartController.formKeyAddCustomer,
            // Add a GlobalKey to the form
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: cartController.nameController,
                  decoration: InputDecoration(labelText: "Name"),
                  validator: (value) {
                    if (value == null || value
                        .trim()
                        .isEmpty) {
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
              textStyle: TextStyle(
                  fontSize: 16, color: Colors.white), // Set text size
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

}



