// ============================================================
// campus_navigation_service.dart
//
// Python campus_route.py 완전 이식
// 알고리즘: 우선순위 큐 기반 A* + Nearest Neighbor 탐욕 알고리즘
// ============================================================

import 'dart:collection';
import 'dart:math';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../model/route_model.dart';

class CampusNavigationService {
  // ----------------------------------------------------------
  // 1. 가천대학교 건물 좌표 데이터 (Python: BUILDING_COORDS)
  // ----------------------------------------------------------
  static const Map<String, (double, double)> buildingCoords = {
    '가천관':           (37.4503, 127.1298),
    '비전타워':         (37.4495, 127.1275),
    '반도체대학':       (37.4510, 127.1272),
    '한의과대학':       (37.4500, 127.1285),
    '바이오나노연구원': (37.4498, 127.1280),
    '글로벌센터':       (37.4519, 127.1271),
    '바이오나노대학':   (37.4512, 127.1296),
    '공과대학1':        (37.4516, 127.1280),
    '공과대학2':        (37.4492, 127.1285),
    '예술·체육대학1':   (37.4522, 127.1287),
    '예술·체육대학2':   (37.4516, 127.1297),
    '대학원':           (37.4527, 127.1301),
    '교육대학원':       (37.4519, 127.1318),
    '중앙도서관':       (37.4524, 127.1328),
    '학생회관':         (37.4529, 127.1344),
    'AI관':             (37.4551, 127.1335),
    '제1학생생활관':    (37.4563, 127.1355),
    '제2학생생활관':    (37.4560, 127.1340),
    '제3학생생활관':    (37.4558, 127.1332),
    '운동장':           (37.4550, 127.1351),
  };

  // ----------------------------------------------------------
  // 2. 건물 별칭 (Python: BUILDING_ALIASES)
  // ----------------------------------------------------------
  static const Map<String, String> buildingAliases = {
    '기숙사':    '제2학생생활관',
    '제1기숙사': '제1학생생활관',
    '제2기숙사': '제2학생생활관',
    '제3기숙사': '제3학생생활관',
    '공대1':     '공과대학1',
    '공대2':     '공과대학2',
    '예체대1':   '예술·체육대학1',
    '예체대2':   '예술·체육대학2',
  };

  // ----------------------------------------------------------
  // 3. 캠퍼스 인도 경로 노드 (Python: PATH_NODES)
  // ----------------------------------------------------------
  static const Map<String, (double, double)> pathNodes = {
    'P_01': (37.4505, 127.1271),
    'P_02': (37.4505, 127.1275),
    'P_03': (37.4504, 127.1279),
    'P_04': (37.4490, 127.1279),
    'P_05': (37.4490, 127.1291),
    'P_06': (37.4500, 127.1294),
    'P_07': (37.4499, 127.1296),
    'P_08': (37.4509, 127.1298),
    'P_09': (37.4517, 127.1275),
    'P_10': (37.4519, 127.1286),
    'P_11': (37.4512, 127.1288),
    'P_12': (37.4514, 127.1298),
    'P_13': (37.4513, 127.1301),
    'P_14': (37.4508, 127.1302),
    'P_15': (37.4509, 127.1303),
    'P_16': (37.4512, 127.1309),
    'P_17': (37.4519, 127.1312),
    'P_18': (37.4525, 127.1305),
    'P_19': (37.4527, 127.1327),
    'P_20': (37.4534, 127.1340),
    'P_21': (37.4552, 127.1332),
    'P_22': (37.4538, 127.1347),
    'P_23': (37.4550, 127.1347),
    'P_24': (37.4558, 127.1346),
  };

  // 모든 노드 (건물 + 경로 노드) — Python: ALL_COORDS
  static Map<String, (double, double)> get allCoords => {
        ...buildingCoords,
        ...pathNodes,
      };

