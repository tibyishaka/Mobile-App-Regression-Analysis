import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'batch_prediction_screen.dart';

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
  final TextEditingController jobTitleController = TextEditingController();
  final TextEditingController yearsOfExperienceController =
      TextEditingController();

  String? selectedGender;
  String? selectedEducation;

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
    jobTitleController.dispose();
    yearsOfExperienceController.dispose();
    super.dispose();
  }

  bool validateInputs() {
    if (ageController.text.isEmpty) {
      setState(() {
        resultMessage = 'Error: Age is required';
        isError = true;
      });
      return false;
    }

    if (selectedGender == null) {
      setState(() {
        resultMessage = 'Error: Gender is required';
        isError = true;
      });
      return false;
    }

    if (selectedEducation == null) {
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

  Future<Map<String, dynamic>> _predictSalaryApiCall() async {
    final apiUrl = 'https://salary-api-o99n.onrender.com/predict';

    Map<String, dynamic> predictionData = {
      'age': int.parse(ageController.text),
      'gender': selectedGender,
      'education_level': selectedEducation,
      'job_title': jobTitleController.text,
      'years_of_experience': double.parse(yearsOfExperienceController.text),
    };

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(predictionData),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error: ${response.statusCode}\n${response.body}');
    }
  }

  void makePrediction() {
    if (!validateInputs()) {
      return;
    }

    // Clear previous validation messages
    setState(() {
      resultMessage = null;
    });

    final predictionFuture = _predictSalaryApiCall();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return FutureBuilder<Map<String, dynamic>>(
          future: predictionFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.deepPurple),
                      SizedBox(height: 20),
                      Text(
                        "Predicting salary...",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            } else if (snapshot.hasError) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.redAccent,
                        size: 50,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Prediction Failed',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        snapshot.error.toString().replaceAll('Exception: ', ''),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Close'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            } else {
              final data = snapshot.data!;
              final predictedSalary = data['predicted_salary'];
              final formattedSalary =
                  "\$${(predictedSalary as num).toStringAsFixed(2)}";

              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
                backgroundColor: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10.0,
                        offset: Offset(0.0, 10.0),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.monetization_on,
                          color: Colors.deepPurple,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Estimated Salary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        formattedSalary,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black54,
                              height: 1.5,
                              fontFamily: 'Roboto', // Default flutter font
                            ),
                            children: [
                              const TextSpan(
                                text: "Based on the profile of a ",
                              ),
                              TextSpan(
                                text: "${ageController.text} year old ",
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(
                                text: "${selectedGender ?? 'N/A'} ",
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(
                                text: "${jobTitleController.text}",
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const TextSpan(text: " with "),
                              TextSpan(
                                text:
                                    "${yearsOfExperienceController.text} years",
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const TextSpan(text: " of experience and a "),
                              TextSpan(
                                text: "${selectedEducation ?? 'N/A'}",
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const TextSpan(text: " degree."),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Cool, Thanks!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          },
        );
      },
    );
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Salary Prediction',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Enter Employee Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Age Input
                    TextFormField(
                      controller: ageController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Age',
                        hintText: 'e.g., 32',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.person),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Gender Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedGender,
                      decoration: InputDecoration(
                        labelText: 'Gender',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.wc),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      items: genderOptions.map((String gender) {
                        return DropdownMenuItem<String>(
                          value: gender,
                          child: Text(gender),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedGender = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Education Level Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedEducation,
                      decoration: InputDecoration(
                        labelText: 'Education Level',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.school),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      items: educationLevelOptions.map((String education) {
                        return DropdownMenuItem<String>(
                          value: education,
                          child: Text(education),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedEducation = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Job Title Input
                    TextFormField(
                      controller: jobTitleController,
                      decoration: InputDecoration(
                        labelText: 'Job Title',
                        hintText: 'e.g., Data Analyst',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.work),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Years of Experience Input
                    TextFormField(
                      controller: yearsOfExperienceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Years of Experience',
                        hintText: 'e.g., 7',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.timeline),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Predict Button
                    ElevatedButton(
                      onPressed: isLoading ? null : makePrediction,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Predict Salary',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),

                    if (resultMessage != null && isError) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                resultMessage!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Retrain Button
            OutlinedButton.icon(
              onPressed: showRetrainingDialog,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Colors.deepPurple, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.upload_file, color: Colors.deepPurple),
              label: const Text(
                'Upload CSV to Retrain Model',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Batch Prediction Button
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BatchPredictionScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.white,
                foregroundColor: Colors.deepPurple,
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.deepPurple.withOpacity(0.5)),
                ),
              ),
              icon: const Icon(Icons.people_alt_outlined),
              label: const Text(
                'Batch Prediction',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
