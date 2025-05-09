import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

// Define app colors
const Color primaryColor = Color(0xFF0A2472); // Dark blue
const Color accentColor = Color(0xFF1E88E5); // Lighter blue

class VideoDetailsPage extends StatefulWidget {
  final String url;
  final String name;

  const VideoDetailsPage({Key? key, required this.url, required this.name})
    : super(key: key);

  @override
  State<VideoDetailsPage> createState() => _VideoDetailsPageState();
}

class _VideoDetailsPageState extends State<VideoDetailsPage> {
  late final VideoPlayerController _controller;
  late final Future<void> _initializeVideoPlayerFuture;

  // Transcript language support
  final List<String> _languages = ['English', 'Spanish', 'French', 'German'];
  String? _selectedLanguage;
  final Map<String, String> _transcripts = {
    'English':
        'This is the English transcript of the video showing a step-by-step tutorial about how to use the application features effectively. The narrator explains each feature in detail with clear examples.',
    'Spanish':
        'Este es el transcript en Español del vídeo que muestra un tutorial paso a paso sobre cómo utilizar las funciones de la aplicación de manera efectiva. El narrador explica cada función en detalle con ejemplos claros.',
    'French':
        'Ceci est la transcription en Français de la vidéo montrant un tutoriel étape par étape sur l\'utilisation efficace des fonctionnalités de l\'application. Le narrateur explique chaque fonctionnalité en détail avec des exemples clairs.',
    'German':
        'Dies ist das Transkript auf Deutsch des Videos, das ein Schritt-für-Schritt-Tutorial zur effektiven Nutzung der Anwendungsfunktionen zeigt. Der Erzähler erklärt jede Funktion ausführlich mit klaren Beispielen.',
  };

