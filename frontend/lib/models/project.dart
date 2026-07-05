class ProjectModel {
  final int id;
  final int userId;
  final String name;
  final String description;
  final String targetUsers;
  final String budget;
  final String timeline;
  final String createdAt;
  final String updatedAt;

  ProjectModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.targetUsers,
    required this.budget,
    required this.timeline,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      targetUsers: json['target_users'] as String,
      budget: json['budget'] as String,
      timeline: json['timeline'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'target_users': targetUsers,
      'budget': budget,
      'timeline': timeline,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
