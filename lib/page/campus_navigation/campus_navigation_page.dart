// 실행 환경: Flutter 3.x / Dart 3.x (Android / iOS / Web)
// 필요 라이브러리: flutter, http (서비스 연동 시)
// 역할: 캠퍼스 길찾기 UI 및 사용자와의 상호작용
// 알고리즘 연동: A* + Nearest Neighbor (CampusNavigationService.findRoute 호출)

import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../api/campus_navigation_service.dart';
import '../../component/common_widgets.dart';
import '../../model/route_model.dart';
import 'widgets/map_visualization_card.dart';
import 'widgets/route_input_card.dart';
import 'widgets/route_result_card.dart';

class CampusNavigationPage extends StatefulWidget {
  const CampusNavigationPage({super.key});
  @override
  State<CampusNavigationPage> createState() => _CampusNavigationPageState();
}

class _CampusNavigationPageState extends State<CampusNavigationPage> {
  final _departCtrl = TextEditingController();
  final _destCtrl = TextEditingController();
  // 자료구조: List<TextEditingController> - 동적으로 추가/삭제되는 경유지 입력 컨트롤러 관리 배열
  final _waypointCtrls = <TextEditingController>[];
  // 자료구조: RouteResult - 전체 캠퍼스 경로 탐색 결과 데이터 보관
  RouteResult? _result;
  // 자료구조: List<String> - 지도에 시각화할 전체 경로 좌표 노드(P_ 포함) 리스트
  List<String>? _fullPath; // P_ 포함 전체 경로
  bool _isLoading = false;
  bool _isInitializing = true;
  String? _error;

  // 미니맵 모드
  MapMode _mapMode = MapMode.graph;

  // 네이버 지도 이미지 캐시
  Uint8List? _naverImageBytes;
  bool _naverLoading = false;
  String? _naverError;

  @override
  void initState() {
    super.initState();
    _initGraph();
  }

  Future<void> _initGraph() async {
    await CampusNavigationService.initialize();
    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  @override
  void dispose() {
    _departCtrl.dispose();
    _destCtrl.dispose();
    for (final c in _waypointCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _search() async {
    // [Input Validation]
    // Validate required fields and sanitize text inputs.
    final depart = _departCtrl.text.trim();
    final dest = _destCtrl.text.trim();
    if (depart.isEmpty || dest.isEmpty) {
      setState(() => _error = '출발지와 도착지를 입력해주세요.');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
      _fullPath = null;
      _naverImageBytes = null;
      _naverError = null;
    });
    try {
      // [Route Calculation]
      // 알고리즘: A* + Nearest Neighbor (TSP 근사) 최적 경로 및 경유지 순서 계산
      final r = await CampusNavigationService.findRoute(
        depart,
        _waypointCtrls
            .map((c) => c.text.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        dest,
      );

      // [Path Reconstruction]
      // Reconstruct full path including intermediate (P_) nodes for visualization.
      final graph = CampusNavigationService.buildCampusGraph(
        CampusNavigationService.allCoords,
        CampusNavigationService.walkableEdges,
      );
      final stops = r.orderedStops;
      final fullPath = <String>[];
      for (int i = 0; i < stops.length - 1; i++) {
        final (seg, _) = CampusNavigationService.aStar(
          stops[i],
          stops[i + 1],
          graph,
          CampusNavigationService.allCoords,
        );
        if (seg != null) {
          fullPath.addAll(fullPath.isEmpty ? seg : seg.skip(1));
        }
      }

      setState(() {
        _result = r;
        _fullPath = fullPath;
      });

      // 만약 네이버 지도 모드 상태에서 다시 검색했다면, 바로 새 경로의 지도를 요청
      if (_mapMode == MapMode.naver) {
        _loadNaverMap();
      }
    } on ArgumentError catch (e) {
      setState(() => _error = e.message.toString());
    } catch (e) {
      setState(() => _error = '경로를 찾을 수 없습니다. 건물명을 다시 확인해주세요.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 네이버 지도 이미지를 비동기 로드
  Future<void> _loadNaverMap() async {
    if (_fullPath == null || _naverImageBytes != null) return;
    setState(() {
      _naverLoading = true;
      _naverError = null;
    });
    final bytes = await CampusNavigationService.fetchNaverStaticMap(_fullPath!);
    if (!mounted) return;
    setState(() {
      _naverImageBytes = bytes;
      _naverLoading = false;
      if (bytes == null) _naverError = '네이버 지도 이미지를 불러오지 못했습니다.';
    });
  }

  void _switchMode(MapMode mode) {
    setState(() => _mapMode = mode);
    if (mode == MapMode.naver && _naverImageBytes == null) {
      _loadNaverMap();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: buildAppBar('캠퍼스 길찾기', Colors.blueAccent),
        body: _isInitializing
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // ── 입력 카드 ───────────────────────────────────────
                    RouteInputCard(
                      departCtrl: _departCtrl,
                      destCtrl: _destCtrl,
                      waypointCtrls: _waypointCtrls,
                      isLoading: _isLoading,
                      onSearch: _search,
                      onAddWaypoint: () => setState(
                        () => _waypointCtrls.add(TextEditingController()),
                      ),
                      onRemoveWaypoint: (idx) => setState(() {
                        _waypointCtrls[idx].dispose();
                        _waypointCtrls.removeAt(idx);
                      }),
                    ),

                    if (_error != null) buildErrorBanner(_error!),

                    // ── 결과 ────────────────────────────────────────────
                    if (_result != null) ...[
                      const SizedBox(height: 16),

                      // 요약 카드
                      RouteResultCard(result: _result!),

                      const SizedBox(height: 16),

                      // 지도 시각화 카드
                      MapVisualizationCard(
                        mapMode: _mapMode,
                        result: _result!,
                        fullPath: _fullPath ?? [],
                        naverImageBytes: _naverImageBytes,
                        naverLoading: _naverLoading,
                        naverError: _naverError,
                        onRetryNaver: _loadNaverMap,
                        onSwitchMode: _switchMode,
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
