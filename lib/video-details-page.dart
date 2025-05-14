import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:assemblyai_flutter_sdk/assemblyai_flutter_sdk.dart';
import 'dart:convert';
import 'dart:math' as math;

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

  // Language mapping with AssemblyAI codes
  final List<Map<String, String>> _languageOptions = [
    {'name': 'English', 'code': 'en'},
    {'name': 'French', 'code': 'fr'},
    {'name': 'Spanish', 'code': 'es'},
    {'name': 'German', 'code': 'de'},
    {'name': 'Italian', 'code': 'it'},
    {'name': 'Portuguese', 'code': 'pt'},
    {'name': 'Dutch', 'code': 'nl'},
  ];

  // Selected language code (default to English)
  String _selectedLanguageCode = 'en';

  // Get the selected language map from code
  Map<String, String> get _selectedLanguage {
    return _languageOptions.firstWhere(
      (lang) => lang['code'] == _selectedLanguageCode,
      orElse: () => {'name': 'English', 'code': 'en'},
    );
  }

  // Cache for transcripts by language code
  final Map<String, String> _transcripts = {};

  // TinyURL support
  String? _shortUrl;
  bool _isGeneratingUrl = false;

  // AssemblyAI transcript state
  String? _assemblyTranscript;
  bool _isLoadingTranscript = false;
  String _transcriptStatus = "Not started";
  bool _hasTranscriptError = false;
  String? _transcriptId;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.url);
    _initializeVideoPlayerFuture = _controller.initialize();
    _controller.setLooping(false);
    _generateShortUrl();
    _fetchAssemblyTranscript(); // Fetch transcript in default language
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

  // Add new method to fetch AssemblyAI transcript in selected language
  Future<void> _fetchAssemblyTranscript() async {
    setState(() {
      _isLoadingTranscript = true;
      _hasTranscriptError = false;
      _transcriptStatus = "Submitting transcription...";
    });

    // If we already have a cached transcript for this language, use it
    if (_transcripts.containsKey(_selectedLanguageCode) &&
        _transcripts[_selectedLanguageCode]!.isNotEmpty) {
      setState(() {
        _assemblyTranscript = _transcripts[_selectedLanguageCode];
        _isLoadingTranscript = false;
        _transcriptStatus = "Completed";
      });
      return;
    }

    final api = AssemblyAI('1bcd183ffc084379bf81a5ed0c65e5a5');
    try {
      print(
        'Submitting URL for transcription in ${_selectedLanguage['name']}: ${widget.url}',
      );

      // Debug print all the parameters we're sending
      print(
        'AssemblyAI parameters: {' +
            'audio_url: ${widget.url}, ' +
            'language_code: ${_selectedLanguageCode}, ' +
            'punctuate: true, ' +
            'format_text: true}',
      );

      // Submit the transcription in the selected language
      final transcript = await api.submitTranscription({
        'audio_url': widget.url,
        'language_code': _selectedLanguageCode,
        'punctuate': true,
        'format_text': true,
      });

      // Get the ID from the transcript
      final String? id = transcript.id;
      _transcriptId = id;
      print(
        'Received transcript ID: $id for language: ${_selectedLanguage['name']}',
      );

      if (id == null) {
        throw Exception('Failed to get transcript ID');
      }

      // Poll for results until the transcription is completed
      int attempts = 0;
      const maxAttempts = 20; // Maximum polling attempts (about 1 minute)

      while (attempts < maxAttempts) {
        setState(() {
          _transcriptStatus =
              "Processing transcript... (${attempts + 1}/$maxAttempts)";
        });

        print('Polling attempt ${attempts + 1} for transcript ID: $id');
        final polledTranscript = await api.getTranscription(id);
        final status = polledTranscript.status;
        print(
          'Transcript status: $status for language: ${_selectedLanguage['name']}',
        );

        if (status == 'completed') {
          final transcriptText =
              polledTranscript.text ?? 'No transcript available.';
          print(
            'Transcript completed in ${_selectedLanguage['name']}: ${transcriptText.substring(0, math.min(100, transcriptText.length))}...',
          );

          // Store the transcript in the cache
          _transcripts[_selectedLanguageCode] = transcriptText;

          setState(() {
            _assemblyTranscript = transcriptText;
            _isLoadingTranscript = false;
            _transcriptStatus = "Completed";
            _hasTranscriptError = false;
          });
          break;
        } else if (status == 'error') {
          throw Exception('Transcription failed: ${polledTranscript.error}');
        } else {
          // Still processing, wait and check again
          attempts++;
          await Future.delayed(const Duration(seconds: 3));
        }
      }

      if (attempts >= maxAttempts) {
        print('Transcript polling timed out after $maxAttempts attempts');
        setState(() {
          _assemblyTranscript =
              "Transcription is taking longer than expected. Please try again later.";
          _isLoadingTranscript = false;
          _transcriptStatus = "Timeout";
          _hasTranscriptError = true;
        });
      }
    } catch (e) {
      print('Error fetching transcript: $e');

      String errorMessage = 'Failed to fetch transcript: $e';

      // Provide more helpful error messages for common issues
      if (e.toString().contains('Unauthorized') ||
          e.toString().contains('401')) {
        errorMessage =
            'API Key Error: Please check that your AssemblyAI API key is valid and activated.';
      } else if (e.toString().contains('audio_url')) {
        errorMessage =
            'Audio URL Error: The URL provided is not accessible or not in a supported format.';
      } else if (e.toString().contains('language_code')) {
        errorMessage =
            'Language Code Error: The language code is not valid or not supported.';
      }

      setState(() {
        _assemblyTranscript = errorMessage;
        _isLoadingTranscript = false;
        _transcriptStatus = "Error";
        _hasTranscriptError = true;
      });
    }
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: _selectedLanguageCode,
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
                                      _languageOptions.map((lang) {
                                        return DropdownMenuItem<String>(
                                          value: lang['code'],
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.language,
                                                size: 20,
                                                color: primaryColor.withOpacity(
                                                  0.7,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(lang['name']!),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                  onChanged: (code) {
                                    if (code != null &&
                                        code != _selectedLanguageCode) {
                                      setState(() {
                                        _selectedLanguageCode = code;
                                      });
                                      // Fetch transcript in the new language
                                      _fetchAssemblyTranscript();
                                    }
                                  },
                                ),
                              ),
                            ),
                            if (_isLoadingTranscript)
                              Container(
                                margin: const EdgeInsets.only(left: 8.0),
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: primaryColor,
                                ),
                              ),
                          ],
                        ),
                      ],
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.subject,
                                  color: primaryColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${_selectedLanguage['name']} Transcript',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            if (_isLoadingTranscript)
                              Row(
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: primaryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Loading...',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Error with retry button
                        if (_hasTranscriptError)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Error loading transcript in ${_selectedLanguage['name']}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red.shade800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _assemblyTranscript ??
                                      'An error occurred while processing your request.',
                                  style: TextStyle(color: Colors.red.shade700),
                                ),
                                if (_assemblyTranscript != null &&
                                    _assemblyTranscript!.contains(
                                      "API Key Error",
                                    ))
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      "Tip: You can create/verify your API key at app.assemblyai.com",
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: _fetchAssemblyTranscript,
                                  icon: const Icon(Icons.refresh, size: 18),
                                  label: const Text('Retry'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    textStyle: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Text(
                            _isLoadingTranscript
                                ? 'Loading transcript in ${_selectedLanguage['name']}... $_transcriptStatus'
                                : (_assemblyTranscript ??
                                    'No transcript available for ${_selectedLanguage['name']}'),
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
