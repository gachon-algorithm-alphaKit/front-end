import 'package:flutter_riverpod/legacy.dart';

import '../model/study_room_model.dart';

class ReservationNotifier extends StateNotifier<List<StudyRoomReservation>> {
  ReservationNotifier() : super([]);

  void sync(List<StudyRoomReservation> reservations) {
    state = reservations;
  }

  void addReservation(StudyRoomReservation reservation) {
    state = [...state, reservation];
  }

  void cancelReservation(String reservationId) {
    state = state.where((r) => r.id != reservationId).toList();
  }
}

final reservationProvider = StateNotifierProvider<ReservationNotifier, List<StudyRoomReservation>>((ref) {
  return ReservationNotifier();
});
