
import 'package:vimbika_pos_app/src/features/sale/model/product_full_info_model.dart';

class CartItemModel {
  CartItemModel({
    required this.product,
    required this.quantity,
    this.breakage = false,
    this.usedCodes = const {},
    this.notes = '',
    this.discount = 0.0,
  });

  final ProductFullInfoModel product;
  double quantity;
  Set<String> usedCodes = {};
  bool breakage = false;
  String notes;
  double discount;

  double get totalPrice {
    if (breakage) return 0.00;
    double price = (product.item!.sellingPrice - discount) * quantity;
    return double.parse(price.toStringAsFixed(3));
  }

  double get totalTaxAmount {
    if (breakage) return 0.00;
    double tax = product.item!.taxAmount * quantity;
    return double.parse(tax.toStringAsFixed(3));
  }


  factory CartItemModel.fromMap(Map<String, dynamic> json) => CartItemModel(
    quantity: json["quantity"].toDouble(),
    notes: json["notes"],
    breakage: json["breakage"],
    product: ProductFullInfoModel.fromMap(json["product"]),
    usedCodes: json["usedCodes"] != null
        ? Set<String>.from(json["usedCodes"].map((x) => x.toString()))
        : {},
    discount: json["discount"]?.toDouble() ?? 0.0,
  );
  Map<String, dynamic> toMap() => {
    "quantity": quantity,
    "notes": notes,
    "breakage": breakage,
    "product": product.toMap(),
    "usedCodes": usedCodes.isNotEmpty
        ? List<String>.from(usedCodes.map((x) => x.toString()))
        : [],
    "discount": discount,
  };
}