import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:silid/core/resources/auth/login.dart';
import 'package:silid/core/resources/controllers/data_controller.dart';

class AuthController extends GetxController {
  var isLoading = false.obs;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: GetPlatform.isWeb
        ? '16804108720-qpdsb49g2ddcie3jam5nr6but5gqci2u.apps.googleusercontent.com'
        : null, // Only provide clientId for web
  );

  Rx<User?> currentUser = Rx<User?>(FirebaseAuth.instance.currentUser);

  @override
  void onInit() {
    super.onInit();
    _auth.authStateChanges().listen((User? user) {
      currentUser.value = user;
    });
  }

  Future<void> signInWithEmailAndPass(String email, String password) async {
    isLoading.value = true;
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      String? userId = userCredential.user?.uid;
      if (userId != null) {
        Get.find<DataController>().checkUserAndNavigate(userId);
      }
    } catch (e) {
      Get.snackbar('Error', 'Sign-in failed: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<UserCredential> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception('Failed to register: ${e.message}');
    }
  }

  bool isSigningIn = false; // Add this flag
  Future<void> signInWithGoogle() async {
    if (isSigningIn) return; // Prevent duplicate calls
    isSigningIn = true;

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        isSigningIn = false;
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      // Delay navigation slightly to prevent overlapping calls
      await Future.delayed(const Duration(milliseconds: 500));

      if (userCredential.user != null) {
        if (Get.isRegistered<DataController>()) {
          Get.find<DataController>().checkUserAndNavigate(
            userCredential.user!.uid,
          );
        }
      }
    } catch (e) {
      debugPrint(e.toString());
      Get.snackbar('Error', 'Google Sign-In failed: ${e.toString()}');
    } finally {
      isSigningIn = false;
    }
  }

  Future<void> logOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      currentUser.value = null;

      // Navigate back to LoginPage and remove all previous routes
      Get.offAll(() => LoginPage());
    } catch (e) {
      Get.snackbar('Error', 'Logout failed: ${e.toString()}');
    }
  }

  bool isSignedIn() {
    return currentUser.value != null;
  }
}
