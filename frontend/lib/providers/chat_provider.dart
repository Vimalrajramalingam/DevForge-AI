import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/core/api_client.dart';
import 'package:frontend/models/chat_message.dart';

class ChatProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;
  int? _currentProjectId;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get currentProjectId => _currentProjectId;


  Future<void> loadHistory(int projectId) async {
    _currentProjectId = projectId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.get('/api/projects/$projectId/chat');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _messages = data.map((json) => ChatMessage.fromJson(json)).toList();
      } else {
        _errorMessage = "Failed to load chat history";
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendMessage(int projectId, String message) async {
    _isLoading = true;
    _errorMessage = null;
    
    // Optimistic UI update
    final tempId = DateTime.now().millisecondsSinceEpoch;
    final tempMsg = ChatMessage(
      id: tempId,
      projectId: projectId,
      role: 'user',
      message: message,
      createdAt: DateTime.now().toIso8601String(),
    );
    _messages.add(tempMsg);
    notifyListeners();

    try {
      final response = await _apiClient.post(
        '/api/projects/$projectId/chat',
        {'message': message},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userMsg = ChatMessage.fromJson(data['user_message']);
        final assistantMsg = ChatMessage.fromJson(data['assistant_message']);
        
        // Replace temp message with real one
        final index = _messages.indexWhere((m) => m.id == tempId);
        if (index != -1) {
          _messages[index] = userMsg;
        } else {
          _messages.add(userMsg);
        }
        
        _messages.add(assistantMsg);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = "Failed to send message";
        _messages.removeWhere((m) => m.id == tempId);
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _messages.removeWhere((m) => m.id == tempId);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> clearHistory(int projectId) async {
    try {
      final response = await _apiClient.delete('/api/projects/$projectId/chat');
      if (response.statusCode == 200) {
        _messages = [];
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
