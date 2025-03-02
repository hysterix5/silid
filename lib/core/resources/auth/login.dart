import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:silid/core/resources/auth/register.dart';
import 'package:silid/core/resources/controllers/auth_controller.dart';
import 'package:silid/core/resources/controllers/data_controller.dart';
import 'package:silid/core/utility/theme/controllers/theme_controller.dart';
import 'package:silid/core/utility/widgets/snackbar.dart';

class LoginPage extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthController authController = Get.put(AuthController());

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final ThemeController themeController = Get.find<ThemeController>();

  LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          Icon(themeController.isDarkMode.value
              ? Icons.dark_mode
              : Icons.light_mode),
          const Text("Dark Mode"),
          Switch(
            value: themeController.isDarkMode.value,
            onChanged: (value) {
              themeController.toggleTheme();
            },
          ),
        ],
      ),
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
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .primary, // Border color from theme
                  width: 2.0, // Border thickness
                ),
                borderRadius:
                    BorderRadius.circular(8.0), // Optional: rounded corners
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Welcome!',
                    style: TextStyle(
                      fontSize: 28.0,
                      fontWeight: FontWeight.bold,
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
                            labelStyle: const TextStyle(),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary, // Adjusts with theme
                                width: 2.0,
                              ),
                            ),
                            prefixIcon: const Icon(
                              Icons.email,
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
                            labelStyle: const TextStyle(),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary, // Adjusts with theme
                                width: 2.0,
                              ),
                            ),
                            prefixIcon: const Icon(
                              Icons.lock,
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
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            child: authController.isLoading.value
                                ? const CircularProgressIndicator()
                                : const Text(
                                    "Sign in with Email",
                                    style: TextStyle(),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 10.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Don’t have an account? ',
                              style: TextStyle(
                                fontSize: 12.0,
                              ),
                            ),
                            InkWell(
                              onTap: () => Get.to(() => const RegisterPage()),
                              child: const Text(
                                'Sign up',
                                style: TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30.0),
                        const Text(
                          "Or",
                          style: TextStyle(
                            fontSize: 16,
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
                          SnackbarWidget.showError(
                              'Google Sign-in failed: Please try again.');
                        }
                      } catch (e) {
                        SnackbarWidget.showError(
                            'Google Sign-in failed: ${e.toString()}');
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16.0,
                        horizontal: 24.0,
                      ),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
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
                        const Text(
                          "Sign in with Google",
                          style: TextStyle(
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
