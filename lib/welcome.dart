import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import your AuthService and LoginScreen:
import 'Authentication/login.dart';
import 'video-details-page.dart';
import 'package:helpmeout_flutter/Authentication//auth_service.dart';
import 'upload_video_screen.dart';
import 'legal/legal_center.dart';

import 'Widgets/VideoCard.dart';

// Define app colors
const Color primaryColor = Color(0xFF0A2472); // Dark blue
const Color accentColor = Color(0xFF1E88E5); // Lighter blue
const Color backgroundColor = Color(0xFFF5F7FA); // Light background

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HelpMeOut',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: primaryColor,
        scaffoldBackgroundColor: backgroundColor,
      ),
      home: const WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _searchController = TextEditingController();
  final AuthService _authService = AuthService();
  String firstName = '';
  String lastName = '';
  List<Map<String, dynamic>> _videos = [];
  List<Map<String, dynamic>> _filtVideos = [];

  String uid = '';
  final User? user = FirebaseAuth.instance.currentUser;

  // your items list...

  @override
  void initState() {
    super.initState();
    _checkUserAndLoadData();
  }

  Future<void> _checkUserAndLoadData() async {
    // Check if user is logged in
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      // If not logged in, redirect to login page
      Navigator.of(context).pushReplacementNamed('/login');
      return;
    }

    // User is logged in, load data
    setState(() {
      uid = currentUser.uid;
    });

    await _loadAndFetch();
  }

  Future<void> _loadAndFetch() async {
    await _fetchUserData();
    final videos = await fetchVideos(uid);

    if (mounted) {
      setState(() {
        _videos = videos;
        _filtVideos = videos;
      });
    }
  }

  Future<void> _fetchUserData() async {
    if (user != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .get();
      if (doc.exists) {
        setState(() {
          firstName = doc['firstName'];
          lastName = doc['lastName'];
          uid = user!.uid;
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> fetchVideos(String uid) async {
    final List<Map<String, dynamic>> videoList = [];

    try {
      // Fetch videos from Firestore instead of Storage
      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('videos')
              .orderBy('uploadedAt', descending: true)
              .get();

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Get download URL and other metadata
        final String name = data['videoName'] ?? 'Unnamed Video';
        final String url = data['downloadURL'] ?? '';
        final Timestamp? uploadTime = data['uploadedAt'] as Timestamp?;
        final DateTime? createdAt = uploadTime?.toDate();

        videoList.add({
          'name': name,
          'url': url,
          'createdAt': createdAt,
          'id': doc.id, // Store document ID for deletion
          'storagePath': data['storagePath'],
        });
      }

      print('Fetched ${videoList.length} videos from Firestore');
    } catch (e) {
      print("Error fetching videos from Firestore: $e");
    }

    return videoList;
  }

  Future<void> _deleteVideo(int index) async {
    final vid = _filtVideos[index];
    final name = vid['name'] as String;
    final String? docId = vid['id'] as String?;
    final String? storagePath = vid['storagePath'] as String?;

    try {
      // Delete from Storage
      if (storagePath != null) {
        final storageRef = FirebaseStorage.instance.ref().child(storagePath);
        await storageRef.delete();
      } else {
        // Fallback to old method if storagePath is not available
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('videos')
            .child(uid)
            .child(name);
        await storageRef.delete();
      }

      // Delete from Firestore
      if (docId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('videos')
            .doc(docId)
            .delete();
      }

      await _loadAndFetch();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Deleted "$name"')));
    } catch (e) {
      print('Error deleting video: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete "$name": ${e.toString()}')),
      );
    }
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Confirm Logout'),
            content: const Text('Are you sure you want to log out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (shouldLogout == true) {
      await _authService.signOut();
      // Replace with your actual login screen navigation:
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const login()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            Image.asset('images/logo.png', width: 32, height: 32),
            const SizedBox(width: 8),
            const Text(
              'HelpMeOut',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, size: 22),
            color: primaryColor,
            tooltip: 'Legal Information',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LegalCenterScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 22),
            color: primaryColor,
            tooltip: 'Logout',
            onPressed: _confirmLogout,
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome section
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, $firstName $lastName',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Here are your recorded videos',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.videocam_rounded),
                        label: const Text('Start Recording'),
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: const Text(
                        "Or",
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Upload Video'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const UploadVideoScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: primaryColor,
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: primaryColor),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Search bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search your videos...',
                    prefixIcon: const Icon(Icons.search, color: primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: primaryColor),
                    ),
                  ),
                  onChanged: (query) {
                    final lower = query.toLowerCase();
                    setState(() {
                      _filtVideos =
                          _videos.where((vid) {
                            final name = (vid['name']).toLowerCase();
                            return name.contains(lower);
                          }).toList();
                    });
                  },
                ),

                const SizedBox(height: 24),

                // Recent files section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Recent Videos",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text("Refresh"),
                            onPressed: _loadAndFetch,
                            style: TextButton.styleFrom(
                              foregroundColor: primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _filtVideos.isEmpty
                          ? const Center(child: Text('No videos yet'))
                          : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _filtVideos.length,
                            itemBuilder: (ctx, i) {
                              final vid = _filtVideos[i];
                              final name = vid['name']!;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: VideoCard(
                                  videoUrl: vid['url']!,
                                  fileName: vid['name']!,
                                  availableDate: vid['createdAt'] as DateTime,
                                  onViewDetails: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => VideoDetailsPage(
                                              url: vid['url']!,
                                              name: vid['name']!,
                                            ),
                                      ),
                                    );
                                  },
                                  onDelete: () async {
                                    final bool?
                                    didConfirm = await showDialog<bool>(
                                      context: context,
                                      builder: (BuildContext dialogContext) {
                                        return AlertDialog(
                                          title: const Text('Delete Video'),
                                          content: Text(
                                            'Are you sure you want to delete "$name"?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(
                                                  dialogContext,
                                                ).pop(false);
                                              },
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(
                                                  dialogContext,
                                                ).pop(true);
                                              },
                                              child: const Text(
                                                'Delete',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );

                                    if (didConfirm == true) {
                                      await _deleteVideo(i);
                                    }
                                  },
                                ),
                              );
                            },
                          ),

                      // Video card
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
