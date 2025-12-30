import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/capture.dart';
import '../utils/rarity_utils.dart';

class CardDetailPage extends StatelessWidget {
  final Capture capture;

  const CardDetailPage({super.key, required this.capture});

  @override
  Widget build(BuildContext context) {
    final rarityColor = RarityUtils.getRarityColor(capture.tier);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Details'),
        backgroundColor: rarityColor.withOpacity(0.3),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero image section
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: rarityColor.withOpacity(0.1),
                border: Border.all(
                  color: rarityColor,
                  width: 4,
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    File(capture.photoPath),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.bug_report, size: 96),
                      );
                    },
                  ),
                  // Rarity badge overlay
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: rarityColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            RarityUtils.getRarityIcon(capture.tier),
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            capture.tier,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Card information section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and species
                  Center(
                    child: Column(
                      children: [
                        Text(
                          capture.species ?? capture.genus,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: rarityColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          capture.group,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Stats section
                  _buildSectionTitle(context, 'Stats'),
                  const SizedBox(height: 12),
                  _buildStatRow(context, 'Points', '${capture.points}'),
                  _buildStatRow(context, 'Quality', '${(capture.quality * 100).toStringAsFixed(1)}%'),
                  _buildStatRow(context, 'Genus', capture.genus),
                  if (capture.species != null)
                    _buildStatRow(context, 'Species', capture.species!),
                  
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Location section
                  _buildSectionTitle(context, 'Location'),
                  const SizedBox(height: 12),
                  _buildStatRow(context, 'Region', 'North Georgia'),
                  _buildStatRow(context, 'Geocell', capture.geocell),
                  _buildStatRow(context, 'Coordinates', '${capture.lat.toStringAsFixed(4)}, ${capture.lon.toStringAsFixed(4)}'),
                  
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Collection info
                  _buildSectionTitle(context, 'Collection Info'),
                  const SizedBox(height: 12),
                  _buildStatRow(
                    context,
                    'Collected',
                    DateFormat('MMM d, yyyy at h:mm a').format(capture.timestamp),
                  ),
                  _buildStatRow(context, 'Card ID', capture.id.substring(0, 8)),
                  
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Traits section (flags)
                  _buildSectionTitle(context, 'Traits'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (capture.flags["state_species"] == true)
                        _buildTraitChip(
                          'State Species',
                          Icons.star,
                          Colors.amber,
                        ),
                      if (capture.flags["invasive"] == true)
                        _buildTraitChip(
                          'Invasive',
                          Icons.warning_amber_rounded,
                          Colors.orange,
                        ),
                      if (capture.flags["venomous"] == true)
                        _buildTraitChip(
                          'Venomous',
                          Icons.health_and_safety,
                          Colors.red,
                        ),
                      if (capture.flags["distinctive"] == true)
                        _buildTraitChip(
                          'Distinctive',
                          Icons.visibility,
                          Colors.blue,
                        ),
                      // If no traits, show placeholder
                      if (capture.flags.isEmpty || 
                          !capture.flags.values.any((v) => v == true))
                        Chip(
                          label: const Text('No special traits'),
                          avatar: const Icon(Icons.info_outline, size: 16),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[700],
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTraitChip(String label, IconData icon, Color color) {
    return Chip(
      label: Text(label),
      avatar: Icon(icon, size: 16, color: color),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color, width: 1),
    );
  }
}
