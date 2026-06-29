import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vimbika_pro/customer/payment_receipt_screen.dart';
import 'package:vimbika_pro/model/payment_received.dart';
import '../app_constants/app_theme.dart';
import '../controllers/customer_controller.dart';
import '../model/currency.dart';
import '../model/customer.dart';
import '../model/payment_type.dart';
import '../model/bank.dart'; // Import the Bank model
import 'add_customer_screen.dart';
import 'customer_statement_screen.dart'; // Import the new controller
import '../custom_drawer/home_drawer.dart'; // Import DrawerIndex
import '../navigation_home_screen.dart'; // Import NavigationProvider

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showAddBalanceDialog(BuildContext screenContext, Customer customer, {bool isDeposit = false}) async {
    final controller = Provider.of<CustomerController>(screenContext, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(screenContext);
    final navigator = Navigator.of(screenContext);

    if (controller.currencies.isEmpty || controller.paymentTypes.isEmpty) {
      if (mounted) { // Add mounted check here as well
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Currencies or Payment Types not loaded')),
        );
      }
      return;
    }

    Currency? selectedCurrency = controller.currencies.first;
    List<PaymentType> validPaymentTypes = controller.paymentTypes.where((pt) => !pt.isCredit && (pt.currency == null || pt.currency?.id == selectedCurrency?.id)).toList();
    
    if (validPaymentTypes.isEmpty) {
      if (mounted) { // Add mounted check here as well
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('No valid non-credit payment types found for the selected currency')),
        );
      }
      return;
    }

    PaymentType? selectedPaymentType = validPaymentTypes.first;
    Bank? selectedBank = selectedPaymentType?.banks?.isNotEmpty == true ? selectedPaymentType!.banks!.first : null; // Initialize selectedBank as Bank?
    final TextEditingController amountController = TextEditingController();
    bool isSavingBalance = false;

    await showDialog(
      context: screenContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isDeposit ? 'Add Deposit for ${customer.name}' : 'Add Balance for ${customer.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<Currency>(
                initialValue: selectedCurrency,
                decoration: const InputDecoration(labelText: 'Currency'),
                items: controller.currencies.map((c) => DropdownMenuItem(value: c, child: Text(c.name!))).toList(),
                onChanged: (val) {
                  setDialogState(() {
                    selectedCurrency = val;
                    validPaymentTypes = controller.paymentTypes.where((pt) => !pt.isCredit && (pt.currency == null || pt.currency?.id == selectedCurrency?.id)).toList();
                    selectedPaymentType = validPaymentTypes.isNotEmpty ? validPaymentTypes.first : null;
                    selectedBank = selectedPaymentType?.banks?.isNotEmpty == true ? selectedPaymentType!.banks!.first : null; // Reset selectedBank
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<PaymentType>(
                initialValue: selectedPaymentType,
                decoration: const InputDecoration(labelText: 'Payment Type'),
                items: validPaymentTypes.map((pt) => DropdownMenuItem(value: pt, child: Text(pt.name))).toList(),
                onChanged: (val) {
                  setDialogState(() {
                    selectedPaymentType = val;
                    selectedBank = selectedPaymentType?.banks?.isNotEmpty == true ? selectedPaymentType!.banks!.first : null; // Reset selectedBank
                  });
                },
              ),
              if (selectedPaymentType?.banks?.isNotEmpty == true) // Conditionally display bank selection
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: DropdownButtonFormField<Bank>( // Change type to Bank
                    value: selectedBank,
                    decoration: const InputDecoration(labelText: 'Bank'),
                    items: selectedPaymentType!.banks!.map((bank) => DropdownMenuItem(value: bank, child: Text(bank.name))).toList(), // Use bank.name for display
                    onChanged: (val) {
                      setDialogState(() {
                        selectedBank = val;
                        print(selectedBank!.toJson());
                      });
                    },
                  ),
                ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSavingBalance ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSavingBalance
                  ? null
                  : () async {
                      final amount = double.tryParse(amountController.text) ?? 0.0;
                      if (amount <= 0 || selectedCurrency == null || selectedPaymentType == null) {
                        return; 
                      }
                      // If payment type requires a bank but none is selected
                      if (selectedPaymentType!.banks?.isNotEmpty == true && selectedBank == null) {
                        if (mounted) {
                          scaffoldMessenger.showSnackBar(
                            const SnackBar(content: Text('Please select a bank'), backgroundColor: Colors.red),
                          );
                        }
                        return;
                      }

                      setDialogState(() {
                        isSavingBalance = true;
                      });

                      final PaymentReceived? payment = await controller.addBalance(customer, selectedCurrency!, selectedPaymentType!, amount, selectedBank: selectedBank, isDeposit: isDeposit);

                      if (mounted) {
                        if (payment != null) {
                          scaffoldMessenger.showSnackBar(
                            SnackBar(content: Text(isDeposit ? 'Deposit added successfully' : 'Balance added successfully'), backgroundColor: Colors.green),
                          );
                          Navigator.pop(dialogContext); // Close the dialog
                          navigator.push(
                            MaterialPageRoute(
                              builder: (context) => PaymentReceiptScreen(payment: payment),
                            ),
                          );
                        } else {
                          scaffoldMessenger.showSnackBar(
                            const SnackBar(content: Text('Failed to add balance'), backgroundColor: Colors.red),
                          );
                        }
                      }
                      if (mounted) {
                        setDialogState(() {
                          isSavingBalance = false;
                        });
                      }
                    },
              child: isSavingBalance
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context, CustomerController controller, Customer customer) {
    return Card(
      margin: EdgeInsets.zero, // Let the parent Grid/List handle spacing
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () async {
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CustomerStatementScreen(customer: customer)),
          );
          // After returning from statement screen, refresh data
          final message = await controller.syncCustomers();
          if (mounted && message != null) {
            scaffoldMessenger.showSnackBar(
              SnackBar(content: Text(message)),
            );
          }
        },
        leading: CircleAvatar(
          backgroundColor: AppTheme.vimbikaBlue.withAlpha(26),
          child: const Icon(Icons.person_outline, color: AppTheme.vimbikaBlue),
        ),
        title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (customer.email != null && customer.email!.isNotEmpty)
              Text(customer.email!),
            if (customer.phoneNumber != null && customer.phoneNumber!.isNotEmpty)
              Text(customer.phoneNumber!),
            // Display currency balances
            if (customer.currencyBalance != null && customer.currencyBalance!.isNotEmpty)
              Wrap(
                spacing: 8.0, // gap between adjacent chips
                runSpacing: 4.0, // gap between lines
                children: customer.currencyBalance!.map((cca) {
                  return Chip(
                    label: Text(
                      '${cca.currency?.symbol ?? ''} ${cca.balance?.toStringAsFixed(2) ?? '0.00'}',
                      style: const TextStyle(fontSize: 10),
                    ),
                    backgroundColor: AppTheme.lightText.withAlpha(26),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            if (!customer.isSynced) // Indicate unsynced status
              const Padding(
                padding: EdgeInsets.only(top: 4.0),
                child: Text(
                  'Unsynced (offline)',
                  style: TextStyle(fontSize: 12, color: Colors.orange, fontStyle: FontStyle.italic),
                ),
              ),
            if ((customer.currencyBalance == null || customer.currencyBalance!.isEmpty) && customer.isSynced)
              const Padding(
                padding: EdgeInsets.only(top: 4.0),
                child: Text(
                  'No balance records',
                  style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.add_card, color: AppTheme.vimbikaBlue),
              tooltip: 'Add Balance',
              onPressed: () => _showAddBalanceDialog(context, customer, isDeposit: false),
            ),
            // IconButton(
            //   icon: const Icon(Icons.savings_outlined, color: Colors.green),
            //   tooltip: 'Add Deposit',
            //   onPressed: () => _showAddBalanceDialog(context, customer, isDeposit: true),
            // ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppTheme.grey),
              onPressed: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddCustomerScreen(customer: customer)),
                );
                if (result != null) {
                  final message = await controller.syncCustomers();
                  if (mounted && message != null) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text(message)),
                    );
                  }
                }
              },
            ),
            const Icon(Icons.chevron_right, color: AppTheme.grey),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CustomerController(),
      child: Consumer<CustomerController>(
        builder: (context, controller, child) {
          return Scaffold(
            backgroundColor: AppTheme.nearlyWhite,
            appBar: AppBar(
              title: const Text('Manage Customers', style: AppTheme.title),
              backgroundColor: AppTheme.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: AppTheme.nearlyBlack),
              actions: [
                IconButton(
                  icon: const Icon(Icons.sync),
                  onPressed: controller.isLoading
                      ? null
                      : () async {
                          final scaffoldMessenger = ScaffoldMessenger.of(context);
                          final message = await controller.syncCustomers();
                          if (mounted && message != null) {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(content: Text(message)),
                            );
                          }
                        },
                  tooltip: 'Sync Customers',
                ),
              ],
            ),
            body: controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            controller.setSearchQuery(val);
                          },
                          decoration: InputDecoration(
                            hintText: 'Search customers...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: AppTheme.white,
                          ),
                        ),
                      ),
                      Expanded(
                        child: controller.filteredCustomers.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.people_outline, size: 64, color: AppTheme.grey.withAlpha(128)),
                                    const SizedBox(height: 16),
                                    Text(
                                      controller.searchQuery.isEmpty
                                          ? 'No customers added yet.'
                                          : 'No customers found for "${controller.searchQuery}"',
                                      style: const TextStyle(color: AppTheme.grey, fontSize: 18),
                                      textAlign: TextAlign.center,
                                    ),
                                    if (controller.searchQuery.isEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text('Tap + to add your first customer', style: TextStyle(color: AppTheme.grey.withAlpha(179))),
                                    ],
                                  ],
                                ),
                              )
                            : LayoutBuilder(
                                builder: (context, constraints) {
                                  final isWideScreen = constraints.maxWidth > 600;
                                  
                                  if (isWideScreen) {
                                    int crossAxisCount = constraints.maxWidth > 1200 ? 3 : 2;
                                    return GridView.builder(
                                      padding: const EdgeInsets.all(16),
                                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: crossAxisCount,
                                        crossAxisSpacing: 16,
                                        mainAxisSpacing: 16,
                                        childAspectRatio: 2.5, // Adjust this ratio based on your content
                                      ),
                                      itemCount: controller.filteredCustomers.length,
                                      itemBuilder: (context, index) {
                                        final customer = controller.filteredCustomers[index];
                                        return _buildCustomerCard(context, controller, customer);
                                      },
                                    );
                                  } else {
                                    return ListView.builder(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      itemCount: controller.filteredCustomers.length,
                                      itemBuilder: (context, index) {
                                        final customer = controller.filteredCustomers[index];
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 12.0),
                                          child: _buildCustomerCard(context, controller, customer),
                                        );
                                      },
                                    );
                                  }
                                },
                              ),
                      ),
                    ],
                  ),
            floatingActionButton: FloatingActionButton(
              onPressed: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddCustomerScreen()),
                );
                if (mounted && result != null) { // Add mounted check
                  final message = await controller.syncCustomers();
                  if (mounted && message != null) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text(message)),
                    );
                  }
                }
              },
              backgroundColor: AppTheme.vimbikaBlue,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          );
        },
      ),
    );
  }
}
