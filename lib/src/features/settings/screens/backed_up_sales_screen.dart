import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:intl/intl.dart';
import '../controller/backup_controller.dart';
import 'file_preview_screen.dart';

class BackedUpSalesScreen extends StatelessWidget {
  const BackedUpSalesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final BackupController controller = Get.put(BackupController());
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backed Up Files'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadFiles(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.backedUpFiles.isEmpty) {
          return const Center(
            child: Text('No backed up files found.'),
          );
        }

        return ListView.builder(
          itemCount: controller.backedUpFiles.length,
          itemBuilder: (context, index) {
            final file = controller.backedUpFiles[index];
            final fileName = file.path.split('/').last;
            final isShift = file.path.contains('/Shifts');
            final stats = file.statSync();
            final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(stats.modified);
            final sizeKb = (stats.size / 1024).toStringAsFixed(2);

            return ListTile(
              leading: Icon(
                isShift ? Icons.history : Icons.receipt_long,
                color: isShift ? Colors.blue : Colors.green,
              ),
              title: Text(fileName),
              subtitle: Text('$dateStr • $sizeKb KB'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility, color: Colors.grey),
                    tooltip: 'Preview',
                    onPressed: () => Get.to(() => FilePreviewScreen(file: file)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.download, color: Colors.blue),
                    tooltip: 'Download/Share',
                    onPressed: () => controller.shareFile(file),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Delete',
                    onPressed: () {
                      Get.dialog(
                        AlertDialog(
                          title: const Text('Delete Backup'),
                          content: const Text('Are you sure you want to delete this backup file?'),
                          actions: [
                            TextButton(
                              onPressed: () => Get.back(),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Get.back();
                                controller.deleteFile(file);
                              },
                              child: const Text('Delete', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}
