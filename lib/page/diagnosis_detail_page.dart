import 'package:flutter/material.dart';
import 'dart:io';
import 'package:intl/intl.dart'; // For formatting date and time

class DiagnosisDetailPage extends StatelessWidget {
  final String diseaseName;
  final String imagePath;
  final List<String> cureSteps;
  final String formattedDate;

  const DiagnosisDetailPage({
    Key? key,
    required this.diseaseName,
    required this.imagePath,
    required this.cureSteps,
    required this.formattedDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnosis Details'),
        backgroundColor: Colors.teal,
      ),
      body: Theme(
        data: ThemeData(
          primarySwatch: Colors.teal,
          textTheme: const TextTheme(
            headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            bodyLarge: TextStyle(fontSize: 16),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    diseaseName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.teal,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    formattedDate,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: constraints.maxWidth > 600
                        ? Image.network(
                            imagePath,
                            fit: BoxFit.cover,
                            height: 350,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 350,
                                color: Colors.grey[300],
                                child: const Center(
                                    child: Text('Image not available')),
                              );
                            },
                          )
                        : Image.network(
                            imagePath,
                            fit: BoxFit.cover,
                            height: 250,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 250,
                                color: Colors.grey[300],
                                child: const Center(
                                    child: Text('Image not available')),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Steps for Cure:',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.teal,
                        ),
                  ),
                  const SizedBox(height: 10),
                  ...cureSteps.map((step) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          step,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      )),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
