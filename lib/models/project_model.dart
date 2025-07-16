class ProjectModel {
  final String id;
  final String name;
  final String clientName;
  final String description;
  final String location;
  final String budget;
  final String startDate;
  final String endDate;
  final double progress;
  final String status;
  final Map<String, double> keyIndicators;
  final String imageUrl;
  final String? supervisor;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProjectModel({
    required this.id,
    required this.name,
    required this.clientName,
    required this.description,
    required this.location,
    required this.budget,
    required this.startDate,
    required this.endDate,
    required this.progress,
    required this.status,
    required this.keyIndicators,
    required this.imageUrl,
    this.supervisor,
    this.createdAt,
    this.updatedAt,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      clientName: json['clientName'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      budget: json['budget'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      progress: (json['progress'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'Activo',
      keyIndicators: Map<String, double>.from(
        json['keyIndicators']?.map((key, value) => MapEntry(key, value.toDouble())) ?? 
        {
          'Calidad': 0.0,
          'Tiempo': 0.0,
          'Presupuesto': 0.0,
          'Satisfacción': 0.0,
        }
      ),
      imageUrl: json['imageUrl'] ?? 'https://images.pexels.com/photos/323780/pexels-photo-323780.jpeg?auto=compress&cs=tinysrgb&w=800',
      supervisor: json['supervisor'] is String ? json['supervisor'] : json['supervisor']?['_id'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'name': name,
      'clientName': clientName,
      'description': description,
      'location': location,
      'budget': budget,
      'startDate': startDate,
      'endDate': endDate,
      'imageUrl': imageUrl,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'name': name,
      'clientName': clientName,
      'description': description,
      'location': location,
      'budget': budget,
      'startDate': startDate,
      'endDate': endDate,
      'progress': progress,
      'status': status,
      'keyIndicators': keyIndicators,
      'imageUrl': imageUrl,
    };
  }
  ProjectModel copyWith({
    String? id,
    String? name,
    String? clientName,
    String? description,
    String? location,
    String? budget,
    String? startDate,
    String? endDate,
    double? progress,
    String? status,
    Map<String, double>? keyIndicators,
    String? imageUrl,
    String? supervisor,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      clientName: clientName ?? this.clientName,
      description: description ?? this.description,
      location: location ?? this.location,
      budget: budget ?? this.budget,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      keyIndicators: keyIndicators ?? this.keyIndicators,
      imageUrl: imageUrl ?? this.imageUrl,
      supervisor: supervisor ?? this.supervisor,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

}