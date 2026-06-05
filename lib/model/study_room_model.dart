class StudyRoom {
  final int roomId;
  final int placeId;
  final String name;
  final int capacity;
  final String facilities;

  const StudyRoom({
    required this.roomId,
    required this.placeId,
    required this.name,
    required this.capacity,
    required this.facilities,
  });

  factory StudyRoom.fromJson(Map<String, dynamic> json) {
    return StudyRoom(
      roomId: json['room_id'],
      placeId: json['place_id'],
      name: json['name'],
      capacity: json['capacity'],
      facilities: json['facilities'] ?? '',
    );
  }

  List<String> get facilityList => facilities
      .split(',')
      .map((facility) => facility.trim())
      .where((facility) => facility.isNotEmpty)
      .toList();

  Map<String, dynamic> toJson() {
    return {
      'room_id': roomId,
      'place_id': placeId,
      'name': name,
      'capacity': capacity,
      'facilities': facilities,
    };
  }

  @override
  String toString() {
    return 'StudyRoom(roomId: $roomId, placeId: $placeId, name: $name, capacity: $capacity, facilities: $facilities)';
  }
}

class Reservation {
  final int reservationId;
  final int roomId;
  final int studentId;
  final String startTime;
  final String endTime;
  final int headCount;

  const Reservation({
    required this.reservationId,
    required this.roomId,
    required this.studentId,
    required this.startTime,
    required this.endTime,
    required this.headCount,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      reservationId: json['reservation_id'],
      roomId: json['room_id'],
      studentId: json['student_id'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      headCount: json['head_count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reservation_id': reservationId,
      'room_id': roomId,
      'student_id': studentId,
      'start_time': startTime,
      'end_time': endTime,
      'head_count': headCount,
    };
  }

  @override
  String toString() {
    return 'Reservation(reservationId: $reservationId, roomId: $roomId, studentId: $studentId, startTime: $startTime, endTime: $endTime, headCount: $headCount)';
  }
}

class RoomRecommendation {
  final StudyRoom room;
  final double score;
  final bool isSplitBooking;
  final List<dynamic> comboSlots;

  bool isAvailable;
  bool isMyReservation;
  List<bool> bookedSlots;

  RoomRecommendation({
    required this.room,
    required this.score,
    this.isSplitBooking = false,
    this.comboSlots = const [],
    this.isAvailable = true,
    this.isMyReservation = false,
    this.bookedSlots = const [],
  });
}

class StudyRoomReservation {
  final String id, roomName, location, date;
  final String? reservationGroupId;
  final int startHour, endHour;

  const StudyRoomReservation({
    required this.id,
    required this.roomName,
    required this.location,
    required this.date,
    required this.startHour,
    required this.endHour,
    this.reservationGroupId,
  });
}
