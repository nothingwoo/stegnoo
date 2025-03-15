// image_upload_button.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:path/path.dart' as path;

class ImageUploadButton extends StatefulWidget {
  final Function(String imageUrl) onImageUploaded; // Callback to pass the URL

  ImageUploadButton({required this.onImageUploaded});

  @override
  _ImageUploadButtonState createState() => _ImageUploadButtonState();
}

class _ImageUploadButtonState extends State<ImageUploadButton> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAndUploadImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      File file = File(image.path);
      String fileName = path.basename(image.path);

      try {
        firebase_storage.Reference storageRef = firebase_storage
            .FirebaseStorage.instance
            .ref()
            .child('chat_images/$fileName');

        firebase_storage.UploadTask uploadTask = storageRef.putFile(file);

        await uploadTask.whenComplete(() async {
          String imageUrl = await storageRef.getDownloadURL();
          widget.onImageUploaded(imageUrl); // Pass the URL back
        });
      } catch (e) {
        print('Error uploading image: $e');
        // Handle error (e.g., show a snackbar)
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.image),
      onPressed: _pickAndUploadImage,
    );
  }
}
