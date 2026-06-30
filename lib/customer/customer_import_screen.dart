import 'dart:convert';
import 'package:vimbika_pro/app_constants/app_constants.dart';
import 'package:vimbika_pro/base_import_screen.dart';
import 'package:vimbika_pro/model/customer.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomerImportScreen extends BaseImportScreen {
  const CustomerImportScreen({super.key})
      : super(
          title: 'Import Customers',
          entityName: 'Customers',
          templateFileName: 'customer_import_template.xlsx',
          columns: const [
            'Name',
            'Email',
            'Phone Number',
            'Address',
          ],
        );

  @override
  Future<void> onImport(BuildContext context, List<List<Data?>> rows) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> existingJson = prefs.getStringList(AppConstants.keyCustomers) ?? [];
    final List<Customer> customers = existingJson
        .map((item) => Customer.fromJson(jsonDecode(item)))
        .toList();

    int importCount = 0;
    final String nowStr = DateTime.now().millisecondsSinceEpoch.toString();

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;

      if (row.length < 4) continue;

      final customer = Customer(
        id: '${nowStr}_$i',
        name: row[0]?.value?.toString().trim() ?? '',
        email: row[1]?.value?.toString().trim() ?? '',
        mobilePhone: row[2]?.value?.toString().trim() ?? '',
        address: row[3]?.value?.toString().trim() ?? '',
      );

      customers.add(customer);
      importCount++;
    }

    final List<String> updatedJson = customers.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList('customers', updatedJson);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully imported $importCount customers.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
