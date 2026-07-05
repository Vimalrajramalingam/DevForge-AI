import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/project_provider.dart';
import 'package:frontend/core/api_client.dart';
import 'package:frontend/core/theme.dart';
import 'package:frontend/widgets/glass_card.dart';

class ImprovementsScreen extends StatefulWidget {
  const ImprovementsScreen({Key? key}) : super(key: key);

  @override
  State<ImprovementsScreen> createState() => _ImprovementsScreenState();
}

class _ImprovementsScreenState extends State<ImprovementsScreen> {
  bool _isLoading = true;
  List<dynamic>? _suggestions;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadImprovements();
  }

  Future<void> _loadImprovements() async {
    final project = Provider.of<ProjectProvider>(context, listen: false).selectedProject;
    if (project == null) {
      setState(() {
        _errorMessage = "No project selected.";
        _isLoading = false;
      });
      return;
    }

    try {
      final apiClient = ApiClient();
      final response = await apiClient.get('/api/projects/${project.id}/improvements');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _suggestions = data['suggestions'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Failed to load improvements.";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'security': return Icons.security;
      case 'architecture': return Icons.architecture;
      case 'database': return Icons.storage;
      case 'api': return Icons.api;
      case 'testing': return Icons.bug_report;
      case 'documentation': return Icons.description;
      case 'performance': return Icons.speed;
      case 'devops': return Icons.cloud;
      default: return Icons.tips_and_updates;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high': return AppTheme.riskRed;
      case 'medium': return Colors.orange;
      case 'low': return AppTheme.secondaryEmerald;
      default: return AppTheme.primaryBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
    }
    if (_errorMessage != null || _suggestions == null) {
      return Center(child: Text(_errorMessage ?? "Error loading improvements"));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Improvements", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Recommended Actions",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "AI-generated suggestions to improve your project's architecture, security, and maintainability.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            
            if (_suggestions!.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(48.0),
                  child: Text("Your project is in excellent shape! No major improvements needed."),
                ),
              )
            else
              ..._suggestions!.map((suggestion) {
                final String category = suggestion['category'];
                final String priority = suggestion['priority'];
                final String title = suggestion['title'];
                final String desc = suggestion['description'];
                final List<dynamic> actions = suggestion['action_items'];
                
                final priorityColor = _getPriorityColor(priority);

                return GlassCard(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).dividerColor.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(_getCategoryIcon(category), size: 28, color: AppTheme.primaryBlue),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: priorityColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: priorityColor.withOpacity(0.5)),
                                      ),
                                      child: Text(
                                        "${priority.toUpperCase()} PRIORITY",
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: priorityColor),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(category, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(desc, style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      const Text("ACTION ITEMS:", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey)),
                      const SizedBox(height: 8),
                      ...actions.map((action) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle_outline, size: 16, color: AppTheme.secondaryEmerald),
                            const SizedBox(width: 8),
                            Expanded(child: Text(action.toString(), style: const TextStyle(fontSize: 13))),
                          ],
                        ),
                      )).toList(),
                    ],
                  ),
                );
              }).toList()
          ],
        ),
      ),
    );
  }
}
