import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/project_provider.dart';
import 'package:frontend/core/api_client.dart';
import 'package:frontend/core/theme.dart';
import 'package:frontend/widgets/glass_card.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({Key? key}) : super(key: key);

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _healthData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHealth();
  }

  Future<void> _loadHealth() async {
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
      final response = await apiClient.get('/api/projects/${project.id}/health');
      if (response.statusCode == 200) {
        setState(() {
          _healthData = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Failed to load health data.";
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
    if (_errorMessage != null || _healthData == null) {
      return Center(child: Text(_errorMessage ?? "Error loading health score"));
    }

    final double overallScore = _healthData!['overall_score'] as double;
    final String grade = _healthData!['grade'] as String;
    final String summary = _healthData!['summary'] as String;
    final List<dynamic> categories = _healthData!['categories'];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Project Health Analyzer", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall Score Card
            GlassCard(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          const Text("OVERALL SCORE", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
                          const SizedBox(height: 8),
                          Text(
                            "${overallScore.toInt()}/100",
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: overallScore >= 80 ? AppTheme.secondaryEmerald : (overallScore >= 50 ? Colors.orange : AppTheme.riskRed),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 48),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          grade,
                          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(summary, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15)),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            Text(
              "Health by Category",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Radar Chart or Grid of Categories
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 800 ? 3 : (MediaQuery.of(context).size.width > 500 ? 2 : 1),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final double score = (cat['score'] as num).toDouble();
                final double maxScore = (cat['max_score'] as num).toDouble();
                final String name = cat['category'];
                final String desc = cat['description'];
                final String colorStr = cat['color'];
                
                Color c;
                if (colorStr == "green") c = AppTheme.secondaryEmerald;
                else if (colorStr == "yellow") c = Colors.orange;
                else c = AppTheme.riskRed;

                return GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text("${score.toInt()}/${maxScore.toInt()}", style: TextStyle(fontWeight: FontWeight.bold, color: c, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: score / maxScore,
                        color: c,
                        backgroundColor: c.withOpacity(0.2),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Text(desc, style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 3, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
