import 'package:flutter/material.dart';
import 'package:flutter_icon_snackbar/flutter_icon_snackbar.dart';
import 'package:get/get.dart';

class SnackbarWidget {
  static void showSnackbar({
    required String label,
    required SnackBarType snackBarType,
  }) {
    IconSnackBar.show(Get.context!,
        snackBarType: snackBarType,
        label: label,
        backgroundColor: _getBackgroundColor(snackBarType),
        iconColor: Colors.white,
        labelTextStyle: TextStyle(color: Colors.white) // Ensuring contrast
        );
  }

  static void showSuccess(String message) {
    showSnackbar(
      label: message,
      snackBarType: SnackBarType.success,
    );
  }

  static void showError(String message) {
    showSnackbar(
      label: message,
      snackBarType: SnackBarType.fail,
    );
  }

  static void showWarning(String message) {
    showSnackbar(
      label: message,
      snackBarType: SnackBarType.alert,
    );
  }

  // Helper method to set background color based on type
  static Color _getBackgroundColor(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return Colors.green;
      case SnackBarType.fail:
        return Colors.red;
      case SnackBarType.alert:
        return Colors.orange;
    }
  }
}
