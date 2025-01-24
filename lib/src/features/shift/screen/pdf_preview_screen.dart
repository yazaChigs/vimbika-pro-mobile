import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

class PdfPreviewScreen extends StatelessWidget {
  final Future<Uint8List> pdf;

  PdfPreviewScreen({required this.pdf});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('View and Print Receipt'),
        actions: [
          IconButton(
            icon: Icon(Icons.print),
            onPressed: () async {
              await Printing.layoutPdf(
                onLayout: (format) async => await pdf,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Receipt printed successfully")),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () async {
              await Printing.sharePdf(
                bytes: await pdf,
                filename: 'receipt.pdf',
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Receipt shared successfully")),
              );
            },
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => pdf,
      ),
    );
  }
}
