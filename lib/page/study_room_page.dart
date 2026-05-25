import 'package:flutter/material.dart';

import '../api/study_room_service.dart';
import '../component/common_widgets.dart';
import '../model/study_room_model.dart';
import '../state/app_state.dart';
import 'study_room_reservation_history_page.dart';

class StudyRoomPage extends StatefulWidget {
  const StudyRoomPage({super.key});
  @override
  State<StudyRoomPage> createState() => _StudyRoomPageState();
}

class _StudyRoomPageState extends State<StudyRoomPage> {
  DateTime _date = DateTime.now();
  int _startHour = 10, _endHour = 12, _capacity = 4;
  final _allFacilities = ['TV', '화이트보드', '빔프로젝터', 'HDMI'];
  final _selectedFacilities = <String>[];
  List<RoomRecommendation> _results = [];
  bool _isLoading = false, _searched = false;

  Future<void> _search() async {
    if (_startHour >= _endHour) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('종료 시간은 시작 시간보다 이후여야 합니다.')));
      return;
    }
    if (_endHour - _startHour > 4) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('최대 이용 시간은 4시간입니다.')));
      return;
    }
    setState(() {
      _isLoading = true;
      _searched = true;
      _results = [];
    });
    try {
      // TODO: StudyRoomService.recommend → Bitset + PriorityQueue + Backtracking 처리
      final r = await StudyRoomService.recommend(
        _date,
        _startHour,
        _endHour,
        _capacity,
        _selectedFacilities,
      );
      setState(() => _results = r);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _reserve(RoomRecommendation rec) async {
    // TODO: StudyRoomService.reserve → Bitset OR 예약 확정
    final ok = await StudyRoomService.reserve(
      rec.room.id,
      _date,
      _startHour,
      _endHour,
    );
    if (ok && mounted) {
      // 예약 내역 저장
      myReservations.add(
        StudyRoomReservation(
          id: 'R${DateTime.now().millisecondsSinceEpoch}',
          roomName: rec.room.name,
          location: rec.room.location,
          date:
              "${_date.year}.${_date.month.toString().padLeft(2, "0")}.${_date.day.toString().padLeft(2, "0")}",
          startHour: _startHour,
          endHour: _endHour,
        ),
      );
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('예약 완료', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            '${rec.room.name} 예약이 완료되었습니다.\n$_startHour:00 ~ $_endHour:00',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          '스터디룸 예약',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.green.shade600,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: Colors.white),
            tooltip: '예약 내역',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StudyRoomReservationHistoryPage(
                  reservations: myReservations,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 조건 설정 카드
            buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 날짜
                  buildSectionLabel('날짜'),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null) setState(() => _date = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            color: Colors.green.shade600,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "${_date.year}.${_date.month.toString().padLeft(2, "0")}.${_date.day.toString().padLeft(2, "0")}",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.chevron_right,
                            color: Colors.grey.shade400,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 시간
                  buildSectionLabel('이용 시간'),
                  Row(
                    children: [
                      _hourSelector(
                        '시작',
                        _startHour,
                        (v) => setState(() => _startHour = v),
                        8,
                        20,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '~',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      _hourSelector(
                        '종료',
                        _endHour,
                        (v) => setState(() => _endHour = v),
                        9,
                        22,
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_endHour - _startHour}시간',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 인원
                  buildSectionLabel('인원'),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _capacity > 1
                            ? () => setState(() => _capacity--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        color: Colors.green.shade600,
                      ),
                      Text(
                        '$_capacity명',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: _capacity < 20
                            ? () => setState(() => _capacity++)
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                        color: Colors.green.shade600,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 시설 선택
                  buildSectionLabel('희망 시설 (선택)'),
                  Wrap(
                    spacing: 8,
                    children: _allFacilities.map((f) {
                      final selected = _selectedFacilities.contains(f);
                      return FilterChip(
                        label: Text(f),
                        selected: selected,
                        onSelected: (v) => setState(
                          () => v
                              ? _selectedFacilities.add(f)
                              : _selectedFacilities.remove(f),
                        ),
                        selectedColor: Colors.green.shade100,
                        checkmarkColor: Colors.green.shade700,
                        labelStyle: TextStyle(
                          color: selected
                              ? Colors.green.shade700
                              : Colors.grey.shade700,
                          fontSize: 13,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // 검색
                  SizedBox(
                    width: double.infinity,
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
                          : const Icon(Icons.search),
                      label: Text(_isLoading ? '검색 중...' : '공실 검색 (Bitset 처리)'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 결과
            if (_searched && !_isLoading) ...[
              const SizedBox(height: 16),
              if (_results.isEmpty)
                buildCard(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.event_busy,
                            size: 48,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '해당 조건의 스터디룸이 없습니다.\n시간 분할 매칭(백트래킹)을 시도해보세요.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else ...[
                Row(
                  children: [
                    const Text(
                      '추천 스터디룸',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // TODO: 백엔드에서 우선순위 큐 결과 Top 3 반환
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'PriorityQueue 결과',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ..._results.asMap().entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _roomCard(e.value, e.key == 0),
                  ),
                ),
              ],
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _hourSelector(
    String label,
    int value,
    ValueChanged<int> onChanged,
    int min,
    int max,
  ) => Column(
    children: [
      Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      const SizedBox(height: 4),
      Row(
        children: [
          GestureDetector(
            onTap: value > min ? () => onChanged(value - 1) : null,
            child: Icon(
              Icons.chevron_left,
              color: value > min ? Colors.green.shade600 : Colors.grey.shade300,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '$value:00',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          GestureDetector(
            onTap: value < max ? () => onChanged(value + 1) : null,
            child: Icon(
              Icons.chevron_right,
              color: value < max ? Colors.green.shade600 : Colors.grey.shade300,
            ),
          ),
        ],
      ),
    ],
  );

  Widget _roomCard(RoomRecommendation rec, bool isTop) => Card(
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(
        color: isTop ? Colors.green.shade300 : Colors.grey.shade200,
        width: isTop ? 1.5 : 1,
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              '${rec.score.round()}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      rec.room.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (isTop) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade600,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '추천 1위',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${rec.room.location} · ${rec.room.capacity}인실',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  children: rec.room.facilities
                      .map(
                        (f) => Chip(
                          label: Text(f, style: const TextStyle(fontSize: 10)),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          backgroundColor: Colors.grey.shade100,
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => _reserve(rec),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              minimumSize: const Size(60, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('예약', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════════════
// 3-B. 스터디룸 예약 내역 페이지
// ══════════════════════════════════════════════════════════════
