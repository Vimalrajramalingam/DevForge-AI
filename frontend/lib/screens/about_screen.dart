import 'package:flutter/material.dart';
import 'package:frontend/core/theme.dart';
import 'package:frontend/widgets/glass_card.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "About DevForge AI",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Logo banner
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.psychology,
                      color: AppTheme.primaryBlue,
                      size: 54,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "DevForge AI",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                  ),
                  const Text(
                    "SaaS Software Project Manager v1.0.0",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            Text(
              "Application Core Purpose",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: Text(
                "DevForge AI is an advanced planning suite that transforms simple software ideas into production-ready blueprints. Using specialized AI Agents, DevForge automatically configures functional specs, database ER diagrams, REST endpoint schemas, UI planners, test cases, and task schedules within seconds.",
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark ? const Color(0xffd1d5db) : Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            Text(
              "Specialized Agents Architecture",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildAgentTile(
                    Icons.analytics_outlined,
                    "Requirements Analyzer",
                    "Establishes goals, functional boundaries, and business requirements scope.",
                  ),
                  const Divider(height: 1),
                  _buildAgentTile(
                    Icons.account_tree_outlined,
                    "Architecture Designer",
                    "Creates system folders, suggestions stack, and architectural sequences.",
                  ),
                  const Divider(height: 1),
                  _buildAgentTile(
                    Icons.storage_outlined,
                    "Database Architect",
                    "Renders ER schemas, table details, keys, indexes, and copies SQL DDL.",
                  ),
                  const Divider(height: 1),
                  _buildAgentTile(
                    Icons.api_outlined,
                    "REST API Generator",
                    "Produces endpoint routes, requests, replies, errors, and validation structures.",
                  ),
                  const Divider(height: 1),
                  _buildAgentTile(
                    Icons.palette_outlined,
                    "UI Designer",
                    "Formulates interface templates, visual colors, and user sequence outlines.",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Credits
            const Center(
              child: Text(
                "Powered by Google Gemini | Built with Flutter & FastAPI",
                style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentTile(IconData icon, String name, String desc) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryBlue, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.3)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
