import 'package:vimbika_pro/app_constants/app_constants.dart';
import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:vimbika_pro/model/expense.dart';
import 'package:vimbika_pro/model/expense_category.dart';
import 'package:vimbika_pro/model/payment_type.dart';
import 'package:vimbika_pro/model/payment_paid.dart';
import 'package:vimbika_pro/model/supplier.dart';
import 'package:vimbika_pro/screens/offline/settings/expense_category_management_screen.dart';
import 'package:vimbika_pro/supplier/add_supplier_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? expense;

  const AddExpenseScreen({super.key, this.expense});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _amountController;
  late TextEditingController _notesController;
  late TextEditingController _referenceController;
  DateTime _expenseDate = DateTime.now();
  
  ExpenseCategory? _selectedCategory;
  Supplier? _selectedSupplier;
  
  List<ExpenseCategory> _categories = [];
  List<PaymentType> _paymentTypes = [];
  List<Supplier> _suppliers = [];
  final List<PaymentPaid> _payments = [];
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.expense?.amount.toString() ?? '');
    _notesController = TextEditingController(text: widget.expense?.notes ?? '');
    _referenceController = TextEditingController(text: widget.expense?.reference ?? '');
    if (widget.expense != null) {
      _expenseDate = widget.expense!.expenseDate;
      if (widget.expense!.payments != null) {
        _payments.addAll(widget.expense!.payments!);
      }
    }
    
    _loadData();
  }

  Future<void> _loadData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    
    final List<String> catJson = prefs.getStringList(AppConstants.keyExpenseCategories) ?? [];
    final List<String> payJson = prefs.getStringList(AppConstants.keyOfflinePaymentTypes) ?? [];
    final List<String> supplierJson = prefs.getStringList(AppConstants.keySuppliers) ?? [];
    
    setState(() {
      _categories = catJson.map((e) => ExpenseCategory.fromJson(jsonDecode(e))).toList();
      _paymentTypes = payJson.map((e) => PaymentType.fromJson(jsonDecode(e))).toList();
      _suppliers = supplierJson.map((e) => Supplier.fromJson(jsonDecode(e))).toList();
      
      if (widget.expense != null) {
        if (widget.expense!.expenseCategory != null) {
          _selectedCategory = _categories.firstWhere((e) => e.id == widget.expense!.expenseCategory!.id, orElse: () => widget.expense!.expenseCategory!);
        }
        if (widget.expense!.supplier != null) {
          _selectedSupplier = _suppliers.firstWhere((e) => e.id == widget.expense!.supplier!.id, orElse: () => widget.expense!.supplier!);
        }
      }
      
      _isLoading = false;
    });
  }

  double get _totalAmount => double.tryParse(_amountController.text) ?? 0.0;
  double get _amountPaid => _payments.fold(0, (sum, item) => sum + item.amount);
  double get _balanceDue => _totalAmount - _amountPaid;

  void _addPayment() {
    if (_totalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter an expense amount first.')));
      return;
    }
    if (_balanceDue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expense is already fully paid.')));
      return;
    }

    PaymentType? selectedType;
    final amountController = TextEditingController(text: _balanceDue.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<PaymentType>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Payment Method'),
                items: _paymentTypes.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
                onChanged: (val) => setDialogState(() => selectedType = val),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                onTap: () {
                  amountController.selection = TextSelection(baseOffset: 0, extentOffset: amountController.text.length);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (selectedType == null) return;
                final amount = double.tryParse(amountController.text) ?? 0.0;
                if (amount <= 0) return;

                setState(() {
                  _payments.add(PaymentPaid(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    paymentType: selectedType,
                    amount: amount,
                    paymentDate: DateTime.now(),
                  ));
                });
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an expense category')));
      return;
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> expensesJson = prefs.getStringList('expenses') ?? [];
    
    final newExpense = Expense(
      id: widget.expense?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      expenseCategory: _selectedCategory,
      supplier: _selectedSupplier,
      amount: _totalAmount,
      expenseDate: _expenseDate,
      reference: _referenceController.text,
      notes: _notesController.text,
      payments: _payments,
    );

    if (widget.expense == null) {
      expensesJson.add(jsonEncode(newExpense.toJson()));
    } else {
      final index = expensesJson.indexWhere((e) {
        final map = jsonDecode(e);
        return map['id'] == widget.expense!.id;
      });
      if (index != -1) {
        expensesJson[index] = jsonEncode(newExpense.toJson());
      }
    }

    await prefs.setStringList('expenses', expensesJson);
    if (context.mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.nearlyWhite,
      appBar: AppBar(
        title: Text(widget.expense == null ? 'Record Expense' : 'Edit Expense', style: AppTheme.title),
        backgroundColor: AppTheme.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.nearlyBlack),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCategorySelector(),
                        _buildSupplierSelector(),
                        _buildTextField(_amountController, 'Total Expense Amount', '0.0', keyboardType: TextInputType.number, required: true, onChanged: (val) => setState(() {})),
                        _buildDatePicker(),
                        _buildTextField(_referenceController, 'Reference', 'e.g. Receipt #, Invoice #'),
                        _buildTextField(_notesController, 'Notes', 'Describe the expense', maxLines: 3),
                        const SizedBox(height: 24),
                        const Text('Payments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        _buildPaymentList(),
                        const SizedBox(height: 16),
                        _buildAddPaymentButton(),
                      ],
                    ),
                  ),
                ),
              ),
              _buildSummary(),
            ],
          ),
    );
  }

  Widget _buildCategorySelector() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<ExpenseCategory>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Expense Category',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: AppTheme.white,
              ),
              items: _categories.map((cat) => DropdownMenuItem(
                value: cat,
                child: Text(cat.name),
              )).toList(),
              onChanged: (val) => setState(() => _selectedCategory = val),
              validator: (value) => value == null ? 'Category is required' : null,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: AppTheme.vimbikaBlue.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.add, color: AppTheme.vimbikaBlue),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ExpenseCategoryManagementScreen()),
                );
                if (result == true) {
                  _loadData();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierSelector() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<Supplier>(
              value: _selectedSupplier,
              decoration: InputDecoration(
                labelText: 'Paid To (Supplier)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: AppTheme.white,
              ),
              items: _suppliers.map((s) => DropdownMenuItem(
                value: s,
                child: Text(s.name),
              )).toList(),
              onChanged: (val) => setState(() => _selectedSupplier = val),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: AppTheme.vimbikaBlue.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.add, color: AppTheme.vimbikaBlue),
              onPressed: () async {
                final newSupplier = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddSupplierScreen()),
                );
                if (newSupplier != null && newSupplier is Supplier) {
                  await _loadData();
                  setState(() {
                    _selectedSupplier = newSupplier;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, {bool required = false, TextInputType keyboardType = TextInputType.text, int maxLines = 1, ValueChanged<String>? onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: AppTheme.white,
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

  Widget _buildPaymentList() {
    if (_payments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: Text('No payments added')),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _payments.length,
      itemBuilder: (context, index) {
        final payment = _payments[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(payment.paymentType?.name ?? 'Unknown Method'),
            subtitle: Text(DateFormat('yyyy-MM-dd HH:mm').format(payment.paymentDate ?? DateTime.now())),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('\$${payment.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    final editController = TextEditingController(text: payment.amount.toStringAsFixed(2));
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Edit Payment Amount'),
                        content: TextField(
                          controller: editController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          autofocus: true,
                          decoration: const InputDecoration(border: OutlineInputBorder()),
                          onTap: () => editController.selection = TextSelection(baseOffset: 0, extentOffset: editController.text.length),
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                          ElevatedButton(
                            onPressed: () {
                              final newAmt = double.tryParse(editController.text);
                              if (newAmt != null && newAmt > 0) {
                                setState(() {
                                  _payments[index] = payment.copyWith(amount: newAmt);
                                });
                              } else if (newAmt == 0) {
                                setState(() {
                                  _payments.removeAt(index);
                                });
                              }
                              Navigator.pop(context);
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
                  onTap: () => setState(() => _payments.removeAt(index)),
                  child: const Icon(Icons.close, size: 16, color: Colors.red),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddPaymentButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _addPayment,
        icon: const Icon(Icons.payment),
        label: const Text('Add Payment Entry'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: _expenseDate,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (date != null) setState(() => _expenseDate = date);
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Expense Date',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: AppTheme.white,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(DateFormat('yyyy-MM-dd').format(_expenseDate)),
              const Icon(Icons.calendar_today, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Amount Paid:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
              Text('\$${_amountPaid.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Balance Due:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
              Text('\$${_balanceDue.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saveExpense,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.vimbikaBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Record Expense', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
