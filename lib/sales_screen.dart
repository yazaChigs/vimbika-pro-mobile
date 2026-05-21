import 'services/printer_service.dart';
import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:vimbika_pro/sale_receipt_screen.dart';
import 'package:vimbika_pro/model/branch.dart';
import 'package:vimbika_pro/model/customer.dart';
import 'package:vimbika_pro/model/mobile_pos_shift.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'app_constants/app_constants.dart';
import 'model/sale.dart';
import 'package:intl/intl.dart';
import 'services/excel_export_service.dart';
import 'services/sale_service.dart'; // Import SaleService
import 'package:provider/provider.dart'; // Import provider
import 'custom_drawer/home_drawer.dart'; // Import DrawerIndex
import 'navigation_home_screen.dart'; // Import NavigationProvider

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  _SalesScreenState createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  List<Sale> _allSales = [];
  List<Sale> _filteredSales = [];
  
  List<Branch> _branches = [];
  List<Customer> _customers = [];
  
  String _searchQuery = '';
  Branch? _selectedBranch;
  Customer? _selectedCustomer;
  String _selectedStatus = 'All'; // All, Fully Paid, Partially Paid
  bool _currentShiftOnly = false;
  
  bool _isLoading = true;
  MobilePosShift? _currentShift;

  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  final DateTime _apiStartDate = DateTime.now().subtract(const Duration(days: 7)).copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
  final DateTime _apiEndDate = DateTime.now().copyWith(hour: 23, minute: 59, second: 59, millisecond: 999, microsecond: 999);

  final SaleService _saleService = SaleService(); // Initialize SaleService
  final ExcelExportService _excelExportService = ExcelExportService();

  double get _totalRevenue {
    double total = 0;
    for (var sale in _filteredSales) {
      if (sale.status != 'Reversed') {
        total += sale.grandTotal;
      }
    }
    return total;
  }

  @override
  void initState() {
    super.initState();
    _filterStartDate = DateTime.now().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
    _filterEndDate = DateTime.now().copyWith(hour: 23, minute: 59, second: 59, millisecond: 999, microsecond: 999);
    _loadLocalData().then((_) {
      _syncOnlineSales();
    });
  }

  Future<void> _loadLocalData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    
    _currentShift = await _getCurrentShift();

    // Load Branches
    final List<String> branchJson = prefs.getStringList('branches') ?? [];
    final List<Branch> loadedBranches = branchJson.map((e) => Branch.fromJson(jsonDecode(e))).toList();

    // Load Customers
    final List<String> customerJson = prefs.getStringList('customers') ?? [];
    final List<Customer> loadedCustomers = customerJson.map((e) => Customer.fromJson(jsonDecode(e))).toList();

    final bool isOfflineMode = prefs.getBool(AppConstants.keyIsOfflineMode) ?? false;
    final String salesKey = isOfflineMode ? AppConstants.keyOfflineSales : AppConstants.keySales;
    const String backupSalesKey = 'backup_sales';

    // Load local sales from SharedPreferences
    final List<String> localSalesJson = prefs.getStringList(salesKey) ?? [];
    final List<Sale> localSales = localSalesJson.map((e) => Sale.fromJson(jsonDecode(e))).toList();
    
    // Load backup sales from SharedPreferences
    final List<String> backupSalesJson = prefs.getStringList(backupSalesKey) ?? [];
    final List<Sale> backupSales = backupSalesJson.map((e) => Sale.fromJson(jsonDecode(e))).toList();

    final Map<String, Sale> combinedSalesMap = {};

    for (var sale in localSales) {
      final String? key = sale.posReference ?? sale.id;
      if (key != null) {
        combinedSalesMap[key] = sale;
      }
    }
    
    for (var sale in backupSales) {
      final String? key = sale.posReference ?? sale.id;
      if (key != null && !combinedSalesMap.containsKey(key)) {
        combinedSalesMap[key] = sale;
      }
    }

    List<Sale> combinedSales = combinedSalesMap.values.toList();
    combinedSales.sort((a, b) => b.timeIniated.compareTo(a.timeIniated));

    if (mounted) {
      setState(() {
        _branches = loadedBranches;
        _customers = loadedCustomers;
        _allSales = combinedSales;
        _isLoading = false;
        _applyFilters();
      });
    }
  }

  Future<void> _syncOnlineSales() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool isOfflineMode = prefs.getBool(AppConstants.keyIsOfflineMode) ?? false;
    if (isOfflineMode) return;

    try {
      final fetchedOnlineSales = await _saleService.fetchSales(
        startDate: _apiStartDate,
        endDate: _apiEndDate,
        branchId: _selectedBranch?.id,
      );
      List<Sale> onlineSales = fetchedOnlineSales.map((s) => Sale.fromOnlineSale(s)).toList();

      final Map<String, Sale> salesMap = { for (var s in _allSales) (s.posReference ?? s.id)!: s };

      for (var sale in onlineSales) {
        final String? key = sale.posReference ?? sale.id;
        if (key != null) {
          salesMap[key] = sale;
        }
      }

      List<Sale> combinedSales = salesMap.values.toList();
      combinedSales.sort((a, b) => b.timeIniated.compareTo(a.timeIniated));

      // Save combined sales to backup to avoid re-fetching
      await prefs.setStringList('backup_sales', combinedSales.map((s) => jsonEncode(s.toJson())).toList());

      if (mounted) {
        setState(() {
          _allSales = combinedSales;
          _applyFilters();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sync online sales: $e')),
        );
      }
    }
  }

  Future<MobilePosShift?> _getCurrentShift() async {
    final prefs = await SharedPreferences.getInstance();
    final currentShiftJson = prefs.getString(AppConstants.keyCurrentOpenShift);
    if (currentShiftJson != null) {
      return MobilePosShift.fromRawJson(currentShiftJson);
    }
    return null;
  }

  Future<void> _loadData() async {
    await _loadLocalData();
    await _syncOnlineSales();
  }

  void _applyFilters() {
    if (mounted) {
      setState(() {
        _filteredSales = _allSales.where((sale) {
          // 1. Search Filter (Customer Name or Sale ID)
          final matchesSearch = (sale.customer?.name.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) || 
                               (sale.id?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
                               (_searchQuery.isEmpty);

          // 2. Branch Filter
          final matchesBranch = _selectedBranch == null || sale.branch?.id == _selectedBranch!.id;

          // 3. Customer Filter
          final matchesCustomer = _selectedCustomer == null || sale.customer?.id == _selectedCustomer!.id;

          // 4. Status Filter
          final matchesStatus = _selectedStatus == 'All' || sale.status == _selectedStatus;

          // 5. Shift Filter
          bool matchesShift = true;
          if (_currentShiftOnly && _currentShift != null) {
             matchesShift = sale.shiftReference == _currentShift?.shiftReference;
          }
          
          // 6. Date Filter
          bool matchesDate = true;
          if (_filterStartDate != null && _filterEndDate != null) {
              try {
                  DateTime saleDate = DateTime.parse(sale.timeIniated);
                  matchesDate = saleDate.isAfter(_filterStartDate!) && saleDate.isBefore(_filterEndDate!);
              } catch (e) {
                  matchesDate = false;
              }
          }

          return matchesSearch && matchesBranch && matchesCustomer && matchesStatus && matchesShift && matchesDate;
        }).toList();
      });
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

  Future<void> _reverseSale(Sale sale) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reverse Sale?'),
        content: const Text('Are you sure you want to reverse this sale? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reverse', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }
      try {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final bool isOfflineMode = prefs.getBool(AppConstants.keyIsOfflineMode) ?? false;
        final String salesKey = isOfflineMode ? AppConstants.keyOfflineSales : AppConstants.keySales;

        final List<String> localSalesJson = prefs.getStringList(salesKey) ?? [];
        final List<Sale> localSales = localSalesJson.map((e) => Sale.fromJson(jsonDecode(e))).toList();

        // Update local status
        int localIndex = localSales.indexWhere((s) => s.id == sale.id || s.posReference == sale.posReference);
        if (localIndex != -1) {
          localSales[localIndex] = localSales[localIndex].copyWith(status: 'Reversed');
          await prefs.setStringList(salesKey, localSales.map((s) => jsonEncode(s.toJson())).toList());
        }

        // Run to API if synced and id is not null (which means it comes from API usually)
        if (sale.isSynced == true && sale.id != null) {
          await _saleService.reverseSale(sale.id!);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sale reversed successfully'), backgroundColor: Colors.green),
          );
        }
        await _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to reverse sale: $e'), backgroundColor: Colors.red),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _filterStartDate != null && _filterEndDate != null 
          ? DateTimeRange(start: _filterStartDate!, end: _filterEndDate!)
          : null,
    );
    if (picked != null) {
      if (mounted) {
        setState(() {
          _filterStartDate = picked.start.copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
          _filterEndDate = picked.end.copyWith(hour: 23, minute: 59, second: 59, millisecond: 999, microsecond: 999);
        });
      }
      _applyFilters();
    }
  }

  Future<void> _exportSales() async {
    if (_filteredSales.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No sales to export.'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (mounted) setState(() => _isLoading = true);
    try {
      final String fileName = 'Sales_Export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}';
      await _excelExportService.exportSalesToExcel(_filteredSales, fileName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sales exported as $fileName.xlsx'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export sales: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _importSales() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final List<Sale> importedSales = await _excelExportService.importSalesFromExcel();
      if (importedSales.isNotEmpty) {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        const String backupSalesKey = 'backup_sales';
        
        // Get existing backup sales
        final List<String> existingBackupJson = prefs.getStringList(backupSalesKey) ?? [];
        final Map<String, Sale> backupSalesMap = { 
            for (var s in existingBackupJson.map((e) => Sale.fromJson(jsonDecode(e)))) 
                (s.posReference ?? s.id)!: s 
        };

        // Add new imported sales, overwriting duplicates
        for (var sale in importedSales) {
            final String? key = sale.posReference ?? sale.id;
            if (key != null) {
                backupSalesMap[key] = sale;
            }
        }

        // Save the combined list back to SharedPreferences
        final List<String> combinedBackupJson = backupSalesMap.values.map((s) => jsonEncode(s.toJson())).toList();
        await prefs.setStringList(backupSalesKey, combinedBackupJson);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${importedSales.length} sales imported successfully!'), backgroundColor: Colors.green),
          );
        }
        await _loadData(); // Reload all data
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No sales were imported.'), backgroundColor: Colors.orange),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to import sales: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.nearlyWhite,
      appBar: AppBar(
        title: const Text('Sales History', style: AppTheme.title),
        backgroundColor: AppTheme.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.nearlyBlack),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: _isLoading ? null : _exportSales,
            tooltip: 'Export Sales to Excel',
          ),
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            onPressed: _isLoading ? null : _importSales,
            tooltip: 'Import Sales from Excel',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadData, // Refresh sales
            tooltip: 'Refresh Sales',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSearchAndFilters(),
                Container(
                    width: double.infinity,
                    color: AppTheme.vimbikaBlue.withAlpha(20),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                            const Text('Total Revenue:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('\$${_totalRevenue.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.vimbikaBlue)),
                        ],
                    ),
                ),
                Expanded(
                  child: _filteredSales.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredSales.length,
                          itemBuilder: (context, index) {
                            final sale = _filteredSales[index];
                            final String currentDate = _formatDate(sale.timeIniated);
                            final bool showDivider = index == 0 || _formatDate(_filteredSales[index - 1].timeIniated) != currentDate;

                            Widget saleCard = Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 1,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => SaleReceiptScreen(sale: sale)),
                                  );
                                },
                                onLongPress: () {
                                  if (sale.status != 'Reversed') {
                                    _reverseSale(sale);
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: AppTheme.vimbikaBlue.withAlpha(25),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(Icons.receipt_long, color: AppTheme.vimbikaBlue, size: 20),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  sale.customer?.name ?? 'Walk-in Customer',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '${sale.timeIniated} • ${sale.items.length} items',
                                                  style: const TextStyle(fontSize: 12, color: AppTheme.grey),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                '\$${sale.grandTotal.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: sale.status == 'Reversed' ? Colors.grey : AppTheme.vimbikaBlue,
                                                  decoration: sale.status == 'Reversed' ? TextDecoration.lineThrough : null,
                                                ),
                                              ),
                                              if (sale.referenceNumber != null && sale.referenceNumber!.isNotEmpty)
                                                Text('#${sale.referenceNumber}',
                                                    style: const TextStyle(fontSize: 11, color: AppTheme.grey)),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 8.0),
                                        child: Divider(height: 1, thickness: 0.5),
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: (sale.status == 'Reversed')
                                                        ? Colors.grey.withAlpha(30)
                                                        : ((sale.status == 'Fully Paid' || sale.status == 'Completed')
                                                            ? Colors.green.withAlpha(30)
                                                            : Colors.orange.withAlpha(30)),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    sale.status ?? 'Completed',
                                                    style: TextStyle(
                                                      color: (sale.status == 'Reversed')
                                                          ? Colors.grey
                                                          : ((sale.status == 'Fully Paid' || sale.status == 'Completed')
                                                              ? Colors.green
                                                                : Colors.orange),
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                if (sale.isSynced == false)
                                                  const Padding(
                                                    padding: EdgeInsets.only(left: 8.0),
                                                    child: Icon(Icons.cloud_off, size: 14, color: Colors.red),
                                                  ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    'Branch: ${sale.branch?.name ?? 'Main'}',
                                                    style: const TextStyle(fontSize: 11, color: AppTheme.grey),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (sale.status != 'Reversed')
                                            IconButton(
                                              constraints: const BoxConstraints(),
                                              padding: EdgeInsets.zero,
                                              icon: const Icon(Icons.print, color: AppTheme.vimbikaBlue, size: 20),
                                              onPressed: () async {
                                                final printerService = PrinterService();
                                                try {
                                                  await printerService.init();
                                                  if (printerService.isConnected) {
                                                    await printerService.printSale(sale);
                                                    if (mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(content: Text('Printing receipt...')),
                                                      );
                                                    }
                                                  } else {
                                                    if (mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(
                                                          content: Text('No printer connected. Please check settings.'),
                                                          backgroundColor: Colors.orange,
                                                        ),
                                                      );
                                                    }
                                                  }
                                                } catch (e) {
                                                  if (mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text('Failed to print: $e'),
                                                        backgroundColor: Colors.red,
                                                      ),
                                                    );
                                                  }
                                                }
                                              },
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );

                            if (showDivider) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Text(
                                      currentDate,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.grey),
                                    ),
                                  ),
                                  saleCard,
                                ],
                              );
                            }
                            return saleCard;
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: AppTheme.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            onChanged: (val) {
              _searchQuery = val;
              _applyFilters();
            },
            decoration: InputDecoration(
              hintText: 'Search by customer or receipt ID...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: AppTheme.nearlyWhite,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _selectDateRange(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _filterStartDate == null ? AppTheme.nearlyWhite : AppTheme.vimbikaBlue.withAlpha(25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _filterStartDate == null ? Colors.grey.withAlpha(50) : AppTheme.vimbikaBlue),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _filterStartDate == null 
                            ? 'Date Range' 
                            : '${DateFormat('MMM dd').format(_filterStartDate!)} - ${DateFormat('MMM dd').format(_filterEndDate!)}', 
                          style: TextStyle(fontSize: 12, fontWeight: _filterStartDate == null ? FontWeight.normal : FontWeight.bold)
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.calendar_today, size: 14),
                      ],
                    ),
                  ),
                ),
                if (_filterStartDate != null)
                   IconButton(
                       icon: const Icon(Icons.close, size: 16),
                       padding: EdgeInsets.zero,
                       constraints: const BoxConstraints(),
                       onPressed: () {
                           if (mounted) {
                             setState(() {
                                 _filterStartDate = DateTime.now().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
                                 _filterEndDate = DateTime.now().copyWith(hour: 23, minute: 59, second: 59, millisecond: 999, microsecond: 999);
                             });
                           }
                           _applyFilters();
                       }
                   ),
                const SizedBox(width: 8),
                _buildFilterChip('Status', ['All', 'Fully Paid', 'Partially Paid', 'Reversed'], _selectedStatus, (val) {
                  if (mounted) setState(() => _selectedStatus = val);
                  _applyFilters();
                }),
                const SizedBox(width: 8),
                _buildCompactDropdown<Branch>('Branch', _branches, _selectedBranch, (val) {
                  if (mounted) setState(() => _selectedBranch = val);
                  _applyFilters();
                }, (b) => b.name),
                const SizedBox(width: 8),
                _buildCompactDropdown<Customer>('Customer', _customers, _selectedCustomer, (val) {
                  if (mounted) setState(() => _selectedCustomer = val);
                  _applyFilters();
                }, (c) => c.name),
                if (_currentShift != null) ...[
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Current Shift', style: TextStyle(fontSize: 12)),
                    selected: _currentShiftOnly,
                    onSelected: (bool selected) {
                      if (mounted) {
                        setState(() {
                          _currentShiftOnly = selected;
                        });
                      }
                      _applyFilters();
                    },
                    selectedColor: AppTheme.vimbikaBlue.withAlpha(25),
                    checkmarkColor: AppTheme.vimbikaBlue,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, List<String> options, String selectedValue, Function(String) onSelected) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      itemBuilder: (context) => options.map((opt) => PopupMenuItem(value: opt, child: Text(opt))).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selectedValue == 'All' ? AppTheme.nearlyWhite : AppTheme.vimbikaBlue.withAlpha(25),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selectedValue == 'All' ? Colors.grey.withAlpha(50) : AppTheme.vimbikaBlue),
        ),
        child: Row(
          children: [
            Text('$label: $selectedValue', style: TextStyle(fontSize: 12, fontWeight: selectedValue == 'All' ? FontWeight.normal : FontWeight.bold)),
            const Icon(Icons.arrow_drop_down, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactDropdown<T>(String label, List<T> items, T? selectedValue, ValueChanged<T?> onChanged, String Function(T) itemLabel) {
    return PopupMenuButton<T?>(
      onSelected: onChanged,
      itemBuilder: (context) => [
        PopupMenuItem<T?>(value: null, child: const Text('All')),
        ...items.map((item) => PopupMenuItem<T?>(value: item, child: Text(itemLabel(item)))),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selectedValue == null ? AppTheme.nearlyWhite : AppTheme.vimbikaBlue.withAlpha(25),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selectedValue == null ? Colors.grey.withAlpha(50) : AppTheme.vimbikaBlue),
        ),
        child: Row(
          children: [
            Text('$label: ${selectedValue == null ? 'All' : itemLabel(selectedValue)}', 
                 style: TextStyle(fontSize: 12, fontWeight: selectedValue == null ? FontWeight.normal : FontWeight.bold)),
            const Icon(Icons.arrow_drop_down, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: AppTheme.grey.withAlpha(125)),
          const SizedBox(height: 16),
          const Text('No sales records found.', style: TextStyle(color: AppTheme.grey, fontSize: 18)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              if (mounted) {
                setState(() {
                  _searchQuery = '';
                  _selectedBranch = null;
                  _selectedCustomer = null;
                  _selectedStatus = 'All';
                  _currentShiftOnly = false;
                  _filterStartDate = null;
                  _filterEndDate = null;
                });
              }
              _applyFilters();
            },
            child: const Text('Clear all filters'),
          ),
        ],
      ),
    );
  }
}
