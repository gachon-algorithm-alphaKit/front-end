import 'package:flutter_riverpod/legacy.dart';

import '../api/auth_api.dart';
import '../model/user_profile.dart';

class AuthState {
  final bool isLoading;
  final bool isLoggedIn;
  final UserProfile? profile;

  AuthState({this.isLoading = true, this.isLoggedIn = false, this.profile});

  AuthState copyWith({bool? isLoading, bool? isLoggedIn, UserProfile? profile}) {
    return AuthState(isLoading: isLoading ?? this.isLoading, isLoggedIn: isLoggedIn ?? this.isLoggedIn, profile: profile ?? this.profile);
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState()) {
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    final tokenExists = await AuthApi.isLoggedIn();
    if (tokenExists) {
      final userInfo = await AuthApi.fetchUserInfo();
      if (userInfo != null) {
        state = state.copyWith(isLoading: false, isLoggedIn: true, profile: UserProfile.fromJson(userInfo));
      } else {
        // Token exists but fetch failed (session expired)
        await AuthApi.logout();
        state = state.copyWith(isLoading: false, isLoggedIn: false, profile: null);
      }
    } else {
      state = state.copyWith(isLoading: false, isLoggedIn: false, profile: null);
    }
  }

  Future<void> login(String studentId, String password, int schoolId) async {
    state = state.copyWith(isLoading: true);
    final response = await AuthApi.login(studentId, password, schoolId);
    if (response['status'] == 'success') {
      final data = response['data'];
      if (data != null) {
        await AuthApi.saveTokens(data['access_token'], data['refresh_token']);
      }
      await checkLoginStatus();
    } else {
      state = state.copyWith(isLoading: false, isLoggedIn: false);
      throw Exception('로그인 실패: ${response['message']}');
    }
  }

  Future<void> logout() async {
    await AuthApi.logout();
    state = state.copyWith(isLoggedIn: false, profile: null);
  }

  void sessionExpired() {
    AuthApi.logout();
    state = state.copyWith(isLoggedIn: false, profile: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
