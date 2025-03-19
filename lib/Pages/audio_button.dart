import 'dart:io';
import 'dart:typed_data'; // Import the typed_data library
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AudioUploadButton extends StatelessWidget {
  final Function(String) onAudioUploaded;

  const AudioUploadButton({super.key, required this.onAudioUploaded});

  Future<void> _uploadAudio(BuildContext context) async {
    try {
      // Pick an audio file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        // Show a loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        // Handle file upload based on platform
        String audioUrl;
        if (kIsWeb) {
          // Web platform: Use bytes
          Uint8List? fileBytes = result.files.single.bytes;
          if (fileBytes == null) {
            throw Exception('Failed to read file bytes');
          }
          String fileName = DateTime.now().millisecondsSinceEpoch.toString();
          Reference storageReference = FirebaseStorage.instance
              .ref()
              .child('audios/$fileName.${result.files.single.extension}');

          UploadTask uploadTask = storageReference.putData(fileBytes);
          TaskSnapshot taskSnapshot = await uploadTask;
          audioUrl = await taskSnapshot.ref.getDownloadURL();
        } else {
          // Mobile platform: Use file path
          String filePath = result.files.single.path!;
          File audioFile = File(filePath);
          String fileName = DateTime.now().millisecondsSinceEpoch.toString();
          Reference storageReference = FirebaseStorage.instance
              .ref()
              .child('audios/$fileName.${audioFile.path.split('.').last}');

          UploadTask uploadTask = storageReference.putFile(audioFile);
          TaskSnapshot taskSnapshot = await uploadTask;
          audioUrl = await taskSnapshot.ref.getDownloadURL();
        }

        // Close the loading indicator
        Navigator.of(context).pop();

        // Pass the audio URL back to the parent widget
        onAudioUploaded(audioUrl);
      } else {
        // User canceled the file picker
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No file selected')),
        );
      }
    } catch (e) {
      // Handle errors
      Navigator.of(context).pop(); // Close the loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload audio: $e')),
      );
      print('Error uploading audio: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => _uploadAudio(context),
      icon: const Icon(Icons.audiotrack, color: Colors.white),
    );
  }
}