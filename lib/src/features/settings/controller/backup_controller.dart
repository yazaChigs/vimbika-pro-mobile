import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import 'package:vimbika_pos_app/src/services/backup_service.dart';

class BackupController extends GetxController {
  var backedUpFiles = <File>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadFiles();
  }

  Future<void> loadFiles() async {
    isLoading.value = true;
    try {
      backedUpFiles.value = await BackupService.getBackedUpFiles();
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<List<dynamic>>> readCsvData(File file) async {
    try {
      final input = await file.readAsString();
      // Use shouldParseNumbers: false to keep everything as strings if needed, 
      // but the main issue is likely the line terminator.
      // CsvToListConverter tries to detect line terminator if not provided.
      final fields = const CsvToListConverter(
        fieldDelimiter: ',',
        eol: '\n',
        shouldParseNumbers: false,
      ).convert(input.replaceAll('\r\n', '\n'));
      return fields;
    } catch (e) {
      Get.snackbar('Error', 'Failed to read file: $e',
          snackPosition: SnackPosition.BOTTOM);
      return [];
    }
  }

  Future<void> shareFile(File file) async {
    try {
      final xFile = XFile(file.path);
      await Share.shareXFiles([xFile], text: 'Backup: ${file.path.split('/').last}');
    } catch (e) {
      Get.snackbar('Error', 'Failed to share file: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> deleteFile(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
        backedUpFiles.remove(file);
        Get.snackbar('Success', 'File deleted successfully',
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete file: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }
}
