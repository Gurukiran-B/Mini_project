class RouteResult {
  final List<String> path;
  final double totalCost;
  final double etaMinutes;

  RouteResult({required this.path, required this.totalCost, required this.etaMinutes});

  factory RouteResult.fromJson(Map<String, dynamic> json) {
    return RouteResult(
      path: (json['path'] as List).cast<String>(),
      totalCost: (json['total_cost'] as num).toDouble(),
      etaMinutes: (json['eta_minutes'] as num).toDouble(),
    );
  }
}


