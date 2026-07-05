import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:frontend/providers/project_provider.dart';
import 'package:frontend/models/report.dart';
import 'package:frontend/core/theme.dart';
import 'package:frontend/screens/chat_screen.dart' as frontend_chat;

class ProjectDetailScreen extends StatefulWidget {
  const ProjectDetailScreen({Key? key}) : super(key: key);

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  String _selectedAgent = "requirements";

  final List<Map<String, dynamic>> _agentsList = [
    {"id": "chat", "name": "AI Chat Assistant", "icon": Icons.chat_bubble_outline},
    {"id": "requirements", "name": "Requirements Analyzer", "icon": Icons.analytics_outlined},
    {"id": "architecture", "name": "Architecture Generator", "icon": Icons.account_tree_outlined},
    {"id": "database", "name": "Database Designer", "icon": Icons.storage_outlined},
    {"id": "api", "name": "API Generator", "icon": Icons.api_outlined},
    {"id": "ui", "name": "UI Planner", "icon": Icons.palette_outlined},
    {"id": "test", "name": "Test Case Generator", "icon": Icons.fact_check_outlined},
    {"id": "docs", "name": "Documentation Generator", "icon": Icons.description_outlined},
    {"id": "risk", "name": "Risk Analyzer", "icon": Icons.gpp_bad_outlined},
    {"id": "tasks", "name": "Task Planner (Kanban)", "icon": Icons.view_kanban_outlined},
  ];

  Widget _buildContentArea() {
    if (_selectedAgent == "chat") {
      return const frontend_chat.ChatScreen();
    }
    
    return WorkstationPanel(
      agentType: _selectedAgent,
      agentName: _agentsList.firstWhere((a) => a['id'] == _selectedAgent)['name'],
    );
  }

  @override
  Widget build(BuildContext context) {
    final projectProvider = Provider.of<ProjectProvider>(context);
    final project = projectProvider.selectedProject;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (project == null) {
      return const Scaffold(
        body: Center(child: Text("No project selected")),
      );
    }

    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              project.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              "Timeline: ${project.timeline} | Budget: ${project.budget}",
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          _buildExportDropdown(context, project.id),
        ],
      ),
      body: isWide
          ? Row(
              children: [
                // Desktop left agents navigation panel
                Container(
                  width: 260,
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                      ),
                    ),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _agentsList.length,
                    itemBuilder: (ctx, i) {
                      final agent = _agentsList[i];
                      final isSelected = _selectedAgent == agent['id'];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: InkWell(
                          onTap: () => setState(() => _selectedAgent = agent['id']),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? AppTheme.primaryBlue.withOpacity(0.1) 
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  agent['icon'],
                                  color: isSelected ? AppTheme.primaryBlue : Colors.grey,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    agent['name'],
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isSelected ? AppTheme.primaryBlue : (isDark ? Colors.white : Colors.black87),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // Workstation / Chat area
                Expanded(
                  child: _buildContentArea(),
                ),
              ],
            )
          : Column(
              children: [
                // Mobile horizontal agents list
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                      ),
                    ),
                  ),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _agentsList.length,
                    itemBuilder: (ctx, i) {
                      final agent = _agentsList[i];
                      final isSelected = _selectedAgent == agent['id'];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                        child: ChoiceChip(
                          label: Text(agent['name'], style: const TextStyle(fontSize: 12)),
                          selected: isSelected,
                          selectedColor: AppTheme.primaryBlue.withOpacity(0.2),
                          checkmarkColor: AppTheme.primaryBlue,
                          labelStyle: TextStyle(
                            color: isSelected ? AppTheme.primaryBlue : (isDark ? Colors.white70 : Colors.black87),
                          ),
                          onSelected: (val) {
                            if (val) {
                              setState(() => _selectedAgent = agent['id']);
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
                
                // Workstation / Chat area
                Expanded(
                  child: _buildContentArea(),
                ),
              ],
            ),
    );
  }

  Widget _buildExportDropdown(BuildContext context, int projectId) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.download_outlined),
      tooltip: "Export Project Plan",
      onSelected: (format) async {
        final provider = Provider.of<ProjectProvider>(context, listen: false);
        final content = await provider.fetchExportContent(projectId, format);
        if (content != null && context.mounted) {
          showDialog(
            context: context,
            builder: (ctx) {
              return AlertDialog(
                title: Text("Export: ${format.toUpperCase()}"),
                content: SizedBox(
                  width: 600,
                  height: 400,
                  child: SingleChildScrollView(
                    child: SelectionArea(
                      child: format == "json"
                          ? Text(content, style: const TextStyle(fontFamily: "monospace", fontSize: 12))
                          : MarkdownBody(data: content),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: content));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Copied to Clipboard!")),
                      );
                    },
                    child: const Text("Copy"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text("Close"),
                  ),
                ],
              );
            },
          );
        }
      },
      itemBuilder: (ctx) => [
        const PopupMenuItem(value: "json", child: Text("Export as JSON")),
        const PopupMenuItem(value: "markdown", child: Text("Export as Markdown")),
        const PopupMenuItem(value: "pdf", child: Text("Export as HTML/PDF")),
      ],
    );
  }
}

