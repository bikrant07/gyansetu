import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PoultryPage extends StatelessWidget {
  const PoultryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.poultryFarming ?? 'Poultry Farming'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            context,
            'Breed Selection',
            AppLocalizations.of(context)?.breedSelectionDesc ?? 'Choose the right breeds for your farm',
            [
              AppLocalizations.of(context)?.breedContent1 ?? 'Layer breeds: White Leghorn, Rhode Island Red',
              AppLocalizations.of(context)?.breedContent2 ?? 'Broiler breeds: Cobb 500, Ross 308',
              AppLocalizations.of(context)?.breedContent3 ?? 'Dual-purpose breeds: Plymouth Rock, Australorp',
              AppLocalizations.of(context)?.breedContent4 ?? 'Consider climate adaptability of breeds',
              AppLocalizations.of(context)?.breedContent5 ?? 'Evaluate feed conversion efficiency',
              AppLocalizations.of(context)?.breedContent6 ?? 'Check disease resistance characteristics',
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            'Housing',
            'Proper housing management',
            [
              'Adequate ventilation and temperature control',
              'Appropriate space per bird',
              'Clean and dry litter management',
              'Proper lighting systems',
              'Biosecurity measures',
              'Regular cleaning and disinfection',
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            'Nutrition',
            'Feed and nutrition management',
            [
              'Age-appropriate feed formulation',
              'Clean and fresh water supply',
              'Feed storage and quality control',
              'Supplement requirements',
              'Feeding schedules',
              'Cost-effective feed alternatives',
            ],
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
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
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
                      const Icon(Icons.fiber_manual_record, size: 12),
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
} 