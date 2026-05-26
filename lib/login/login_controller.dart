import 'package:vimbika_pro/services/company_service.dart';
import 'package:vimbika_pro/model/company.dart';
import 'package:vimbika_pro/app_constants/app_constants.dart';
import 'package:vimbika_pro/model/jwt_request_model.dart';
import 'package:vimbika_pro/model/user.dart';
import 'package:vimbika_pro/services/base_http_client.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:uuid/uuid.dart';
import '../model/mobile_pos_shift.dart';
import '../online_navigation_home_screen.dart';
import 'package:vimbika_pro/screens/online/online_reports_screen.dart';
import '../create_company_screen.dart';
import '../screens/online/select_company_branch_screen.dart';
import '../signup_screen.dart';
import 'package:vimbika_pro/services/sale_sync_service.dart';

class LoginController extends ChangeNotifier {
  final TextEditingController identifierController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isLoading = false;
  bool _showCreateButton = true;
  bool _isPasswordVisible = false;
  bool _hasUserData = false; // New variable to track user data
  final BaseHttpClient _client = BaseHttpClient();
  final Uuid _uuid = const Uuid(); // Initialize Uuid

  bool get isLoading => _isLoading;
  bool get showCreateButton => _showCreateButton;
  bool get isPasswordVisible => _isPasswordVisible;
  bool get hasUserData => _hasUserData; // Getter for hasUserData

  LoginController({String? initialUsername}) {
    if (initialUsername != null) {
      print('initialUsername: $initialUsername');
      identifierController.text = initialUsername;
    }
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Company? company = await CompanyService().getCompany();
    final bool hasCompany = company != null;
    final List<String> allUsers = prefs.getStringList(AppConstants.keyAllUsers) ?? [];
    
    _showCreateButton = !hasCompany || allUsers.isEmpty;
    _hasUserData = allUsers.isNotEmpty; // Set _hasUserData based on existing users
    notifyListeners();
  }

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  Future<void> handleLogin(BuildContext context) async {
    final String identifier = identifierController.text.trim();
    final String password = passwordController.text;

    if (identifier.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Username and Password/PIN')),
      );
      return;
    }

    _isLoading = true;
    notifyListeners();

    // First attempt offline login
    bool offlineSuccess = await _handleOfflineLogin(context, identifier, password);

    if (offlineSuccess) {
      // Offline login successful, navigation handled within _handleOfflineLogin
      // Optional: We could start syncing in the background here if needed
      _isLoading = false;
      notifyListeners();
      return;
    }

