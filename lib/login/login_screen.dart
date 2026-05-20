import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'login_controller.dart';
import 'login_view.dart';

class LoginScreen extends StatelessWidget {
  final bool initialOfflineMode;
  final String? initialUsername;
  
  const LoginScreen({super.key, this.initialOfflineMode = true, this.initialUsername});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoginController(initialUsername: initialUsername),
      child: const LoginView(),
    );
  }
}
