import 'package:flutter_riverpod/legacy.dart';

import '../api/wishlist_service.dart';

class WishlistNotifier extends StateNotifier<Set<int>> {
  WishlistNotifier() : super({}) {
    fetchInitial();
  }

  Future<void> fetchInitial() async {
    final ids = await WishlistService.fetchWishlistIds();
    state = ids;
  }

  void sync(Set<int> ids) {
    state = ids;
  }

  Future<void> toggle(int courseId) async {
    // Optimistic UI update
    final wasBookmarked = state.contains(courseId);
    if (wasBookmarked) {
      state = {...state}..remove(courseId);
    } else {
      state = {...state, courseId};
    }

    try {
      final success = await WishlistService.toggleWishlist(courseId);
      if (!success.success) {
        // Revert on failure
        if (wasBookmarked) {
          state = {...state, courseId};
        } else {
          state = {...state}..remove(courseId);
        }
      }
    } catch (e) {
      // Revert on failure
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
