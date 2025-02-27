import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';

import 'ar_vr_viewer.dart';

class ArVrPage extends StatelessWidget {
  const ArVrPage({Key? key}) : super(key: key);

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AR/VR Learning"),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.7),
                    Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.view_in_ar,
                        size: 40,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          "Interactive 3D Learning",
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Experience immersive learning through Augmented and Virtual Reality",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Subjects Grid

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.85,
              children: [
                _buildSubjectCard(
                  context,
                  "Biology",
                  Icons.biotech,
                  Colors.green,
                  "Explore 3D models of human anatomy, cell structures, and more",
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ArVrSubjectPage(
                        subject: "Biology",
                        models: _getBiologyModels(),
                      ),
                    ),
                  ),
                ),
                _buildSubjectCard(
                  context,
                  "Chemistry",
                  Icons.science,
                  Colors.purple,
                  "Visualize molecular structures and chemical reactions",
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ArVrSubjectPage(
                        subject: "Chemistry",
                        models: _getChemistryModels(),
                      ),
                    ),
                  ),
                ),
                _buildSubjectCard(
                  context,
                  "Physics",
                  Icons.rocket_launch,
                  Colors.blue,
                  "Interactive simulations of physics concepts",
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ArVrSubjectPage(
                        subject: "Physics",
                        models: _getPhysicsModels(),
                      ),
                    ),
                  ),
                ),
                _buildSubjectCard(
                  context,
                  "Geography",
                  Icons.public,
                  Colors.orange,
                  "Explore 3D maps and geological formations",
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ArVrSubjectPage(
                        subject: "Geography",
                        models: _getGeographyModels(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String description,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
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
                size: 40,
                color: Colors.white,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<ArVrModel> _getBiologyModels() {
    return [
      ArVrModel(
        title: "Human Heart",
        description: "3D model of human heart",
        thumbnailUrl: "assets/images/Heart.webp",
        modelUrl: "assets/models/heart.glb",
        audioUrl: "assets/audio/Heart_audio.mp3",
        type: ArVrModelType.anatomy,
      ),
      ArVrModel(
        title: "Human Brain",
        description: "3D model of human brain",
        thumbnailUrl: "assets/images/Brain.webp",
        modelUrl: "assets/models/brain.glb",
        audioUrl: "assets/audio/Brain_audio.mp3",
        type: ArVrModelType.anatomy,
      ),
      ArVrModel(
        title: "Human Cell",
        description: "3D model of human cell",
        thumbnailUrl: "assets/images/Humancell.webp",
        modelUrl: "assets/models/human_cell.glb",
        audioUrl: "assets/audio/HumanCell_audio.mp3",
        type: ArVrModelType.anatomy,
      ),
      ArVrModel(
        title: "Human Tooth",
        description: "3D model of human tooth",
        thumbnailUrl: "assets/images/Teeth.webp",
        modelUrl: "assets/models/teeth.glb",
        audioUrl: "assets/audio/Teeth_audio.mp3",
        type: ArVrModelType.anatomy,
      ),
      ArVrModel(
        title: "Human DNA",
        description: "3D model of human DNA",
        thumbnailUrl: "assets/images/DNA.webp",
        modelUrl: "assets/models/dna.glb",
        audioUrl: "assets/audio/DNA_audio.mp3",
        type: ArVrModelType.anatomy,
      ),
      ArVrModel(
        title: "Human Skeleton",
        description: "3D model of human skeleton",
        thumbnailUrl: "assets/images/Skeleton.webp",
        modelUrl: "assets/models/skeleton.glb",
        audioUrl: "assets/audio/Skeleton_audio.mp3",
        type: ArVrModelType.anatomy,
      ),
      ArVrModel(
        title: "Virus",
        description: "3D model of virus",
        thumbnailUrl: "assets/images/Virus.webp",
        modelUrl: "assets/models/virus.glb",
        audioUrl: "assets/audio/Virus_audio.mp3",
        type: ArVrModelType.anatomy,
      ),

      // Add more biology models
    ];
  }

  List<ArVrModel> _getChemistryModels() {
    return [
      ArVrModel(
        title: "Modern Periodic Table",
        description: "Interactive modern periodic table",
        thumbnailUrl: "assets/images/PeriodicTable.jpg",
        modelUrl: "assets/models/the_3d_periodic_table.glb",
        type: ArVrModelType.molecule,
      ),

      // Add more chemistry models
    ];
  }

  List<ArVrModel> _getPhysicsModels() {
    return [
      ArVrModel(
        title: "Solar System",
        description: "Interactive solar system simulation",
        thumbnailUrl: "assets/images/Solarsystem.webp",
        modelUrl: "assets/models/solsystem.glb",
        audioUrl: "assets/audio/SolarSystem_audio.mp3",
        type: ArVrModelType.simulation,
      ),
    ];
  }

  List<ArVrModel> _getGeographyModels() {
    return [
      ArVrModel(
        title: "Soil Profile",
        description: "Cross-section of a soil profile",
        thumbnailUrl: "assets/images/Soilprofile.webp",
        modelUrl: "assets/models/soil_profile.glb",
        audioUrl: "assets/audio/SoilProfile_audio.mp3",
        type: ArVrModelType.geography,
      ),

      // Add more geography models
    ];
  }
}

class ArVrSubjectPage extends StatelessWidget {
  final String subject;

  final List<ArVrModel> models;

  const ArVrSubjectPage({
    Key? key,
    required this.subject,
    required this.models,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("$subject AR/VR Models"),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: models.length,
        itemBuilder: (context, index) {
          final model = models[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              leading: Image.asset(
                model.thumbnailUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
              title: Text(model.title),
              subtitle: Text(model.description),
              trailing: Icon(
                _getIconForModelType(model.type),
                color: Theme.of(context).colorScheme.primary,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ArVrViewer(
                      modelUrl: model.modelUrl,
                      title: model.title,
                      audioUrl: model.audioUrl,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  IconData _getIconForModelType(ArVrModelType type) {
    switch (type) {
      case ArVrModelType.anatomy:
        return Icons.accessibility_new;

      case ArVrModelType.molecule:
        return Icons.science;

      case ArVrModelType.simulation:
        return Icons.animation;

      case ArVrModelType.geography:
        return Icons.public;
    }
  }
}

class ArVrModel {
  final String title;

  final String description;

  final String thumbnailUrl;

  final String modelUrl;

  final String? audioUrl;

  final ArVrModelType type;

  ArVrModel({
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.modelUrl,
    this.audioUrl,
    required this.type,
  });
}

enum ArVrModelType {
  anatomy,

  molecule,

  simulation,

  geography,
}
