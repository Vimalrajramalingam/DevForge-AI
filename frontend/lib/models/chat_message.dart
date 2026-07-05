class ChatMessage {
  final int id;
  final int projectId;
  final String role;
  final String message;
  final String createdAt;

  ChatMessage({
    required this.id,
    required this.projectId,
    required this.role,
    required this.message,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as int,
      projectId: json['project_id'] as int,
      role: json['role'] as String,
      message: json['message'] as String,
      createdAt: json['created_at'] as String,
    );
  }

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
}
