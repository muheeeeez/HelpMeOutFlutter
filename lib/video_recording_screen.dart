import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';

class VideoRecordingScreen extends StatefulWidget {
  const VideoRecordingScreen({Key? key}) : super(key: key);

  @override
  _VideoRecordingScreenState createState() => _VideoRecordingScreenState();
}

class _VideoRecordingScreenState extends State<VideoRecordingScreen> {
  CameraController? _controller;
  bool _isRecording = false;
  bool _isInitialized = false;
  String? _videoPath;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  final TextEditingController _titleController = TextEditingController();
  bool _captureAudio = true;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      Fluttertoast.showToast(msg: 'No cameras available');
      return;
    }

    _controller = CameraController(
      cameras[0],
      ResolutionPreset.high,
      enableAudio: _captureAudio,
    );

    try {
      await _controller!.initialize();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to initialize camera: $e');
    }
  }

  Future<void> _startRecording() async {
    if (!_isInitialized || _controller == null) return;

    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String dirPath = '${appDir.path}/Videos';
      await Directory(dirPath).create(recursive: true);
      final String filePath =
          '$dirPath/${DateTime.now().millisecondsSinceEpoch}.mp4';

      await _controller!.startVideoRecording();
      setState(() {
        _isRecording = true;
      });
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to start recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    if (!_isInitialized || _controller == null) return;

    try {
      final XFile video = await _controller!.stopVideoRecording();
      setState(() {
        _isRecording = false;
        _videoPath = video.path;
      });
      _showUploadDialog();
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to stop recording: $e');
    }
  }

  Future<void> _pickVideo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.gallery);

    if (video != null) {
      setState(() {
        _videoPath = video.path;
      });
      _showUploadDialog();
    }
  }

  void _showUploadDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Upload Video'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Video Title',
                    hintText: 'Enter a title for your video',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Capture Audio'),
                    Switch(
                      value: _captureAudio,
                      onChanged: (value) {
                        setState(() {
                          _captureAudio = value;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _uploadVideo();
                },
                child: const Text('Upload'),
              ),
            ],
          ),
    );
  }

  Future<void> _uploadVideo() async {
    if (_videoPath == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Fluttertoast.showToast(msg: 'User not authenticated');
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final fileName = path.basename(_videoPath!);
      final storageRef = FirebaseStorage.instance.ref().child(
        'videos/${user.uid}/$fileName',
      );

      final uploadTask = storageRef.putFile(File(_videoPath!));

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        setState(() {
          _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
        });
      });

      await uploadTask;

      final downloadURL = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('videos')
          .add({
            'videoName':
                _titleController.text.isEmpty
                    ? fileName
                    : _titleController.text,
            'downloadURL': downloadURL,
            'storagePath': 'videos/${user.uid}/$fileName',
            'uploadedAt': FieldValue.serverTimestamp(),
          });

      Fluttertoast.showToast(msg: 'Video uploaded successfully!');
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
        _videoPath = null;
        _titleController.clear();
      });
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to upload video: $e');
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Video'),
        backgroundColor: const Color(0xFF100A42),
      ),
      body: Column(
        children: [
          Expanded(
            child:
                _isInitialized && _controller != null
                    ? CameraPreview(_controller!)
                    : const Center(child: CircularProgressIndicator()),
          ),
          if (_isUploading) LinearProgressIndicator(value: _uploadProgress),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _isRecording ? _stopRecording : _startRecording,
                  icon: Icon(_isRecording ? Icons.stop : Icons.videocam),
                  label: Text(
                    _isRecording ? 'Stop Recording' : 'Start Recording',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF100A42),
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _pickVideo,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload Video'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF100A42),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
