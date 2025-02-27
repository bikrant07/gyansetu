import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class FishFarmingPage extends StatelessWidget {
  const FishFarmingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.fishFarming ?? 'Fish Farming'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            context,
            'Pond Management',
            AppLocalizations.of(context)?.pondManagementDesc ?? 'Maintain optimal pond conditions',
            [
              'Monitor water quality parameters (pH, oxygen, ammonia)',
              'Maintain proper stocking density',
              'Implement aeration systems',
              'Regular pond cleaning and maintenance',
              'Feed management and scheduling',
              'Disease prevention and control',
            ],
            Icons.water,
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            'Species Selection',
            'Choose suitable fish species',
            [
              'Consider local climate and water conditions',
              'Market demand and price analysis',
              'Growth rate and feed conversion efficiency',
              'Disease resistance and hardiness',
              'Compatibility with other species',
              'Local regulations and permits',
            ],
            Icons.set_meal,
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            'Water Quality',
            'Regular water testing and monitoring',
            [
              'Regular water testing and monitoring',
              'Proper filtration systems',
              'Water exchange schedules',
              'Algae control methods',
              'Waste management practices',
              'Emergency procedures',
            ],
            Icons.opacity,
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
    IconData icon,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 24, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
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
                      const Icon(Icons.check_circle_outline, size: 20),
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