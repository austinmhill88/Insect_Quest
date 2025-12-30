import 'dart:io';
import 'package:flutter/material.dart';
import '../services/anti_cheat_service.dart';

/// Admin panel stub for reviewing suspicious and rejected captures
/// Displays logged validation failures for review
class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  List<Map<String, dynamic>> suspiciousCaptures = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadSuspiciousCaptures();
  }

  Future<void> _loadSuspiciousCaptures() async {
    setState(() => loading = true);
    final captures = await AntiCheatService.getSuspiciousCaptures();
    setState(() {
      suspiciousCaptures = captures;
      loading = false;
    });
  }

  Future<void> _clearLogs() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Logs?'),
        content: const Text(
          'This will permanently delete all suspicious capture logs. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AntiCheatService.clearLogs();
      await _loadSuspiciousCaptures();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logs cleared')),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'rejected':
        return Colors.red;
      case 'flagged':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'rejected':
        return Icons.block;
      case 'flagged':
        return Icons.warning_amber_rounded;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin: Suspicious Captures'),
        actions: [
          if (suspiciousCaptures.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _clearLogs,
              tooltip: 'Clear all logs',
            ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : suspiciousCaptures.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 64, color: Colors.green),
                      SizedBox(height: 16),
                      Text(
                        'No suspicious captures logged',
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSuspiciousCaptures,
                  child: ListView.builder(
                    itemCount: suspiciousCaptures.length,
                    itemBuilder: (ctx, i) {
                      final capture = suspiciousCaptures[i];
                      final timestamp = DateTime.parse(capture['timestamp']);
                      final imagePath = capture['imagePath'];
                      final reason = capture['reason'];
                      final status = capture['status'];

                      return Card(
                        margin: const EdgeInsets.all(12),
                        child: ListTile(
                          leading: File(imagePath).existsSync()
                              ? Image.file(
                                  File(imagePath),
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.broken_image),
                                )
                              : const Icon(Icons.broken_image),
                          title: Text(
                            reason,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                'Time: ${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Path: ${imagePath.split('/').last}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          trailing: Chip(
                            label: Text(
                              status.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            avatar: Icon(
                              _getStatusIcon(status),
                              size: 16,
                              color: Colors.white,
                            ),
                            backgroundColor: _getStatusColor(status),
                          ),
                          onTap: () {
                            // Show detailed dialog
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text('${status.toUpperCase()} Capture'),
                                content: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Reason:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(reason),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Timestamp:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(timestamp.toString()),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Image Path:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(imagePath),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
