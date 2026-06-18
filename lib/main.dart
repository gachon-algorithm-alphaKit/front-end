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
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

<<<<<<< HEAD
        // If snapshot data is not null, it means we have a successful fetch.
        // We need to parse it to UserProfile. Wait, I should parse it here or in auth_api?
        // auth_api returns a Map<String, dynamic>. We can parse it here.
=======
>>>>>>> origin/new-ui
        if (snapshot.hasData && snapshot.data != null) {
          try {
            final profile = UserProfile.fromJson(
              snapshot.data as Map<String, dynamic>,
            );
            return MainDashboardPage(initialProfile: profile);
          } catch (e) {
            return const LoginPage(sessionExpired: true);
          }
        } else {
          return FutureBuilder<bool>(
<<<<<<< HEAD
            future: AuthApi.isLoggedIn(),
            builder: (ctx, loginSnapshot) {
              if (loginSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              final bool hasToken = loginSnapshot.data ?? false;
              if (hasToken) {
                // Had token but fetch failed -> session expired
                AuthApi.logout(); // clear bad token
                return const LoginPage(sessionExpired: true);
              }
              return const LoginPage();
            },
=======
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
>>>>>>> origin/new-ui
          );
        }
      },
    ),
  );
<<<<<<< HEAD
}

class ResponsiveAppWrapper extends StatefulWidget {
  final Widget child;
  const ResponsiveAppWrapper({super.key, required this.child});

  @override
  State<ResponsiveAppWrapper> createState() => _ResponsiveAppWrapperState();
}

class _ResponsiveAppWrapperState extends State<ResponsiveAppWrapper> {
  static const double desktopBreakpoint = 600;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (kIsWeb) {
      precacheImage(const AssetImage('assets/icon/alphakit.png'), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return widget.child;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < desktopBreakpoint) {
          return widget.child;
        }

        final screenHeight = constraints.maxHeight;
        final deviceHeight = screenHeight * 0.92;
        final deviceWidth = deviceHeight * 9 / 20;

        return Scaffold(
          backgroundColor: Colors.white,
          body: Row(
            children: [
              Expanded(
                child: Center(
                  child: IgnorePointer(
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Image.asset(
                        'assets/icon/alphakit.png',
                        width: 200,
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 380,
                    maxWidth: 520,
                  ),
                  child: Container(
                    width: deviceWidth,
                    height: deviceHeight,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border.all(color: Colors.black, width: 16),
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: widget.child,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: IgnorePointer(
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Image.asset(
                        'assets/icon/alphakit.png',
                        width: 200,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
=======
}
>>>>>>> origin/new-ui
