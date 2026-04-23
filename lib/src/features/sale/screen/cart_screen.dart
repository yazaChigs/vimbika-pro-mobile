import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:vimbika_pos_app/src/constants/app_constants.dart';
import 'package:vimbika_pos_app/src/features/sale/controller/cart_controller.dart';
import 'package:vimbika_pos_app/src/shared/controller/inactivity_controller.dart';
import 'package:vimbika_pos_app/src/features/sale/model/cart_item_model.dart';

class CartScreen extends StatelessWidget {
  final CartController cartController = Get.find();
  final InactivityController inactivityController = Get.find();

  void _showEditQuantityDialog(BuildContext context, CartItemModel cartItem) {
    final TextEditingController quantityController =
        TextEditingController(text: cartItem.quantity.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Quantity'),
          content: TextField(
            controller: quantityController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            decoration: InputDecoration(
              labelText: 'Quantity',
              hintText: 'Enter quantity',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final double? newQuantity =
                    double.tryParse(quantityController.text);
                if (newQuantity != null) {
                  cartController.updateQuantity(cartItem, newQuantity);
                  Navigator.pop(context);
                } else {
                  Get.snackbar(
                    "Invalid Quantity",
                    "Please enter a valid number",
                    snackPosition: SnackPosition.BOTTOM,
                  );
                }
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      // onTap: inactivityController.resetInactivityTimer,
      // onPanDown: (_) => inactivityController.resetInactivityTimer(),
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
                    String imageUrl = cartItem.product.item!.image != null
                        ? "${AppConstants.VIMBIKA_BACKEND_URL}/inventory/image?name=${cartItem.product.item!.image}"
                        : "https://via.placeholder.com/150";

                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ListTile(
                        tileColor: Colors.lightBlue[100],
                        title: Text(
                          cartItem.product.item!.name ?? '',
                        ),
                        subtitle: InkWell(
                          onTap: () => _showEditQuantityDialog(context, cartItem),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text(
                              'Quantity ${cartItem.quantity.toStringAsFixed(cartItem.quantity % 1 == 0 ? 0 : 2)}',
                              style: TextStyle(
                                fontWeight: cartItem.quantity > 1
                                    ? FontWeight.bold
                                    : null,
                                decoration: TextDecoration.underline,
                                decorationStyle: TextDecorationStyle.dashed,
                              ),
                            ),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.remove,
                                color: Colors.cyan,
                              ),
                              onPressed: () =>
                                  cartController.decrementQuantity(cartItem),
                            ),
                            Text(
                              '${(cartItem.quantity * cartItem.product.item!.sellingPrice).toStringAsFixed(2)}',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.add,
                                color: Colors.cyan,
                              ),
                              onPressed: () =>
                                  cartController.incrementQuantity(cartItem),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete,
                                color: Colors.cyan,
                              ),
                              onPressed: () =>
                                  cartController.removeFromCart(cartItem),
                            ),
                          ],
                        ),
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
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.cyan),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        for (var item in cartController.cartItems) {
                          print(
                              "Item: ${item.product.item!.name}, Quantity: ${item.quantity}, Price: ${item.product.item!.sellingPrice}");
                        }
                        cartController.checkout();
                      },
                      style: TextButton.styleFrom(
                        backgroundColor:
                            Colors.cyan, // Set button color to primary theme color
                        // foregroundColor: context.theme.colorScheme.onPrimary, // Set text color to onPrimary theme color
                        textStyle: TextStyle(
                            fontSize: 16,
                            color: context.theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.bold), // Set text size
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
