// 실행 환경: Flutter 3.x / Dart 3.x
// 필요 라이브러리: flutter_riverpod: ^3.3.1, http: ^1.6.0, shared_preferences: ^2.5.5
// Input 데이터 출처: 서버 GET /api/wishlist/?limit=1000 (앱 시작 시 전체 동기화)

import 'package:flutter_riverpod/legacy.dart';
import '../api/wishlist_service.dart';

// 자료구조: Set<int> (해시 집합 / Hash Table)
// - 찜한 강의 courseId 집합 관리
// - wishlist.contains(courseId): O(1) 찜 여부 확인 → 리스트 O(n) 탐색 대비 성능 우위
// - 앱 시작 시 /api/wishlist/?limit=1000 으로 전체 ID 동기화
class WishlistNotifier extends StateNotifier<Set<int>> {
  WishlistNotifier() : super({}) {
    fetchInitial();
  }

  Future<void> fetchInitial() async {
    // 자료구조: Set<int> - 서버에서 찜 목록 전체 동기화
    final ids = await WishlistService.fetchWishlistIds();
    state = ids;
  }

  void sync(Set<int> ids) {
    state = ids;
  }

  Future<void> toggle(int courseId) async {
    // Optimistic UI: API 응답 전 Set<int> 로컬 상태 먼저 변경
    final wasBookmarked = state.contains(courseId); // O(1) 해시 집합 조회
    if (wasBookmarked) {
      state = {...state}..remove(courseId);
    } else {
      state = {...state, courseId};
    }

    try {
      final success = await WishlistService.toggleWishlist(courseId);
      if (!success.success) {
        // 실패 시 롤백
        if (wasBookmarked) {
          state = {...state, courseId};
        } else {
          state = {...state}..remove(courseId);
        }
      }
    } catch (e) {
      if (wasBookmarked) {
        state = {...state, courseId};
      } else {
        state = {...state}..remove(courseId);
      }
    }
  }
}

final wishlistProvider = StateNotifierProvider<WishlistNotifier, Set<int>>((ref) {
  return WishlistNotifier();
});
