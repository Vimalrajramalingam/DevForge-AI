import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/core/api_client.dart';
import 'package:frontend/models/project.dart';
import 'package:frontend/models/report.dart';

class ProjectProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<ProjectModel> _projects = [];
  ProjectModel? _selectedProject;
  
  // Maps agentType -> ReportModel
  Map<String, ReportModel> _reports = {};
  
  bool _isLoadingList = false;
  bool _isLoadingDetails = false;
  
  // Tracks loading state for each AI Agent generation
  final Map<String, bool> _agentGeneratingStates = {};
  
  String? _errorMessage;

  List<ProjectModel> get projects => _projects;
  ProjectModel? get selectedProject => _selectedProject;
  Map<String, ReportModel> get reports => _reports;
  bool get isLoadingList => _isLoadingList;
  bool get isLoadingDetails => _isLoadingDetails;
  String? get errorMessage => _errorMessage;

  bool isAgentGenerating(String agentType) => _agentGeneratingStates[agentType] ?? false;

  void selectProject(ProjectModel? project) {
    _selectedProject = project;
    _reports = {};
    if (project != null) {
      fetchProjectReports(project.id);
    }
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchProjects() async {
    _isLoadingList = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.get('/api/projects');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _projects = data.map((json) => ProjectModel.fromJson(json)).toList();
        _isLoadingList = false;
        notifyListeners();
      } else {
        _errorMessage = 'Failed to load projects';
        _isLoadingList = false;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Network error: cannot load projects';
      _isLoadingList = false;
      notifyListeners();
    }
  }

  Future<bool> createProject({
    required String name,
    required String description,
    required String targetUsers,
    required String budget,
    required String timeline,
  }) async {
    _isLoadingDetails = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.post('/api/projects', {
        'name': name,
        'description': description,
        'target_users': targetUsers,
        'budget': budget,
        'timeline': timeline,
      });

      if (response.statusCode == 200) {
        final newProject = ProjectModel.fromJson(jsonDecode(response.body));
        _projects.insert(0, newProject);
        _selectedProject = newProject;
        _isLoadingDetails = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to create project';
        _isLoadingDetails = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Network error: unable to create project';
      _isLoadingDetails = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchProjectReports(int projectId) async {
    _isLoadingDetails = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.get('/api/projects/$projectId/reports');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _reports = {};
        for (var json in data) {
          final report = ReportModel.fromJson(json);
          _reports[report.agentType] = report;
        }
        _isLoadingDetails = false;
        notifyListeners();
      } else {
        _errorMessage = 'Failed to load reports';
        _isLoadingDetails = false;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Network error: unable to fetch reports';
      _isLoadingDetails = false;
      notifyListeners();
    }
  }

  Future<bool> generateReport(int projectId, String agentType) async {
    _agentGeneratingStates[agentType] = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.post('/api/projects/$projectId/generate/$agentType', {});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reportContent = data['content'] as Map<String, dynamic>;
        
        // Update reports list manually
        final newReport = ReportModel(
          id: DateTime.now().millisecondsSinceEpoch, // temporary local id
          projectId: projectId,
          agentType: agentType,
          content: reportContent,
          createdAt: DateTime.now().toIso8601String(),
        );
        _reports[agentType] = newReport;
        
        _agentGeneratingStates[agentType] = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'AI Agent generation failed for $agentType';
        _agentGeneratingStates[agentType] = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Generation connection timeout or error.';
      _agentGeneratingStates[agentType] = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProject(int projectId) async {
    _isLoadingList = true;
    notifyListeners();

    try {
      final response = await _apiClient.delete('/api/projects/$projectId');
      if (response.statusCode == 200) {
        _projects.removeWhere((p) => p.id == projectId);
        if (_selectedProject?.id == projectId) {
          _selectedProject = null;
          _reports = {};
        }
        _isLoadingList = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = "Failed to delete project.";
    }
    
    _isLoadingList = false;
    notifyListeners();
    return false;
  }

  Future<bool> duplicateProject(int projectId) async {
    _isLoadingList = true;
    notifyListeners();

    try {
      final response = await _apiClient.post('/api/projects/$projectId/duplicate', {});
      if (response.statusCode == 200) {
        final duplicate = ProjectModel.fromJson(jsonDecode(response.body));
        _projects.insert(0, duplicate);
        _isLoadingList = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = "Failed to duplicate project.";
    }
    
    _isLoadingList = false;
    notifyListeners();
    return false;
  }

  Future<String?> fetchExportContent(int projectId, String format) async {
    try {
      final response = await _apiClient.get('/api/projects/$projectId/export/$format');
      if (response.statusCode == 200) {
        return response.body;
      }
    } catch (e) {
      // Ignored
    }
    return null;
  }
}
