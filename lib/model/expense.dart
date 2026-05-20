import 'base_entity.dart';
import 'expense_category.dart';
import 'branch.dart';
import 'currency.dart';
import 'supplier.dart';
import 'payment_paid.dart';

class Expense extends BaseEntity {
  final ExpenseCategory? expenseCategory;
  final Branch? branch;
  final Currency? currency;
  final Supplier? supplier;
  final List<PaymentPaid>? payments;
  final double amount;
  final DateTime expenseDate;
  final String? reference;
  final String? notes;

  Expense({
    String? id,
    String? dateCreated,
    String? dateModified,
    String? createdByName,
    String? modifiedByName,
    int? version,
    this.expenseCategory,
    this.branch,
    this.currency,
    this.supplier,
    this.payments,
    required this.amount,
    required this.expenseDate,
    this.reference,
    this.notes,
  }) : super(
          id: id,
          dateCreated: dateCreated,
          dateModified: dateModified,
          createdByName: createdByName,
          modifiedByName: modifiedByName,
          version: version,
        );

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      dateCreated: json['dateCreated'] ,
      dateModified: json['dateModified'] ,
      createdByName: json['createdByName'],
      modifiedByName: json['modifiedByName'],
      version: json['version'],
      expenseCategory: json['expenseCategory'] != null
          ? ExpenseCategory.fromJson(json['expenseCategory'])
          : (json['category'] != null ? ExpenseCategory.fromJson(json['category']) : null),
      branch: json['branch'] != null ? Branch.fromJson(json['branch']) : null,
      currency: json['currency'] != null ? Currency.fromJson(json['currency']) : null,
      supplier: json['supplier'] != null ? Supplier.fromJson(json['supplier']) : null,
      payments: json['payments'] != null
          ? (json['payments'] as List).map((i) => PaymentPaid.fromJson(i)).toList()
          : null,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      expenseDate: json['expenseDate'] != null ? DateTime.parse(json['expenseDate']) : DateTime.now(),
      reference: json['reference'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dateCreated': dateCreated,
      'dateModified': dateModified,
      'createdByName': createdByName,
      'modifiedByName': modifiedByName,
      'version': version,
      'expenseCategory': expenseCategory?.toJson(),
      'branch': branch?.toJson(),
      'currency': currency?.toJson(),
      'supplier': supplier?.toJson(),
      'payments': payments?.map((i) => i.toJson()).toList(),
      'amount': amount,
      'expenseDate': expenseDate.toIso8601String(),
      'reference': reference,
      'notes': notes,
    };
  }
}
