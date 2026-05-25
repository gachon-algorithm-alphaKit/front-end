import 'dart:math';

import '../model/route_model.dart';

class CampusNavigationService {
  // ─────────────────────────────────────────────────────────
  // 실제 건물 목록: 백엔드 API 또는 로컬 JSON에서 로드
  // TODO: GET /api/campus/buildings → List<Building>
  // ─────────────────────────────────────────────────────────
  static const buildings = <Building>[
    Building(name: '가천관', alias: '가천관', lat: 37.4491, lng: 127.1273),
    Building(name: '비전타워', alias: '비전', lat: 37.4499, lng: 127.1281),
    Building(name: '공과대학1관', alias: '공대1', lat: 37.4483, lng: 127.1265),
    Building(name: '공과대학2관', alias: '공대2', lat: 37.4480, lng: 127.1270),
    Building(name: 'AI도서관', alias: '도서관', lat: 37.4496, lng: 127.1278),
    Building(name: '제1학생생활관', alias: '기숙사1', lat: 37.4473, lng: 127.1255),
    Building(name: '제3학생생활관', alias: '기숙사3', lat: 37.4469, lng: 127.1260),
    Building(name: '교육대학원', alias: '교육대학원', lat: 37.4487, lng: 127.1290),
    Building(name: '학생회관', alias: '학생회관', lat: 37.4492, lng: 127.1262),
    Building(name: '의과대학', alias: '의대', lat: 37.4502, lng: 127.1295),
    Building(name: '약학대학', alias: '약대', lat: 37.4497, lng: 127.1268),
    Building(name: 'IT대학', alias: 'IT관', lat: 37.4485, lng: 127.1285),
  ];

  static List<String> get buildingNames =>
      buildings.map((b) => b.name).toList();

  // ─────────────────────────────────────────────────────────
  // 경로 탐색 (A* + 순열 최적화)
  // TODO: POST /api/campus/route
  //   Body: { departure, waypoints:[], destination }
  //   Response: RouteResult JSON
  // ─────────────────────────────────────────────────────────
  static Future<RouteResult> findRoute(
    String departure,
    List<String> waypoints,
    String destination,
  ) async {
    await Future.delayed(const Duration(milliseconds: 800)); // 네트워크 시뮬레이션

    // MOCK: 실제 A* 알고리즘 결과 대체
    final allStops = [departure, ...waypoints, destination];
    final segments = <WaypointResult>[];
    double total = 0;
    for (int i = 0; i < allStops.length - 1; i++) {
      final dist = (_mockDistance(allStops[i], allStops[i + 1]) * 1000)
          .roundToDouble();
      total += dist;
      segments.add(
        WaypointResult(
          from: allStops[i],
          to: allStops[i + 1],
          distanceM: dist,
          path: [allStops[i], '경유지점 A', '경유지점 B', allStops[i + 1]],
        ),
      );
    }
    return RouteResult(
      orderedStops: allStops,
      totalDistanceM: total,
      segments: segments,
    );
  }

  static double _mockDistance(String a, String b) {
    final ba = buildings.firstWhere(
      (x) => x.name == a,
      orElse: () => buildings[0],
    );
    final bb = buildings.firstWhere(
      (x) => x.name == b,
      orElse: () => buildings[1],
    );
    final dlat = ba.lat - bb.lat, dlng = ba.lng - bb.lng;
    return sqrt(dlat * dlat + dlng * dlng) * 111; // 대략적 km
  }
}
