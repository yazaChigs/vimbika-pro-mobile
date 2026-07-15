import 'package:vimbika_pro/app_constants/app_constants.dart';
import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:vimbika_pro/model/category.dart';
import 'package:vimbika_pro/model/inventory_item.dart';
import 'package:vimbika_pro/model/branch_stock.dart';
import 'package:vimbika_pro/model/branch.dart';
import 'package:vimbika_pro/model/item_type.dart';
import 'package:vimbika_pro/model/tax.dart';
import 'package:vimbika_pro/model/unit.dart';
import 'package:vimbika_pro/model/supplier.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:vimbika_pro/services/inventory_item_service.dart';
import 'package:uuid/uuid.dart';

class AddInventoryItemScreen extends StatefulWidget {
  final InventoryItem? item;
  final BranchStock? branchStock;

  const AddInventoryItemScreen({super.key, this.item, this.branchStock});

  @override
  State<AddInventoryItemScreen> createState() => _AddInventoryItemScreenState();
}

class _AddInventoryItemScreenState extends State<AddInventoryItemScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _codeController;
  late TextEditingController _costPriceController;
  late TextEditingController _sellingPriceController;
  late TextEditingController _priceWithoutTaxController;
  late TextEditingController _taxAmountController;
  late TextEditingController _reorderLevelController;
  
  bool _isService = false;
  bool _isCalculating = false;
  
  Category? _selectedCategory;
  Unit? _selectedUnit;
  Supplier? _selectedSupplier;
  Tax? _selectedTax;
  Tax? _selectedPurchaseTax;
  Branch? _selectedBranch;

  List<Category> _categories = [];
  List<Unit> _units = [];
  List<Supplier> _suppliers = [];
  List<Tax> _taxes = [];
  
  bool _isLoading = true;
  bool _isOnline = false; // Added for offline/online mode
  bool _isTaxEnabled = true;
  final InventoryItemService _inventoryItemService = InventoryItemService(); // Instantiate the service

  @override
  void initState() {
    super.initState();
    final item = widget.item ?? widget.branchStock?.item.value;
    
    _nameController = TextEditingController(text: item?.name);
    _descriptionController = TextEditingController(text: item?.description);
    _codeController = TextEditingController(text: item?.itemCode);
    _costPriceController = TextEditingController(text: item?.purchasePrice.toString() ?? '0.0');
    _sellingPriceController = TextEditingController(text: item?.sellingPrice.toString() ?? '0.0');
    _priceWithoutTaxController = TextEditingController(text: item?.priceWithoutTax.toString() ?? '0.0');
    _taxAmountController = TextEditingController(text: item?.taxAmount.toString() ?? '0.0');
    _reorderLevelController = TextEditingController(text: item?.reorderLevel.toString() ?? '0.0');
    _isService = item?.isService ?? false;

    _costPriceController.addListener(_calculateTaxes);
    _priceWithoutTaxController.addListener(_calculateTaxesBackward);
    
    _loadData();
  }

  Future<void> _loadData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Determine online/offline mode
    _isOnline = !(prefs.getBool(AppConstants.keyIsOfflineMode) ?? false);

    final List<String> catJson = _isOnline
        ? (prefs.getStringList(AppConstants.keyCategories) ?? [])
        : (prefs.getStringList(AppConstants.keyOfflineCategories) ?? []);
    final List<String> unitJson = _isOnline
        ? (prefs.getStringList(AppConstants.keyUnits) ?? [])
        : (prefs.getStringList(AppConstants.keyOfflineUnits) ?? []);
    final List<String> supplierJson = _isOnline
        ? (prefs.getStringList(AppConstants.keySuppliers) ?? [])
        : (prefs.getStringList(AppConstants.keyOfflineSuppliers) ?? []);
    final List<String> taxJson = _isOnline
        ? (prefs.getStringList(AppConstants.keyTaxes) ?? [])
        : (prefs.getStringList(AppConstants.keyOfflineTaxes) ?? []);
    final String? defaultBranchJson = _isOnline
        ? prefs.getString(AppConstants.keyDefaultBranch)
        : prefs.getString(AppConstants.keyOfflineBranch);
    
    setState(() {
      _isTaxEnabled = prefs.getBool(AppConstants.keyIsPriceInclusiveTax) ?? true;
      _categories = catJson.map((e) => Category.fromJson(jsonDecode(e))).toList();
      _units = unitJson.map((e) => Unit.fromJson(jsonDecode(e))).toList();
      _suppliers = supplierJson.map((e) => Supplier.fromJson(jsonDecode(e))).toList();
      _taxes = taxJson.map((e) => Tax.fromJson(jsonDecode(e))).toList();

      final item = widget.item ?? widget.branchStock?.item.value;
      if (item != null) {
        if (item.category.value != null) {
          _selectedCategory = _categories.cast<Category?>().firstWhere((element) => element?.id == item.category.value!.id, orElse: () => null); // Changed orElse to null
        }
        if (item.unit.value != null) {
          _selectedUnit = _units.cast<Unit?>().firstWhere((element) => element?.id == item.unit.value!.id, orElse: () => null); // Changed orElse to null
        }
        if (item.supplier.value != null) {
          _selectedSupplier = _suppliers.cast<Supplier?>().firstWhere((element) => element?.id == item.supplier.value!.id, orElse: () => null);
        }
        if (item.tax.value != null) {
          _selectedTax = _taxes.cast<Tax?>().firstWhere((element) => element?.id == item.tax.value!.id, orElse: () => null); // Changed orElse to null
        }
        if (item.purchaseTax.value != null) {
          _selectedPurchaseTax = _taxes.cast<Tax?>().firstWhere((element) => element?.id == item.purchaseTax.value!.id, orElse: () => null);
        }
      }

      // Find the branch to pre-select
      if (defaultBranchJson != null) {
        _selectedBranch = Branch.fromJson(jsonDecode(defaultBranchJson));
      }

      _isLoading = false;
      _calculateTaxes();
    });
  }

  void _calculateTaxes() {
    if (_isCalculating) return;
    _isCalculating = true;

    final double costPrice = double.tryParse(_costPriceController.text) ?? 0.0;
    double purchasePriceAfterTax = costPrice;
    double taxAmount = 0.0;

    if (_selectedPurchaseTax != null && _selectedPurchaseTax!.taxPercentage != null) {
      double taxRate = _selectedPurchaseTax!.taxPercentage! / 100;
      taxAmount = costPrice * taxRate;
      purchasePriceAfterTax = costPrice + taxAmount;
    }
    
    _priceWithoutTaxController.text = purchasePriceAfterTax.toStringAsFixed(2);
    _taxAmountController.text = taxAmount.toStringAsFixed(2);

    _isCalculating = false;
  }

  void _calculateTaxesBackward() {
    if (_isCalculating) return;
    _isCalculating = true;

    final double purchasePriceAfterTax = double.tryParse(_priceWithoutTaxController.text) ?? 0.0;
    double costPrice = purchasePriceAfterTax;
    double taxAmount = 0.0;

    if (_selectedPurchaseTax != null && _selectedPurchaseTax!.taxPercentage != null) {
      double taxRate = _selectedPurchaseTax!.taxPercentage! / 100;
      // CostPrice = PriceAfterTax / (1 + TaxRate)
      costPrice = purchasePriceAfterTax / (1 + taxRate);
      taxAmount = purchasePriceAfterTax - costPrice;
    }

    _costPriceController.text = costPrice.toStringAsFixed(2);
    _taxAmountController.text = taxAmount.toStringAsFixed(2);

    _isCalculating = false;
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Check for duplicates
    final String inventoryItemsKey = _isOnline ? AppConstants.keyInventoryItems : AppConstants.keyOfflineInventoryItems;
    List<String> itemsJsonList = prefs.getStringList(inventoryItemsKey) ?? [];
    List<InventoryItem> localItems = itemsJsonList.map((e) => InventoryItem.fromJson(jsonDecode(e))).toList();

    final String newName = _nameController.text.trim();
    final String newCode = _codeController.text.trim();
    final String? currentId = widget.item?.id ?? widget.branchStock?.item.value?.id;

    bool isDuplicateName = localItems.any((item) => 
        item.id != currentId && 
        item.name.toLowerCase().trim() == newName.toLowerCase());
    
    bool isDuplicateCode = newCode.isNotEmpty && localItems.any((item) => 
        item.id != currentId && 
        item.itemCode?.toLowerCase().trim() == newCode.toLowerCase());

    if (isDuplicateName) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An item with this name already exists.'), backgroundColor: Colors.red),
      );
      setState(() => _isLoading = false);
      return;
    }

    if (isDuplicateCode) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An item with this item code already exists.'), backgroundColor: Colors.red),
      );
      setState(() => _isLoading = false);
      return;
    }

    // 1. Create/Update InventoryItem
    final existingItem = widget.item ?? widget.branchStock?.item.value;
    final String itemId = existingItem?.id ?? const Uuid().v4();

    final double costPrice = double.tryParse(_costPriceController.text) ?? 0.0;
    double purchasePriceAfterTax = costPrice;
    double taxAmount = 0.0;

    if (_selectedPurchaseTax != null && _selectedPurchaseTax!.taxPercentage != null) {
      double taxRate = _selectedPurchaseTax!.taxPercentage! / 100;
      taxAmount = costPrice * taxRate;
      purchasePriceAfterTax = costPrice + taxAmount;
    }
    
    InventoryItem newItem = InventoryItem(
      id: itemId, // Preserve ID if editing or generate new one
      name: _nameController.text,
      description: _descriptionController.text,
      itemCode: _codeController.text,
      category: _selectedCategory,
      unit: _selectedUnit,
      supplier: _selectedSupplier,
      tax: _selectedTax,
      purchaseTax: _selectedPurchaseTax,
      // currency: existingItem?.currency ?? _baseCurrency,
      purchasePrice: costPrice,
      sellingPrice: double.tryParse(_sellingPriceController.text) ?? 0.0,
      priceWithoutTax: purchasePriceAfterTax,
      taxAmount: taxAmount,
      reorderLevel: double.tryParse(_reorderLevelController.text) ?? 0.0,
      isService: _isService,
      itemType: _isService ? ItemType.SERVICE : ItemType.INVENTORY,
      // company: _selectedBranch?.company, // Ensure company is set
      isSynced: false, // Default to not synced
    );

    try {
      if (_isOnline) {
        // Attempt to save to backend
        final savedItem = await _inventoryItemService.saveInventoryItem(newItem);
        newItem = savedItem.copyWith(isSynced: true); // Update with server data and mark as synced
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item saved online successfully!')),
        );
      } else {
        // Offline mode: save locally
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item saved offline. Will sync when online.')),
        );
      }

      // Update local storage for InventoryItem
      // (already loaded above as localItems)
      final int itemIndex = localItems.indexWhere((element) => element.id == newItem.id);
      if (itemIndex != -1) {
        localItems[itemIndex] = newItem;
      } else {
        localItems.add(newItem);
      }
      await prefs.setStringList(inventoryItemsKey, localItems.map((e) => jsonEncode(e.toJson())).toList());

      // 2. Create/Update BranchStock
      final String branchStockKey = _isOnline ? AppConstants.keyBranchStock : AppConstants.keyOfflineBranchStock;
      List<String> branchStocksJsonList = prefs.getStringList(branchStockKey) ?? [];
      List<BranchStock> localBranchStocks = branchStocksJsonList.map((e) => BranchStock.fromJson(jsonDecode(e))).toList();

      BranchStock branchStock = BranchStock(
        id: widget.branchStock?.id ?? '${newItem.id}_bs', // Use existing ID or generate new one
        stock: widget.branchStock?.stock ?? 0.00
      );
      branchStock.item.value = newItem;
      branchStock.branch.value = _selectedBranch;

      final int branchStockIndex = localBranchStocks.indexWhere((element) => element.id == branchStock.id);
      if (branchStockIndex != -1) {
        localBranchStocks[branchStockIndex] = branchStock;
      } else {
        localBranchStocks.add(branchStock);
      }
      await prefs.setStringList(branchStockKey, localBranchStocks.map((e) => jsonEncode(e.toJson())).toList());

      if (context.mounted) Navigator.pop(context, true);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save item: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _codeController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    _priceWithoutTaxController.dispose();
    _taxAmountController.dispose();
    _reorderLevelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.item != null || widget.branchStock != null;

    return Scaffold(
      backgroundColor: AppTheme.nearlyWhite,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Stock Item' : 'Add Stock Item', style: AppTheme.title),
        backgroundColor: AppTheme.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.nearlyBlack),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_nameController, 'Item Name', 'Enter item name', required: true)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField(_codeController, 'Item Code', 'Barcode/Internal Code')),
                    ],
                  ),
                  _buildTextField(_descriptionController, 'Description', 'Enter description'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown<Category>(
                          'Category', 
                          _categories, 
                          _selectedCategory, 
                          (val) => setState(() => _selectedCategory = val),
                          (cat) => cat.name
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDropdown<Unit>(
                          'Unit', 
                          _units, 
                          _selectedUnit, 
                          (val) => setState(() => _selectedUnit = val),
                          (unit) => unit.name
                        ),
                      ),
                    ],
                  ),
                  _buildDropdown<Supplier>(
                    'Supplier', 
                    _suppliers, 
                    _selectedSupplier, 
                    (val) => setState(() => _selectedSupplier = val),
                    (s) => s.name
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (_isTaxEnabled)
                        Expanded(
                          child: _buildDropdown<Tax>(
                            'Sales Tax', 
                            _taxes, 
                            _selectedTax, 
                            (val) {
                              setState(() {
                                _selectedTax = val;
                              });
                            },
                            (tax) => '${tax.name} (${tax.taxPercentage}%)'
                          ),
                        ),
                      if (_isTaxEnabled)
                        const SizedBox(width: 12),
                      Expanded(child: _buildTextField(_sellingPriceController, 'Selling Price', '0.0', keyboardType: TextInputType.number)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (_isTaxEnabled)
                        Expanded(
                          child: _buildDropdown<Tax>(
                              'Purchase Tax',
                              _taxes,
                              _selectedPurchaseTax,
                                  (val) {
                                setState(() {
                                  _selectedPurchaseTax = val;
                                  _calculateTaxes();
                                });
                              },
                                  (tax) => '${tax.name} (${tax.taxPercentage}%)'
                          ),
                        ),
                      if (_isTaxEnabled)
                        const SizedBox(width: 12),
                      Expanded(child: _buildTextField(_costPriceController, 'Cost Price (Before Tax)', '0.0', keyboardType: TextInputType.number)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_priceWithoutTaxController, 'Purchase Price (After Tax)', '0.0', keyboardType: TextInputType.number)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField(_taxAmountController, 'Tax Amount', '0.0', keyboardType: TextInputType.number, enabled: false)),
                    ],
                  ),
                  _buildTextField(_reorderLevelController, 'Reorder Level', '0.0', keyboardType: TextInputType.number),
                  SwitchListTile(
                    title: const Text('Is Service Item?'),
                    subtitle: const Text('Services do not track stock levels'),
                    value: _isService,
                    onChanged: (val) => setState(() => _isService = val),
                    activeColor: AppTheme.vimbikaBlue,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveItem,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.vimbikaBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(isEditing ? 'Update Stock' : 'Save Stock', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, {bool required = false, TextInputType keyboardType = TextInputType.text, bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: enabled ? AppTheme.white : Colors.grey[200],
        ),
        validator: required ? (value) => value == null || value.isEmpty ? 'This field is required' : null : null,
        onTap: () {
          if (keyboardType == TextInputType.number) {
            controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length);
          }
        },
      ),
    );
  }

  Widget _buildDropdown<T>(String label, List<T> items, T? selectedValue, ValueChanged<T?> onChanged, String Function(T) itemLabel) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<T>(
        value: selectedValue,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: AppTheme.white,
        ),
        items: items.map((item) => DropdownMenuItem(
          value: item,
          child: Text(itemLabel(item)),
        )).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
