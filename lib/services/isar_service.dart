import 'dart:async';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vimbika_pro/model/sale.dart';
import 'package:vimbika_pro/model/sale_item.dart';
import 'package:vimbika_pro/model/payment_received.dart';
import 'package:vimbika_pro/model/customer.dart';
import 'package:vimbika_pro/model/company.dart';
import 'package:vimbika_pro/model/branch.dart';
import 'package:vimbika_pro/model/currency.dart';
import 'package:vimbika_pro/model/inventory_item.dart';
import 'package:vimbika_pro/model/payment_type.dart';
import 'package:vimbika_pro/model/bank.dart';
import 'package:vimbika_pro/model/customer_currency_amount.dart';
import 'package:vimbika_pro/model/category.dart';
import 'package:vimbika_pro/model/unit.dart';
import 'package:vimbika_pro/model/tax.dart';
import 'package:vimbika_pro/model/branch_stock.dart';

class IsarService {
  static final IsarService _instance = IsarService._internal();
  factory IsarService() => _instance;
  IsarService._internal() {
    db = openDB();
  }

  late Future<Isar> db;

  Future<Isar> openDB() async {
    if (Isar.instanceNames.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      return await Isar.open(
        [
          SaleSchema,
          SaleItemSchema,
          PaymentReceivedSchema,
          CustomerSchema,
          CompanySchema,
          BranchSchema,
          CurrencySchema,
          InventoryItemSchema,
          PaymentTypeSchema,
          BankSchema,
          CustomerCurrencyAmountSchema,
          CategorySchema,
          UnitSchema,
          TaxSchema,
          BranchStockSchema,
        ],
        directory: dir.path,
        inspector: true,
      );
    }

    return Future.value(Isar.getInstance());
  }

  void _putInventoryItemSync(Isar isar, InventoryItem item) {
    if (item.category.value != null) isar.categorys.putSync(item.category.value!);
    if (item.unit.value != null) isar.units.putSync(item.unit.value!);
    if (item.tax.value != null) isar.taxs.putSync(item.tax.value!);
    if (item.currency.value != null) isar.currencys.putSync(item.currency.value!);
    if (item.company.value != null) isar.companys.putSync(item.company.value!);
    isar.inventoryItems.putSync(item);
  }

  void _putCustomerSync(Isar isar, Customer customer) {
    if (customer.company.value != null) isar.companys.putSync(customer.company.value!);
    if (customer.branch.value != null) {
      final b = customer.branch.value!;
      if (b.company.value != null) isar.companys.putSync(b.company.value!);
      isar.branchs.putSync(b);
    }

    for (var cca in customer.currencyBalance) {
      if (cca.currency.value != null) isar.currencys.putSync(cca.currency.value!);
      isar.customerCurrencyAmounts.putSync(cca);
    }
    isar.customers.putSync(customer);
  }

  void _putPaymentReceivedSync(Isar isar, PaymentReceived payment) {
    if (payment.paymentType.value != null) {
      final pt = payment.paymentType.value!;
      if (pt.banks != null && pt.banks!.isNotEmpty) {
        for (var bank in pt.banks!) {
          isar.banks.putSync(bank);
        }
      }
      if (pt.currency.value != null) isar.currencys.putSync(pt.currency.value!);
      isar.paymentTypes.putSync(pt);
    }
    if (payment.currency.value != null) isar.currencys.putSync(payment.currency.value!);
    if (payment.branch.value != null) {
      final b = payment.branch.value!;
      if (b.company.value != null) isar.companys.putSync(b.company.value!);
      isar.branchs.putSync(b);
    }
    if (payment.bank.value != null) isar.banks.putSync(payment.bank.value!);
    isar.paymentReceiveds.putSync(payment);
  }

  Future<void> completeSaleTransaction(Sale sale, List<PaymentReceived> paymentTypes, List<SaleItem> items, List<Customer> customersToUpdate, ) async {
    final isar = await db;
    isar.writeTxnSync(() {
      sale.syncListsToLinks();
      // 1. Put all customers that need updating
      for (var customer in customersToUpdate) {
        _putCustomerSync(isar, customer);
      }

      // 2. Put SaleItems and their nested entities
      for (var item in items) {
        if (item.inventoryItem.value != null) {
          _putInventoryItemSync(isar, item.inventoryItem.value!);
        }
        isar.saleItems.putSync(item);
      }

      // 3. Put PaymentReceived and their nested entities
      for (var payment in paymentTypes) {
        if (payment.payer.value != null) {
          _putCustomerSync(isar, payment.payer.value!);
        }
        _putPaymentReceivedSync(isar, payment);
      }

      // 4. Put the Sale's direct related entities
      if (sale.customer.value != null) _putCustomerSync(isar, sale.customer.value!);
      if (sale.company.value != null) isar.companys.putSync(sale.company.value!);
      if (sale.branch.value != null) {
        final b = sale.branch.value!;
        if (b.company.value != null) isar.companys.putSync(b.company.value!);
        isar.branchs.putSync(b);
      }
      if (sale.currency.value != null) isar.currencys.putSync(sale.currency.value!);
      if (sale.baseCurrency.value != null) isar.currencys.putSync(sale.baseCurrency.value!);

      // 5. Now, put the Sale itself
      isar.sales.putSync(sale);
    });
  }

