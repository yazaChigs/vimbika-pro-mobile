import 'dart:convert';
import 'package:vimbika_pro/app_constants/app_constants.dart';
import 'package:vimbika_pro/base_import_screen.dart';
import 'package:vimbika_pro/model/supplier.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SupplierImportScreen extends BaseImportScreen {
  const SupplierImportScreen({super.key})
      : super(
          title: 'Import Suppliers',
          entityName: 'Suppliers',
          templateFileName: 'supplier_import_template.xlsx',
          columns: const [
            'Name',
            'Email',
            'Phone Number',
            'Address',
            'Contact Person',
          ],
        );

  @override
  Future<void> onImport(BuildContext context, List<List<Data?>> rows) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> existingJson = prefs.getStringList(AppConstants.keySuppliers) ?? [];
    final List<Supplier> suppliers = existingJson
        .map((item) => Supplier.fromJson(jsonDecode(item)))
        .toList();

    int importCount = 0;
    final String nowStr = DateTime.now().millisecondsSinceEpoch.toString();

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;

      if (row.length < 5) continue;

      final supplier = Supplier(
        id: '${nowStr}_$i',
        name: row[0]?.value?.toString().trim() ?? '',
        email: row[1]?.value?.toString().trim() ?? '',
        phoneNumber: row[2]?.value?.toString().trim() ?? '',
        address: row[3]?.value?.toString().trim() ?? '',
        contactPerson: row[4]?.value?.toString().trim() ?? '',
      );

      suppliers.add(supplier);
      importCount++;
    }

    final List<String> updatedJson = suppliers.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList('suppliers', updatedJson);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully imported $importCount suppliers.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
