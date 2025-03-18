import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:path/path.dart' as path;
import 'dart:typed_data';
import 'package:mime/mime.dart'; // Import mime package

class VideoUploadButton extends StatefulWidget {
  final Function(String videoUrl) onVideoUploaded;

  const VideoUploadButton({Key? key, required this.onVideoUploaded})
      : super(key: key);

  @override
  _VideoUploadButtonState createState() => _VideoUploadButtonState();
}

class _VideoUploadButtonState extends State<VideoUploadButton> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  Future<void> _pickAndUploadVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 2), // Limit video duration
      );

      if (video != null) {
        setState(() => _isUploading = true);

        String fileName = path.basename(video.path);
        firebase_storage.Reference storageRef = firebase_storage
            .FirebaseStorage.instance
            .ref()
            .child('chat_videos/$fileName');

        firebase_storage.UploadTask uploadTask;

        // Determine MIME type
        String? mimeType = lookupMimeType(fileName);

        // Set metadata with content type
        firebase_storage.SettableMetadata metadata =
        firebase_storage.SettableMetadata(
            contentType: mimeType ?? 'video/mp4');

        if (kIsWeb) {
          Uint8List bytes = await video.readAsBytes();
          uploadTask = storageRef.putData(bytes, metadata); // Upload with metadata
        } else {
          File file = File(video.path);
          uploadTask = storageRef.putFile(file, metadata); // Upload with metadata
        }

        // Monitor upload progress
        uploadTask.snapshotEvents.listen((firebase_storage.TaskSnapshot snapshot) {
          setState(() {
            _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
          });
        });

        await uploadTask.whenComplete(() async {
          String videoUrl = await storageRef.getDownloadURL();
          print('Video URL: $videoUrl');

          widget.onVideoUploaded(videoUrl);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video uploaded successfully!')),
        );
      }
    } catch (e) {
      print('Error uploading video: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading video: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.videocam),
          onPressed: _isUploading ? null : _pickAndUploadVideo,
          tooltip: 'Upload Video',
        ),
        if (_isUploading)
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              value: _uploadProgress,
              strokeWidth: 2,
            ),
          ),
      ],
    );
  }
}