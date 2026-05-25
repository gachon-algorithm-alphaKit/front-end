import 'dart:math';

import '../model/lost_found_model.dart';

class LostFoundService {
  // TODO: GET /api/lost-items/search?q=&mode=kmp|levenshtein
  static Future<List<LostItemPost>> search(String query, bool isFuzzy) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (query.isEmpty) {
      return _mockItems;
    }

    return _mockItems.where((item) {
      final target = '${item.title} ${item.category} ${item.description}';
      return isFuzzy
          ? _levenshtein(query, item.title) <= 5
          : target.contains(query);
    }).toList()..sort((a, b) => b.similarity.compareTo(a.similarity));
  }

  // TODO: POST /api/lost-items/{itemId}/claim
  static Future<bool> claimItem(int itemId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }

  static int _levenshtein(String s, String t) {
    final m = s.length, n = t.length;
    final dp = List.generate(m + 1, (i) => List.filled(n + 1, 0));
    for (int i = 0; i <= m; i++) {
      dp[i][0] = i;
    }
    for (int j = 0; j <= n; j++) {
      dp[0][j] = j;
    }
    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        dp[i][j] = s[i - 1] == t[j - 1]
            ? dp[i - 1][j - 1]
            : 1 + [dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]].reduce(min);
      }
    }
    return dp[m][n];
  }

  static const _mockItems = <LostItemPost>[
    LostItemPost(
      itemId: 1,
      schoolId: 1,
      placeId: 2,
      studentId: 1,
      title: '에어팟 프로',
      isAnonymous: true,
      category: '비전타워 3층',
      description: '흰색 케이스, 이름 스티커 있음',
      imgFilePath: '',
      createTime: '2026-05-24',
      similarity: 100,
      status: '보관중',
    ),
    LostItemPost(
      itemId: 2,
      schoolId: 1,
      placeId: 9,
      studentId: 2,
      title: '지갑',
      isAnonymous: true,
      category: '학생회관 1층',
      description: '검정 가죽 반지갑, 카드 여러 장',
      imgFilePath: '',
      createTime: '2026-05-23',
      similarity: 90,
      status: '보관중',
    ),
    LostItemPost(
      itemId: 3,
      schoolId: 1,
      placeId: 5,
      studentId: 3,
      title: '텀블러',
      isAnonymous: true,
      category: 'AI도서관 열람실',
      description: '스탠리 초록색 500ml',
      imgFilePath: '',
      createTime: '2026-05-22',
      similarity: 85,
      status: '보관중',
    ),
    LostItemPost(
      itemId: 4,
      schoolId: 1,
      placeId: 1,
      studentId: 4,
      title: '우산',
      isAnonymous: true,
      category: '가천관 1층',
      description: '자동 접이식 남색 우산',
      imgFilePath: '',
      createTime: '2026-05-21',
      similarity: 80,
      status: '보관중',
    ),
    LostItemPost(
      itemId: 5,
      schoolId: 1,
      placeId: 5,
      studentId: 5,
      title: '아이패드',
      isAnonymous: true,
      category: 'AI도서관 2층',
      description: 'iPad Pro 11인치, 케이스 있음',
      imgFilePath: '',
      createTime: '2026-05-20',
      similarity: 95,
      status: '주인 찾음',
    ),
    LostItemPost(
      itemId: 6,
      schoolId: 1,
      placeId: 8,
      studentId: 6,
      title: '학생증',
      isAnonymous: true,
      category: '교육대학원 지하',
      description: '가천대학교 학생증',
      imgFilePath: '',
      createTime: '2026-05-19',
      similarity: 88,
      status: '보관중',
    ),
  ];
}
