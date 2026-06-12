import 'dart:io';

import 'package:vimbika_pro/services/default_data_service.dart';
import 'package:vimbika_pro/services/printer_service.dart';
import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:vimbika_pro/model/sale.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    print(widget.sale.items.map((item)=> item.total));
    if (widget.sale.company?.id != null) {
      final defaultDataService = DefaultDataService();
      final imageFile = await defaultDataService.getImage(widget.sale.company!.id!);
      if (imageFile != null && await imageFile.exists()) {
        setState(() {
          _logoFile = imageFile;
        });
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
              print(widget.sale.items.map((item)=> item.toJson()));
              // TODO: Implement PDF sharing/printing
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
                    Text('${widget.sale.company?.name ?? 'Vimbika'}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
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
                              DateFormat(AppConstants.APP_DATE_TIME_FMT).format(DateTime.parse(widget.sale.timeIniated))
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
                    if (widget.sale.customer != null) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('CUSTOMER', style: TextStyle(fontSize: 10, color: AppTheme.grey)),
                            Text(widget.sale.customer!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            if (widget.sale.customer!.phoneNumber != null) Text(widget.sale.customer!.phoneNumber!, style: const TextStyle(fontSize: 12)),
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
                    ...widget.sale.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text('${item.inventoryItem?.name} (x${item.quantity.toStringAsFixed(0)})'),
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
                    if (widget.sale.paymentTypes != null && widget.sale.paymentTypes!.isNotEmpty) ...[
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('PAYMENT DETAILS', style: TextStyle(fontSize: 10, color: AppTheme.grey)),
                      ),
                      const SizedBox(height: 4),
                      ...widget.sale.paymentTypes!.map((p) => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(p.paymentType?.name ?? 'Method', style: const TextStyle(fontSize: 12)),
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
