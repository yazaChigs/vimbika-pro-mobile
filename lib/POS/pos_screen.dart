import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:vimbika_pro/model/branch_stock.dart';
import 'package:vimbika_pro/model/currency.dart';
import 'package:vimbika_pro/model/customer.dart';
import 'package:vimbika_pro/customer/add_customer_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import provider
import 'package:vimbika_pro/POS/pos_screen_controller.dart';
import 'package:collection/collection.dart'; // Import for groupBy

import '../model/customer_currency_amount.dart';
import '../model/sale.dart';
import '../model/sale_item.dart'; // Import SaleItem
import 'package:vimbika_pro/model/category.dart' as model; // Re-add this import for _CategoryFilterWidget

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
                  icon: const Icon(Icons.calculate),
                  tooltip: 'Calculator',
                  onPressed: () => _showCalculatorDialog(context),
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
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'clear_sale') {
                      controller.clearPOSScreen();
                    } else if (value == 'refresh_stock') {
                      controller.downloadStockForDefaultBranch();
                    } else if (value == 'download_other_data') {
                      controller.downloadOtherData();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'clear_sale',
                      child: Text('Clear Sale'),
                    ),
                    const PopupMenuItem(
                      value: 'refresh_stock',
                      child: Text('Refresh Stock'),
                    ),
                    const PopupMenuItem(
                      value: 'download_other_data',
                      child: Text('Download other data'),
                    ),
                  ],
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
                      flex: 2,
                      child: _buildProductList(context, controller, constraints, isSmallScreen),
                    ),
                    Expanded(
                      flex: 1,
                      child: Container(
                        decoration: BoxDecoration(color: AppTheme.white, boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 10)]),
                        child: _buildCartSummary(context, controller),
                      ),
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
                    child: controller.isBarcodeSearchMode
                        ? TextField(
                            controller: controller.scanController,
                            focusNode: controller.scanFocusNode,
                            onSubmitted: (_) {
                              controller.scanFocusNode.requestFocus();
                            },
                            onEditingComplete: () {
                              // Prevent default focus movement
                            },
                            onChanged: (val) {
                              if (val.isNotEmpty) {
                                final stock = controller.filteredBranchStocks.firstWhere(
                                  (s) => s.item?.itemCode == val,
                                  orElse: () => BranchStock(id: '', item: null, branch: null, stock: 0),
                                );
                                if (stock.item != null) {
                                  controller.addToCart(stock);
                                  controller.scanController.clear();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('${stock.item!.name} added to cart.'),
                                        duration: const Duration(seconds: 1),
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                            decoration: InputDecoration(
                              hintText: 'Scan barcode...',
                              prefixIcon: const Icon(Icons.barcode_reader),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.search),
                                tooltip: 'Switch to Text Search',
                                onPressed: controller.toggleBarcodeSearchMode,
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: AppTheme.white,
                            ),
                            keyboardType: TextInputType.number,
                          )
                        : TextField(
                            controller: controller.searchController,
                            focusNode: controller.searchFocusNode,
                            onChanged: (val) {
                              controller.setSearchQuery(val);
                            },
                            decoration: InputDecoration(
                              hintText: 'Search products...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.barcode_reader),
                                tooltip: 'Switch to Barcode Search',
                                onPressed: controller.toggleBarcodeSearchMode,
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: AppTheme.white,
                            ),
                            keyboardType: TextInputType.text,
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _CategoryFilterWidget(controller: controller),
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
                              Text(product.isService ? 'Service' : 'In Stock: ${stock.stock.toStringAsFixed(0)}', style: TextStyle(fontSize: 10, color: product.isService ? Colors.green : (stock.stock <= 0 ? Colors.red : AppTheme.vimbikaBlue))),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Added vertical padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min, // Use min size
        children: [
          const Text('Current Order', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          _buildCustomerSelector(context, controller),
          if (controller.selectedCustomer != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0), // Reduced padding
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Customer Balance: ${controller.selectedCurrency?.symbol ?? ''}${customerBalance.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.vimbikaBlue),
                  ),
                  Text(
                    'Points: ${controller.selectedCustomer?.points.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.vimbikaBlue),
                  ),
                ],
              ),
            ),
          const Divider(height: 8), // Reduced height
          Expanded(
            child: controller.cart.isEmpty
                ? const Center(child: Text('Order is empty', style: TextStyle(fontSize: 14)))
                : ListView.builder(
              itemCount: controller.cart.length,
              itemBuilder: (context, index) {
                final item = controller.cart[controller.cart.length - 1 - index]; // Display last added on top
                // final taxRate = item.inventoryItem?.tax?.taxPercentage ?? 0.0; // Removed taxRate as it's not used for display
                final rate = controller.selectedCurrency?.rate ?? 1.0;
                double displayTotal = (item.total ) * rate;

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
                  margin: const EdgeInsets.only(bottom: 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.inventoryItem?.name ?? '',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${controller.selectedCurrency?.symbol ?? ''}${displayTotal.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.vimbikaBlue),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Text(
                              'Qty: ',
                              style: TextStyle(fontSize: 12, color: AppTheme.grey),
                            ),
                            SizedBox(
                              width: 35,
                              height: 16,
                              child: TextField(
                                controller: quantityController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  border: UnderlineInputBorder(),
                                ),
                                onTap: () {
                                  quantityController!.selection = TextSelection(baseOffset: 0, extentOffset: quantityController.text.length);
                                },
                                onChanged: (value) {
                                  final val = double.tryParse(value);
                                  if (val != null) controller.updateCartItemDetails(controller.cart.length - 1 - index, quantity: val);
                                },
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${controller.selectedCurrency?.symbol ?? ''}${(item.sellingPrice * rate).toStringAsFixed(2)} '
                                    '${item.discountAmount > 0 ? "(-${controller.selectedCurrency?.symbol ?? ''}${(item.discountAmount * rate).toStringAsFixed(2)})" : ""}',
                                style: const TextStyle(fontSize: 11, color: AppTheme.grey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.edit, size: 18, color: AppTheme.vimbikaBlue),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'price', child: Text('Edit Price', style: TextStyle(fontSize: 13))),
                                const PopupMenuItem(value: 'discount', child: Text('Edit Discount', style: TextStyle(fontSize: 13))),
                              ],
                              onSelected: (value) {
                                if (value == 'price') {
                                  _showEditDialog(context, 'Edit Price', priceController!, controller, (val) {
                                    controller.updateCartItemDetails(controller.cart.length - 1 - index, sellingPrice: val);
                                  });
                                } else if (value == 'discount') {
                                  _showEditDialog(context, 'Edit Discount', discountController!, controller, (val) {
                                    controller.updateCartItemDetails(controller.cart.length - 1 - index, discountAmount: val);
                                  }, item: item);
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18, color: Colors.red),
                              onPressed: () => controller.removeFromCart(controller.cart.length - 1 - index),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 8), // Reduced height
          _buildPaymentSummarySection(context, controller, groupedPayments, isDialog: isDialog), // Call the new section builder
          const SizedBox(height: 8), // Reduced height
          if (controller.cart.isNotEmpty && controller.balanceDueConverted > 0.01)
            Padding(
              padding: const EdgeInsets.only(top: 4), // Reduced padding
              child: Text('Balance Due: ${controller.selectedCurrency?.symbol ?? ""}${controller.balanceDueConverted.toStringAsFixed(2)}',
                  textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15)),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummarySection(BuildContext context, POSScreenController controller, Map<String, double> groupedPayments, {bool isDialog = false}) {
    final double taxAmountConverted = controller.taxTotalBase * (controller.selectedCurrency?.rate ?? 1.0);
    final double subtotalConverted = controller.subTotalBase - controller.taxTotalBase * (controller.selectedCurrency?.rate ?? 1.0);

    return Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Subtotal:', style: TextStyle(fontSize: 15)),
          Text('${controller.selectedCurrency?.symbol ?? ''}${subtotalConverted.toStringAsFixed(2)}', style: const TextStyle(fontSize: 15))
        ]),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Tax Total:', style: TextStyle(fontSize: 15)),
          Text('${controller.selectedCurrency?.symbol ?? ''}${taxAmountConverted.toStringAsFixed(2)}', style: const TextStyle(fontSize: 15))
        ]),
        const SizedBox(height: 2), // Reduced height
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Grand Total:', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          Text('${controller.selectedCurrency?.symbol ?? ''}${controller.grandTotalConverted.toStringAsFixed(2)}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold))
        ]),
        const SizedBox(height: 4), // Reduced height
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Paid: ${controller.selectedCurrency?.symbol ?? ''}${controller.amountPaidConverted.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.green, fontSize: 15, fontWeight: FontWeight.bold)),
            Text(
              controller.balanceDueConverted <= 0.0
                  ? 'Change: ${controller.selectedCurrency?.symbol ?? ''}${(controller.balanceDueConverted * -1).toStringAsFixed(2)}'
                  : 'Balance Due: ${controller.selectedCurrency?.symbol ?? ''}${controller.balanceDueConverted.toStringAsFixed(2)}',
              style: TextStyle(
                  color: controller.balanceDueConverted <= 0.0 ? Colors.green : Colors.red,
                  fontSize: 15,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8), // Reduced height
        if (controller.payments.isNotEmpty)
          Container(
            decoration: BoxDecoration(color: AppTheme.grey.withAlpha(10), borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: List.generate(controller.payments.length, (index) {
                final payment = controller.payments[index];
                return ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact, // Make ListTile more compact
                  title: Text(payment.paymentType?.name ?? 'Unknown', style: const TextStyle(fontSize: 14)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${controller.selectedCurrency?.symbol ?? ''}${payment.amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 4), // Reduced width
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
                        child: const Icon(Icons.edit, size: 18, color: AppTheme.vimbikaBlue),
                      ),
                      const SizedBox(width: 4), // Reduced width
                      InkWell(
                        onTap: () => controller.removePayment(index),
                        child: const Icon(Icons.close, size: 18, color: Colors.red),
                      )
                    ],
                  ),
                );
              }),
            ),
          ),
        const SizedBox(height: 4), // Reduced height
        // New "Print Receipt" checkbox
        if (controller.cart.isNotEmpty)
          SwitchListTile(
            title: const Text('Print Receipt for this Sale', style: TextStyle(fontSize: 15)),
            value: controller.printReceiptForThisSale,
            onChanged: (value) {
              controller.printReceiptForThisSale = value;
            },
            secondary: const Icon(Icons.print, size: 22),
            contentPadding: EdgeInsets.zero, // Adjust padding as needed
            dense: true, // Make SwitchListTile more compact
          ),
        const SizedBox(height: 4), // Reduced height
        if (controller.balanceDueConverted > 0.01 || (controller.cart.isEmpty && controller.selectedCustomer != null))
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
                      label: const Text('Add Payment', style: TextStyle(fontSize: 14)),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)), // Reduced padding
                    ),
                  ),
                  const SizedBox(width: 4), // Reduced width
                  if (controller.cart.isNotEmpty)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await controller.quickCashSale();
                          if (context.mounted && isDialog) {
                            Navigator.pop(context);
                          }
                        },
                        icon: const Icon(Icons.flash_on, size: 18),
                        label: const Text('Quick Cash', style: TextStyle(fontSize: 14)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8), // Reduced padding
                        ),
                      ),
                    ),
                ],
              ),
              if (controller.selectedCustomer != null && controller.cart.isNotEmpty) ...[
                const SizedBox(height: 4), // Reduced height
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      controller.payFromAccount(context);
                    },
                    icon: const Icon(Icons.account_balance_wallet, size: 18),
                    label: const Text('Pay via ACC', style: TextStyle(fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8), // Reduced padding
                    ),
                  ),
                ),
              ],
            ],
          )
        else if (controller.cart.isNotEmpty || controller.payments.isNotEmpty)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.vimbikaBlue,
                padding: const EdgeInsets.symmetric(vertical: 12), // Reduced padding
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
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) // Reduced size
                  : const Text('Complete Sale', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }

  Widget _buildCustomerSelector(BuildContext context, POSScreenController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4), // Reduced padding
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
                    prefixIcon: const Icon(Icons.person_search, size: 22),
                    suffixIcon: textEditingController.text.isNotEmpty || controller.selectedCustomer != null
                        ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        textEditingController.clear();
                        controller.selectedCustomer = null;
                        FocusScope.of(context).requestFocus(focusNode); // Request focus using the provided focusNode
                      },
                    )
                        : const Icon(Icons.arrow_drop_down, size: 22),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: AppTheme.nearlyWhite,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10), // Reduced padding
                  ),
                  style: const TextStyle(fontSize: 16),
                  onChanged: (value) {
                    if (value.isEmpty) {
                      controller.selectedCustomer = null;
                      controller.customerSelectFocus = false;
                    } else {
                      // Check if the entered value matches any customer's account number
                      final matchingCustomer = controller.customers.firstWhereOrNull(
                            (customer) => customer.accountNumber?.toLowerCase() == value.toLowerCase(),
                      );
                      if (matchingCustomer != null) {
                        controller.selectedCustomer = matchingCustomer;
                        // textEditingController.clear(); // Clear the text field after auto-selecting
                        FocusScope.of(context).unfocus(); // Unfocus the text field
                      }
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
                      height: 150.0, // Reduced height
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
                              title: Text(option.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              subtitle: option.accountNumber != null ? Text(option.accountNumber!, style: const TextStyle(fontSize: 14)) : null,
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
            iconSize: 22,
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
                  final double conversionRate = (sale.currency?.rate ?? 1.0);
                  final String displaySymbol = sale.currency?.symbol ?? '';
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 2), // Reduced margin
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), // Reduced padding
                      title: Text('Sale for ${sale.ticketName ?? 'Guest'}', style: const TextStyle(fontSize: 14)), // Reduced font size
                      subtitle: Text('Items: ${sale.items.length}, Total: $displaySymbol${(sale.grandTotal).toStringAsFixed(2)}', style: const TextStyle(fontSize: 12)), // Reduced font size
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0), // Reduced padding
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: sale.items.map((item) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.0), // Reduced padding
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${item.inventoryItem?.name ?? 'Unknown Item'} (x${item.quantity.toStringAsFixed(0)})',
                                        style: const TextStyle(fontSize: 12), // Reduced font size
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      '$displaySymbol${(item.total * conversionRate).toStringAsFixed(2)}',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), // Reduced font size
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0), // Reduced padding
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.play_arrow, color: Colors.green, size: 18), // Reduced icon size
                                tooltip: 'Load Sale',
                                onPressed: () {
                                  controller.loadHeldSale(sale);
                                  controller.removeHeldSale(sale.id!);
                                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 18), // Reduced icon size
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
                        const Text('Value', style: TextStyle(fontSize: 13)), // Reduced font size
                        Switch(
                          value: discountAsPercentage,
                          onChanged: (value) {
                            setDialogState(() {
                              discountAsPercentage = value;
                            });
                          },
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // Make switch more compact
                        ),
                        const Text('Percentage', style: TextStyle(fontSize: 13)), // Reduced font size
                      ],
                    ),
                  TextField(
                    controller: textController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    autofocus: true,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      suffixText: discountAsPercentage && isPercentage ? '%' : null,
                      isDense: true, // Make TextField more compact
                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10), // Reduced padding
                    ),
                    style: const TextStyle(fontSize: 14), // Reduced font size
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
                    child: const Text('Cancel', style: TextStyle(fontSize: 13)) // Reduced font size
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
                  child: const Text('Save', style: TextStyle(fontSize: 13)), // Reduced font size
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCalculatorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return _CalculatorDialog();
      },
    );
  }
}

