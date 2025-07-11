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
  });

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
    );
  }

  // Sample projects for demonstration
  static List<ProjectModel> getSampleProjects() {
    return [
      ProjectModel(
        id: '1',
        name: 'Centro Comercial Plaza Norte',
        clientName: 'Manufactura Industrial SAC',
        description: 'En construcción',
        location: 'Guayaquil',
        budget: 'USD 2,500,000',
        startDate: '01/01/2024',
        endDate: '31/12/2024',
        progress: 0.75,
        status: 'Activo',
        keyIndicators: {
          'Calidad': 0.85,
          'Tiempo': 0.92,
          'Presupuesto': 0.68,
          'Satisfacción': 0.78,
        },
        imageUrl: 'https://images.pexels.com/photos/323780/pexels-photo-323780.jpeg?auto=compress&cs=tinysrgb&w=800',
      ),
      ProjectModel(
        id: '2',
        name: 'Complejo Residencial Norte',
        clientName: 'Constructora del Norte',
        description: 'En construcción',
        location: 'Quito',
        budget: 'USD 1,800,000',
        startDate: '15/02/2024',
        endDate: '15/10/2024',
        progress: 0.45,
        status: 'Activo',
        keyIndicators: {
          'Calidad': 0.72,
          'Tiempo': 0.65,
          'Presupuesto': 0.88,
          'Satisfacción': 0.70,
        },
        imageUrl: 'https://images.pexels.com/photos/1105766/pexels-photo-1105766.jpeg?auto=compress&cs=tinysrgb&w=800',
      ),
      ProjectModel(
        id: '3',
        name: 'Torre Empresarial Central',
        clientName: 'Grupo Empresarial Central',
        description: 'En construcción',
        location: 'Cuenca',
        budget: 'USD 3,200,000',
        startDate: '10/03/2024',
        endDate: '10/01/2025',
        progress: 0.85,
        status: 'Activo',
        keyIndicators: {
          'Calidad': 0.90,
          'Tiempo': 0.85,
          'Presupuesto': 0.75,
          'Satisfacción': 0.88,
        },
        imageUrl: 'https://images.pexels.com/photos/1105766/pexels-photo-1105766.jpeg?auto=compress&cs=tinysrgb&w=800',
      ),
    ];
  }
}