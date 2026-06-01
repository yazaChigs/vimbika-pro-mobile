import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class SalesBackupScreen extends StatefulWidget {
  const SalesBackupScreen({super.key});

  @override
  _SalesBackupScreenState createState() => _SalesBackupScreenState();
}

class _SalesBackupScreenState extends State<SalesBackupScreen> {
  List<File> _backupFiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    setState(() {
      _isLoading = true;
    });
    try {
      Directory? directory;
      directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        directory = await getExternalStorageDirectory();
      }
      if (directory != null) {
        final List<FileSystemEntity> entities = directory.listSync();
        final List<File> excelFiles = entities
            .whereType<File>()
            .where((file) => file.path.endsWith('.xlsx') && file.path.contains('sales_backup_'))
            .toList();
            
        // Sort files by modified date descending
        excelFiles.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
        
        setState(() {
          _backupFiles = excelFiles;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading backups: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _shareFile(File file) {
    Share.shareXFiles([XFile(file.path)], text: 'Sales Backup');
  }

  Future<void> _downloadFile(File file) async {
    try {
      PermissionStatus status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }
      
      if (!status.isGranted) {
         status = await Permission.manageExternalStorage.request();
      }

      if (status.isGranted) {
        Directory? downloadsDir;
        if (Platform.isAndroid) {
           downloadsDir = Directory('/storage/emulated/0/Download');
           if (!downloadsDir.existsSync()) {
               downloadsDir = await getExternalStorageDirectory();
           }
        } else {
           downloadsDir = await getApplicationDocumentsDirectory();
        }

        if (downloadsDir != null) {
          final String newPath = '${downloadsDir.path}/${file.path.split('/').last}';
          await file.copy(newPath);
          
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text('File downloaded to: $newPath')),
             );
          }
        }
      } else {
         if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Storage permission is required to download files.')),
             );
         }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading file: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.nearlyWhite,
      appBar: AppBar(
        title: const Text('Sales Backups', style: AppTheme.title),
        backgroundColor: AppTheme.white,
        iconTheme: const IconThemeData(color: AppTheme.nearlyBlack),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBackups,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _backupFiles.isEmpty
              ? const Center(
                  child: Text(
                    'No backups found.',
                    style: TextStyle(fontSize: 18, color: AppTheme.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _backupFiles.length,
                  itemBuilder: (context, index) {
                    final file = _backupFiles[index];
                    final fileName = file.path.split('/').last;
                    final fileDate = file.lastModifiedSync();
                    final fileSize = (file.lengthSync() / 1024).toStringAsFixed(2); // KB

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppTheme.vimbikaBlue,
                          child: Icon(Icons.table_chart, color: AppTheme.white),
                        ),
                        title: Text(
                          fileName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Modified: ${fileDate.year}-${fileDate.month.toString().padLeft(2, '0')}-${fileDate.day.toString().padLeft(2, '0')} ${fileDate.hour.toString().padLeft(2, '0')}:${fileDate.minute.toString().padLeft(2, '0')}\nSize: $fileSize KB',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.download, color: AppTheme.vimbikaBlue),
                              onPressed: () => _downloadFile(file),
                              tooltip: 'Download to Downloads folder',
                            ),
                            IconButton(
                              icon: const Icon(Icons.share, color: AppTheme.vimbikaBlue),
                              onPressed: () => _shareFile(file),
                              tooltip: 'Share',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
