

import 'package:vimbika_pos_app/src/features/sale/model/product_full_info_model.dart';

class CartItemModel {
  CartItemModel({
    required this.product,
    required this.quantity,
  });

  final ProductFullInfoModel product;
  double quantity;

  double get totalPrice => product.item!.sellingPrice * quantity;

  double get totalTaxAmount => product.item!.taxAmount * quantity;

  factory CartItemModel.fromMap(Map<String, dynamic> json) => CartItemModel(
    quantity: json["quantity"],
    product: ProductFullInfoModel.fromMap(json["product"]),
  );
  Map<String, dynamic> toMap() => {
    "quantity": quantity,
    "product": product.toMap()
  };
}