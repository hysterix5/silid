import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ShowDialogUtil {
  /// Shows an information dialog with a title and message.
  static void showInfoDialog(String title, String message) {
    Get.defaultDialog(
      title: title,
      middleText: message,
      textConfirm: "OK",
      confirmTextColor: Colors.white,
      onConfirm: () => Get.back(),
    );
  }

  /// Shows a confirmation dialog with customizable actions.
  static void showConfirmDialog({
    required String title,
    required String message,
    required VoidCallback onConfirm,
    String confirmText = "Yes",
    String cancelText = "No",
  }) {
    Get.defaultDialog(
      title: title,
      middleText: message,
      textConfirm: confirmText,
      textCancel: cancelText,
      confirmTextColor: Colors.white,
      onConfirm: () {
        onConfirm();
        Get.back(); // Close dialog after confirming
      },
      onCancel: () => Get.back(),
    );
  }

  /// Shows a loading dialog
  static void showLoadingDialog({String message = "Loading..."}) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(message, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
      barrierDismissible: false, // Prevent dismissing by tapping outside
    );
  }

  /// Hides any currently open dialog
  static void hideDialog() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }

  /// Shows a dialog with cards
  static void showCardsDialog({
    required BuildContext context, // Add context parameter
    required String title,
    required List<Widget> cards,
  }) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Column(
                children: cards.map((card) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: card,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true, // Allow dismissing by tapping outside
    );
  }

  static Future<Map<String, dynamic>?> showTimeslotDialog(BuildContext context,
      DateTime selectedDay, List<Map<String, String>> existingTimeslots) {
    final selectedTimeslots = List<Map<String, String>>.from(existingTimeslots);

    return Get.dialog<Map<String, dynamic>>(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Timeslots',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Selected Date: ${DateFormat('yyyy-MM-dd').format(selectedDay)}',
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.maxFinite,
                height: 400,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return ListView.builder(
                      itemCount: 48, // 24 hours * 2 (30-minute intervals)
                      itemBuilder: (context, index) {
                        final time = DateTime(0, 0, 0, 0, 0)
                            .add(Duration(minutes: 30 * index));
                        final formattedTime =
                            DateFormat('hh:mm a').format(time);
                        final isSelected = selectedTimeslots
                            .any((element) => element['time'] == formattedTime);

                        return CheckboxListTile(
                          title: Text(formattedTime),
                          value: isSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                selectedTimeslots.add(
                                    {'time': formattedTime, 'status': 'open'});
                              } else {
                                selectedTimeslots.removeWhere((element) =>
                                    element['time'] == formattedTime);
                              }
                            });
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context, {'status': 'cancel', 'time': []});
                    },
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context,
                          {'status': 'confirm', 'time': selectedTimeslots});
                    },
                    child: const Text('Confirm'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true, // Allow dismissing by tapping outside
    );
  }
}
