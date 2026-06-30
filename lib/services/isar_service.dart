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

class IsarService {
  late Future<Isar> db;

  IsarService() {
    db = openDB();
  }

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
        ],
        directory: dir.path,
        inspector: true,
      );
    }

    return Future.value(Isar.getInstance());
  }

  Future<void> saveSale(Sale sale) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.sales.put(sale);
    });
  }

  Future<List<Sale>> getUnsyncedSales() async {
    final isar = await db;
    return await isar.sales.filter().isSyncedEqualTo(false).findAll();
  }

  Future<void> updateSale(Sale sale) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.sales.put(sale);
    });
  }
}
