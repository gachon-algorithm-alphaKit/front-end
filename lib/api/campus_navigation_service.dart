import 'dart:math';

import '../model/route_model.dart';

class CampusNavigationService {
  // TODO: GET /api/places?school_id=
  static const places = <Place>[
    Place(
      placeId: 1,
      schoolId: 1,
      name: '가천관',
      placeType: 'building',
      latitude: 37.4491,
      longitude: 127.1273,
    ),
    Place(
      placeId: 2,
      schoolId: 1,
      name: '비전타워',
      placeType: 'building',
      latitude: 37.4499,
      longitude: 127.1281,
    ),
    Place(
      placeId: 3,
      schoolId: 1,
      name: '공과대학1관',
      placeType: 'building',
      latitude: 37.4483,
      longitude: 127.1265,
    ),
    Place(
      placeId: 4,
      schoolId: 1,
      name: '공과대학2관',
      placeType: 'building',
      latitude: 37.4480,
      longitude: 127.1270,
    ),
    Place(
      placeId: 5,
      schoolId: 1,
      name: 'AI도서관',
      placeType: 'building',
      latitude: 37.4496,
      longitude: 127.1278,
    ),
    Place(
      placeId: 6,
      schoolId: 1,
      name: '제1학생생활관',
      placeType: 'dormitory',
      latitude: 37.4473,
      longitude: 127.1255,
    ),
    Place(
      placeId: 7,
      schoolId: 1,
      name: '제3학생생활관',
      placeType: 'dormitory',
      latitude: 37.4469,
      longitude: 127.1260,
    ),
    Place(
      placeId: 8,
      schoolId: 1,
      name: '교육대학원',
      placeType: 'building',
      latitude: 37.4487,
      longitude: 127.1290,
    ),
    Place(
      placeId: 9,
      schoolId: 1,
      name: '학생회관',
      placeType: 'building',
      latitude: 37.4492,
      longitude: 127.1262,
    ),
    Place(
      placeId: 10,
      schoolId: 1,
      name: '의과대학',
      placeType: 'building',
      latitude: 37.4502,
      longitude: 127.1295,
    ),
    Place(
      placeId: 11,
      schoolId: 1,
      name: '약학대학',
      placeType: 'building',
      latitude: 37.4497,
      longitude: 127.1268,
    ),
    Place(
      placeId: 12,
      schoolId: 1,
      name: 'IT대학',
      placeType: 'building',
      latitude: 37.4485,
      longitude: 127.1285,
    ),
  ];

  static List<String> get buildingNames => places.map((p) => p.name).toList();

  // TODO: POST /api/campus/route
  static Future<RouteResult> findRoute(
    String departure,
    List<String> waypoints,
    String destination,
  ) async {
    await Future.delayed(const Duration(milliseconds: 800));

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
    final pa = places.firstWhere((x) => x.name == a, orElse: () => places[0]);
    final pb = places.firstWhere((x) => x.name == b, orElse: () => places[1]);
    final dlat = pa.latitude - pb.latitude;
    final dlng = pa.longitude - pb.longitude;
    return sqrt(dlat * dlat + dlng * dlng) * 111;
  }
}
