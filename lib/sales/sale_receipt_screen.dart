import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:vimbika_pro/model/sale.dart';
import 'package:vimbika_pro/services/default_data_service.dart';
import 'package:vimbika_pro/services/pdf_receipt_service.dart';
import 'package:vimbika_pro/services/printer_service.dart';

import '../app_constants/app_constants.dart';

class SaleReceiptScreen extends StatefulWidget {
  final Sale sale;

  const SaleReceiptScreen({super.key, required this.sale});

  @override
  State<SaleReceiptScreen> createState() => _SaleReceiptScreenState();
}

class _SaleReceiptScreenState extends State<SaleReceiptScreen> {
  File? _logoFile;

  @override
  void initState() {
    super.initState();
    _loadLogo();
  }

  Future<void> _loadLogo() async {
    if (widget.sale.company.value?.id != null) {
      final defaultDataService = DefaultDataService();
      final imageFile = await defaultDataService.getImage(widget.sale.company.value!.id!);
      if (imageFile != null && await imageFile.exists()) {
        setState(() {
          _logoFile = imageFile;
        });
      }
    }
  }

  Future<void> _shareReceipt() async {
    try {
      final StringBuffer buffer = StringBuffer();
      final companyName = widget.sale.company.value?.name ?? 'Vimbika';
      final receiptNo = widget.sale.referenceNumber ?? widget.sale.posReference ?? '';
      final dateStr = widget.sale.timeIniated != null
          ? DateFormat(AppConstants.APP_DATE_TIME_FMT).format(DateTime.parse(widget.sale.timeIniated!))
          : '';

      buffer.writeln(companyName);
      buffer.writeln('Official Sales Receipt');
      buffer.writeln('--------------------------------');
      if (dateStr.isNotEmpty) buffer.writeln('Date: $dateStr');
      if (receiptNo.isNotEmpty) buffer.writeln('Receipt #: $receiptNo');

      if (widget.sale.customer.value != null) {
        buffer.writeln('Customer: ${widget.sale.customer.value!.name}');
        if (widget.sale.customer.value!.mobilePhone != null && widget.sale.customer.value!.mobilePhone!.isNotEmpty) {
          buffer.writeln('Phone: ${widget.sale.customer.value!.mobilePhone}');
        }
      }

      buffer.writeln('--------------------------------');
      buffer.writeln('ITEMS:');
      for (final item in widget.sale.allItems) {
        final itemName = item.inventoryItem.value?.name ?? 'Item';
        final qty = item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 2);
        final total = item.total.toStringAsFixed(2);
        buffer.writeln('- $itemName (x$qty): \$$total');
      }

      buffer.writeln('--------------------------------');
      buffer.writeln('TOTAL: \$${widget.sale.grandTotal.toStringAsFixed(2)}');

      if (widget.sale.allPaymentTypes.isNotEmpty) {
        buffer.writeln('--------------------------------');
        buffer.writeln('PAYMENT DETAILS:');
        for (final p in widget.sale.allPaymentTypes) {
          final method = p.paymentType.value?.name ?? 'Method';
          final amount = p.amount.toStringAsFixed(2);
          buffer.writeln('- $method: \$$amount');
        }
      }

      buffer.writeln('--------------------------------');
      buffer.writeln('Thank you for your business!');

      final box = context.findRenderObject() as RenderBox?;
      await Share.share(
        buffer.toString(),
        subject: 'Sales Receipt ${receiptNo.isNotEmpty ? '#$receiptNo' : ''}'.trim(),
        sharePositionOrigin: box != null ? (box.localToGlobal(Offset.zero) & box.size) : null,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share receipt: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadPdf() async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Generating PDF receipt...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      final pdfService = PdfReceiptService();
      final savedFile = await pdfService.saveReceiptPdfToStorage(widget.sale);

      if (mounted) {
        if (savedFile != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF saved to: ${savedFile.path}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permission denied or failed to save PDF.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.nearlyWhite,
      appBar: AppBar(
        title: const Text('Sale Receipt', style: AppTheme.title),
        backgroundColor: AppTheme.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.nearlyBlack),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            onPressed: () async {
              final printerService = PrinterService();
              // Try to print
              try {
                // Ensure printer is initialized and connected if possible
                await printerService.init();
                if (printerService.isConnected) {
                  await printerService.printSale(widget.sale);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Printing receipt...')),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No printer connected. Please check printer settings.'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to print: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              _shareReceipt();
            },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Download PDF',
            onPressed: () {
              _downloadPdf();
            },
          ),
        ],
      ),
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width > 600 ? 500 : double.infinity,
          margin: const EdgeInsets.all(16),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: SingleChildScrollView( // Added SingleChildScrollView here
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_logoFile != null)
                      Image.file(
                        _logoFile!,
                        height: 100,
                        width: 100,
                      ),
                    Text('${widget.sale.company.value?.name ?? 'Vimbika'}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    const Text('Official Sales Receipt', style: TextStyle(fontSize: 12, color: AppTheme.grey)),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('DATE', style: TextStyle(fontSize: 10, color: AppTheme.grey)),
                            Text(
                              DateFormat(AppConstants.APP_DATE_TIME_FMT).format(DateTime.parse(widget.sale.timeIniated!))
                                , style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('RECEIPT #', style: TextStyle(fontSize: 10, color: AppTheme.grey)),
                            Text(widget.sale.referenceNumber?? widget.sale.posReference!, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    if (widget.sale.customer.value != null) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('CUSTOMER', style: TextStyle(fontSize: 10, color: AppTheme.grey)),
                            Text(widget.sale.customer.value!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            if (widget.sale.customer.value!.mobilePhone != null) Text(widget.sale.customer.value!.mobilePhone!, style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      const Divider(height: 32),
                    ],
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('ITEMS', style: TextStyle(fontSize: 10, color: AppTheme.grey)),
                    ),
                    const SizedBox(height: 8),
                    ...widget.sale.allItems.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text('${item.inventoryItem.value?.name} (x${item.quantity.toStringAsFixed(0)})'),
                          ),
                          Text('\$${item.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    )),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TOTAL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('\$${widget.sale.grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.vimbikaBlue)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (widget.sale.allPaymentTypes.isNotEmpty) ...[
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('PAYMENT DETAILS', style: TextStyle(fontSize: 10, color: AppTheme.grey)),
                      ),
                      const SizedBox(height: 4),
                      ...widget.sale.allPaymentTypes.map((p) => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(p.paymentType.value?.name ?? 'Method', style: const TextStyle(fontSize: 12)),
                          Text('\$${p.amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                        ],
                      )),
                    ],
                    const SizedBox(height: 40),
                    const Text('Thank you for your business!', style: TextStyle(fontStyle: FontStyle.italic, color: AppTheme.grey)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
