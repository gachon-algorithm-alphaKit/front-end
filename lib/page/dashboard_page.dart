import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../model/user_profile.dart';
import 'campus_navigation_page.dart';
import 'course_search_page.dart';
import 'lost_found_page.dart';
import 'profile_settings_page.dart';
import 'scholarship_page.dart';
import 'study_room_page.dart';

class MainDashboardPage extends StatefulWidget {
  final UserProfile? initialProfile;
  final XFile? initialProfileImage;
  const MainDashboardPage({
    super.key,
    this.initialProfile,
    this.initialProfileImage,
  });
  @override
  State<MainDashboardPage> createState() => _MainDashboardPageState();
}

class _MainDashboardPageState extends State<MainDashboardPage> {
  late UserProfile _profile;
  XFile? _profileImage;

  @override
  void initState() {
    super.initState();
    _profile = widget.initialProfile ?? UserProfile();
    _profileImage = widget.initialProfileImage;
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _goTo(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  void _openSettings() => _goTo(
    ProfileSettingsPage(
      profile: _profile,
      profileImage: _profileImage,
      onProfileChanged: (p) => setState(() => _profile = p),
      onImageChanged: (img) => setState(() => _profileImage = img),
    ),
  );

  static const _cards = [
    {
      'title': '캠퍼스 길찾기',
      'sub': 'A* 알고리즘 최적 경로',
      'icon': Icons.explore_rounded,
      'color': Colors.blueAccent,
    },
    {
      'title': '강의 계획서 검색',
      'sub': '초성·Trie 자동완성 검색',
      'icon': Icons.find_in_page_rounded,
      'color': null,
    },
    {
      'title': '스터디룸 예약',
      'sub': '실시간 공석·최적 매칭',
      'icon': Icons.meeting_room_rounded,
      'color': null,
    },
    {
      'title': '분실물 통합 센터',
      'sub': 'KMP + 유사도 검색',
      'icon': Icons.inventory_2_rounded,
      'color': Colors.redAccent,
    },
    {
      'title': '장학 제도 탐색',
      'sub': '맞춤형 장학금 매칭',
      'icon': Icons.monetization_on_rounded,
      'color': null,
    },
  ];

  Color _cardColor(int i) {
    final colors = [
      Colors.blueAccent,
      Colors.amber.shade800,
      Colors.green.shade600,
      Colors.redAccent,
      Colors.teal.shade600,
    ];
    return colors[i];
  }

  Widget _getPage(int i) {
    switch (i) {
      case 0:
        return const CampusNavigationPage();
      case 1:
        return const CourseSearchPage();
      case 2:
        return const StudyRoomPage();
      case 3:
        return const LostFoundPage();
      case 4:
        return ScholarshipPage(profile: _profile);
      default:
        return const CampusNavigationPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      extendBody: true,
      appBar: AppBar(
        title: const Text(
          'AlphaKit',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.indigo,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 웰컴 배너 (정적)
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.indigo,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '안녕하세요, ${_profile.name}님! 👋',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '성공적인 대학 생활을 위한 핵심 서비스를 이용해 보세요.',
                    style: TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                ],
              ),
            ),

            // 서비스 카드
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '캠퍼스 종합 서비스',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _serviceCard(0)),
                      const SizedBox(width: 16),
                      Expanded(child: _serviceCard(1)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _serviceCard(2)),
                      const SizedBox(width: 16),
                      Expanded(child: _serviceCard(3)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _wideCard(4),
                ],
              ),
            ),
            SizedBox(height: bottom + 28),
          ],
        ),
      ),
    );
  }

  Widget _serviceCard(int i) {
    final color = _cardColor(i);
    final card = _cards[i];
    return AspectRatio(
      aspectRatio: 1.15,
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: InkWell(
          onTap: () => _goTo(_getPage(i)),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(card['icon'] as IconData, color: color, size: 28),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card['title'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      card['sub'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _wideCard(int i) {
    final color = _cardColor(i);
    final card = _cards[i];
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => _goTo(_getPage(i)),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(card['icon'] as IconData, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card['title'] as String,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      card['sub'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.grey.shade400,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// 1. 캠퍼스 길찾기 페이지
// ══════════════════════════════════════════════════════════════
