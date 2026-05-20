import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:vimbika_pro/app_constants/app_constants.dart';
import 'package:vimbika_pro/model/company.dart';
import 'package:vimbika_pro/model/user.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CompanyProfileScreen extends StatefulWidget {
  const CompanyProfileScreen({super.key});

  @override
  State<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends State<CompanyProfileScreen> {
  Company? _company;
  bool _isLoading = true;
  bool _canEdit = true;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCompanyData();
  }

  Future<void> _loadCompanyData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool isOfflineMode = prefs.getBool(AppConstants.keyIsOfflineMode) ?? false;
    final String companyKey;
    if(isOfflineMode) {
      companyKey = AppConstants.keyOfflineCompanyData;
    }else{
      companyKey = AppConstants.keyCompanyData;
    }
    final String? companyJson = prefs.getString(companyKey);

    bool canEdit = true;
    if (!isOfflineMode) {
      final String? userDataJson = prefs.getString(AppConstants.keyOnlineUserData);
      if (userDataJson != null) {
        final user = User.fromJson(jsonDecode(userDataJson));
        canEdit = user.userRoles?.any((role) => role.name == 'ROLE_SUPER_ADMIN') ?? false;
      } else {
        canEdit = false;
      }
    }
    
    if (companyJson != null) {
      setState(() {
        _company = Company.fromJson(jsonDecode(companyJson));
        _nameController.text = _company?.name ?? '';
        _addressController.text = _company?.address ?? '';
        _phoneController.text = _company?.phoneNumber ?? '';
        _emailController.text = _company?.email ?? '';
        _websiteController.text = _company?.website ?? '';
        _isLoading = false;
        _canEdit = canEdit;
      });
    } else {
      setState(() {
        _isLoading = false;
        _canEdit = canEdit;
      });
    }
  }

  Future<void> _updateCompany() async {
    if (!_canEdit) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You do not have permission to edit company profile.')));
      return;
    }
    
    if (_nameController.text.isEmpty) return;

    final updatedCompany = Company(
      id: _company?.id,
      name: _nameController.text,
      address: _addressController.text,
      phoneNumber: _phoneController.text,
      email: _emailController.text,
      website: _websiteController.text,
    );

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool isOfflineMode = prefs.getBool(AppConstants.keyIsOfflineMode) ?? false;
    final String companyKey = isOfflineMode ? AppConstants.keyOfflineCompanyData : AppConstants.keyCompanyData;
    
    await prefs.setString(companyKey, jsonEncode(updatedCompany.toJson()));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Company profile updated')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.nearlyWhite,
      appBar: AppBar(
        title: const Text('Company Profile', style: AppTheme.title),
        backgroundColor: AppTheme.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.nearlyBlack),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildTextField(_nameController, 'Company Name', Icons.business, required: true),
                  _buildTextField(_addressController, 'Address', Icons.location_on),
                  _buildTextField(_phoneController, 'Phone', Icons.phone, keyboardType: TextInputType.phone),
                  _buildTextField(_emailController, 'Email', Icons.email, keyboardType: TextInputType.emailAddress),
                  _buildTextField(_websiteController, 'Website', Icons.language),
                  const SizedBox(height: 32),
                  if (_canEdit)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.vimbikaBlue),
                        onPressed: _updateCompany,
                        child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool required = false, TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: !_canEdit,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppTheme.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: _canEdit ? AppTheme.white : AppTheme.nearlyWhite,
        ),
      ),
    );
  }
}