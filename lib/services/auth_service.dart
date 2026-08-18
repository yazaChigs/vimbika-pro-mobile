import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:vimbika_pro/app_constants/app_constants.dart';
import 'package:vimbika_pro/services/base_http_client.dart';
import 'package:vimbika_pro/services/company_service.dart';
import 'package:vimbika_pro/model/company.dart';
import 'package:vimbika_pro/model/user.dart';
import 'package:vimbika_pro/model/jwt_request_model.dart';

class AuthService {
  static bool isLoginScreenActive = false;
  static bool _isShowingDialog = false;

  static void showRegenerateTokenDialog() {
    if (isLoginScreenActive) return;

    final context = AppConstants.navigatorKey.currentContext;
    if (context == null || _isShowingDialog) return;

    _isShowingDialog = true;
    
    final TextEditingController usernameController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Regenerate Server Token',
      pageBuilder: (context, animation, secondaryAnimation) {
        bool isLoading = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Session Expired'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Your session has expired or is unauthorized. Please enter your credentials to continue.'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 16.0),
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () {
                    _isShowingDialog = false;
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final username = usernameController.text.trim();
                          final password = passwordController.text;

                          if (username.isEmpty || password.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter both username and password')),
                            );
                            return;
                          }

                          setState(() {
                            isLoading = true;
                          });

                          try {
                            final BaseHttpClient client = BaseHttpClient();
                            final jwtRequest = JwtRequestModel(
                              userName: username,
                              password: password,
                            );

                            final responseStr = await client.post('/authentication', jsonEncode(jwtRequest.toJson()));
                            final Map<String, dynamic> data = jsonDecode(responseStr);

                            final SharedPreferences prefs = await SharedPreferences.getInstance();
                            
                            await prefs.setString(AppConstants.CACHED_ACCESS_TOKEN, data['token'] ?? '');
                            await prefs.setString(AppConstants.keyOnlineUserData, jsonEncode(data['user']));
                            
                            if (data['company'] != null) {
                              await CompanyService().saveOnlineCompany(Company.fromJson(data['company']));
                            }
                            
                            await prefs.setString(AppConstants.keySubscriptions, jsonEncode(data['subscriptions']));
                            await prefs.setString(AppConstants.keyOfflineSubscriptions, jsonEncode(data['subscriptions']));
                            await prefs.setString(AppConstants.keyConfig, jsonEncode(data['config']));

                            final String? offlineUserDataStr = prefs.getString(AppConstants.keyOfflineUserData);
                            if (offlineUserDataStr != null) {
                              final offlineUser = User.fromJson(jsonDecode(offlineUserDataStr));
                              final onlineUser = User.fromJson(data['user']);
                              if (offlineUser.userName == onlineUser.userName) {
                                await prefs.setString(AppConstants.keyOfflineUserData, jsonEncode(data['user']));
                              }
                            }
                            
                            await prefs.setString(AppConstants.keyUserData, jsonEncode(data['user']));

                            _isShowingDialog = false;
                            Navigator.pop(context);
                            
                            ScaffoldMessenger.of(AppConstants.navigatorKey.currentContext!).showSnackBar(
                              const SnackBar(content: Text('Server token regenerated successfully')),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to regenerate token: $e')),
                            );
                          } finally {
                            setState(() {
                              isLoading = false;
                            });
                          }
                        },
                  child: const Text('Login'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
