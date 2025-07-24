class ProjectImageModel {
  final String id;
  final String projectId;
  final String imageUrl;
  final String filename;
  final String originalName;
  final int size;
  final String mimetype;
  final String? description;
  final DateTime uploadedAt;
  final Map<String, dynamic>? uploadedBy;

  ProjectImageModel({
    required this.id,
    required this.projectId,
    required this.imageUrl,
    required this.filename,
    required this.originalName,
    required this.size,
    required this.mimetype,
    this.description,
    required this.uploadedAt,
    this.uploadedBy,
  });

  factory ProjectImageModel.fromJson(Map<String, dynamic> json) {
    return ProjectImageModel(
      id: json['id'] ?? '',
      projectId: json['project'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      filename: json['filename'] ?? '',
      originalName: json['originalName'] ?? '',
      size: json['size'] ?? 0,
      mimetype: json['mimetype'] ?? '',
      description: json['description'],
      uploadedAt: DateTime.parse(json['uploadedAt'] ?? DateTime.now().toIso8601String()),
      uploadedBy: json['uploadedBy'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project': projectId,
      'imageUrl': imageUrl,
      'filename': filename,
      'originalName': originalName,
      'size': size,
      'mimetype': mimetype,
      'description': description,
      'uploadedAt': uploadedAt.toIso8601String(),
      'uploadedBy': uploadedBy,
    };
  }
}