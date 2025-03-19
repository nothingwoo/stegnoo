import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioPlayerPage extends StatefulWidget {
  final String audioUrl;

  const AudioPlayerPage({super.key, required this.audioUrl});

  @override
  State<AudioPlayerPage> createState() => _AudioPlayerPageState();
}

class _AudioPlayerPageState extends State<AudioPlayerPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _playAudio() async {
    try {
      setState(() {
        _isLoading = true;
      });

      int result = await _audioPlayer.play(widget.audioUrl);

      if (result == 1) { // Success
        setState(() {
          _isPlaying = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to play audio: $e')),
      );
      print('Error playing audio: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pauseAudio() async {
    int result = await _audioPlayer.pause();
    if (result == 1) { // Success
      setState(() {
        _isPlaying = false;
      });
    }
  }

  Future<void> _stopAudio() async {
    int result = await _audioPlayer.stop();
    if (result == 1) { // Success
      setState(() {
        _isPlaying = false;
      });
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Player'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              const CircularProgressIndicator()
            else
              IconButton(
                onPressed: _isPlaying ? _pauseAudio : _playAudio,
                icon: Icon(
                  _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                  size: 70,
                  color: Colors.blue,
                ),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _stopAudio,
              child: const Text('Stop'),
            ),
          ],
        ),
      ),
    );
  }
}
