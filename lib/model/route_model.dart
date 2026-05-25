class Building {
  final String name, alias;
  final double lat, lng;
  const Building({
    required this.name,
    required this.alias,
    required this.lat,
    required this.lng,
  });
}

class WaypointResult {
  final String from, to;
  final double distanceM;
  final List<String> path;
  const WaypointResult({
    required this.from,
    required this.to,
    required this.distanceM,
    required this.path,
  });
}

class RouteResult {
  final List<String> orderedStops;
  final double totalDistanceM;
  final List<WaypointResult> segments;
  const RouteResult({
    required this.orderedStops,
    required this.totalDistanceM,
    required this.segments,
  });
}

// 강의 검색
