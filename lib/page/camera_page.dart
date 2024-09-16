import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'output_page.dart';
import 'dart:io';

class CameraPage extends StatefulWidget {
  final bool openCameraOnLoad;

  CameraPage({required this.openCameraOnLoad});

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final ImagePicker _picker = ImagePicker();
  List<XFile> _galleryImages = [];

  @override
  void initState() {
    super.initState();
    if (widget.openCameraOnLoad) {
      _takePhoto();
    }
  }

  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _galleryImages.add(photo);
      });
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OutputPage(
            imagePath: photo.path,
          ),
        ),
      );
    }
  }

  Future<void> _uploadPhoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.gallery);
    if (photo != null) {
      setState(() {
        _galleryImages.add(photo);
      });
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OutputPage(
            imagePath: photo.path,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Thumbnail gallery
          Positioned(
            bottom: 150,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _galleryImages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Image.file(
                      File(_galleryImages[index].path),
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ),
          ),
          // Capture Button
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _takePhoto,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
          // Video and Photo buttons
          Positioned(
            bottom: 30,
            left: 20,
            child: TextButton(
              onPressed: () {
                // Handle Video button press
              },
              child: Text(
                'Video',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            right: 20,
            child: TextButton(
              onPressed: () {
                // Handle Photo button press
              },
              child: Text(
                'Photo',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          // Cancel and Switch Camera buttons
          Positioned(
            top: 20,
            left: 10,
            child: IconButton(
              icon: Icon(Icons.close, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          Positioned(
            top: 20,
            right: 10,
            child: IconButton(
              icon: Icon(Icons.flip_camera_android, color: Colors.white),
              onPressed: () {
                // Handle switch camera
              },
            ),
          ),
        ],
      ),
    );
  }
}
