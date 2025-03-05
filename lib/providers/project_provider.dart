import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project.dart';
import '../services/cospend_api_service.dart';

class ProjectProvider with ChangeNotifier {
  List<Project> _projects = [];
  Project? _selectedProject;
  bool _isLoading = false;
  String? _error;

  List<Project> get projects => List.unmodifiable(_projects);
  Project? get selectedProject => _selectedProject;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadProjects() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      debugPrint('ProjectProvider - Loading projects from Cospend API');
      _projects = await CospendApiService.getProjects();
      
      // Load selected project from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final selectedProjectId = prefs.getString('selected_project_id');
      
      if (_projects.isEmpty) {
        _selectedProject = null;
      } else if (selectedProjectId != null) {
        try {
          _selectedProject = _projects.firstWhere(
            (project) => project.id == selectedProjectId,
          );
        } catch (_) {
          // If the saved project is not found, use the first project
          _selectedProject = _projects.first;
        }
      } else {
        _selectedProject = _projects.first;
      }

      // Save the selected project ID
      if (_selectedProject != null) {
        await prefs.setString('selected_project_id', _selectedProject!.id);
      } else {
        await prefs.remove('selected_project_id');
      }

      debugPrint('ProjectProvider - Loaded ${_projects.length} projects');
      if (_selectedProject != null) {
        debugPrint('ProjectProvider - Selected project: ${_selectedProject!.name}');
      }

      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('ProjectProvider - Error loading projects: $e');
      debugPrint('Stack trace: $stackTrace');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setSelectedProject(String projectId) async {
    try {
      final project = _projects.firstWhere((p) => p.id == projectId);
      _selectedProject = project;
      
      // Save the selection to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_project_id', projectId);
      
      debugPrint('ProjectProvider - Selected project updated: ${project.name}');
      notifyListeners();
    } catch (e) {
      debugPrint('ProjectProvider - Error setting selected project: $e');
      _error = 'Project not found: $projectId';
      notifyListeners();
    }
  }

  Future<void> addProject(Project project) async {
    try {
      // TODO: Implement when Cospend API supports project creation
      _error = 'Project creation not supported yet';
      notifyListeners();
    } catch (e) {
      debugPrint('ProjectProvider - Error adding project: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateProject(Project project) async {
    try {
      // TODO: Implement when Cospend API supports project updates
      _error = 'Project updates not supported yet';
      notifyListeners();
    } catch (e) {
      debugPrint('ProjectProvider - Error updating project: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteProject(String projectId) async {
    try {
      // TODO: Implement when Cospend API supports project deletion
      _error = 'Project deletion not supported yet';
      
      if (_selectedProject?.id == projectId) {
        _selectedProject = null;
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('selected_project_id');
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('ProjectProvider - Error deleting project: $e');
      _error = e.toString();
      notifyListeners();
    }
  }
} 