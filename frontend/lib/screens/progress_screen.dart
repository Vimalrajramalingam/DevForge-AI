import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/project_provider.dart';
import 'package:frontend/core/api_client.dart';
import 'package:frontend/core/theme.dart';
import 'package:frontend/widgets/glass_card.dart';
import 'package:percent_indicator/percent_indicator.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({Key? key}) : super(key: key);

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _progressData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
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
      final response = await apiClient.get('/api/projects/${project.id}/progress');
      if (response.statusCode == 200) {
        setState(() {
          _progressData = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Failed to load progress data.";
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
    }
    if (_errorMessage != null || _progressData == null) {
      return Center(child: Text(_errorMessage ?? "Error loading progress"));
    }

    final double completionPercentage = _progressData!['completion_percentage'] as double;
    final int completedCount = _progressData!['completed_count'] as int;
    final int totalStages = _progressData!['total_stages'] as int;
    final List<dynamic> stages = _progressData!['stages'];
    final String? currentStage = _progressData!['current_stage'];
    final String? nextStep = _progressData!['next_recommended_step'];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Project Progress", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header summary
            GlassCard(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  CircularPercentIndicator(
                    radius: 60.0,
                    lineWidth: 12.0,
                    percent: completionPercentage / 100,
                    center: Text(
                      "${completionPercentage.toInt()}%",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                    ),
                    progressColor: AppTheme.primaryBlue,
                    backgroundColor: Theme.of(context).dividerColor,
                    circularStrokeCap: CircularStrokeCap.round,
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Development Progress",
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "$completedCount of $totalStages stages completed.",
                          style: const TextStyle(fontSize: 16),
                        ),
                        if (currentStage != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryEmerald.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("NEXT RECOMMENDED STEP", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.secondaryEmerald)),
                                const SizedBox(height: 4),
                                Text(nextStep ?? "Continue working", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ]
                      ],
                    ),
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            Text(
              "SDLC Stages",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Stages List
            ...stages.map((stage) {
              final bool completed = stage['completed'] as bool;
              final String name = (stage['stage'] as String).toUpperCase();
              final bool isCurrent = stage['stage'] == currentStage;
              
              return GlassCard(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: completed ? AppTheme.secondaryEmerald : (isCurrent ? AppTheme.primaryBlue : Theme.of(context).dividerColor),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        completed ? Icons.check : (isCurrent ? Icons.play_arrow : Icons.lock_outline),
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                          if (isCurrent)
                            const Text("In Progress", style: TextStyle(fontSize: 12, color: AppTheme.primaryBlue)),
                        ],
                      ),
                    ),
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