class WorkstationPanel extends StatelessWidget {
  final String agentType;
  final String agentName;

  const WorkstationPanel({
    Key? key,
    required this.agentType,
    required this.agentName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final projectProvider = Provider.of<ProjectProvider>(context);
    final isGenerating = projectProvider.isAgentGenerating(agentType);
    final report = projectProvider.reports[agentType];
    final project = projectProvider.selectedProject!;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: isGenerating
          ? _buildGeneratingState(context)
          : report == null
              ? _buildEmptyState(context, project.id)
              : _buildReportContent(context, report),
    );
  }

  Widget _buildGeneratingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            height: 64,
            width: 64,
            child: CircularProgressIndicator(
              color: AppTheme.primaryBlue,
              strokeWidth: 4,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Agent: $agentName is working...",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Analyzing inputs, executing prompts, and building database models...",
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 24),
          _buildStatusProgressLogs(context),
        ],
      ),
    );
  }

  Widget _buildStatusProgressLogs(BuildContext context) {
    return Container(
      width: 400,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 16),
              SizedBox(width: 8),
              Text("Loaded Project Scope details...", style: TextStyle(fontSize: 12, fontFamily: "monospace")),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 16),
              SizedBox(width: 8),
              Text("Preparing specialized system prompt...", style: TextStyle(fontSize: 12, fontFamily: "monospace")),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 1.5, color: AppTheme.primaryBlue),
              ),
              SizedBox(width: 8),
              Text("Invoking Gemini REST Interface...", style: TextStyle(fontSize: 12, fontFamily: "monospace", color: AppTheme.primaryBlue)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, int projectId) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.smart_toy_outlined,
            size: 64,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            "Agent Offline",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "The $agentName has not been run for this plan yet.",
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              final provider = Provider.of<ProjectProvider>(context, listen: false);
              provider.generateReport(projectId, agentType);
            },
            icon: const Icon(Icons.bolt, size: 18),
            label: Text("Run $agentName"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportContent(BuildContext context, ReportModel report) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // We build specialized workspaces based on agentType
    return Column(
      children: [
        // Action Bar for Report View
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.circle, color: Colors.green, size: 10),
                  const SizedBox(width: 8),
                  Text(
                    "Latest Version Active",
                    style: TextStyle(fontSize: 12, color: Colors.green.shade400, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  final provider = Provider.of<ProjectProvider>(context, listen: false);
                  provider.generateReport(report.projectId, agentType);
                },
                icon: const Icon(Icons.refresh, size: 14),
                label: const Text("Regenerate Plan", style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: isDark ? Colors.white70 : Colors.black87,
                  elevation: 0,
                  side: BorderSide(color: Theme.of(context).dividerColor),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ],
          ),
        ),
        
        // Main Content display
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (agentType == "tasks")
                  // Task Planner visual Kanban board
                  KanbanBoardWidget(reportContent: report.content)
                else if (agentType == "ui")
                  // UI Designer Swatches + Palette
                  UiPlannerWidget(reportContent: report.content)
                else if (agentType == "api")
                  // API Generator Endpoint lists
                  ApiEndpointsWidget(reportContent: report.content)
                else if (agentType == "database")
                  // Database DDL Code Script
                  DatabaseDesignerWidget(reportContent: report.content)
                else
                  // Standard Markdown parsed output representation
                  MarkdownReportBody(reportContent: report.content),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// --- Specialized UI Components for AI Reports ---

class MarkdownReportBody extends StatelessWidget {
  final Map<String, dynamic> reportContent;

  const MarkdownReportBody({Key? key, required this.reportContent}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Convert JSON map report keys to Markdown layout
    final buffer = StringBuffer();
    
    reportContent.forEach((key, val) {
      final title = key.replaceFirst("_", " ").toUpperCase();
      buffer.writeln("# $title\n");
      
      if (val is List) {
        for (var item in val) {
          if (item is Map) {
            item.forEach((k, v) {
              buffer.writeln("- **${k.toUpperCase()}**: $v");
            });
            buffer.writeln();
          } else {
            buffer.writeln("- $item");
          }
        }
        buffer.writeln();
      } else if (val is Map) {
        val.forEach((k, v) {
          buffer.writeln("- **$k**: $v");
        });
        buffer.writeln();
      } else {
        buffer.writeln("$val\n");
      }
      buffer.writeln("---");
    });

    return MarkdownBody(
      data: buffer.toString(),
      selectable: true,
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        h1: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryBlue,
        ),
        h2: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
        p: Theme.of(context).textTheme.bodyLarge,
        listBullet: const TextStyle(color: AppTheme.primaryBlue),
      ),
    );
  }
}

