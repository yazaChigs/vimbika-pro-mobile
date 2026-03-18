import 'dart:developer';
import 'dart:ffi';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:search_choices/search_choices.dart';
import 'package:vimbika_pos_app/src/constants/app_constants.dart';
import 'package:vimbika_pos_app/src/constants/app_routes.dart';
import 'package:vimbika_pos_app/src/features/sale/controller/cart_controller.dart';
import 'package:vimbika_pos_app/src/features/sale/controller/sale_controller.dart';
import 'package:vimbika_pos_app/src/features/sale/model/product_full_info_model.dart';
import 'package:vimbika_pos_app/src/features/sale/screen/product_description_screen.dart';
import 'package:vimbika_pos_app/src/features/sale/screen/barcode_scanner_screen.dart';
import 'package:vimbika_pos_app/src/features/sale/widget/custom_dropdown_widget.dart';
import 'package:vimbika_pos_app/src/features/sale/widget/product_list_widget.dart';
import 'package:vimbika_pos_app/src/features/sale/widget/product_tile_widget.dart';
import 'package:vimbika_pos_app/src/features/sale_receipts/controller/receipt_controller.dart';
import 'package:vimbika_pos_app/src/features/shift/controller/shift_controller.dart';
import 'package:vimbika_pos_app/src/features/ticket/controller/ticket_controller.dart';
import 'package:vimbika_pos_app/src/rear/sunmi_controller.dart';
import 'package:vimbika_pos_app/src/services/background_service.dart';
import 'package:vimbika_pos_app/src/services/printer_service.dart';
import 'package:vimbika_pos_app/src/services/sync_service.dart';
import 'package:vimbika_pos_app/src/shared/controller/inactivity_controller.dart';
import 'package:vimbika_pos_app/src/shared/models/base_name_model.dart';
import 'package:vimbika_pos_app/src/shared/models/currency_model.dart';
import 'package:vimbika_pos_app/src/shared/models/payment_type_model.dart';
import 'package:vimbika_pos_app/src/widgets/nav_drawer_widget.dart';
import 'package:vimbika_pos_app/src/widgets/badge_widget.dart';

import '../../../shared/models/customer_model.dart';
import '../../customers/controller/customer_controller.dart';

class SaleScreen extends GetView {
  var scaffoldKey = GlobalKey<ScaffoldState>();
  final SaleController saleController = Get.put(SaleController());
  final CartController cartController = Get.put(CartController());
  final CustomerController customerController = Get.put(CustomerController());
  final ShiftController shiftController = Get.put(ShiftController());
  final TicketController ticketController = Get.put(TicketController());
  final SunmiController sunmiController = Get.put(SunmiController());
  final InactivityController inactivityController =
      Get.put(InactivityController());
  final ReceiptController receiptController = Get.put(ReceiptController());
  final ScrollController _scrollController = ScrollController();

  // const Responsive({required this.mobile, required this.tablet, required this.desktop, super.key});

  late Widget mobile;
  late Widget tablet;
  double screenSize = 0.00;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 950.0;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 950.0;

  SaleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    screenSize = MediaQuery.of(context).size.width;
    String fullName =
        "${saleController.user.firstName} ${saleController.user.lastName}";
    String initials =
        saleController.user.firstName[0] + saleController.user.lastName[0];

    // Refresh shift information when sale screen is accessed
    // This ensures the correct shift is loaded for the current user
    WidgetsBinding.instance.addPostFrameCallback((_) {
      cartController.refreshShiftForCurrentUser();
      // Also refresh customers to ensure latest data is loaded
      cartController.refreshCustomers();
    });

