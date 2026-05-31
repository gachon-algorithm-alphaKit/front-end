

/// 한국어 불용어 + 댓글에서 단어 빈도를 분석하는 유틸리티
class WordFrequencyAnalyzer {
  WordFrequencyAnalyzer._();

  static const _stopwords = <String>{
    // 조사
    '이', '가', '은', '는', '을', '를', '에', '의', '와', '과',
    '도', '로', '으로', '에서', '까지', '부터', '보다', '처럼',
    '만큼', '대로', '마저', '조차', '밖에', '뿐',
    // 대명사·지시어
    '나', '너', '저', '우리', '그', '이것', '저것', '그것',
    '여기', '거기', '저기', '이런', '그런', '저런',
    // 동사·형용사 어미
    '하다', '되다', '있다', '없다', '이다', '아니다',
    '같다', '하는', '되는', '있는', '없는', '한다',
    // 부사
    '매우', '너무', '정말', '진짜', '아주', '좀', '잘',
    '못', '안', '또', '더', '다시', '항상', '자주',
    // 접속사
    '그리고', '하지만', '그런데', '그래서', '또는', '혹은',
    // 기타
    '것', '수', '때', '중', '등', '점', '그냥',
    '거', '게', '데', '건', '말', '걸',
  };

  static final _koreanPattern = RegExp(r'[가-힣]{2,}');
  static final _urlPattern = RegExp(r'https?://\S+');
  static final _hashtagPattern = RegExp(r'#\S+');
  static final _emojiPattern = RegExp(
    r'[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|'
    r'[\u{1F1E0}-\u{1F1FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]',
    unicode: true,
  );

  /// 댓글 리스트에서 상위 [topN]개 단어 빈도 분석
  static Map<String, int> analyze(List<String> texts, {int topN = 20}) {
    final freq = <String, int>{};

    for (final text in texts) {
      // URL, 해시태그, 이모지 제거
      var cleaned = text
          .replaceAll(_urlPattern, '')
          .replaceAll(_hashtagPattern, '')
          .replaceAll(_emojiPattern, '');

      // 한국어 단어 추출
      final matches = _koreanPattern.allMatches(cleaned);
      for (final match in matches) {
        final word = match.group(0)!;
        if (!_stopwords.contains(word)) {
          freq[word] = (freq[word] ?? 0) + 1;
        }
      }
    }

    // 빈도순 정렬 후 상위 N개
    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sorted.take(topN));
  }
}
