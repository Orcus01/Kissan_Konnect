import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final DatabaseReference _messageRef = FirebaseDatabase.instance.ref().child('chats');
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Community Chat'),
        backgroundColor: Colors.teal,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Back button should navigate to the homepage
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: StreamBuilder(
                stream: _messageRef.onValue,
                builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                  if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                    return Center(child: Text('No messages yet.'));
                  }

                  Map data = snapshot.data!.snapshot.value as Map;
                  List messages = data.values.toList();
                  messages.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

                  return ListView.builder(
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message['uid'] == _auth.currentUser!.uid;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        child: Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.teal[200] : Colors.grey[200],
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                if (message.containsKey('imageUrl') && message['imageUrl'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: Image.network(
                                        message['imageUrl'],
                                        height: 200,
                                        width: MediaQuery.of(context).size.width * 0.6,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                if (message.containsKey('fileUrl') && message['fileUrl'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Text(
                                      'File: ${message['fileName']}',
                                      style: TextStyle(color: Colors.blueAccent, fontSize: 16),
                                    ),
                                  ),
                                if (message['text'] != null)
                                  Text(
                                    message['text'] ?? '',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                SizedBox(height: 5),
                                Text(
                                  message['senderName'],
                                  style: TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.attach_file),
                  color: Colors.teal,
                  onPressed: _attachFile,
                ),
                IconButton(
                  icon: Icon(Icons.camera_alt),
                  color: Colors.teal,
                  onPressed: _attachImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Enter your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      fillColor: Colors.grey[200],
                      filled: true,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send),
                  color: Colors.teal,
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }

  void _sendMessage({String? imageUrl, String? fileUrl, String? fileName}) {
    if (_messageController.text.isEmpty && imageUrl == null && fileUrl == null) return;

    final message = {
      'text': _messageController.text.isNotEmpty ? _messageController.text : null,
      'senderName': _auth.currentUser!.displayName ?? 'Anonymous',
      'uid': _auth.currentUser!.uid,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'imageUrl': imageUrl,
      'fileUrl': fileUrl,
      'fileName': fileName,
    };

    _messageRef.push().set(message);
    _messageController.clear();
  }

  Future<void> _attachImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      String imageUrl = await _uploadFile(File(image.path));
      if (imageUrl.isNotEmpty) {
        _sendMessage(imageUrl: imageUrl);
      }
    }
  }

  Future<void> _attachFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single != null) {
      File file = File(result.files.single.path!);
      String fileName = result.files.single.name;
      String fileUrl = await _uploadFile(file);
      if (fileUrl.isNotEmpty) {
        _sendMessage(fileUrl: fileUrl, fileName: fileName);
      }
    }
  }

  Future<String> _uploadFile(File file) async {
    try {
      String fileName = file.path.split('/').last;
      Reference ref = FirebaseStorage.instance.ref().child('chat_uploads/$fileName');
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading file: $e');
      return '';
    }
  }
}
