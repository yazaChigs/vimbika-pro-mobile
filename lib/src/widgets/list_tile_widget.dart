import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vimbika_pos_app/src/features/printers/model/available_printer_model.dart';


class ListTileWidget extends StatelessWidget {
  final AvailablePrinterModel printer;
  final ValueChanged<bool?>? onDefaultChanged;
  final VoidCallback onTestPrinter;

  const ListTileWidget({
    Key? key,
    required this.printer,
    this.onDefaultChanged,
    required this.onTestPrinter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(
        value: printer.isDefault,
        onChanged: onDefaultChanged,
      ),
      title: Text(printer.name ?? 'Unknown Printer'),
      subtitle: Text(printer.type ?? 'Unknown Type'),
      trailing: ElevatedButton(
        onPressed: onTestPrinter,
        child: const Text('Test'),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      tileColor: Colors.grey[200],
    );
  }
}