    // Sync default payment type to saleController for highlighting
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (cartController.selectedPaymentType.value != null &&
          cartController.selectedPaymentType.value!.id != null &&
          !saleController.selectedPaymentTypes.any(
              (pt) => pt.id == cartController.selectedPaymentType.value!.id)) {
        saleController.selectedPaymentTypes
            .add(cartController.selectedPaymentType.value!);
        saleController.selectedPaymentType =
            cartController.selectedPaymentType.value!;
      }
    });

    if (isMobile(context)) {
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: inactivityController.resetInactivityTimer,
        onPanDown: (_) => inactivityController.resetInactivityTimer(),
        child: PopScope(
          canPop: false,
          child: Scaffold(
            key: scaffoldKey,
            appBar: AppBar(
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
                        padding:
                            EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          // Set the background color for the count
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          count.toString(),
                          style: TextStyle(
                              color: Colors.white, fontSize: 10), // Text color
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
                Obx(() => IconButton(
                      icon: cartController.isNfcReading.value
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.blue),
                              ),
                            )
                          : Icon(Icons.nfc),
                      onPressed: () {
                        cartController.selectCustomerByNfc();
                      },
                    )),
              ],
            ),
            drawer: NavDrawer(
                fullName: fullName,
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
                                  cartController.cartItems,
                                  "");
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.cyan,
                              padding: EdgeInsets.symmetric(vertical: 14.0),
                              textStyle: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                            child: Text(
                              cartController.cartItems.length > 0
                                  ? 'SAVE'
                                  : 'OPEN TICKETS',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16),
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
                            textStyle: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          child: Obx(() {
                            // Check if totalCostInSelectedCurrency is a number
                            final totalCost =
                                cartController.totalCostInSelectedCurrency;
                            final formattedCost = totalCost != null
                                ? totalCost.toStringAsFixed(
                                    2) // Convert to 2 decimal places
                                : '0.00';

                            return Text(
                              'CHARGE : ${cartController.selectedCurrency.value?.symbol ?? ''} $formattedCost',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16),
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
                                        saleController
                                            .searchTextEditingController
                                            .clear();
                                        saleController.isSearching.value =
                                            false; // Hide search field

                                        final allItemsCategory = saleController
                                            .categories
                                            .firstWhere(
                                          (category) =>
                                              category.id == "All Items",
                                          orElse: () =>
                                              saleController.categories.first,
                                        );
                                        saleController.selectedCategory.value =
                                            allItemsCategory;

                                        saleController.filterProducts(
                                            query: '',
                                            category: saleController
                                                .selectedCategory.value?.id);
                                      },
                                    ),
                                  ),
                                  onChanged: (query) {
                                    // saleController.filterProducts(query);
                                    saleController.filterProducts(
                                        query: query,
                                        category: saleController
                                            .selectedCategory
                                            .value
                                            ?.name); // Filter based on search query and category
                                  },
                                ),
                              )
                            : Expanded(
                                child: DropdownButton<BaseNameModel>(
                                  value: saleController.selectedCategory.value,
                                  isExpanded: true,
                                  // Make the dropdown take full width
                                  items:
                                      saleController.categories.map((category) {
                                    return DropdownMenuItem<BaseNameModel>(
                                      value: category,
                                      child: Text(category.name!),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    saleController.isCatSelected.value = true;
                                    saleController.selectedCategory.value =
                                        value!;
                                    // saleController.filterProducts(value.name!);
                                    saleController.filterProducts(
                                        category: value
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
                              saleController.filterProducts(
                                  query: '',
                                  category: saleController
                                      .selectedCategory.value?.id);
                            },
                          ),
                      ],
                    );
                  }),
                ),
                const SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller:
                              saleController.barCodeTextEditingController,
                          autofocus: true,
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
                            prefixIcon: IconButton(
                              icon: const Icon(Icons.camera_alt),
                              onPressed: () {
                                Get.toNamed(AppRoutes.BARCODE_SCANNER);
                              },
                            ),
                            labelText: "Bar Code",
                            hintText: "Bar Code",
                          ),
                          onChanged: saleController.onBarcodeChanged,
                          validator: (value) {
                            return null;
                          },
                          onSaved: (value) {
                            // cartController.amountPaid.value = int.parse(value!);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          Get.toNamed(AppRoutes.BARCODE_SCANNER);
                        },
                        icon: const Icon(Icons.camera_alt),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(12),
                        ),
                        tooltip: 'Scan Barcode',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Obx(() {
                    return Container(
                      child: saleController.filteredProducts.isEmpty
                          ? Center(
                              child: LoadingAnimationWidget.discreteCircle(
                                secondRingColor: const Color(0xFF98EF17),
                                color: const Color(0xFFEA3799),
                                thirdRingColor: const Color(0xFFF14405),
                                size: 200,
                              ),
                            )
                          : ListView.builder(
                              itemCount: saleController.filteredProducts.length,
                              itemBuilder: (context, index) {
                                final product =
                                    saleController.filteredProducts[index];
                                String name = product.item!.name ?? 'no name';
                                String brand = product.item!.brand?.name ?? '';
                                String fullName = "${name}  ${brand}";
                                String category =
                                    product.item!.category?.name ?? '';
                                String itemName = fullName + ' ' + category;
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Card(
                                      child: ListTile(
                                    tileColor: context.theme.colorScheme.primaryContainer,
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
                                    subtitle: Text('Available units ' +
                                        '(' +
                                        product.stock!.toInt().toString() +
                                        ')'),
                                    trailing: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                            "\$${product.item!.sellingPrice.toStringAsFixed(2)}"),
                                        SizedBox(
                                          height:
                                              4, // Space between price and button
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
                                  )),
                                );
                              },
                            ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: inactivityController.resetInactivityTimer,
        onPanDown: (_) => inactivityController.resetInactivityTimer(),
        child: PopScope(
          canPop: false,
          child: Scaffold(
            resizeToAvoidBottomInset: true,
            key: scaffoldKey,
            appBar: AppBar(
              // Same as your app theme
              elevation: 0,
              title: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color:
                            context.theme.colorScheme.onSecondaryFixedVariant,
                        width: 2.0,
                      ),
                      color: context.theme.colorScheme.inversePrimary,
                      // Set the background color for the count
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(children: [
                      GestureDetector(
                        onTap: () {
                          // Define the action when "Ticket" is clicked
                          Get.toNamed(AppRoutes.TICKET_LIST);
                        },
                        child: Text(
                          'Ticket',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          // Define the action when the count is clicked
                          Get.toNamed(AppRoutes.TICKET_LIST);
                        },
                        child: Obx(() {
                          final count = ticketController.openedTicketsCount;
                          return Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              // Set the background color for the count
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              count.toString(),
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10), // Text color
                            ),
                          );
                        }),
                      ),
                    ]),
                  ),
                  SizedBox(width: 6),
                  Expanded(child: Container(child: Obx(() {
                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cartController.currencyList.length>0 ? cartController.currencyList.length : 1,
                        mainAxisSpacing: 10.0,
                        crossAxisSpacing: 2.0,
                        // childAspectRatio: 2.0, // Adjust aspect ratio as needed
                        mainAxisExtent: 40.0, // Adjust height of each item
                      ),
                      // scrollDirection: Axis.horizontal,
                      physics: PageScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: cartController.currencyList.length,
                      itemBuilder: (context, index) {
                        final currency = cartController.currencyList[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: cartController.isCurrencySelected.value &&
                                    cartController.selectedCurrency.value?.id ==
                                        currency.id
                                ? context.theme.colorScheme.primary
                                : context.theme.colorScheme.surface,
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
                                style: TextStyle(
                                    fontSize: 12.0,
                                    color: context.theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }))),
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
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          borderSide: BorderSide(
                                            color: Colors.indigo,
                                            width: 2.0,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          borderSide: BorderSide(
                                            color: context
                                                .theme.colorScheme.secondary,
                                            width: 2.0,
                                          ),
                                        ),
                                        prefixIcon: IconButton(
                                          icon: Icon(Icons.close),
                                          onPressed: () {
                                            saleController
                                                .searchTextEditingController
                                                .clear();
                                            saleController.isSearching.value =
                                                false; // Hide search field

                                            final allItemsCategory =
                                                saleController.categories
                                                    .firstWhere(
                                              (category) =>
                                                  category.id == "All Items",
                                              orElse: () => saleController
                                                  .categories.first,
                                            );
                                            saleController.selectedCategory
                                                .value = allItemsCategory;

                                            saleController.filterProducts(
                                                query: '',
                                                category: saleController
                                                    .selectedCategory
                                                    .value
                                                    ?.id);
                                          },
                                        ),
                                      ),
                                      onChanged: (query) {
                                        // saleController.filterProducts(query);
                                        saleController.filterProducts(
                                            query: query,
                                            category: saleController
                                                .selectedCategory
                                                .value
                                                ?.name); // Filter based on search query and category
                                      },
                                    ),
                                  ),
                                )
                              : Expanded(
                                  child: Container(
                                    width: screenSize * 0.4 * 0.7,
                                    child: TextFormField(
                                      controller: saleController
                                          .barCodeTextEditingController,
                                      decoration: InputDecoration(
                                        iconColor: Colors.indigo,
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          borderSide: const BorderSide(
                                            color: Colors.indigo,
                                            width: 2.0,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          borderSide: BorderSide(
                                            color: context
                                                .theme.colorScheme.primary,
                                            width: 2.0,
                                          ),
                                        ),
                                        prefixIcon: IconButton(
                                          icon: const Icon(Icons.camera_alt),
                                          onPressed: () {
                                            Get.toNamed(
                                                AppRoutes.BARCODE_SCANNER);
                                          },
                                        ),
                                        labelText: "Bar Code",
                                        hintText: "Bar Code",
                                      ),
                                      onChanged: saleController.onBarcodeChanged,
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
                              child: Container(
                                // wrap the text/widget using container
                                padding:
                                    const EdgeInsets.all(10), // add padding
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.indigo,
                                    width: 2,
                                  ),
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(
                                          10)), // radius as you wish
                                ),
                                child: Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: const [
                                    Icon(
                                      CupertinoIcons.search,
                                      color: Colors.indigo,
                                      size: 30,
                                    ),
                                    Text(
                                      " Search item",
                                      style: TextStyle(
                                          color: Colors.indigo, fontSize: 12),
                                    )
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
                                saleController.filterProducts(
                                    query: '',
                                    category: saleController
                                        .selectedCategory.value?.id);
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
                      decoration: BoxDecoration(
                        color: context.theme.colorScheme.surfaceBright,
                        border: Border.all(
                            color: context.theme.colorScheme.primary,
                            width: 5.0),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Obx(() {
                        // Create a stable snapshot of customers to prevent race conditions
                        final List<CustomerModel> customersSnapshot =
                            List.from(cartController.allCustomers);

                        return SearchChoices.single(
                          padding: 0,
                          items:
                              customersSnapshot.map((CustomerModel customer) {
                            return DropdownMenuItem<CustomerModel>(
                              value: customer,
                              child: Text(
                                customer.name ?? '',
                                style: TextStyle(
                                    fontSize: 15,
                                    color: context.theme.colorScheme.onSurface),
                              ),
                            );
                          }).toList(),
                          value: cartController.selectedCustomer.value,
                          // onTap: cartController.refreshCustomers(),
                          // initial selected value if needed
                          hint: "🔍 Search or Select Customer",
                          searchHint:
                              "Type customer name, phone, ID, customer ID, or account number...",
                          menuBackgroundColor:
                              context.theme.colorScheme.surface,
                          searchFn: (String searchTerm,
                              List<DropdownMenuItem> items) {
                            // Enhanced search: search by name, phone, ID, customer ID, or account number
                            // Add bounds checking to prevent RangeError
                            List<int> matches = [];
                            if (items.isEmpty || searchTerm.isEmpty) {
                              // If empty search term, return all indices
                              if (searchTerm.isEmpty) {
                                for (int i = 0; i < items.length; i++) {
                                  matches.add(i);
                                }
                              }
                              return matches;
                            }

                            for (int i = 0; i < items.length; i++) {
                              // Safety check: ensure index is valid
                              if (i >= items.length) break;

                              try {
                                final item = items[i];
                                if (item.value == null) continue;

                                CustomerModel customer =
                                    item.value as CustomerModel;

                                bool nameMatch = customer.name != null &&
                                    customer.name!
                                        .toLowerCase()
                                        .contains(searchTerm.toLowerCase());
                                bool phoneMatch =
                                    customer.mobilePhone != null &&
                                        customer.mobilePhone!
                                            .toLowerCase()
                                            .contains(searchTerm.toLowerCase());
                                bool idMatch = customer.id != null &&
                                    customer.id!
                                        .toLowerCase()
                                        .contains(searchTerm.toLowerCase());
                                bool customerIdMatch =
                                    customer.customerId != null &&
                                        customer.customerId!
                                            .toLowerCase()
                                            .contains(searchTerm.toLowerCase());
                                bool accountNumberMatch =
                                    customer.accountNumber != null &&
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
                              } catch (e) {
                                // Skip invalid items to prevent crashes
                                print(
                                    "Error processing customer at index $i: $e");
                                continue;
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
                          onChanged: (selected) {
                            if (selected is CustomerModel) {
                              cartController.onCustomerChange(selected);
                            } else {
                              cartController.onCustomerChange(null);
                            }
                          },
                          underline: SizedBox.shrink(),
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                          isExpanded: true,
                        );
                      }),
                    ),
                  ),
                  SizedBox(width: 3),
                  IconButton(
                    icon: Icon(
                      Icons.refresh,
                      color: context.theme.colorScheme.primary,
                      size: 30,
                    ),
                    onPressed: () {
                      saleController.syncData();
                      Get.snackbar(
                        "Syncing",
                        "Refreshing customer data...",
                        snackPosition: SnackPosition.TOP,
                        backgroundColor: Colors.blue,
                        colorText: Colors.white,
                        duration: Duration(seconds: 1),
                      );
                    },
                    tooltip: "Refresh Customer Data",
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.camera_alt,
                      color: Colors.orange,
                      size: 30,
                    ),
                    onPressed: () {
                      // Open customer scanner
                      Get.toNamed(AppRoutes.BARCODE_SCANNER,
                          arguments: {'scanMode': 'customer'});
                    },
                    tooltip: "Scan Customer Loyalty Card with Camera",
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
                  icon: Icon(
                    Icons.person_add,
                    color: context.theme.colorScheme.primary,
                    size: 30,
                  ),
                  onPressed: () {
                    Get.toNamed(AppRoutes.CUSTOMER_FORM);
                  },
                ),
              ],
            ),
            drawer: NavDrawer(
                fullName: fullName,
                mobileNumber: saleController.user.mobilePhone ?? "",
                nameInitials: initials),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 2.0, vertical: 2.0),
                  child: SizedBox(
                    height: 50,
                    width: screenSize,
                    child: Obx(() {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          ListView.builder(
                            controller: _scrollController,
                            scrollDirection: Axis.horizontal,
                            shrinkWrap: true,
                            itemCount: saleController.categories.length,
                            itemBuilder: (context, index) {
                              final category = saleController.categories[index];
                              final isSelected = saleController
                                      .isCatSelected.value &&
                                  saleController.selectedCategory.value?.id ==
                                      category.id;
                              return Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4.0),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context)
                                          .colorScheme
                                          .inversePrimary,
                                  border: Border.all(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    width: 2.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    saleController.isCatSelected.value = true;
                                    saleController.selectedCategory.value =
                                        category;
                                    saleController.filterProducts(
                                        category: category.id!);
                                    saleController.categories.refresh();
                                  },
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16.0),
                                      child: Text(
                                        category.name!,
                                        style: TextStyle(
                                            fontSize: 12.0,
                                            color: isSelected
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .onPrimary
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                            fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          Positioned(
                            left: 0,
                            top: -15,
                            bottom: 0,
                            child: IconButton(
                              icon: Icon(
                                Icons.arrow_back_ios,
                                color: Theme.of(context)
                                    .colorScheme
                                    .inverseSurface,
                                size: 60,
                              ),
                              onPressed: () {
                                _scrollController.animateTo(
                                  _scrollController.offset - 500,
                                  duration: Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: -15,
                            bottom: 0,
                            child: IconButton(
                              icon: Icon(
                                Icons.arrow_forward_ios,
                                color: Theme.of(context)
                                    .colorScheme
                                    .inverseSurface,
                                size: 60,
                              ),
                              onPressed: () {
                                _scrollController.animateTo(
                                  _scrollController.offset + 500,
                                  duration: Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Obx(() {
                    return Row(
                      children: [
                        Expanded(
                          flex: 50,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: context.theme.colorScheme.primary,
                                  width: 1.0),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            alignment: Alignment.topLeft,
                            child: saleController.filteredProducts.isEmpty
                                ? Center(
                                    child:
                                        LoadingAnimationWidget.discreteCircle(
                                      secondRingColor: const Color(0xFF98EF17),
                                      color: const Color(0xFFEA3799),
                                      thirdRingColor: const Color(0xFFF14405),
                                      size: 200,
                                    ),
                                  )
                                : GridView.builder(
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 4,
                                      crossAxisSpacing: 1.0,
                                      mainAxisSpacing: 1.0,
                                      childAspectRatio:
                                          1.7, // Adjust aspect ratio as needed
                                    ),
                                    itemCount:
                                        saleController.filteredProducts.length,
                                    itemBuilder: (context, index) =>
                                        ProductTileWidget(
                                      productName: saleController
                                          .filteredProducts[index].item!.name!,
                                      price: saleController
                                          .filteredProducts[index]
                                          .item!
                                          .sellingPrice,
                                      quantity: saleController
                                          .filteredProducts[index].stock!,
                                      onTap: () {
                                        if (saleController
                                                .filteredProducts[index]
                                                .item
                                                ?.itemType ==
                                            'SERVICE') {
                                          cartController.addToCart(
                                              saleController
                                                  .filteredProducts[index],
                                              1);
                                          cartController
                                                  .amountPaidTextEditingController
                                                  .text =
                                              cartController
                                                  .totalCostInSelectedCurrency
                                                  .value
                                                  .toStringAsFixed(2);
                                          cartController.hasAmountText.value =
                                              true;
                                          cartController.amountPaid.value =
                                              cartController
                                                  .totalCostInSelectedCurrency
                                                  .value;
                                          cartController
                                                  .customerAmountPaid.value =
                                              cartController
                                                  .totalCostInSelectedCurrency
                                                  .value;
                                        } else if (saleController
                                                    .filteredProducts[index]
                                                    .stock! >
                                                0 ||
                                            saleController.sellNilItems) {
                                          print(saleController
                                              .filteredProducts[index]
                                              .item!
                                              .name);
                                          cartController.addToCart(
                                              saleController
                                                  .filteredProducts[index],
                                              1);
                                          cartController
                                                  .amountPaidTextEditingController
                                                  .text =
                                              cartController
                                                  .totalCostInSelectedCurrency
                                                  .value
                                                  .toStringAsFixed(2);
                                          cartController.hasAmountText.value =
                                              true;
                                          cartController.amountPaid.value =
                                              cartController
                                                  .totalCostInSelectedCurrency
                                                  .value;
                                          cartController
                                                  .customerAmountPaid.value =
                                              cartController
                                                  .totalCostInSelectedCurrency
                                                  .value;
                                        } else {
                                          Get.snackbar("Check your stock",
                                              "Stock not available!!!",
                                              snackPosition:
                                                  SnackPosition.BOTTOM);
                                        }
                                      },
                                    ),
                                  ),
                          ),
                        ),
                        Expanded(
                          flex: 50,
                          child: Container(
                            // height: 500,
                            child: Row(
                              // mainAxisAlignment: MainAxisAlignment.start,
                              // mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      alignment: Alignment.topCenter,
                                      width: 0.28 * screenSize,
                                      height: double.infinity,
                                      child: Obx(() {
                                        if (cartController.cartItems.isEmpty) {
                                          return Center(
                                              child: Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: context.theme
                                                      .colorScheme.primary,
                                                  width: 3.0),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            child: Column(
                                              children: [
                                                SizedBox(height: 30),
                                                Text('Your cart is empty'),
                                                SizedBox(height: 10),
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.warning_amber,
                                                    size: 50,
                                                  ),
                                                  color: Colors.grey,
                                                  onPressed: () {},
                                                ),
                                              ],
                                            ),
                                          ));
                                        }
                                        return Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                    color: context.theme
                                                        .colorScheme.primary,
                                                    width: 3.0),
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                              ),
                                              height: 490,
                                              child: ListView.builder(
                                                itemCount: cartController
                                                    .cartItems.length,
                                                itemBuilder: (context, index) {
                                                  final cartItem =
                                                      cartController
                                                          .cartItems[index];
                                                  return Card(
                                                    child: ListTile(
                                                      contentPadding:
                                                          EdgeInsets.zero,
                                                      minTileHeight: 25,
                                                      tileColor: context
                                                          .theme
                                                          .colorScheme
                                                          .surfaceBright,
                                                      title: Text(
                                                        cartItem.product.item!
                                                                .name ??
                                                            'No Name',
                                                        style: TextStyle(
                                                            fontSize: 13,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: context
                                                                .theme
                                                                .colorScheme
                                                                .primary,
                                                            fontStyle: FontStyle
                                                                .italic),
                                                      ),
                                                      subtitle: Text(
                                                        style: TextStyle(fontWeight:cartItem.quantity>1 ? FontWeight.bold : FontWeight.normal),
                                                          'Qty: ${cartItem.quantity} Price: \$${cartItem.product.item!.sellingPrice.toStringAsFixed(2)} \n '
                                                          '${cartItem.notes}'),
                                                      trailing: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            "\$${cartItem.totalPrice.toStringAsFixed(2)}",
                                                            style: TextStyle(
                                                                fontSize: 18,
                                                                color: context
                                                                    .theme
                                                                    .colorScheme
                                                                    .primary,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold),
                                                          ),
                                                          PopupMenuButton(
                                                              onSelected:
                                                                  (result) {},
                                                              itemBuilder:
                                                                  (context) => [
                                                                        PopupMenuItem(
                                                                          child: ListTile(
                                                                              leading: Icon(
                                                                                Icons.remove,
                                                                                color: Colors.deepOrange,
                                                                              ),
                                                                              title: Text("Reduce Qty")),
                                                                          value:
                                                                              0,
                                                                          onTap:
                                                                              () {
                                                                            cartController.decrementQuantity(cartItem);
                                                                          },
                                                                        ),
                                                                        PopupMenuItem(
                                                                          child: ListTile(
                                                                              leading: Icon(Icons.add, color: Colors.lightBlue),
                                                                              title: Text("Increase Qty")),
                                                                          value:
                                                                              0,
                                                                          onTap:
                                                                              () {
                                                                            cartController.incrementQuantity(cartItem);
                                                                          },
                                                                        ),
                                                                        PopupMenuItem(
                                                                          child: ListTile(
                                                                              leading: Icon(Icons.delete, color: Colors.redAccent),
                                                                              title: Text("Delete item")),
                                                                          value:
                                                                              0,
                                                                          onTap:
                                                                              () {
                                                                            cartController.removeFromCart(cartItem);
                                                                          },
                                                                        ),
                                                                        PopupMenuItem(
                                                                          child: ListTile(
                                                                              leading: Icon(Icons.arrow_downward, color: Colors.redAccent),
                                                                              title: Text("Add Discount")),
                                                                          value:
                                                                              0,
                                                                          onTap:
                                                                              () async {
                                                                            // bool authenticated = await SyncService().showAuthenticationDialog(context);
                                                                            // if(authenticated)
                                                                            addDiscount(index);
                                                                          },
                                                                        ),
                                                                        PopupMenuItem(
                                                                          child: ListTile(
                                                                              leading: Icon(Icons.note_alt, color: Colors.green),
                                                                              title: Text("Add notes")),
                                                                          value:
                                                                              0,
                                                                          onTap:
                                                                              () {
                                                                            addNotes(index);
                                                                          },
                                                                        ),
                                                                        PopupMenuItem(
                                                                          child: ListTile(
                                                                              leading: Icon(Icons.scatter_plot, color: Colors.lightBlue),
                                                                              title: Text("Add breakage")),
                                                                          value:
                                                                              0,
                                                                          onTap:
                                                                              () {
                                                                            cartItem.breakage =
                                                                                true;
                                                                            cartController.cartItems.refresh();
                                                                            cartController.calculateTotalAmounts(cartController.cartItems);
                                                                          },
                                                                        ),
                                                                      ])
                                                        ],
                                                      ),
                                                      onTap: () {
                                                        // Get.to(() => CartDetailsScreen(cartItem: cartItem));
                                                      },
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                            Container(
                                              width: double.infinity,
                                              child: Row(
                                                children: [
                                                  if (cartController
                                                      .isKOTEnaabled.isTrue)
                                                    Expanded(
                                                      child: ElevatedButton(
                                                        onPressed: () {
                                                          if (cartController
                                                              .cartItems
                                                              .isNotEmpty) {
                                                            cartController
                                                                .printQuickTicket();
                                                          }
                                                        },
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          backgroundColor:
                                                              Colors
                                                                  .orangeAccent,
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                                  vertical:
                                                                      14.0),
                                                          textStyle: TextStyle(
                                                              fontSize: 18,
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                        child: Text(
                                                          'PRINT KOT',
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 18),
                                                        ),
                                                      ),
                                                    ),
                                                  SizedBox(width: 5),
                                                  Expanded(
                                                    child: ElevatedButton.icon(
                                                      onPressed: ticketController
                                                              .isPerformingTicketAction
                                                              .value
                                                          ? null
                                                          : () {
                                                              // ticketController.getTickets();
                                                              if (!saleController
                                                                  .saveTicketClicked
                                                                  .value) {
                                                                saleController
                                                                    .saveTicketClicked
                                                                    .value = true;
                                                                ticketController.debouncedTicketActionButton(
                                                                    cartController
                                                                        .selectedCurrency
                                                                        .value!,
                                                                    cartController
                                                                        .cartItems,
                                                                    cartController.selectedCustomer.value!.name !=
                                                                            "WalkIn"
                                                                        ? cartController
                                                                            .selectedCustomer
                                                                            .value!
                                                                            .name
                                                                            .toString()
                                                                        : "Table ${ticketController.openedTicketsCount + 1}");
                                                                ticketController
                                                                        .openedTicketsCount -
                                                                    1;
                                                                saleController
                                                                    .saveTicketClicked
                                                                    .value = false;
                                                              }
                                                            },
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            ticketController
                                                                    .isPerformingTicketAction
                                                                    .value
                                                                ? Colors.grey
                                                                : context
                                                                    .theme
                                                                    .colorScheme
                                                                    .primary,
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                                vertical: 14.0),
                                                        textStyle: TextStyle(
                                                            fontSize: 18,
                                                            color: context
                                                                .theme
                                                                .colorScheme
                                                                .primary,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                      icon: Icon(
                                                        Icons.save_as,
                                                        color: context
                                                            .theme
                                                            .colorScheme
                                                            .surface,
                                                        size: 30,
                                                      ),
                                                      label: Obx(() => Text(
                                                            ticketController
                                                                    .isPerformingTicketAction
                                                                    .value
                                                                ? 'SAVING...'
                                                                : 'SAVE',
                                                            style: TextStyle(
                                                                color: context
                                                                    .theme
                                                                    .colorScheme
                                                                    .surface,
                                                                fontSize: 18),
                                                          )),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      }),
                                    ),
                                  ],
                                ),
                                Container(
                                  alignment: Alignment.topRight,
                                  width: 0.22 * screenSize,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        height: 490,
                                        child: ListView(
                                          shrinkWrap: true,
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Column(
                                                children: [
                                                  // Quick amount buttons for tablet view
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child:
                                                            _buildQuickAmountButton(
                                                          context,
                                                          '0.5',
                                                          0.5,
                                                          cartController,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Expanded(
                                                        child:
                                                            _buildQuickAmountButton(
                                                          context,
                                                          '1',
                                                          1.0,
                                                          cartController,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Expanded(
                                                        child:
                                                            _buildQuickAmountButton(
                                                          context,
                                                          '2',
                                                          2.0,
                                                          cartController,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Expanded(
                                                        child:
                                                            _buildQuickAmountButton(
                                                          context,
                                                          '5',
                                                          5.0,
                                                          cartController,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Expanded(
                                                        child:
                                                            _buildQuickAmountButton(
                                                          context,
                                                          '10',
                                                          10.0,
                                                          cartController,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Expanded(
                                                        child:
                                                            _buildQuickAmountButton(
                                                          context,
                                                          '20',
                                                          20.0,
                                                          cartController,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  TextFormField(
                                                    controller: cartController
                                                        .amountPaidTextEditingController,
                                                    keyboardType:
                                                        const TextInputType
                                                            .numberWithOptions(
                                                            decimal: true),
                                                    inputFormatters: <TextInputFormatter>[
                                                      FilteringTextInputFormatter
                                                          .allow(RegExp(
                                                              r'^\d+\.?\d{0,2}')),
                                                    ],
                                                    decoration: InputDecoration(
                                                        enabledBorder:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      8.0),
                                                          borderSide:
                                                              BorderSide(
                                                            color: context
                                                                .theme
                                                                .colorScheme
                                                                .primary,
                                                            width: 3.0,
                                                          ),
                                                        ),
                                                        focusedBorder:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      8.0),
                                                          borderSide:
                                                              const BorderSide(
                                                            color: Colors
                                                                .pinkAccent,
                                                            width: 3.0,
                                                          ),
                                                        ),
                                                        prefixIcon: const Icon(
                                                            Icons.money),
                                                        suffixIcon: Obx(
                                                          () => cartController
                                                                  .hasAmountText
                                                                  .value
                                                              ? IconButton(
                                                                  icon: const Icon(
                                                                      Icons
                                                                          .clear,
                                                                      color: Colors
                                                                          .grey),
                                                                  onPressed:
                                                                      () {
                                                                    cartController
                                                                        .clearAmountPaid();
                                                                    FocusScope.of(
                                                                            context)
                                                                        .unfocus();
                                                                  },
                                                                )
                                                              : const SizedBox
                                                                  .shrink(),
                                                        ),
                                                        labelText:
                                                            "Amount Paid",
                                                        hintText:
                                                            "Amount Paid"),
                                                    onTap: () {
                                                      cartController.activeInput
                                                          .value = 'amountPaid';
                                                    },
                                                    onChanged: (String val) {
                                                      cartController
                                                              .hasAmountText
                                                              .value =
                                                          val.isNotEmpty;
                                                      if (val.isNotEmpty) {
                                                        cartController
                                                            .amountPaidChange(
                                                                val);
                                                        cartController
                                                                .amountPaid
                                                                .value =
                                                            double.parse(val);
                                                        cartController
                                                                .customerAmountPaid
                                                                .value =
                                                            double.parse(val);
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
                                                              .value
                                                              .toStringAsFixed(
                                                                  2))) {
                                                        return 'Amount paid cannot be less than the total amount';
                                                      }
                                                      return null;
                                                    },
                                                    onSaved: (value) {
                                                      cartController.amountPaid
                                                              .value =
                                                          double.parse(value!);
                                                      cartController
                                                              .customerAmountPaid
                                                              .value =
                                                          double.parse(value!);
                                                    },
                                                  ),
                                                  Obx(() {
                                                    // Hide total and change displays when "Add to Account" button is enabled
                                                    bool isAddToAccountMode =
                                                        cartController
                                                                    .amountPaid
                                                                    .value >
                                                                0 &&
                                                            cartController
                                                                .cartItems
                                                                .isEmpty &&
                                                            (cartController
                                                                    .selectedCustomer
                                                                    .value
                                                                    ?.isLoyalCustomer ??
                                                                false);

                                                    if (isAddToAccountMode) {
                                                      return SizedBox.shrink();
                                                    }

                                                    return SingleChildScrollView(
                                                      scrollDirection:
                                                          Axis.horizontal,
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceEvenly,
                                                        children: [
                                                          Text(
                                                            'Total: ',
                                                            style: TextStyle(
                                                              fontSize: 15,
                                                            ),
                                                          ),
                                                          Text(
                                                            '${cartController.selectedCurrency.value!.symbol} ${cartController.totalCostInSelectedCurrency.toStringAsFixed(2)}',
                                                            style: TextStyle(
                                                                fontSize: 20,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .indigo),
                                                          ),
                                                          cartController
                                                                      .change >
                                                                  0
                                                              ? Text(
                                                                  'Change: ',
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        15,
                                                                  ),
                                                                )
                                                              : SizedBox
                                                                  .shrink(),
                                                          cartController
                                                                      .change >
                                                                  0
                                                              ? Text(
                                                                  '${cartController.selectedCurrency.value!.symbol} ${cartController.change.toStringAsFixed(2)}',
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          20,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: Colors
                                                                          .orange),
                                                                )
                                                              : SizedBox
                                                                  .shrink(),
                                                        ],
                                                      ),
                                                    );
                                                  }),
                                                  Obx(() {
                                                    // Hide change to account and tip inputs when "Add to Account" button is enabled
                                                    bool isAddToAccountMode =
                                                        cartController
                                                                    .amountPaid
                                                                    .value >
                                                                0 &&
                                                            cartController
                                                                .cartItems
                                                                .isEmpty &&
                                                            (cartController
                                                                    .selectedCustomer
                                                                    .value
                                                                    ?.isLoyalCustomer ??
                                                                false);

                                                    return Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceAround,
                                                      children: [
                                                        // Change to Account input - hide when Add to Account button is enabled
                                                        !isAddToAccountMode &&
                                                                cartController
                                                                        .selectedCustomer
                                                                        .value!
                                                                        .isLoyalCustomer ==
                                                                    true
                                                            ? Expanded(
                                                                flex: 3,
                                                                child:
                                                                    TextField(
                                                                  onTap: () {
                                                                    cartController
                                                                            .activeInput
                                                                            .value =
                                                                        'amtToAcc';
                                                                  },
                                                                  onChanged:
                                                                      (String
                                                                          val) {
                                                                    cartController
                                                                        .amtToAccChange(
                                                                            val);
                                                                  },
                                                                  controller:
                                                                      cartController
                                                                          .amtToAccTextEditingController,
                                                                  keyboardType: const TextInputType
                                                                      .numberWithOptions(
                                                                      decimal:
                                                                          true),
                                                                  decoration: InputDecoration(
                                                                      enabledBorder: OutlineInputBorder(
                                                                        borderRadius:
                                                                            BorderRadius.circular(8.0),
                                                                        borderSide:
                                                                            const BorderSide(
                                                                          color:
                                                                              Colors.redAccent,
                                                                          width:
                                                                              2.0,
                                                                        ),
                                                                      ),
                                                                      focusedBorder: OutlineInputBorder(
                                                                        borderRadius:
                                                                            BorderRadius.circular(8.0),
                                                                        borderSide:
                                                                            const BorderSide(
                                                                          color:
                                                                              Colors.redAccent,
                                                                          width:
                                                                              2.0,
                                                                        ),
                                                                      ),
                                                                      prefixIcon: const Icon(Icons.monetization_on_outlined),
                                                                      labelText: "Change TO Acc",
                                                                      hintText: "Change TO Acc",
                                                                      suffixIcon: cartController.amtToAccTextEditingController.text.isNotEmpty
                                                                          ? IconButton(
                                                                              icon: const Icon(Icons.clear),
                                                                              onPressed: () {
                                                                                cartController.amtToAccTextEditingController.clear();
                                                                                cartController.amtToAccChange("0");
                                                                                cartController.activeInput.value = 'none';
                                                                              },
                                                                            )
                                                                          : null),
                                                                ),
                                                              )
                                                            : SizedBox(),
                                                        // Tip input - hide when Add to Account button is enabled
                                                        !isAddToAccountMode &&
                                                                (cartController
                                                                        .amountPaid >
                                                                    cartController
                                                                        .totalCostInSelectedCurrency
                                                                        .value)
                                                            ? Expanded(
                                                                flex: 3,
                                                                child:
                                                                    TextField(
                                                                  onTap: () {
                                                                    cartController
                                                                        .activeInput
                                                                        .value = 'tip';
                                                                  },
                                                                  onChanged:
                                                                      (String
                                                                          val) {
                                                                    cartController
                                                                        .tipAmountChange(
                                                                            val);
                                                                  },
                                                                  controller:
                                                                      cartController
                                                                          .tipAmtTextEditingController,
                                                                  keyboardType: const TextInputType
                                                                      .numberWithOptions(
                                                                      decimal:
                                                                          true),
                                                                  decoration: InputDecoration(
                                                                      enabledBorder: OutlineInputBorder(
                                                                        borderRadius:
                                                                            BorderRadius.circular(8.0),
                                                                        borderSide:
                                                                            const BorderSide(
                                                                          color:
                                                                              Colors.green,
                                                                          width:
                                                                              2.0,
                                                                        ),
                                                                      ),
                                                                      focusedBorder: OutlineInputBorder(
                                                                        borderRadius:
                                                                            BorderRadius.circular(8.0),
                                                                        borderSide:
                                                                            const BorderSide(
                                                                          color:
                                                                              Colors.green,
                                                                          width:
                                                                              2.0,
                                                                        ),
                                                                      ),
                                                                      prefixIcon: const Icon(Icons.monetization_on_sharp),
                                                                      labelText: "Tip Amt",
                                                                      hintText: "Tip amt",
                                                                      suffixIcon: cartController.tipAmtTextEditingController.text.isNotEmpty
                                                                          ? IconButton(
                                                                              icon: const Icon(Icons.clear),
                                                                              onPressed: () {
                                                                                cartController.tipAmtTextEditingController.clear();
                                                                                cartController.tipAmountChange("0");
                                                                                cartController.activeInput.value = 'none';
                                                                              },
                                                                            )
                                                                          : null),
                                                                ),
                                                              )
                                                            : SizedBox(),
                                                      ],
                                                    );
                                                  }),
                                                  // : SizedBox(),
                                                  cartController
                                                              .selectedCustomer
                                                              .value!
                                                              .isLoyalCustomer ==
                                                          true
                                                      ? Row(
                                                          children: [
                                                            Text(
                                                              "ACC Bal:",
                                                              style: TextStyle(
                                                                  fontSize: 20,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Colors
                                                                      .red),
                                                            ),
                                                            Text(
                                                              cartController
                                                                  .selectedCustomer
                                                                  .value!
                                                                  .currencyBalance!
                                                                  .map((bal) =>
                                                                      "${bal.currency.symbol} ${bal.balance!.toStringAsFixed(2)} ,")
                                                                  .join(""),
                                                              style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                            ),
                                                          ],
                                                        )
                                                      : SizedBox(),
                                                  Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Obx(() {
                                                        // Hide print receipt checkbox when "Add to Account" button is enabled
                                                        bool
                                                            isAddToAccountMode =
                                                            cartController.amountPaid
                                                                        .value >
                                                                    0 &&
                                                                cartController
                                                                    .cartItems
                                                                    .isEmpty &&
                                                                (cartController
                                                                        .selectedCustomer
                                                                        .value
                                                                        ?.isLoyalCustomer ??
                                                                    false);

                                                        if (isAddToAccountMode) {
                                                          return SizedBox
                                                              .shrink();
                                                        }

                                                        return Container(
                                                          height: 30,
                                                          child:
                                                              CheckboxListTile(
                                                            title: Text(
                                                                'Print Receipt'),
                                                            value: cartController
                                                                .isPrintEnabled
                                                                .value,
                                                            onChanged:
                                                                (bool? value) {
                                                              cartController
                                                                      .isPrintEnabled
                                                                      .value =
                                                                  value ??
                                                                      false;
                                                            },
                                                          ),
                                                        );
                                                      }),
                                                      Obx(() {
                                                        // Hide fiscalize receipt checkbox when "Add to Account" button is enabled
                                                        bool
                                                            isAddToAccountMode =
                                                            cartController.amountPaid
                                                                        .value >
                                                                    0 &&
                                                                cartController
                                                                    .cartItems
                                                                    .isEmpty &&
                                                                (cartController
                                                                        .selectedCustomer
                                                                        .value
                                                                        ?.isLoyalCustomer ??
                                                                    false);

                                                        if (isAddToAccountMode) {
                                                          return SizedBox
                                                              .shrink();
                                                        }
                                                        // Show checkbox if fiscal device is registered (like web version's *ngIf="isFiscalDeviceRegistered")
                                                        if (cartController
                                                            .fiscalizeReceipt
                                                            .value) {
                                                          return Container(
                                                            height:48, // Match height of other checkboxes
                                                            decoration: BoxDecoration(
                                                              border: Border(
                                                                bottom: BorderSide(color: Colors.grey, width: 2.0),
                                                              ),
                                                            ),
                                                            child:
                                                                Row( // <--- Changed from Expanded to Row
                                                                    children: [
                                                                      Expanded(
                                                                        flex:9,
                                                                        child: CheckboxListTile(
                                                                          title: Text(
                                                                          'fiscal invoice'),
                                                                          enabled: false,
                                                                          value: cartController.fiscalizeReceipt.value,
                                                                          onChanged: (bool?
                                                                          value) {
                                                                        cartController.fiscalizeReceipt.value = value ??false;
                                                                        },
                                                                        ),
                                                                      ),
                                                                      Expanded(
                                                                        flex: 1,
                                                                        child: CheckboxListTile(
                                                                          value: cartController.fiscalizeCurrentReceipt.value,
                                                                          onChanged: (bool?
                                                                          value) {
                                                                        cartController.fiscalizeCurrentReceipt.value = value ??false;
                                                                        },
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                          );
                                                        } else {
                                                          return Container(); // Empty when fiscal device not available
                                                        }
                                                      }),
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
                                                                  .emailReceipt
                                                                  .value,
                                                              onChanged: (bool?
                                                                  value) {
                                                                cartController
                                                                        .emailReceipt
                                                                        .value =
                                                                    value ??
                                                                        false;
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
                                            Column(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(0.0),
                                                  height: 40,
                                                  child: Obx(() =>
                                                      CheckboxListTile(
                                                        title: Text(
                                                            'Select Multiple'),
                                                        value: saleController
                                                            .multiple.value,
                                                        onChanged:
                                                            (bool? value) {
                                                          saleController
                                                                  .multiple
                                                                  .value =
                                                              value ?? false;
                                                          cartController
                                                                  .multiple
                                                                  .value =
                                                              value ?? false;
                                                          saleController
                                                                  .showMultiple
                                                                  .value =
                                                              value ?? false;
                                                          if (saleController
                                                                  .multiple
                                                                  .value ==
                                                              true) {
                                                            cartController
                                                                .amountPaidTextEditingController
                                                                .clear();
                                                            cartController
                                                                    .amountPaidTextEditingController
                                                                    .text =
                                                                0.00.toStringAsFixed(
                                                                    2);
                                                            cartController
                                                                .hasAmountText
                                                                .value = true;
                                                            cartController
                                                                .amountPaid
                                                                .value = 0.00;
                                                            cartController
                                                                .customerAmountPaid
                                                                .value = 0.00;
                                                          }
                                                        },
                                                      )),
                                                ),
                                                Container(
                                                  child: Obx(() {
                                                    return GridView.builder(
                                                        gridDelegate:
                                                            SliverGridDelegateWithFixedCrossAxisCount(
                                                                crossAxisCount:
                                                                    4),
                                                        shrinkWrap: true,
                                                        physics:
                                                            NeverScrollableScrollPhysics(),
                                                        itemCount: cartController
                                                            .filteredPaymentTypesList
                                                            .length,
                                                        itemBuilder: (context,
                                                                index) =>
                                                            Container(
                                                                margin:
                                                                    EdgeInsets
                                                                        .all(
                                                                            4.0),
                                                                child:
                                                                    ElevatedButton(
                                                                  onPressed:
                                                                      () {
                                                                    var paymentType =
                                                                        cartController
                                                                            .filteredPaymentTypesList[index];
                                                                    saleController
                                                                            .selectedPaymentType =
                                                                        paymentType;
                                                                    if (saleController
                                                                            .multiple
                                                                            .value ==
                                                                        false) {
                                                                      saleController
                                                                          .selectedPaymentTypes
                                                                          .clear();
                                                                    }
                                                                    if (saleController
                                                                        .selectedPaymentTypes
                                                                        .any((element) =>
                                                                            element.id ==
                                                                            paymentType.id)) {
                                                                      saleController
                                                                          .selectedPaymentTypes
                                                                          .removeWhere((element) =>
                                                                              element.id ==
                                                                              paymentType.id);
                                                                    } else {
                                                                      if (saleController
                                                                              .multiple
                                                                              .value ==
                                                                          false)
                                                                        paymentType.amount = cartController
                                                                            .totalCostInSelectedCurrency
                                                                            .value;
                                                                      saleController
                                                                          .selectedPaymentTypes
                                                                          .add(
                                                                              paymentType);
                                                                      cartController.onChangePaymentType(
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
                                                                    backgroundColor: saleController.selectedPaymentTypes.contains(cartController.filteredPaymentTypesList[index]) || cartController.selectedPaymentType.value?.id == cartController.filteredPaymentTypesList[index].id
                                                                        ? context
                                                                            .theme
                                                                            .colorScheme
                                                                            .inversePrimary
                                                                        : context
                                                                            .theme
                                                                            .colorScheme
                                                                            .primary,
                                                                    // backgroundColor: Colors.indigo,
                                                                    padding:
                                                                        EdgeInsets.all(
                                                                            8.0),
                                                                    textStyle: TextStyle(
                                                                        fontSize:
                                                                            14,
                                                                        color: Colors
                                                                            .black),
                                                                  ),
                                                                  child: Text(
                                                                    cartController
                                                                            .filteredPaymentTypesList[index]
                                                                            .name ??
                                                                        'No Name',
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            14,
                                                                        color: context
                                                                            .theme
                                                                            .colorScheme
                                                                            .onPrimary),
                                                                  ),
                                                                )));
                                                  }),
                                                ),
                                              ],
                                            ),
                                            Container(
                                              color: Colors.pinkAccent[50],
                                              height: saleController
                                                      .showMultiple.value
                                                  ? 200
                                                  : 10,
                                              decoration: saleController
                                                      .showMultiple.value
                                                  ? BoxDecoration(
                                                      border: Border.all(
                                                          color: Colors
                                                              .lightGreenAccent,
                                                          width: 2.0),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8.0),
                                                    )
                                                  : BoxDecoration(),
                                              child: Obx(() {
                                                if (saleController
                                                        .showMultiple.value ==
                                                    false) {
                                                  return Container();
                                                } else {
                                                  return ListView.builder(
                                                    itemCount: cartController
                                                        .selectedPaymentTypes
                                                        .length,
                                                    itemBuilder:
                                                        (context, index) {
                                                      final paymentType =
                                                          cartController
                                                                  .selectedPaymentTypes[
                                                              index];
                                                      return Card(
                                                        child: ListTile(
                                                          title: Text(
                                                              paymentType
                                                                      .name ??
                                                                  'No Name',
                                                              style: TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Colors
                                                                      .indigo,
                                                                  fontStyle:
                                                                      FontStyle
                                                                          .italic)),
                                                          subtitle: Text(
                                                              'Amount: \$${paymentType.amount!.toStringAsFixed(2)}',
                                                              style: TextStyle(
                                                                  fontSize: 10,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Colors
                                                                      .black54)),
                                                          trailing: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              ElevatedButton(
                                                                onPressed:
                                                                    () async {
                                                                  final amount =
                                                                      await addAmount(
                                                                          index);
                                                                },
                                                                child: Text(
                                                                  "Add Amount",
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .indigo,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      fontSize:
                                                                          12),
                                                                ),
                                                                style: TextButton
                                                                    .styleFrom(
                                                                  padding:
                                                                      EdgeInsets
                                                                          .all(
                                                                              8.0),
                                                                  shape:
                                                                      RoundedRectangleBorder(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            8.0),
                                                                  ),
                                                                  backgroundColor:
                                                                      Colors
                                                                          .transparent,
                                                                  // Set button color to red
                                                                  foregroundColor:
                                                                      Colors
                                                                          .black, // Set text color to red
                                                                ),
                                                              ),
                                                              IconButton(
                                                                icon: Icon(
                                                                  Icons.delete,
                                                                  color: Colors
                                                                      .red,
                                                                ),
                                                                onPressed: () {
                                                                  cartController
                                                                      .removePaymentMethod(
                                                                          index);
                                                                  saleController
                                                                      .selectedPaymentTypes
                                                                      .removeAt(
                                                                          index);
                                                                  saleController
                                                                      .selectedPaymentTypes
                                                                      .refresh();
                                                                  cartController
                                                                      .selectedPaymentTypes
                                                                      .refresh();
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
                                          ],
                                        ),
                                      ),
                                      cartController.amountPaid.value > 0 &&
                                              cartController
                                                  .cartItems.isEmpty &&
                                              cartController.selectedCustomer
                                                  .value!.isLoyalCustomer!
                                          ? Container(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  if (!saleController
                                                      .addAccClicked.value) {
                                                    if (cartController
                                                                .selectedPaymentType
                                                                .value ==
                                                            null ||
                                                        cartController
                                                                .selectedPaymentType
                                                                .value!
                                                                .id ==
                                                            null) {
                                                      Get.snackbar("Error",
                                                          "Please select a payment type.",
                                                          snackPosition:
                                                              SnackPosition
                                                                  .BOTTOM);
                                                    } else {
                                                      cartController
                                                          .savePayment();
                                                      saleController
                                                          .addAccClicked
                                                          .value = true;
                                                    }
                                                  }
                                                },
                                                style: TextButton.styleFrom(
                                                  backgroundColor: Colors.pink,
                                                  // Set button color to red
                                                  foregroundColor: Colors.black,
                                                  // Set text color to red
                                                  textStyle: TextStyle(
                                                      fontSize: 18,
                                                      color: Colors.white,
                                                      fontWeight: FontWeight
                                                          .bold), // Set text size
                                                ),
                                                child: Text('Add to Account'),
                                              ),
                                            )
                                          : cartController.cartItems.any(
                                                      (cartItem) =>
                                                          !cartItem.breakage) ||
                                                  cartController
                                                      .cartItems.isEmpty
                                              ? Container(
                                                  width: double.infinity,
                                                  child: Obx(() {
                                                    final tip = cartController
                                                        .tipValue.value;
                                                    final amtToAcc =
                                                        cartController
                                                            .amtToAccValue
                                                            .value;
                                                    final requiredAmount =
                                                        cartController
                                                                .totalCostInSelectedCurrency
                                                                .value +
                                                            tip +
                                                            amtToAcc;
                                                    final paymentSelected =
                                                        cartController
                                                                    .selectedPaymentType
                                                                    .value !=
                                                                null &&
                                                            cartController
                                                                    .selectedPaymentType
                                                                    .value!
                                                                    .id !=
                                                                null;
                                                    final canCharge = !cartController
                                                            .isCharging.value &&
                                                        !saleController
                                                            .chargeClicked
                                                            .value &&
                                                        paymentSelected &&
                                                        cartController
                                                                .amountPaid
                                                                .value >=
                                                            requiredAmount &&
                                                        cartController.cartItems
                                                            .isNotEmpty;
                                                    return Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .stretch,
                                                      children: [
                                                        ElevatedButton.icon(
                                                          onPressed: canCharge
                                                              ? () {
                                                                  cartController
                                                                      .showConfirmDialogChargeSale();
                                                                  saleController
                                                                      .chargeClicked
                                                                      .value = true;
                                                                }
                                                              : null,
                                                          style: TextButton
                                                              .styleFrom(
                                                            backgroundColor: canCharge
                                                                ? context
                                                                    .theme
                                                                    .colorScheme
                                                                    .inversePrimary
                                                                : context
                                                                    .theme
                                                                    .colorScheme
                                                                    .secondary,
                                                            foregroundColor:
                                                                Colors.black,
                                                            textStyle: TextStyle(
                                                                fontSize: 18,
                                                                color: context
                                                                    .theme
                                                                    .colorScheme
                                                                    .onSurface,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold),
                                                          ),
                                                          icon: Icon(
                                                              Icons
                                                                  .check_circle,
                                                              color: canCharge
                                                                  ? Colors.green
                                                                  : Colors.red,
                                                              size: 30),
                                                          label: Text(
                                                            cartController
                                                                    .isCharging
                                                                    .value
                                                                ? 'CHARGING...'
                                                                : 'Charge',
                                                          ),
                                                        ),
                                                        if (!canCharge)
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .only(
                                                                    top: 4.0),
                                                            child: Text(
                                                              'Need at least ${requiredAmount.toStringAsFixed(2)} (have ${cartController.amountPaid.value.toStringAsFixed(2)})',
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              style: TextStyle(
                                                                  fontSize: 12,
                                                                  color: Colors
                                                                      .red),
                                                            ),
                                                          ),
                                                      ],
                                                    );
                                                  }),
                                                )
                                              : Container(
                                                  width: double.infinity,
                                                  child: ElevatedButton(
                                                    onPressed: () {
                                                      if (cartController
                                                          .cartItems.isEmpty) {
                                                        Get.snackbar("Error",
                                                            "Your cart is empty.",
                                                            snackPosition:
                                                                SnackPosition
                                                                    .TOP);
                                                        return;
                                                      }
                                                      if (cartController
                                                              .amountPaid
                                                              .value <
                                                          cartController
                                                              .totalCostInSelectedCurrency
                                                              .value) {
                                                        Get.snackbar("Error",
                                                            "Please enter a valid amount paid.",
                                                            snackPosition:
                                                                SnackPosition
                                                                    .TOP);
                                                        return;
                                                      }
                                                      if (!saleController
                                                              .chargeClicked
                                                              .value &&
                                                          !cartController
                                                              .isCharging
                                                              .value) {
                                                        // cartController.selectedPaymentTypes.add(cartController.selectedPaymentType.value!);
                                                        cartController.onChangePaymentType(
                                                            cartController
                                                                .filteredPaymentTypesList
                                                                .firstWhereOrNull(
                                                                    (pt) => pt
                                                                        .name!
                                                                        .startsWith(
                                                                            "CASH-"))!,
                                                            false);
                                                        cartController
                                                            .fiscalizeReceipt
                                                            .value = false;
                                                        cartController
                                                            .showConfirmDialogChargeSale();
                                                        saleController
                                                            .chargeClicked
                                                            .value = true;
                                                      }
                                                    },
                                                    style: TextButton.styleFrom(
                                                      backgroundColor: Colors
                                                          .blueAccent[400],
                                                      // Set button color to red
                                                      foregroundColor:
                                                          Colors.black,
                                                      // Set text color to red
                                                      textStyle: TextStyle(
                                                          fontSize: 18,
                                                          color: Colors.white,
                                                          fontWeight: FontWeight
                                                              .bold), // Set text size
                                                    ),
                                                    child: Text(
                                                        'Charge Breakages'),
                                                  ),
                                                ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
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
        ),
      );
    }
  }

  Future<Double?> addAmount(int index) => showDialog<Double>(
        context: Get.context!,
        builder: (context) {
          return AlertDialog(
            title: Text("Add Amount"),
            content: TextField(
              autofocus: true,
              controller: saleController.amountTextEditingController,
              decoration: InputDecoration(
                labelText: "Enter Amount",
                border: OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
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
                  print(
                      "Amount: ${saleController.amountTextEditingController.text}");
                  if (saleController
                      .amountTextEditingController.text.isNotEmpty) {
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
                    cartController.hasAmountText.value = true;
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
  Future<Double?> addDiscount(int index) => showDialog<Double>(
        context: Get.context!,
        builder: (context) {
          return AlertDialog(
            title: Text("Add Discount"),
            content: TextField(
              autofocus: true,
              controller: saleController.discountTextEditingController,
              decoration: InputDecoration(
                labelText: "Enter Amount",
                border: OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (String val) {
                // if (val.isNotEmpty) {
                //   cartController.cartItems[index].product.item!.sellingPrice =
                //       double.parse(val);
                // }
              },
            ),
            actions: [
              TextButton(
                onPressed: () {
                  saleController.discountTextEditingController.clear();
                  Get.back(); // Close dialog without adding an amount
                },
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  if (saleController
                      .discountTextEditingController.text.isNotEmpty) {
                    double amount = double.parse(
                        saleController.discountTextEditingController.text);
                    // if (amount <= 0) {
                    //   Get.snackbar("Error", "Amount must be greater than zero.",
                    //       snackPosition: SnackPosition.TOP);
                    //   return;
                    // }
                    cartController.cartItems[index].discount = amount;
                    cartController.cartItems.refresh();
                    cartController
                        .calculateTotalAmounts(cartController.cartItems);
                    saleController.discountTextEditingController.clear();
                    Get.back(); // Close the dialog after adding
                  }
                },
                child: Text("Add"),
              ),
            ],
          );
        },
      );

  Future<String?> addNotes(int index) => showDialog<String>(
        context: Get.context!,
        builder: (context) {
          return AlertDialog(
            title: Text("Add notes"),
            content: TextField(
              autofocus: true,
              controller: saleController.itemNotesTextEditingController,
              decoration: InputDecoration(
                labelText: "Enter notes",
                border: OutlineInputBorder(),
              ),
              onChanged: (String val) {
                if (val.isNotEmpty) {
                  cartController.cartItems[index].notes = val;
                  cartController.cartItems.refresh();
                }
              },
            ),
            actions: [
              TextButton(
                onPressed: () {
                  cartController.cartItems[index].notes = "";
                  saleController.itemNotesTextEditingController.clear();
                  Get.back(); // Close dialog without adding an amount
                },
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  Get.back(); // Close the dialog after adding
                  saleController.itemNotesTextEditingController.clear();
                },
                child: Text("Add Notes"),
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
        backgroundColor: context.theme.colorScheme.onPrimary,
        foregroundColor: context.theme.colorScheme.onSurface,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 2,
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
