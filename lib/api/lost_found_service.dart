import 'dart:math';

import '../model/lost_found_model.dart';

class LostFoundService {
  // ─────────────────────────────────────────────────────────
  // TODO: GET /api/lostfound/search?q=&mode=kmp|levenshtein
  //   Response: List<LostItem>
  //   서버: KMP(정확검색) 또는 Levenshtein(유사검색) 처리
  // ─────────────────────────────────────────────────────────
  static Future<List<LostItem>> search(String query, bool isFuzzy) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (query.isEmpty) {
      return _mockItems;
    }
    // MOCK: 실제 KMP / Levenshtein은 서버에서 처리
    return _mockItems.where((i) {
      final target = '${i.itemName} ${i.description}';
      return isFuzzy
          ? _levenshtein(query, i.itemName) <= 5
          : target.contains(query);
    }).toList()..sort((a, b) => b.similarity.compareTo(a.similarity));
  }

  // ─────────────────────────────────────────────────────────
  // TODO: POST /api/lostfound/claim
  //   Body: { itemId, userId, contact }
  //   Response: { success, claimId }
  // ─────────────────────────────────────────────────────────
  static Future<bool> claimItem(String itemId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return true; // MOCK
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

  static final _mockItems = <LostItem>[
    const LostItem(
      id: 'L001',
      itemName: '에어팟 프로',
      description: '흰색 케이스, 이름 스티커 있음',
      location: '비전타워 3층',
      foundDate: '2026.05.24',
      status: '보관중',
      similarity: 100,
    ),
    const LostItem(
      id: 'L002',
      itemName: '지갑',
      description: '검정 가죽 반지갑, 카드 여러 장',
      location: '학생회관 1층',
      foundDate: '2026.05.23',
      status: '보관중',
      similarity: 90,
    ),
    const LostItem(
      id: 'L003',
      itemName: '텀블러',
      description: '스탠리 초록색 500ml',
      location: 'AI도서관 열람실',
      foundDate: '2026.05.22',
      status: '보관중',
      similarity: 85,
    ),
    const LostItem(
      id: 'L004',
      itemName: '우산',
      description: '자동 접이식 남색 우산',
      location: '가천관 1층',
      foundDate: '2026.05.21',
      status: '보관중',
      similarity: 80,
    ),
    const LostItem(
      id: 'L005',
      itemName: '아이패드',
      description: 'iPad Pro 11인치, 케이스 있음',
      location: 'AI도서관 2층',
      foundDate: '2026.05.20',
      status: '주인 찾음',
      similarity: 95,
    ),
    const LostItem(
      id: 'L006',
      itemName: '학생증',
      description: '가천대학교 학생증',
      location: '교육대학원 지하',
      foundDate: '2026.05.19',
      status: '보관중',
      similarity: 88,
    ),
  ];
}
