import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Salary Prediction App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SalaryPredictionScreen(),
    );
  }
}

class SalaryPredictionScreen extends StatefulWidget {
  const SalaryPredictionScreen({super.key});

  @override
  State<SalaryPredictionScreen> createState() => _SalaryPredictionScreenState();
}

class _SalaryPredictionScreenState extends State<SalaryPredictionScreen> {
  final TextEditingController ageController = TextEditingController();
  final TextEditingController genderController = TextEditingController();
  final TextEditingController educationLevelController =
      TextEditingController();
  final TextEditingController jobTitleController = TextEditingController();
  final TextEditingController yearsOfExperienceController =
      TextEditingController();

  String? resultMessage;
  bool isError = false;
  bool isLoading = false;

  final List<String> genderOptions = ['Male', 'Female'];
  final List<String> educationLevelOptions = [
    "High School",
    "Bachelor's",
    "Master's",
    "PhD",
  ];

  @override
  void dispose() {
    ageController.dispose();
    genderController.dispose();
    educationLevelController.dispose();
    jobTitleController.dispose();
    yearsOfExperienceController.dispose();
    super.dispose();
  }

  String normalizeEducationLevel(String input) {
    String normalized = input.trim().toLowerCase();

    if (normalized == 'high school' || normalized == 'highschool') {
      return "High School";
    } else if (normalized == 'bachelor' || normalized == "bachelor's") {
      return "Bachelor's";
    } else if (normalized == 'master' || normalized == "master's") {
      return "Master's";
    } else if (normalized == 'phd') {
      return "PhD";
    }
    return input;
  }

  String normalizeGender(String input) {
    String normalized = input.trim().toLowerCase();
    if (normalized == 'male') {
      return 'Male';
    } else if (normalized == 'female') {
      return 'Female';
    }
    return input;
  }

  bool validateInputs() {
    if (ageController.text.isEmpty) {
      setState(() {
        resultMessage = 'Error: Age is required';
        isError = true;
      });
      return false;
    }

    if (genderController.text.isEmpty) {
      setState(() {
        resultMessage = 'Error: Gender is required';
        isError = true;
      });
      return false;
    }

    if (educationLevelController.text.isEmpty) {
      setState(() {
        resultMessage = 'Error: Education Level is required';
        isError = true;
      });
      return false;
    }

    if (jobTitleController.text.isEmpty) {
      setState(() {
        resultMessage = 'Error: Job Title is required';
        isError = true;
      });
      return false;
    }

    if (yearsOfExperienceController.text.isEmpty) {
      setState(() {
        resultMessage = 'Error: Years of Experience is required';
        isError = true;
      });
      return false;
    }

    try {
      int age = int.parse(ageController.text);
      if (age < 18 || age > 80) {
        setState(() {
          resultMessage = 'Error: Age must be between 18 and 80';
          isError = true;
        });
        return false;
      }
    } catch (e) {
      setState(() {
        resultMessage = 'Error: Age must be a valid number';
        isError = true;
      });
      return false;
    }

    try {
      double experience = double.parse(yearsOfExperienceController.text);
      if (experience < 0 || experience > 60) {
        setState(() {
          resultMessage = 'Error: Years of Experience must be between 0 and 60';
          isError = true;
        });
        return false;
      }
    } catch (e) {
      setState(() {
        resultMessage = 'Error: Years of Experience must be a valid number';
        isError = true;
      });
      return false;
    }

    String normalizedGender = normalizeGender(genderController.text);
    if (!genderOptions.contains(normalizedGender)) {
      setState(() {
        resultMessage = 'Error: Gender must be Male or Female';
        isError = true;
      });
      return false;
    }

    String normalizedEducation = normalizeEducationLevel(
      educationLevelController.text,
    );
    if (!educationLevelOptions.contains(normalizedEducation)) {
      setState(() {
        resultMessage =
            'Error: Education Level must be one of: High School, Bachelor\'s, Master\'s, PhD';
        isError = true;
      });
      return false;
    }

    if (jobTitleController.text.length < 1 ||
        jobTitleController.text.length > 100) {
      setState(() {
        resultMessage = 'Error: Job Title must be between 1 and 100 characters';
        isError = true;
      });
      return false;
    }

    return true;
  }

