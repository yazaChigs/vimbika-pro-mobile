import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:vimbika_pos_app/src/constants/app_constants.dart';
import 'package:vimbika_pos_app/src/features/sale/controller/cart_controller.dart';
import 'package:vimbika_pos_app/src/shared/controller/inactivity_controller.dart';

class CartScreen extends StatelessWidget {
  final CartController cartController = Get.find();
  final InactivityController inactivityController = Get.find();


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: inactivityController.resetInactivityTimer,
      onPanDown: (_) => inactivityController.resetInactivityTimer(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white, // Same as your app theme
          elevation: 0,
          title: Text('Cart'),
        ),
        body: Obx(() {
          if (cartController.cartItems.isEmpty) {
            return Center(child: Text('Your cart is empty'));
          }
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cartController.cartItems.length,
                  itemBuilder: (context, index) {
                    final cartItem = cartController.cartItems[index];
                    String imageUrl = cartItem.product.item!.image!=null
                        ? "${AppConstants
                        .VIMBIKA_BACKEND_URL}/inventory/image?name=${cartItem
                        .product.item!.image}"
                        : "https://via.placeholder.com/150";

                    return ListTile(
                      tileColor: Colors.blue[100],
                      leading: CachedNetworkImage(
                          imageUrl: imageUrl,
                          placeholder: (context, url) =>
                              CircularProgressIndicator(),
                          errorWidget: (context, url, error) => Image.asset(
                            'assets/images/dummy/dummy.png', // Path to your error image
                            fit: BoxFit.cover,
                          ),
                      ),
                      title: Text(cartItem.product.item!.name ?? ''),
                      subtitle: Text('${cartItem.product.item!
                          .sellingPrice} x ${cartItem.quantity}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove),
                            onPressed: () =>
                                cartController.decrementQuantity(cartItem),
                          ),
                          Text('${(cartItem.quantity*cartItem.product.item!.sellingPrice).toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.indigo,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.add,color: Colors.indigoAccent,),
                            onPressed: () =>
                                cartController.incrementQuantity(cartItem),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete,color: Colors.red,),
                            onPressed: () =>
                                cartController.removeFromCart(cartItem),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Total : ${cartController.selectedCurrency.value?.symbol ?? ''} ${cartController.totalCostInSelectedCurrency.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold,color: Colors.indigoAccent),
                    ),

                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                          cartController.checkout();
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.lightGreenAccent, // Set button color to red
                        foregroundColor: Colors.black, // Set text color to red
                        textStyle: TextStyle(fontSize: 16,color: Colors.white, fontWeight: FontWeight.bold), // Set text size
                      ),
                      child: Text('Checkout'),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
