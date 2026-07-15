import 'package:intl/intl.dart';
import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:vimbika_pro/model/user_role.dart';
import 'dart:convert';
import 'app_constants/app_constants.dart';
import 'login/login_screen.dart';
import 'model/user.dart';
import 'model/branch.dart';
import 'model/currency.dart';
import 'model/tax.dart';
import 'model/category.dart';
import 'model/payment_type.dart';
import 'model/bank.dart';
import 'model/unit.dart';
import 'model/expense_category.dart';
import 'model/mobile_pos_shift.dart';
import 'model/subscription.dart';
import 'model/inventory_item.dart';
import 'model/supplier.dart';
import 'model/company.dart';
import 'services/company_service.dart';
import 'quick_start_screen.dart'; // Import the new quick start screen

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _showOptionalFields = false; // New state variable
  final Uuid _uuid = const Uuid(); // Initialize Uuid

  Future<void> _handleSignup() async {
    if (_usernameController.text.isEmpty || _pinController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username and PIN are required')),
        );
      }
      return;
    }

    if (_usernameController.text.length < 4) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username must be at least 4 characters')),
        );
      }
      return;
    }

    if (_pinController.text.length != 4) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN must be 4 digits')),
        );
      }
      return;
    }

    // Make password required
    if (_passwordController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password is required')),
        );
      }
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match')),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      
      final List<String> allUsersJson = prefs.getStringList(AppConstants.keyAllUsers) ?? [];

      Branch? defaultBranch;
      final String? branchJson = prefs.getString(AppConstants.keyOfflineBranch);
      if (branchJson != null) {
        defaultBranch = Branch.fromJson(jsonDecode(branchJson));
      }

      bool isFirstUser = allUsersJson.isEmpty;
      String? finalRole;
      if (isFirstUser) {
        finalRole = 'ROLE_SUPER_ADMIN';
      }
      final userRole = UserRole(name: 'ROLE_SUPER_ADMIN');

      final newUser = User(
        // id: _uuid.v4(), // Assign a unique ID
        userName: _usernameController.text.trim(),
        firstName: _firstNameController.text.isNotEmpty ? _firstNameController.text : null,
        lastName: _lastNameController.text.isNotEmpty ? _lastNameController.text : null,
        phoneNumber: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        role: finalRole,
        branch: defaultBranch,
        isActive: true,
        pin: _pinController.text,
        password: _passwordController.text,
        userRoles: [userRole]
      );

      await prefs.setString(AppConstants.keyOfflineUserData, jsonEncode(newUser.toJson()));
      await prefs.setBool(AppConstants.keyHasUser, true);

      allUsersJson.add(jsonEncode(newUser.toJson()));
      await prefs.setStringList(AppConstants.keyAllUsers, allUsersJson);

      if (isFirstUser) {
        await _initializeDefaultBusinessData(prefs);
        await _createInitialShift(prefs, newUser);
      }

      if (mounted) {
        final String savedUsername = _usernameController.text;
        final String savedPassword = _passwordController.text.isNotEmpty 
            ? _passwordController.text 
            : _pinController.text;
        
        if (isFirstUser) {
          // If this is the first user, take them to the quick start setup
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => QuickStartScreen(
                savedUsername: savedUsername,
                savedPassword: savedPassword,
              ),
            ),
          );
        } else {
          // Otherwise, just go straight to login
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => LoginScreen(
                initialUsername: savedUsername,
                initialPassword: savedPassword,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signup failed: $e')),
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

  Future<void> _createInitialShift(SharedPreferences prefs, User user) async {
    final shift = MobilePosShift(
      id: _uuid.v4(),
      userId: user.id,
      userFullName: '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim(),
      createdByName: user.userName,
      dateCreated: DateTime.now().toIso8601String(),
      openingTime: DateTime.now().toIso8601String(),
      active: true,
      isShiftClosed: false,
      synced: false,
      stopSync: false,
      kotNumber: 0,
      shiftReference: 'SF${DateTime.now().millisecondsSinceEpoch}',
      shiftCurrencyAmounts: [],
    );

    // Set as current open shift
    await prefs.setString(AppConstants.keyCurrentOpenShift, jsonEncode(shift.toJson()));

    // Also add to the offline mobile shifts history
    final List<String> shiftsJson = prefs.getStringList(AppConstants.keyOfflineMobileShifts) ?? [];
    shiftsJson.add(jsonEncode(shift.toJson()));
    await prefs.setStringList(AppConstants.keyOfflineMobileShifts, shiftsJson);
  }

  Future<void> _initializeDefaultBusinessData(SharedPreferences prefs) async {
    final List<Currency> defaultCurrencies = [
      Currency(
        id: _uuid.v4(), // Assign a unique ID
        name: 'USD',
        symbol: '\$',
        rate: 1.0,
        isBaseCurrency: true,
        isSystemCreated: true
      ),
      Currency(
        id: _uuid.v4(), // Assign a unique ID
        name: 'ZWG',
        symbol: 'ZiG',
        rate: 25.0,
        isBaseCurrency: false,
        isSystemCreated: true
      ),
    ];

    if (!prefs.containsKey(AppConstants.keyOfflineCurrencies)) {
      await prefs.setStringList(
        AppConstants.keyOfflineCurrencies,
        defaultCurrencies.map((c) => jsonEncode(c.toJson())).toList()
      );
    }

    if (!prefs.containsKey(AppConstants.keyOfflineBanks) || !prefs.containsKey(AppConstants.keyOfflinePaymentTypes)) {
      List<Bank> defaultBanks = [];
      List<PaymentType> defaultPaymentTypes = [];

      for (var currency in defaultCurrencies) {
        final cashBank = Bank(
          id: _uuid.v4(), // Assign a unique ID
          name: 'Cash-${currency.name}',
          currency: currency,
          description: 'Default cash account for ${currency.name}',
          isSystemCreated: true,
        );
        final arBank = Bank(
          id: _uuid.v4(), // Assign a unique ID
          name: 'accounts-receivables-${currency.name}',
          currency: currency,
          description: 'Default accounts receivables for ${currency.name}',
          isSystemCreated: true,
        );
        final apBank = Bank(
          id: _uuid.v4(), // Assign a unique ID
          name: 'accounts-payables-${currency.name}',
          currency: currency,
          description: 'Default accounts payables for ${currency.name}',
          isSystemCreated: true,
        );
        // We probably don't need a specific bank for customer accounts at this basic setup layer,
        // but we add the payment type. The account balance is tracked in the customer object.

        defaultBanks.addAll([cashBank, arBank, apBank]);

        defaultPaymentTypes.add(PaymentType(
          id: _uuid.v4(), // Assign a unique ID
          name: 'CASH-${currency.name}',
          isCash: true,
          currency: currency,
          banks: [cashBank],
          isSystemCreated: true,
            active: true
        ));
        defaultPaymentTypes.add(PaymentType(
          id: _uuid.v4(), // Assign a unique ID
          name: 'CREDIT-${currency.name}',
          currency: currency,
          banks: [arBank],
          isSystemCreated: true,
          active: true
        ));
        
        // Add the account payment type requested
        defaultPaymentTypes.add(PaymentType(
          id: _uuid.v4(), // Assign a unique ID
          name: 'ACC-${currency.name}',
          currency: currency,
          banks: [arBank],
          isSystemCreated: true,
            active: true
        ));
      }

      await prefs.setStringList(
        AppConstants.keyOfflineBanks,
        defaultBanks.map((b) => jsonEncode(b.toJson())).toList()
      );
      await prefs.setStringList(
        AppConstants.keyOfflinePaymentTypes,
        defaultPaymentTypes.map((p) => jsonEncode(p.toJson())).toList()
      );
    }

    if (!prefs.containsKey(AppConstants.keyOfflineTaxes)) {
      final defaultTaxes = [
        Tax(id: _uuid.v4(), name: 'Exempt', taxPercentage: 0.0, description: 'Exempt items'), // Assign a unique ID
        Tax(id: _uuid.v4(), name: 'Zero rate 0%', taxPercentage: 0.0, description: 'Zero rated items'), // Assign a unique ID
        Tax(id: _uuid.v4(), name: 'Standard rated 15.5%', taxPercentage: 15.5, description: 'Standard standard items'), // Assign a unique ID
      ];
      await prefs.setStringList(
        AppConstants.keyOfflineTaxes,
        defaultTaxes.map((t) => jsonEncode(t.toJson())).toList()
      );
    }

    if (!prefs.containsKey(AppConstants.keyOfflineCategories)) {
      final defaultCategories = [
        Category(id: _uuid.v4(), name: 'General', description: 'General items'), // Assign a unique ID
        Category(id: _uuid.v4(), name: 'Services', description: 'Service items'), // Assign a unique ID
      ];
      await prefs.setStringList(AppConstants.keyOfflineCategories, defaultCategories.map((c) => jsonEncode(c.toJson())).toList());
    }

    if (!prefs.containsKey(AppConstants.keyOfflineUnits)) {
      final defaultUnits = [
        Unit(id: _uuid.v4(), name: 'Each', abbreviation: 'each', description: 'Single unit'), // Assign a unique ID
        Unit(id: _uuid.v4(), name: 'Kilogram', abbreviation: 'kg', description: 'Weight in kg'), // Assign a unique ID
        Unit(id: _uuid.v4(), name: 'Litre', abbreviation: 'l', description: 'Volume in litres'), // Assign a unique ID
        Unit(id: _uuid.v4(), name: 'Unit(s)', abbreviation: 'unit(s)', description: 'Volume in litres'), // Assign a unique ID
      ];
      await prefs.setStringList(AppConstants.keyOfflineUnits, defaultUnits.map((u) => jsonEncode(u.toJson())).toList());
    }

    if (!prefs.containsKey(AppConstants.keyOfflineSuppliers)) {
      final Company? company = await CompanyService().getCompany();
      if (company != null) {
        final defaultSupplier = Supplier(
          id: company.id != null ? 'supplier_${company.id}' : _uuid.v4(),
          name: company.name ?? 'Default Supplier',
          email: company.email,
          phoneNumber: company.phoneNumber,
          address: company.address,
        );
        await prefs.setStringList(
          AppConstants.keyOfflineSuppliers,
          [jsonEncode(defaultSupplier.toJson())]
        );
      }
    }

    if (!prefs.containsKey(AppConstants.keyExpenseCategories)) {
      final defaultExpenseCategories = [
        ExpenseCategory(id: _uuid.v4(), name: 'Rent', description: 'Monthly office/store rent'), // Assign a unique ID
        ExpenseCategory(id: _uuid.v4(), name: 'Salaries', description: 'Employee salaries and wages'), // Assign a unique ID
        ExpenseCategory(id: _uuid.v4(), name: 'Utilities', description: 'Electricity, water, internet bills'), // Assign a unique ID
        ExpenseCategory(id: _uuid.v4(), name: 'Marketing', description: 'Advertising and promotional expenses'), // Assign a unique ID
        ExpenseCategory(id: _uuid.v4(), name: 'Travel', description: 'Business travel expenses'), // Assign a unique ID
        ExpenseCategory(id: _uuid.v4(), name: 'Office Supplies', description: 'Stationery and office consumables'), // Assign a unique ID
        ExpenseCategory(id: _uuid.v4(), name: 'Repairs & Maintenance', description: 'Repair and upkeep of assets'), // Assign a unique ID
        ExpenseCategory(id: _uuid.v4(), name: 'Fuel', description: 'Vehicle fuel expenses'), // Assign a unique ID
        ExpenseCategory(id: _uuid.v4(), name: 'Other', description: 'Miscellaneous expenses'), // Assign a unique ID
      ];
      await prefs.setStringList(
        AppConstants.keyExpenseCategories,
        defaultExpenseCategories.map((ec) => jsonEncode(ec.toJson())).toList()
      );
    }

    if (!prefs.containsKey(AppConstants.keyOfflineSubscriptions)) {
      // Find base currency or use USD from the list
      final baseCurrency = defaultCurrencies.firstWhere(
        (c) => c.isBaseCurrency == true,
        orElse: () => defaultCurrencies.first,
      );

      final trialPackage = InventoryItem(
        id: _uuid.v4(),
        name: '7-Day Trial',
        description: 'Initial 7-day free trial package',
        isService: true,
        sellingPrice: 0.0,
        dateCreated: DateTime.now().toIso8601String(),
      );

      final trialSubscription = Subscription(
        id: _uuid.v4(),
        name: '7-Day Trial',
        active: true,
        currency: baseCurrency,
        renewalAmount: 0.0,
        renewalDate: DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 7))),
        subscription: trialPackage,
        dateCreated: DateTime.now().toIso8601String(),
      );

      await prefs.setString(
        AppConstants.keyOfflineSubscriptions,
        jsonEncode([trialSubscription.toMap()])
      );
      
      // Also update remaining days for UI
      await prefs.setInt(AppConstants.keySubscriptionDaysRemaining, 7);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.nearlyWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Create Account', style: AppTheme.headline),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Enter your details to register',
                style: AppTheme.subtitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildTextField(
                controller: _usernameController,
                hintText: 'Username *',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _pinController,
                hintText: 'Login PIN (4 digits) *',
                icon: Icons.pin_outlined,
                keyboardType: TextInputType.number,
                isObscure: true,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _passwordController,
                hintText: 'Password *', // Updated hint text
                icon: Icons.lock_outline,
                isObscure: true,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _confirmPasswordController,
                hintText: 'Confirm Password *', // Updated hint text
                icon: Icons.lock_outline,
                isObscure: true,
              ),
              const SizedBox(height: 16),
              // Optional Fields Section
              ExpansionTile(
                title: Text(
                  _showOptionalFields ? 'Hide Optional Details' : 'Add Optional Details',
                  style: TextStyle(color: AppTheme.vimbikaBlue),
                ),
                onExpansionChanged: (bool expanded) {
                  setState(() {
                    _showOptionalFields = expanded;
                  });
                },
                initiallyExpanded: _showOptionalFields,
                children: <Widget>[
                  _buildTextField(
                    controller: _firstNameController,
                    hintText: 'First Name',
                    icon: Icons.badge_outlined,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _lastNameController,
                    hintText: 'Last Name',
                    icon: Icons.badge_outlined,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _phoneController,
                    hintText: 'Phone Number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16), // Add some spacing after the last optional field
                ],
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
                onPressed: _isLoading ? null : _handleSignup,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: AppTheme.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Sign Up',
                        style: AppTheme.title.copyWith(color: AppTheme.white),
                      ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account? ', style: AppTheme.subtitle),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    },
                    child: Text(
                      'Login',
                      style: AppTheme.subtitle.copyWith(
                        color: AppTheme.vimbikaBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
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
          prefixIcon: Icon(icon, color: AppTheme.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }
}
