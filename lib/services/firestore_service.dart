import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> saveDiagnosis(String userId, String diagnosis) async {
  await FirebaseFirestore.instance.collection('diagnoses').add({
    'userId': userId,
    'diagnosis': diagnosis,
    'timestamp': FieldValue.serverTimestamp(),
  });
}
