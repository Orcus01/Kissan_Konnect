import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'diagnosis_detail_page.dart';

class DiagnosisPage extends StatefulWidget {
  @override
  _DiagnosisPageState createState() => _DiagnosisPageState();
}

class _DiagnosisPageState extends State<DiagnosisPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child('diagnoses');
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  List<Map<String, dynamic>> _diagnoses = [];

  @override
  void initState() {
    super.initState();
    if (_userId.isNotEmpty) {
      _loadDiagnoses();
    } else {
      print('User ID is empty, not loading diagnoses.');
    }
  }

  void _loadDiagnoses() {
    print('Current User ID: $_userId'); // Debug print
    _dbRef.onValue.listen((DatabaseEvent event) {
      final snapshot = event.snapshot;
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        print('Data fetched: $data'); // Debug print
        setState(() {
          _diagnoses = data.entries
              .map((e) => Map<String, dynamic>.from(e.value as Map))
              .where((diagnosis) => diagnosis['userId'] == _userId)
              .toList();
          print('Filtered diagnoses: $_diagnoses'); // Debug print
        });
      } else {
        print('No data found');
      }
    }).onError((error) {
      print('Error fetching data: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Saved Diagnoses'),
        backgroundColor: Colors.teal, // Consistent theme color
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: _diagnoses.isEmpty
                  ? Center(
                      child: Text(
                        'No diagnoses found',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    )
                  : Column(
                      children: _diagnoses.map((diagnosis) {
                        final DateTime timestamp = DateTime.fromMillisecondsSinceEpoch(diagnosis['timestamp']);
                        final String formattedDate = DateFormat.yMMMd().add_jm().format(timestamp);

                        return Card(
                          elevation: 5,
                          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.all(16),
                            title: Text(
                              diagnosis['diseaseName'],
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              formattedDate,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DiagnosisDetailPage(
                                    diseaseName: diagnosis['diseaseName'],
                                    imagePath: diagnosis['imagePath'],
                                    cureSteps: List<String>.from(diagnosis['cureSteps']),
                                    formattedDate: formattedDate,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      }).toList(),
                    ),
            ),
          );
        },
      ),
    );
  }
}
