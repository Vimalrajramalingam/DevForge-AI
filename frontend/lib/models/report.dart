import 'dart:convert';

class ReportModel {
  final int id;
  final int projectId;
  final String agentType;
  final Map<String, dynamic> content;
  final String createdAt;

  ReportModel({
    required this.id,
    required this.projectId,
    required this.agentType,
    required this.content,
    required this.createdAt,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> parsedContent = {};
    try {
      final rawContent = json['content'] as String;
      parsedContent = jsonDecode(rawContent) as Map<String, dynamic>;
    } catch (e) {
      // Fallback if it is already a decoded map
      if (json['content'] is Map) {
        parsedContent = Map<String, dynamic>.from(json['content'] as Map);
      }
    }
    
    return ReportModel(
      id: json['id'] as int,
      projectId: json['project_id'] as int,
      agentType: json['agent_type'] as String,
      content: parsedContent,
      createdAt: json['created_at'] as String,
    );
  }
}
