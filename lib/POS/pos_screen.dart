import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:vimbika_pro/model/branch_stock.dart';
import 'package:vimbika_pro/model/currency.dart';
import 'package:vimbika_pro/model/customer.dart';
import 'package:vimbika_pro/model/category.dart' as model;
import 'package:vimbika_pro/customer/add_customer_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import provider
import 'package:vimbika_pro/POS/pos_screen_controller.dart';
import 'package:collection/collection.dart'; // Import for groupBy

import '../model/customer_currency_amount.dart';
import '../model/sale.dart';
import '../model/sale_item.dart'; // Import SaleItem


class POSScreen extends StatelessWidget {
  const POSScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => POSScreenController(context),
      child: Consumer<POSScreenController>(
        builder: (context, controller, child) {
          return Scaffold(
            backgroundColor: AppTheme.nearlyWhite,
            appBar: AppBar(
              title: const Text('POS', style: AppTheme.title),
              backgroundColor: AppTheme.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: AppTheme.nearlyBlack),
              actions: [
                if (controller.currencies.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: AppTheme.vimbikaBlue.withAlpha(20), borderRadius: BorderRadius.circular(8)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Currency>(
                        value: controller.selectedCurrency,
                        onChanged: (val) => controller.selectedCurrency = val,
                        items: controller.currencies.map((c) => DropdownMenuItem(value: c, child: Text(c.name!, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.vimbikaBlue)))).toList(),
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.pause),
                  tooltip: 'Hold Sale',
                  onPressed: controller.holdSale,
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.unarchive),
                      tooltip: 'View Held Sales',
                      onPressed: () => _showHeldSalesDialog(context, controller),
                    ),
                    if (controller.heldSalesCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '${controller.heldSalesCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Clear Sale',
                  onPressed: controller.clearPOSScreen,
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_cart),
                      onPressed: () {
                        _showCartDialog(context, controller);
                      },
                    ),
                    if (controller.cart.isNotEmpty)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '${controller.cart.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                )
              ],
            ),
            body: controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final isSmallScreen = constraints.maxWidth < 800;

                      if (isSmallScreen) {
                        return _buildProductList(context, controller, constraints, isSmallScreen);
                      }

                      return Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: _buildProductList(context, controller, constraints, isSmallScreen),
                          ),
                          Container(
                            width: 380,
                            decoration: BoxDecoration(color: AppTheme.white, boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 10)]),
                            child: _buildCartSummary(context, controller),
                          ),
                        ],
                      );
                    },
                  ),
            floatingActionButton: MediaQuery.of(context).size.width < 800
                ? FloatingActionButton.extended(
                    onPressed: () => _showCartDialog(context, controller),
                    label: Text('Cart (${controller.cart.length})'),
                    icon: const Icon(Icons.shopping_basket),
                    backgroundColor: AppTheme.vimbikaBlue,
                  )
                : null,
          );
        },
      ),
    );
  }

  Widget _buildProductList(BuildContext context, POSScreenController controller, BoxConstraints constraints, bool isSmallScreen) {
    final filteredStocks = controller.filteredBranchStocks;
    final crossAxisCount = isSmallScreen ? (constraints.maxWidth < 450 ? 2 : 3) : (constraints.maxWidth < 1000 ? 3 : 4);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller.searchController,
                      onChanged: (val) {
                        controller.setSearchQuery(val);
                        if (controller.isBarcodeSearchMode && val.isNotEmpty) {
                          final stock = controller.filteredBranchStocks.firstWhere(
                            (s) => s.item?.itemCode == val,
                            orElse: () => BranchStock(id: '', item: null, branch: null, quantity: 0),
                          );
                          if (stock.item != null) {
                            controller.addToCart(stock);
                            controller.searchController.clear();
                            controller.setSearchQuery('');
                          }
                        }
                      },
                      decoration: InputDecoration(
                        hintText: controller.isBarcodeSearchMode ? 'Scan barcode...' : 'Search products...',
                        prefixIcon: Icon(controller.isBarcodeSearchMode ? Icons.barcode_reader : Icons.search),
                        suffixIcon: IconButton(
                          icon: Icon(controller.isBarcodeSearchMode ? Icons.text_fields : Icons.barcode_reader),
                          tooltip: controller.isBarcodeSearchMode ? 'Switch to Text Search' : 'Switch to Barcode Search',
                          onPressed: controller.toggleBarcodeSearchMode,
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: AppTheme.white,
                      ),
                      keyboardType: controller.isBarcodeSearchMode ? TextInputType.number : TextInputType.text,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildCategoryFilter(controller),
            ],
          ),
        ),
        Expanded(
          child: controller.isDownloadingStock
              ? const Center(child: CircularProgressIndicator())
              : filteredStocks.isEmpty
                  ? Center(child: Text(controller.allBranchStocks.isEmpty ? 'No stock in inventory' : 'No matching products'))
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: filteredStocks.length,
                      itemBuilder: (context, index) {
                        final stock = filteredStocks[index];
                        final product = stock.item!;
                        return GestureDetector(
                          onTap: () => controller.addToCart(stock),
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: Container(decoration: BoxDecoration(color: AppTheme.vimbikaBlue.withAlpha(20), borderRadius: const BorderRadius.vertical(top: Radius.circular(12))), child: Icon(product.isService ? Icons.room_service_outlined : Icons.inventory_2_outlined, color: AppTheme.vimbikaBlue, size: 32))),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      Text('${controller.selectedCurrency?.symbol ?? ''}${(product.sellingPrice * (controller.selectedCurrency?.rate ?? 1.0)).toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.vimbikaBlue, fontWeight: FontWeight.bold, fontSize: 12)),
                                      if (!controller.allowOutOfStockSales) // Conditionally display stock
                                        Text(product.isService ? 'Service' : 'In Stock: ${stock.quantity.toStringAsFixed(0)}', style: TextStyle(fontSize: 10, color: product.isService ? Colors.green : (stock.quantity <= 0 ? Colors.red : AppTheme.vimbikaBlue))),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  void _showCartDialog(BuildContext context, POSScreenController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) => ListenableBuilder(
        listenable: controller,
        builder: (context, child) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(color: AppTheme.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: Column(
            children: [
              Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              Expanded(child: _buildCartSummary(context, controller, isDialog: true)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartSummary(BuildContext context, POSScreenController controller, {bool isDialog = false}) {
    final customerBalance = controller.selectedCustomer?.currencyBalance?.firstWhere(
          (cca) => cca.currency?.id == controller.selectedCurrency?.id,
          orElse: () => CustomerCurrencyAmount(currency: controller.selectedCurrency, balance: 0.0),
        ).balance ??
        0.0;

    // Group payments by payment type
    final groupedPayments = controller.payments.groupFoldBy<String, double>(
      (payment) => payment.paymentType?.name ?? 'Unknown',
      (previous, payment) => previous??0.00 + payment.amount,
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Current Order', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          _buildCustomerSelector(context, controller),
          if (controller.selectedCustomer != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                'Customer Balance: ${controller.selectedCurrency?.symbol ?? ''}${customerBalance.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.vimbikaBlue),
              ),
            ),
          const Divider(),
          Expanded(
            child: controller.cart.isEmpty
                ? const Center(child: Text('Order is empty'))
                : ListView.builder(
                    itemCount: controller.cart.length,
                    itemBuilder: (context, index) {
                      final item = controller.cart[index];
                      final taxRate = item.inventoryItem?.tax?.taxPercentage ?? 0.0;

                      final rate = controller.selectedCurrency?.rate ?? 1.0;
                      double displayTotal = (item.total + item.taxAmount) * rate;

                      final String itemId = item.inventoryItem!.id!;
                      TextEditingController? quantityController = controller.quantityControllers[itemId];
                      TextEditingController? priceController = controller.priceControllers[itemId];
                      TextEditingController? discountController = controller.discountControllers[itemId];

                      if (quantityController == null) {
                        quantityController = TextEditingController(text: item.quantity.toStringAsFixed(2));
                        controller.quantityControllers[itemId] = quantityController;
                      } else {
                        final currentTextAsDouble = double.tryParse(quantityController.text);
                        if (currentTextAsDouble == null || (currentTextAsDouble - item.quantity).abs() > 0.001) {
                          quantityController.text = item.quantity.toStringAsFixed(2);
                        }
                      }

                      if (priceController == null) {
                        priceController = TextEditingController(text: item.sellingPrice.toStringAsFixed(2));
                        controller.priceControllers[itemId] = priceController;
                      } else {
                        final currentTextAsDouble = double.tryParse(priceController.text);
                        if (currentTextAsDouble == null || (currentTextAsDouble - item.sellingPrice).abs() > 0.001) {
                          priceController.text = item.sellingPrice.toStringAsFixed(2);
                        }
                      }

                      if (discountController == null) {
                        discountController = TextEditingController(text: item.discountAmount.toStringAsFixed(2));
                        controller.discountControllers[itemId] = discountController;
                      } else {
                        final currentTextAsDouble = double.tryParse(discountController.text);
                        if (currentTextAsDouble == null || (currentTextAsDouble - item.discountAmount).abs() > 0.001) {
                          discountController.text = item.discountAmount.toStringAsFixed(2);
                        }
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.inventoryItem?.name ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                        Text(
                                          '${controller.selectedCurrency?.symbol ?? ''}${(item.sellingPrice * rate).toStringAsFixed(2)} '
                                          '${item.discountAmount > 0 ? "(-${controller.selectedCurrency?.symbol ?? ''}${(item.discountAmount * rate).toStringAsFixed(2)})" : ""}',
                                          style: const TextStyle(fontSize: 11, color: AppTheme.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 50,
                                        child: TextField(
                                          controller: quantityController,
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                                            border: UnderlineInputBorder(),
                                          ),
                                          onTap: () {
                                            quantityController!.selection = TextSelection(baseOffset: 0, extentOffset: quantityController.text.length);
                                          },
                                          onChanged: (value) {
                                            final val = double.tryParse(value);
                                            if (val != null) controller.updateCartItemDetails(index, quantity: val);
                                          },
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.edit, size: 18, color: AppTheme.vimbikaBlue),
                                        padding: EdgeInsets.zero,
                                        onSelected: (value) {
                                          if (value == 'price') {
                                            _showEditDialog(context, 'Edit Price', priceController!, controller, (val) {
                                              controller.updateCartItemDetails(index, sellingPrice: val);
                                            });
                                          } else if (value == 'discount') {
                                            _showEditDialog(context, 'Edit Discount', discountController!, controller, (val) {
                                              controller.updateCartItemDetails(index, discountAmount: val);
                                            }, item: item);
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(value: 'price', child: Text('Edit Price')),
                                          const PopupMenuItem(value: 'discount', child: Text('Edit Discount')),
                                        ],
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close, size: 18, color: Colors.red),
                                        onPressed: () => controller.removeFromCart(index),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  if (taxRate > 0)
                                    Text('Tax: $taxRate% (${controller.selectedCurrency?.symbol ?? ''}${(item.taxAmount * rate).toStringAsFixed(2)})',
                                        style: const TextStyle(fontSize: 10, color: AppTheme.grey)),
                                  if (taxRate <= 0) const SizedBox(),
                                  Text('Total: ${controller.selectedCurrency?.symbol ?? ''}${displayTotal.toStringAsFixed(2)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.vimbikaBlue)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const Divider(),
          _buildPaymentSummarySection(context, controller, groupedPayments, isDialog: isDialog), // Call the new section builder
          const SizedBox(height: 12),
          if (controller.cart.isNotEmpty && controller.balanceDueConverted > 0.01)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Balance Due: ${controller.selectedCurrency?.symbol ?? ""}${controller.balanceDueConverted.toStringAsFixed(2)}',
                  textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummarySection(BuildContext context, POSScreenController controller, Map<String, double> groupedPayments, {bool isDialog = false}) {
    final double taxAmountConverted = controller.taxTotalBase * (controller.selectedCurrency?.rate ?? 1.0);
    final double subtotalConverted = controller.subTotalBase * (controller.selectedCurrency?.rate ?? 1.0);

    return Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Subtotal:', style: TextStyle(fontSize: 14)),
          Text('${controller.selectedCurrency?.symbol ?? ''}${subtotalConverted.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14))
        ]),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Tax Total:', style: TextStyle(fontSize: 14)),
          Text('${controller.selectedCurrency?.symbol ?? ''}${taxAmountConverted.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14))
        ]),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Grand Total:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text('${controller.selectedCurrency?.symbol ?? ''}${controller.grandTotalConverted.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
        ]),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Paid:', style: TextStyle(color: Colors.green)),
          Text('${controller.selectedCurrency?.symbol ?? ''}${controller.amountPaidConverted.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
        ]),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Balance:', style: TextStyle(color: Colors.red)),
          Text('${controller.selectedCurrency?.symbol ?? ''}${controller.balanceDueConverted.toStringAsFixed(2)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
        ]),
        const SizedBox(height: 12),
        if (controller.payments.isNotEmpty)
          Container(
            decoration: BoxDecoration(color: AppTheme.grey.withAlpha(10), borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: List.generate(controller.payments.length, (index) {
                final payment = controller.payments[index];
                return ListTile(
                  dense: true,
                  title: Text(payment.paymentType?.name ?? 'Unknown', style: const TextStyle(fontSize: 11)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${controller.selectedCurrency?.symbol ?? ''}${payment.amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11)),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          final editController = TextEditingController(text: payment.amount.toStringAsFixed(2));
                          showDialog(
                            context: context, // Using the correct context here
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Edit Payment Amount'),
                              content: TextField(
                                controller: editController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                autofocus: true,
                                decoration: const InputDecoration(border: OutlineInputBorder()),
                                onTap: () => editController.selection = TextSelection(baseOffset: 0, extentOffset: editController.text.length),
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
                                ElevatedButton(
                                  onPressed: () {
                                    final newAmt = double.tryParse(editController.text);
                                    if (newAmt != null && newAmt > 0) {
                                      controller.updatePaymentAmount(index, newAmt);
                                    } else if (newAmt == 0) {
                                      controller.removePayment(index);
                                    }
                                    Navigator.pop(dialogContext);
                                  },
                                  child: const Text('Save'),
                                ),
                              ],
                            ),
                          );
                        },
                        child: const Icon(Icons.edit, size: 16, color: AppTheme.vimbikaBlue),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => controller.removePayment(index),
                        child: const Icon(Icons.close, size: 16, color: Colors.red),
                      )
                    ],
                  ),
                );
              }),
            ),
          ),
        const SizedBox(height: 8),
        // New "Print Receipt" checkbox
        if (controller.cart.isNotEmpty)
          SwitchListTile(
            title: const Text('Print Receipt for this Sale'),
            value: controller.printReceiptForThisSale,
            onChanged: (value) {
              controller.printReceiptForThisSale = value;
            },
            secondary: const Icon(Icons.print),
            contentPadding: EdgeInsets.zero, // Adjust padding as needed
          ),
        const SizedBox(height: 8),
        if (controller.balanceDueConverted > 0.01)
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        controller.addPayment(context);
                      },
                      icon: const Icon(Icons.payment, size: 18),
                      label: const Text('Add Payment', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await controller.quickCashSale();
                        if (context.mounted && isDialog) {
                          Navigator.pop(context);
                        }
                      },
                      icon: const Icon(Icons.flash_on, size: 18),
                      label: const Text('Quick Cash', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              if (controller.selectedCustomer != null && controller.cart.isNotEmpty) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      controller.payFromAccount(context);
                    },
                    icon: const Icon(Icons.account_balance_wallet, size: 18),
                    label: const Text('Pay via ACC', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          )
        else if (controller.cart.isNotEmpty)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.vimbikaBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: controller.isProcessingSale
                  ? null
                  : () async {
                      await controller.completeSale();
                      if (context.mounted && isDialog) {
                        Navigator.pop(context);
                      }
                    },
              child: controller.isProcessingSale
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Complete Sale', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryFilter(POSScreenController controller) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildCategoryChip(controller, null),
          ...controller.categories.map((cat) => _buildCategoryChip(controller, cat)),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(POSScreenController controller, model.Category? category) {
    final isSelected = controller.selectedCategory?.id == category?.id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(category?.name ?? 'All'),
        selected: isSelected,
        onSelected: (selected) {
          controller.selectedCategory = selected ? category : null;
        },
        selectedColor: AppTheme.vimbikaBlue.withAlpha(50),
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.vimbikaBlue : AppTheme.darkText,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildCustomerSelector(BuildContext context, POSScreenController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Autocomplete<Customer>(
              initialValue: TextEditingValue(text: controller.selectedCustomer?.name ?? ''),
              displayStringForOption: (customer) => customer.name,
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text == '') {
                  return controller.customers; // Show all customers when text is empty
                }
                return controller.customers.where((customer) {
                  return customer.name.toLowerCase().contains(textEditingValue.text.toLowerCase()) ||
                         (customer.accountNumber?.toLowerCase().contains(textEditingValue.text.toLowerCase()) ?? false);
                });
              },
              onSelected: (Customer selection) {
                controller.selectedCustomer = selection;
                // Unfocus the text field to close the options list
                FocusScope.of(context).unfocus();
              },
              fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
                // Ensure the Autocomplete's internal controller is cleared when our managed controller is cleared
                controller.customerSearchController.addListener(() {
                  if (controller.customerSearchController.text.isEmpty && textEditingController.text.isNotEmpty) {
                    textEditingController.clear();
                  }
                });

                return TextField(
                  controller: textEditingController,
                  focusNode: focusNode, // Use the Autocomplete's provided FocusNode
                  canRequestFocus: controller.customerSelectFocus, // Manually disable focus
                  decoration: InputDecoration(
                    hintText: 'Search or select customer...',
                    prefixIcon: const Icon(Icons.person_search),
                    suffixIcon: textEditingController.text.isNotEmpty || controller.selectedCustomer != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              textEditingController.clear();
                              controller.selectedCustomer = null;
                              FocusScope.of(context).requestFocus(focusNode); // Request focus using the provided focusNode
                            },
                          )
                        : const Icon(Icons.arrow_drop_down), // Add dropdown icon when empty
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: AppTheme.nearlyWhite,
                    isDense: true,
                  ),
                  onChanged: (value) {
                    if (value.isEmpty) {
                      controller.selectedCustomer = null;
                      controller.customerSelectFocus = false;
                    }
                  },
                  onTap: () {
                    controller.customerSelectFocus = true;
                    // Workaround to show dropdown on tap when empty
                    if (textEditingController.text.isEmpty) {
                      textEditingController.text = ' ';
                      textEditingController.text = '';
                    }
                  },
                );
              },
              optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<Customer> onSelected, Iterable<Customer> options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4.0,
                    child: SizedBox(
                      height: 200.0,
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: options.length,
                        itemBuilder: (BuildContext context, int index) {
                          final Customer option = options.elementAt(index);
                          return GestureDetector(
                            onTap: () {
                              onSelected(option);
                            },
                            child: ListTile(
                              dense: true,
                              visualDensity: VisualDensity.compact,
                              title: Text(option.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                              subtitle: option.accountNumber != null ? Text(option.accountNumber!) : null,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          IconButton(
            iconSize: 20,
            onPressed: () async {
              final Customer? newCustomer = await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddCustomerScreen()));
              if (context.mounted && newCustomer != null) {
                controller.clearPOSScreen(newCustomer: newCustomer); // Pass the new customer
              }
            },
            icon: const Icon(Icons.person_add_alt_1, color: AppTheme.vimbikaBlue),
          ),
        ],
      ),
    );
  }

  void _showHeldSalesDialog(BuildContext context, POSScreenController controller) async {
    final List<Sale> heldSales = await controller.retrieveHeldSales();
    if (!context.mounted) return; // Add this check

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Held Sales'),
            content: SizedBox(
              width: double.maxFinite,
              child: heldSales.isEmpty
                  ? const Center(child: Text('No sales on hold.'))
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: heldSales.length,
                      itemBuilder: (context, index) {
                        final sale = heldSales[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ExpansionTile(
                            title: Text('Sale for ${sale.ticketName ?? 'Guest'}'),
                            subtitle: Text('Items: ${sale.items.length}, Total: ${sale.currency?.symbol ?? ''}${sale.grandTotal.toStringAsFixed(2)}'),
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: sale.items.map((item) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${item.inventoryItem?.name ?? 'Unknown Item'} (x${item.quantity.toStringAsFixed(0)})',
                                              style: const TextStyle(fontSize: 13),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Text(
                                            '${sale.currency?.symbol ?? ''}${(item.total + item.taxAmount).toStringAsFixed(2)}',
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.play_arrow, color: Colors.green),
                                      tooltip: 'Load Sale',
                                      onPressed: () {
                                        controller.loadHeldSale(sale);
                                        controller.removeHeldSale(sale.id!);
                                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      tooltip: 'Delete Sale',
                                      onPressed: () async {
                                        await controller.removeHeldSale(sale.id!);
                                        setDialogState(() {
                                          heldSales.removeAt(index);
                                        });
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Held sale for ${sale.customer?.name ?? 'Guest'} deleted.'), backgroundColor: Colors.red),
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, String title, TextEditingController textController, POSScreenController controller, Function(double) onSubmitted, {SaleItem? item}) {
    bool isPercentage = title.toLowerCase().contains('discount');
    bool discountAsPercentage = true; // Default to percentage for discount dialog

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isPercentage)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Value'),
                        Switch(
                          value: discountAsPercentage,
                          onChanged: (value) {
                            setDialogState(() {
                              discountAsPercentage = value;
                            });
                          },
                        ),
                        const Text('Percentage'),
                      ],
                    ),
                  TextField(
                    controller: textController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    autofocus: true,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      suffixText: discountAsPercentage && isPercentage ? '%' : null,
                    ),
                    onTap: () {
                      textController.selection = TextSelection(baseOffset: 0, extentOffset: textController.text.length);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    controller.customerSelectFocus = false;
                    Navigator.pop(context);
                  }, 
                  child: const Text('Cancel')
                ),
                ElevatedButton(
                  onPressed: () {
                    final val = double.tryParse(textController.text);
                    if (val != null) {
                      if (isPercentage && discountAsPercentage) {
                        if (item != null) {
                          final discountAmount = (item.quantity * item.sellingPrice) * (val / 100);
                          onSubmitted(discountAmount);
                        }
                      } else {
                        onSubmitted(val);
                      }
                    }
                    controller.customerSelectFocus = false;
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