class _CategoryFilterWidget extends StatelessWidget {
  final POSScreenController controller;

  const _CategoryFilterWidget({required this.controller});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<model.Category?>(
      value: controller.selectedCategory,
      decoration: InputDecoration(
        labelText: 'Filter by Category',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: AppTheme.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('All Categories')),
        ...controller.categories.map((category) => DropdownMenuItem(
          value: category,
          child: Text(category.name ?? 'Unknown Category'),
        )),
      ],
      onChanged: (category) {
        controller.selectedCategory = category;
      },
    );
  }
}

class _CalculatorDialog extends StatefulWidget {
  @override
  __CalculatorDialogState createState() => __CalculatorDialogState();
}

class __CalculatorDialogState extends State<_CalculatorDialog> {
  String _output = "0"; // What is displayed
  String _currentNumber = ""; // The number currently being typed
  double _firstOperand = 0.0;
  String _operator = "";
  bool _shouldClearDisplay = false; // Flag to clear _currentNumber on next digit input

  // Helper to format the result for display
  String _formatResult(double result) {
    if (result.isNaN) return "Error";
    if (result.isInfinite) return "Infinity";
    String s = result.toString();
    if (s.endsWith(".0")) {
      return result.toStringAsFixed(0);
    }
    // Limit decimal places for display if it's too long
    if (s.contains(".") && s.split(".")[1].length > 10) {
      return result.toStringAsFixed(10);
    }
    return s;
  }

