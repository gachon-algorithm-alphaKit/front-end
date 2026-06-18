// 실행 환경: Flutter 3.x / Dart 3.x (Android / iOS / Web)
// 필요 라이브러리: 없음 (순수 Dart 모델 클래스)
// Input 데이터 출처: CampusNavigationService 길찾기 알고리즘 결과 및 자체 관리 데이터
//
// 자료구조: 캠퍼스 길찾기 데이터 모델
// - WaypointResult: 자료구조 (List<String> path) 출발지부터 도착지까지의 경로 노드 리스트
// - RouteResult: 자료구조 (List<String> orderedStops, List<WaypointResult> segments) 전체 경로 리스트
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
  // 자료구조: List<String> - 출발지에서 도착지까지 거치는 노드 목록 (경로 탐색 결과)
  final List<String> path;

  const WaypointResult({
    required this.from,
    required this.to,
    required this.distanceM,
    required this.path,
  });
}

class RouteResult {
  // 자료구조: List<String> - 전체 경로에서 방문해야 할 주요 거점(건물)들의 순서 목록
  final List<String> orderedStops;
  final double totalDistanceM;
  // 자료구조: List<WaypointResult> - 각 경유지 구간별 세부 경로(path)와 거리 정보를 담은 배열
  final List<WaypointResult> segments;

  const RouteResult({
    required this.orderedStops,
    required this.totalDistanceM,
    required this.segments,
  });
}
