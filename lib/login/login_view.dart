import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'login_controller.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LoginController>(
      builder: (context, controller, child) {
        // Auto-login if initial credentials are provided
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (controller.identifierController.text.isNotEmpty && 
              controller.passwordController.text.isNotEmpty && 
              !controller.isLoading &&
              !controller.hasLoggedInAttempted) { // Need to add this flag to controller
            controller.handleLogin(context);
          }
        });

        return Scaffold(
          backgroundColor: AppTheme.nearlyWhite,
          body: SingleChildScrollView(
            child: Container(
              height: MediaQuery.of(context).size.height,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 300, // Adjust height as needed
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getGreeting(),
                    style: AppTheme.headline,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  
                  _buildTextField(
                    controller: controller.identifierController,
                    hintText: 'Username',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: controller.passwordController,
                    hintText: 'Password',
                    icon: Icons.lock_outline,
                    isObscure: !controller.isPasswordVisible,
                    keyboardType: TextInputType.text,
                    suffixIcon: IconButton(
                      icon: Icon(
                        controller.isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: AppTheme.grey,
                      ),
                      onPressed: controller.togglePasswordVisibility,
                    ),
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
                    onPressed: controller.isLoading ? null : () => controller.handleLogin(context),
                    child: controller.isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(
                            'Login',
                            style: AppTheme.title.copyWith(color: AppTheme.white),
                          ),
                  ),
                  if (controller.hasUserData) // Conditionally show Forgot Password
                    const SizedBox(height: 32),
                  if (controller.hasUserData) // Conditionally show Forgot Password
                    TextButton(
                      onPressed: () {
                        // TODO: Implement forgot password
                      },
                      child: Text(
                        'Forgot Password?',
                        style: AppTheme.subtitle.copyWith(color: AppTheme.vimbikaBlue),
                      ),
                    ),
                  if (controller.showCreateButton) ...[
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => controller.navigateToCreateCompany(context),
                      child: Text(
                        'Create Company/User',
                        style: AppTheme.subtitle.copyWith(color: AppTheme.vimbikaBlue),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
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
