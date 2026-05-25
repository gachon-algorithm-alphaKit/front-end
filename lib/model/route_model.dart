class School {
  final int schoolId;
  final String name;

  const School({required this.schoolId, required this.name});

  factory School.fromJson(Map<String, dynamic> json) {
    return School(schoolId: json['school_id'], name: json['name']);
  }

  Map<String, dynamic> toJson() {
    return {'school_id': schoolId, 'name': name};
  }

  @override
  String toString() {
    return 'School(schoolId: $schoolId, name: $name)';
  }
}

class Place {
  final int placeId;
  final int schoolId;
  final String name;
  final String placeType;
  final double latitude;
  final double longitude;

  const Place({
    required this.placeId,
    required this.schoolId,
    required this.name,
    required this.placeType,
    required this.latitude,
    required this.longitude,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      placeId: json['place_id'],
      schoolId: json['school_id'],
      name: json['name'],
      placeType: json['place_type'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'place_id': placeId,
      'school_id': schoolId,
      'name': name,
      'place_type': placeType,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  @override
  String toString() {
    return 'Place(placeId: $placeId, schoolId: $schoolId, name: $name, placeType: $placeType, latitude: $latitude, longitude: $longitude)';
  }
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
