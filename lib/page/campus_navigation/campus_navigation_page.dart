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
  final _waypointCtrls = <TextEditingController>[];
  RouteResult? _result;
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
      final r = await CampusNavigationService.findRoute(depart, _waypointCtrls.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList(), dest);

      // fullPath 재구성 (P_ 노드 포함)
      final graph = CampusNavigationService.buildCampusGraph(CampusNavigationService.allCoords, CampusNavigationService.walkableEdges);
      final stops = r.orderedStops;
      final fullPath = <String>[];
      for (int i = 0; i < stops.length - 1; i++) {
        final (seg, _) = CampusNavigationService.aStar(stops[i], stops[i + 1], graph, CampusNavigationService.allCoords);
        if (seg != null) {
          fullPath.addAll(fullPath.isEmpty ? seg : seg.skip(1));
        }
      }

      setState(() {
        _result = r;
        _fullPath = fullPath;
      });
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
    return Scaffold(
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
                    onAddWaypoint: () => setState(() => _waypointCtrls.add(TextEditingController())),
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
    );
  }
}