  // ----------------------------------------------------------
  // 4. 보행 가능한 엣지 정의 (Python: WALKABLE_EDGES)
  // ----------------------------------------------------------
  static const List<(String, String)> walkableEdges = [
    // 건물 <-> 인접 경로 노드
    ('비전타워',       'P_01'),
    ('비전타워',       'P_02'),
    ('반도체대학',     'P_01'),
    ('반도체대학',     'P_02'),
    ('글로벌센터',     'P_09'),
    ('바이오나노연구원', 'P_03'),
    ('바이오나노연구원', 'P_04'),
    ('바이오나노연구원', '공과대학2'),
    ('한의과대학',     'P_03'),
    ('한의과대학',     'P_06'),
    ('한의과대학',     '바이오나노연구원'),
    ('한의과대학',     '공과대학2'),
    ('공과대학2',      'P_04'),
    ('공과대학2',      'P_05'),
    ('가천관',         'P_06'),
    ('가천관',         'P_07'),
    ('가천관',         'P_08'),
    ('공과대학1',      'P_03'),
    ('공과대학1',      'P_09'),
    ('공과대학1',      'P_10'),
    ('바이오나노대학', 'P_11'),
    ('바이오나노대학', 'P_12'),
    ('예술·체육대학1', 'P_10'),
    ('예술·체육대학2', 'P_12'),
    ('교육대학원',     'P_17'),
    ('대학원',         'P_18'),
    ('중앙도서관',     'P_19'),
    ('학생회관',       'P_20'),
    ('AI관',           'P_21'),
    ('제3학생생활관',  'P_21'),
    ('제2학생생활관',  'P_24'),
    ('제1학생생활관',  'P_24'),
    ('운동장',         'P_23'),
    // 경로 노드 <-> 경로 노드
    ('P_01', 'P_02'),
    ('P_02', 'P_03'),
    ('P_02', 'P_09'),
    ('P_03', 'P_04'),
    ('P_03', 'P_06'),
    ('P_04', 'P_05'),
    ('P_05', 'P_06'),
    ('P_06', 'P_07'),
    ('P_06', 'P_08'),
    ('P_08', 'P_14'),
    ('P_09', 'P_10'),
    ('P_10', 'P_11'),
    ('P_10', 'P_18'),
    ('P_11', 'P_12'),
    ('P_12', 'P_13'),
    ('P_13', 'P_14'),
    ('P_14', 'P_15'),
    ('P_15', 'P_16'),
    ('P_16', 'P_17'),
    ('P_17', 'P_18'),
    ('P_17', 'P_19'),
    ('P_18', 'P_19'),
    ('P_19', 'P_20'),
    ('P_20', 'P_21'),
    ('P_20', 'P_22'),
    ('P_21', 'P_24'),
    ('P_22', 'P_23'),
    ('P_23', 'P_24'),
  ];

  // 건물 이름 목록 (UI 자동완성용)
  static List<String> get buildingNames => buildingCoords.keys.toList();

  // ----------------------------------------------------------
  // 5. 별칭 → 실제 건물명 변환 (Python: resolve_name)
  // ----------------------------------------------------------
  static String resolveName(String name) =>
      buildingAliases[name] ?? name;

