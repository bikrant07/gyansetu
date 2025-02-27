import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:firebase_storage/firebase_storage.dart';

import 'package:flutter/material.dart';

import 'package:gyansetu_client/auth_service.dart';

import 'package:gyansetu_client/login_page.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'dart:io';

import 'package:image_picker/image_picker.dart';

import 'package:path/path.dart' as path;

import 'package:image_cropper/image_cropper.dart';

class ProfilePage extends StatefulWidget {
  final User user;

  final String profileName;

  const ProfilePage({Key? key, required this.user, required this.profileName})
      : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController _nameController;

  late TextEditingController _bioController;

  String? _cachedEmail;

  String? _cachedProfileName;

  Map<String, dynamic>? _cachedLearningProgress;

  bool _isEditing = false;

  bool _isInitialLoad = true;

  bool _isBioLoading = true;

  String? _cachedBio;

  String? _profileImageUrl;

  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;

  Stream<DocumentSnapshot> get _userDataStream => FirebaseFirestore.instance
      .collection('users')
      .doc(widget.user.uid)
      .snapshots();

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.profileName);

    _bioController = TextEditingController();

    _cachedEmail = widget.user.email;

    _cachedProfileName = widget.profileName;

    _loadCachedBio();

    _loadUserData();

    _loadProfileImage();
  }

  Future<void> _loadCachedBio() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final cachedBio = prefs.getString('user_bio_${widget.user.uid}');

      if (cachedBio != null && mounted) {
        setState(() {
          _cachedBio = cachedBio;

          _bioController.text = cachedBio;

          _isBioLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading cached bio: $e');
    }
  }

  Future<void> _loadUserData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .get();

      if (mounted && doc.exists) {
        final bio = doc.data()?['bio'] as String? ?? '';

        await SharedPreferences.getInstance().then((prefs) {
          prefs.setString('user_bio_${widget.user.uid}', bio);
        });

        setState(() {
          _cachedLearningProgress =
              doc.data()?['learningProgress'] as Map<String, dynamic>? ?? {};

          _isInitialLoad = false;

          _isBioLoading = false;
        });
      } else {
        setState(() {
          _isInitialLoad = false;

          _isBioLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');

      setState(() {
        _isInitialLoad = false;

        _isBioLoading = false;
      });
    }
  }

  Future<void> _loadProfileImage() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .get();

      if (mounted && doc.exists) {
        setState(() {
          _profileImageUrl = doc.data()?['profileImageUrl'] as String?;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile image: $e');
    }
  }

  Widget _buildProfileImage() {
    return GestureDetector(
      onTap: _showFullScreenImage,
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: _isLoading
            ? const CircleAvatar(
                radius: 60,
                child: CircularProgressIndicator(),
              )
            : CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white,
                backgroundImage: _profileImageUrl != null
                    ? NetworkImage(_profileImageUrl!)
                    : const AssetImage('assets/images/default_profile.png')
                        as ImageProvider,
              ),
      ),
    );
  }

  Widget _buildProgressSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Learning Progress',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(widget.user.uid)
                .snapshots(),
            builder: (context, snapshot) {
              final data = snapshot.data?.data() as Map<String, dynamic>? ??
                  {'learningProgress': _cachedLearningProgress};

              final learningProgress =
                  data['learningProgress'] as Map<String, dynamic>? ?? {};

              if (learningProgress.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'No quiz attempts yet. Take some quizzes to see your progress!',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              if (snapshot.hasData && mounted) {
                _cachedLearningProgress = learningProgress;
              }

              final sortedEntries = learningProgress.entries.toList()
                ..sort((a, b) {
                  final aTimestamp = (a.value
                      as Map<String, dynamic>)['lastAttempt'] as Timestamp?;

                  final bTimestamp = (b.value
                      as Map<String, dynamic>)['lastAttempt'] as Timestamp?;

                  if (aTimestamp == null || bTimestamp == null) return 0;

                  return bTimestamp.compareTo(aTimestamp);
                });

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedEntries.length,
                itemBuilder: (context, index) {
                  final entry = sortedEntries[index];

                  final subject = entry.key;

                  final progress = entry.value as Map<String, dynamic>;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(
                        subject.replaceAll('_', ' ').toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Last Score: ${progress['lastScore']}/10',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      trailing: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 45,
                            height: 45,
                            child: CircularProgressIndicator(
                              value: (progress['lastPercentage'] as num?) !=
                                      null
                                  ? (progress['lastPercentage'] as num) / 100
                                  : 0,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          Text(
                            '${(progress['lastPercentage'] as num? ?? 0).toInt()}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _updateBio(String newBio) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .update({'bio': newBio});

      await SharedPreferences.getInstance().then((prefs) {
        prefs.setString('user_bio_${widget.user.uid}', newBio);
      });

      if (mounted) {
        setState(() => _isEditing = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isEditing = true);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating bio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildBioSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bio',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        _isBioLoading && _cachedBio == null
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              )
            : TextFormField(
                controller: _bioController,
                minLines: 1,
                maxLines: 5,
                enabled: _isEditing,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: _isEditing
                    ? (_) async {
                        setState(() => _isEditing = false);

                        await _updateBio(_bioController.text.trim());
                      }
                    : null,
                decoration: InputDecoration(
                  hintText: 'Tell us about yourself...',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: _isEditing ? Colors.white : Colors.grey[100],
                  isDense: true,
                ),
              ),
      ],
    );
  }

  Future<void> _uploadProfilePicture() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      if (image == null) return;

      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        cropStyle: CropStyle.circle,
        compressQuality: 80,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Profile Picture',
            toolbarColor: Theme.of(context).colorScheme.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: 'Crop Profile Picture',
            aspectRatioLockEnabled: true,
            minimumAspectRatio: 1.0,
            aspectRatioPickerButtonHidden: true,
          ),
        ],
      );

      if (croppedFile == null) return;

      setState(() {
        _isLoading = true;
      });

      final String fileName =
          '${widget.user.uid}${path.extension(croppedFile.path)}';

      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child(widget.user.uid)
          .child(fileName);

      final UploadTask uploadTask = storageRef.putFile(File(croppedFile.path));

      final TaskSnapshot taskSnapshot = await uploadTask;

      final String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .update({'profileImageUrl': downloadUrl});

      setState(() {
        _profileImageUrl = downloadUrl;

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Column(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        Theme.of(context).colorScheme.primary.withOpacity(0.05),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        _buildProfileImage(),
                        const SizedBox(height: 16),
                        Text(
                          widget.profileName,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.user.email ?? '',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StreamBuilder<DocumentSnapshot>(
                        stream: _userDataStream,
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            final data =
                                snapshot.data?.data() as Map<String, dynamic>?;

                            _bioController.text = data?['bio'] ?? '';

                            return _buildBioSection();
                          }

                          return _buildBioSection();
                        },
                      ),
                      const SizedBox(height: 24),
                      _buildProgressSection(),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                ),
                child: IconButton(
                  icon: Icon(
                    _isEditing ? Icons.save : Icons.edit,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () async {
                    if (_isEditing) {
                      await _updateBio(_bioController.text.trim());

                      setState(() => _isEditing = false);
                    } else {
                      _showEditOptions();
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Change Profile Picture'),
                onTap: () {
                  Navigator.pop(context);
                  _uploadProfilePicture();
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Bio'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _isEditing = true);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logout',
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold)),
                onTap: () async {
                  Navigator.pop(context);
                  await AuthService().signOut();
                  if (mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              LoginPage(authService: AuthService())),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();

    _bioController.dispose();

    super.dispose();
  }

  void _showFullScreenImage() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                        image: DecorationImage(
                          image: _profileImageUrl != null
                              ? NetworkImage(_profileImageUrl!)
                              : const AssetImage(
                                      'assets/images/default_profile.png')
                                  as ImageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: Theme.of(context).colorScheme.primary,
                        size: 30,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  widget.profileName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
