class StatsModel {
  final int activeProjects;
  final int activeAlerts;
  final String totalBudget;
  final double averageProgress;
  final DateTime lastUpdated;

  StatsModel({
    required this.activeProjects,
    required this.activeAlerts,
    required this.totalBudget,
    required this.averageProgress,
    required this.lastUpdated,
  });

  factory StatsModel.fromJson(Map<String, dynamic> json) {
    return StatsModel(
      activeProjects: json['activeProjects'] ?? 0,
      activeAlerts: json['activeAlerts'] ?? 0,
      totalBudget: json['totalBudget'] ?? '\$0',
      averageProgress: (json['averageProgress'] ?? 0.0).toDouble(),
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'activeProjects': activeProjects,
      'activeAlerts': activeAlerts,
      'totalBudget': totalBudget,
      'averageProgress': averageProgress,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}