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
    try {
      return ProjectImageModel(
        id: json['id'] ?? '',
        projectId: _extractProjectId(json['project']),
        imageUrl: json['imageUrl'] ?? '',
        filename: json['filename'] ?? '',
        originalName: json['originalName'] ?? '',
        size: json['size'] ?? 0,
        mimetype: json['mimetype'] ?? '',
        description: json['description'],
        uploadedAt: DateTime.parse(
          json['uploadedAt'] ?? DateTime.now().toIso8601String(),
        ),
        uploadedBy: _extractUploadedBy(json['uploadedBy']),
      );
    } catch (e) {
      print('❌ Error parsing ProjectImageModel: $e');
      print('❌ JSON data: $json');
      rethrow;
    }
  }

  static String _extractProjectId(dynamic project) {
    if (project == null) return '';
    if (project is String) return project;
    if (project is Map<String, dynamic>) {
      return project['_id'] ?? project['id'] ?? '';
    }
    return '';
  }

  static Map<String, dynamic>? _extractUploadedBy(dynamic uploadedBy) {
    if (uploadedBy == null) return null;
    if (uploadedBy is Map<String, dynamic>) return uploadedBy;
    if (uploadedBy is String) {
      return {'id': uploadedBy, 'name': 'Usuario', 'email': ''};
    }
    return null;
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