  // Resets all calculator state
  void _resetCalculator() {
    _output = "0";
    _currentNumber = "";
    _firstOperand = 0.0;
    _operator = "";
    _shouldClearDisplay = false;
  }

  // Performs the calculation based on current state
  double _calculateResult() {
    double secondOperand = _currentNumber.isEmpty ? _firstOperand : double.parse(_currentNumber);
    double result = _firstOperand;

    if (_operator == "+") {
      result = _firstOperand + secondOperand;
    } else if (_operator == "-") {
      result = _firstOperand - secondOperand;
    } else if (_operator == "×") {
      result = _firstOperand * secondOperand;
    } else if (_operator == "÷") {
      if (secondOperand != 0) {
        result = _firstOperand / secondOperand;
      } else {
        return double.nan; // Indicate error
      }
    }
    return result;
  }

  void _buttonPressed(String buttonText) {
    setState(() {
      if (buttonText == "CLEAR") {
        _resetCalculator();
      } else if (buttonText == "+" || buttonText == "-" || buttonText == "×" || buttonText == "÷") {
        if (_currentNumber.isNotEmpty) {
          if (_operator.isNotEmpty) { // Chaining operations (e.g., 5 + 3 +)
            _firstOperand = _calculateResult();
            _output = _formatResult(_firstOperand);
          } else { // First operation (e.g., 5 +)
            _firstOperand = double.parse(_currentNumber);
          }
        } else if (_output != "0" && _operator.isEmpty) { // If no current number but output has a result (e.g., after =), use output as first operand
          _firstOperand = double.parse(_output);
        }
        _operator = buttonText;
        _shouldClearDisplay = true;
      } else if (buttonText == "=") {
        if (_operator.isNotEmpty) {
          double result = _calculateResult();
          if (result.isNaN) {
            _output = "Error";
            _resetCalculator();
          } else {
            _output = _formatResult(result);
            _firstOperand = result; // Store result for potential chaining or repeated '='
            _currentNumber = ""; // Clear current number, result is in _output
            _operator = ""; // Clear operator
            _shouldClearDisplay = true;
          }
        } else if (_currentNumber.isNotEmpty) {
          // If equals pressed with no operator, just display current number
          _output = _formatResult(double.parse(_currentNumber));
          _firstOperand = 0.0;
          _currentNumber = "";
          _shouldClearDisplay = true;
        }
      } else if (buttonText == ".") {
        if (_shouldClearDisplay) {
          _currentNumber = "0.";
          _shouldClearDisplay = false;
        } else if (!_currentNumber.contains(".")) {
          _currentNumber += buttonText;
        }
        _output = _currentNumber;
      } else { // Number buttons
        if (_shouldClearDisplay) {
          _currentNumber = buttonText;
          _shouldClearDisplay = false;
        } else {
          if (_currentNumber == "0" && buttonText != ".") { // Avoid "01", "02" etc.
            _currentNumber = buttonText;
          } else {
            _currentNumber += buttonText;
          }
        }
        _output = _currentNumber;
      }
    });
  }

