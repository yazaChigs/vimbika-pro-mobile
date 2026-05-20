import 'package:vimbika_pro/services/company_service.dart';
import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'app_constants/app_constants.dart';
import 'signup_screen.dart';
import 'model/company.dart';
import 'model/branch.dart';

class CreateCompanyScreen extends StatefulWidget {
  @override
  _CreateCompanyScreenState createState() => _CreateCompanyScreenState();
}

class _CreateCompanyScreenState extends State<CreateCompanyScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _branchNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();

  bool _isLoading = false;

  Future<void> _handleCreateCompany() async {
    if (_nameController.text.isEmpty || _branchNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Company and Branch names are required')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create Company object
      final company = Company(
        name: _nameController.text,
        address: _addressController.text.isNotEmpty ? _addressController.text : null,
        phoneNumber: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        email: _emailController.text.isNotEmpty ? _emailController.text : null,
        website: _websiteController.text.isNotEmpty ? _websiteController.text : null,
      );

      // Create Default Branch object using company's contact info
      final defaultBranch = Branch(
        name: _branchNameController.text,
        company: company,
        address: company.address,
        phoneNumber: company.phoneNumber,
        email: company.email,
      );

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Save Company and Default Branch data
      await CompanyService().saveOfflineCompany(company);
      await prefs.setString(AppConstants.keyOfflineBranch, jsonEncode(defaultBranch.toJson()));

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SignupScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create company: $e')),
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.nearlyWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Register Company', style: AppTheme.headline),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'First, let\'s set up your company details',
                style: AppTheme.subtitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildTextField(
                controller: _nameController,
                hintText: 'Company Name *',
                icon: Icons.business_outlined,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _branchNameController,
                hintText: 'Initial Branch Name (e.g. Head Office) *',
                icon: Icons.store_outlined,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _addressController,
                hintText: 'Address',
                icon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneController,
                hintText: 'Phone Number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emailController,
                hintText: 'Company Email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _websiteController,
                hintText: 'Website',
                icon: Icons.language_outlined,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.vimbikaBlue,
                  foregroundColor: AppTheme.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _isLoading ? null : _handleCreateCompany,
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: AppTheme.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Next: Create Admin Account',
                        style: AppTheme.title.copyWith(color: AppTheme.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isObscure = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isObscure,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(icon, color: AppTheme.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }
}
