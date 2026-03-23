import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class BatchPredictionScreen extends StatefulWidget {
  const BatchPredictionScreen({super.key});

  @override
  State<BatchPredictionScreen> createState() => _BatchPredictionScreenState();
}

class _BatchPredictionScreenState extends State<BatchPredictionScreen> {
  final List<Map<String, dynamic>> _employeeList = [];
  bool _isLoading = false;

  // Controllers for the current entry being added
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();

  // Dropdown values
  String? _selectedGender;
  String? _selectedEducation;

  final List<String> _genderOptions = ['Male', 'Female'];
  final List<String> _educationLevelOptions = [
    "High School",
    "Bachelor's",
    "Master's",
    "PhD",
  ];

  @override
  void dispose() {
    _ageController.dispose();
    _jobTitleController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  void _addEmployee() {
    if (!_validateInputs()) return;

    setState(() {
      _employeeList.add({
        'age': int.parse(_ageController.text),
        'gender': _selectedGender,
        'education_level': _selectedEducation,
        'job_title': _jobTitleController.text,
        'years_of_experience': double.parse(_experienceController.text),
      });

      // Clear inputs
      _ageController.clear();
      _jobTitleController.clear();
      _experienceController.clear();
      _selectedGender = null;
      _selectedEducation = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Employee added to batch'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }

  void _removeEmployee(int index) {
    setState(() {
      _employeeList.removeAt(index);
    });
  }

  bool _validateInputs() {
    if (_ageController.text.isEmpty ||
        _selectedGender == null ||
        _selectedEducation == null ||
        _jobTitleController.text.isEmpty ||
        _experienceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill all fields'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> _makeBatchPrediction() async {
    if (_employeeList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one employee')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final apiUrl = 'https://salary-api-o99n.onrender.com/predict/batch';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'predictions': _employeeList}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _showBatchResults(data);
      } else {
        _showErrorDialog('Error: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorDialog('Connection error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error', style: TextStyle(color: Colors.red)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showBatchResults(Map<String, dynamic> data) {
    final predictions = data['predictions'] as List;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: double.maxFinite,
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.checklist, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'Batch Results',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  shrinkWrap: true,
                  itemCount: predictions.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final prediction = predictions[index];
                    final employee = _employeeList[index];
                    final salary = (prediction['predicted_salary'] as num)
                        .toDouble();

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: CircleAvatar(
                          backgroundColor: Colors.deepPurple.shade100,
                          child: Icon(
                            Icons.person,
                            color: Colors.deepPurple.shade700,
                          ),
                        ),
                        title: Text(
                          employee['job_title'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              '${employee['age']} yrs • ${employee['gender']}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            Text(
                              '${employee['education_level']} • ${employee['years_of_experience']}y exp',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Text(
                            '\$${salary.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.deepPurple.shade300),
      labelStyle: TextStyle(color: Colors.grey[700]),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey[50],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Batch Prediction',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'New Employee Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration('Age', Icons.cake),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _experienceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: _inputDecoration(
                          'Exp (Yrs)',
                          Icons.work_history,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedGender,
                        items: _genderOptions
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _selectedGender = v!),
                        decoration: _inputDecoration('Gender', Icons.wc),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedEducation,
                        items: _educationLevelOptions
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text(
                                  e,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedEducation = v!),
                        decoration: _inputDecoration('Degree', Icons.school),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _jobTitleController,
                  decoration: _inputDecoration('Job Title', Icons.badge),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _addEmployee,
                  icon: const Icon(Icons.add_circle, color: Colors.white),
                  label: const Text(
                    'Add to Batch',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          Expanded(
            child: _employeeList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.group_add,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No employees added yet',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Fill the form above to add to the list',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 80),
                    itemCount: _employeeList.length,
                    itemBuilder: (context, index) {
                      final item = _employeeList[index];
                      return Dismissible(
                        key: Key(UniqueKey().toString()),
                        onDismissed: (_) => _removeEmployee(index),
                        background: Container(
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Icon(Icons.delete, color: Colors.red.shade700),
                        ),
                        direction: DismissDirection.endToStart,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: Colors.deepPurple.shade50,
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.deepPurple,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              item['job_title'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${item['age']} yrs • ${item['gender']} • ${item['years_of_experience']} exp',
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                color: Colors.grey,
                              ),
                              onPressed: () => _removeEmployee(index),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _employeeList.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _isLoading ? null : _makeBatchPrediction,
              backgroundColor: _isLoading
                  ? Colors.grey
                  : Colors.deepPurpleAccent,
              icon: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.auto_awesome, color: Colors.white),
              label: Text(
                _isLoading
                    ? 'Processing...'
                    : 'Predict ${_employeeList.length} Salaries',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }
}
