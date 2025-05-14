import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

// Import your AuthService and LoginScreen:
import 'Authentication/login.dart';
import 'video-details-page.dart';
import 'Authentication/auth_service.dart';
import 'upload_video_screen.dart';
import 'legal/legal_center.dart';

import 'Widgets/VideoCard.dart';

// Define app colors
const Color primaryColor = Color(0xFF0A2472); // Dark blue
const Color accentColor = Color(0xFF1E88E5); // Lighter blue
const Color backgroundColor = Color(0xFFF5F7FA); // Light background

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
  bool _isLoading = true;
  bool _isRefreshing = false;

  String uid = '';
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    // Delay user check to avoid blocking UI rendering
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUserAndLoadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkUserAndLoadData() async {
    // Check if user is logged in
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      // If not logged in, redirect to login page
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
      return;
    }

    // User is logged in, load data
    setState(() {
      uid = currentUser.uid;
    });

    await _loadAndFetch();
  }

  Future<void> _loadAndFetch() async {
    if (_isRefreshing) return;

    setState(() {
      _isLoading = true;
      _isRefreshing = true;
    });

    try {
      await _fetchUserData();
      final videos = await fetchVideos(uid);

      if (mounted) {
        setState(() {
          _videos = videos;
          _filtVideos = videos;
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _fetchUserData() async {
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (doc.exists && mounted) {
        setState(() {
          firstName = doc['firstName'] ?? '';
          lastName = doc['lastName'] ?? '';
          uid = user!.uid;
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchVideos(String uid) async {
    final List<Map<String, dynamic>> videoList = [];

    try {
      // Fetch videos from Firestore with a limit to improve performance
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('videos')
          .orderBy('uploadedAt', descending: true)
          .limit(50) // Limit the number of videos to improve performance
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

    // Show confirmation dialog
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    // If user cancels or dismisses the dialog
    if (shouldDelete != true) {
      return;
    }

    try {
      // Delete from Storage
      if (storagePath != null) {
        final storageRef = FirebaseStorage.instance.ref().child(storagePath);
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Deleted "$name"')));
      }
    } catch (e) {
      print('Error deleting video: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete "$name": ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
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
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const login()),
          (route) => false,
        );
      }
    }
  }

  void _filterVideos(String query) {
    if (!mounted) return;

    // Use a post-frame callback to avoid doing filtering work during build
    Future.microtask(() {
      if (mounted) {
        setState(() {
          if (query.isEmpty) {
            _filtVideos = _videos;
          } else {
            _filtVideos = _videos
                .where(
                  (video) => video['name'].toString().toLowerCase().contains(
                        query.toLowerCase(),
                      ),
                )
                .toList();
          }
        });
      }
    });
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
            icon: const Icon(Icons.refresh, size: 22),
            color: primaryColor,
            tooltip: 'Refresh Videos',
            onPressed: _isRefreshing
                ? null
                : () {
                    _loadAndFetch().then((_) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Videos refreshed'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    });
                  },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, size: 22),
            color: primaryColor,
            tooltip: 'Legal Information',
            onPressed: () => Navigator.pushNamed(context, '/legal'),
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: primaryColor),
            )
          : SafeArea(
              child: RefreshIndicator(
                onRefresh: _loadAndFetch,
                color: primaryColor,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
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
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Action buttons
                            Container(
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
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.videocam_rounded,
                                    size: 48,
                                    color: primaryColor,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Record or Upload Video',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Share your screen or upload a video to get help',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      // Screen Recording Button (Coming Soon)
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          icon: const Icon(Icons.record_voice_over),
                                          label: const Text('Start Recording'),
                                          onPressed: null,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: primaryColor,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Upload Video Button (Working)
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          icon: const Icon(Icons.upload_file),
                                          label: const Text('Upload Video'),
                                          onPressed: () {
                                            print(
                                              "Opening upload video screen...",
                                            );
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const UploadVideoScreen(),
                                              ),
                                            ).then((_) {
                                              print(
                                                "Returned from upload screen, refreshing...",
                                              );
                                              _loadAndFetch();
                                            });
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: primaryColor,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Search field
                            TextField(
                              controller: _searchController,
                              onChanged: _filterVideos,
                              decoration: InputDecoration(
                                hintText: 'Search videos...',
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: Colors.grey,
                                ),
                                fillColor: Colors.white,
                                filled: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 16,
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Section title - Your videos
                            _filtVideos.isEmpty
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(32.0),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.videocam_off,
                                            size: 48,
                                            color: Colors.grey,
                                          ),
                                          SizedBox(height: 16),
                                          Text(
                                            'No videos found',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Upload your first video to get started',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : const Padding(
                                    padding: EdgeInsets.only(bottom: 12.0),
                                    child: Text(
                                      'Your Videos',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),

                    // Video list
                    _filtVideos.isEmpty
                        ? SliverToBoxAdapter(child: Container())
                        : SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final video = _filtVideos[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                child: VideoCard(
                                  videoUrl: video['url'],
                                  fileName: video['name'],
                                  availableDate:
                                      video['createdAt'] ?? DateTime.now(),
                                  onViewDetails: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => VideoDetailsPage(
                                          url: video['url'],
                                          name: video['name'],
                                        ),
                                      ),
                                    );
                                  },
                                  onDelete: () => _deleteVideo(index),
                                ),
                              );
                            }, childCount: _filtVideos.length),
                          ),

                    SliverPadding(padding: const EdgeInsets.only(bottom: 24)),
                  ],
                ),
              ),
            ),
    );
  }
}
