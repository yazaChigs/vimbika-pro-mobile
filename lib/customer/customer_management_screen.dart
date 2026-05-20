import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_constants/app_theme.dart';
import '../controllers/customer_controller.dart';
import '../model/currency.dart';
import '../model/customer.dart';
import '../model/payment_type.dart';
import '../model/bank.dart'; // Import the Bank model
import 'add_customer_screen.dart';
import 'customer_statement_screen.dart'; // Import the new controller

class CustomerManagementScreen extends StatefulWidget {
  const CustomerManagementScreen({super.key});

  @override
  State<CustomerManagementScreen> createState() => _CustomerManagementScreenState();
}

class _CustomerManagementScreenState extends State<CustomerManagementScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    Provider.of<CustomerController>(context, listen: false).setSearchQuery(_searchController.text);
  }

  Future<void> _showAddBalanceDialog(BuildContext screenContext, Customer customer) async {
    final controller = Provider.of<CustomerController>(screenContext, listen: false);

    if (controller.currencies.isEmpty || controller.paymentTypes.isEmpty) {
      if (mounted) { // Add mounted check here as well
        ScaffoldMessenger.of(this.context).showSnackBar(
          const SnackBar(content: Text('Currencies or Payment Types not loaded')),
        );
      }
      return;
    }

    Currency? selectedCurrency = controller.currencies.first;
    List<PaymentType> validPaymentTypes = controller.paymentTypes.where((pt) => !pt.isCredit && (pt.currency == null || pt.currency?.id == selectedCurrency?.id)).toList();
    
    if (validPaymentTypes.isEmpty) {
      if (mounted) { // Add mounted check here as well
        ScaffoldMessenger.of(this.context).showSnackBar(
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
          title: Text('Add Balance for ${customer.name}'),
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
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(content: Text('Please select a bank'), backgroundColor: Colors.red),
                          );
                        }
                        return;
                      }

                      setDialogState(() {
                        isSavingBalance = true;
                      });

                      final message = await controller.addBalance(customer, selectedCurrency!, selectedPaymentType!, amount, selectedBank: selectedBank);

                      if (mounted) {
                        if (message == null) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(content: Text('Balance added successfully'), backgroundColor: Colors.green),
                          );
                          Navigator.pop(dialogContext);
                        } else {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(content: Text(message), backgroundColor: Colors.red),
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
                          final message = await controller.syncCustomers();
                          if (mounted && message != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
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
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: controller.filteredCustomers.length,
                                itemBuilder: (context, index) {
                                  final customer = controller.filteredCustomers[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    child: ListTile(
                                      onTap: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => CustomerStatementScreen(customer: customer)),
                                        );
                                        // After returning from statement screen, refresh data
                                        final message = await controller.syncCustomers();
                                        if (mounted && message != null) {
                                          ScaffoldMessenger.of(context).showSnackBar(
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
                                            onPressed: () => _showAddBalanceDialog(context, customer),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, color: AppTheme.grey),
                                            onPressed: () async {
                                              final result = await Navigator.push(
                                                context,
                                                MaterialPageRoute(builder: (context) => AddCustomerScreen(customer: customer)),
                                              );
                                              if (result != null) {
                                                final message = await controller.syncCustomers();
                                                if (mounted && message != null) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
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
                                },
                              ),
                      ),
                    ],
                  ),
            floatingActionButton: FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddCustomerScreen()),
                );
                if (mounted && result != null) { // Add mounted check here
                  final message = await controller.syncCustomers();
                  if (mounted && message != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
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