  Future<void> saveSale(Sale sale) async {
    final isar = await db;
    isar.writeTxnSync(() {
      sale.syncListsToLinks();
      // 1. Put all SaleItems
      for (var item in sale.allItems) {
        if (item.inventoryItem.value != null) {
          _putInventoryItemSync(isar, item.inventoryItem.value!);
        }
        isar.saleItems.putSync(item);
      }

      // 2. Put PaymentReceived objects
      for (var payment in sale.allPaymentTypes) {
        if (payment.payer.value != null) {
          _putCustomerSync(isar, payment.payer.value!);
        }
        _putPaymentReceivedSync(isar, payment);
      }

      // 3. Put the Sale's direct related entities
      if (sale.customer.value != null) _putCustomerSync(isar, sale.customer.value!);
      if (sale.company.value != null) isar.companys.putSync(sale.company.value!);
      if (sale.branch.value != null) {
        final b = sale.branch.value!;
        if (b.company.value != null) isar.companys.putSync(b.company.value!);
        isar.branchs.putSync(b);
      }
      if (sale.currency.value != null) isar.currencys.putSync(sale.currency.value!);
      if (sale.baseCurrency.value != null) isar.currencys.putSync(sale.baseCurrency.value!);

      // 4. Now put the Sale object.
      isar.sales.putSync(sale);
    });
  }

  Future<List<Sale>> getUnsyncedSales() async {
    final isar = await db;
    return await isar.sales.filter().isSyncedEqualTo(false).findAll();
  }

  Future<List<Sale>> getAllSales() async {
    final isar = await db;
    return await isar.sales.where().findAll();
  }

  Future<void> updateSale(Sale sale) async {
    print('updateSale called: ${sale.isSynced}');
    final isar = await db;
    isar.writeTxnSync(() {
      sale.syncListsToLinks();
      isar.sales.putSync(sale);
    });
  }

  Future<void> saveBranchStocks(List<BranchStock> stocks, {bool clear = false}) async {
    final isar = await db;
    isar.writeTxnSync(() {
      if (clear) {
        isar.branchStocks.clearSync();
      }
      for (var stock in stocks) {
        // 1. Save nested item and its dependencies
        if (stock.item.value != null) {
          _putInventoryItemSync(isar, stock.item.value!);
        }

        // 2. Save branch
        if (stock.branch.value != null) {
          final b = stock.branch.value!;
          if (b.company.value != null) isar.companys.putSync(b.company.value!);
          isar.branchs.putSync(b);
        }

        // 3. Put the BranchStock now that dependencies are saved
        isar.branchStocks.putSync(stock);
      }
    });
  }

  Future<List<BranchStock>> getAllBranchStocks() async {
    final isar = await db;
    return await isar.branchStocks.where().findAll();
  }

  Future<void> clearBranchStocks() async {
    final isar = await db;
    isar.writeTxnSync(() {
      isar.branchStocks.clearSync();
    });
  }

  Future<void> saveCustomers(List<Customer> customers, {bool clear = false}) async {
    final isar = await db;
    isar.writeTxnSync(() {
      if (clear) {
        isar.customers.clearSync();
      }
      for (var customer in customers) {
        _putCustomerSync(isar, customer);
      }
    });
  }

  Future<List<Customer>> getAllCustomers() async {
    final isar = await db;
    return await isar.customers.where().findAll();
  }

  Future<void> clearCustomers() async {
    final isar = await db;
    isar.writeTxnSync(() {
      isar.customers.clearSync();
    });
  }

  Future<void> savePaymentReceived(PaymentReceived payment) async {
    final isar = await db;
    isar.writeTxnSync(() {
      if (payment.payer.value != null) {
        _putCustomerSync(isar, payment.payer.value!);
      }
      _putPaymentReceivedSync(isar, payment);
    });
  }

  Future<List<PaymentReceived>> getUnsyncedPayments() async {
    final isar = await db;
    return await isar.paymentReceiveds.filter().isSyncedEqualTo(false).findAll();
  }

  Future<void> deletePaymentReceived(String paymentId) async {
    final isar = await db;
    isar.writeTxnSync(() {
      isar.paymentReceiveds.filter().idEqualTo(paymentId).deleteAllSync();
    });
  }
}
