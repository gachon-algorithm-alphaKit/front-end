import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../api/campus_navigation_service.dart';
import '../component/common_widgets.dart';
import '../model/route_model.dart';

// ──────────────────────────────────────────────────────────────
// 시각화 모드
// ──────────────────────────────────────────────────────────────
enum _MapMode { graph, naver }

class CampusNavigationPage extends StatefulWidget {
  const CampusNavigationPage({super.key});
  @override
  State<CampusNavigationPage> createState() => _CampusNavigationPageState();
}

class _CampusNavigationPageState extends State<CampusNavigationPage> {
  final _departCtrl    = TextEditingController();
  final _destCtrl      = TextEditingController();
  final _waypointCtrls = <TextEditingController>[];
  RouteResult? _result;
  List<String>? _fullPath; // P_ 포함 전체 경로
  bool _isLoading = false;
  String? _error;

  // 미니맵 모드
  _MapMode _mapMode = _MapMode.graph;

  // 네이버 지도 이미지 캐시
  Uint8List? _naverImageBytes;
  bool _naverLoading = false;
  String? _naverError;

  final _buildings = CampusNavigationService.buildingNames;

  @override
  void dispose() {
    _departCtrl.dispose();
    _destCtrl.dispose();
    for (final c in _waypointCtrls) c.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final depart = _departCtrl.text.trim();
    final dest   = _destCtrl.text.trim();
    if (depart.isEmpty || dest.isEmpty) {
      setState(() => _error = '출발지와 도착지를 입력해주세요.');
      return;
    }
    setState(() {
      _isLoading       = true;
      _error           = null;
      _result          = null;
      _fullPath        = null;
      _naverImageBytes = null;
      _naverError      = null;
    });
    try {
      final r = await CampusNavigationService.findRoute(
        depart,
        _waypointCtrls
            .map((c) => c.text.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        dest,
      );

      // fullPath 재구성 (P_ 노드 포함)
      final graph  = CampusNavigationService.buildCampusGraph(
        CampusNavigationService.allCoords,
        CampusNavigationService.walkableEdges,
      );
      final stops      = r.orderedStops;
      final fullPath   = <String>[];
      for (int i = 0; i < stops.length - 1; i++) {
        final (seg, _) = CampusNavigationService.aStar(
          stops[i], stops[i + 1], graph, CampusNavigationService.allCoords,
        );
        if (seg != null) {
          fullPath.addAll(fullPath.isEmpty ? seg : seg.skip(1));
        }
      }

      setState(() {
        _result   = r;
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
      _naverError   = null;
    });
    final bytes = await CampusNavigationService.fetchNaverStaticMap(_fullPath!);
    if (!mounted) return;
    setState(() {
      _naverImageBytes = bytes;
      _naverLoading    = false;
      if (bytes == null) _naverError = '네이버 지도 이미지를 불러오지 못했습니다.';
    });
  }

  void _switchMode(_MapMode mode) {
    setState(() => _mapMode = mode);
    if (mode == _MapMode.naver && _naverImageBytes == null) {
      _loadNaverMap();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: buildAppBar('캠퍼스 길찾기', Colors.blueAccent),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── 입력 카드 ───────────────────────────────────────
            buildCard(
              child: Column(
                children: [
                  _buildingField(
                    _departCtrl, '출발지', Icons.radio_button_checked, Colors.green,
                  ),
                  ..._waypointCtrls.asMap().entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildingField(
                              e.value, '경유지 ${e.key + 1}',
                              Icons.add_location_alt, Colors.orange,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.grey.shade400),
                            onPressed: () => setState(() {
                              _waypointCtrls[e.key].dispose();
                              _waypointCtrls.removeAt(e.key);
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildingField(
                    _destCtrl, '도착지', Icons.location_on, Colors.red,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _waypointCtrls.length < 3
                            ? () => setState(
                                  () => _waypointCtrls.add(TextEditingController()),
                                )
                            : null,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('경유지 추가', style: TextStyle(fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blueAccent,
                          side: const BorderSide(color: Colors.blueAccent),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isLoading ? null : _search,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.route, size: 18),
                          label: Text(_isLoading ? '계산 중 (A*)...' : '최적 경로 탐색'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (_error != null) buildErrorBanner(_error!),

            // ── 결과 ────────────────────────────────────────────
            if (_result != null) ...[
              const SizedBox(height: 16),

              // 요약 카드
              buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          '최적 경로',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '총 ${_result!.totalDistanceM.round()}m',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_result!.orderedStops.length > 2) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: _result!.orderedStops.asMap().entries.map((e) {
                          final isFirst = e.key == 0;
                          final isLast  =
                              e.key == _result!.orderedStops.length - 1;
                          final Color bg = isFirst
                              ? Colors.green
                              : isLast
                                  ? Colors.red
                                  : Colors.orange;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: bg.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: bg.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              e.value,
                              style: TextStyle(
                                fontSize: 11,
                                color: bg,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 14),
                    ..._result!.segments.asMap().entries.map(
                      (e) => _segmentTile(e.key, e.value),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── 지도 시각화 카드 ────────────────────────────────
              buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 헤더
                    Row(
                      children: [
                        Icon(
                          _mapMode == _MapMode.naver
                              ? Icons.map
                              : Icons.account_tree_rounded,
                          color: Colors.blueAccent,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _mapMode == _MapMode.naver
                              ? '네이버 지도 기반 시각화'
                              : '그래프 기반 시각화',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _mapMode == _MapMode.naver
                                ? 'Naver Static Maps'
                                : 'A* 알고리즘',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 지도 영역
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 280,
                        child: _mapMode == _MapMode.graph
                            ? _CampusMapPainterWidget(result: _result!)
                            : _NaverMapView(
                                fullPath:    _fullPath ?? [],
                                imageBytes:  _naverImageBytes,
                                isLoading:   _naverLoading,
                                errorMsg:    _naverError,
                                onRetry:     _loadNaverMap,
                              ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── 토글 버튼 ──────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _ModeButton(
                            icon: Icons.account_tree_rounded,
                            label: '그래프 시각화',
                            sublabel: 'A* 노드·엣지',
                            selected: _mapMode == _MapMode.graph,
                            color: Colors.blueAccent,
                            onTap: () => _switchMode(_MapMode.graph),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ModeButton(
                            icon: Icons.map_rounded,
                            label: '네이버 지도',
                            sublabel: 'Static Maps API',
                            selected: _mapMode == _MapMode.naver,
                            color: Colors.green,
                            onTap: () => _switchMode(_MapMode.naver),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // 범례 (그래프 모드)
                    if (_mapMode == _MapMode.graph)
                      Wrap(
                        spacing: 12,
                        children: [
                          _legend(Colors.green,      '출발지'),
                          _legend(Colors.red,        '도착지'),
                          _legend(Colors.orange,     '경유지'),
                          _legend(Colors.blueAccent, '최적 경로'),
                        ],
                      ),

                    // 범례 (네이버 모드)
                    if (_mapMode == _MapMode.naver)
                      Wrap(
                        spacing: 12,
                        children: [
                          _legend(Colors.green,      '출발지'),
                          _legend(Colors.red,        '도착지'),
                          _legend(Colors.orange,     '경유지'),
                          _legend(Colors.blueAccent, '최적 경로'),
                        ],
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildingField(
    TextEditingController ctrl,
    String hint,
    IconData icon,
    Color color,
  ) {
    return Autocomplete<String>(
      optionsBuilder: (v) => v.text.isEmpty
          ? const []
          : _buildings.where((b) => b.contains(v.text)),
      onSelected: (s) => ctrl.text = s,
      fieldViewBuilder: (ctx, ctrl2, fn, onSubmit) {
        ctrl.addListener(() {
          if (ctrl2.text != ctrl.text) ctrl2.text = ctrl.text;
        });
        return TextField(
          controller: ctrl2,
          focusNode: fn,
          decoration: InputDecoration(
            labelText: hint,
            prefixIcon: Icon(icon, color: color, size: 20),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: color, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        );
      },
    );
  }

  Widget _segmentTile(int idx, WaypointResult seg) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '${idx + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (idx < _result!.segments.length - 1)
              Container(
                width: 2,
                height: 32,
                color: Colors.blueAccent.withValues(alpha: 0.3),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${seg.from} → ${seg.to}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Text(
                '${seg.distanceM.round()}m  |  ${seg.path.join(' → ')}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _legend(Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 11)),
    ],
  );
}

// ──────────────────────────────────────────────────────────────
// 모드 토글 버튼 위젯
// ──────────────────────────────────────────────────────────────
class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _ModeButton({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? color : Colors.grey.shade500),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: selected ? color : Colors.grey.shade600,
                  ),
                ),
                Text(
                  sublabel,
                  style: TextStyle(
                    fontSize: 9,
                    color: selected
                        ? color.withValues(alpha: 0.7)
                        : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// 네이버 지도 뷰 (이미지 + CustomPainter 오버레이)
// Python: generate_static_map() + PIL 오버레이에 대응
// ──────────────────────────────────────────────────────────────
class _NaverMapView extends StatelessWidget {
  final List<String> fullPath;
  final Uint8List? imageBytes;
  final bool isLoading;
  final String? errorMsg;
  final VoidCallback onRetry;

  const _NaverMapView({
    required this.fullPath,
    required this.imageBytes,
    required this.isLoading,
    required this.errorMsg,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        color: const Color(0xFFF0F4FF),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.blueAccent),
              SizedBox(height: 12),
              Text(
                '네이버 지도 불러오는 중...',
                style: TextStyle(fontSize: 13, color: Colors.blueAccent),
              ),
            ],
          ),
        ),
      );
    }

    if (errorMsg != null) {
      return Container(
        color: const Color(0xFFFFF0F0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off_rounded,
                  size: 40, color: Colors.red.shade300),
              const SizedBox(height: 8),
              Text(
                errorMsg!,
                style: TextStyle(fontSize: 13, color: Colors.red.shade400),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('다시 시도'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blueAccent,
                  side: const BorderSide(color: Colors.blueAccent),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (imageBytes == null) {
      return Container(
        color: const Color(0xFFF0F4FF),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_outlined, size: 40, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              Text(
                '지도 이미지를 불러오는 중입니다.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    // 이미지 + 경로 오버레이
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final widgetW = constraints.maxWidth;
        final widgetH = constraints.maxHeight;
        return Stack(
          children: [
            // 네이버 지도 이미지
            Positioned.fill(
              child: Image.memory(
                imageBytes!,
                fit: BoxFit.fill,
              ),
            ),
            // 경로 오버레이 (Python: PIL 오버레이에 대응)
            Positioned.fill(
              child: CustomPaint(
                painter: _NaverOverlayPainter(
                  fullPath: fullPath,
                  widgetW: widgetW,
                  widgetH: widgetH,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────
// 네이버 이미지 위 오버레이 CustomPainter
// Python: PIL 경로 선·화살표·마커 렌더링에 대응
// ──────────────────────────────────────────────────────────────
class _NaverOverlayPainter extends CustomPainter {
  final List<String> fullPath;
  final double widgetW;
  final double widgetH;

  // 네이버 API 이미지 원본 크기
  static const double _imgW = 920;
  static const double _imgH = 920;

  _NaverOverlayPainter({
    required this.fullPath,
    required this.widgetW,
    required this.widgetH,
  });

  /// 위경도 → 위젯 픽셀 (Python: latlon_to_pixel → 위젯 스케일 적용)
  Offset _toOffset(
    double lat,
    double lon,
    double centerLat,
    double centerLon,
  ) {
    final (px, py) = CampusNavigationService.latLonToPixel(
      lat, lon, centerLat, centerLon,
      w: _imgW.toInt(),
      h: _imgH.toInt(),
    );
    // 이미지 원본 → 위젯 크기로 스케일
    final x = px * widgetW / _imgW;
    final y = py * widgetH / _imgH;
    return Offset(x, y);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (fullPath.isEmpty) return;

    final coords = CampusNavigationService.allCoords;
    final (centerLat, centerLon) =
        CampusNavigationService.routeCenter(fullPath);

    final validPath =
        fullPath.where((n) => coords.containsKey(n)).toList();
    if (validPath.isEmpty) return;

    final offsets = validPath.map((n) {
      final c = coords[n]!;
      return _toOffset(c.$1, c.$2, centerLat, centerLon);
    }).toList();

    // 1) 경로 선 (Python: draw.line LINE_COLOR)
    final linePaint = Paint()
      ..color = Colors.blueAccent.withValues(alpha: 0.85)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final routePath = Path();
    routePath.moveTo(offsets.first.dx, offsets.first.dy);
    for (final pt in offsets.skip(1)) {
      routePath.lineTo(pt.dx, pt.dy);
    }
    canvas.drawPath(routePath, linePaint);

    // 2) 방향 화살표 (Python: draw_arrow ARROW_COLOR)
    _drawArrows(canvas, offsets);

    // 3) 건물 마커 (P_ 제외) — Python: ellipse 출발=red, 도착=green, 경유=blue
    final buildingPath =
        validPath.where((n) => !n.startsWith('P_')).toList();

    final markerPaint  = Paint()..style = PaintingStyle.fill;
    final outlinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (int i = 0; i < buildingPath.length; i++) {
      final node = buildingPath[i];
      final c    = coords[node]!;
      final pt   = _toOffset(c.$1, c.$2, centerLat, centerLon);

      Color color;
      if (i == 0) {
        color = Colors.green;  // 출발
      } else if (i == buildingPath.length - 1) {
        color = Colors.red;    // 도착
      } else {
        color = Colors.orange; // 경유
      }

      // 흰 외곽
      canvas.drawCircle(pt, 9, outlinePaint);
      // 색 마커
      markerPaint.color = color;
      canvas.drawCircle(pt, 7, markerPaint);

      // 건물 라벨
      final tp = TextPainter(
        text: TextSpan(
          text: node,
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.bold,
            shadows: const [Shadow(color: Colors.white, blurRadius: 4)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 90);
      tp.paint(canvas, pt.translate(10, -6));
    }
  }

  void _drawArrows(Canvas canvas, List<Offset> points) {
    final paint = Paint()
      ..color = const Color(0xE60A3CC8)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final dx = p2.dx - p1.dx;
      final dy = p2.dy - p1.dy;
      final len = sqrt(dx * dx + dy * dy);
      if (len < 10) continue;

      final angle = atan2(dy, dx);
      final mx    = (p1.dx + p2.dx) / 2;
      final my    = (p1.dy + p2.dy) / 2;
      const s     = 7.0; // 화살표 크기 (Python: size=8)

      final tip   = Offset(mx + s * cos(angle),            my + s * sin(angle));
      final left  = Offset(mx - s * cos(angle - pi / 5),   my - s * sin(angle - pi / 5));
      final right = Offset(mx - s * cos(angle + pi / 5),   my - s * sin(angle + pi / 5));

      canvas.drawPath(
        Path()
          ..moveTo(tip.dx,   tip.dy)
          ..lineTo(left.dx,  left.dy)
          ..lineTo(right.dx, right.dy)
          ..close(),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NaverOverlayPainter old) =>
      old.fullPath != fullPath ||
      old.widgetW  != widgetW  ||
      old.widgetH  != widgetH;
}

// ──────────────────────────────────────────────────────────────
// 그래프 CustomPainter 위젯 (빈 배경 기반 시각화)
// ──────────────────────────────────────────────────────────────
class _CampusMapPainterWidget extends StatelessWidget {
  final RouteResult result;
  const _CampusMapPainterWidget({required this.result});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) => CustomPaint(
        size: Size(constraints.maxWidth, constraints.maxHeight),
        painter: _CampusMapPainter(result: result),
      ),
    );
  }
}

class _CampusMapPainter extends CustomPainter {
  final RouteResult result;
  _CampusMapPainter({required this.result});

  Offset _latLonToOffset(
    double lat,
    double lon,
    double minLat,
    double maxLat,
    double minLon,
    double maxLon,
    Size size,
    double padding,
  ) {
    double mercY(double latDeg) {
      final r = latDeg * pi / 180;
      return log(tan(pi / 4 + r / 2));
    }

    final mercMin = mercY(minLat);
    final mercMax = mercY(maxLat);
    final rangeX  = maxLon - minLon;
    if (rangeX == 0 || (mercMax - mercMin) == 0) {
      return Offset(size.width / 2, size.height / 2);
    }

    final x = padding + (lon - minLon) / rangeX * (size.width - padding * 2);
    final y = padding +
        (mercMax - mercY(lat)) /
            (mercMax - mercMin) *
            (size.height - padding * 2);
    return Offset(x, y);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final coords  = CampusNavigationService.allCoords;
    final edges   = CampusNavigationService.walkableEdges;
    final padding = 24.0;

    final lats = coords.values.map((c) => c.$1).toList();
    final lons = coords.values.map((c) => c.$2).toList();
    final minLat = lats.reduce(min);
    final maxLat = lats.reduce(max);
    final minLon = lons.reduce(min);
    final maxLon = lons.reduce(max);

    Offset toOff(String node) {
      final c = coords[node]!;
      return _latLonToOffset(
          c.$1, c.$2, minLat, maxLat, minLon, maxLon, size, padding);
    }

    // 배경
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(0)),
      Paint()..color = const Color(0xFFF0F4FF),
    );

    // 엣지 (전체)
    final edgePaint = Paint()
      ..color = const Color(0xFFBBCCDD)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (final (n1, n2) in edges) {
      if (!coords.containsKey(n1) || !coords.containsKey(n2)) continue;
      canvas.drawLine(toOff(n1), toOff(n2), edgePaint);
    }

    // 최적 경로 재구성
    final graph = CampusNavigationService.buildCampusGraph(
        coords, CampusNavigationService.walkableEdges);
    final stops      = result.orderedStops;
    final routePts   = <Offset>[];
    for (int i = 0; i < stops.length - 1; i++) {
      final (path, _) = CampusNavigationService.aStar(
          stops[i], stops[i + 1], graph, coords);
      if (path != null) {
        for (int j = (routePts.isEmpty ? 0 : 1); j < path.length; j++) {
          if (coords.containsKey(path[j])) routePts.add(toOff(path[j]));
        }
      }
    }

    // 경로 선
    if (routePts.length > 1) {
      final routePaint = Paint()
        ..color = Colors.blueAccent.withValues(alpha: 0.85)
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final rPath = Path();
      rPath.moveTo(routePts.first.dx, routePts.first.dy);
      for (final pt in routePts.skip(1)) rPath.lineTo(pt.dx, pt.dy);
      canvas.drawPath(rPath, routePaint);
      _drawArrows(canvas, routePts, Colors.blueAccent);
    }

    // 경로 노드
    final pnPaint = Paint()..color = const Color(0xFF90B8E0);
    for (final node in coords.keys) {
      if (!node.startsWith('P_')) continue;
      canvas.drawCircle(toOff(node), 2.5, pnPaint);
    }

    // 건물 노드
    final bPaint = Paint()..color = const Color(0xFF3D3D3D);
    for (final node in CampusNavigationService.buildingCoords.keys) {
      canvas.drawCircle(toOff(node), 4, bPaint);
    }

    // 출발·경유·도착 마커
    for (int i = 0; i < result.orderedStops.length; i++) {
      final node = result.orderedStops[i];
      if (!coords.containsKey(node)) continue;
      final pt = toOff(node);
      final Color mc = i == 0
          ? Colors.green
          : i == result.orderedStops.length - 1
              ? Colors.red
              : Colors.orange;

      canvas.drawCircle(pt, 9, Paint()..color = Colors.white);
      canvas.drawCircle(pt, 7, Paint()..color = mc);

      final tp = TextPainter(
        text: TextSpan(
          text: node,
          style: TextStyle(
              fontSize: 9, color: mc, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 80);
      tp.paint(canvas, pt.translate(10, -6));
    }
  }

  void _drawArrows(Canvas canvas, List<Offset> points, Color color) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final dx = p2.dx - p1.dx;
      final dy = p2.dy - p1.dy;
      if (sqrt(dx * dx + dy * dy) < 12) continue;
      final angle = atan2(dy, dx);
      final mx = (p1.dx + p2.dx) / 2;
      final my = (p1.dy + p2.dy) / 2;
      const s = 6.0;
      canvas.drawPath(
        Path()
          ..moveTo(mx + s * cos(angle), my + s * sin(angle))
          ..lineTo(mx - s * cos(angle - pi / 5), my - s * sin(angle - pi / 5))
          ..lineTo(mx - s * cos(angle + pi / 5), my - s * sin(angle + pi / 5))
          ..close(),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CampusMapPainter old) => old.result != result;
}

// ══════════════════════════════════════════════════════════════
// 2. 강의 계획서 검색 페이지
// ══════════════════════════════════════════════════════════════
