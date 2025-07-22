class ActivityModel {
  final String id;
  final String title;
  final String? description;
  final String date;
  final String type;
  final String status;
  final String project;
  final String user;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ActivityModel({
    required this.id,
    required this.title,
    this.description,
    required this.date,
    required this.type,
    required this.status,
    required this.project,
    required this.user,
    this.createdAt,
    this.updatedAt,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      date: json['date'] ?? '',
      type: json['type'] ?? 'other',
      status: json['status'] ?? 'completed',
      project: json['project'] is String ? json['project'] : json['project']?['_id'] ?? '',
      user: json['user'] is String ? json['user'] : json['user']?['_id'] ?? '',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'title': title,
      'description': description,
      'date': date,
      'type': type,
      'project': project,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'title': title,
      'description': description,
      'date': date,
      'type': type,
      'status': status,
    };
  }

  ActivityModel copyWith({
    String? id,
    String? title,
    String? description,
    String? date,
    String? type,
    String? status,
    String? project,
    String? user,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ActivityModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      type: type ?? this.type,
      status: status ?? this.status,
      project: project ?? this.project,
      user: user ?? this.user,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}