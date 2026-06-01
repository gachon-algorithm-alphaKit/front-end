import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/study_room_service.dart';
import '../../component/common_widgets.dart';
import '../../model/study_room_model.dart';
import '../../provider/reservation_provider.dart';
import 'study_room_reservation_history_page.dart';

class StudyRoomPage extends ConsumerStatefulWidget {
  const StudyRoomPage({super.key});
  @override
  ConsumerState<StudyRoomPage> createState() => _StudyRoomPageState();
}

class _StudyRoomPageState extends ConsumerState<StudyRoomPage> {
  DateTime _date = DateTime.now();
  int _startHour = 10, _endHour = 12, _capacity = 4;
  final _allFacilities = ['TV', '화이트보드', '빔프로젝터', 'HDMI'];
  final _selectedFacilities = <String>[];
  List<RoomRecommendation> _results = [];
  bool _isLoading = false, _searched = false;
  int _page = 1;
  bool _hasMore = false;
  bool _isFetchingMore = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMyReservations();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && !_isLoading && !_isFetchingMore && _hasMore) {
        _fetchMore();
      }
    });
  }

  Future<void> _loadMyReservations() async {
    final reservations = await StudyRoomService.fetchMyReservations();
    if (mounted) {
      ref.read(reservationProvider.notifier).sync(reservations);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_startHour >= _endHour) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('종료 시간은 시작 시간보다 이후여야 합니다.')));
      return;
    }
    if (_endHour - _startHour > 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('최대 이용 시간은 4시간입니다.')));
      return;
    }
    setState(() {
      _isLoading = true;
      _searched = true;
      _page = 1;
      _results = [];
    });
    try {
      final r = await StudyRoomService.recommend(_date, _startHour, _endHour, _capacity, _selectedFacilities, page: _page);
      setState(() {
        _results = r['list'] as List<RoomRecommendation>;
        _hasMore = r['hasMore'] as bool;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchMore() async {
    setState(() => _isFetchingMore = true);
    try {
      _page++;
      final r = await StudyRoomService.recommend(_date, _startHour, _endHour, _capacity, _selectedFacilities, page: _page);
      setState(() {
        _results.addAll(r['list'] as List<RoomRecommendation>);
        _hasMore = r['hasMore'] as bool;
      });
    } finally {
      setState(() => _isFetchingMore = false);
    }
  }

  Future<void> _reserve(RoomRecommendation rec) async {
    if (!rec.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('이미 예약된 시간대입니다.'), backgroundColor: Colors.orange.shade600, behavior: SnackBarBehavior.floating));
      return;
    }
    if (_endHour - _startHour > 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('최대 이용 시간은 4시간입니다.')));
      return;
    }
    if (_endHour - _startHour < 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('최소 이용 시간은 1시간입니다.')));
      return;
    }
    if (rec.isMyReservation) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('이미 예약된 시간대입니다.'), backgroundColor: Colors.orange.shade600, behavior: SnackBarBehavior.floating));
      return;
    }
    try {
      final reservationId = await StudyRoomService.reserve(rec.room.roomId, _date, _startHour, _endHour, _capacity);
      if (reservationId != null && mounted) {
        // 예약 내역 저장
        ref
            .read(reservationProvider.notifier)
            .addReservation(
              StudyRoomReservation(
                id: reservationId,
                roomName: rec.room.name,
                location: StudyRoomService.locationFor(rec.room),
                date: "${_date.year}.${_date.month.toString().padLeft(2, "0")}.${_date.day.toString().padLeft(2, "0")}",
                startHour: _startHour,
                endHour: _endHour,
              ),
            );

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${rec.room.name} 예약이 완료되었습니다.'), backgroundColor: Colors.green.shade600, behavior: SnackBarBehavior.floating));
        rec.isAvailable = false;
        rec.isMyReservation = true;
        for (int i = _startHour; i < _endHour; i++) {
          if (i >= 8 && i < 22) {
            if (rec.bookedSlots.length > i - 8) {
              rec.bookedSlots[i - 8] = true;
            }
          }
        }
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString();
        if (msg.startsWith('Exception: ')) {
          msg = msg.substring(11);
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red.shade600, behavior: SnackBarBehavior.floating));
      }
    }
  }

  Future<void> _reserveCombo(RoomRecommendation rec) async {
    if (!rec.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('이미 예약된 시간대입니다.'), backgroundColor: Colors.orange.shade600, behavior: SnackBarBehavior.floating));
      return;
    }
    try {
      final reservationIds = await StudyRoomService.reserveCombo(rec.comboSlots, _capacity);
      if (reservationIds != null && reservationIds.isNotEmpty && mounted) {
        // 예약 내역 저장 (연속 예약)
        for (int i = 0; i < reservationIds.length; i++) {
          final slot = rec.comboSlots[i];
          ref.read(reservationProvider.notifier).addReservation(
            StudyRoomReservation(
              id: reservationIds[i],
              roomName: slot['name'],
              location: slot['place_name'],
              date: "${_date.year}.${_date.month.toString().padLeft(2, "0")}.${_date.day.toString().padLeft(2, "0")}",
              startHour: slot['start_hour'],
              endHour: slot['end_hour'],
            ),
          );
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('공실 조합 일괄 예약이 완료되었습니다.'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
        rec.isAvailable = false;
        rec.isMyReservation = true;
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString();
        if (msg.startsWith('Exception: ')) {
          msg = msg.substring(11);
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red.shade600, behavior: SnackBarBehavior.floating));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final myReservations = ref.watch(reservationProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          '스터디룸 예약',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
        ),
        backgroundColor: Colors.green.shade600,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.event_note, color: Colors.white),
            label: Text(
              '예약 내역(${myReservations.length})',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudyRoomReservationHistoryPage())),
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 조건 설정 카드
            buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('예약 조건', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 20, color: Colors.green.shade600),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 30)));
                            if (d != null) setState(() => _date = d);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Text('${_date.year}년 ${_date.month}월 ${_date.day}일', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 20, color: Colors.green.shade600),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _hourSelector(
                              '시작',
                              _startHour,
                              (v) => setState(() {
                                _startHour = v;
                                if (_endHour <= _startHour) _endHour = _startHour + 1;
                                if (_endHour - _startHour > 4) _endHour = _startHour + 4;
                              }),
                              8,
                              21,
                            ),
                            Text('~', style: TextStyle(fontSize: 18, color: Colors.grey.shade400)),
                            _hourSelector(
                              '종료',
                              _endHour,
                              (v) => setState(() {
                                _endHour = v;
                                if (_startHour >= _endHour) _startHour = _endHour - 1;
                                if (_endHour - _startHour > 4) _startHour = _endHour - 4;
                              }),
                              9,
                              22,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(Icons.people_outline, size: 20, color: Colors.green.shade600),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('이용 인원', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  color: Colors.green.shade600,
                                  onPressed: _capacity > 1 ? () => setState(() => _capacity--) : null,
                                ),
                                Text('$_capacity명', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  color: Colors.green.shade600,
                                  onPressed: _capacity < 20 ? () => setState(() => _capacity++) : null,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('필요 시설', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _allFacilities.map((f) {
                      final selected = _selectedFacilities.contains(f);
                      return ChoiceChip(
                        label: Text(f),
                        selected: selected,
                        onSelected: (v) {
                          setState(() {
                            if (v) {
                              _selectedFacilities.add(f);
                            } else {
                              _selectedFacilities.remove(f);
                            }
                          });
                        },
                        selectedColor: Colors.green.shade100,
                        labelStyle: TextStyle(
                          color: selected ? Colors.green.shade800 : Colors.grey.shade700,
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                        backgroundColor: Colors.grey.shade50,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isLoading ? null : _search,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('빈 방 찾기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_searched && !_isLoading) ...[
              if (_results.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('조건에 맞는 스터디룸이 없습니다.', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                    ],
                  ),
                )
              else ...[
                Row(
                  children: [
                    const Text('추천 결과', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(12)),
                      child: Text(
                        '${_results.length}개',
                        style: TextStyle(color: Colors.green.shade800, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ..._results.asMap().entries.map(
                  (e) => Padding(padding: const EdgeInsets.only(bottom: 10), child: e.value.isSplitBooking ? _comboRoomCard(e.value) : _roomCard(e.value, e.key == 0)),
                ),
                if (_isFetchingMore)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _hourSelector(String label, int value, ValueChanged<int> onChanged, int min, int max) => Column(
    children: [
      Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      const SizedBox(height: 4),
      Row(
        children: [
          GestureDetector(
            onTap: value > min ? () => onChanged(value - 1) : null,
            child: Icon(Icons.chevron_left, color: value > min ? Colors.green.shade600 : Colors.grey.shade300),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text('$value:00', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
          GestureDetector(
            onTap: value < max ? () => onChanged(value + 1) : null,
            child: Icon(Icons.chevron_right, color: value < max ? Colors.green.shade600 : Colors.grey.shade300),
          ),
        ],
      ),
    ],
  );

  Widget _comboRoomCard(RoomRecommendation rec) {
    return Card(
      elevation: 0,
      color: Colors.amber.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.amber.shade300, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.link, color: Colors.amber.shade800),
                const SizedBox(width: 8),
                Text(
                  '공실 조합 추천 (${rec.comboSlots.length}시간 연속)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.amber.shade900),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: rec.isAvailable ? () => _reserveCombo(rec) : null,
                  style: FilledButton.styleFrom(backgroundColor: rec.isAvailable ? Colors.amber.shade700 : Colors.grey.shade400, minimumSize: const Size(60, 36)),
                  child: Text(rec.isAvailable ? '일괄 예약' : '마감', style: const TextStyle(fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('요청하신 연속된 시간에 예약 가능한 단일 스터디룸이 없어, 시간대별로 이용 가능한 방을 조합했습니다.', style: TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 12),
            ...rec.comboSlots.map((slot) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(6)),
                      child: Text(
                        '${slot['start_hour']}:00 ~ ${slot['end_hour']}:00',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('${slot['name']} (${slot['place_name']})', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _roomCard(RoomRecommendation rec, bool isTop) => Card(
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: isTop ? Colors.green.shade300 : Colors.grey.shade200, width: isTop ? 1.5 : 1),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: Text(
              '${rec.score.round()}',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700, fontSize: 15),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(rec.room.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    if (isTop) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.green.shade600, borderRadius: BorderRadius.circular(4)),
                        child: const Text(
                          '추천 1위',
                          style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    if (rec.isMyReservation) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.blue.shade600, borderRadius: BorderRadius.circular(4)),
                        child: const Text(
                          '내가 예약함',
                          style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text('${StudyRoomService.locationFor(rec.room)} · ${rec.room.capacity}인실', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  children: rec.room.facilityList
                      .map(
                        (f) => Chip(
                          label: Text(f, style: const TextStyle(fontSize: 10)),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          backgroundColor: Colors.grey.shade100,
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 10),
                Row(
                  children: List.generate(14, (i) {
                    final isBooked = rec.bookedSlots.length > i ? rec.bookedSlots[i] : false;
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.only(right: i < 13 ? 2.0 : 0.0),
                        decoration: BoxDecoration(color: isBooked ? Colors.grey.shade400 : Colors.green.shade500, borderRadius: BorderRadius.circular(2)),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('08시', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                    Text('22시', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: rec.isAvailable ? () => _reserve(rec) : null,
            style: FilledButton.styleFrom(
              backgroundColor: rec.isAvailable ? Colors.green.shade600 : Colors.grey.shade400,
              disabledBackgroundColor: Colors.grey.shade300,
              minimumSize: const Size(60, 36),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(rec.isAvailable ? '예약' : '마감', style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    ),
  );
}
