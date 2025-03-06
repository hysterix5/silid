import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:silid/core/resources/controllers/data_controller.dart';
import 'package:silid/core/utility/widgets/snackbar.dart';

class AuthController extends GetxController {
  var isLoading = false.obs;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: GetPlatform.isWeb
        ? '16804108720-qpdsb49g2ddcie3jam5nr6but5gqci2u.apps.googleusercontent.com'
        : null, // Only for web
  );

  Rx<User?> currentUser =
      Rx<User?>(null); // Start with null, don't initialize immediately

  @override
  void onInit() {
    super.onInit();

    _restoreUser(); // Restore user on startup
    _auth.authStateChanges().listen((User? user) {
      currentUser.value = user;
    });
  }

  Future<void> _restoreUser() async {
    isLoading.value = true;
    await Future.delayed(
        Duration(seconds: 2)); // Allow Firebase to restore session
    currentUser.value = _auth.currentUser;
    isLoading.value = false;
    if (currentUser.value != null) {
      // ✅ Ensure user is navigated to the right dashboard after refresh
      Get.find<DataController>().checkUserAndNavigate(currentUser.value!.uid);
    }
  }

  Future<void> signInWithEmailAndPass(String email, String password) async {
    isLoading.value = true;
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      currentUser.value = userCredential.user;

      if (userCredential.user != null) {
        Get.find<DataController>()
            .checkUserAndNavigate(userCredential.user!.uid);
      }
    } catch (e) {
      SnackbarWidget.showError('Sign in failed $e');
    } finally {
      isLoading.value = false;
    }
  }

  bool isSigningIn = false;
  Future<void> signInWithGoogle() async {
    if (isSigningIn) return;
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

      UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      currentUser.value = userCredential.user;

      await Future.delayed(const Duration(milliseconds: 500));

      if (userCredential.user != null) {
        Get.find<DataController>()
            .checkUserAndNavigate(userCredential.user!.uid);
      }
    } catch (e) {
      debugPrint(e.toString());
      SnackbarWidget.showError('Google Sign in failed $e');
    } finally {
      isSigningIn = false;
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

  Future<void> logOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      currentUser.value = null;
      Get.offAllNamed('/login');
    } catch (e) {
      SnackbarWidget.showError('Log out failed $e');
    }
  }

  bool isSignedIn() {
    return currentUser.value != null;
  }
}
