import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:vimbika_pro/app_constants/app_constants.dart';
import 'package:vimbika_pro/base_import_screen.dart';
import 'package:vimbika_pro/model/branch.dart';
import 'package:vimbika_pro/model/branch_stock.dart';
import 'package:vimbika_pro/model/category.dart';
import 'package:vimbika_pro/model/company.dart';
import 'package:vimbika_pro/model/inventory_item.dart';
import 'package:vimbika_pro/model/item_type.dart';
import 'package:vimbika_pro/model/supplier.dart';
import 'package:vimbika_pro/model/tax.dart';
import 'package:vimbika_pro/model/unit.dart';
import 'package:vimbika_pro/services/company_service.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InventoryImportScreen extends BaseImportScreen {
  const InventoryImportScreen({super.key})
      : super(
          title: 'Import Inventory',
          entityName: 'Inventory',
          templateFileName: 'inventory_import_template.xlsx',
          columns: const [
            'Name',
            'Description',
            'Code',
            'Category',
            'Unit',
            'Supplier',
            'Tax Name',
            'Tax Rate (%)',
            'Cost Price',
            'Selling Price',
            'Reorder Level',
            'Is Service (true/false)',
            'Branch',
            'Quantity'
          ],
        );

  @override
  Future<void> onImport(BuildContext context, List<List<Data?>> rows) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Load existing data for validation
    final List<String> existingStockJson = prefs.getStringList(AppConstants.keyOfflineBranchStock) ?? [];
    final List<BranchStock> branchStocks = existingStockJson
        .map((item) => BranchStock.fromJson(jsonDecode(item)))
        .toList();

    // Load actual branches
    final List<String> branchStrings = prefs.getStringList(AppConstants.keyBranches) ?? [];
    final List<Branch> availableBranches = branchStrings.map((e) => Branch.fromJson(jsonDecode(e))).toList();

    // Load Default Branch
    Branch? defaultBranch;
    final String? defaultBranchJson = prefs.getString(AppConstants.keyOfflineBranch);
    if (defaultBranchJson != null) {
      defaultBranch = Branch.fromJson(jsonDecode(defaultBranchJson));
    }

    final bool isTaxInclusive = prefs.getBool(AppConstants.keyIsPriceInclusiveTax) ?? true;
    
    // Load suppliers for lookup
    final List<String> supplierJsonList = prefs.getStringList(AppConstants.keyOfflineSuppliers) ?? [];
    final List<Supplier> offlineSuppliers = supplierJsonList.map((s) => Supplier.fromJson(jsonDecode(s))).toList();

    // Get company name for default supplier
    final Company? company = await CompanyService().getCompany();
    final String companyName = company?.name ?? '';

    Supplier? defaultSupplier;
    if (companyName.isNotEmpty) {
      try {
        defaultSupplier = offlineSuppliers.firstWhere(
          (s) => s.name.toLowerCase() == companyName.toLowerCase()
        );
      } catch (_) {
        defaultSupplier = Supplier(name: companyName);
      }
    }

    int importCount = 0;
    int skipCount = 0;
    List<String> errors = [];
    final String nowStr = DateTime.now().millisecondsSinceEpoch.toString();

    for (int i = 1; i < rows.length; i++) {
      final List<Data?> row = rows[i];
      if (row.isEmpty) continue;

      if (row.length < 14) {
        errors.add('Line ${i + 1}: Invalid column count');
        skipCount++;
        continue;
      }

      final String name = row[0]?.value?.toString().trim() ?? '';
      final String code = row[2]?.value?.toString().trim() ?? '';
      final String branchNameInCsv = row[12]?.value?.toString().trim() ?? '';

      // VALIDATION 1: Required Name
      if (name.isEmpty) {
        errors.add('Line ${i + 1}: Item name is required');
        skipCount++;
        continue;
      }

      // VALIDATION 2: Duplicate Name or Code
      bool isDuplicate = branchStocks.any((s) => 
        s.item.value?.name.toLowerCase() == name.toLowerCase() ||
        (code.isNotEmpty && s.item.value?.itemCode?.toLowerCase() == code.toLowerCase())
      );

      if (isDuplicate) {
        errors.add('Line ${i + 1}: Duplicate item name or code ($name / $code)');
        skipCount++;
        continue;
      }

      // BRANCH VALIDATION:
      Branch? targetBranch;
      if (branchNameInCsv.isNotEmpty) {
        try {
          // Look for matching branch by name
          targetBranch = availableBranches.firstWhere(
            (b) => b.name!.toLowerCase() == branchNameInCsv.toLowerCase()
          );
        } catch (_) {
          // If branch in CSV doesn't exist, use default branch
          targetBranch = defaultBranch;
        }
      } else {
        // If branch column is empty, use default branch
        targetBranch = defaultBranch;
      }

      // Final check: if we still have no branch (e.g. system not set up), skip.
      if (targetBranch == null) {
        errors.add('Line ${i + 1}: No valid branch found and no default branch set.');
        skipCount++;
        continue;
      }

      final bool isService = row[11]?.value?.toString().toLowerCase() == 'true';
      final double costPriceFromCsv = double.tryParse(row[8]?.value?.toString() ?? '') ?? 0.0;
      final double sPrice = double.tryParse(row[9]?.value?.toString() ?? '') ?? 0.0;
      final double taxRate = double.tryParse(row[7]?.value?.toString() ?? '') ?? 0.0;
      
      double purchasePriceBeforeTax;
      double purchasePriceAfterTax;
      double tAmt;

      if (isTaxInclusive) {
        purchasePriceAfterTax = costPriceFromCsv;
        purchasePriceBeforeTax = purchasePriceAfterTax / (1 + taxRate / 100);
        tAmt = purchasePriceAfterTax - purchasePriceBeforeTax;
      } else {
        purchasePriceBeforeTax = costPriceFromCsv;
        tAmt = purchasePriceBeforeTax * (taxRate / 100);
        purchasePriceAfterTax = purchasePriceBeforeTax + tAmt;
      }

      final String supplierNameInCsv = row[5]?.value?.toString().trim() ?? '';
      Supplier? rowSupplier;
      if (supplierNameInCsv.isNotEmpty) {
        try {
          rowSupplier = offlineSuppliers.firstWhere(
            (s) => s.name.toLowerCase() == supplierNameInCsv.toLowerCase()
          );
        } catch (_) {
          rowSupplier = defaultSupplier;
        }
      } else {
        rowSupplier = defaultSupplier;
      }

      final inventoryItem = InventoryItem(
        id: const Uuid().v4(),
        name: name,
        description: row[1]?.value?.toString().trim() ?? '',
        itemCode: code,
        category: (row[3]?.value?.toString().trim() ?? '').isNotEmpty ? Category(name: row[3]?.value?.toString().trim() ?? '') : null,
        unit: (row[4]?.value?.toString().trim() ?? '').isNotEmpty ? Unit(name: row[4]?.value?.toString().trim() ?? '') : null,
        supplier: rowSupplier,
        tax: (row[6]?.value?.toString().trim() ?? '').isNotEmpty 
            ? Tax(name: row[6]?.value?.toString().trim() ?? '', taxPercentage: taxRate)
            : null,
        purchaseTax: (row[6]?.value?.toString().trim() ?? '').isNotEmpty 
            ? Tax(name: row[6]?.value?.toString().trim() ?? '', taxPercentage: taxRate)
            : null,
        purchasePrice: purchasePriceBeforeTax,
        sellingPrice: sPrice,
        priceWithoutTax: purchasePriceAfterTax,
        taxAmount: tAmt,
        reorderLevel: double.tryParse(row[10]?.value?.toString() ?? '') ?? 0.0,
        isService: isService,
        itemType: isService ? ItemType.SERVICE : ItemType.INVENTORY,
      );

      final branchStock = BranchStock(
        id: '${nowStr}_bs_$i',
        stock: double.tryParse(row[13]?.value?.toString() ?? '') ?? 0.0,
      );
      branchStock.item.value = inventoryItem;
      branchStock.branch.value = targetBranch;

      branchStocks.add(branchStock);
      importCount++;
    }

    if (importCount > 0) {
      final List<String> updatedStockJson = branchStocks.map((item) => jsonEncode(item.toJson())).toList();
      await prefs.setStringList(AppConstants.keyOfflineBranchStock, updatedStockJson);
    }

    if (context.mounted) {
      if (errors.isNotEmpty) {
        _showImportSummary(context, importCount, skipCount, errors);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully imported $importCount inventory items.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _showImportSummary(BuildContext context, int success, int skipped, List<String> errors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Summary'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Success: $success items', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              Text('Skipped: $skipped items (Errors)', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              const Divider(),
              const Text('Errors:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: errors.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• ${errors[index]}', style: const TextStyle(fontSize: 12, color: Colors.red)),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }
}
