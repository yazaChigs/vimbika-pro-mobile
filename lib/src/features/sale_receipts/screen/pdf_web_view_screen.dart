import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class PdfWebViewScreen extends StatelessWidget {
  final String url;

  PdfWebViewScreen({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('View and Print Receipt'),
        actions: [
          IconButton(
            icon: Icon(Icons.print),
            onPressed: () {
              _printPdf(url);
            },
          ),
        ],
      ),
      body: PDF().fromUrl(

        url,
        placeholder: (progress) => Center(child: Text('$progress %')),
        errorWidget: (error) => Center(child: Text(error.toString())),
      ),
    );
  }

  // Method to print the PDF using the 'printing' package
  void _printPdf(String url) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async {
        // Load the PDF from the URL
        final pdfBytes = await NetworkAssetBundle(Uri.parse(url)).load(url);
        return pdfBytes.buffer.asUint8List();
      },
    );
  }
}