class DatabaseDesignerWidget extends StatelessWidget {
  final Map<String, dynamic> reportContent;

  const DatabaseDesignerWidget({Key? key, required this.reportContent}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final erDiagram = reportContent['er_diagram'] as String? ?? '';
    final tables = reportContent['tables'] as List<dynamic>? ?? [];
    final sqlScript = reportContent['sql_script'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("UML ER DIAGRAM", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Text(
            erDiagram,
            style: const TextStyle(fontFamily: "monospace", fontSize: 13, height: 1.4),
          ),
        ),
        const SizedBox(height: 24),
        const Text("TABLES & ATTRIBUTES", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
        const SizedBox(height: 12),
        ...tables.map((t) {
          final tMap = t as Map<String, dynamic>;
          final name = tMap['name'] as String? ?? '';
          final cols = tMap['columns'] as List<dynamic>? ?? [];
          final rels = tMap['relationships'] as List<dynamic>? ?? [];
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.table_chart_outlined, color: AppTheme.secondaryEmerald, size: 20),
                      const SizedBox(width: 8),
                      Text(name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text("Columns:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ...cols.map((col) => Text("- $col", style: const TextStyle(fontSize: 13, fontFamily: "monospace"))),
                  if (rels.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text("Relationships:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    ...rels.map((rel) => Text("- $rel", style: const TextStyle(fontSize: 13))),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("SQL DDL SCRIPT", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
            IconButton(
              icon: const Icon(Icons.copy_outlined, size: 20),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: sqlScript));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("SQL script copied!")),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Text(
            sqlScript,
            style: const TextStyle(fontFamily: "monospace", fontSize: 12, color: Colors.green, height: 1.4),
          ),
        ),
      ],
    );
  }
}

class ApiEndpointsWidget extends StatelessWidget {
  final Map<String, dynamic> reportContent;

  const ApiEndpointsWidget({Key? key, required this.reportContent}) : super(key: key);

  Color _getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case "GET":
        return Colors.green;
      case "POST":
        return Colors.blue;
      case "PUT":
        return Colors.orange;
      case "DELETE":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final endpoints = reportContent['endpoints'] as List<dynamic>? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("REST ENDPOINTS DEFINITION", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
        const SizedBox(height: 12),
        ...endpoints.map((e) {
          final eMap = e as Map<String, dynamic>;
          final path = eMap['path'] as String? ?? '';
          final method = eMap['method'] as String? ?? 'GET';
          final desc = eMap['description'] as String? ?? '';
          final request = eMap['request_body'] as String? ?? 'None';
          final response = eMap['response'] as String? ?? '';

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ExpansionTile(
              leading: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _getMethodColor(method).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: _getMethodColor(method).withOpacity(0.3)),
                ),
                child: Text(
                  method.toUpperCase(),
                  style: TextStyle(
                    color: _getMethodColor(method),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                path,
                style: const TextStyle(fontFamily: "monospace", fontSize: 14, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(desc, style: const TextStyle(fontSize: 12)),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Request Body Scheme:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(request, style: const TextStyle(fontFamily: "monospace", fontSize: 11)),
                      ),
                      const SizedBox(height: 12),
                      const Text("Response Body Scheme (200 OK):", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(response, style: const TextStyle(fontFamily: "monospace", fontSize: 11, color: Colors.green)),
                      ),
                    ],
                  ),
                )
              ],
            ),
          );
        }).toList()
      ],
    );
  }
}

class UiPlannerWidget extends StatelessWidget {
  final Map<String, dynamic> reportContent;

  const UiPlannerWidget({Key? key, required this.reportContent}) : super(key: key);

