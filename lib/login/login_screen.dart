import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'login_controller.dart';
import 'login_view.dart';

class LoginScreen extends StatelessWidget {
  final bool initialOfflineMode;
  final String? initialUsername;
  final String? initialPassword;
  
  const LoginScreen({
    super.key, 
    this.initialOfflineMode = true, 
    this.initialUsername,
    this.initialPassword,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoginController(
        initialUsername: initialUsername,
        initialPassword: initialPassword,
      ),
      child: const LoginView(),
    );
  }
}
