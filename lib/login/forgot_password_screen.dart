import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vimbika_pro/app_constants/app_constants.dart';
import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:vimbika_pro/model/company.dart';
import 'package:vimbika_pro/model/user.dart';
import 'package:vimbika_pro/services/company_service.dart';
import 'login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _companyPhoneOrEmailController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _newPinController = TextEditingController();

  bool _isLoading = false;
  bool _isVerified = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  User? _matchedUser;
  Company? _offlineCompany;

  @override
  void initState() {
    super.initState();
    _loadCompanyData();
  }

  Future<void> _loadCompanyData() async {
    final company = await CompanyService().getCompany();
    setState(() {
      _offlineCompany = company;
    });
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _companyPhoneOrEmailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _newPinController.dispose();
    super.dispose();
  }

  Future<void> _verifyOfflineUserAndCompany() async {
    final String identifier = _identifierController.text.trim();
    final String securityDetail = _companyPhoneOrEmailController.text.trim().toLowerCase();

    if (identifier.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your Username')),
      );
      return;
    }

    if (securityDetail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Company/User Phone Number, Email, or Company Name for verification')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> allUsersJson = prefs.getStringList(AppConstants.keyAllUsers) ?? [];

      User? userToReset;
      for (String userStr in allUsersJson) {
        try {
          final userMap = jsonDecode(userStr);
          final user = User.fromJson(userMap);
          if (user.userName.toLowerCase() == identifier.toLowerCase()) {
            userToReset = user;
            break;
          }
        } catch (_) {}
      }

      if (userToReset == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No offline user found matching this username.')),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Verify against user phone/name or company info
      bool matches = false;
      final String? userPhone = userToReset.phoneNumber?.trim().toLowerCase();
      final String? compName = _offlineCompany?.name?.trim().toLowerCase();
      final String? compPhone = _offlineCompany?.phoneNumber?.trim().toLowerCase();
      final String? compEmail = _offlineCompany?.email?.trim().toLowerCase();

      if (userPhone != null && userPhone.isNotEmpty && (userPhone == securityDetail || securityDetail.contains(userPhone) || userPhone.contains(securityDetail))) {
        matches = true;
      } else if (compName != null && compName.isNotEmpty && compName == securityDetail) {
        matches = true;
      } else if (compPhone != null && compPhone.isNotEmpty && (compPhone == securityDetail || securityDetail.contains(compPhone) || compPhone.contains(securityDetail))) {
        matches = true;
      } else if (compEmail != null && compEmail.isNotEmpty && compEmail == securityDetail) {
        matches = true;
      }

      if (!matches) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Verification details do not match the offline company or user records.')),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _matchedUser = userToReset;
        _isVerified = true;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Identity verified successfully! Please enter your new password and PIN.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification error: $e')),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handlePasswordReset() async {
    final String newPassword = _newPasswordController.text;
    final String confirmPassword = _confirmPasswordController.text;
    final String newPin = _newPinController.text.trim();

    if (newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a new password')),
      );
      return;
    }

    if (newPassword.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 4 characters long')),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    if (newPin.isNotEmpty && newPin.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN must be 4 digits')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> allUsersJson = prefs.getStringList(AppConstants.keyAllUsers) ?? [];
      final List<String> updatedUsersJson = [];

      for (String userStr in allUsersJson) {
        try {
          final userMap = jsonDecode(userStr);
          final user = User.fromJson(userMap);
          if (user.userName.toLowerCase() == _matchedUser!.userName.toLowerCase()) {
            final updatedUser = user.copyWith(
              password: newPassword,
              pin: newPin.isNotEmpty ? newPin : (user.pin ?? newPassword),
            );
            updatedUsersJson.add(jsonEncode(updatedUser.toJson()));
          } else {
            updatedUsersJson.add(userStr);
          }
        } catch (_) {
          updatedUsersJson.add(userStr);
        }
      }

      await prefs.setStringList(AppConstants.keyAllUsers, updatedUsersJson);

      // Check if current offline user is this user
      final String? currentOfflineUserStr = prefs.getString(AppConstants.keyOfflineUserData);
      if (currentOfflineUserStr != null) {
        try {
          final currentOfflineUser = User.fromJson(jsonDecode(currentOfflineUserStr));
          if (currentOfflineUser.userName.toLowerCase() == _matchedUser!.userName.toLowerCase()) {
            final updatedCurrent = currentOfflineUser.copyWith(
              password: newPassword,
              pin: newPin.isNotEmpty ? newPin : (currentOfflineUser.pin ?? newPassword),
            );
            await prefs.setString(AppConstants.keyOfflineUserData, jsonEncode(updatedCurrent.toJson()));
          }
        } catch (_) {}
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset successfully! You can now log in.')),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => LoginScreen(
              initialUsername: _matchedUser!.userName,
              initialPassword: newPassword,
            ),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reset password: $e')),
        );
      }
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.darkText),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Reset Offline Password', style: AppTheme.headline),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (_offlineCompany != null) ...[
                Card(
                  elevation: 0,
                  color: AppTheme.vimbikaBlue.withAlpha(20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        const Icon(Icons.business, color: AppTheme.vimbikaBlue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _offlineCompany!.name ?? 'Offline Company',
                                style: AppTheme.title.copyWith(fontSize: 16),
                              ),
                              Text(
                                'Local Offline Mode',
                                style: AppTheme.caption.copyWith(color: AppTheme.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                !_isVerified
                    ? 'Verify company and account details to reset your local password.'
                    : 'Enter your new credentials below.',
                style: AppTheme.subtitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (!_isVerified) ...[
                _buildTextField(
                  controller: _identifierController,
                  hintText: 'Username',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _companyPhoneOrEmailController,
                  hintText: 'Registered Phone, Email, or Company Name',
                  icon: Icons.security,
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.vimbikaBlue,
                    foregroundColor: AppTheme.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _verifyOfflineUserAndCompany,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Verify Identity',
                          style: AppTheme.title.copyWith(color: AppTheme.white),
                        ),
                ),
              ] else ...[
                _buildTextField(
                  controller: _newPasswordController,
                  hintText: 'New Password',
                  icon: Icons.lock_outline,
                  isObscure: !_isPasswordVisible,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: AppTheme.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _confirmPasswordController,
                  hintText: 'Confirm New Password',
                  icon: Icons.lock_outline,
                  isObscure: !_isConfirmPasswordVisible,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: AppTheme.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _newPinController,
                  hintText: 'New 4-digit PIN (Optional)',
                  icon: Icons.pin_outlined,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.vimbikaBlue,
                    foregroundColor: AppTheme.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _handlePasswordReset,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Save New Password',
                          style: AppTheme.title.copyWith(color: AppTheme.white),
                        ),
                ),
              ],
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
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isObscure,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(icon, color: AppTheme.vimbikaBlue),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }
}
