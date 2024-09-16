import 'package:flutter/material.dart';
import 'diagnosis_detail_page.dart'; // Ensure correct path
import 'package:intl/intl.dart';


class SampleDiagnosisDetailPage extends StatelessWidget {
  const SampleDiagnosisDetailPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Sample data for testing
    final String diseaseName = 'Powdery Mildew';
    final String imagePath = 'https://example.com/sample_image.jpg'; // Use a URL or correct file path
    final List<String> cureSteps = [
      'Remove infected leaves immediately.',
      'Avoid overhead watering to prevent spreading spores.',
      'Apply fungicide if the disease is severe.',
    ];
    final String formattedDate = DateFormat('MMMM d, yyyy – h:mm a').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sample Diagnosis Detail'),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DiagnosisDetailPage(
                  diseaseName: diseaseName,
                  imagePath: imagePath,
                  cureSteps: cureSteps,
                  formattedDate: formattedDate,
                ),
              ),
            );
          },
          child: const Text('Show Sample Diagnosis'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }
}