  // ----------------------------------------------------------
  // 6. Haversine 거리 계산 (단위: m) (Python: haversine_distance)
  // ----------------------------------------------------------
  static double haversineDistance(
      (double, double) coord1, (double, double) coord2) {
    const r = 6371000.0;
    final lat1 = coord1.$1 * pi / 180;
    final lon1 = coord1.$2 * pi / 180;
    final lat2 = coord2.$1 * pi / 180;
    final lon2 = coord2.$2 * pi / 180;
    final dlat = lat2 - lat1;
    final dlon = lon2 - lon1;
    final a = sin(dlat / 2) * sin(dlat / 2) +
        cos(lat1) * cos(lat2) * sin(dlon / 2) * sin(dlon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  // ----------------------------------------------------------
  // 7. 그래프 생성 (Python: build_campus_graph)
  // ----------------------------------------------------------
  static Map<String, Map<String, double>> buildCampusGraph(
    Map<String, (double, double)> coords,
    List<(String, String)> edges,
  ) {
    final graph = <String, Map<String, double>>{
      for (final node in coords.keys) node: {},
    };
    for (final (n1, n2) in edges) {
      if (!coords.containsKey(n1) || !coords.containsKey(n2)) continue;
      final dist = haversineDistance(coords[n1]!, coords[n2]!);
      graph[n1]![n2] = dist;
      graph[n2]![n1] = dist; // 양방향
    }
    return graph;
  }

  // ----------------------------------------------------------
  // 8. A* 알고리즘 (Python: a_star)
  // 반환: (경로 노드 목록, 총 거리m) — 경로 없으면 (null, inf)
  // ----------------------------------------------------------
  static (List<String>?, double) aStar(
    String start,
    String goal,
    Map<String, Map<String, double>> graph,
    Map<String, (double, double)> coords,
  ) {
    // 우선순위 큐: (f_score, node)
    // Dart에는 내장 MinHeap이 없으므로 SplayTreeSet으로 구현
    final openSet =
        SplayTreeSet<(double, String)>((a, b) {
      final cmp = a.$1.compareTo(b.$1);
      return cmp != 0 ? cmp : a.$2.compareTo(b.$2);
    });

    final cameFrom = <String, String>{};
    final gScore = <String, double>{
      for (final n in graph.keys) n: double.infinity,
    };
    gScore[start] = 0.0;

    final fScore = <String, double>{
      for (final n in graph.keys) n: double.infinity,
    };
    fScore[start] = haversineDistance(coords[start]!, coords[goal]!);
    openSet.add((fScore[start]!, start));

    final closedSet = <String>{};

    while (openSet.isNotEmpty) {
      final (_, current) = openSet.first;
      openSet.remove(openSet.first);

      if (closedSet.contains(current)) continue;

      if (current == goal) {
        // 경로 재구성
        final path = <String>[];
        String node = current;
        while (cameFrom.containsKey(node)) {
          path.add(node);
          node = cameFrom[node]!;
        }
        path.add(start);
        return (path.reversed.toList(), gScore[goal]!);
      }

      closedSet.add(current);

      for (final MapEntry(:key, :value) in (graph[current] ?? {}).entries) {
        if (closedSet.contains(key)) continue;
        final tentativeG = gScore[current]! + value;
        if (tentativeG < gScore[key]!) {
          cameFrom[key] = current;
          gScore[key] = tentativeG;
          fScore[key] =
              tentativeG + haversineDistance(coords[key]!, coords[goal]!);
          openSet.add((fScore[key]!, key));
        }
      }
    }
    return (null, double.infinity);
  }

  // ----------------------------------------------------------
  // 9. Nearest Neighbor 탐욕 알고리즘 (Python: optimize_route)
  // 경유지 순서 결정 + 전체 최적 경로 반환
  // 반환: (fullPath, totalCostM, bestOrder) — 실패 시 (null, inf, [])
  // ----------------------------------------------------------
  static (List<String>?, double, List<String>) optimizeRoute(
    String start,
    String end,
    List<String> waypoints,
    Map<String, Map<String, double>> graph,
    Map<String, (double, double)> coords,
  ) {
    if (waypoints.isEmpty) {
      final (path, cost) = aStar(start, end, graph, coords);
      return (path, cost, []);
    }

    final unvisited = List<String>.from(waypoints);
    String current = start;
    final bestOrder = <String>[];
    final fullPath = <String>[];
    double totalCost = 0.0;

    // 단계 1: Nearest Neighbor — 가장 가까운 미방문 경유지 선택
    while (unvisited.isNotEmpty) {
      String? nearestNode;
      double nearestCost = double.infinity;
      List<String>? nearestSeg;

      for (final wp in unvisited) {
        final (seg, cost) = aStar(current, wp, graph, coords);
        if (seg != null && cost < nearestCost) {
          nearestNode = wp;
          nearestCost = cost;
          nearestSeg = seg;
        }
      }

      if (nearestNode == null) return (null, double.infinity, []);

      totalCost += nearestCost;
      fullPath.addAll(fullPath.isEmpty ? nearestSeg! : nearestSeg!.skip(1));
      bestOrder.add(nearestNode);
      current = nearestNode;
      unvisited.remove(nearestNode);
    }

    // 단계 2: 마지막 경유지 → 도착지
    final (seg, cost) = aStar(current, end, graph, coords);
    if (seg == null) return (null, double.infinity, []);

    totalCost += cost;
    fullPath.addAll(seg.skip(1));

    return (fullPath, totalCost, bestOrder);
  }

  // ----------------------------------------------------------
  // 10. 공개 API: findRoute (campus_navigation_page.dart에서 호출)
  //
  // departure, waypoints, destination 은 건물명 또는 별칭.
  // 내부적으로 A* + Nearest Neighbor 를 실행하고
  // RouteResult 로 변환하여 반환합니다.
  // ----------------------------------------------------------
  static Future<RouteResult> findRoute(
    String departure,
    List<String> waypoints,
    String destination,
  ) async {
    // 1) 별칭 → 정규 이름 변환
    final start = resolveName(departure.trim());
    final end   = resolveName(destination.trim());
    final wps   = waypoints
        .map((w) => resolveName(w.trim()))
        .where((w) => w.isNotEmpty)
        .toList();

    // 2) 입력 검증
    final coords = allCoords;
    for (final name in [start, end, ...wps]) {
      if (!buildingCoords.containsKey(name)) {
        throw ArgumentError('등록되지 않은 건물입니다: $name');
      }
    }

    // 3) 그래프 생성
    final graph = buildCampusGraph(coords, walkableEdges);

    // 4) 경로 탐색 (Nearest Neighbor + A*)
    final (fullPath, totalCost, bestOrder) =
        optimizeRoute(start, end, wps, graph, coords);

    if (fullPath == null) {
      throw StateError('경로를 찾을 수 없습니다. WALKABLE_EDGES 연결 관계를 확인하세요.');
    }

    // 5) WaypointResult 세그먼트 목록 생성
    //    orderedStops: 출발 → (경유지 최적 순서) → 도착
    final orderedStops = [start, ...bestOrder, end];
    final segments = <WaypointResult>[];

    for (int i = 0; i < orderedStops.length - 1; i++) {
      final from = orderedStops[i];
      final to   = orderedStops[i + 1];
      final (segPath, segCost) = aStar(from, to, graph, coords);

      // 구간 경로에서 P_ 노드를 제거하고 건물명만 표시
      final visiblePath = (segPath ?? [from, to])
          .where((n) => !n.startsWith('P_'))
          .toList();
      if (visiblePath.isEmpty) {
        visiblePath.addAll([from, to]);
      }

      segments.add(WaypointResult(
        from: from,
        to: to,
        distanceM: segCost.isInfinite ? 0 : segCost,
        path: visiblePath,
      ));
    }

    return RouteResult(
      orderedStops: orderedStops,
      totalDistanceM: totalCost,
      segments: segments,
    );
  }

  // ----------------------------------------------------------
  // 11. 네이버 Static Map API 호출 (Python: generate_static_map)
  //
  // fullPath     : A* 결과 전체 노드 목록 (P_ 포함)
  // 반환          : PNG 이미지 바이트 (Uint8List)
  // 실패 시        : null 반환
  // ----------------------------------------------------------
  static const String _clientId     = '892iyj75cq';
  static const String _clientSecret = 'ZiJpxXhpGaKwbJVRX5intB1I83C4Z3n314qZosD0';
  static const int    _mapLevel     = 16;
  static const int    _imgW         = 900;
  static const int    _imgH         = 700;

  /// 네이버 Static Maps API에서 지도 이미지를 받아 PNG 바이트로 반환합니다.
  static Future<Uint8List?> fetchNaverStaticMap(
    List<String> fullPath, {
    int w = _imgW,
    int h = _imgH,
  }) async {
    final coords = allCoords;

    final lats = fullPath.map((n) => coords[n]?.$1 ?? 0.0).toList();
    final lons = fullPath.map((n) => coords[n]?.$2 ?? 0.0).toList();

    final centerLat = (lats.reduce(min) + lats.reduce(max)) / 2;
    final centerLon = (lons.reduce(min) + lons.reduce(max)) / 2;

    final uri = Uri.https(
      'maps.apigw.ntruss.com',
      '/map-static/v2/raster',
      {
        'w': '$w',
        'h': '$h',
        'center': '${centerLon.toStringAsFixed(7)},${centerLat.toStringAsFixed(7)}',
        'level': '$_mapLevel',
        'format': 'png',
      },
    );

    try {
      final response = await http.get(
        uri,
        headers: {
          'X-NCP-APIGW-API-KEY-ID': _clientId,
          'X-NCP-APIGW-API-KEY':    _clientSecret,
          'Referer':                 'http://localhost',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ----------------------------------------------------------
  // 12. 위경도 → 오버레이 픽셀 좌표 변환 (Python: latlon_to_pixel)
  //
  // 네이버 Static Map 이미지(w×h) 위에서 해당 노드의
  // 픽셀 좌표를 계산합니다.
  // ----------------------------------------------------------
  static (double, double) latLonToPixel(
    double lat,
    double lon,
    double centerLat,
    double centerLon, {
    int w = _imgW,
    int h = _imgH,
  }) {
    // Python과 동일: level+1 보정
    final totalPx = 256 * (1 << (_mapLevel + 1));

    final dx = (lon - centerLon) * (totalPx / 360.0);

    double mercY(double latDeg) {
      final r = latDeg * pi / 180;
      return log(tan(pi / 4 + r / 2));
    }

    final dy = -(mercY(lat) - mercY(centerLat)) * (totalPx / (2 * pi));

    return (w / 2 + dx, h / 2 + dy);
  }

  /// fullPath 의 중심 좌표를 반환 (오버레이 Painter 에서 사용)
  static (double, double) routeCenter(List<String> fullPath) {
    final coords = allCoords;
    final lats = fullPath.map((n) => coords[n]?.$1 ?? 0.0).toList();
    final lons = fullPath.map((n) => coords[n]?.$2 ?? 0.0).toList();
    return (
      (lats.reduce(min) + lats.reduce(max)) / 2,
      (lons.reduce(min) + lons.reduce(max)) / 2,
    );
  }
}