  // TinyURL support
  String? _shortUrl;
  bool _isGeneratingUrl = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.url);
    _initializeVideoPlayerFuture = _controller.initialize();
    _controller.setLooping(false);
    _selectedLanguage = _languages[0]; // Default to English

    // Automatically generate short URL
    _generateShortUrl();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
  }

  void _copyToClipboard() {
    // Update to copy the short URL if available, or fall back to original URL
    final textToCopy = _shortUrl ?? widget.url;
    Clipboard.setData(ClipboardData(text: textToCopy));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Generate short URL using TinyURL API
  Future<void> _generateShortUrl() async {
    if (_isGeneratingUrl) return; // Prevent multiple concurrent calls

    setState(() {
      _isGeneratingUrl = true;
    });

    try {
      // Make API call to TinyURL
      final response = await http.post(
        Uri.parse(
          'https://tinyurl.com/api-create.php?url=${Uri.encodeComponent(widget.url)}',
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          _shortUrl = response.body;
          _isGeneratingUrl = false;
        });
      } else {
        throw Exception('Failed to generate short URL');
      }
    } catch (e) {
      print('Error generating short URL: $e');
      setState(() {
        _isGeneratingUrl = false;
      });
      // Don't show error snackbar as this is automatic
    }
  }

  void _shareVia(String platform) {
    // This would be implemented with actual sharing functionality
    // using packages like share_plus or platform-specific sharing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing via $platform coming soon'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              _showShareOptions(context);
            },
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video container with gradient background
            Container(
              color: primaryColor.withOpacity(0.9),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16.0,
                      right: 16.0,
                      top: 16.0,
                      bottom: 8.0,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Home / ${widget.name}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Video player
                  FutureBuilder<void>(
                    future: _initializeVideoPlayerFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        return AspectRatio(
                          aspectRatio: _controller.value.aspectRatio,
                          child: VideoPlayer(_controller),
                        );
                      } else {
                        return const SizedBox(
                          height: 200,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        );
                      }
                    },
                  ),

                  // Video controls
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () {
                            // Rewind 10 seconds
                            final currentPosition = _controller.value.position;
                            final newPosition =
                                currentPosition - const Duration(seconds: 10);
                            _controller.seekTo(newPosition);
                          },
                          icon: const Icon(
                            Icons.replay_10,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        FloatingActionButton(
                          backgroundColor: Colors.white,
                          onPressed: _togglePlayPause,
                          child: Icon(
                            _controller.value.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: primaryColor,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          onPressed: () {
                            // Forward 10 seconds
                            final currentPosition = _controller.value.position;
                            final newPosition =
                                currentPosition + const Duration(seconds: 10);
                            _controller.seekTo(newPosition);
                          },
                          icon: const Icon(
                            Icons.forward_10,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Progress indicator
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: VideoProgressIndicator(
                      _controller,
                      allowScrubbing: true,
                      colors: const VideoProgressColors(
                        playedColor: Colors.white,
                        bufferedColor: Colors.white30,
                        backgroundColor: Colors.white10,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Share section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Share Video',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 16),

                  // Remove original URL display and replace with only short URL section
                  // Short URL section (now the only URL section)
                  Container(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: const Text(
                      'Share Link',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child:
                            _shortUrl != null
                                ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _shortUrl!,
                                          style: TextStyle(
                                            color: Colors.grey.shade800,
                                            fontSize: 14,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.copy,
                                          color: primaryColor,
                                        ),
                                        onPressed: _copyToClipboard,
                                        tooltip: 'Copy Link',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                )
                                : Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: primaryColor,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Generating share link...',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Share via',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),

                  const SizedBox(height: 12),

                  // Share options
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ShareOption(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        color: Colors.red,
                        onTap: () => _shareVia('Email'),
                      ),
                      _ShareOption(
                        icon: Icons.message,
                        label: 'WhatsApp',
                        color: Colors.green.shade600,
                        onTap: () => _shareVia('WhatsApp'),
                      ),
                      _ShareOption(
                        icon: Icons.send,
                        label: 'Telegram',
                        color: Colors.blue,
                        onTap: () => _shareVia('Telegram'),
                      ),
                      _ShareOption(
                        icon: Icons.thumb_up,
                        label: 'Facebook',
                        color: Colors.indigo,
                        onTap: () => _shareVia('Facebook'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(thickness: 1),

            // Transcript section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Video Transcript',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 16),

                  // Language dropdown with custom styling
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedLanguage,
                        hint: const Text('Select language'),
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          color: primaryColor,
                        ),
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                        ),
                        items:
                            _languages.map((lang) {
                              return DropdownMenuItem<String>(
                                value: lang,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.language,
                                      size: 20,
                                      color: primaryColor.withOpacity(0.7),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(lang),
                                  ],
                                ),
                              );
                            }).toList(),
                        onChanged: (lang) {
                          setState(() {
                            _selectedLanguage = lang;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Transcript display
                  Container(
                    padding: const EdgeInsets.all(16),
                    width: double.infinity,
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
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.subject, color: primaryColor, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              _selectedLanguage != null
                                  ? '$_selectedLanguage Transcript'
                                  : 'Transcript',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedLanguage != null
                              ? _transcripts[_selectedLanguage!]!
                              : 'Please select a language to see the transcript.',
                          style: const TextStyle(fontSize: 16, height: 1.5),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showShareOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Share Video',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ShareOption(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    color: Colors.red,
                    onTap: () {
                      Navigator.pop(context);
                      _shareVia('Email');
                    },
                  ),
                  _ShareOption(
                    icon: Icons.message,
                    label: 'WhatsApp',
                    color: Colors.green.shade600,
                    onTap: () {
                      Navigator.pop(context);
                      _shareVia('WhatsApp');
                    },
                  ),
                  _ShareOption(
                    icon: Icons.send,
                    label: 'Telegram',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      _shareVia('Telegram');
                    },
                  ),
                  _ShareOption(
                    icon: Icons.thumb_up,
                    label: 'Facebook',
                    color: Colors.indigo,
                    onTap: () {
                      Navigator.pop(context);
                      _shareVia('Facebook');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.link, color: primaryColor),
                title: const Text('Copy Link'),
                onTap: () {
                  Navigator.pop(context);
                  _copyToClipboard();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(10),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
