import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'app_constants/app_constants.dart';
import 'model/branch_stock.dart';
import 'model/inventory_item.dart';
import 'model/purchase.dart';
import 'model/sale.dart';
import 'package:intl/intl.dart';

class ProductFlowReportScreen extends StatefulWidget {
  const ProductFlowReportScreen({super.key});

  @override
  State<ProductFlowReportScreen> createState() => _ProductFlowReportScreenState();
}

class _ProductFlowReportScreenState extends State<ProductFlowReportScreen> {
  InventoryItem? _selectedProduct;
  List<InventoryItem> _products = [];
  List<Purchase> _allPurchases = [];
  List<Sale> _allSales = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    
    final bool isOffline = prefs.getBool(AppConstants.keyIsOfflineMode) ?? false;
    // We should load from branch stock rather than just raw inventory items 
    // because products shown in reports are generally those available in stock.
    final String branchStockKey = isOffline ? AppConstants.keyOfflineBranchStock : AppConstants.keyBranchStock;
    final String salesKey = isOffline ? AppConstants.keyOfflineSales : AppConstants.keySales;

    final List<String> stockJson = prefs.getStringList(branchStockKey) ?? [];
    final List<String> purchasesJson = prefs.getStringList(AppConstants.keyPurchases) ?? [];
    final List<String> salesJson = prefs.getStringList(salesKey) ?? [];
    
    // Extract unique items from BranchStock
    final Set<String> addedItemIds = {};
    final List<InventoryItem> extractedProducts = [];
    
    for (var stockString in stockJson) {
      final stock = BranchStock.fromJson(jsonDecode(stockString));
      if (stock.item != null && !addedItemIds.contains(stock.item!.id)) {
        extractedProducts.add(stock.item!);
        addedItemIds.add(stock.item!.id!);
      }
    }

    setState(() {
      _products = extractedProducts;
      _allPurchases = purchasesJson.map((e) => Purchase.fromJson(jsonDecode(e))).toList();
      _allSales = salesJson.map((e) => Sale.fromJson(jsonDecode(e))).toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Purchase> productPurchases = [];
    List<Sale> productSales = [];

    if (_selectedProduct != null) {
      productPurchases = _allPurchases.where((p) => p.items.any((i) => i.inventoryItem?.id == _selectedProduct!.id)).toList();
      productSales = _allSales.where((s) => s.items.any((i) => i.inventoryItem?.id == _selectedProduct!.id)).toList();
    }

    return Scaffold(
      backgroundColor: AppTheme.nearlyWhite,
      appBar: AppBar(
        title: const Text('Product Flow Report', style: AppTheme.title),
        backgroundColor: AppTheme.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.nearlyBlack),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: DropdownButtonFormField<InventoryItem>(
                    value: _selectedProduct,
                    decoration: InputDecoration(
                      labelText: 'Select Product',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: AppTheme.white,
                    ),
                    items: _products.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                    onChanged: (val) => setState(() => _selectedProduct = val),
                  ),
                ),
                if (_selectedProduct == null)
                  Expanded(
                    child: Center(
                      child: Text('Select a product to view its flow', style: TextStyle(color: AppTheme.grey.withAlpha(150))),
                    ),
                  )
                else
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _buildSectionHeader('Procurement (Suppliers)'),
                        if (productPurchases.isEmpty)
                          _buildEmptyState('No purchase records for this product.')
                        else
                          ...productPurchases.map((p) => _buildFlowTile(
                            title: p.supplier?.name ?? 'Unknown Supplier',
                            subtitle: 'Purchased on ${DateFormat('MMM dd, yyyy').format(p.purchaseDate)}',
                            amount: p.items.firstWhere((i) => i.inventoryItem?.id == _selectedProduct!.id).quantity,
                            isIncoming: true,
                          )),
                        const SizedBox(height: 24),
                        _buildSectionHeader('Distribution (Buyers)'),
                        if (productSales.isEmpty)
                          _buildEmptyState('No sales records for this product.')
                        else
                          ...productSales.map((s) => _buildFlowTile(
                            title: s.customer?.name ?? 'Walk-in Customer',
                            subtitle: 'Sold on ${_formatDateString(s.timeIniated)}',
                            amount: s.items.firstWhere((i) => i.inventoryItem?.id == _selectedProduct!.id).quantity,
                            isIncoming: false,
                          )),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  String _formatDateString(String dateString) {
      try {
          return DateFormat('MMM dd, yyyy HH:mm').format(DateTime.parse(dateString));
      } catch (e) {
          return dateString;
      }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.vimbikaBlue),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(message, style: const TextStyle(color: AppTheme.grey, fontStyle: FontStyle.italic)),
    );
  }

  Widget _buildFlowTile({required String title, required String subtitle, required double amount, required bool isIncoming}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          isIncoming ? Icons.arrow_downward : Icons.arrow_upward,
          color: isIncoming ? Colors.green : Colors.orange,
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${amount.toStringAsFixed(0)} units',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(isIncoming ? 'Received' : 'Dispatched', style: const TextStyle(fontSize: 10, color: AppTheme.grey)),
          ],
        ),
      ),
    );
  }
}
