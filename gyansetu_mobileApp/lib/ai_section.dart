import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:http/http.dart' as http;

import 'package:flutter_markdown/flutter_markdown.dart';

import 'package:flutter_image_compress/flutter_image_compress.dart';

class AiSectionPage extends StatefulWidget {
  const AiSectionPage({super.key});

  @override
  _AiSectionPageState createState() => _AiSectionPageState();
}

class _AiSectionPageState extends State<AiSectionPage>
    with WidgetsBindingObserver {
  final _controller = TextEditingController();

  final FocusNode _focusNode = FocusNode();

  final List<Map<String, dynamic>> _messages = [];

  final String _apiKey = 'AIzaSyDs3vEPT17sggs2fYBuVYsB-wEeNNfmXnw';

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  String? _selectedImageIndicator;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _controller.dispose();

    _focusNode.dispose();

    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      // Ensure keyboard is dismissed when app becomes inactive

      _focusNode.unfocus();
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _selectedImageIndicator = 'Image selected';
        
        // Set focus to text field after image selection
        _focusNode.requestFocus();
      });
    }
  }

  void _showQueryInputSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Ask something about this image...',
                  ),
                  onSubmitted: (query) {
                    Navigator.pop(context);
                    _sendMessage(query, hasImage: true);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendMessage(String message, {bool hasImage = false}) async {
    if (message.isEmpty) return;

    setState(() {
      _messages.add({
        'sender': 'user',
        'text': message,
        'isLoading': false,
        'image': _selectedImage?.path,
      });

      _messages.add({
        'sender': 'model',
        'text': '',
        'isLoading': true,
      });
    });

    try {
      String? base64Image;
      if (_selectedImage != null) {
        try {
          List<int> imageBytes = await _compressImage(_selectedImage!);
          base64Image = base64Encode(imageBytes);
          
          // Verify base64 string isn't too large (max 20MB)
          if (base64Image.length > 20 * 1024 * 1024) {
            throw Exception('Image too large after compression');
          }
        } catch (e) {
          print('Error processing image: $e');
          setState(() {
            _messages.removeLast();
            _messages.add({
              'sender': 'model',
              'text': 'Sorry, the image is too large or in an unsupported format. Please try a different image.',
              'isLoading': false,
            });
          });
          return;
        }
      }

      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey',
      );

      final headers = {
        'Content-Type': 'application/json',
      };

      // Build conversation history
      List<Map<String, dynamic>> parts = [];
      
      // Add previous messages to maintain context (last 5 messages)
      for (var msg in _messages.reversed.take(5).toList().reversed) {
        if (!msg['isLoading']) {
          if (msg['image'] != null) {
            parts.add({
              "role": msg['sender'] == 'ai' ? 'model' : msg['sender'],
              "parts": [
                {
                  "inline_data": {
                    "mime_type": "image/jpeg",
                    "data": base64Encode(File(msg['image']).readAsBytesSync())
                  }
                },
                {"text": msg['text']}
              ]
            });
          } else {
            parts.add({
              "role": msg['sender'] == 'ai' ? 'model' : msg['sender'],
              "parts": [{"text": msg['text']}]
            });
          }
        }
      }

      // Prepare the request body based on whether there's an image
      final body = _selectedImage != null
          ? jsonEncode({
              "contents": [
                {
                  "role": "user",
                  "parts": [
                    {
                      "inline_data": {
                        "mime_type": "image/jpeg",
                        "data": base64Image
                      }
                    },
                    {
                      "text": message
                    }
                  ]
                }
              ]
            })
          : jsonEncode({
              "contents": parts + [
                {
                  "role": "user",
                  "parts": [
                    {"text": message}
                  ]
                }
              ]
            });

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');  // For debugging

      setState(() {
        _messages.removeLast();
      });

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData != null &&
            responseData['candidates'] != null &&
            responseData['candidates'].isNotEmpty) {
          final candidate = responseData['candidates'][0];

          if (candidate['content'] != null &&
              candidate['content']['parts'] != null &&
              candidate['content']['parts'].isNotEmpty) {
            final aiResponse = candidate['content']['parts'][0]['text'];

            setState(() {
              _messages.add({
                'sender': 'model',
                'text': aiResponse ?? 'Sorry, no response from AI.',
                'isLoading': false,
              });
            });

            return;
          }
        }

        setState(() {
          _messages.add({
            'sender': 'model',
            'text':
                'I apologize, but I could not process that request. Please try again.',
            'isLoading': false,
          });
        });
      } else {
        setState(() {
          _messages.add({
            'sender': 'model',
            'text': 'Error: Failed to get response',
            'isLoading': false,
          });
        });
      }
    } catch (error) {
      setState(() {
        _messages.removeLast();

        _messages.add({
          'sender': 'model',
          'text':
              'Sorry, there was an error processing your request. Please try again.',
          'isLoading': false,
        });
      });
    } finally {
      if (hasImage) {
        setState(() {
          _selectedImage = null;
        });
      }
    }
  }

  Future<List<int>> _compressImage(File file) async {
    try {
      Uint8List bytes = await file.readAsBytes();
      // Always compress images to ensure consistent size and format
      final resized = await FlutterImageCompress.compressWithList(
        bytes,
        minHeight: 1024,  // Increased size for better quality
        minWidth: 1024,   // Increased size for better quality
        quality: 85,      // Better quality
        format: CompressFormat.jpeg, // Ensure JPEG format
      );
      
      // Ensure the image isn't too large (max 4MB)
      if (resized.length > 4 * 1024 * 1024) {
        // Compress again with lower quality if still too large
        return await FlutterImageCompress.compressWithList(
          resized,
          minHeight: 800,
          minWidth: 800,
          quality: 70,
          format: CompressFormat.jpeg,
        );
      }
      return resized;
    } catch (e) {
      print('Error compressing image: $e');
      // Return original bytes if compression fails
      return file.readAsBytesSync();
    }
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Thinking...',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Ensure keyboard is dismissed when navigating back

        _focusNode.unfocus();

        return true;
      },
      child: GestureDetector(
        onTap: () {
          // Dismiss keyboard when tapping outside

          _focusNode.unfocus();

          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (ctx, index) {
                    final message = _messages[index];

                    if (message['isLoading'] == true) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: _buildLoadingIndicator(),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Align(
                        alignment: message['sender'] == 'user'
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: message['sender'] == 'user'
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context)
                                    .colorScheme
                                    .secondary
                                    .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (message['image'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxHeight: 200,  // Maximum height for the image
                                        maxWidth: MediaQuery.of(context).size.width * 0.6,  // 60% of screen width
                                      ),
                                      child: Image.file(
                                        File(message['image']),
                                        fit: BoxFit.contain,  // This will maintain aspect ratio
                                      ),
                                    ),
                                  ),
                                ),
                              message['sender'] == 'user'
                                  ? Text(
                                      message['text'] ?? '',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    )
                                  : MarkdownBody(
                                      data: message['text'] ?? '',
                                      styleSheet: MarkdownStyleSheet(
                                        p: TextStyle(
                                          color: Colors.black87,
                                          fontSize: 16,
                                        ),
                                        strong: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        h1: TextStyle(
                                          color:
                                              Theme.of(context).colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        h2: TextStyle(
                                          color:
                                              Theme.of(context).colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        h3: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        listBullet: TextStyle(
                                          color:
                                              Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    if (_selectedImage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.image,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Image selected',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.photo),
                          onPressed: _showImagePickerOptions,
                        ),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            onTapOutside: (_) {
                              _focusNode.unfocus();
                              FocusScope.of(context).unfocus();
                            },
                            onEditingComplete: () {
                              _focusNode.unfocus();
                              final message = _controller.text.trim();
                              if (message.isNotEmpty) {
                                _sendMessage(message);
                                _controller.clear();
                              }
                            },
                            decoration: InputDecoration(
                              hintText: 'Ask your query...',
                              hintStyle: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            maxLines: null,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (value) {
                              if (value.trim().isNotEmpty) {
                                _sendMessage(value, hasImage: _selectedImage != null);
                                _controller.clear();
                                setState(() {
                                  _selectedImageIndicator = null;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 36,
                          width: 36,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.send,
                                color: Colors.white,
                                size: 18,
                              ),
                              onPressed: () {
                                final message = _controller.text.trim();
                                if (message.isNotEmpty) {
                                  _sendMessage(message, hasImage: _selectedImage != null);
                                  _controller.clear();
                                  setState(() {
                                    _selectedImageIndicator = null;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
