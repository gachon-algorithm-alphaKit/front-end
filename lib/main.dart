import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import 'api/auth_api.dart';
import 'model/user_profile.dart';
import 'page/login/login_page.dart';
import 'page/dashboard_page.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,

    // 🌟 웹/데스크톱 화면 최적화: 가로 넓이 제한 및 가운데 정렬
    builder: (context, child) {
      return Container(
        // 양옆 남는 빈 공간의 배경색 (부드러운 회색)
        color: const Color(0xFFF3F4F6),
        child: Center(
          child: ConstrainedBox(
            // 앱 화면의 최대 너비를 제한합니다.
            // 600: 넓적한 태블릿 느낌 / 450: 딱 스마트폰 느낌
            constraints: const BoxConstraints(maxWidth: 600),
            child: Container(
              // 앱 본문 뒤쪽 배경은 흰색으로 고정
              color: Colors.white,
              // 그림자를 넣어주면 웹페이지 느낌이 훨씬 살아납니다
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      spreadRadius: 1,
                    )
                  ],
                ),
                child: child!,
              ),
            ),
          ),
        ),
      );
    },

    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      useMaterial3: true,
    ),

    home: FutureBuilder<dynamic>(
      future: AuthApi.fetchUserInfo(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasData && snapshot.data != null) {
          try {
            final profile = UserProfile.fromJson(snapshot.data as Map<String, dynamic>);
            return MainDashboardPage(initialProfile: profile);
          } catch (e) {
            return const LoginPage(sessionExpired: true);
          }
        } else {
          return FutureBuilder<bool>(
              future: AuthApi.isLoggedIn(),
              builder: (ctx, loginSnapshot) {
                if (loginSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(body: Center(child: CircularProgressIndicator()));
                }
                final bool hasToken = loginSnapshot.data ?? false;
                if (hasToken) {
                  AuthApi.logout();
                  return const LoginPage(sessionExpired: true);
                }
                return const LoginPage();
              }
          );
        }
      },
    ),
  );
}