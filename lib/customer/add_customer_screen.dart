import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:vimbika_pro/model/customer.dart';
import 'package:vimbika_pro/services/customer_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:vimbika_pro/app_constants/app_constants.dart';
import 'package:vimbika_pro/model/company.dart';
import 'package:vimbika_pro/model/branch.dart';
import 'package:vimbika_pro/model/user.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';

class AddCustomerScreen extends StatefulWidget {
  final Customer? customer;

  const AddCustomerScreen({super.key, this.customer});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final CustomerService _customerService = CustomerService();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _accountNumberController;
  late TextEditingController _taxNumberController;
  late TextEditingController _tinNumberController;

  bool _isSaving = false;
  bool _isTaxEnabled = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer?.name);
    _emailController = TextEditingController(text: widget.customer?.email);
    _phoneController = TextEditingController(text: widget.customer?.mobilePhone);
    _addressController = TextEditingController(text: widget.customer?.address);
    _accountNumberController = TextEditingController(text: widget.customer?.accountNumber);
    _taxNumberController = TextEditingController(text: widget.customer?.taxNumber);
    _tinNumberController = TextEditingController(text: widget.customer?.tinNumber);
    _loadTaxConfig();
  }

  Future<void> _loadTaxConfig() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isTaxEnabled = prefs.getBool(AppConstants.keyIsPriceInclusiveTax) ?? true;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _accountNumberController.dispose();
    _taxNumberController.dispose();
    _tinNumberController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final bool isOfflineMode = prefs.getBool(AppConstants.keyIsOfflineMode) ?? false;

      // Check for duplicate name and account number locally
      List<Customer> allCustomers = await _customerService.getCustomersLocally();
      
      bool hasDuplicateName = allCustomers.any((c) => 
        c.name.toLowerCase().trim() == _nameController.text.toLowerCase().trim() && 
        c.id != widget.customer?.id
      );
      
      bool hasDuplicateAccount = _accountNumberController.text.trim().isNotEmpty && allCustomers.any((c) => 
        c.accountNumber?.trim() == _accountNumberController.text.trim() && 
        c.id != widget.customer?.id
      );

      if (hasDuplicateName) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A customer with this name already exists.'), backgroundColor: Colors.red));
           setState(() => _isSaving = false);
        }
        return;
      }

      if (hasDuplicateAccount) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A customer with this account number already exists.'), backgroundColor: Colors.red));
           setState(() => _isSaving = false);
        }
        return;
      }

      // Get the company from logged in user if possible
      Company? currentCompany = widget.customer?.company.value;
      Branch? currentBranch = widget.customer?.branch.value;

      if (currentCompany == null || currentBranch == null) {
        final String? userData = prefs.getString(isOfflineMode ? AppConstants.keyOfflineUserData : AppConstants.keyOnlineUserData);
        if (userData != null) {
            final user = User.fromJson(jsonDecode(userData));
            currentCompany ??= user.branch?.company.value;
            currentBranch ??= user.branch;
        }
      }

      if (currentCompany == null) {
        final String? companyData = prefs.getString(isOfflineMode ? AppConstants.keyOfflineCompanyData : AppConstants.keyOnlineCompanyData);
        if (companyData != null) {
          currentCompany = Company.fromJson(jsonDecode(companyData));
        }
      }

      Customer customerToSave = Customer(
        id: widget.customer?.id ?? const Uuid().v4(), // Use existing ID or generate one
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        mobilePhone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        accountNumber: _accountNumberController.text.trim(),
        taxNumber: _taxNumberController.text.trim(),
        tinNumber: _tinNumberController.text.trim(),
        dateCreated: widget.customer?.dateCreated,
        dateModified: widget.customer?.dateModified,
        createdByName: widget.customer?.createdByName,
        modifiedByName: widget.customer?.modifiedByName,
        version: widget.customer?.version,
        isSynced: false, // Initially false, will be updated after successful API sync
      );
      customerToSave.company.value = currentCompany;
      customerToSave.branch.value = currentBranch;
      if (widget.customer != null) {
        customerToSave.currencyBalance.addAll(widget.customer!.currencyBalance);
      }


      // 1. Save locally first
      await _customerService.saveCustomerLocally(customerToSave);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer saved locally.'), backgroundColor: Colors.green),
        );
      }

      // 2. Attempt to save to API in the background (after popping the screen)
      // We don't await this call, allowing the function to complete and the screen to pop.
      _syncCustomerToApi(customerToSave);
      
      if (mounted) {
        Navigator.pop(context, customerToSave); // Return the saved customer object
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: $e'), backgroundColor: Colors.red),
        );
        debugPrint('An unexpected error occurred: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // New function to handle API sync in the background
  Future<void> _syncCustomerToApi(Customer customer) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final connectivityResult = await (Connectivity().checkConnectivity());
    bool isConnected = connectivityResult.any((result) => result != ConnectivityResult.none);
    final bool isOfflineMode = prefs.getBool(AppConstants.keyIsOfflineMode) ?? false;

    if (isConnected && !isOfflineMode) {
      try {
        final savedCustomer = await _customerService.saveCustomer(customer);
        // Update local storage with the API-saved customer, marking as synced
         _customerService.saveCustomerLocally(savedCustomer.copyWith(isSynced: true));
        debugPrint('Customer synced to API successfully: ${savedCustomer.id}');
      } catch (e) {
        debugPrint('Failed to sync customer ${customer.id} to API: $e');
        // Customer remains unsynced locally. A separate retry mechanism will handle this.
      }
    } else {
      debugPrint('Not connected or in offline mode. Customer ${customer.id} remains unsynced.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.nearlyWhite,
      appBar: AppBar(
        title: Text(widget.customer == null ? 'Add Customer' : 'Edit Customer', style: AppTheme.title),
        backgroundColor: AppTheme.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.nearlyBlack),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(_nameController, 'Customer Name', 'Enter full name', required: true),
              _buildTextField(_accountNumberController, 'Account Number', 'Enter account number'),
              if (_isTaxEnabled) ...[
                _buildTextField(_taxNumberController, 'Tax Number', 'Enter tax number'),
                _buildTextField(_tinNumberController, 'TIN Number', 'Enter TIN number'),
              ],
              _buildTextField(_emailController, 'Email Address', 'example@mail.com', keyboardType: TextInputType.emailAddress),
              _buildTextField(_phoneController, 'Phone Number', '+263...', keyboardType: TextInputType.phone),
              _buildTextField(_addressController, 'Physical Address', 'Street, City', maxLines: 3),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveCustomer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.vimbikaBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save Customer', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, {bool required = false, TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: AppTheme.white,
        ),
        validator: required ? (value) => value == null || value.isEmpty ? 'This field is required' : null : null,
      ),
    );
  }
}
