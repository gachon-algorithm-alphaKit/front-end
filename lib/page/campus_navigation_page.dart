import 'package:flutter/material.dart';

import '../api/campus_navigation_service.dart';
import '../component/common_widgets.dart';
import '../model/route_model.dart';

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
  bool _isLoading = false;
  String? _error;

  final _buildings = CampusNavigationService.buildingNames;

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
    if (_departCtrl.text.isEmpty || _destCtrl.text.isEmpty) {
      setState(() => _error = '출발지와 도착지를 입력해주세요.');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });
    try {
      // TODO: CampusNavigationService.findRoute 호출 → 백엔드 연결
      final r = await CampusNavigationService.findRoute(
        _departCtrl.text,
        _waypointCtrls.map((c) => c.text).where((s) => s.isNotEmpty).toList(),
        _destCtrl.text,
      );
      setState(() => _result = r);
    } catch (e) {
      setState(() => _error = '경로를 찾을 수 없습니다. 다시 시도해주세요.');
    } finally {
      setState(() => _isLoading = false);
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
            // 입력 카드
            buildCard(
              child: Column(
                children: [
                  _buildingField(
                    _departCtrl,
                    '출발지',
                    Icons.radio_button_checked,
                    Colors.green,
                  ),
                  ..._waypointCtrls.asMap().entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildingField(
                              e.value,
                              '경유지 ${e.key + 1}',
                              Icons.add_location_alt,
                              Colors.orange,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              color: Colors.grey.shade400,
                            ),
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
                    _destCtrl,
                    '도착지',
                    Icons.location_on,
                    Colors.red,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _waypointCtrls.length < 3
                            ? () => setState(
                                () =>
                                    _waypointCtrls.add(TextEditingController()),
                              )
                            : null,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text(
                          '경유지 추가',
                          style: TextStyle(fontSize: 13),
                        ),
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
                          label: Text(_isLoading ? '계산 중...' : '최적 경로 탐색'),
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

            // 결과
            if (_result != null) ...[
              const SizedBox(height: 16),
              buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '최적 경로',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '총 ${(_result!.totalDistanceM).round()}m',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ..._result!.segments.asMap().entries.map(
                      (e) => _segmentTile(e.key, e.value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // 지도 영역 (네이버 지도 API 연결 자리)
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.map_outlined,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '지도 영역',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // TODO: flutter_naver_map 패키지 연결 후 NaverMap 위젯으로 교체
                      Text(
                        'TODO: 네이버 지도 API 연결',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
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
              decoration: BoxDecoration(
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
                '${seg.distanceM.round()}m | ${seg.path.join(' → ')}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════════════
// 2. 강의 계획서 검색 페이지
// ══════════════════════════════════════════════════════════════
