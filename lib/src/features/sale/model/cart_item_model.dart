

import 'package:vimbika_pos_app/src/features/sale/model/product_full_info_model.dart';

class CartItemModel {
  CartItemModel({
    required this.product,
    required this.quantity,
    this.usedCodes = const {},
  });

  final ProductFullInfoModel product;
  double quantity;
  Set<String> usedCodes = {};

  double get totalPrice => product.item!.sellingPrice * quantity;

  double get totalTaxAmount => product.item!.taxAmount * quantity;

  factory CartItemModel.fromMap(Map<String, dynamic> json) => CartItemModel(
    quantity: json["quantity"],
    product: ProductFullInfoModel.fromMap(json["product"]),
    usedCodes: json["usedCodes"] != null
        ? Set<String>.from(json["usedCodes"].map((x) => x.toString()))
        : {},
  );
  Map<String, dynamic> toMap() => {
    "quantity": quantity,
    "product": product.toMap(),
    "usedCodes": usedCodes.isNotEmpty
        ? List<String>.from(usedCodes.map((x) => x.toString()))
        : [],
  };
}