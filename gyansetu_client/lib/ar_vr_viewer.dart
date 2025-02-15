import 'package:flutter/material.dart';

import 'package:model_viewer_plus/model_viewer_plus.dart';

import 'package:just_audio/just_audio.dart';

class ArVrViewer extends StatefulWidget {
  final String modelUrl;

  final String title;

  final String? audioUrl;

  const ArVrViewer({
    Key? key,
    required this.modelUrl,
    required this.title,
    this.audioUrl,
  }) : super(key: key);

  @override
  State<ArVrViewer> createState() => _ArVrViewerState();
}

class _ArVrViewerState extends State<ArVrViewer> {
  bool _isLoading = true;

  late AudioPlayer _audioPlayer;

  bool _isPlaying = false;

  bool _showTooltip = true;

  @override
  void initState() {
    super.initState();

    _audioPlayer = AudioPlayer();

    _setupAudio();

    // Add listener for audio player state changes
    _audioPlayer.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        setState(() {
          _isPlaying = false;
        });
        _audioPlayer.stop(); // Stop the audio completely
        _audioPlayer.seek(Duration.zero); // Reset to beginning
      }
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });

    // Auto-hide tooltip after 5 seconds

    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) {
        setState(() {
          _showTooltip = false;
        });
      }
    });
  }

  Future<void> _setupAudio() async {
    if (widget.audioUrl != null) {
      try {
        await _audioPlayer.setAsset(widget.audioUrl!);
        // Set audio to stop when completed
        await _audioPlayer.setLoopMode(LoopMode.off);
        print('Audio loaded successfully');
      } catch (e) {
        print('Error loading audio: $e');
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _handleAudioToggle() {
    setState(() {
      _showTooltip = false;
      _isPlaying = !_isPlaying;

      if (_isPlaying) {
        _audioPlayer.seek(Duration.zero); // Reset to start before playing
        _audioPlayer.play();
      } else {
        _audioPlayer.pause();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Stack(
        children: [
          ModelViewer(
            src: widget.modelUrl,

            alt: "A 3D model of ${widget.title}",

            ar: true,

            autoRotate: true,

            cameraControls: true,

            loading: Loading.lazy,

            // Performance optimization settings

            shadowIntensity: 0,

            exposure: 0.5,

            minCameraOrbit: "auto auto 10%",

            maxCameraOrbit: "auto auto 100%",

            touchAction: TouchAction.panY,
          ),

          if (_isLoading)
            Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading 3D Model...',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Add audio control button

          if (widget.audioUrl != null && !_isLoading)
            Positioned(
              top: 16,
              left: 16,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      onPressed: _handleAudioToggle,
                    ),
                  ),
                  if (_showTooltip)
                    Positioned(
                      top: 50,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Click here for audio',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
