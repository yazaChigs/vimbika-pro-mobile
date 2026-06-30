import 'package:intl/intl.dart';
import 'package:vimbika_pro/model/subscription.dart';
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
import '../screens/offline/settings/subscription_screen.dart';
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
  bool _hasLoggedInAttempted = false;
  final BaseHttpClient _client = BaseHttpClient();
  final Uuid _uuid = const Uuid(); // Initialize Uuid

  bool get isLoading => _isLoading;
  bool get showCreateButton => _showCreateButton;
  bool get isPasswordVisible => _isPasswordVisible;
  bool get hasUserData => _hasUserData; // Getter for hasUserData
  bool get hasLoggedInAttempted => _hasLoggedInAttempted;

  LoginController({String? initialUsername, String? initialPassword}) {
    if (initialUsername != null) {
      print('initialUsername: $initialUsername');
      identifierController.text = initialUsername;
    }
    if (initialPassword != null) {
      passwordController.text = initialPassword;
    }
    _loadInitialState().then((_) {
      if (initialUsername != null && initialPassword != null) {
        // Use a small delay to ensure the UI is ready if needed, 
        // or just call handleLogin if context is not needed immediately for the login logic itself.
        // Actually handleLogin needs context. 
      }
    });
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
    _hasLoggedInAttempted = true;
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
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text('Local login failed. Attempting online login...')),
      // );
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
        if (user.userName == username && (user.pin == pin || user.password == pin)) {
          foundUser = user;
          break;
        }
      }

      if (foundUser != null) {
        // --- Start of new code for subscription check ---
        final String? subscriptionsJson = prefs.getString(AppConstants.keyOfflineSubscriptions);
        bool isValidSubscription = false;

        if (subscriptionsJson != null) {
          final List<dynamic> offlineSubscriptionsData = jsonDecode(subscriptionsJson);
          isValidSubscription = await _validateSubscriptionFromData(context, offlineSubscriptionsData);
        } else {
          if (context.mounted) {
              _showErrorDialog(context, "Subscription Error", "No offline subscription data found.");
          }
        }

        if (!isValidSubscription) {
            if (context.mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
              );
            }
            return false; // Stop login process if subscription is invalid
        }
        // --- End of new code for subscription check ---

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
        dateCreated: DateFormat('yyyy-MM-dd').format(DateTime.now()),
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

  Future<bool> _hasLocalNetworkConnection() async {
    try {
      // Check for any non-loopback network interfaces.
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.any,
      );

      // Keywords often found in hotspot/tethering interface names
      final hotspotKeywords = ['ap', 'hotspot', 'tether', 'bridge'];

      for (var interface in interfaces) {
        final name = interface.name.toLowerCase();
        // Check if the interface name contains any of the hotspot keywords
        final isHotspot = hotspotKeywords.any((keyword) => name.contains(keyword));

        if (!isHotspot) {
          return true; // Found a valid, non-hotspot connection
        }
      }

      return false; // Only hotspot or no interfaces found
    } catch (e) {
      print('Could not check network interfaces: $e');
      return false;
    }
  }

  Future<bool> _checkServerConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    } on SocketException catch (_) {
      return false;
    }
    return false;
  }

  Future<bool> _handleOnlineLogin(BuildContext context, String username, String password) async {
    try {
      // First, check for a local network connection (Wi-Fi or mobile data)
      final hasLocalConnection = await _hasLocalNetworkConnection();
      if (!hasLocalConnection) {
        throw const SocketException('No active network connection found. Please check your Wi-Fi or Mobile Data.');
      }

      // If a local connection exists, then check if the server is reachable
      final isServerReachable = await _checkServerConnectivity();
      if (!isServerReachable) {
        throw const SocketException('Unable to reach the server. Please check your internet connection.');
      }

      final jwtRequest = JwtRequestModel(
        userName: username,
        password: password,
      );

      final responseStr = await _client.post('/authentication', jsonEncode(jwtRequest.toJson()));
      final Map<String, dynamic> data = jsonDecode(responseStr);

      // Verify subscription FIRST before saving anything
      bool isValidSubscription = false;
      if (data['subscriptions'] != null) {
        isValidSubscription = await _validateSubscriptionFromData(context, data['subscriptions']);
      } else {
        if (context.mounted) {
            _showErrorDialog(context, "Subscription Error", "No subscription data found in server response.");
        }
      }

      if (!isValidSubscription) {
          return false; // Stop login process if subscription is invalid
      }

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
        if (user.userRoles!.any((role) => role.name == 'ROLE_SUPER_ADMIN')) {
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
    } on SocketException catch(e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Online login failed: Username or Password incorrect...');
    }
  }

  Future<bool> _validateSubscriptionFromData(BuildContext context, dynamic subscriptionsData) async {
      try {
        final List<Subscription> subscriptions = (subscriptionsData as List)
            .map((data) => Subscription.fromMap(data as Map<String, dynamic>))
            .toList();

        final SharedPreferences prefs = await SharedPreferences.getInstance();

        for (final subscription in subscriptions) {
          final DateTime? renewalDateTime = subscription.getRenewalDate();
          if (subscription.active == true &&
              renewalDateTime != null &&
              renewalDateTime.isAfter(DateTime.now())) {
            final now = DateTime.now();
            final startOfDay = DateTime(now.year, now.month, now.day);
            final daysRemaining = renewalDateTime.difference(startOfDay).inDays;

            await prefs.setInt(AppConstants.keySubscriptionDaysRemaining, daysRemaining);

            if (daysRemaining <= 5 && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Your subscription will expire in $daysRemaining days"),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
            return true;
          }
        }
      } catch (e) {
        if (context.mounted) {
            _showErrorDialog(context, "Subscription Error", "Failed to parse subscription data.");
        }
        return false;
      }

      if (context.mounted) {
          _showErrorDialog(context, "Subscription Expired", "Your subscription has expired. Please contact your admin.");
      }
      return false;
  }

  // Still keeping this for potential other uses (e.g. checking later on)
  Future<bool> hasValidSubscription(BuildContext context) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? subscriptionsJson = prefs.getString(AppConstants.keySubscriptions);

    if (subscriptionsJson == null) {
      _showErrorDialog(context, "Subscription Error", "No subscription data found.");
      return false;
    }

    try {
      final List<dynamic> subscriptionsData = jsonDecode(subscriptionsJson);
      return await _validateSubscriptionFromData(context, subscriptionsData);
    } catch (e) {
      _showErrorDialog(context, "Subscription Error", "Failed to parse subscription data.");
      return false;
    }
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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
