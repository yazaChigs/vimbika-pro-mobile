import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:vimbika_pro/model/branch_stock.dart';
import 'package:vimbika_pro/model/branch.dart';
import 'package:vimbika_pro/model/category.dart';
import 'package:vimbika_pro/services/branch_stock_service.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'add_inventory_item_screen.dart';
import '../app_constants/app_constants.dart';
// Assuming you have an ApiService for network calls
// import 'package:vimbika_pro/api/api_service.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<BranchStock> _allStocks = [];
  List<BranchStock> _filteredStocks = [];
  
  List<Category> _categories = [];
  
  String _searchQuery = '';
  Branch? _selectedBranch;
  Category? _selectedCategory;
  String _selectedItemType = 'All'; // All, Products, Services
  String _selectedStockStatus = 'All'; // All, In Stock, Out of Stock, Low Stock
  
  bool _isLoading = true;
  bool _isOnline = false; // New: To track network status
  final BranchStockService _stockService = BranchStockService(); // Instantiate StockService

  @override
  void initState() {
    _loadData();
    super.initState();
  }

  // Updated: To check network status based on saved preference
  Future<void> _checkConnectivity() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // If 'is_offline_mode' is true, then we are NOT online. Default to online if not set.
    _isOnline = !(prefs.getBool(AppConstants.keyIsOfflineMode) ?? false); // Default to false (offline) if not set, meaning online if not explicitly offline
    print("App is in online mode: $_isOnline");
  }

  // Updated: To use StockService for fetching online branch stock
  Future<List<BranchStock>> _fetchOnlineBranchStock() async {
    print("Attempting to fetch online branch stock...");
    List<BranchStock> onlineStocks = [];
    try {
      if (_selectedBranch != null) {
        onlineStocks = await _stockService.fetchStockByBranch(_selectedBranch!);
        print("Fetched ${onlineStocks.length} online branch stocks.");
        
        // Save onlineStock to keyBranchStock for offline use
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final List<String> stockJsonList = onlineStocks.map((stock) => jsonEncode(stock.toJson())).toList();
        await prefs.setStringList(AppConstants.keyOfflineBranchStock, stockJsonList);
        print("Saved ${onlineStocks.length} online branch stocks to local storage.");

      } else {
        print("No branch selected for fetching online stock.");
      }
    } catch (e) {
      print('Error fetching online branch stock: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching online inventory: $e'), backgroundColor: Colors.red),
        );
      }
    }
    return onlineStocks;
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    await _checkConnectivity(); // Check network status based on preference

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Load Default Branch
    Branch? defaultBranch;
    final String? dBranchJson = _isOnline?prefs.getString(AppConstants.keyDefaultBranch):prefs.getString(AppConstants.keyOfflineBranch);
    if (dBranchJson != null) {
      defaultBranch = Branch.fromJson(jsonDecode(dBranchJson));
    }

    // Load Categories
    final List<String> catJson = prefs.getStringList('categories') ?? [];
    final List<Category> loadedCategories = catJson.map((e) => Category.fromJson(jsonDecode(e))).toList();

    List<BranchStock> loadedStocks = [];
    if (_isOnline) {
      // Fetch from online source if online
      loadedStocks = await _fetchOnlineBranchStock();
    } else {
      // Load from local storage if offline
      final List<String> listJson = prefs.getStringList(AppConstants.keyOfflineBranchStock) ?? []; // Corrected key
      loadedStocks = listJson
          .map((item) => BranchStock.fromJson(jsonDecode(item)))
          .toList();
    }
    
    setState(() {
      _selectedBranch = defaultBranch;
      _categories = loadedCategories;
      _allStocks = loadedStocks;
      _applyFilters();
      _isLoading = false;
    });
  }

  Future<void> _exportToExcel() async {
    try {
      // Permission Handling
      if (Platform.isAndroid) {
        if (!await Permission.manageExternalStorage.isGranted) {
          await Permission.manageExternalStorage.request();
        }
      }

      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Sheet1'];

      // Add Headers
      List<String> headers = [
        'Name', 'Description', 'Code', 'Category', 'Unit', 
        'Tax Name', 'Tax Rate (%)', 'Cost Price', 'Selling Price', 
        'Reorder Level', 'Is Service', 'Branch', 'Quantity'
      ];
      
      for (var i = 0; i < headers.length; i++) {
        var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
      }

      // Add Data
      for (var i = 0; i < _allStocks.length; i++) {
        var stock = _allStocks[i];
        var item = stock.item!;
        
        List<CellValue> values = [
          TextCellValue(item.name),
          TextCellValue(item.description!),
          TextCellValue(item.itemCode ?? ''),
          TextCellValue(item.category?.name ?? ''),
          TextCellValue(item.unit?.name ?? ''),
          TextCellValue(item.tax?.name ?? ''),
          DoubleCellValue(item.tax?.taxPercentage ?? 0.0),
          DoubleCellValue(item.purchasePrice),
          DoubleCellValue(item.sellingPrice),
          DoubleCellValue(item.reorderLevel),
          TextCellValue(item.isService.toString()),
          TextCellValue(stock.branch?.name ?? ''),
          DoubleCellValue(stock.quantity),
        ];

        for (var j = 0; j < values.length; j++) {
          var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + 1));
          cell.value = values[j];
        }
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

      final String filePath = '${directory.path}/inventory_export_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final File file = File(filePath);
      await file.writeAsBytes(fileBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Inventory exported to: $filePath'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting inventory: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredStocks = _allStocks.where((stock) {
        final item = stock.item;
        if (item == null) return false;

        // Search Filter (Name, SKU, or Item Code)
        final matchesSearch = item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                             (item.itemCode?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

        // Branch Filter
        final matchesBranch = _selectedBranch == null || stock.branch?.id == _selectedBranch!.id;

        // Category Filter
        final matchesCategory = _selectedCategory == null || item.category?.id == _selectedCategory!.id;

        bool matchesItemType = true;
        if (_selectedItemType == 'Products') matchesItemType = !item.isService;
        if (_selectedItemType == 'Services') matchesItemType = item.isService;

        bool matchesStockStatus = true;
        if (_selectedStockStatus == 'In Stock') matchesStockStatus = stock.quantity > 0;
        if (_selectedStockStatus == 'Out of Stock') matchesStockStatus = stock.quantity <= 0 && !item.isService;
        if (_selectedStockStatus == 'Low Stock') matchesStockStatus = stock.quantity <= item.reorderLevel && stock.quantity > 0;

        return matchesSearch && matchesBranch && matchesCategory && matchesItemType && matchesStockStatus;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.nearlyWhite,
      appBar: AppBar(
        title: const Text('Inventory', style: AppTheme.title),
        backgroundColor: AppTheme.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.nearlyBlack),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: _exportToExcel,
            tooltip: 'Export to Excel',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSearchAndFilters(),
                Expanded(
                  child: _filteredStocks.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredStocks.length,
                          itemBuilder: (context, index) {
                            final stock = _filteredStocks[index];
                            final item = stock.item!;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => AddInventoryItemScreen(branchStock: stock)),
                                  );
                                  if (result == true) _loadData();
                                },
                                leading: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppTheme.vimbikaBlue.withAlpha(25),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    item.isService ? Icons.room_service_outlined : Icons.inventory_2_outlined, 
                                    color: AppTheme.vimbikaBlue
                                  ),
                                ),
                                title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Code: ${item.itemCode ?? 'N/A'}'),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: stock.quantity <= item.reorderLevel ? Colors.red.withAlpha(25) : Colors.green.withAlpha(25),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Stock: ${stock.quantity.toStringAsFixed(0)} ${item.unit?.name ?? ''}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: stock.quantity <= item.reorderLevel ? Colors.red : Colors.green,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '\$${item.sellingPrice.toStringAsFixed(2)}', 
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.vimbikaBlue)
                                    ),
                                    const Text('Price', style: TextStyle(fontSize: 10, color: AppTheme.grey)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddInventoryItemScreen()),
          );
          if (result == true) _loadData();
        },
        backgroundColor: AppTheme.vimbikaBlue,
        child: const Icon(Icons.add, color: Colors.white),
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
              hintText: 'Search by name, SKU or item code...',
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
                _buildFilterChip('Type', ['All', 'Products', 'Services'], _selectedItemType, (val) {
                  setState(() => _selectedItemType = val);
                  _applyFilters();
                }),
                const SizedBox(width: 8),
                _buildFilterChip('Stock', ['All', 'In Stock', 'Out of Stock', 'Low Stock'], _selectedStockStatus, (val) {
                  setState(() => _selectedStockStatus = val);
                  _applyFilters();
                }),
                const SizedBox(width: 8),
                _buildCompactDropdown<Category>('Category', _categories, _selectedCategory, (val) {
                  setState(() => _selectedCategory = val);
                  _applyFilters();
                }, (c) => c.name),
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
          const Text('No matching items found.', style: TextStyle(color: AppTheme.grey, fontSize: 18)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _selectedBranch = null;
                _selectedCategory = null;
                _selectedItemType = 'All';
                _selectedStockStatus = 'All';
              });
              _applyFilters();
            },
            child: const Text('Clear all filters'),
          ),
        ],
      ),
    );
  }
}
