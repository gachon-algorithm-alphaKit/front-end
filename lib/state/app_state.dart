import '../model/lost_found_model.dart';
import '../model/study_room_model.dart';

final List<StudyRoomReservation> myReservations = [];
final List<LostFoundPost> myPosts = [];
final Set<int> wishlistCourseIds = {}; // 찜한 강의 ID Set

/// 서버에서 받아온 위시리스트 ID로 전역 상태 동기화
void syncWishlistIds(Set<int> ids) {
  wishlistCourseIds.clear();
  wishlistCourseIds.addAll(ids);
}
