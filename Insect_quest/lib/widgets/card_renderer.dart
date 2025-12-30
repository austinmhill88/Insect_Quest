import 'dart:io';
import 'package:flutter/material.dart';
import '../models/arthropod_card.dart';

/// Widget that renders an ArthropodCard with placeholder frame.
///
/// Displays the card with:
/// - Placeholder frame border
/// - Captured photo
/// - Taxonomic name (species or genus)
/// - Rarity tier with color coding
/// - Quality score
/// - Special traits as badges
/// - Foil effect overlay (if applicable)
class CardRenderer extends StatelessWidget {
  final ArthropodCard card;
  final bool showDetails;

  const CardRenderer({
    super.key,
    required this.card,
    this.showDetails = true,
  });

  /// Get color for rarity tier
  Color _getRarityColor(String rarity) {
    switch (rarity) {
      case "Legendary":
        return Colors.amber.shade700;
      case "Epic":
        return Colors.purple.shade700;
      case "Rare":
        return Colors.blue.shade700;
      case "Uncommon":
        return Colors.green.shade700;
      case "Common":
      default:
        return Colors.grey.shade700;
    }
  }

  /// Get icon for rarity tier
  IconData _getRarityIcon(String rarity) {
    switch (rarity) {
      case "Legendary":
        return Icons.stars;
      case "Epic":
        return Icons.auto_awesome;
      case "Rare":
        return Icons.diamond;
      case "Uncommon":
        return Icons.hexagon;
      case "Common":
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Card frame background
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/cards/card_frame_placeholder.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Photo section
                AspectRatio(
                  aspectRatio: 1.33,
                  child: Container(
                    margin: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.amber.shade700, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.file(
                      File(card.imageUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade800,
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.white54,
                            size: 48,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Info section
                if (showDetails)
                  Container(
                    margin: const EdgeInsets.fromLTRB(30, 0, 30, 30),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _getRarityColor(card.rarity), width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name
                        Row(
                          children: [
                            Icon(
                              _getRarityIcon(card.rarity),
                              color: _getRarityColor(card.rarity),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                card.displayName,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _getRarityColor(card.rarity),
                                  fontStyle: card.species == null ? FontStyle.italic : FontStyle.normal,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Rarity and Quality
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getRarityColor(card.rarity).withOpacity(0.3),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: _getRarityColor(card.rarity)),
                              ),
                              child: Text(
                                card.rarity.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _getRarityColor(card.rarity),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  '${(card.quality * 100).toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Traits
                        if (card.traits.isNotEmpty)
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: card.traits.map((trait) {
                              IconData icon;
                              Color color;
                              
                              switch (trait) {
                                case "state_species":
                                  icon = Icons.star;
                                  color = Colors.amber;
                                  break;
                                case "invasive":
                                  icon = Icons.warning_amber_rounded;
                                  color = Colors.orange;
                                  break;
                                case "venomous":
                                  icon = Icons.health_and_safety;
                                  color = Colors.red;
                                  break;
                                default:
                                  icon = Icons.label;
                                  color = Colors.blue;
                              }

                              return Chip(
                                avatar: Icon(icon, size: 14, color: color),
                                label: Text(
                                  trait.replaceAll('_', ' ').toUpperCase(),
                                  style: const TextStyle(fontSize: 10),
                                ),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              );
                            }).toList(),
                          ),

                        // Timestamp
                        const SizedBox(height: 4),
                        Text(
                          '${card.timestamp.year}-${card.timestamp.month.toString().padLeft(2, '0')}-${card.timestamp.day.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Foil overlay effect
          if (card.foil)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.3),
                      Colors.transparent,
                      Colors.white.withOpacity(0.3),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.25, 0.75, 1.0],
                  ),
                ),
              ),
            ),

          // Foil badge
          if (card.foil)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade700, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'FOIL',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