  Color _parseColor(String? hexString) {
    if (hexString == null) return Colors.blue;
    final buffer = StringBuffer();
    if (hexString.length == 7 && hexString.startsWith('#')) {
      buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    }
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    final palette = reportContent['palette'] as Map<String, dynamic>? ?? {};
    final screens = reportContent['screens'] as List<dynamic>? ?? [];
    final typography = reportContent['typography'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("VISUAL BRAND COLOR PALETTE", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
        const SizedBox(height: 12),
        Row(
          children: palette.entries.map((entry) {
            final colorValue = _parseColor(entry.value as String?);
            return Expanded(
              child: Card(
                margin: const EdgeInsets.only(right: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: colorValue,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        entry.key.toUpperCase(),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "${entry.value}",
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        const Text("SCREEN MOCKUPS & INTERACTIVE FLOWS", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
        const SizedBox(height: 12),
        ...screens.map((s) {
          final sMap = s as Map<String, dynamic>;
          final name = sMap['name'] as String? ?? '';
          final desc = sMap['description'] as String? ?? '';
          final comps = sMap['components'] as List<dynamic>? ?? [];
          final navs = sMap['navigation'] as List<dynamic>? ?? [];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(desc, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 12),
                  const Text("Key Widgets:", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    children: comps.map((c) => Chip(
                      label: Text(c as String, style: const TextStyle(fontSize: 11)),
                      padding: EdgeInsets.zero,
                    )).toList(),
                  ),
                  if (navs.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text("Navigation Outlets:", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 4),
                    ...navs.map((n) => Text("→ $n", style: const TextStyle(fontSize: 12))),
                  ]
                ],
              ),
            ),
          );
        }).toList(),
        if (typography.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text("TYPOGRAPHY SYSTEM", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
          const SizedBox(height: 12),
          ...typography.map((t) {
            String text = '';
            if (t is Map) {
              final styleVal = t['style'] ?? '';
              final fontVal = t['font'] ?? '';
              final sizeVal = t['size'] ?? '';
              text = "$styleVal: $fontVal $sizeVal";
            } else {
              text = t.toString();
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: AppTheme.primaryBlue, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      text,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ],
    );
  }
}

class KanbanBoardWidget extends StatefulWidget {
  final Map<String, dynamic> reportContent;

  const KanbanBoardWidget({Key? key, required this.reportContent}) : super(key: key);

  @override
  State<KanbanBoardWidget> createState() => _KanbanBoardWidgetState();
}

class _KanbanBoardWidgetState extends State<KanbanBoardWidget> {
  late List<String> _todo;
  late List<String> _inProgress;
  late List<String> _done;

  @override
  void initState() {
    super.initState();
    _loadKanbanData();
  }

  @override
  void didUpdateWidget(covariant KanbanBoardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadKanbanData();
  }

  void _loadKanbanData() {
    final kanban = widget.reportContent['kanban'] as Map<String, dynamic>? ?? {};
    _todo = List<String>.from(kanban['todo'] ?? []);
    _inProgress = List<String>.from(kanban['in_progress'] ?? []);
    _done = List<String>.from(kanban['done'] ?? []);
  }

  void _moveTask(String task, String from, String to) {
    setState(() {
      if (from == "todo") _todo.remove(task);
      if (from == "progress") _inProgress.remove(task);
      if (from == "done") _done.remove(task);

      if (to == "todo") _todo.add(task);
      if (to == "progress") _inProgress.add(task);
      if (to == "done") _done.add(task);
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 900;

    final columns = [
      _buildKanbanColumn(
        context,
        title: "TO DO",
        tasks: _todo,
        color: Colors.blueAccent,
        columnId: "todo",
        nextColumnId: "progress",
        prevColumnId: null,
      ),
      _buildKanbanColumn(
        context,
        title: "IN PROGRESS",
        tasks: _inProgress,
        color: Colors.orangeAccent,
        columnId: "progress",
        nextColumnId: "done",
        prevColumnId: "todo",
      ),
      _buildKanbanColumn(
        context,
        title: "DONE",
        tasks: _done,
        color: Colors.greenAccent,
        columnId: "done",
        nextColumnId: null,
        prevColumnId: "progress",
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("INTERACTIVE TASK KANBAN BOARD", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
        const SizedBox(height: 16),
        isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: columns.map((c) => Expanded(child: c)).toList(),
              )
            : Column(
                children: columns.map((c) => Padding(padding: const EdgeInsets.only(bottom: 16), child: c)).toList(),
              ),
      ],
    );
  }

  Widget _buildKanbanColumn(
    BuildContext context, {
    required String title,
    required List<String> tasks,
    required Color color,
    required String columnId,
    required String? nextColumnId,
    required String? prevColumnId,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13, letterSpacing: 0.5),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Text("${tasks.length}", style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (tasks.isEmpty)
            Container(
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5), style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(child: Text("Column empty", style: TextStyle(color: Colors.grey, fontSize: 11))),
            )
          else
            ...tasks.map((task) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: Theme.of(context).brightness == Brightness.dark 
                    ? const Color(0xff1e202b) 
                    : Colors.white,
                elevation: 0.5,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(task, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (prevColumnId != null)
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios, size: 12, color: Colors.grey),
                              onPressed: () => _moveTask(task, columnId, prevColumnId),
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                            ),
                          if (nextColumnId != null)
                            IconButton(
                              icon: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                              onPressed: () => _moveTask(task, columnId, nextColumnId),
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                            ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            }).toList()
        ],
      ),
    );
  }
}