  void makePrediction() async {
    if (!validateInputs()) {
      return;
    }

    setState(() {
      isLoading = true;
      resultMessage = 'Connecting to API...';
      isError = false;
    });

    // TODO: Replace with actual API endpoint when deployed
    // Example: String apiUrl = 'https://your-api.onrender.com/predict';

    String normalizedGender = normalizeGender(genderController.text);
    String normalizedEducation = normalizeEducationLevel(
      educationLevelController.text,
    );

    Map<String, dynamic> predictionData = {
      'age': int.parse(ageController.text),
      'gender': normalizedGender,
      'education_level': normalizedEducation,
      'job_title': jobTitleController.text,
      'years_of_experience': double.parse(yearsOfExperienceController.text),
    };

    // Simulate successful prediction for now
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      isLoading = false;
      // Mock response - replace with actual API response
      double mockPredictedSalary = 75000.50;
      String modelUsed = 'RandomForest';

      resultMessage =
          'Predicted Salary: \$${mockPredictedSalary.toStringAsFixed(2)}\nModel: $modelUsed';
      isError = false;
    });
  }

  void showRetrainingDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Model Retraining'),
          content: const Text(
            'Upload a CSV file to retrain the model with new data.\n\n'
            'CSV must contain columns: age, gender, education_level, job_title, years_of_experience, salary',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement CSV file picker and upload to /retrain/upload endpoint
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('File picker to be implemented'),
                  ),
                );
                Navigator.of(context).pop();
              },
              child: const Text('Upload CSV'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Employee Salary Predictor',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header

            // const SizedBox(height: 8),
            const Text(
              'Enter your information to predict salary',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // Age Input
            TextField(
              controller: ageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Age',
                hintText: 'e.g., 32',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.person),
                helperText: 'Must be between 18 and 80',
              ),
            ),
            const SizedBox(height: 16),

            // Gender Input
            TextField(
              controller: genderController,
              decoration: InputDecoration(
                labelText: 'Gender',
                hintText: 'e.g., Male or Female',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.wc),
                helperText: 'Male or Female (case-insensitive)',
              ),
            ),
            const SizedBox(height: 16),

            // Education Level Input
            TextField(
              controller: educationLevelController,
              decoration: InputDecoration(
                labelText: 'Education Level',
                hintText: 'e.g., Bachelor\'s or Master\'s',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.school),
                helperText: 'High School, Bachelor\'s, Master\'s, or PhD',
              ),
            ),
            const SizedBox(height: 16),

            // Job Title Input
            TextField(
              controller: jobTitleController,
              decoration: InputDecoration(
                labelText: 'Job Title',
                hintText: 'e.g., Data Analyst',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.work),
                helperText: '1-100 characters',
              ),
            ),
            const SizedBox(height: 16),

            // Years of Experience Input
            TextField(
              controller: yearsOfExperienceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Years of Experience',
                hintText: 'e.g., 7',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.timeline),
                helperText: 'Must be between 0 and 60',
              ),
            ),
            const SizedBox(height: 30),

            // Predict Button
            ElevatedButton(
              onPressed: isLoading ? null : makePrediction,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.deepPurple,
                disabledBackgroundColor: Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Predict Salary',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
            const SizedBox(height: 24),

            // Result Display Area
            if (resultMessage != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isError ? Colors.red : Colors.green,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: isError
                      ? Colors.red.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                ),
                child: Text(
                  resultMessage!,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isError ? Colors.red[700] : Colors.green[700],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 20),

            // Retrain Model Button
            OutlinedButton(
              onPressed: showRetrainingDialog,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Colors.deepPurple, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.upload_file, color: Colors.deepPurple),
                  SizedBox(width: 8),
                  Text(
                    'Upload CSV to Retrain Model',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
