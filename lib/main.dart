import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api/auth_api.dart';
import 'model/user_profile.dart';
import 'page/login_page.dart';
import 'page/dashboard_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
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
        
        // If snapshot data is not null, it means we have a successful fetch.
        // We need to parse it to UserProfile. Wait, I should parse it here or in auth_api?
        // auth_api returns a Map<String, dynamic>. We can parse it here.
        if (snapshot.hasData && snapshot.data != null) {
          try {
            final profile = UserProfile.fromJson(snapshot.data as Map<String, dynamic>);
            return MainDashboardPage(initialProfile: profile);
          } catch (e) {
            return const LoginPage(sessionExpired: true);
          }
        } else {
          // Check if there was a token but fetch failed (session expired) vs no token
          // Since fetchUserInfo returns null on failure or no token, we can just check isLoggedIn.
          // Let's do a simple check. If isLoggedIn is true but data is null, session expired.
          // Wait, the user specifically wants the message. If fetchUserInfo() handles no-token vs bad-token,
          // let's just use a FutureBuilder that calls a custom method.
          // Actually, let's just check if token exists.
          return FutureBuilder<bool>(
            future: AuthApi.isLoggedIn(),
            builder: (ctx, loginSnapshot) {
              if (loginSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              final bool hasToken = loginSnapshot.data ?? false;
              if (hasToken) {
                // Had token but fetch failed -> session expired
                AuthApi.logout(); // clear bad token
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
