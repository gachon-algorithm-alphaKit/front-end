// ============================================================
// campus_navigation_service.dart
//
// Python campus_route.py 완전 이식
// 알고리즘: 우선순위 큐 기반 A* + Nearest Neighbor 탐욕 알고리즘
// ============================================================

import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../model/route_model.dart';
import 'package:alpha_kit/config/api_constants.dart';

class CampusNavigationService {
  static const String baseUrl = ApiConstants.baseUrl;
  static bool _initialized = false;

  // ----------------------------------------------------------
  // 1. 서버에서 받아올 그래프 데이터
  // ----------------------------------------------------------
  static Map<String, (double, double)> buildingCoords = {};
  static Map<String, (double, double)> pathNodes = {};
  static Map<String, String> buildingAliases = {};
  static List<(String, String)> walkableEdges = [];

  // 모든 노드 (건물 + 경로 노드)
  static Map<String, (double, double)> get allCoords => {
        ...buildingCoords,
        ...pathNodes,
      };

  // 건물 이름 목록 (UI 자동완성용)
  static List<String> get buildingNames => buildingCoords.keys.toList();

  /// 서버에서 맵 데이터를 가져와 초기화
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      final response = await http.get(Uri.parse('$baseUrl/api/campus/graph/')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded['status'] == 'success') {
          final data = decoded['data'];
          
          buildingCoords.clear();
          pathNodes.clear();
          final nodes = data['nodes'] as Map<String, dynamic>;
          nodes.forEach((name, info) {
            final lat = (info['lat'] as num).toDouble();
            final lon = (info['lon'] as num).toDouble();
            final type = info['type'] as String;
            if (type == 'PATH') {
              pathNodes[name] = (lat, lon);
            } else {
              buildingCoords[name] = (lat, lon);
            }
          });

          walkableEdges.clear();
          final edges = data['edges'] as List;
          for (final e in edges) {
            walkableEdges.add((e[0] as String, e[1] as String));
          }

          buildingAliases.clear();
          final aliases = data['aliases'] as Map<String, dynamic>;
          aliases.forEach((k, v) {
            buildingAliases[k] = v as String;
          });

          _initialized = true;
        }
      }
    } catch (e) {
      print('Campus map init failed: $e');
    }
  }

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

    String current = start;
    final fullPath = <String>[];
    double totalCost = 0.0;

    for (final wp in waypoints) {
      final (seg, cost) = aStar(current, wp, graph, coords);
      if (seg == null) return (null, double.infinity, []);
      
      totalCost += cost;
      fullPath.addAll(fullPath.isEmpty ? seg : seg.skip(1));
      current = wp;
    }

    final (seg, cost) = aStar(current, end, graph, coords);
    if (seg == null) return (null, double.infinity, []);
    
    totalCost += cost;
    fullPath.addAll(seg.skip(1));

    return (fullPath, totalCost, List.from(waypoints));
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
    // 0) 데이터 초기화 확인
    if (!_initialized) {
      await initialize();
    }

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
  static const int    _mapLevel     = 16;
  static const int    _imgW         = 1024;
  static const int    _imgH         = 1024;

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
    final centerStr = '${centerLon.toStringAsFixed(7)},${centerLat.toStringAsFixed(7)}';

    final uri = Uri.parse('$baseUrl/api/campus/map/?w=$w&h=$h&center=$centerStr&level=$_mapLevel&format=png');

    try {
      final response = await http.get(
        uri,
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
