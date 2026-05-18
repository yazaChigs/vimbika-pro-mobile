import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/backup_controller.dart';

class FilePreviewScreen extends StatelessWidget {
  final File file;
  const FilePreviewScreen({Key? key, required this.file}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final BackupController controller = Get.find<BackupController>();
    final fileName = file.path.split('/').last;

    return Scaffold(
      appBar: AppBar(
        title: Text(fileName),
      ),
      body: FutureBuilder<List<List<dynamic>>>(
        future: controller.readCsvData(file),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No data found in file.'));
          }

          final data = snapshot.data!;
          if (data.isEmpty) {
            return const Center(child: Text('No data found in file.'));
          }
          final headers = data[0].map((e) => e.toString()).toList();
          // Reverse the rows to show newest first (since CSV is append-only)
          final rows = data.skip(1).toList().reversed.toList();

          final isShift = file.path.contains('/Shifts');
          
          Widget summaryWidget = const SizedBox.shrink();

          if (!isShift) {
            // Sales Summary
            int amountPaidIndex = headers.indexOf('Amount Paid');
            if (amountPaidIndex != -1) {
              double totalSales = 0;
              for (var row in rows) {
                if (amountPaidIndex < row.length) {
                  totalSales += double.tryParse(row[amountPaidIndex].toString()) ?? 0;
                }
              }
              summaryWidget = Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Total Sales: ${totalSales.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              );
            }
          } else {
            // Shifts Summary
            int currencyIndex = headers.indexOf('Currency');
            int amountIndex = headers.indexOf('Amount');
            int paymentTypeIndex = headers.indexOf('Payment Type');

            if (currencyIndex != -1 && amountIndex != -1 && paymentTypeIndex != -1) {
              Map<String, double> totalsByCurrency = {};
              Map<String, double> totalsByPaymentType = {};

              for (var row in rows) {
                if (currencyIndex < row.length && amountIndex < row.length && paymentTypeIndex < row.length) {
                  String currency = row[currencyIndex].toString();
                  String paymentType = row[paymentTypeIndex].toString();
                  double amount = double.tryParse(row[amountIndex].toString()) ?? 0;

                  totalsByCurrency[currency] = (totalsByCurrency[currency] ?? 0) + amount;
                  totalsByPaymentType[paymentType] = (totalsByPaymentType[paymentType] ?? 0) + amount;
                }
              }

              summaryWidget = Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Totals by Currency:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ...totalsByCurrency.entries.map((e) => Text('${e.key}: ${e.value.toStringAsFixed(2)}')),
                    const SizedBox(height: 8),
                    const Text('Totals by Payment Type:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ...totalsByPaymentType.entries.map((e) => Text('${e.key}: ${e.value.toStringAsFixed(2)}')),
                  ],
                ),
              );
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              summaryWidget,
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: headers
                          .map((header) => DataColumn(
                                label: Text(
                                  header,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ))
                          .toList(),
                      rows: rows
                          .map((row) => DataRow(
                                cells: List.generate(headers.length, (index) {
                                  final cellValue = index < row.length ? row[index] : '';
                                  return DataCell(Text(cellValue.toString()));
                                }),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
