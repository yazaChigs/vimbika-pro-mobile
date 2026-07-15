import 'package:vimbika_pro/model/user.dart';
import 'package:vimbika_pro/model/company.dart';
import 'package:vimbika_pro/model/currency.dart';
import 'package:vimbika_pro/model/bank.dart';
import 'package:vimbika_pro/model/branch.dart';
import 'package:vimbika_pro/model/customer.dart';
import 'package:vimbika_pro/model/inventory_item.dart';
import 'package:vimbika_pro/model/payment_type.dart';
import 'package:vimbika_pro/model/subscription.dart';
import 'package:vimbika_pro/model/unit.dart';
import 'package:vimbika_pro/model/category.dart';
import 'package:vimbika_pro/model/tax.dart';
import 'package:vimbika_pro/model/supplier.dart';

class CompanySyncDto {
  final User user;
  final Company company;
  final Branch branch;
  final List<Currency> currencies;
  final List<Bank> banks;
  final List<Customer> customers;
  final List<Supplier> suppliers;
  final List<InventoryItem> inventoryItems;
  final List<PaymentType> paymentTypes;
  final List<Unit> units;
  final List<Category> categories;
  final List<Tax> taxes;
  final Subscription subscription;

  CompanySyncDto({
    required this.user,
    required this.company,
    required this.branch,
    required this.currencies,
    required this.banks,
    required this.customers,
    required this.suppliers,
    required this.inventoryItems,
    required this.paymentTypes,
    required this.units,
    required this.categories,
    required this.taxes,
    required this.subscription,
  });

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'company': company.toJson(),
      'branch': branch.toJson(),
      'currencies': currencies.map((c) => c.toJson()).toList(),
      'banks': banks.map((b) => b.toJson()).toList(),
      'customers': customers.map((c) => c.toJson()).toList(),
      'suppliers': suppliers.map((s) => s.toJson()).toList(),
      'inventoryItems': inventoryItems.map((item) => item.toJson()).toList(),
      'paymentTypes': paymentTypes.map((pt) => pt.toJson()).toList(),
      'units': units.map((u) => u.toJson()).toList(),
      'categories': categories.map((c) => c.toJson()).toList(),
      'taxes': taxes.map((t) => t.toJson()).toList(),
      'subscription': subscription.toJson(),
    };
  }
}
