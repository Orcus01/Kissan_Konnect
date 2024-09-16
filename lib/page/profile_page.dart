import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'diagnosis_page.dart'; // Import DiagnosisPage

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _professionController = TextEditingController();
  
  String? profilePictureUrl;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    if (user != null) {
      final userProfile = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      setState(() {
        _nameController.text = userProfile['full_name'] ?? user!.displayName ?? '';
        _phoneController.text = userProfile['phone'] ?? '';
        _professionController.text = userProfile['profession'] ?? '';
        profilePictureUrl = userProfile['profilePictureUrl'];
      });
    }
  }

  Future<void> _updateUserProfile() async {
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'full_name': _nameController.text,
        'phone': _phoneController.text,
        'profession': _professionController.text,
        'profilePictureUrl': profilePictureUrl,
      }, SetOptions(merge: true));

      await user!.updateDisplayName(_nameController.text);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully')),
      );

      setState(() {
        _isEditing = false; // Stop editing mode after saving
      });
    }
  }

  Future<void> _uploadProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // Here, you might want to upload the image to Firebase Storage and get the URL
      // For now, we're using local file path
      setState(() {
        profilePictureUrl = pickedFile.path; // Update with file path for local usage
      });
      await _updateUserProfile();
    }
  }

  void _showImagePickerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Profile Picture'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt, color: Colors.teal),
                title: Text('Take a photo'),
                onTap: () {
                  Navigator.pop(context);
                  _uploadProfilePicture(); // Implement image picker to take a photo
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: Colors.teal),
                title: Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _uploadProfilePicture(); // Implement image picker to choose from gallery
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: Colors.teal, // Consistent theme color
        actions: [
          if (!_isEditing)
            TextButton(
              onPressed: () {
                setState(() {
                  _isEditing = true; // Enter edit mode
                });
              },
              child: Text(
                'Edit Profile',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          if (_isEditing)
            IconButton(
              icon: Icon(Icons.save),
              onPressed: _updateUserProfile,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _isEditing ? _showImagePickerDialog : null,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: profilePictureUrl != null
                    ? FileImage(File(profilePictureUrl!))
                    : null,
                child: profilePictureUrl == null
                    ? Icon(Icons.person, size: 50, color: Colors.grey[600])
                    : null,
                backgroundColor: Colors.grey[200],
                foregroundColor: Colors.teal,
              ),
            ),
            SizedBox(height: 20),
            _buildTextField('Full Name', _nameController, _isEditing),
            SizedBox(height: 10),
            _buildTextField('Email', TextEditingController(text: user?.email ?? 'No email provided'), false),
            SizedBox(height: 10),
            _buildTextField('Phone Number', _phoneController, _isEditing),
            SizedBox(height: 10),
            _buildTextField('Profession', _professionController, _isEditing),
            SizedBox(height: 20),
            Divider(height: 40),
            _buildListTile('My Diagnosis', Icons.history, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DiagnosisPage()), // Navigate to DiagnosisPage
              );
            }),
            _buildListTile('Privacy Options', Icons.lock, () {
              // Navigate to Privacy options
            }),
            _buildListTile('Help and Support', Icons.help, () {
              // Navigate to Help and Support
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, bool isEditing) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[200],
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      enabled: isEditing, // Enable only when in editing mode
    );
  }

  Widget _buildListTile(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      title: Text(title),
      leading: Icon(icon, color: Colors.teal),
      onTap: onTap,
    );
  }
}
