import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/project_provider.dart';
import 'package:frontend/models/project.dart';
import 'package:frontend/core/theme.dart';
import 'package:frontend/widgets/glass_card.dart';
import 'package:frontend/screens/project_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projectProvider = Provider.of<ProjectProvider>(context);


    // Filter projects based on query
    final filteredProjects = projectProvider.projects.where((p) {
      final nameMatch = p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final descMatch = p.description.toLowerCase().contains(_searchQuery.toLowerCase());
      return nameMatch || descMatch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Project History",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Search Input Field
            TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              decoration: InputDecoration(
                hintText: "Search through plans by title or details...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = "";
                          });
                        },
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            
            // List of Projects
            Expanded(
              child: projectProvider.isLoadingList
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
                  : filteredProjects.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          itemCount: filteredProjects.length,
                          itemBuilder: (ctx, i) {
                            final project = filteredProjects[i];
                            return _buildHistoryCard(context, project);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, ProjectModel project) {
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    project.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  "Updated: ${project.updatedAt.split(' ').first}",
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              project.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xff9ca3af) : const Color(0xff64748b),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 12, color: isDark ? Colors.white54 : Colors.black54),
                const SizedBox(width: 4),
                Text(project.timeline, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 16),
                Icon(Icons.attach_money_outlined, size: 14, color: isDark ? Colors.white54 : Colors.black54),
                const SizedBox(width: 2),
                Text(project.budget, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),
            
            // Actions Toolbar
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.copy_outlined, color: AppTheme.primaryBlue, size: 18),
                  tooltip: "Duplicate Plan",
                  onPressed: () async {
                    final success = await provider.duplicateProject(project.id);
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Plan duplicated successfully"), backgroundColor: AppTheme.secondaryEmerald),
                      );
                    }
                  },
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppTheme.riskRed, size: 18),
                  tooltip: "Delete Plan",
                  onPressed: () => _confirmDelete(context, project.id),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    provider.selectProject(project);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProjectDetailScreen()),
                    );
                  },
                  icon: const Icon(Icons.launch_outlined, size: 14),
                  label: const Text("Open Plan", style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, int projectId) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Delete Plan"),
          content: const Text("Are you sure you want to delete this software plan? This cannot be undone."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                final provider = Provider.of<ProjectProvider>(context, listen: false);
                final success = await provider.deleteProject(projectId);
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Plan deleted"), backgroundColor: Colors.amber),
                  );
                }
              },
              child: const Text("Delete", style: TextStyle(color: AppTheme.riskRed)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_outlined,
            size: 64,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            "No Matching Project Plans",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Try adjusting your search criteria.",
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
