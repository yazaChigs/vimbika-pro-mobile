import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:vimbika_pro/model/supplier.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AddSupplierScreen extends StatefulWidget {
  final Supplier? supplier;

  const AddSupplierScreen({super.key, this.supplier});

  @override
  State<AddSupplierScreen> createState() => _AddSupplierScreenState();
}

class _AddSupplierScreenState extends State<AddSupplierScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _contactPersonController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.supplier?.name);
    _emailController = TextEditingController(text: widget.supplier?.email);
    _phoneController = TextEditingController(text: widget.supplier?.phoneNumber);
    _addressController = TextEditingController(text: widget.supplier?.address);
    _contactPersonController = TextEditingController(text: widget.supplier?.contactPerson);
  }

  Future<void> _saveSupplier() async {
    if (!_formKey.currentState!.validate()) return;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> suppliersJson = prefs.getStringList('suppliers') ?? [];
    
    final newSupplier = Supplier(
      id: widget.supplier?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      email: _emailController.text,
      phoneNumber: _phoneController.text,
      address: _addressController.text,
      contactPerson: _contactPersonController.text,
    );

    if (widget.supplier == null) {
      suppliersJson.add(jsonEncode(newSupplier.toJson()));
    } else {
      final index = suppliersJson.indexWhere((element) {
        final map = jsonDecode(element);
        return map['id'] == widget.supplier!.id;
      });
      if (index != -1) {
        suppliersJson[index] = jsonEncode(newSupplier.toJson());
      }
    }

    await prefs.setStringList('suppliers', suppliersJson);
    if (context.mounted) Navigator.pop(context, newSupplier);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.nearlyWhite,
      appBar: AppBar(
        title: Text(widget.supplier == null ? 'Add Supplier' : 'Edit Supplier', style: AppTheme.title),
        backgroundColor: AppTheme.white,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.nearlyBlack),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(_nameController, 'Supplier / Company Name', 'Enter company name', required: true),
              _buildTextField(_contactPersonController, 'Contact Person', 'Enter full name'),
              _buildTextField(_emailController, 'Email Address', 'example@mail.com', keyboardType: TextInputType.emailAddress),
              _buildTextField(_phoneController, 'Phone Number', '+263...', keyboardType: TextInputType.phone),
              _buildTextField(_addressController, 'Physical Address', 'Street, City', maxLines: 3),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveSupplier,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.vimbikaBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save Supplier', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
