import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'helpers/quiz_data.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'services/quiz_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:firebase_storage/firebase_storage.dart';

class MaterialsPage extends StatefulWidget {
  @override
  _MaterialsPageState createState() => _MaterialsPageState();
}

class _MaterialsPageState extends State<MaterialsPage> {
  String _selectedClass = 'Class 6'; // Default selected class

  final List<String> _classes = [
    'Class 6',
    'Class 7',
    'Class 8',
    'Class 9',
    'Class 10',
    'Miscellaneous',
  ];

  // Define subjects for each class

  final Map<String, List<SubjectInfo>> _classSubjects = {
    'Class 6': [
      SubjectInfo('Mathematics', Icons.calculate, Colors.blue, [
        'Numbers and Operations',
        'Basic Algebra',
        'Geometry',
        'Data Handling',
      ]),
      SubjectInfo('Science', Icons.science, Colors.green, [
        'Living World',
        'Materials',
        'The Earth',
        'Natural Phenomena',
      ]),
      SubjectInfo('English', Icons.menu_book, Colors.orange, [
        'Grammar',
        'Literature',
        'Writing',
        'Reading Comprehension',
      ]),
      SubjectInfo('Social Studies', Icons.public, Colors.purple, [
        'History',
        'Geography',
        'Civics',
        'Economics',
      ]),
      SubjectInfo('Computer', Icons.computer, Colors.indigo, [
        'Basic Computing',
        'Word Processing',
        'Internet Basics',
        'Digital Safety',
      ]),
      SubjectInfo('Geography', Icons.terrain, Colors.teal, [
        'Maps and Globes',
        'Landforms',
        'Climate',
        'Natural Resources',
      ]),
    ],
    'Class 7': [
      SubjectInfo('Mathematics', Icons.calculate, Colors.blue, [
        'Integers',
        'Fractions and Decimals',
        'Algebra',
        'Geometry and Mensuration',
      ]),
      SubjectInfo('Science', Icons.science, Colors.green, [
        'Living Systems',
        'Matter and Chemical Changes',
        'Physical Phenomena',
        'Environment',
      ]),
      SubjectInfo('English', Icons.menu_book, Colors.orange, [
        'Advanced Grammar',
        'Creative Writing',
        'Literature Analysis',
        'Comprehension Skills',
      ]),
      SubjectInfo('Social Studies', Icons.public, Colors.purple, [
        'Medieval History',
        'Democracy',
        'Geography',
        'Social Issues',
      ]),
      SubjectInfo('Computer', Icons.computer, Colors.indigo, [
        'Programming Basics',
        'Spreadsheets',
        'Digital Communication',
        'Cyber Security',
      ]),
      SubjectInfo('Geography', Icons.terrain, Colors.teal, [
        'Environment',
        'Human Settlements',
        'Natural Resources',
        'Weather and Climate',
      ]),
    ],
    'Class 8': [
      SubjectInfo('Mathematics', Icons.calculate, Colors.blue, [
        'Quadratic Equations',
        'Linear Equations',
        'Geometry',
        'Data Analysis',
      ]),
      SubjectInfo('Science', Icons.science, Colors.green, [
        'Cell Structure',
        'Chemical Reactions',
        'Force and Pressure',
        'Energy',
      ]),
      SubjectInfo('English', Icons.menu_book, Colors.orange, [
        'Advanced Literature',
        'Essay Writing',
        'Speech and Debate',
        'Critical Analysis',
      ]),
      SubjectInfo('Social Studies', Icons.public, Colors.purple, [
        'Modern History',
        'Constitution',
        'Economics',
        'World Geography',
      ]),
      SubjectInfo('Computer', Icons.computer, Colors.indigo, [
        'Web Development',
        'Database Concepts',
        'Digital Design',
        'Network Basics',
      ]),
      SubjectInfo('Geography', Icons.terrain, Colors.teal, [
        'Physical Geography',
        'Population',
        'Industries',
        'Environmental Conservation',
      ]),
    ],
    'Class 9': [
      SubjectInfo('Mathematics', Icons.calculate, Colors.blue, [
        'Number Systems',
        'Polynomials',
        'Coordinate Geometry',
        'Statistics',
      ]),
      SubjectInfo('Science', Icons.science, Colors.green, [
        'Matter',
        'Life Processes',
        'Motion',
        'Natural Resources',
      ]),
      SubjectInfo('English', Icons.menu_book, Colors.orange, [
        'Literature and Poetry',
        'Writing Skills',
        'Grammar',
        'Communication Skills',
      ]),
      SubjectInfo('Social Studies', Icons.public, Colors.purple, [
        'Contemporary India',
        'Democratic Politics',
        'Economics',
        'Disaster Management',
      ]),
      SubjectInfo('Computer', Icons.computer, Colors.indigo, [
        'Programming',
        'Data Structures',
        'Web Technologies',
        'Computer Networks',
      ]),
      SubjectInfo('Geography', Icons.terrain, Colors.teal, [
        'Contemporary India',
        'Climate',
        'Natural Vegetation',
        'Population',
      ]),
    ],
    'Class 10': [
      SubjectInfo('Mathematics', Icons.calculate, Colors.blue, [
        'Real Numbers',
        'Polynomials',
        'Trigonometry',
        'Statistics and Probability',
      ]),
      SubjectInfo('Science', Icons.science, Colors.green, [
        'Chemical Reactions',
        'Life Processes',
        'Electricity',
        'Environmental Issues',
      ]),
      SubjectInfo('English', Icons.menu_book, Colors.orange, [
        'Advanced Literature',
        'Writing Applications',
        'Grammar and Usage',
        'Reading Skills',
      ]),
      SubjectInfo('Social Studies', Icons.public, Colors.purple, [
        'India and Contemporary World',
        'Democratic Politics',
        'Economics Development',
        'Resource Management',
      ]),
      SubjectInfo('Computer', Icons.computer, Colors.indigo, [
        'Advanced Programming',
        'Database Management',
        'Cyber Ethics',
        'Mobile Computing',
      ]),
      SubjectInfo('Geography', Icons.terrain, Colors.teal, [
        'Resources and Development',
        'Agriculture',
        'Manufacturing Industries',
        'Lifelines of Economy',
      ]),
    ],
    'Miscellaneous': [
      SubjectInfo('Languages', Icons.code, Colors.deepPurple, [
        'Java',
        'Python',
        'Others',
      ]),
      SubjectInfo('Technology', Icons.computer_outlined, Colors.teal, [
        'Basics of AI',
        'Basics of Cloud Computing',
        'Others',
      ]),
    ],
  };

