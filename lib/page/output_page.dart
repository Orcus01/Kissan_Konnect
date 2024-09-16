import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io'; // Only for mobile
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:math';

class OutputPage extends StatelessWidget {
  final String imagePath;
  final String diseaseName;
  final List<String> cureSteps;

  OutputPage({
    required this.imagePath,
    this.diseaseName = 'Disease Name',
    this.cureSteps = const ['Step 1', 'Step 2', 'Step 3'],
  });

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child('diagnoses');
  final List<Map<String, String>> _sampleDiseases = [
    {
      'name': 'Powdery Mildew',
      'cure': '1. Apply fungicide.\n2. Remove affected leaves.\n3. Ensure good air circulation.'
    },
  ];

  // Get a random sample disease
  Map<String, String> _getRandomSampleDisease() {
    final random = Random();
    return _sampleDiseases[random.nextInt(_sampleDiseases.length)];
  }

  // Save diagnosis to Firebase
  Future<void> _saveDiagnosis(BuildContext context) async {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
    print('Attempting to save diagnosis for User ID: $userId'); // Debug print
    if (userId.isNotEmpty) {
      final newDiagnosisRef = _dbRef.push();
      final diagnosisData = {
        'diseaseName': diseaseName,
        'imagePath': imagePath,
        'userId': userId,
        'cureSteps': cureSteps,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      print('Diagnosis data: $diagnosisData'); // Debug print
      newDiagnosisRef.set(diagnosisData).then((_) {
        print('Diagnosis saved successfully to path: ${newDiagnosisRef.key}');
      }).catchError((error) {
        print('Error saving diagnosis: $error');
      });
    } else {
      print('User ID is empty, cannot save diagnosis.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final sampleDisease = _getRandomSampleDisease();

    return Scaffold(
      appBar: AppBar(
        title: Text('Diagnosis Result'),
        backgroundColor: Colors.teal, // Match the theme color
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    sampleDisease['name'] ?? 'Disease Name',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.teal,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  kIsWeb
                      ? Image.network(
                          imagePath, // Use the URL to the image
                          fit: BoxFit.cover,
                          height: constraints.maxWidth > 600 ? 300 : 200, // Responsive height
                          width: double.infinity,
                        )
                      : Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.teal, width: 4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(imagePath),
                              fit: BoxFit.cover,
                              height: constraints.maxWidth > 600 ? 300 : 200, // Responsive height
                              width: double.infinity,
                            ),
                          ),
                        ),
                  SizedBox(height: 20),
                  Text(
                    'Steps for Cure:',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    sampleDisease['cure'] ?? 'No cure available',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _saveDiagnosis(context),
                    child: Text('Save Diagnosis'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
