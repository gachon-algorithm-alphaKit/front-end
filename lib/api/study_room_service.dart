import '../model/route_model.dart';
import '../model/study_room_model.dart';

class StudyRoomService {
  // TODO: GET /api/studyrooms
  static Future<List<StudyRoom>> fetchRooms() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockRooms;
  }

  // TODO: POST /api/studyrooms/recommend
  static Future<List<RoomRecommendation>> recommend(
    DateTime date,
    int startHour,
    int endHour,
    int capacity,
    List<String> facilities,
  ) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final results = <RoomRecommendation>[];
    for (final room in _mockRooms) {
      double score = 100;
      score -= (room.capacity - capacity).abs() * 5.0;
      for (final f in facilities) {
        if (room.facilityList.contains(f)) {
          score += 10;
        }
      }
      if (score > 0) {
        results.add(RoomRecommendation(room: room, score: score.clamp(0, 100)));
      }
    }
    results.sort((a, b) => b.score.compareTo(a.score));
    return results.take(3).toList();
  }

  // TODO: POST /api/studyrooms/reserve
  static Future<bool> reserve(
    int roomId,
    DateTime date,
    int startHour,
    int endHour,
  ) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return true;
  }

  static String locationFor(StudyRoom room) {
    return _mockPlaces
        .firstWhere(
          (place) => place.placeId == room.placeId,
          orElse: () => const Place(
            placeId: 0,
            schoolId: 1,
            name: '위치 미정',
            placeType: 'unknown',
            latitude: 0,
            longitude: 0,
          ),
        )
        .name;
  }

  static const _mockPlaces = <Place>[
    Place(
      placeId: 2,
      schoolId: 1,
      name: '비전타워 3층',
      placeType: 'study_room_area',
      latitude: 37.4499,
      longitude: 127.1281,
    ),
    Place(
      placeId: 5,
      schoolId: 1,
      name: 'AI도서관 2층',
      placeType: 'study_room_area',
      latitude: 37.4496,
      longitude: 127.1278,
    ),
    Place(
      placeId: 1,
      schoolId: 1,
      name: '가천관 5층',
      placeType: 'study_room_area',
      latitude: 37.4491,
      longitude: 127.1273,
    ),
  ];

  static const _mockRooms = <StudyRoom>[
    StudyRoom(
      roomId: 1,
      placeId: 2,
      name: '스터디룸 A',
      capacity: 6,
      facilities: 'TV,화이트보드,HDMI',
    ),
    StudyRoom(
      roomId: 2,
      placeId: 2,
      name: '스터디룸 B',
      capacity: 4,
      facilities: '화이트보드',
    ),
    StudyRoom(
      roomId: 3,
      placeId: 5,
      name: '스터디룸 C',
      capacity: 10,
      facilities: 'TV,빔프로젝터,화이트보드',
    ),
    StudyRoom(
      roomId: 4,
      placeId: 5,
      name: '스터디룸 D',
      capacity: 4,
      facilities: '화이트보드,HDMI',
    ),
    StudyRoom(
      roomId: 5,
      placeId: 1,
      name: '스터디룸 E',
      capacity: 8,
      facilities: 'TV,화이트보드',
    ),
  ];
}
