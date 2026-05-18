import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vimbika_pos_app/src/features/sale/model/sale_model.dart';
import 'package:vimbika_pos_app/src/features/shift/model/shift_model.dart';

class BackupService {
  static Future<void> backupSaleToCsv(SaleModel sale) async {
    try {
      Directory? directory = await getBackupDirectory();

      final folderPath = directory.path;
      final folder = Directory(folderPath);
      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }

      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final filePath = '$folderPath/Sales_Backup_$dateStr.csv';
      final file = File(filePath);

      bool fileExists = await file.exists();

      String paymentMethods = sale.paymentTypes?.map((e) => e.paymentType?.name ?? '').join('; ') ?? '';
      
      // Escape quotes in data just in case
      String escapeCsv(String input) {
        return '"' + input.replaceAll('"', '""') + '"';
      }

      String row = '${escapeCsv(sale.timeIniated ?? '')},'
          '${escapeCsv(sale.referenceNumber ?? '')},'
          '${escapeCsv(sale.cashierFullName ?? '')},'
          '${escapeCsv(sale.customer?.name ?? 'WalkIn')},'
          '${escapeCsv((sale.totalQuantity ?? 0).toString())},'
          '${escapeCsv((sale.amountPaid ?? 0).toString())},'
          '${escapeCsv((sale.totalTaxAmount ?? 0).toString())},'
          '${escapeCsv((sale.amountAfterDiscount ?? 0).toString())},'
          '${escapeCsv(paymentMethods)}\n';

      if (!fileExists) {
        String header = '"Date","Reference","Cashier","Customer","Total Quantity","Amount Paid","Tax Amount","Gross Amount","Payment Methods"\n';
        await file.writeAsString(header + row);
      } else {
        await file.writeAsString(row, mode: FileMode.append);
      }
      
      print('Backup successful to $filePath');
    } catch (e) {
      print('Error backing up sale: $e');
    }
  }

  static String escapeCsvValue(String input) {
    if (input.contains(',') || input.contains('"') || input.contains('\n')) {
      return '"' + input.replaceAll('"', '""') + '"';
    }
    return input;
  }

  static Future<void> backupShiftToCsv(ShiftModel shift) async {
    try {
      Directory? directory = await getBackupDirectory();

      final folderPath = '${directory.path}/Shifts';
      final folder = Directory(folderPath);
      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }

      final fileName = '${shift.shiftReference?.replaceAll('/', '_') ?? 'Shift_${shift.id}'}.csv';
      final filePath = '$folderPath/$fileName';
      final file = File(filePath);

      // Create CSV content manually to avoid dependency issues if any,
      // though csv package is in pubspec.
      StringBuffer csvBuffer = StringBuffer();
      // Header
      csvBuffer.writeln('Currency,Amount,Type,Payment Type,Notes,Time Created,Reference');

      if (shift.shiftCurrencyAmounts != null) {
        for (var currencyAmount in shift.shiftCurrencyAmounts!) {
          csvBuffer.write(escapeCsvValue(currencyAmount.currency.name ?? currencyAmount.currency.symbol ?? ''));
          csvBuffer.write(',');
          csvBuffer.write(currencyAmount.amount);
          csvBuffer.write(',');
          csvBuffer.write(escapeCsvValue(currencyAmount.amountType));
          csvBuffer.write(',');
          csvBuffer.write(escapeCsvValue(currencyAmount.paymentType ?? ''));
          csvBuffer.write(',');
          csvBuffer.write(escapeCsvValue(currencyAmount.notes ?? ''));
          csvBuffer.write(',');
          csvBuffer.write(escapeCsvValue(currencyAmount.timeCreated));
          csvBuffer.write(',');
          csvBuffer.write(escapeCsvValue(currencyAmount.ref ?? ''));
          csvBuffer.writeln();
        }
      }

      await file.writeAsString(csvBuffer.toString());
      
      print('Shift backup successful to $filePath');
    } catch (e) {
      print('Error backing up shift: $e');
    }
  }

  static Future<Directory> getBackupDirectory() async {
    Directory? directory;
    if (Platform.isAndroid) {
      directory = await getExternalStorageDirectory();
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    if (directory == null) {
      directory = await getApplicationDocumentsDirectory();
    }

    final folderPath = '${directory.path}/VimbikaBackups';
    final folder = Directory(folderPath);
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    return folder;
  }

  static Future<List<File>> getBackedUpFiles() async {
    try {
      final directory = await getBackupDirectory();
      List<File> files = [];

      // Get sales files from root VimbikaBackups
      if (await directory.exists()) {
        final List<FileSystemEntity> entities = await directory.list().toList();
        for (var entity in entities) {
          if (entity is File && entity.path.endsWith('.csv')) {
            files.add(entity);
          }
        }
      }

      // Get shift files from VimbikaBackups/Shifts
      final shiftsDir = Directory('${directory.path}/Shifts');
      if (await shiftsDir.exists()) {
        final List<FileSystemEntity> entities = await shiftsDir.list().toList();
        for (var entity in entities) {
          if (entity is File && entity.path.endsWith('.csv')) {
            files.add(entity);
          }
        }
      }

      // Sort files by last modified date (oldest first - as requested by "reverse order")
      files.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));

      return files;
    } catch (e) {
      print('Error getting backed up files: $e');
      return [];
    }
  }
}