    // Offline failed, attempt online login
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Local login failed. Attempting online login...')),
      );
    }

    bool onlineSuccess = false;
    String? onlineErrorMessage;

    try {
      onlineSuccess = await _handleOnlineLogin(context, identifier, password);
    } catch (e) {
      onlineErrorMessage = e.toString();
      print('Online login attempt failed: $e');
    }

    if (onlineSuccess) {
      // Online login successful, navigation handled within _handleOnlineLogin
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(onlineErrorMessage != null ? 'Login failed: $onlineErrorMessage' : 'Login failed. Invalid username or password.')),
        );
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> _handleOfflineLogin(BuildContext context, String username, String pin) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> allUsersJson = prefs.getStringList(AppConstants.keyAllUsers) ?? [];
      
      User? foundUser;
      for (String userStr in allUsersJson) {
        final userMap = jsonDecode(userStr);
        final user = User.fromJson(userMap);
        if (user.userName == username && user.pin == pin) {
          foundUser = user;
          break;
        }
      }

      if (foundUser != null) {
        await prefs.setString(AppConstants.keyOfflineUserData, jsonEncode(foundUser.toJson()));
        await prefs.setString(AppConstants.keyUserData, jsonEncode(foundUser.toJson()));
        if (foundUser.branch?.company != null) {
          await CompanyService().saveOfflineCompany(foundUser.branch!.company!);
        }
        await prefs.setBool(AppConstants.keyHasUser, true);
        await prefs.setBool(AppConstants.keyHasLoggedIn, true); // Mark as logged in
        await prefs.setBool(AppConstants.keyIsOfflineMode, true); // Keep this to indicate the mode of the current session

        // Ensure there is an open shift
        await _ensureOpenShift(prefs, foundUser);

        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const OnlineNavigationHomeScreen(isOnline: false)),
          );
        }
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Offline login error: $e');
      return false;
    }
  }

  Future<void> _ensureOpenShift(SharedPreferences prefs, User user) async {
    final String? currentShiftJson = prefs.getString(AppConstants.keyCurrentOpenShift);
    
    // Check if shift exists, if not, create one
    if (currentShiftJson == null) {
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
      await prefs.setString(AppConstants.keyCurrentOpenShift, shift.toJson());

      // Also add to the offline mobile shifts history
      final List<String> shiftsJson = prefs.getStringList(AppConstants.keyOfflineMobileShifts) ?? [];
      shiftsJson.add(shift.toJson());
      await prefs.setStringList(AppConstants.keyOfflineMobileShifts, shiftsJson);
    }
  }

  Future<bool> _handleOnlineLogin(BuildContext context, String username, String password) async {
    try {
      // Check internet connection
      try {
        final result = await InternetAddress.lookup('google.com');
        if (result.isEmpty || result[0].rawAddress.isEmpty) {
          throw const SocketException('No Internet connection');
        }
      } on SocketException catch (_) {
        throw Exception('No internet connection. Please check your settings.');
      }

      final jwtRequest = JwtRequestModel(
        userName: username,
        password: password,
      );

      final responseStr = await _client.post('/authentication', jsonEncode(jwtRequest.toJson()));
      final Map<String, dynamic> data = jsonDecode(responseStr);

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      
      await prefs.setString(AppConstants.CACHED_ACCESS_TOKEN, data['token'] ?? '');
      await prefs.setString(AppConstants.keyOnlineUserData, jsonEncode(data['user']));
      
      if (data['company'] != null) {
        await CompanyService().saveOnlineCompany(Company.fromJson(data['company']));
      }
      
      await prefs.setString(AppConstants.keySubscriptions, jsonEncode(data['subscriptions']));
      await prefs.setString(AppConstants.keyConfig, jsonEncode(data['config']));
      await prefs.setBool(AppConstants.keyHasUser, true);
      await prefs.setBool(AppConstants.keyHasLoggedIn, true); // Mark as logged in
      await prefs.setBool(AppConstants.keyIsOfflineMode, false); // Keep this to indicate the mode of the current session

      final user = User.fromJson(data['user']);
      if (user.branch != null) {
        await prefs.setString(AppConstants.keyDefaultBranch, jsonEncode(user.branch!.toJson()));
      }

      // Ensure there is an open shift for online mode too, or it could be handled by the server. 
      // For now, doing it here to be consistent with offline mode.
      await _ensureOpenShift(prefs, user);

      // Start the sync service after successful online login
      SaleSyncService().startSyncTimer();

      if (context.mounted) {
        if (user.userRoles!.any((role)=> role.name =='ROLE_SUPER_ADMIN'))  {
          print('Super Admin');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const OnlineReportsScreen()),
          );
        } else {
          print('Not Super Admin');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => SelectCompanyBranchScreen(user: user)),
          );
        }
      }
      return true;
    } catch (e) {
      print('Online login failed: $e');
      throw Exception('Online login failed: ${e.toString()}');
    }
  }

  void navigateToCreateCompany(BuildContext context) async {
    final Company? company = await CompanyService().getCompanyFromLocalStorage();
    final bool hasCompany = company != null;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> allUsers = prefs.getStringList(AppConstants.keyAllUsers) ?? [];
    
    if (context.mounted) {
      if (!hasCompany) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => CreateCompanyScreen()));
      } else if (allUsers.isEmpty) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupScreen()));
      }
    }
  }

  @override
  void dispose() {
    identifierController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
