import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vimbika_pos_app/src/constants/sizes.dart';
import 'package:vimbika_pos_app/src/features/authentication/controller/auth_controller.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.put(AuthController());

    return WillPopScope(
      onWillPop: () => Future.value(false),
      child: SafeArea(
        child: Scaffold(
          body: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(tDefaultSize),
                child: Column(
                  children: [
                    Form(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: tFormHeight - 10),
                        child: Form(
                          key: authController.loginFormKey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [

                              // Image
                              Image.asset(
                                'assets/images/logo/logo.png',
                                width: 150,
                                height: 150,
                              ),
                              SizedBox(height: 20),
                              // Greeting Text
                              Obx(() =>
                                  Text(
                                    authController.greeting.value,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )),
                              SizedBox(height: 20),

                              TextFormField(
                                  controller: authController
                                      .usernameTextEditingController,
                                  decoration: const InputDecoration(
                                      prefixIcon: Icon(
                                          Icons.person_outline_outlined),
                                      labelText: "Username",
                                      hintText: "Username"),

                                  onSaved: (value) {
                                    authController.userName = value!;
                                  }
                              ),
                              const SizedBox(height: tFormHeight - 20),
                              // TextFormField(
                              //   obscureText:  authController.isPasswordVisible.isTrue ? true : false,
                              //   controller: authController.passwordTextEditingController,
                              //   decoration: const InputDecoration(
                              //       prefixIcon: Icon(Icons.fingerprint),
                              //       labelText: "Password",
                              //       hintText: "Password",
                              //        suffixIcon:  authController.isPasswordVisible.isTrue ?  Icon(Icons.visibility_off) :  Icon(Icons.visibility),
                              //        // suffixIcon: Icon(Icons.hide_source)
                              //   ),
                              //   onSaved: (value) {
                              //     authController.password = value!;
                              //   },
                              // ),
                              Obx(() {
                                return TextFormField(
                                  obscureText: authController.isPasswordVisible
                                      .isTrue,
                                  // Obscure text based on isPasswordVisible
                                  controller: authController
                                      .passwordTextEditingController,
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(Icons.fingerprint),
                                    labelText: "Password",
                                    hintText: "Password",
                                    suffixIcon:
                                        IconButton(
                                          icon: Icon(
                                            // Change icon based on password visibility status
                                            authController.isPasswordVisible
                                                .isTrue
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                          ),
                                          onPressed: () {
                                            authController
                                                .changePasswordVisibleStatus();
                                          }, // Toggle visibility
                                        )
                                  ),
                                  onSaved: (value) {
                                    authController.password = value!;
                                  },
                                );
                              }),

                              const SizedBox(height: tFormHeight - 20),


                              /// -- LOGIN BTN
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (authController.checkValidation()) {
                                      print("Validation okay..");
                                      authController.authenticateUser();
                                    } else {
                                      print("Validation not okay..");
                                    }
                                  },
                                  child: Text("Login"),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              )
          ),
        ),
      ),
    );
  }
}
