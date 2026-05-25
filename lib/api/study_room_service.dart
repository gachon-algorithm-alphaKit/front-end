import '../model/study_room_model.dart';

class StudyRoomService {
  // ─────────────────────────────────────────────────────────
  // TODO: GET /api/studyrooms
  //   Response: List<StudyRoom>
  // ─────────────────────────────────────────────────────────
  static Future<List<StudyRoom>> fetchRooms() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockRooms;
  }

  // ─────────────────────────────────────────────────────────
  // TODO: POST /api/studyrooms/recommend
  //   Body: { date, startHour, endHour, capacity, facilities[] }
  //   Response: { recommendations: List<RoomRecommendation>, isSplit: bool }
  //   서버: Bitset 충돌검사 → PriorityQueue 점수화 → Backtracking 분할
  // ─────────────────────────────────────────────────────────
  static Future<List<RoomRecommendation>> recommend(
    DateTime date,
    int startHour,
    int endHour,
    int capacity,
    List<String> facilities,
  ) async {
    await Future.delayed(const Duration(milliseconds: 600));
    // MOCK: 적합도 점수 계산 (실제: Bitset + PriorityQueue)
    final results = <RoomRecommendation>[];
    for (final room in _mockRooms) {
      double score = 100;
      score -= (room.capacity - capacity).abs() * 5.0; // 인원 패널티
      for (final f in facilities) {
        if (room.facilities.contains(f)) {
          score += 10; // 시설 가산점
        }
      }
      if (score > 0) {
        results.add(RoomRecommendation(room: room, score: score.clamp(0, 100)));
      }
    }
    results.sort((a, b) => b.score.compareTo(a.score));
    return results.take(3).toList();
  }

  // ─────────────────────────────────────────────────────────
  // TODO: POST /api/studyrooms/reserve
  //   Body: { roomId, date, startHour, endHour, userId }
  //   Response: { success, reservationId }
  //   서버: Bitset OR 연산으로 예약 확정
  // ─────────────────────────────────────────────────────────
  static Future<bool> reserve(
    String roomId,
    DateTime date,
    int startHour,
    int endHour,
  ) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return true; // MOCK
  }

  static final _mockRooms = <StudyRoom>[
    const StudyRoom(
      id: 'R01',
      name: '스터디룸 A',
      location: '비전타워 3층',
      capacity: 6,
      facilities: ['TV', '화이트보드', 'HDMI'],
    ),
    const StudyRoom(
      id: 'R02',
      name: '스터디룸 B',
      location: '비전타워 3층',
      capacity: 4,
      facilities: ['화이트보드'],
    ),
    const StudyRoom(
      id: 'R03',
      name: '스터디룸 C',
      location: 'AI도서관 2층',
      capacity: 10,
      facilities: ['TV', '빔프로젝터', '화이트보드'],
    ),
    const StudyRoom(
      id: 'R04',
      name: '스터디룸 D',
      location: 'AI도서관 2층',
      capacity: 4,
      facilities: ['화이트보드', 'HDMI'],
    ),
    const StudyRoom(
      id: 'R05',
      name: '스터디룸 E',
      location: '가천관 5층',
      capacity: 8,
      facilities: ['TV', '화이트보드'],
    ),
  ];
}
