import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:vimbika_pos_app/src/features/sale/model/sale_model.dart';
import 'package:pdf/widgets.dart' as pw;

class GenerateFlutterPdf{
  static Future<Uint8List> generateReceipt(SaleModel sale) async {
    final pdf = pw.Document();

    // Define a custom page format for thermal receipt size (e.g., 80mm x 200mm)
    final PdfPageFormat receiptPageFormat = PdfPageFormat(
      80 * PdfPageFormat.mm, // 80mm width
      200 * PdfPageFormat.mm, // Adjustable height
      marginAll: 5 * PdfPageFormat.mm, // Small margin
    );

    pdf.addPage(
      pw.Page(
        pageFormat: receiptPageFormat,
        build: (pw.Context context) {
          List<pw.Widget> receiptItems = [];

          // Header
          receiptItems.add(
            pw.Text("RECEIPT", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
          );
          receiptItems.add(pw.SizedBox(height: 10));
          receiptItems.add(pw.Text("Date: ${sale.timeIniated}", textAlign: pw.TextAlign.left));
          receiptItems.add(pw.Text("Reference: ${sale.referenceNumber}", textAlign: pw.TextAlign.left));

          // Customer Information
          if (sale.customer != null) {
            receiptItems.add(pw.Text("Customer: ${sale.customer!.name}", textAlign: pw.TextAlign.left));
          }

          receiptItems.add(pw.Divider());

          // Items
          for (var item in sale.items!) {
            String itemName = item.inventoryItem?.name ?? 'Item';
            double quantity = item.quantity ?? 0;
            double price = item.sellingPrice ?? 0;
            double total = item.total ?? 0;

            receiptItems.add(
              pw.Text(
                itemName,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
                textAlign: pw.TextAlign.left,
              ),
            );
            receiptItems.add(
              pw.Text("Qty: $quantity  Price: ${price.toStringAsFixed(2)}", textAlign: pw.TextAlign.left),
            );
            receiptItems.add(
              pw.Text("Total: ${total.toStringAsFixed(2)}", textAlign: pw.TextAlign.left),
            );
            receiptItems.add(pw.Divider());
          }

          // Totals
          receiptItems.add(pw.Text("Subtotal: ${sale.currency!.symbol} ${sale.amountPaid?.toStringAsFixed(2)}", textAlign: pw.TextAlign.right));
          receiptItems.add(pw.Text("Amount Paid: ${sale.currency!.symbol} ${sale.amountPaid?.toStringAsFixed(2)}", textAlign: pw.TextAlign.right));
          receiptItems.add(pw.Text("Change: ${sale.currency!.symbol} ${sale.change?.toStringAsFixed(2)}", textAlign: pw.TextAlign.right));

          // Footer
          receiptItems.add(pw.SizedBox(height: 20));
          receiptItems.add(
            pw.Text(
              "Thank you for your purchase!",
              style: pw.TextStyle(fontWeight: pw.FontWeight.normal, fontSize: 12),
              textAlign: pw.TextAlign.center,
            ),
          );

          return pw.Column(children: receiptItems);
        },
      ),
    );

    return pdf.save();
  }
}