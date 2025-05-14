import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

// Define app colors
const Color primaryColor = Color(0xFF0A2472); // Dark blue
const Color accentColor = Color(0xFF1E88E5); // Lighter blue
const Color backgroundColor = Color(0xFFF5F7FA); // Light background

class UploadVideoScreen extends StatefulWidget {
  const UploadVideoScreen({Key? key}) : super(key: key);

  @override
  State<UploadVideoScreen> createState() => _UploadVideoScreenState();
}

class _UploadVideoScreenState extends State<UploadVideoScreen> {
  File? _selectedFile;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _fileName = '';
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _selectFile() async {
    try {
      final XFile? pickedFile = await _picker.pickVideo(
        source: ImageSource.gallery,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedFile = File(pickedFile.path);
          _fileName = path.basename(pickedFile.path);
          // Pre-populate the title field with the filename (without extension)
          _titleController.text = _fileName.split('.').first;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting video: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a video file first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      print("Form validation failed");
      return;
    }

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("Error: User is not logged in");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to upload videos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print("Starting upload process for: ${_fileName}");
    print("User ID: ${user.uid}");

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      // Get custom title
      final String videoTitle = _titleController.text.trim();
      print("Video title: $videoTitle");

      // Create a more clean filename by replacing spaces with underscores
      final String cleanFileName =
          videoTitle.replaceAll(' ', '_') + path.extension(_fileName);
      print("Clean filename: $cleanFileName");

      // Define storage path
      final String videoStoragePath = 'videos/${user.uid}/$cleanFileName';
      print("Storage path: $videoStoragePath");

      // Verify file exists and is readable
      if (!await _selectedFile!.exists()) {
        print("Error: File does not exist at path: ${_selectedFile!.path}");
        throw Exception("Selected file does not exist");
      }

      print(
        "File size: ${(_selectedFile!.lengthSync() / 1024 / 1024).toStringAsFixed(2)} MB",
      );

      // Create a temporary copy of the file to prevent platform channel errors
      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath = '${tempDir.path}/$cleanFileName';
      final File tempFile = await _selectedFile!.copy(tempPath);
      print("Created temporary file at: $tempPath");

      // Get FirebaseStorage instance
      final storageRef = FirebaseStorage.instance.ref().child(videoStoragePath);

      // Create upload task with the temporary file
      print("Creating upload task...");
      final uploadTask = storageRef.putFile(
        tempFile,
        SettableMetadata(
            contentType:
                'video/${path.extension(_fileName).replaceAll('.', '')}'),
      );

      // Listen for progress updates
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        setState(() {
          _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
        });
        print(
          "Upload progress: ${(_uploadProgress * 100).toStringAsFixed(0)}%",
        );
      });

      // Wait for upload to complete
      print("Waiting for upload to complete...");
      await uploadTask;
      print("Upload completed successfully");

      // Delete temporary file
      if (await tempFile.exists()) {
        await tempFile.delete();
        print("Deleted temporary file");
      }

      // Get download URL
      print("Getting download URL...");
      final String downloadURL = await storageRef.getDownloadURL();
      print("Download URL: $downloadURL");

      // Store metadata in Firestore
      print("Storing metadata in Firestore...");
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('videos')
          .add({
        'videoName': videoTitle,
        'downloadURL': downloadURL,
        'storagePath': videoStoragePath,
        'uploadedAt': FieldValue.serverTimestamp(),
        'fileSize': _selectedFile!.lengthSync(),
      });
      print("Metadata stored in Firestore successfully");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video uploaded successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _selectedFile = null;
        _fileName = '';
        _titleController.clear();
      });

      // Return to the previous screen after successful upload
      print("Upload process completed, returning to previous screen");
      Navigator.pop(context);
    } catch (e) {
      print("Error during upload process: $e");
      print("Stack trace: ${StackTrace.current}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading video: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('images/logo.png', width: 32, height: 32),
            const SizedBox(width: 8),
            const Text('Upload Video'),
          ],
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                const Text(
                  'Upload a New Video',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Choose a video file from your device to upload',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 24),

                // Video title field
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Video Title',
                    hintText: 'Enter a title for your video',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title for your video';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Selected file card
                if (_selectedFile != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.video_file, color: accentColor),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _fileName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${(_selectedFile!.lengthSync() / 1024 / 1024).toStringAsFixed(2)} MB',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  _selectedFile = null;
                                  _fileName = '';
                                });
                              },
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                if (_selectedFile == null)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: _selectFile,
                            borderRadius: BorderRadius.circular(60),
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.upload_file,
                                  size: 64,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Tap to select a video',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Upload progress
                if (_isUploading)
                  Column(
                    children: [
                      const SizedBox(height: 24),
                      LinearProgressIndicator(
                        value: _uploadProgress,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Uploading... ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(color: primaryColor),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),

                const Spacer(),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.attach_file),
                        label: const Text('Select File'),
                        onPressed: _isUploading ? null : _selectFile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: primaryColor),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.cloud_upload),
                        label: const Text('Upload File'),
                        onPressed: _isUploading ? null : _uploadFile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
