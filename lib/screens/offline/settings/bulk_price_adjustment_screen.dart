import 'dart:convert';
import 'package:vimbika_pro/app_constants/app_constants.dart';
import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:vimbika_pro/model/category.dart';
import 'package:vimbika_pro/model/inventory_item.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BulkPriceAdjustmentScreen extends StatefulWidget {
  const BulkPriceAdjustmentScreen({Key? key}) : super(key: key);

  @override
  _BulkPriceAdjustmentScreenState createState() => _BulkPriceAdjustmentScreenState();
}

class _BulkPriceAdjustmentScreenState extends State<BulkPriceAdjustmentScreen> {
  bool _isLoading = true;
  bool _isOfflineMode = false;

  List<InventoryItem> _allItems = [];
  List<InventoryItem> _filteredItems = [];
  List<Category> _categories = [];

  Category? _selectedCategory;
  String _priceType = 'Selling Price';
  String _adjustmentType = 'Increase %';
  final TextEditingController _valueController = TextEditingController();

  final List<String> _priceTypes = ['Selling Price', 'Purchase Price', 'Both'];
  final List<String> _adjustmentTypes = [
    'Increase %',
    'Decrease %',
    'Increase Amount',
    'Decrease Amount',
    'Set New Price'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _valueController.addListener(_onValueChanged);
  }

  @override
  void dispose() {
    _valueController.removeListener(_onValueChanged);
    _valueController.dispose();
    super.dispose();
  }

  void _onValueChanged() {
    setState(() {}); // Rebuild to update preview
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _isOfflineMode = prefs.getBool(AppConstants.keyIsOfflineMode) ?? false;

    // Load categories
    final List<String> catJson = _isOfflineMode
        ? (prefs.getStringList(AppConstants.keyOfflineCategories) ?? [])
        : (prefs.getStringList(AppConstants.keyCategories) ?? []);
    _categories = catJson.map((e) => Category.fromJson(jsonDecode(e))).toList();

    // Load inventory items
    final String inventoryKey = _isOfflineMode
        ? AppConstants.keyOfflineInventoryItems
        : AppConstants.keyInventoryItems;
    final List<String> itemsJsonList = prefs.getStringList(inventoryKey) ?? [];
    _allItems = itemsJsonList.map((e) => InventoryItem.fromJson(jsonDecode(e))).toList();

    _applyCategoryFilter();

    setState(() => _isLoading = false);
  }

  void _applyCategoryFilter() {
    setState(() {
      if (_selectedCategory == null) {
        _filteredItems = List.from(_allItems);
      } else {
        _filteredItems = _allItems
            .where((item) => item.category?.id == _selectedCategory!.id)
            .toList();
      }
    });
  }

  double _calculateNewPrice(double oldPrice) {
    double value = double.tryParse(_valueController.text) ?? 0.0;
    if (value <= 0) return oldPrice;

    switch (_adjustmentType) {
      case 'Increase %':
        return oldPrice + (oldPrice * value / 100);
      case 'Decrease %':
        return oldPrice - (oldPrice * value / 100);
      case 'Increase Amount':
        return oldPrice + value;
      case 'Decrease Amount':
        return oldPrice - value;
      case 'Set New Price':
        return value;
      default:
        return oldPrice;
    }
  }

  Future<void> _applyBulkAdjustment() async {
    double value = double.tryParse(_valueController.text) ?? 0.0;
    if (value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid adjustment value.')),
      );
      return;
    }

