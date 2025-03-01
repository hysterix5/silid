import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:silid/core/utility/theme/colors.dart';
import 'package:silid/core/views/newcomer/form.dart';

class Newcomer extends StatelessWidget {
  const Newcomer({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "I am a:",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 30.0),

                // Grid with fixed size and Card
                SizedBox(
                  height: 350, // Adjust the height of the grid
                  width: 500, // Adjust the width of the grid
                  child: GridView.count(
                    crossAxisCount: 2, // Two columns
                    mainAxisSpacing: 20.0,
                    crossAxisSpacing: 20.0,
                    physics:
                        const NeverScrollableScrollPhysics(), // Disable scrolling
                    children: [
                      // Teacher Option
                      InkWell(
                        onTap: () {
                          Get.to(() => const TeacherForm());
                        },
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          elevation: 4.0,
                          child: Column(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(10.0),
                                  ),
                                  child: AspectRatio(
                                    aspectRatio:
                                        1.0, // Maintain square aspect ratio
                                    child: Image.asset(
                                      'assets/icons/teacher.png', // Replace with your teacher image path
                                      fit: BoxFit
                                          .cover, // Prevent image distortion
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  "Teacher",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Student Option
                      InkWell(
                        onTap: () {
                          Get.to(() => const StudentForm());
                        },
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          elevation: 4.0,
                          child: Column(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(10.0),
                                  ),
                                  child: AspectRatio(
                                    aspectRatio:
                                        1.0, // Maintain square aspect ratio
                                    child: Image.asset(
                                      'assets/icons/student.png', // Replace with your student image path
                                      fit: BoxFit
                                          .fitHeight, // Prevent image distortion
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  "Student",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
    );
  }
}
