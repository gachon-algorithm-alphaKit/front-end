class StudyRoom {
  final String id, name, location;
  final int capacity;
  final List<String> facilities;
  const StudyRoom({
    required this.id,
    required this.name,
    required this.location,
    required this.capacity,
    required this.facilities,
  });
}

class RoomRecommendation {
  final StudyRoom room;
  final double score;
  final bool isSplitBooking;
  final List<Map<String, int>> splitSlots; // [{room:'A', start:10, end:11}]
  const RoomRecommendation({
    required this.room,
    required this.score,
    this.isSplitBooking = false,
    this.splitSlots = const [],
  });
}

// 스터디룸 예약 내역
class StudyRoomReservation {
  final String id, roomName, location, date;
  final int startHour, endHour;
  const StudyRoomReservation({
    required this.id,
    required this.roomName,
    required this.location,
    required this.date,
    required this.startHour,
    required this.endHour,
  });
}

// 분실물 작성 게시물
