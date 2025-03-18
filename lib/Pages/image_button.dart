import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:path/path.dart' as path;
import 'dart:typed_data';
import 'package:mime/mime.dart'; // Import mime package

class ImageUploadButton extends StatefulWidget {
  final Function(String imageUrl) onImageUploaded;

  const ImageUploadButton({Key? key, required this.onImageUploaded})
      : super(key: key);

  @override
  _ImageUploadButtonState createState() => _ImageUploadButtonState();
}

class _ImageUploadButtonState extends State<ImageUploadButton> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() => _isUploading = true);

        String fileName = path.basename(image.path);
        firebase_storage.Reference storageRef = firebase_storage
            .FirebaseStorage.instance
            .ref()
            .child('chat_images/$fileName');

        firebase_storage.UploadTask uploadTask;

        // Determine MIME type
        String? mimeType = lookupMimeType(fileName);

        // Set metadata with content type
        firebase_storage.SettableMetadata metadata =
            firebase_storage.SettableMetadata(
                contentType: mimeType ?? 'image/png');

        if (kIsWeb) {
          Uint8List bytes = await image.readAsBytes();
          uploadTask =
              storageRef.putData(bytes, metadata); // Upload with metadata
        } else {
          File file = File(image.path);
          uploadTask =
              storageRef.putFile(file, metadata); // Upload with metadata
        }

        await uploadTask.whenComplete(() async {
          String imageUrl = await storageRef.getDownloadURL();
          print('Fresh URL: $imageUrl');

          widget.onImageUploaded(imageUrl);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded successfully!')),
        );
      }
    } catch (e) {
      print('Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.image),
          onPressed: _pickAndUploadImage,
        ),
        if (_isUploading) const CircularProgressIndicator(),
      ],
    );
  }
}
