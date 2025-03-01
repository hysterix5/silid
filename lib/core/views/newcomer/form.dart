import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:silid/core/resources/controllers/data_controller.dart';
import 'package:silid/core/resources/controllers/student_controller.dart';
import 'package:silid/core/resources/controllers/teacher_controller.dart';
import 'package:silid/core/resources/models/teacher.dart';
import 'package:silid/core/resources/models/student.dart';
import 'package:silid/core/utility/theme/colors.dart';

class TeacherForm extends StatefulWidget {
  const TeacherForm({super.key});

  @override
  State<TeacherForm> createState() => _TeacherFormState();
}

class _TeacherFormState extends State<TeacherForm> {
  // Controllers for retrieving input text
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(); // Form key
  final TeacherController teacherController = Get.put(TeacherController());
  final DataController dataController = Get.put(DataController());

  User? user = FirebaseAuth.instance.currentUser;
  bool _isLoading = false; // Track form submission state

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text('Basic Info'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.accent,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Enter Your Information',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // First Name Field
                  TextFormField(
                    controller: firstNameController,
                    decoration: InputDecoration(
                      labelText: 'First Name',
                      labelStyle: TextStyle(color: AppColors.primary),
                      floatingLabelStyle: TextStyle(
                        color: AppColors.tertiary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                    ),
                    validator: (value) => value!.trim().isEmpty
                        ? 'Please enter your first name'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Last Name Field
                  TextFormField(
                    controller: lastNameController,
                    decoration: InputDecoration(
                      labelText: 'Last Name',
                      labelStyle: TextStyle(color: AppColors.primary),
                      floatingLabelStyle: TextStyle(
                        color: AppColors.primary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                    ),
                    validator: (value) => value!.trim().isEmpty
                        ? 'Please enter your last name'
                        : null,
                  ),

                  const SizedBox(height: 24),

                  // Submit Button
                  ElevatedButton(
                    onPressed: () async {
                      setState(() {
                        _isLoading = true;
                      });
                      try {
                        // Create a Student instance with the form data
                        Teacher teacher = Teacher(
                          uid: user!.uid,
                          name:
                              '${firstNameController.text} ${lastNameController.text}',
                          email: user!.email!,
                        );
                        await teacherController.submitTeacherData(teacher);
                      } finally {
                        await dataController.checkUserAndNavigate(user!.uid);
                        setState(() {
                          _isLoading = false; // Ensure loading state resets
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.tertiary,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : Text(
                            'Submit',
                            style: TextStyle(color: AppColors.accent),
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

  @override
  void dispose() {
    // Dispose controllers when the widget is removed
    firstNameController.dispose();
    lastNameController.dispose();
    super.dispose();
  }
}

class StudentForm extends StatefulWidget {
  const StudentForm({super.key});

  @override
  State<StudentForm> createState() => _StudentFormState();
}

class _StudentFormState extends State<StudentForm> {
  // Controllers for retrieving input text
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(); // Form key
  final StudentController studentController = Get.put(StudentController());
  final DataController dataController = Get.put(DataController());

  User? user = FirebaseAuth.instance.currentUser;
  bool _isLoading = false; // Track form submission state

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text('Basic Info'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.accent,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Enter Your Information',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // First Name Field
                  TextFormField(
                    controller: firstNameController,
                    decoration: InputDecoration(
                      labelText: 'First Name',
                      labelStyle: TextStyle(color: AppColors.primary),
                      floatingLabelStyle: TextStyle(
                        color: AppColors.tertiary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                    ),
                    validator: (value) => value!.trim().isEmpty
                        ? 'Please enter your first name'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Last Name Field
                  TextFormField(
                    controller: lastNameController,
                    decoration: InputDecoration(
                      labelText: 'Last Name',
                      labelStyle: TextStyle(color: AppColors.primary),
                      floatingLabelStyle: TextStyle(
                        color: AppColors.primary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                    ),
                    validator: (value) => value!.trim().isEmpty
                        ? 'Please enter your last name'
                        : null,
                  ),

                  const SizedBox(height: 24),

                  // Submit Button
                  ElevatedButton(
                    onPressed: () async {
                      setState(() {
                        _isLoading = true;
                      });
                      try {
                        // Create a Student instance with the form data
                        Student student = Student(
                          uid: user!.uid,
                          name:
                              '${firstNameController.text} ${lastNameController.text}',
                          email: user!.email!,
                        );
                        await studentController.submitStudentData(student);
                      } finally {
                        await dataController.checkUserAndNavigate(user!.uid);

                        setState(() {
                          _isLoading = false; // Ensure loading state resets
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.tertiary,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : Text(
                            'Submit',
                            style: TextStyle(color: AppColors.accent),
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

  @override
  void dispose() {
    // Dispose controllers when the widget is removed
    firstNameController.dispose();
    lastNameController.dispose();
    super.dispose();
  }
}
