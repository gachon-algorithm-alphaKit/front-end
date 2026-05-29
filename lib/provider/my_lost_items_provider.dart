import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../model/lost_found_model.dart';
import '../api/lost_found_service.dart';

// 신고 내역 총 개수 상태
class MyLostItemsCountNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void increment() => state++;
  void decrement() => state--;
  void set(int value) => state = value;
}

final myLostItemsCountProvider = NotifierProvider<MyLostItemsCountNotifier, int>(() {
  return MyLostItemsCountNotifier();
});

// 페이지네이션 및 리스트 상태를 위한 클래스
class MyLostItemsState {
  final List<LostItemPost> items;
  final bool isLoading;
  final bool isFetchingMore;
  final int currentPage;
  final bool hasMoreData;

  MyLostItemsState({
    required this.items,
    this.isLoading = false,
    this.isFetchingMore = false,
    this.currentPage = 1,
    this.hasMoreData = true,
  });

  MyLostItemsState copyWith({
    List<LostItemPost>? items,
    bool? isLoading,
    bool? isFetchingMore,
    int? currentPage,
    bool? hasMoreData,
  }) {
    return MyLostItemsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      currentPage: currentPage ?? this.currentPage,
      hasMoreData: hasMoreData ?? this.hasMoreData,
    );
  }
}

class MyLostItemsNotifier extends Notifier<MyLostItemsState> {
  @override
  MyLostItemsState build() {
    // 앱 시작 시 혹은 Provider 첫 접근 시 데이터 로드
    Future.microtask(() => fetchInitialData());
    return MyLostItemsState(items: []);
  }

  Future<void> fetchInitialData() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, currentPage: 1, hasMoreData: true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final headers = token != null ? {'Authorization': 'Bearer $token'} : const <String, String>{};

      final response = await http.get(
        Uri.parse('${LostFoundService.baseUrl}/api/students/me/lost-items?page=1&limit=10'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded['status'] == 'success') {
          final List data = decoded['data'] ?? [];
          final items = data.map((e) => LostItemPost.fromJson(e)).toList();
          
          final pagination = decoded['pagination'];
          final int totalItems = pagination['total_items'] ?? 0;
          final int totalPages = pagination['total_pages'] ?? 1;

          ref.read(myLostItemsCountProvider.notifier).set(totalItems);

          state = state.copyWith(
            items: items,
            isLoading: false,
            hasMoreData: 1 < totalPages,
            currentPage: 1,
          );
        } else {
          state = state.copyWith(isLoading: false);
        }
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      print('Fetch error: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadMore() async {
    if (state.isFetchingMore || !state.hasMoreData || state.isLoading) return;
    state = state.copyWith(isFetchingMore: true);

    final nextPage = state.currentPage + 1;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final headers = token != null ? {'Authorization': 'Bearer $token'} : const <String, String>{};

      final response = await http.get(
        Uri.parse('${LostFoundService.baseUrl}/api/students/me/lost-items?page=$nextPage&limit=10'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded['status'] == 'success') {
          final List data = decoded['data'] ?? [];
          final newItems = data.map((e) => LostItemPost.fromJson(e)).toList();
          
          final pagination = decoded['pagination'];
          final int totalPages = pagination['total_pages'] ?? 1;

          state = state.copyWith(
            items: [...state.items, ...newItems],
            isFetchingMore: false,
            currentPage: nextPage,
            hasMoreData: nextPage < totalPages,
          );
        } else {
          state = state.copyWith(isFetchingMore: false);
        }
      } else {
        state = state.copyWith(isFetchingMore: false);
      }
    } catch (e) {
      print('Load more error: $e');
      state = state.copyWith(isFetchingMore: false);
    }
  }

  void addPostOptimistic(LostItemPost post) {
    state = state.copyWith(items: [post, ...state.items]);
    ref.read(myLostItemsCountProvider.notifier).increment();
  }

  void updatePostOptimistic(LostItemPost post) {
    final newItems = state.items.map((e) => e.itemId == post.itemId ? post : e).toList();
    state = state.copyWith(items: newItems);
  }

  Future<void> removePostOptimistic(String postId) async {
    final targetId = int.tryParse(postId) ?? 0;
    
    // UI 우선 반영 (Optimistic Update)
    final oldItems = state.items;
    final newItems = state.items.where((e) => e.itemId != targetId).toList();
    state = state.copyWith(items: newItems);
    ref.read(myLostItemsCountProvider.notifier).decrement();

    // 서버에 실제 삭제 요청
    final success = await LostFoundService.deletePost(targetId);
    if (!success) {
      // 실패 시 상태 복구(롤백)
      state = state.copyWith(items: oldItems);
      ref.read(myLostItemsCountProvider.notifier).increment();
    }
  }
}

final myLostItemsProvider = NotifierProvider<MyLostItemsNotifier, MyLostItemsState>(() {
  return MyLostItemsNotifier();
});
