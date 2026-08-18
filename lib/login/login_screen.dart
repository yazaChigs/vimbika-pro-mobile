import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vimbika_pro/services/auth_service.dart';
import 'login_controller.dart';
import 'login_view.dart';

class LoginScreen extends StatefulWidget {
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
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  void initState() {
    super.initState();
    AuthService.isLoginScreenActive = true;
  }

  @override
  void dispose() {
    AuthService.isLoginScreenActive = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoginController(
        initialUsername: widget.initialUsername,
        initialPassword: widget.initialPassword,
      ),
      child: const LoginView(),
    );
  }
}
