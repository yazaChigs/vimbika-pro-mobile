import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:vimbika_pro/app_constants/app_constants.dart';
import 'package:vimbika_pro/model/sale.dart';
import 'package:vimbika_pro/services/default_data_service.dart';

class PdfReceiptService {
  Future<Uint8List> generateReceiptPdf(Sale sale) async {
    final pdf = pw.Document();

    // Load company logo if available
    pw.MemoryImage? logoImage;
    if (sale.company.value?.id != null) {
      try {
        final defaultDataService = DefaultDataService();
        final imageFile = await defaultDataService.getImage(sale.company.value!.id!);
        if (imageFile != null && await imageFile.exists()) {
          final bytes = await imageFile.readAsBytes();
          logoImage = pw.MemoryImage(bytes);
        }
      } catch (_) {}
    }

    final companyName = sale.company.value?.name ?? 'Vimbika Pro';
    final branchName = sale.branch.value?.name ?? '';
    final address = _getReceiptAddress(sale);
    final phone = _getReceiptPhone(sale);
    final receiptNo = sale.referenceNumber ?? sale.posReference ?? '';
    final dateStr = sale.timeIniated != null
        ? DateFormat(AppConstants.APP_DATE_TIME_FMT).format(DateTime.parse(sale.timeIniated!))
        : '';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (logoImage != null) ...[
                        pw.Image(logoImage, width: 60, height: 60),
                        pw.SizedBox(height: 8),
                      ],
                      pw.Text(
                        companyName,
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      if (branchName.isNotEmpty)
                        pw.Text(branchName, style: const pw.TextStyle(fontSize: 12)),
                      if (address.isNotEmpty)
                        pw.Text(address, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      if (phone.isNotEmpty)
                        pw.Text('Tel: $phone', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'SALES RECEIPT',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      if (receiptNo.isNotEmpty)
                        pw.Text('Receipt #: $receiptNo', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                      if (dateStr.isNotEmpty)
                        pw.Text('Date: $dateStr', style: const pw.TextStyle(fontSize: 11)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(thickness: 1, color: PdfColors.grey400),
              pw.SizedBox(height: 8),

              // Customer info if available
              if (sale.customer.value != null) ...[
                pw.Text('Customer Details:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                pw.SizedBox(height: 2),
                pw.Text(sale.customer.value!.name, style: const pw.TextStyle(fontSize: 10)),
                if (sale.customer.value!.mobilePhone != null && sale.customer.value!.mobilePhone!.isNotEmpty)
                  pw.Text('Phone: ${sale.customer.value!.mobilePhone!}', style: const pw.TextStyle(fontSize: 10)),
                if (sale.customer.value!.email != null && sale.customer.value!.email!.isNotEmpty)
                  pw.Text('Email: ${sale.customer.value!.email!}', style: const pw.TextStyle(fontSize: 10)),
                pw.SizedBox(height: 12),
              ],

              // Items Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(4),
                  1: const pw.FlexColumnWidth(1.5),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(2),
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Item', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Qty', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Unit Price', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Total', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ),
                    ],
                  ),
                  // Table Rows
                  ...sale.allItems.map((item) {
                    final itemName = item.inventoryItem.value?.name ?? 'Item';
                    final qty = item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 2);
                    final unitPrice = item.sellingPrice.toStringAsFixed(2);
                    final total = item.total.toStringAsFixed(2);

                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(itemName, style: const pw.TextStyle(fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(qty, textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('\$$unitPrice', textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('\$$total', textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 10)),
                        ),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 12),

              // Summary
              () {
                final double subTotal = sale.baseSaleAmount ??
                    sale.allItems.fold<double>(0.0, (double sum, i) => sum + (i.quantity * i.sellingPrice));
                final double tax = sale.totalTaxAmount ??
                    sale.allItems.fold<double>(0.0, (double sum, i) => sum + i.taxAmount);
                final double discount = sale.totalDiscount ??
                    sale.allItems.fold<double>(0.0, (double sum, i) => sum + i.discountAmount);

                return pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Container(
                      width: 200,
                      child: pw.Column(
                        children: [
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Subtotal:', style: const pw.TextStyle(fontSize: 10)),
                              pw.Text('\$${subTotal.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
                            ],
                          ),
                          if (tax > 0) ...[
                            pw.SizedBox(height: 4),
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text('Tax:', style: const pw.TextStyle(fontSize: 10)),
                                pw.Text('\$${tax.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
                              ],
                            ),
                          ],
                          if (discount > 0) ...[
                            pw.SizedBox(height: 4),
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text('Discount:', style: const pw.TextStyle(fontSize: 10)),
                                pw.Text('-\$${discount.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
                              ],
                            ),
                          ],
                          pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Grand Total:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                              pw.Text('\$${sale.grandTotal.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }(),

              if (sale.allPaymentTypes.isNotEmpty) ...[
                pw.SizedBox(height: 16),
                pw.Text('Payment Breakdown:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                pw.SizedBox(height: 4),
                ...sale.allPaymentTypes.map((p) {
                  final method = p.paymentType.value?.name ?? 'Payment';
                  final amount = p.amount.toStringAsFixed(2);
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 2),
                    child: pw.Text('- $method: \$$amount', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                  );
                }),
              ],

              pw.Spacer(),
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.Center(
                child: pw.Text(
                  'Thank you for your business!',
                  style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<File?> saveReceiptPdfToStorage(Sale sale) async {
    PermissionStatus status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }

    if (!status.isGranted) {
      status = await Permission.manageExternalStorage.request();
    }

    final Uint8List pdfBytes = await generateReceiptPdf(sale);

    Directory? directory;
    if (Platform.isAndroid) {
      directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        directory = await getExternalStorageDirectory();
      }
    } else {
      directory = await getDownloadsDirectory();
      directory ??= await getApplicationDocumentsDirectory();
    }

    if (directory == null) {
      directory = await getApplicationDocumentsDirectory();
    }

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final receiptNo = (sale.referenceNumber ?? sale.posReference ?? 'receipt').replaceAll(RegExp(r'[^\w\-]'), '_');
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'Receipt_${receiptNo}_$timestamp.pdf';
    final filePath = '${directory.path}/$fileName';

    final file = File(filePath);
    await file.writeAsBytes(pdfBytes);
    return file;
  }

  String _getReceiptAddress(Sale sale) {
    final branch = sale.branch.value;
    final company = sale.company.value;

    if (branch != null) {
      final bStreet = branch.street?.trim() ?? "";
      final bCity = branch.city?.trim() ?? "";
      if (bStreet.isNotEmpty && bCity.isNotEmpty) {
        return bStreet.endsWith(',') ? "$bStreet $bCity" : "$bStreet, $bCity";
      } else if (bStreet.isNotEmpty) {
        return bStreet;
      } else if (bCity.isNotEmpty) {
        return bCity;
      }
    }

    if (company != null) {
      final cStreet = company.street?.trim() ?? "";
      final cCity = company.city?.trim() ?? "";
      if (cStreet.isNotEmpty && cCity.isNotEmpty) {
        return cStreet.endsWith(',') ? "$cStreet $cCity" : "$cStreet, $cCity";
      } else if (cStreet.isNotEmpty) {
        return cStreet;
      } else if (cCity.isNotEmpty) {
        return cCity;
      }
    }

    return "";
  }

  String _getReceiptPhone(Sale sale) {
    final branch = sale.branch.value;
    final company = sale.company.value;

    if (branch != null && branch.contactNumber != null && branch.contactNumber!.trim().isNotEmpty) {
      return branch.contactNumber!.trim();
    }
    if (company != null && company.mobilePhone != null && company.mobilePhone!.trim().isNotEmpty) {
      return company.mobilePhone!.trim();
    }
    return "";
  }
}
