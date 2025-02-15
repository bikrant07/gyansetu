import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AgriculturePage extends StatefulWidget {
  const AgriculturePage({Key? key}) : super(key: key);

  @override
  State<AgriculturePage> createState() => _AgriculturePageState();
}

class _AgriculturePageState extends State<AgriculturePage> {
  late List<Map<String, dynamic>> cropCycles;

  @override
  void dispose() {
    super.dispose();
  }

  String _getSectionTitle(BuildContext context, String key) {
    final localizations = AppLocalizations.of(context);
    switch (key) {
      case 'cropSelection':
        return localizations?.cropSelection ?? 'Crop Selection';
      case 'soilManagement':
        return localizations?.soilManagement ?? 'Soil Management';
      case 'irrigation':
        return localizations?.irrigation ?? 'Irrigation';
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Initialize cropCycles here where we have access to context
    cropCycles = [
      {
        'title': AppLocalizations.of(context)?.wheatCropCycle ?? 'Wheat Crop Cycle',
        'image': 'assets/images/agriculture/wheat_cycle.png',
        'stages': [
          AppLocalizations.of(context)?.wheatStage1 ?? 'Seed Germination: Seeds absorb water and begin to sprout, developing initial root and shoot',
          AppLocalizations.of(context)?.wheatStage2 ?? 'Seedling Growth: First leaves emerge and plant establishes itself in soil',
          AppLocalizations.of(context)?.wheatStage3 ?? 'Tillering Phase: Multiple stems develop from the base of the plant',
          AppLocalizations.of(context)?.wheatStage4 ?? 'Stem Extension: Plant grows taller and develops more leaves',
          AppLocalizations.of(context)?.wheatStage5 ?? 'Heading Stage: Grain head emerges from the stem\'s flag leaf',
          AppLocalizations.of(context)?.wheatStage6 ?? 'Flowering Phase: Pollination occurs and kernels begin to form',
          AppLocalizations.of(context)?.wheatStage7 ?? 'Grain Filling: Kernels develop and fill with starch',
          AppLocalizations.of(context)?.wheatStage8 ?? 'Ripening: Grain matures and dries, plant turns golden-brown',
        ],
        'duration': AppLocalizations.of(context)?.wheatDuration ?? '120-150 days',
      },
      {
        'title': AppLocalizations.of(context)?.riceCropCycle ?? 'Rice Crop Cycle',
        'image': 'assets/images/agriculture/rice_cycle.png',
        'stages': [
          AppLocalizations.of(context)?.riceStage1 ?? 'Seed Selection: Choose high-quality seeds and prepare them for sowing',
          AppLocalizations.of(context)?.riceStage2 ?? 'Nursery Preparation: Seeds are sown in nursery beds for initial growth',
          AppLocalizations.of(context)?.riceStage3 ?? 'Transplanting: Young seedlings are moved to the main field',
          AppLocalizations.of(context)?.riceStage4 ?? 'Vegetative Phase: Plant develops tillers and grows in height',
          AppLocalizations.of(context)?.riceStage5 ?? 'Reproductive Stage: Panicle develops and flowering occurs',
          AppLocalizations.of(context)?.riceStage6 ?? 'Ripening Phase: Grain fills and matures, changing from green to golden',
          AppLocalizations.of(context)?.riceStage7 ?? 'Harvesting: Crop is harvested when grains are mature and golden',
        ],
        'duration': AppLocalizations.of(context)?.riceDuration ?? '100-150 days',
      },
      // Add more crop cycles
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.agriculture ?? 'Agriculture'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Crop Cycle Carousel
            _buildCarouselSection(),
            
            // Soil Types Interactive Section
            _buildSoilTypesSection(),
            
            // Weather Impact Visualization
            _buildWeatherImpactSection(),
            
            // Traditional Content Sections
            _buildSection(
              context,
              'cropSelection',
              AppLocalizations.of(context)?.cropSelectionDesc ?? 'Choose the right crops for optimal yield',
              [
                'Test soil pH and nutrient levels before planting',
                'Consider local climate and growing season length',
                'Check water availability and irrigation requirements',
                'Research market demand and crop prices',
                'Evaluate pest and disease resistance of varieties',
                'Consider crop rotation patterns for soil health',
                'Assess required labor and equipment resources',
                'Choose certified and quality seeds',
                'Factor in storage and transportation facilities',
                'Consider intercropping opportunities',
                'Evaluate previous crop performance in the area',
                'Check compatibility with existing farming practices',
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarouselSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                Icons.grass,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                'Crop Growth Cycles',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        FlutterCarousel(
          options: CarouselOptions(
            height: 200.0,
            showIndicator: true,
            slideIndicator: const CircularSlideIndicator(),
            autoPlay: true,
            viewportFraction: 0.85,
            enableInfiniteScroll: true,
            autoPlayInterval: const Duration(seconds: 5),
          ),
          items: cropCycles.map((cycle) {
            return Builder(
              builder: (BuildContext context) {
                return GestureDetector(
                  onTap: () => _showCropDetails(context, cycle),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          Image.asset(
                            cycle['image'],
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.7),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 16,
                            left: 16,
                            right: 16,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cycle['title'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Duration: ${cycle["duration"]}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSoilTypesSection() {
    final translations = AppLocalizations.of(context);
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            translations?.soilTypesTitle ?? 'Soil Types',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _showSoilDetails(context, translations?.sandySoil ?? 'Sandy Soil'),
            child: Card(
              color: Colors.amber[100],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Image.asset('assets/images/agriculture/sandy_soil.png', fit: BoxFit.cover),
                    const SizedBox(height: 8),
                    Text(translations?.sandySoil ?? 'Sandy Soil'),
                    Text(translations?.sandySoilManagement1 ?? 'Add organic matter regularly'),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _showSoilDetails(context, translations?.claySoil ?? 'Clay Soil'),
            child: Card(
              color: Colors.brown[100],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Image.asset('assets/images/agriculture/clay_soil.png', fit: BoxFit.cover),
                    const SizedBox(height: 8),
                    Text(translations?.claySoil ?? 'Clay Soil'),
                    Text(translations?.claySoilManagement1 ?? 'Avoid working when wet'),
                  ],
                ),
              ),
            ),
          ),
          // Add more soil types as needed
        ],
      ),
    );
  }

  void _showSoilDetails(BuildContext context, String soilType) {
    final Map<String, Map<String, dynamic>> soilDetails = {
      AppLocalizations.of(context)?.sandySoil ?? 'Sandy Soil': {
        'characteristics': [
          AppLocalizations.of(context)?.sandySoilCharacteristic1 ?? 'Light and well-aerated',
          AppLocalizations.of(context)?.sandySoilCharacteristic2 ?? 'Warms up quickly in spring',
          AppLocalizations.of(context)?.sandySoilCharacteristic3 ?? 'Drains water quickly',
          AppLocalizations.of(context)?.sandySoilCharacteristic4 ?? 'Low in nutrients',
          AppLocalizations.of(context)?.sandySoilCharacteristic5 ?? 'Easy to work with',
        ],
        'bestCrops': [
          AppLocalizations.of(context)?.sandySoilBestCrop1 ?? 'Carrots',
          AppLocalizations.of(context)?.sandySoilBestCrop2 ?? 'Potatoes',
          AppLocalizations.of(context)?.sandySoilBestCrop3 ?? 'Radishes',
          AppLocalizations.of(context)?.sandySoilBestCrop4 ?? 'Lettuce',
          AppLocalizations.of(context)?.sandySoilBestCrop5 ?? 'Strawberries',
        ],
        'management': [
          AppLocalizations.of(context)?.sandySoilManagement1 ?? 'Add organic matter regularly',
          AppLocalizations.of(context)?.sandySoilManagement2 ?? 'Use mulch to retain moisture',
          AppLocalizations.of(context)?.sandySoilManagement3 ?? 'Frequent but light watering',
          AppLocalizations.of(context)?.sandySoilManagement4 ?? 'Regular fertilization needed',
        ],
        'color': Colors.amber[100],
        'icon': Icons.grain,
        'image': 'assets/images/agriculture/sandy_soil.png',
      },
      AppLocalizations.of(context)?.claySoil ?? 'Clay Soil': {
        'characteristics': [
          AppLocalizations.of(context)?.claySoilCharacteristic1 ?? 'Heavy and dense',
          AppLocalizations.of(context)?.claySoilCharacteristic2 ?? 'Retains water well',
          AppLocalizations.of(context)?.claySoilCharacteristic3 ?? 'Rich in nutrients',
          AppLocalizations.of(context)?.claySoilCharacteristic4 ?? 'Slow to warm in spring',
          AppLocalizations.of(context)?.claySoilCharacteristic5 ?? 'Can be difficult to work',
        ],
        'bestCrops': [
          AppLocalizations.of(context)?.claySoilBestCrop1 ?? 'Wheat',
          AppLocalizations.of(context)?.claySoilBestCrop2 ?? 'Rice',
          AppLocalizations.of(context)?.claySoilBestCrop3 ?? 'Cabbage',
          AppLocalizations.of(context)?.claySoilBestCrop4 ?? 'Broccoli',
          AppLocalizations.of(context)?.claySoilBestCrop5 ?? 'Beans',
        ],
        'management': [
          AppLocalizations.of(context)?.claySoilManagement1 ?? 'Avoid working when wet',
          AppLocalizations.of(context)?.claySoilManagement2 ?? 'Add organic matter to improve structure',
          AppLocalizations.of(context)?.claySoilManagement3 ?? 'Improve drainage if needed',
          AppLocalizations.of(context)?.claySoilManagement4 ?? 'Deep watering but less frequent',
        ],
        'color': Colors.brown[100],
        'icon': Icons.landscape,
        'image': 'assets/images/agriculture/clay_soil.png',
      },
    };

    final details = soilDetails[soilType];
    if (details == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: details['color'] ?? Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Scaffold(
                              appBar: AppBar(
                                backgroundColor: Colors.black,
                                iconTheme: const IconThemeData(color: Colors.white),
                                title: Text(
                                  soilType,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              backgroundColor: Colors.black,
                              body: Center(
                                child: InteractiveViewer(
                                  minScale: 0.5,
                                  maxScale: 4.0,
                                  child: Image.asset(
                                    details['image'] as String,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      child: Hero(
                        tag: details['image'],
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: AssetImage(details['image'] as String),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          details['icon'] as IconData? ?? Icons.landscape,
                          size: 32,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          soilType,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle(context, 'Characteristics'),
                    _buildBulletPoints(context, details['characteristics'] as List),
                    const SizedBox(height: 16),
                    _buildSectionTitle(context, 'Best Crops'),
                    _buildBulletPoints(context, details['bestCrops'] as List),
                    const SizedBox(height: 16),
                    _buildSectionTitle(context, 'Management Tips'),
                    _buildBulletPoints(context, details['management'] as List),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Widget _buildBulletPoints(BuildContext context, List points) {
    return Column(
      children: points.map((point) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.circle,
              size: 8,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                point,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  void _showARSimulation(BuildContext context) {
    // Implement AR visualization using AR packages
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AR Simulation'),
        content: const Text('AR simulation feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    String description,
    List<String> points,
  ) {
    // Get the translations
    final translations = AppLocalizations.of(context);
    
    // If it's the crop selection section, use the translated points
    if (title == 'cropSelection') {
      points = [
        translations?.cropContent1 ?? points[0],
        translations?.cropContent2 ?? points[1],
        translations?.cropContent3 ?? points[2],
        translations?.cropContent4 ?? points[3],
        translations?.cropContent5 ?? points[4],
        translations?.cropContent6 ?? points[5],
      ];
    }
    // If it's the soil management section
    else if (title == 'soilManagement') {
      points = [
        translations?.soilContent1 ?? points[0],
        translations?.soilContent2 ?? points[1],
        translations?.soilContent3 ?? points[2],
        translations?.soilContent4 ?? points[3],
        translations?.soilContent5 ?? points[4],
        translations?.soilContent6 ?? points[5],
      ];
    }
    // If it's the irrigation section
    else if (title == 'irrigation') {
      points = [
        translations?.irrigationContent1 ?? points[0],
        translations?.irrigationContent2 ?? points[1],
        translations?.irrigationContent3 ?? points[2],
        translations?.irrigationContent4 ?? points[3],
        translations?.irrigationContent5 ?? points[4],
        translations?.irrigationContent6 ?? points[5],
      ];
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getSectionTitle(context, title),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ...points.map((point) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.arrow_right, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          point,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherImpactSection() {
    final translations = AppLocalizations.of(context);
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            translations?.weatherImpactTitle ?? 'Weather Impact on Crops',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.wb_sunny, color: Colors.orange),
                    title: Text(translations?.temperatureImpactTitle ?? 'Temperature'),
                    subtitle: Text(translations?.temperatureImpactDesc ?? 'Affects growth rate and development'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.water_drop, color: Colors.blue),
                    title: Text(translations?.rainfallImpactTitle ?? 'Rainfall'),
                    subtitle: Text(translations?.rainfallImpactDesc ?? 'Critical for germination and growth'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.air, color: Colors.grey),
                    title: Text(translations?.windImpactTitle ?? 'Wind'),
                    subtitle: Text(translations?.windImpactDesc ?? 'Influences pollination and plant structure'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.brightness_5, color: Colors.yellow),
                    title: Text(translations?.sunlightImpactTitle ?? 'Sunlight'),
                    subtitle: Text(translations?.sunlightImpactDesc ?? 'Essential for photosynthesis'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYoutubePlayer(String videoId) {
    final WebViewController controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString('''
        <html>
          <body style="margin:0;padding:0">
            <iframe 
              width="100%" 
              height="100%" 
              src="https://www.youtube.com/embed/${videoId}?rel=0"
              frameborder="0" 
              allowfullscreen>
            </iframe>
          </body>
        </html>
      ''');

    return Container(
      height: 220,
      child: WebViewWidget(controller: controller),
    );
  }

  void _showCropDetails(BuildContext context, Map<String, dynamic> cycle) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(cycle['title']),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTap: () {
                    // Show full screen image when tapped
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Scaffold(
                          appBar: AppBar(
                            backgroundColor: Colors.black,
                            iconTheme: const IconThemeData(color: Colors.white),
                          ),
                          backgroundColor: Colors.black,
                          body: Center(
                            child: InteractiveViewer(
                              minScale: 0.5,
                              maxScale: 4.0,
                              child: Image.asset(
                                cycle['image'],
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  child: Hero(
                    tag: cycle['image'],
                    child: Image.asset(
                      cycle['image'],
                      height: 300,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.grass,
                            color: Theme.of(context).colorScheme.primary,
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              cycle['title'],
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Duration: ${cycle["duration"]}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Growth Stages',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...List.generate(
                        (cycle['stages'] as List<String>).length,
                        (index) {
                          final stage = cycle['stages'][index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      stage,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      // Video section at the end
                      if (cycle['title'] == 'Rice Crop Cycle' || cycle['title'] == 'Wheat Crop Cycle') ...[
                        const SizedBox(height: 32),
                        Text(
                          'Watch ${cycle['title'].split(' ')[0]} Farming Video',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildYoutubePlayer(
                          cycle['title'] == 'Rice Crop Cycle' 
                            ? '-eBrAm64fpg'
                            : 'xVO9bjuhB58'
                        ),
                        const SizedBox(height: 16),
                      ],
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