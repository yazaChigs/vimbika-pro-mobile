import 'dart:convert';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vimbika_pro/model/sale.dart';
import 'package:file_picker/file_picker.dart';
import 'package:vimbika_pro/model/mobile_shift_currency_amount.dart';

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

  Future<void> exportShiftCurrencyAmountsToExcel(List<MobileShiftCurrencyAmount> amounts) async {
    if (amounts.isEmpty) {
      print("No shift currency amounts to export.");
      return;
    }

    final String? shiftReference = amounts.first.shiftReference;
    if (shiftReference == null || shiftReference.isEmpty) {
      print("Shift reference is missing, cannot create a named Excel file.");
      return;
    }
    final String fileName = shiftReference;

    print("Exporting shift currency amounts to Excel file: $fileName.xlsx");
    
    PermissionStatus status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }
    
    if (!status.isGranted) {
      status = await Permission.manageExternalStorage.request();
    }

    if (status.isGranted) {
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

      Excel excel;
      Sheet sheet;

      if (await file.exists() && await file.length() > 0) {
        try {
          final bytes = await file.readAsBytes();
          excel = Excel.decodeBytes(bytes);
          sheet = excel[excel.getDefaultSheet()!];
        } catch (e) {
          print("Error decoding existing Excel file: $e. Falling back to creating a new one.");
          excel = Excel.createExcel();
          sheet = excel[excel.getDefaultSheet()!];
          // Create header row
          final firstAmountJson = amounts.first.toJson();
          final headers = firstAmountJson.keys.map((key) => TextCellValue(key) as CellValue).toList();
          sheet.appendRow(headers);
        }
      } else {
        excel = Excel.createExcel();
        sheet = excel[excel.getDefaultSheet()!];
        // Create header row only if the file is new
        final firstAmountJson = amounts.first.toJson();
        final headers = firstAmountJson.keys.map((key) => TextCellValue(key) as CellValue).toList();
        sheet.appendRow(headers);
      }

      // Add data rows for all amounts passed in the list
      for (final amount in amounts) {
        final jsonMap = amount.toJson();
        final List<CellValue> row = [];
        
        for (final value in jsonMap.values) {
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
            row.add(TextCellValue(jsonEncode(value)));
          }
        }
        sheet.appendRow(row);
      }

      final List<int>? excelBytes = excel.encode();
      if (excelBytes != null) {
        await file.writeAsBytes(excelBytes);
        print("Successfully wrote to $path");
      }
    } else {
      print("Storage permission not granted. Unable to export Excel.");
    }
  }

  Future<Map<String, dynamic>> importSalesFromExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result != null && result.files.single.path != null) {
        var filePath = result.files.single.path!;
        var bytes = File(filePath).readAsBytesSync();
        Excel excel;
        try {
          excel = Excel.decodeBytes(bytes);
        } catch (e) {
          print("Error decoding Excel file: $e");
          return {'success': false, 'message': 'Unsupported or corrupted Excel file format. Only .xlsx files are supported.', 'sales': []};
        }

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
        return {
          'sales': importedSales,
          'filePath': result.files.single.path,
        };
      }
    } catch (e) {
      print("Error importing Excel file: $e");
    }
    return {};
  }

  Future<List<MobileShiftCurrencyAmount>> importShiftCurrencyAmountsFromExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result != null && result.files.single.path != null) {
        var file = result.files.single.path!;
        var bytes = File(file).readAsBytesSync();
        var excel = Excel.decodeBytes(bytes);

        List<MobileShiftCurrencyAmount> importedAmounts = [];

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

              Map<String, dynamic> amountJson = {};
              for (var j = 0; j < headers.length; j++) {
                if (j < row.length) {
                  var cellValue = row[j]?.value;
                  var header = headers[j];

                  if (cellValue != null && cellValue.toString().isNotEmpty) {
                    try {
                      // Try parsing JSON structures back for maps and lists
                      if (cellValue.toString().startsWith('{') || cellValue.toString().startsWith('[')) {
                        amountJson[header] = jsonDecode(cellValue.toString());
                      } else {
                        amountJson[header] = _parseCellValue(cellValue);
                      }
                    } catch (e) {
                      // Fallback to literal value if JSON decoding fails
                      amountJson[header] = _parseCellValue(cellValue);
                    }
                  } else {
                    amountJson[header] = null;
                  }
                }
              }

              try {
                importedAmounts.add(MobileShiftCurrencyAmount.fromJson(amountJson));
              } catch (e) {
                print("[DEBUG_LOG] Error parsing row $i to MobileShiftCurrencyAmount: $e. Row data: $amountJson");
              }
            }
          }
        }
        return importedAmounts;
      }
    } catch (e) {
      print("Error importing Excel file: $e");
    }
    return [];
  }

  dynamic _parseCellValue(CellValue? value) {
    if (value == null) return null;
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

  Future<void> updateSalesInExcel(String filePath, List<Sale> updatedSales) async {
    try {
      final File file = File(filePath);
      if (!await file.exists()) {
        print("Excel file not found at $filePath");
        return;
      }

      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel[excel.getDefaultSheet()!];

      if (sheet.rows.isEmpty) return;

      final headers = sheet.rows.first.map((e) => e?.value.toString() ?? '').toList();
      final posRefIndex = headers.indexOf('posReference');

      if (posRefIndex == -1) {
        print("posReference column not found in Excel");
        return;
      }

      for (var sale in updatedSales) {
        if (sale.posReference == null) continue;

        for (var i = 1; i < sheet.rows.length; i++) {
          final row = sheet.rows[i];
          if (row.length > posRefIndex) {
            final cellValue = row[posRefIndex]?.value;
            if (cellValue?.toString() == sale.posReference) {
              // Found the row, update it
              final jsonMap = sale.toJson();
              for (var j = 0; j < headers.length; j++) {
                final header = headers[j];
                final value = jsonMap[header];
                CellValue? cellVal;

                if (value == null) {
                  cellVal = TextCellValue('');
                } else if (value is String) {
                  cellVal = TextCellValue(value);
                } else if (value is int) {
                  cellVal = IntCellValue(value);
                } else if (value is num) {
                  cellVal = DoubleCellValue(value.toDouble());
                } else if (value is bool) {
                  cellVal = BoolCellValue(value);
                } else {
                  cellVal = TextCellValue(jsonEncode(value));
                }

                sheet.updateCell(
                  CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i),
                  cellVal,
                );
              }
              break; // Row updated, move to next sale
            }
          }
        }
      }

      final List<int>? excelBytes = excel.encode();
      if (excelBytes != null) {
        await file.writeAsBytes(excelBytes);
        print("Successfully updated sales in Excel: $filePath");
      }
    } catch (e) {
      print("Error updating Excel: $e");
    }
  }
}