  bool _isDownloading = false;

  Future<void> _downloadMaterial(String fileUrl) async {
    if (fileUrl.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Download URL not available'),
            backgroundColor: Colors.red,
          ),
        );
      }

      return;
    }

    setState(() => _isDownloading = true);

    try {
      // Ensure the URL is properly formatted

      String sanitizedUrl = fileUrl.trim();

      if (!sanitizedUrl.startsWith('http://') &&
          !sanitizedUrl.startsWith('https://')) {
        sanitizedUrl = 'https://$sanitizedUrl';
      }

      final Uri url = Uri.parse(sanitizedUrl);

      if (!await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
        webViewConfiguration: const WebViewConfiguration(
          enableJavaScript: true,
          enableDomStorage: true,
        ),
      )) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open: $sanitizedUrl'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error launching URL: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accessing file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)?.studyMaterials ??
              "Study Materials"),
          backgroundColor: Theme.of(context).colorScheme.primary,
          bottom: TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 14,
            ),
            tabs: [
              Tab(
                icon: Icon(Icons.library_books),
                text: AppLocalizations.of(context)?.materials ?? "Materials",
              ),
              Tab(
                icon: Icon(Icons.quiz),
                text: AppLocalizations.of(context)?.quizzes ?? "Quizzes",
              ),
              Tab(
                icon: Icon(Icons.record_voice_over),
                text: "Speech Notes",
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildMaterialsSection(context),
            _buildQuizzesSection(context),
            _buildSpeechNotesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialsSection(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Class Selection Dropdown

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedClass,
                isExpanded: true,
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: Theme.of(context).colorScheme.primary,
                ),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                items: _classes.map((String className) {
                  return DropdownMenuItem<String>(
                    value: className,
                    child: Text(className),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedClass = newValue;
                    });
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Subjects Grid

          LayoutBuilder(builder: (context, constraints) {
            final subjects = _classSubjects[_selectedClass] ?? [];

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: constraints.maxWidth > 600 ? 3 : 2,
                childAspectRatio: 1.2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
              ),
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                final subject = subjects[index];

                return _buildSubjectCard(
                  context,
                  subject.name,
                  subject.icon,
                  subject.color,
                  subject.topics,
                );
              },
            );
          }),

          const SizedBox(height: 24),

          Text(
            "Recent Notes",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),

          const SizedBox(height: 16),

          FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('study_materials')
                .orderBy('uploadDate', descending: true)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final materials = snapshot.data?.docs ?? [];

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: materials.length,
                itemBuilder: (context, index) {
                  final material =
                      materials[index].data() as Map<String, dynamic>;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Icon(
                        _getFileIcon(material['fileUrl']?.toString() ?? ''),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(
                        material['title']?.toString() ?? 'Untitled',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      // In the ListView.builder for Recent Notes, update the subtitle section
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (material['class'] != null &&
                              material['subject'] != null &&
                              material['topic'] != null)
                            Text(
                              '${material['class']} > ${material['subject']} > ${material['topic']}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue[700],
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (material['uploadDate'] != null)
                            Text(
                              'Uploaded: ${DateFormat('MMM dd, yyyy').format((material['uploadDate'] as Timestamp).toDate())}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: _isDownloading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.download),
                        onPressed: _isDownloading
                            ? null
                            : () => _downloadMaterial(
                                material['fileUrl']?.toString() ?? ''),
                        tooltip: 'Download Material',
                      ),
                      isThreeLine: true,
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

  Widget _buildQuizzesSection(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text(
          "Select Your Class",
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const SizedBox(height: 16),
        ...List.generate(5, (index) {
          final className = "Class ${index + 6}";

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(
                className,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text("Take quizzes for $className"),
              trailing: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.arrow_forward,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ClassQuizPage(className: className),
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSubjectCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    List<String> topics,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SubjectContentPage(
                subject: title,
                color: color,
                icon: icon,
                className: _selectedClass,
                topics: topics,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.7),
                color.withOpacity(0.4),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: Colors.white,
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileUrl) {
    final extension = fileUrl.split('.').last.toLowerCase();

    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;

      case 'doc':
      case 'docx':
        return Icons.description;

      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;

      case 'mp4':
      case 'mov':
        return Icons.video_library;

      default:
        return Icons.insert_drive_file;
    }
  }

  Widget _buildSpeechNotesSection() {
    // Format class name to match storage path format (e.g., "Class 6" -> "class6")
    String formattedClassName = _selectedClass.toLowerCase().replaceAll(' ', '');
    print('Current user: ${FirebaseAuth.instance.currentUser?.email}'); // Debug log
    print('Is user signed in: ${FirebaseAuth.instance.currentUser != null}'); // Debug log
    print('Attempting to fetch transcripts for class: $formattedClassName'); // Debug log

    return Column(
      children: [
        // Class Selection Dropdown
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedClass,
                isExpanded: true,
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: Theme.of(context).colorScheme.primary,
                ),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                items: _classes.map((String className) {
                  return DropdownMenuItem<String>(
                    value: className,
                    child: Text(className),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedClass = newValue;
                    });
                  }
                },
              ),
            ),
          ),
        ),
        // Speech Notes List
        Expanded(
          child: FutureBuilder<ListResult>(
            future: FirebaseStorage.instance
                .ref('transcripts/$formattedClassName')
                .listAll(),
            builder: (context, snapshot) {
              // Add debug logging
              if (snapshot.hasError) {
                print('Error fetching transcripts: ${snapshot.error}'); // Debug log
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: ${snapshot.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {}); // Refresh the FutureBuilder
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading transcripts...'),
                    ],
                  ),
                );
              }

              final items = snapshot.data?.items ?? [];
              print('Found ${items.length} transcripts for $formattedClassName'); // Debug log

              if (items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.notes, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'No speech notes available for $_selectedClass',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {}); // Refresh the FutureBuilder
                        },
                        child: const Text('Refresh'),
                      ),
                    ],
                  ),
                );
              }

              // Sort items by timestamp in filename (most recent first)
              items.sort((a, b) {
                final aTimestamp = _extractTimestamp(a.name);
                final bTimestamp = _extractTimestamp(b.name);
                return bTimestamp.compareTo(aTimestamp);
              });

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final timestamp = _extractTimestamp(item.name);
                  final teacherName = _extractTeacherName(item.name);

                  return FutureBuilder<String>(
                    future: item.getDownloadURL(),
                    builder: (context, urlSnapshot) {
                      final fileUrl = urlSnapshot.data;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.text_snippet),
                          title: Text(
                            teacherName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Created: ${DateFormat('MMM dd, yyyy HH:mm').format(timestamp)}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.visibility),
                                tooltip: 'View',
                                onPressed: fileUrl != null 
                                  ? () => _viewTranscript(context, fileUrl, item.name)
                                  : null,
                              ),
                              IconButton(
                                icon: const Icon(Icons.download),
                                tooltip: 'Download',
                                onPressed: fileUrl != null 
                                  ? () => _downloadTranscript(context, fileUrl, item.name)
                                  : null,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // Add helper methods to extract information from filename
  DateTime _extractTimestamp(String filename) {
    try {
      // Extract the timestamp part from filename (e.g., "2024-12-12T02:24:32.976Z")
      final regex = RegExp(r'\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z');
      final match = regex.firstMatch(filename);
      if (match != null) {
        return DateTime.parse(match.group(0)!);
      }
    } catch (e) {
      print('Error parsing timestamp from filename: $e');
    }
    return DateTime(1970); // Return epoch time if parsing fails
  }

  String _extractTeacherName(String filename) {
    try {
      // Extract teacher name from filename (e.g., "sandesh_teacher")
      final parts = filename.split('_');
      if (parts.length >= 2) {
        return toTitleCase('${parts[0]} ${parts[1]}'.replaceAll('_', ' '));
      }
    } catch (e) {
      print('Error extracting teacher name from filename: $e');
    }
    return 'Unknown Teacher';
  }

  String toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ')
        .map((word) => word.isEmpty
            ? ''
            : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');
  }

  // Update the view transcript method to handle text files better
  Future<void> _viewTranscript(BuildContext context, String fileUrl, String fileName) async {
    try {
      final response = await http.get(Uri.parse(fileUrl));
      if (response.statusCode == 200) {
        if (!context.mounted) return;
        
        showDialog(
          context: context,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              padding: const EdgeInsets.all(16),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
                maxWidth: MediaQuery.of(context).size.width * 0.9,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _extractTeacherName(fileName),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        DateFormat('MMM dd, yyyy HH:mm')
                            .format(_extractTimestamp(fileName)),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: SingleChildScrollView(
                      child: SelectableText(
                        utf8.decode(response.bodyBytes),
                        style: const TextStyle(height: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        throw Exception('Failed to load transcript');
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error viewing transcript: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _downloadTranscript(BuildContext context, String fileUrl, String fileName) async {
    try {
      if (!await launchUrl(
        Uri.parse(fileUrl),
        mode: LaunchMode.externalApplication,
      )) {
        throw Exception('Could not launch URL');
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading transcript: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class ClassSelectionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Class for Quizzes")),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildClassTile(context, className: "Class 6"),
          _buildClassTile(context, className: "Class 7"),
          _buildClassTile(context, className: "Class 8"),
          _buildClassTile(context, className: "Class 9"),
          _buildClassTile(context, className: "Class 10"),
        ],
      ),
    );
  }

  Widget _buildClassTile(BuildContext context, {required String className}) {
    return Card(
      elevation: 4,
      child: ListTile(
        title: Text(className, style: const TextStyle(fontSize: 20)),
        trailing: const Icon(Icons.arrow_forward),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ClassQuizPage(className: className)),
          );
        },
      ),
    );
  }
}

class ClassQuizPage extends StatefulWidget {
  final String className;

  ClassQuizPage({required this.className});

  @override
  _ClassQuizPageState createState() => _ClassQuizPageState();
}

class _ClassQuizPageState extends State<ClassQuizPage> {
  static const apiKey = 'AIzaSyDs3vEPT17sggs2fYBuVYsB-wEeNNfmXnw';

  late Future<List<Question>> _quizQuestions = _getOfflineQuestions();

  List<int> _selectedAnswers = List.filled(10, -1);

  final model = GenerativeModel(
    model: 'gemini-pro',
    apiKey: apiKey,
  );

  bool _isReviewMode = false;

  List<bool> _correctAnswers = [];

  bool _isOnline = false;

  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  bool _isSubmitting = false;

  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _syncAndLoadQuestions();
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();

    super.dispose();
  }

  // Initialize connectivity checking

  Future<void> _initConnectivity() async {
    try {
      final connectivity = Connectivity();

      final result = await connectivity.checkConnectivity();

      setState(() {
        _isOnline = result != ConnectivityResult.none;
      });

      // Listen for connectivity changes

      _connectivitySubscription =
          connectivity.onConnectivityChanged.listen((result) {
        setState(() {
          _isOnline = result != ConnectivityResult.none;
        });
        if (result != ConnectivityResult.none) {
          _syncAndLoadQuestions(); // Sync when coming online
        }
      });
    } catch (e) {
      print('Connectivity check failed: $e');

      setState(() {
        _isOnline = false;
      });
    }
  }

  Future<void> _syncAndLoadQuestions() async {
    if (!mounted) return;

    setState(() {
      _isInitialLoad = true;
    });

    try {
      if (_isOnline) {
        // If online, try to fetch online questions
        setState(() {
          _quizQuestions = _fetchQuizQuestions().catchError((error) {
            print('Error fetching online questions: $error');
            return _getOfflineQuestions();
          });
        });
      } else {
        // If offline, use cached questions
        setState(() {
          _quizQuestions = _getOfflineQuestions().then((questions) {
            setState(() {
              _isInitialLoad = false;
            });
            return questions;
          });
        });
      }
    } catch (e) {
      print('Error in sync and load: $e');
      setState(() {
        _quizQuestions = _getOfflineQuestions().then((questions) {
          setState(() {
            _isInitialLoad = false;
          });
          return questions;
        });
      });
    }
  }

  Future<List<Question>> _fetchQuizQuestions() async {
    try {
      if (_isOnline) {
        print('Device is online, attempting to fetch online questions...');

        for (int attempt = 0; attempt < 3; attempt++) {
          // Try up to 3 times
          try {
            final prompt =
                '''Generate 10 multiple choice questions for ${widget.className} students.
Return a SINGLE LINE JSON object with NO line breaks or formatting, exactly like this:
{"questions":[{"question":"Question text here?","options":["Option A","Option B","Option C","Option D"],"correctAnswer":"Exact text of correct option","subject":"One of: Mathematics, Science, English, Social Studies"}]}

Distribution:
- 3 Mathematics questions
- 3 Science questions
- 2 English questions
- 2 Social Studies questions

Each question must:
1. Have exactly 4 options
2. Have correctAnswer that exactly matches one of the options
3. Have subject matching one of the specified subjects
4. Be appropriate for ${widget.className} level

IMPORTANT: Return ONLY the JSON object with NO additional text, line breaks, or formatting.''';

            final response = await model.generateContent([
              Content.text(prompt),
              Content.text(
                  'Return ONLY the JSON object with no additional text or formatting.')
            ]);

            if (response.text == null || response.text!.isEmpty) {
              print(
                  'Empty response from AI, falling back to offline questions');
              return _getOfflineQuestions();
            }

            print('Successfully received response from AI');

            // Clean the response text
            String cleanResponse = response.text!
                .replaceAll('```json', '')
                .replaceAll('```JSON', '')
                .replaceAll('```', '')
                .replaceAll('JSON', '')
                .replaceAll('\n', '') // Remove all line breaks
                .replaceAll('\r', '') // Remove all carriage returns
                .trim();

            // Remove any text before the first {
            final startIndex = cleanResponse.indexOf('{');
            if (startIndex != -1) {
              cleanResponse = cleanResponse.substring(startIndex);
            }

            // Remove any text after the last }
            final endIndex = cleanResponse.lastIndexOf('}');
            if (endIndex != -1) {
              cleanResponse = cleanResponse.substring(0, endIndex + 1);
            }

            // Clean up any double spaces
            cleanResponse = cleanResponse.replaceAll(RegExp(r'\s+'), ' ');

            // Add logging to see cleaned response
            print('Cleaned response: $cleanResponse');

            try {
              final Map<String, dynamic> jsonResponse =
                  json.decode(cleanResponse);

              if (!jsonResponse.containsKey('questions')) {
                print(
                    'Invalid JSON format from AI, falling back to offline questions');
                return _getOfflineQuestions();
              }

              final List<dynamic> questionsData =
                  jsonResponse['questions'] as List;
              print(
                  'Successfully parsed ${questionsData.length} questions from AI');

              if (questionsData.isEmpty) {
                return _getOfflineQuestions();
              }

              // First convert questions to proper format
              List<Question> questions = questionsData
                  .map((questionData) => Question(
                        question: questionData['question'] as String,
                        options: List<String>.from(questionData['options']),
                        correctAnswer: questionData['correctAnswer'] as String,
                        subject: questionData['subject'] as String,
                      ))
                  .toList();

              // Then update Firebase in background
              QuizService.updateFirebaseQuestions(
                widget.className,
                questionsData
                    .map((q) => {
                          'question': q['question'],
                          'options': q['options'],
                          'correctAnswer': q['correctAnswer'],
                          'subject': q['subject'],
                        })
                    .toList(),
              ).then((_) => QuizDataHelper.syncWithFirebase());

              setState(() {
                _isInitialLoad = false;
              });

              return questions;
            } catch (parseError) {
              print('JSON parsing error: $parseError');
              print('Response that failed to parse: $cleanResponse');
              return _getOfflineQuestions();
            }
          } catch (parseError) {
            print('Attempt ${attempt + 1} failed: $parseError');
            if (attempt == 2) {
              // Last attempt failed
              print('All attempts failed, falling back to offline questions');
              return _getOfflineQuestions();
            }
            // Wait briefly before retrying
            await Future.delayed(Duration(seconds: 1));
          }
        }
      }
      return _getOfflineQuestions();
    } catch (error) {
      print('Error in _fetchQuizQuestions: $error');
      return _getOfflineQuestions();
    }
  }

  Future<List<Question>> _getOfflineQuestions() async {
    print('Loading offline questions...');

    try {
      // First try to get questions from local storage (synced from Firebase)
      final file = await QuizDataHelper.localFile;
      if (await file.exists()) {
        final String jsonString = await file.readAsString();
        print('Found local storage file');

        try {
          final jsonData = json.decode(jsonString);
          print('Successfully parsed local storage data');

          if (jsonData.containsKey(widget.className)) {
            List<Map<String, dynamic>> selectedQuestions = [];
            final classData = jsonData[widget.className];

            // Get questions according to distribution
            final subjects = [
              'Mathematics',
              'Science',
              'English',
              'Social Studies'
            ];
            final counts = [3, 3, 2, 2];

            for (int i = 0; i < subjects.length; i++) {
              final subject = subjects[i];
              final count = counts[i];

              if (classData.containsKey(subject) &&
                  classData[subject] is List &&
                  (classData[subject] as List).isNotEmpty) {
                List<dynamic> subjectQuestions = List.from(classData[subject]);
                subjectQuestions.shuffle();

                int questionsToAdd = count.clamp(0, subjectQuestions.length);
                print(
                    'Adding $questionsToAdd questions from $subject (cached)');

                for (int j = 0; j < questionsToAdd; j++) {
                  selectedQuestions.add({
                    ...subjectQuestions[j] as Map<String, dynamic>,
                    'subject': subject,
                  });
                }
              }
            }

            if (selectedQuestions.isNotEmpty) {
              print('Loaded ${selectedQuestions.length} questions from cache');
              selectedQuestions.shuffle();
              return selectedQuestions.map((questionData) {
                return Question(
                  question: questionData['question'] as String,
                  options: List<String>.from(questionData['options']),
                  correctAnswer: questionData['correctAnswer'] as String,
                  subject: questionData['subject'] as String,
                );
              }).toList();
            }
          } else {
            print(
                'No questions found for ${widget.className} in local storage');
          }
        } catch (e) {
          print('Error parsing local storage data: $e');
        }
      } else {
        print('No local storage file found');
      }

      // If we get here, either no cached questions or error occurred
      print('Falling back to asset file');
      final offlineQuestions = await QuizDataHelper.getOfflineQuestions(
        widget.className,
        ['Mathematics', 'Science', 'English', 'Social Studies'],
        [3, 3, 2, 2],
      );

      setState(() {
        _isInitialLoad = false;
      });

      return offlineQuestions.map((questionData) {
        return Question(
          question: questionData['question'] as String,
          options: List<String>.from(questionData['options']),
          correctAnswer: questionData['correctAnswer'] as String,
          subject: questionData['subject'] as String,
        );
      }).toList();
    } catch (e) {
      print('Error loading offline questions: $e');
      print(e.toString());

      // If all else fails, try one last time with asset file
      final offlineQuestions = await QuizDataHelper.getOfflineQuestions(
        widget.className,
        ['Mathematics', 'Science', 'English', 'Social Studies'],
        [3, 3, 2, 2],
      );

      setState(() {
        _isInitialLoad = false;
      });

      return offlineQuestions.map((questionData) {
        return Question(
          question: questionData['question'] as String,
          options: List<String>.from(questionData['options']),
          correctAnswer: questionData['correctAnswer'] as String,
          subject: questionData['subject'] as String,
        );
      }).toList();
    }
  }

  String _getMathTopics(String className) {
    switch (className) {
      case "Class 6":
        return "integers, fractions, decimals, basic algebra, geometry basics";

      case "Class 7":
        return "rational numbers, exponents, algebraic expressions, linear equations";

      case "Class 8":
        return "squares and square roots, polynomials, coordinate geometry";

      case "Class 9":
        return "quadratic equations, trigonometry basics, statistics";

      case "Class 10":
        return "trigonometry, probability, coordinate geometry, real numbers";

      default:
        return "basic mathematics concepts";
    }
  }

  String _getScienceTopics(String className) {
    switch (className) {
      case "Class 6":
        return "basic physics concepts, living organisms, matter and materials";

      case "Class 7":
        return "heat, motion, acids and bases, reproduction in plants";

      case "Class 8":
        return "force and pressure, chemical reactions, cell structure";

      case "Class 9":
        return "Newton's laws, atomic structure, biological systems";

      case "Class 10":
        return "electricity, chemical reactions, genetics and evolution";

      default:
        return "basic science concepts";
    }
  }

  String _getEnglishTopics(String className) {
    switch (className) {
      case "Class 6":
        return "basic grammar, comprehension, vocabulary";

      case "Class 7":
        return "tenses, active/passive voice, reading comprehension";

      case "Class 8":
        return "advanced grammar, writing skills, literature";

      case "Class 9":
        return "advanced comprehension, writing formats, literature analysis";

      case "Class 10":
        return "advanced writing skills, complex grammar, literature criticism";

      default:
        return "basic English concepts";
    }
  }

  String _getSocialTopics(String className) {
    switch (className) {
      case "Class 6":
        return "basic geography, ancient civilizations, map reading";

      case "Class 7":
        return "medieval history, environmental geography, civics";

      case "Class 8":
        return "modern history, physical geography, government";

      case "Class 9":
        return "contemporary history, economic geography, political science";

      case "Class 10":
        return "world history, advanced geography, economics basics";

      default:
        return "basic social studies concepts";
    }
  }

  Widget _buildSubmitButton(List<Question> questions) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: _isSubmitting
            ? null // Disable button while submitting

            : () => _submitQuiz(questions),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        child: _isSubmitting
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isOnline ? "Saving..." : "Processing...",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            : const Text(
                "Submit Quiz",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  void _submitQuiz(List<Question> questions) async {
    if (_isSubmitting) return; // Prevent multiple submissions

    setState(() {
      _isSubmitting = true; // Start loading
    });

    try {
      int score = 0;

      _correctAnswers = List.filled(10, false);

      for (int i = 0; i < 10; i++) {
        if (_selectedAnswers[i] != -1 &&
            _selectedAnswers[i] == questions[i].correctAnswerIndex) {
          score++;

          _correctAnswers[i] = true;
        }
      }

      final percentage = (score / 10) * 100;

      if (_isOnline) {
        final user = FirebaseAuth.instance.currentUser;

        if (user != null) {
          await _saveQuizResult(user.uid, score, percentage);
        }
      }

      if (mounted) {
        await _showQuizResultDialog(score);
      }
    } catch (error) {
      print('Error in _submitQuiz: $error');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving quiz result: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false; // Stop loading
        });
      }
    }
  }

  Future<void> _saveQuizResult(
      String userId, int score, double percentage) async {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);

    final docSnapshot = await userDoc.get();

    if (!docSnapshot.exists) {
      await userDoc.set({
        'email': FirebaseAuth.instance.currentUser?.email,
        'createdAt': FieldValue.serverTimestamp(),
        'learningProgress': {},
      });
    }

    String subjectKey = widget.className.replaceAll(' ', '_').toLowerCase();

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      transaction.set(
        userDoc,
        {
          'learningProgress': {
            subjectKey: {
              'lastScore': score,
              'lastPercentage': percentage,
              'lastAttempt': FieldValue.serverTimestamp(),
            }
          }
        },
        SetOptions(merge: true),
      );

      final quizResultRef =
          FirebaseFirestore.instance.collection('quiz_results').doc();

      transaction.set(quizResultRef, {
        'userId': userId,
        'subject': widget.className,
        'score': score,
        'totalQuestions': 10,
        'percentage': percentage,
        'timestamp': FieldValue.serverTimestamp(),
      });
    });
  }

  Color _getSubjectColor(String subject) {
    switch (subject) {
      case 'Mathematics':
        return Colors.blue;

      case 'Science':
        return Colors.green;

      case 'English':
        return Colors.orange;

      case 'Social Studies':
      case 'Geography':
        return Colors.purple;

      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isReviewMode ? "Quiz Review" : "${widget.className} Quiz"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: _isReviewMode
            ? [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isReviewMode = false;
                      _selectedAnswers = List.filled(10, -1);
                      _quizQuestions = _fetchQuizQuestions();
                    });
                  },
                  child: const Text(
                    "New Quiz",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ]
            : null,
      ),
      body: Column(
        children: [
          // Status indicator with loading state
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4),
            color: _isOnline
                ? Colors.green.withOpacity(0.1)
                : Colors.orange.withOpacity(0.1),
            child: Text(
              _isOnline
                  ? (_isInitialLoad
                      ? 'Loading Online Questions...'
                      : 'Online Questions')
                  : 'Offline Questions',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: _isOnline ? Colors.green[700] : Colors.orange[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // Existing quiz content
          Expanded(
            child: FutureBuilder<List<Question>>(
              future: _quizQuestions,
              builder: (context, snapshot) {
                if (_isInitialLoad || !snapshot.hasData) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          "Preparing your quiz...",
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline),
                        Text('Error: ${snapshot.error}'),
                        ElevatedButton(
                          onPressed: _syncAndLoadQuestions,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.data!.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          "Loading questions...",
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                // Display questions
                List<Question> questions = snapshot.data!;
                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: questions.length,
                        itemBuilder: (context, index) {
                          return QuizQuestionWidget(
                            question: questions[index],
                            questionIndex: index,
                            selectedAnswer: _selectedAnswers[index],
                            isReviewMode: _isReviewMode,
                            isCorrect:
                                _isReviewMode ? _correctAnswers[index] : null,
                            onOptionSelected: _isReviewMode
                                ? null
                                : (selectedOptionIndex) {
                                    setState(() {
                                      _selectedAnswers[index] =
                                          selectedOptionIndex;
                                    });
                                  },
                          );
                        },
                      ),
                    ),
                    if (!_isReviewMode) _buildSubmitButton(questions),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showQuizResultDialog(int score) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              maxWidth: 400,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  score >= 7 ? Icons.emoji_events : Icons.school,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  "Quiz Complete!",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "$score out of 10",
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isOnline
                            ? "Score saved"
                            : "Practice Quiz - Score not saved",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();

                        Navigator.of(context).pop();
                      },
                      child: const Text("Exit"),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();

                        setState(() {
                          _isReviewMode = true;
                        });
                      },
                      child: const Text("Review"),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();

                        setState(() {
                          _selectedAnswers = List.filled(10, -1);

                          _quizQuestions = _fetchQuizQuestions();

                          _isReviewMode = false;
                        });
                      },
                      child: const Text("Try Again"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class QuizQuestionWidget extends StatelessWidget {
  final Question question;

  final int questionIndex;

  final int selectedAnswer;

  final Function(int)? onOptionSelected;

  final bool isReviewMode;

  final bool? isCorrect;

  QuizQuestionWidget({
    required this.question,
    required this.questionIndex,
    required this.selectedAnswer,
    required this.onOptionSelected,
    this.isReviewMode = false,
    this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: isReviewMode
              ? Border.all(
                  color: isCorrect == true ? Colors.green : Colors.red,
                  width: 2,
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getSubjectColor(question.subject).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getSubjectColor(question.subject).withOpacity(0.5),
                      ),
                    ),
                    child: Text(
                      question.subject,
                      style: TextStyle(
                        color: _getSubjectColor(question.subject),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (isReviewMode)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(
                        isCorrect == true ? Icons.check_circle : Icons.cancel,
                        color: isCorrect == true ? Colors.green : Colors.red,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                question.question,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              ...List.generate(
                question.options.length,
                (index) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getOptionBorderColor(index, context),
                    ),
                    color: _getOptionBackgroundColor(index),
                  ),
                  child: RadioListTile<int>(
                    title: Text(question.options[index]),
                    value: index,
                    groupValue: selectedAnswer,
                    onChanged: onOptionSelected != null
                        ? (value) => onOptionSelected!(value!)
                        : null,
                    activeColor: Theme.of(context).colorScheme.primary,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              if (isReviewMode && selectedAnswer != question.correctAnswerIndex)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    "Correct answer: ${question.correctAnswer}",
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getOptionBorderColor(int index, BuildContext context) {
    if (!isReviewMode) {
      return selectedAnswer == index
          ? Theme.of(context).colorScheme.primary
          : Colors.grey.withOpacity(0.3);
    }

    if (index == question.correctAnswerIndex) {
      return Colors.green;
    }

    if (index == selectedAnswer &&
        selectedAnswer != question.correctAnswerIndex) {
      return Colors.red;
    }

    return Colors.grey.withOpacity(0.3);
  }

  Color? _getOptionBackgroundColor(int index) {
    if (!isReviewMode) return null;

    if (index == question.correctAnswerIndex) {
      return Colors.green.withOpacity(0.1);
    }

    if (index == selectedAnswer &&
        selectedAnswer != question.correctAnswerIndex) {
      return Colors.red.withOpacity(0.1);
    }

    return null;
  }

  Color _getSubjectColor(String subject) {
    switch (subject) {
      case 'Mathematics':
        return Colors.blue;

      case 'Science':
        return Colors.green;

      case 'English':
        return Colors.orange;

      case 'Social Studies':
      case 'Geography':
        return Colors.purple;

      default:
        return Colors.grey;
    }
  }
}

class Question {
  final String question;

  final String correctAnswer;

  final List<String> options;

  final String subject;

  Question({
    required this.question,
    required this.correctAnswer,
    required this.options,
    required this.subject,
  });

  int get correctAnswerIndex {
    return options.indexOf(correctAnswer);
  }
}

class SubjectContentPage extends StatelessWidget {
  final String subject;

  final Color color;

  final IconData icon;

  final String className;

  final List<String> topics;

  const SubjectContentPage({
    Key? key,
    required this.subject,
    required this.color,
    required this.icon,
    required this.className,
    required this.topics,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$subject - $className'),
        backgroundColor: color,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    icon,
                    size: 60,
                    color: color,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '$subject for $className',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: topics.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Icon(icon, color: color),
                      title: Text(
                        topics[index],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TopicDetailPage(
                              subject: subject,
                              topic: topics[index],
                              color: color,
                              className: className,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TopicDetailPage extends StatefulWidget {
  final String subject;
  final String topic;
  final Color color;
  final String className;

  const TopicDetailPage({
    Key? key,
    required this.subject,
    required this.topic,
    required this.color,
    required this.className,
  }) : super(key: key);

  @override
  State<TopicDetailPage> createState() => _TopicDetailPageState();
}

class _TopicDetailPageState extends State<TopicDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _cachedContent;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadContent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadContent() async {
    setState(() => _isLoading = true);
    try {
      // Try to get content metadata from Firestore
      final contentDoc = await FirebaseFirestore.instance
          .collection('topic_contents')
          .where('class', isEqualTo: widget.className)
          .where('subject', isEqualTo: widget.subject)
          .where('topic', isEqualTo: widget.topic)
          .get();

      if (contentDoc.docs.isNotEmpty) {
        final fileUrl = contentDoc.docs.first.get('fileUrl') as String;

        // Fetch the content from Firebase Storage URL
        try {
          final response = await http.get(Uri.parse(fileUrl));
          if (response.statusCode == 200) {
            // Sanitize the content before storing
            final sanitizedContent = _sanitizeMarkdownContent(response.body);

            setState(() {
              _cachedContent = sanitizedContent;
              _isLoading = false;
            });

            // Cache the sanitized content locally
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(
              'content_${widget.className}_${widget.subject}_${widget.topic}',
              sanitizedContent,
            );
          } else {
            throw Exception('Failed to load content');
          }
        } catch (e) {
          print('Error fetching content file: $e');
          // Try to load from local cache if fetch fails
          final prefs = await SharedPreferences.getInstance();
          final cachedContent = prefs.getString(
            'content_${widget.className}_${widget.subject}_${widget.topic}',
          );
          setState(() {
            _cachedContent = cachedContent != null
                ? _sanitizeMarkdownContent(cachedContent)
                : null;
            _isLoading = false;
          });
        }
      } else {
        // Try to load from local cache if no online content
        final prefs = await SharedPreferences.getInstance();
        final cachedContent = prefs.getString(
          'content_${widget.className}_${widget.subject}_${widget.topic}',
        );
        setState(() {
          _cachedContent = cachedContent != null
              ? _sanitizeMarkdownContent(cachedContent)
              : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading content: $e');
      setState(() => _isLoading = false);
    }
  }

  // Add this helper method to sanitize markdown content
  String _sanitizeMarkdownContent(String content) {
    // Remove any potential problematic URI references
    content = content.replaceAll(RegExp(r']\(c:.*?\)'), '](#)');

    // Ensure all links are properly formatted
    content = content.replaceAll(RegExp(r']\((?!http|https|#)'), '](https://');

    // Remove any null bytes or other problematic characters
    content =
        content.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');

    return content;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.topic),
        backgroundColor: widget.color,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Content'),
            Tab(text: 'Materials'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Content Tab
          _buildContentTab(),
          // Materials Tab
          _buildMaterialsTab(),
        ],
      ),
    );
  }

  Widget _buildContentTab() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading content...'),
          ],
        ),
      );
    }

    if (_cachedContent == null || _cachedContent!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No content available for this topic',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            if (!_isLoading)
              ElevatedButton(
                onPressed: _loadContent,
                child: const Text('Retry Loading'),
              ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Builder(
                builder: (context) {
                  try {
                    return MarkdownBody(
                      data: _cachedContent!,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        h1: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontFamily:
                                  'NotoColorEmoji', // Add support for color emojis
                            ),
                        h2: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontFamily: 'NotoColorEmoji',
                            ),
                        h3: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontFamily: 'NotoColorEmoji',
                            ),
                        p: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontFamily: 'NotoColorEmoji',
                            ),
                      ),
                      onTapLink: (text, href, title) {
                        if (href != null) {
                          try {
                            final uri = Uri.parse(href);
                            launchUrl(uri);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Invalid link: $href'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      imageBuilder: (uri, title, alt) {
                        try {
                          return Image.network(
                            uri.toString(),
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.broken_image);
                            },
                          );
                        } catch (e) {
                          return const Icon(Icons.broken_image);
                        }
                      },
                    );
                  } catch (e) {
                    return Text(
                      'Error displaying content: ${e.toString()}',
                      style: const TextStyle(color: Colors.red),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('study_materials')
          .where('class', isEqualTo: widget.className)
          .where('subject', isEqualTo: widget.subject)
          .where('topic', isEqualTo: widget.topic)
          .orderBy('uploadDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No materials available yet',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final material = doc.data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: Text(material['title'] ?? 'Untitled'),
                subtitle: material['uploadDate'] != null
                    ? Text(
                        'Uploaded: ${_formatDate(material['uploadDate'] as Timestamp)}')
                    : null,
                trailing: IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () => _downloadMaterial(
                    context,
                    material['fileUrl'] as String,
                    material['fileName'] as String,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _downloadMaterial(
      BuildContext context, String fileUrl, String fileName) async {
    try {
      await launchUrl(Uri.parse(fileUrl));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening file: $e')),
        );
      }
    }
  }
}

class SubjectInfo {
  final String name;

  final IconData icon;

  final Color color;

  final List<String> topics;

  SubjectInfo(this.name, this.icon, this.color, this.topics);
}
