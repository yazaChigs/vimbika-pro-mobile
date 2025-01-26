import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vimbika_pos_app/src/constants/app_constants.dart';
import 'package:vimbika_pos_app/src/constants/app_routes.dart';
import 'package:vimbika_pos_app/src/features/sale/screen/product_description_screen.dart';
import 'package:vimbika_pos_app/src/features/stock_requests/controller/stock_request_controller.dart';
import 'package:vimbika_pos_app/src/features/stock_requests/model/requisition_model.dart';
import 'package:vimbika_pos_app/src/shared/models/base_name_model.dart';

class NewStockRequestScreen extends GetView {
  final StockRequestController stockRequestController = Get.find();


  @override
  Widget build(BuildContext context) {
    RequisitionModel val = stockRequestController.selectedReq.value!;
    String title = val.id != null ? 'EDITING REQUEST (' + val.referenceNumber! + ')':'SELECT ITEMS';
    return Scaffold(
      appBar: AppBar(
        title: Text(title),

        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Obx(() {
                      return ElevatedButton(
                        onPressed: () {
                          // ticketController.ticketActionButton(cartController.selectedCurrency.value!, cartController.cartItems.length);
                          Get.toNamed(AppRoutes.NEW_STOCK_REQUEST_CART);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14.0),
                          textStyle: TextStyle(fontSize: 12),
                        ),

                        child: Text('REQUEST ITEMS : ' +
                            stockRequestController.cartItems.length.toString(),
                          style: TextStyle(color: Colors.white, fontSize: 16),

                        ),
                      );
                    }),
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
                      stockRequestController.isSearching.value
                          ? Expanded(
                        child: TextField(
                          controller: stockRequestController
                              .searchTextEditingController,
                          decoration: InputDecoration(
                            hintText: 'Search Items...',
                            border: OutlineInputBorder(),
                            prefixIcon: IconButton(
                              icon: Icon(Icons.close),
                              onPressed: () {
                                stockRequestController
                                    .searchTextEditingController
                                    .clear();
                                stockRequestController.isSearching.value =
                                false; // Hide search field

                                final allItemsCategory = stockRequestController
                                    .categories
                                    .firstWhere(
                                      (category) => category.id == "All Items",
                                  orElse: () =>
                                  stockRequestController.categories.first,
                                );
                                stockRequestController.selectedCategory.value =
                                    allItemsCategory;


                                stockRequestController.filterProducts(query: '',
                                    category: stockRequestController
                                        .selectedCategory
                                        .value?.id);
                              },
                            ),
                          ),
                          onChanged: (query) {
                            // saleController.filterProducts(query);
                            stockRequestController.filterProducts(query: query,
                                category: stockRequestController
                                    .selectedCategory.value
                                    ?.name); // Filter based on search query and category
                          },
                        ),
                      )
                          : Expanded(
                        child: DropdownButton<BaseNameModel>(
                          value: stockRequestController.selectedCategory.value,
                          isExpanded: true,
                          // Make the dropdown take full width
                          items: stockRequestController.categories.map((
                              category) {
                            return DropdownMenuItem<BaseNameModel>(
                              value: category,
                              child: Text(category.name!),
                            );
                          }).toList(),
                          onChanged: (value) {
                            stockRequestController.isCatSelected.value = true;
                            stockRequestController.selectedCategory.value =
                            value!;
                            stockRequestController.filterProducts(
                                category: value
                                    .id!); // Filter based on selected category

                          },
                          hint: Text("Select Category"),
                        ),
                      ),
                      // Search Icon
                      if (!stockRequestController.isSearching
                          .value) // Show search icon only when not searching
                        IconButton(
                          icon: Icon(Icons.search),
                          onPressed: () {
                            stockRequestController.isSearching.value =
                            true; // Show search field
                            stockRequestController.selectedCategory.value =
                                BaseNameModel(
                                    id: "All Items", name: "All Items");
                            stockRequestController.filterProducts(query: '',
                                category: stockRequestController
                                    .selectedCategory.value
                                    ?.id);
                          },
                        ),
                    ],
                  );
                }),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Obx(() {
                  return ListView.builder(
                    itemCount: stockRequestController.filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = stockRequestController
                          .filteredProducts[index];
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
                                      // Get.to(() =>
                                      //     ProductDescriptionScreen(
                                      //         productFullInfo: product));
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.all(5.0),
                                      textStyle: TextStyle(fontSize: 14),
                                    ),
                                    child: Text('(' +
                                        product.stock!.toInt().toString() +
                                        ')'),
                                  ),
                                ),
                              ],
                            ),
                            isThreeLine: true,

                            onTap: () {
                              stockRequestController.addToCart(product);
                            },
                          )
                      );
                    },
                  );
                }),
              ),
            ],
          )
      ),
    );
  }
}
