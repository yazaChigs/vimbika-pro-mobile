import 'dart:convert';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vimbika_pro/model/sale.dart';
import 'package:file_picker/file_picker.dart';

class ExcelExportService {
  Future<void> exportSalesToExcel(List<Sale> sales, String fileName) async {
    print("Exporting sales to Excel...");
    
    PermissionStatus status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }
    
    // For Android 13+ (API 33+), manage external storage might be needed or media permissions
    if (!status.isGranted) {
      status = await Permission.manageExternalStorage.request();
    }

    if (status.isGranted) {
      final excel = Excel.createExcel();
      final Sheet sheet = excel[excel.getDefaultSheet()!];

      if (sales.isNotEmpty) {
        // Add header row dynamically from JSON keys
        final firstSaleJson = sales.first.toJson();
        final headers = firstSaleJson.keys.map((key) => TextCellValue(key) as CellValue).toList();
        sheet.appendRow(headers);

        // Add data rows
        for (final sale in sales) {
          final json = sale.toJson();
          final List<CellValue> row = [];
          
          for (final value in json.values) {
            if (value == null) {
              row.add(TextCellValue(''));
            } else if (value is String) {
              row.add(TextCellValue(value));
            } else if (value is int) {
              row.add(IntCellValue(value));
            } else if (value is num) {
              row.add(DoubleCellValue(value.toDouble()));
            } else if (value is bool) {
              row.add(BoolCellValue(value));
            } else {
              // Serialize nested Maps or Lists to JSON string
              row.add(TextCellValue(jsonEncode(value)));
            }
          }
          sheet.appendRow(row);
        }
      } else {
        sheet.appendRow([TextCellValue('No sales available to export.')]);
      }

      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getDownloadsDirectory();
      }

      final String path = '${directory!.path}/$fileName.xlsx';
      print('Excel file path: $path');
      final File file = File(path);

      final List<int>? excelBytes = excel.encode();
      if (excelBytes != null) {
        await file.writeAsBytes(excelBytes);
      }
    } else {
      print("Storage permission not granted. Unable to export Excel.");
    }
  }

  Future<List<Sale>> importSalesFromExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result != null && result.files.single.path != null) {
        var file = result.files.single.path!;
        var bytes = File(file).readAsBytesSync();
        var excel = Excel.decodeBytes(bytes);

        List<Sale> importedSales = [];

        for (var table in excel.tables.keys) {
          var sheet = excel.tables[table];
          if (sheet != null && sheet.rows.isNotEmpty) {
            // First row should be headers
            var headers = sheet.rows.first.map((e) => e?.value.toString() ?? '').toList();

            for (var i = 1; i < sheet.rows.length; i++) {
              var row = sheet.rows[i];
              if (row.isEmpty || row.every((cell) => cell == null || cell.value == null)) {
                  continue; // Skip empty rows
              }

              Map<String, dynamic> saleJson = {};
              for (var j = 0; j < headers.length; j++) {
                if (j < row.length) {
                  var cellValue = row[j]?.value;
                  var header = headers[j];
                  
                  if (cellValue != null && cellValue.toString().isNotEmpty) {
                    try {
                        // Try parsing JSON structures back for maps and lists
                        if (cellValue.toString().startsWith('{') || cellValue.toString().startsWith('[')) {
                             saleJson[header] = jsonDecode(cellValue.toString());
                        } else {
                            saleJson[header] = _parseCellValue(cellValue);
                        }
                    } catch (e) {
                         // Fallback to literal value if JSON decoding fails
                         saleJson[header] = _parseCellValue(cellValue);
                    }
                  } else {
                      saleJson[header] = null;
                  }
                }
              }
              
              try {
                  importedSales.add(Sale.fromJson(saleJson));
              } catch (e) {
                  print("Error parsing row $i to Sale: $e");
              }
            }
          }
        }
        return importedSales;
      }
    } catch (e) {
      print("Error importing Excel file: $e");
    }
    return [];
  }

  dynamic _parseCellValue(dynamic value) {
      if (value is IntCellValue) return value.value;
      if (value is DoubleCellValue) return value.value;
      if (value is BoolCellValue) return value.value;
      if (value is TextCellValue) {
          final textValue = value.value.toString();
          
          // Handle 'true'/'false' strings if they represent booleans
          if (textValue.toLowerCase() == 'true') return true;
          if (textValue.toLowerCase() == 'false') return false;
          
          // Check if string is actually a number
          var numValue = num.tryParse(textValue);
          if (numValue != null) return numValue;
          
          return textValue;
      }
      return value.toString();
  }
}