  Widget _buildButton(String buttonText, {Color? buttonColor, Color? textColor, bool isSelected = false}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? Colors.orange.shade800 : (buttonColor ?? AppTheme.vimbikaBlue.withAlpha(50)),
            foregroundColor: isSelected ? Colors.white : (textColor ?? AppTheme.nearlyBlack),
            padding: const EdgeInsets.all(16), // Reduced padding
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => _buttonPressed(buttonText),
          child: Text(
            buttonText,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Quick Calculator'),
      content: SingleChildScrollView( // Added SingleChildScrollView
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12), // Reduced vertical padding
              child: Text(
                _output,
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            Column(
              children: [
                Row(
                  children: [
                    _buildButton("7"),
                    _buildButton("8"),
                    _buildButton("9"),
                    _buildButton("÷", buttonColor: Colors.orange, textColor: Colors.white, isSelected: _operator == "÷"),
                  ],
                ),
                Row(
                  children: [
                    _buildButton("4"),
                    _buildButton("5"),
                    _buildButton("6"),
                    _buildButton("×", buttonColor: Colors.orange, textColor: Colors.white, isSelected: _operator == "×"),
                  ],
                ),
                Row(
                  children: [
                    _buildButton("1"),
                    _buildButton("2"),
                    _buildButton("3"),
                    _buildButton("-", buttonColor: Colors.orange, textColor: Colors.white, isSelected: _operator == "-"),
                  ],
                ),
                Row(
                  children: [
                    _buildButton("."),
                    _buildButton("0"),
                    _buildButton("CLEAR", buttonColor: Colors.red, textColor: Colors.white),
                    _buildButton("+", buttonColor: Colors.orange, textColor: Colors.white, isSelected: _operator == "+"),
                  ],
                ),
                Row(
                  children: [
                    _buildButton("=", buttonColor: AppTheme.vimbikaBlue, textColor: Colors.white),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Close'),
        ),
      ],
    );
  }
}
