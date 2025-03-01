import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:silid/core/resources/auth/register.dart';
import 'package:silid/core/resources/controllers/auth_controller.dart';
import 'package:silid/core/resources/controllers/data_controller.dart';
import 'package:silid/core/utility/theme/colors.dart';

class LoginPage extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthController authController = Get.put(AuthController());

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Container(
              width: 400.0,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: AppColors.primary,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.white,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Welcome!',
                    style: TextStyle(
                      fontSize: 28.0,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20.0),
                  Form(
                    key: formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: emailController,
                          decoration: InputDecoration(
                            labelText: "Email",
                            labelStyle: TextStyle(
                              color: AppColors.accent,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(
                                color: AppColors.accent,
                              ),
                            ),
                            prefixIcon: Icon(
                              Icons.email,
                              color: AppColors.accent,
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) =>
                              value!.isEmpty ? "Enter your email" : null,
                        ),
                        const SizedBox(height: 16.0),
                        TextFormField(
                          controller: passwordController,
                          decoration: InputDecoration(
                            labelText: "Password",
                            labelStyle: TextStyle(
                              color: AppColors.accent,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(
                                color: AppColors.accent,
                              ),
                            ),
                            prefixIcon: Icon(
                              Icons.lock,
                              color: AppColors.accent,
                            ),
                          ),
                          obscureText: true,
                          validator: (value) =>
                              value!.isEmpty ? "Enter your password" : null,
                        ),
                        const SizedBox(height: 16.0),
                        Obx(
                          () => OutlinedButton(
                            onPressed: authController.isLoading.value
                                ? null
                                : () {
                                    if (formKey.currentState?.validate() ??
                                        false) {
                                      authController.signInWithEmailAndPass(
                                        emailController.text,
                                        passwordController.text,
                                      );
                                    }
                                  },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: 14.0,
                              ),
                              side: BorderSide(
                                color: AppColors.accent,
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              minimumSize: const Size(double.infinity, 48),
                              foregroundColor: AppColors.accent,
                            ),
                            child: authController.isLoading.value
                                ? CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.tertiary,
                                    ),
                                  )
                                : Text(
                                    "Sign in with Email",
                                    style: TextStyle(
                                      color: AppColors.accent,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 10.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Don’t have an account? ',
                              style: TextStyle(
                                fontSize: 12.0,
                                color: AppColors.accent,
                              ),
                            ),
                            InkWell(
                              onTap: () => Get.to(() => const RegisterPage()),
                              child: Text(
                                'Sign up',
                                style: TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30.0),
                        Text(
                          "Or",
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  OutlinedButton(
                    onPressed: () async {
                      try {
                        final authController = Get.find<AuthController>();
                        final dataController = Get.find<DataController>();

                        await authController.signInWithGoogle();

                        final user = authController.currentUser.value;
                        final userId = user?.uid;

                        if (userId != null) {
                          dataController.checkUserAndNavigate(userId);
                        } else {
                          Get.snackbar(
                            'Error',
                            'Google Sign-in failed. Please try again.',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        }
                      } catch (e) {
                        Get.snackbar(
                          'Error',
                          'Google Sign-in failed: ${e.toString()}',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16.0,
                        horizontal: 24.0,
                      ),
                      side: BorderSide(
                        color: AppColors.accent,
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      backgroundColor: AppColors.tertiary,
                      minimumSize: const Size(double.infinity, 60),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/icons/google_icon.png',
                          height: 24.0,
                          width: 24.0,
                        ),
                        const SizedBox(width: 10.0),
                        Text(
                          "Sign in with Google",
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 18.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
