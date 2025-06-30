import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vimbika_pos_app/src/constants/app_constants.dart';
import 'package:vimbika_pos_app/src/constants/app_routes.dart';
import 'package:vimbika_pos_app/src/features/sale/controller/cart_controller.dart';
import 'package:vimbika_pos_app/src/features/sale/model/product_full_info_model.dart';
import 'package:vimbika_pos_app/src/features/sale/model/inventory_item_model.dart';
import 'package:vimbika_pos_app/src/shared/controller/inactivity_controller.dart';

class ProductDescriptionScreen extends StatelessWidget {
  final ProductFullInfoModel productFullInfo;
  final CartController cartController = Get.find();
  final InactivityController inactivityController = Get.find();

  ProductDescriptionScreen({required this.productFullInfo});

  @override
  Widget build(BuildContext context) {
    InventoryItemModel product = productFullInfo.item!;
    String imageUrl = product.image != null
        ? "${AppConstants.VIMBIKA_BACKEND_URL}/inventory/image?name=${product.image}"
        : "https://via.placeholder.com/150";

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: inactivityController.resetInactivityTimer,
      onPanDown: (_) => inactivityController.resetInactivityTimer(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white, // Same as your app theme
          elevation: 0,
          leading: IconButton(
            color: Colors.white,
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Get.back(); // Go back to the previous page
            },
          ),
          title: Text(product.name ?? 'Product Details'),
          //backgroundColor: Colors.black, // AppBar background color
          foregroundColor: Colors.white, // AppBar text and icon color
        ),
        body: SingleChildScrollView(
          child: Container(
            color: Colors.white, // Page background color
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center, // Center-align all children in the column
                children: [
                  Center(
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      placeholder: (context, url) =>
                          CircularProgressIndicator(),
                      errorWidget: (context, url, error) {
                        debugPrint('Image load failed: $error');
                        return Image.asset(
                          'assets/images/dummy/dummy.png', // Path to your error image
                          fit: BoxFit.cover,
                        );
                      },
                      height: 200,
                      imageBuilder: (context, imageProvider) {
                        return Image(
                          image: imageProvider,
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    product.name ?? 'No name',
                    style: TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center, // Center-align text
                  ),
                  SizedBox(height: 8),
                  Text(
                    product.fullName ?? 'No description',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center, // Center-align text
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Brand: ${product.brand?.name ?? 'No brand'}',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center, // Center-align text
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Category: ${product.category?.name ?? 'No category'}',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center, // Center-align text
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Item Type: ${product.itemType ?? 'No Item Type'}',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center, // Center-align text
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Item Code: ${product.itemCode ?? 'No Item Code'}',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center, // Center-align text
                  ),
                  SizedBox(height: 16),
                  Text(
                    '\$${product.sellingPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green),
                    textAlign: TextAlign.center, // Center-align text
                  ),
                  SizedBox(height: 24),
                  Center(
                    child: SizedBox(
                      width: 100,
                      child: ElevatedButton(
                        onPressed: () {
                          // Add to cart functionality
                          if(productFullInfo.stock! > 0 ) {
                            cartController.addToCart(productFullInfo, 1);
                          } else if(productFullInfo.item?.itemType == 'SERVICE'){
                            cartController.addToCart(productFullInfo, 1);
                          }else{
                            Get.snackbar("Check your stock", "Stock not available!!!", snackPosition: SnackPosition.BOTTOM);
                          }

                          Get.back();
                        },
                        child: Text('Add to Cart'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
