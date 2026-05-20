import 'dart:io';
import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

abstract class BaseImportScreen extends StatelessWidget {
  final String title;
  final String entityName;
  final List<String> columns;
  final String templateFileName;

  const BaseImportScreen({
    super.key,
    required this.title,
    required this.entityName,
    required this.columns,
    required this.templateFileName,
  });

  Future<void> onImport(BuildContext context, List<List<Data?>> rows);

  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      // For Android 11 (API 30) and above
      if (await Permission.manageExternalStorage.isGranted) {
        return true;
      }
      
      // Request Manage External Storage (scoped storage workaround)
      final status = await Permission.manageExternalStorage.request();
      if (status.isGranted) {
        return true;
      }

      // Fallback for older Android versions
      final storageStatus = await Permission.storage.request();
      return storageStatus.isGranted;
    }
    return true;
  }

  Future<void> _downloadTemplate(BuildContext context) async {
    try {
      if (!await _requestPermissions()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Storage permission denied'), backgroundColor: Colors.red),
          );
        }
        return;
      }

      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Sheet1'];

      // Add Headers
      for (var i = 0; i < columns.length; i++) {
        var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(columns[i]);
      }

      final List<int>? fileBytes = excel.save();
      if (fileBytes == null) throw Exception('Could not generate Excel file');

      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) throw Exception('Could not access storage');

      final String filePath = '${directory.path}/$templateFileName';
      final File file = File(filePath);
      
      await file.writeAsBytes(fileBytes);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Template saved to: $filePath'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving template: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _importFile(BuildContext context) async {
    try {
      if (!await _requestPermissions()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Storage permission denied'), backgroundColor: Colors.red),
          );
        }
        return;
      }

      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) throw Exception('Could not access storage');

      final String filePath = '${directory.path}/$templateFileName';
      final File file = File(filePath);

      if (!await file.exists()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please fill and save the $entityName template first.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final bytes = await file.readAsBytes();
      var excel = Excel.decodeBytes(bytes);
      
      List<List<Data?>> rows = [];
      for (var table in excel.tables.keys) {
        rows.addAll(excel.tables[table]!.rows);
      }

      if (rows.length <= 1) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File is empty.')),
          );
        }
        return;
      }

      await onImport(context, rows);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing file: $e'),
            backgroundColor: Colors.red,
          ),
        );
        print('Error importing file: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.nearlyWhite,
      appBar: AppBar(
        title: Text(title, style: AppTheme.title),
        backgroundColor: AppTheme.white,
        iconTheme: IconThemeData(color: AppTheme.nearlyBlack),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Follow these steps to import $entityName:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkText,
              ),
            ),
            const SizedBox(height: 24),
            _buildStep(
              context,
              number: '1',
              title: 'Download Template',
              description: 'Download the Excel template for $entityName correctly.',
              icon: Icons.download,
              buttonLabel: 'Download Template',
              onPressed: () => _downloadTemplate(context),
            ),
            const SizedBox(height: 32),
            _buildStep(
              context,
              number: '2',
              title: 'Upload Filled File',
              description: 'Once you have filled the template, upload it here to import your data.',
              icon: Icons.upload_file,
              buttonLabel: 'Select & Import File',
              onPressed: () => _importFile(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(
    BuildContext context, {
    required String number,
    required String title,
    required String description,
    required IconData icon,
    required String buttonLabel,
    required VoidCallback onPressed,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: AppTheme.vimbikaBlue,
              child: Text(
                number,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                description,
                style: TextStyle(fontSize: 14, color: AppTheme.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onPressed,
                icon: Icon(icon),
                label: Text(buttonLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.vimbikaBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
