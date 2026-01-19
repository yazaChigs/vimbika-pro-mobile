

import 'package:vimbika_pos_app/src/features/sale/model/product_full_info_model.dart';

class CartItemModel {
  CartItemModel({
    required this.product,
    required this.quantity,
    this.breakage = false,
    this.usedCodes = const {},
    this.notes = '',
  });

  final ProductFullInfoModel product;
  double quantity;
  Set<String> usedCodes = {};
  bool breakage = false;
  String notes;

  double get totalPrice => breakage ? 0.00 : product.item!.sellingPrice * quantity;

  double get totalTaxAmount => breakage ? 0.00 :  product.item!.taxAmount * quantity;


  factory CartItemModel.fromMap(Map<String, dynamic> json) => CartItemModel(
    quantity: json["quantity"],
    notes: json["notes"],
    breakage: json["breakage"],
    product: ProductFullInfoModel.fromMap(json["product"]),
    usedCodes: json["usedCodes"] != null
        ? Set<String>.from(json["usedCodes"].map((x) => x.toString()))
        : {},
  );
  Map<String, dynamic> toMap() => {
    "quantity": quantity,
    "notes": notes,
    "breakage": breakage,
    "product": product.toMap(),
    "usedCodes": usedCodes.isNotEmpty
        ? List<String>.from(usedCodes.map((x) => x.toString()))
        : [],
  };
}