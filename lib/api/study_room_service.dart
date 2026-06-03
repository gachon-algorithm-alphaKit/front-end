import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../model/route_model.dart';
import '../model/study_room_model.dart';

class StudyRoomService {
  // TODO: GET /api/studyrooms
  static Future<List<StudyRoom>> fetchRooms() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockRooms;
  }

  static const String baseUrl = 'http://10.0.2.2:8000';

  static Future<Map<String, dynamic>> recommend(
    DateTime date,
    int startHour,
    int endHour,
    int capacity,
    List<String> facilities, {
    int page = 1,
    int limit = 10,
  }) async {
    final start = DateTime(date.year, date.month, date.day, startHour).toIso8601String();
    final end = DateTime(date.year, date.month, date.day, endHour).toIso8601String();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final response = await http.post(
        Uri.parse('$baseUrl/api/rooms/recommend/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'school_id': 1,
          'start_time': start,
          'end_time': end,
          'head_count': capacity,
          'facilities': facilities,
          'page': page,
          'limit': limit,
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded['status'] == 'success') {
          final String matchType = decoded['data']['match_type'] ?? 'SINGLE';
          final List data = decoded['data']['recommendations'] ?? [];
          final bool hasMore = (decoded['data']['pagination']['current_page'] < decoded['data']['pagination']['total_pages']);
          
          if (matchType == 'COMBINED') {
            final list = data.map((json) {
              return RoomRecommendation(
                room: const StudyRoom(roomId: 0, placeId: 0, name: '공실 조합 추천', capacity: 0, facilities: ''),
                score: (json['total_score'] as num).toDouble(),
                isSplitBooking: true,
                comboSlots: json['slots'] ?? [],
              );
            }).toList();
            return {'list': list, 'hasMore': hasMore};
          } else {
            final list = data.map((json) {
              final room = StudyRoom(
                roomId: json['room_id'],
                placeId: json['place_id'] ?? 0,
                name: json['name'],
                capacity: json['capacity'],
                facilities: (json['facilities'] as List).join(','),
              );
              return RoomRecommendation(
                room: room,
                score: (json['score'] as num).toDouble(),
                isAvailable: json['is_available'] ?? true,
                isMyReservation: json['is_my_reservation'] ?? false,
                bookedSlots: List<bool>.from(json['booked_slots'] ?? List.filled(14, false)),
              );
            }).toList();
            return {'list': list, 'hasMore': hasMore};
          }
        }
      }
    } catch (e) {
      print('Error fetching recommendations: $e');
    }
    return {'list': <RoomRecommendation>[], 'hasMore': false};
  }

  // POST /api/rooms/reserve_combo/
  static Future<List<String>?> reserveCombo(
    List<dynamic> comboSlots,
    int capacity,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      final slots = comboSlots.map((slot) {
        return {
          'room_id': slot['room_id'],
          'start_time': slot['start_time'],
          'end_time': slot['end_time'],
        };
      }).toList();

      final response = await http.post(
        Uri.parse('$baseUrl/api/rooms/reserve_combo/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'slots': slots,
          'head_count': capacity,
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded['status'] == 'success') {
          return List<String>.from(decoded['data']['reservation_ids'].map((x) => x.toString()));
        } else if (decoded['message'] != null) {
          throw Exception(decoded['message']);
        }
      } else {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded['message'] != null) {
          throw Exception(decoded['message']);
        }
      }
    } catch (e) {
      if (e is Exception) rethrow;
      print('Error combo reserving: $e');
      throw Exception('예약 처리에 실패했습니다.');
    }
    return null;
  }

  // POST /api/rooms/reserve/
  static Future<String?> reserve(
    int roomId,
    DateTime date,
    int startHour,
    int endHour,
    int capacity,
  ) async {
    final start = DateTime(date.year, date.month, date.day, startHour).toIso8601String();
    final end = DateTime(date.year, date.month, date.day, endHour).toIso8601String();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      final response = await http.post(
        Uri.parse('$baseUrl/api/rooms/reserve/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'room_id': roomId,
          'start_time': start,
          'end_time': end,
          'head_count': capacity,
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded['status'] == 'success') {
          return decoded['data']['reservation_id'].toString();
        } else if (decoded['message'] != null) {
          throw Exception(decoded['message']);
        }
      } else {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded['message'] != null) {
          throw Exception(decoded['message']);
        }
      }
    } catch (e) {
      if (e is Exception) rethrow;
      print('Error reserving room: $e');
      throw Exception('예약 처리에 실패했습니다.');
    }
    return null;
  }

  // GET /api/rooms/reservations/
  static Future<List<StudyRoomReservation>> fetchMyReservations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/rooms/reservations/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded['status'] == 'success') {
          final List data = decoded['data']['reservations'] ?? [];
          final allReservations = data.map((json) => StudyRoomReservation(
            id: json['id'],
            roomName: json['roomName'],
            location: json['location'],
            date: json['date'],
            startHour: json['startHour'],
            endHour: json['endHour'],
          )).toList();

          final now = DateTime.now();
          final validReservations = <StudyRoomReservation>[];

          for (final res in allReservations) {
            try {
              final parts = res.date.split('.');
              if (parts.length == 3) {
                final year = int.parse(parts[0]);
                final month = int.parse(parts[1]);
                final day = int.parse(parts[2]);
                final endTime = DateTime(year, month, day, res.endHour);

                if (endTime.isBefore(now)) {
                  cancelReservation(res.id);
                  continue;
                }
              }
            } catch (e) {
              print('Error parsing date: $e');
            }
            validReservations.add(res);
          }

          return validReservations;
        }
      }
    } catch (e) {
      print('Error fetching my reservations: $e');
    }
    return [];
  }

  // DELETE /api/rooms/reservations/<id>/
  static Future<bool> cancelReservation(String reservationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      final response = await http.delete(
        Uri.parse('$baseUrl/api/rooms/reservations/$reservationId/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded['status'] == 'success') {
          return true;
        }
      }
    } catch (e) {
      print('Error cancelling reservation: $e');
    }
    return false;
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
