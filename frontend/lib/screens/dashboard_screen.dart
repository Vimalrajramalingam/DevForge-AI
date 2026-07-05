import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/models/project.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/project_provider.dart';
import 'package:frontend/core/theme.dart';
import 'package:frontend/widgets/glass_card.dart';
import 'package:frontend/widgets/sidebar.dart';
import 'package:frontend/screens/project_detail_screen.dart';
import 'package:frontend/screens/history_screen.dart';
import 'package:frontend/screens/progress_screen.dart';
import 'package:frontend/screens/health_screen.dart';
import 'package:frontend/screens/improvements_screen.dart';
import 'package:frontend/screens/profile_screen.dart';
import 'package:frontend/screens/settings_screen.dart';
import 'package:frontend/screens/about_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load projects list on startup
    Future.microtask(() {
      Provider.of<ProjectProvider>(context, listen: false).fetchProjects();
    });
  }

  void _onNavigationChanged(int index) {
    setState(() {
      _currentNavIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget activeView;
    switch (_currentNavIndex) {
      case 0:
        activeView = const DashboardView();
        break;
      case 1:
        activeView = const HistoryScreen();
        break;
      case 2:
        activeView = const ProgressScreen();
        break;
      case 3:
        activeView = const HealthScreen();
        break;
      case 4:
        activeView = const ImprovementsScreen();
        break;
      case 5:
        activeView = const ProfileScreen();
        break;
      case 6:
        activeView = const SettingsScreen();
        break;
      case 7:
        activeView = const AboutScreen();
        break;
      default:
        activeView = const DashboardView();
    }

    return ResponsiveNavigation(
      selectedIndex: _currentNavIndex,
      onDestinationSelected: _onNavigationChanged,
      child: activeView,
    );
  }
}

class DashboardView extends StatelessWidget {
  const DashboardView({Key? key}) : super(key: key);

  void _showCreateProjectDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final usersController = TextEditingController();
    final budgetController = TextEditingController();
    final timelineController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Theme.of(context).dividerColor,
            ),
          ),
          title: Text(
            "New Software Idea",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Project Name",
                        hintText: "e.g., FoodDelivery App, TaskFlow SaaS",
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: "Short Description",
                        hintText: "Describe the core features and concept...",
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: usersController,
                      decoration: const InputDecoration(
                        labelText: "Target Users",
                        hintText: "e.g., Students, Remote Teams, Small Businesses",
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: budgetController,
                            decoration: const InputDecoration(
                              labelText: "Budget",
                              hintText: "e.g., \$10k, Flexible",
                            ),
                            validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: timelineController,
                            decoration: const InputDecoration(
                              labelText: "Timeline",
                              hintText: "e.g., 3 months, 6 weeks",
                            ),
                            validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                
                final success = await projectProvider.createProject(
                  name: nameController.text.trim(),
                  description: descController.text.trim(),
                  targetUsers: usersController.text.trim(),
                  budget: budgetController.text.trim(),
                  timeline: timelineController.text.trim(),
                );

                if (success && ctx.mounted) {
                  Navigator.of(ctx).pop();
                  // Automatically navigate to project detail screen
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ProjectDetailScreen(),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Generate Workspace"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final projectProvider = Provider.of<ProjectProvider>(context);
    final userName = authProvider.user?.fullName ?? "Developer";

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Dashboard",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => projectProvider.fetchProjects(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => projectProvider.fetchProjects(),
        color: AppTheme.primaryBlue,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Message
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Hello, $userName 👋",
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Welcome to your AI workspace. Select or create a project to deploy your agents.",
                          style: TextStyle(color: Color(0xff9ca3af), fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateProjectDialog(context),
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text("New Project Plan"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Statistics Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 800 ? 3 : 1;
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: crossAxisCount == 3 ? 2.5 : 4,
                    children: [
                      _buildStatCard(
                        context,
                        title: "Total Projects",
                        value: "${projectProvider.projects.length}",
                        icon: Icons.folder_copy_outlined,
                        color: AppTheme.primaryBlue,
                      ),
                      _buildStatCard(
                        context,
                        title: "AI Actions Taken",
                        value: "Active",
                        icon: Icons.smart_toy_outlined,
                        color: AppTheme.secondaryEmerald,
                      ),
                      _buildStatCard(
                        context,
                        title: "System Status",
                        value: "Online",
                        icon: Icons.cloud_done_outlined,
                        color: AppTheme.accentIndigo,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 36),

              // Recent Projects
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Recent Plans",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      // Programmatically route to History view
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Use bottom nav / sidebar to view History")),
                      );
                    },
                    child: const Text("View All History", style: TextStyle(color: AppTheme.primaryBlue)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              projectProvider.isLoadingList
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: CircularProgressIndicator(color: AppTheme.primaryBlue),
                      ),
                    )
                  : projectProvider.projects.isEmpty
                      ? _buildEmptyState(context)
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: MediaQuery.of(context).size.width > 900 ? 3 : (MediaQuery.of(context).size.width > 600 ? 2 : 1),
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.6,
                          ),
                          itemCount: projectProvider.projects.take(6).length,
                          itemBuilder: (ctx, i) {
                            final project = projectProvider.projects[i];
                            return _buildProjectCard(context, project);
                          },
                        ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return GlassCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).brightness == Brightness.dark ? const Color(0xff9ca3af) : const Color(0xff64748b),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildProjectCard(BuildContext context, ProjectModel project) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: () {
        final provider = Provider.of<ProjectProvider>(context, listen: false);
        provider.selectProject(project);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const ProjectDetailScreen(),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    project.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    "Plan Active",
                    style: TextStyle(fontSize: 10, color: AppTheme.primaryBlue, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                project.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? const Color(0xff9ca3af) : const Color(0xff64748b),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Timeline: ${project.timeline}",
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                ),
                Text(
                  "Budget: ${project.budget}",
                  style: const TextStyle(fontSize: 11, color: AppTheme.secondaryEmerald, fontWeight: FontWeight.bold),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 48),
          Icon(
            Icons.folder_open_outlined,
            size: 64,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            "No Projects Found",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Create your first software concept to begin generation.",
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _showCreateProjectDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text("Create Workspace"),
          ),
        ],
      ),
    );
  }
}