    if (_filteredItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No items to adjust.')),
      );
      return;
    }

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Bulk Adjustment'),
        content: Text(
            'Are you sure you want to apply these changes to ${_filteredItems.length} items? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Apply'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String inventoryKey = _isOfflineMode
          ? AppConstants.keyOfflineInventoryItems
          : AppConstants.keyInventoryItems;
      
      // We will only update the items that are currently in _filteredItems
      // Create a map for quick lookup
      Map<String, InventoryItem> updatedItemsMap = {};
      for (var item in _filteredItems) {
        double newSellingPrice = item.sellingPrice;
        double newPurchasePrice = item.purchasePrice;

        if (_priceType == 'Selling Price' || _priceType == 'Both') {
          newSellingPrice = _calculateNewPrice(item.sellingPrice);
          if (newSellingPrice < 0) newSellingPrice = 0; // Prevent negative prices
        }
        if (_priceType == 'Purchase Price' || _priceType == 'Both') {
          newPurchasePrice = _calculateNewPrice(item.purchasePrice);
          if (newPurchasePrice < 0) newPurchasePrice = 0;
        }

        updatedItemsMap[item.id!] = item.copyWith(
          sellingPrice: newSellingPrice,
          purchasePrice: newPurchasePrice,
          isSynced: false, // Mark as unsynced so it gets pushed to API later
        );
      }

      // Update _allItems with the new values
      for (int i = 0; i < _allItems.length; i++) {
        final item = _allItems[i];
        if (updatedItemsMap.containsKey(item.id)) {
          _allItems[i] = updatedItemsMap[item.id]!;
        }
      }

      // Save to SharedPreferences
      final List<String> updatedJsonList =
          _allItems.map((e) => jsonEncode(e.toJson())).toList();
      await prefs.setStringList(inventoryKey, updatedJsonList);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prices updated successfully.'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to adjust prices: $e'), backgroundColor: Colors.red),
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
        title: const Text('Bulk Price Adjustment', style: AppTheme.title),
        backgroundColor: AppTheme.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.nearlyBlack),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildControls(),
                const Divider(height: 1),
                Expanded(child: _buildPreviewList()),
                _buildApplyButton(),
              ],
            ),
    );
  }

  Widget _buildControls() {
    return Container(
      color: AppTheme.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<Category>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Filter by Category',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem<Category>(
                      value: null,
                      child: Text('All Categories'),
                    ),
                    ..._categories.map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat.name),
                        ))
                  ],
                  onChanged: (val) {
                    _selectedCategory = val;
                    _applyCategoryFilter();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _priceType,
                  decoration: InputDecoration(
                    labelText: 'Price to Adjust',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _priceTypes
                      .map((pt) => DropdownMenuItem(value: pt, child: Text(pt)))
                      .toList(),
                  onChanged: (val) => setState(() => _priceType = val!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _adjustmentType,
                  decoration: InputDecoration(
                    labelText: 'Adjustment Type',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _adjustmentTypes
                      .map((at) => DropdownMenuItem(value: at, child: Text(at)))
                      .toList(),
                  onChanged: (val) => setState(() => _adjustmentType = val!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _valueController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Adjustment Value',
              hintText: 'e.g. 10',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              prefixIcon: Icon(
                _adjustmentType.contains('%') ? Icons.percent : Icons.attach_money,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewList() {
    if (_filteredItems.isEmpty) {
      return const Center(child: Text('No items match the selected category.'));
    }

    double value = double.tryParse(_valueController.text) ?? 0.0;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        final item = _filteredItems[index];
        final oldSelling = item.sellingPrice;
        final oldPurchase = item.purchasePrice;
        
        double newSelling = oldSelling;
        double newPurchase = oldPurchase;

        if (value > 0) {
          if (_priceType == 'Selling Price' || _priceType == 'Both') {
            newSelling = _calculateNewPrice(oldSelling);
            if (newSelling < 0) newSelling = 0;
          }
          if (_priceType == 'Purchase Price' || _priceType == 'Both') {
            newPurchase = _calculateNewPrice(oldPurchase);
            if (newPurchase < 0) newPurchase = 0;
          }
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                if (_priceType == 'Selling Price' || _priceType == 'Both')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Selling Price:', style: TextStyle(color: AppTheme.grey)),
                      Row(
                        children: [
                          Text(oldSelling.toStringAsFixed(2), style: TextStyle(decoration: value > 0 ? TextDecoration.lineThrough : null)),
                          if (value > 0) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward, size: 14, color: AppTheme.vimbikaBlue),
                            const SizedBox(width: 8),
                            Text(newSelling.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                          ]
                        ],
                      ),
                    ],
                  ),
                if (_priceType == 'Purchase Price' || _priceType == 'Both') ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Purchase Price:', style: TextStyle(color: AppTheme.grey)),
                      Row(
                        children: [
                          Text(oldPurchase.toStringAsFixed(2), style: TextStyle(decoration: value > 0 ? TextDecoration.lineThrough : null)),
                          if (value > 0) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward, size: 14, color: AppTheme.vimbikaBlue),
                            const SizedBox(width: 8),
                            Text(newPurchase.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                          ]
                        ],
                      ),
                    ],
                  ),
                ]
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildApplyButton() {
    double value = double.tryParse(_valueController.text) ?? 0.0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: value > 0 && _filteredItems.isNotEmpty ? _applyBulkAdjustment : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.vimbikaBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Apply Changes', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}
