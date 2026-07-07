import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vimbika_pro/app_constants/app_constants.dart';
import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:vimbika_pro/model/sale.dart';
import 'package:vimbika_pro/services/excel_export_service.dart';
import 'package:vimbika_pro/services/sale_sync_service.dart';

class ImportedSalesPreviewScreen extends StatefulWidget {
  final List<Sale> importedSales;
  final String? excelFilePath;

  const ImportedSalesPreviewScreen({
    super.key, 
    required this.importedSales,
    this.excelFilePath,
  });

  @override
  _ImportedSalesPreviewScreenState createState() => _ImportedSalesPreviewScreenState();
}

class _ImportedSalesPreviewScreenState extends State<ImportedSalesPreviewScreen> {
  late Set<int> _selectedIndices;
  bool _isSyncing = false;
  final SaleSyncService _saleSyncService = SaleSyncService();
  final ExcelExportService _excelExportService = ExcelExportService();
  late List<Sale> _currentSales;

  @override
  void initState() {
    super.initState();
    _currentSales = List.from(widget.importedSales);
    print(('_currentSales: ${_currentSales.first.items.length}'));
    // By default, all imported sales are selected by index
    _selectedIndices = Set.from(Iterable<int>.generate(_currentSales.length));
  }

  Future<void> _syncToApi() async {
    if (_selectedIndices.isEmpty) return;

    setState(() => _isSyncing = true);

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? userData = prefs.getString(AppConstants.keyOnlineUserData);
      
      if (userData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please login online to sync sales')),
          );
        }
        setState(() => _isSyncing = false);
        return;
      }

      final Map<String, dynamic> userMap = jsonDecode(userData);
      final String? companyId = userMap['branch']?['company']?['id'];

      if (companyId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Company ID not found. Please relogin.')),
          );
        }
        setState(() => _isSyncing = false);
        return;
      }

      final List<Sale> salesToSync = _selectedIndices
          .map((index) => _currentSales[index])
          .where((sale) => sale.isSynced != true)
          .toList();

      if (salesToSync.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Selected sales are already synced')),
          );
        }
        setState(() => _isSyncing = false);
        return;
      }

      print('Syncing ${salesToSync.length} sales... ${salesToSync.first.items.length}');
      final List<Sale> syncedSales = await _saleSyncService.syncSelectedSales(salesToSync, companyId);
      
      // Update local state and excel
      final List<Sale> successfullySynced = syncedSales.where((s) => s.isSynced == true).toList();
      
      if (successfullySynced.isNotEmpty) {
        if (widget.excelFilePath != null) {
          await _excelExportService.updateSalesInExcel(widget.excelFilePath!, successfullySynced);
        }

        setState(() {
          for (var syncedSale in successfullySynced) {
            final index = _currentSales.indexWhere((s) => s.posReference == syncedSale.posReference);
            if (index != -1) {
              _currentSales[index] = syncedSale;
            }
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Successfully synced ${successfullySynced.length} sales')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to sync sales. Check connection.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during sync: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  String _formatDate(String dateString) {
    try {
      DateTime date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString; // fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview Imported Sales'),
        actions: [
          if (_selectedIndices.any((i) => _currentSales[i].isSynced != true))
            IconButton(
              icon: _isSyncing 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.cloud_upload),
              onPressed: _isSyncing ? null : _syncToApi,
              tooltip: 'Sync Selected to API',
            ),
          IconButton(
            icon: Icon(
              _selectedIndices.length == _currentSales.length 
                  ? Icons.deselect
                  : Icons.select_all
            ),
            onPressed: () {
              setState(() {
                if (_selectedIndices.length == _currentSales.length) {
                  _selectedIndices.clear();
                } else {
                  _selectedIndices = Set.from(Iterable<int>.generate(_currentSales.length));
                }
              });
            },
            tooltip: 'Select/Deselect All',
          )
        ],
      ),
      body: Column(
        children: [
          if (_isSyncing)
            const LinearProgressIndicator(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _currentSales.length,
              itemBuilder: (context, index) {
                final sale = _currentSales[index];
                final isSelected = _selectedIndices.contains(index);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? AppTheme.vimbikaBlue : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedIndices.remove(index);
                        } else {
                          _selectedIndices.add(index);
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Checkbox(
                            value: isSelected,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _selectedIndices.add(index);
                                } else {
                                  _selectedIndices.remove(index);
                                }
                              });
                            },
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        sale.customer.value?.name ?? 'Walk-in Customer',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (sale.isSynced == true)
                                      const Icon(Icons.check_circle, color: Colors.green, size: 16)
                                    else
                                      const Icon(Icons.cloud_off, color: Colors.orange, size: 16),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(sale.timeIniated!))} • ${sale.allItems.length} items',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.grey),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${sale.currency.value?.symbol ?? ''}${sale.grandTotal.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppTheme.vimbikaBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _selectedIndices.isNotEmpty
                  ? () {
                      final selectedSales = _selectedIndices
                          .map((index) => _currentSales[index])
                          .toList();
                      Navigator.pop(context, selectedSales);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: AppTheme.vimbikaBlue,
                foregroundColor: Colors.white,
              ),
              child: Text('Import ${_selectedIndices.length} Selected Sales'),
            ),
          ),
        ],
      ),
    );
  }
}
