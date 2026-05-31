import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../model/topic_model.dart';
import '../../provider/topic_provider.dart';
import '../../component/common_widgets.dart';

import 'widget/vote_panel.dart';
import 'widget/vote_count_badge.dart';
import 'widget/opinion_tab_bar.dart';
import 'widget/comment_list.dart';
import 'widget/word_frequency_analyzer.dart';
import 'widget/word_frequency_chart.dart';

class TopicDetailPage extends ConsumerStatefulWidget {
  final Topic topic;
  const TopicDetailPage({super.key, required this.topic});

  @override
  ConsumerState<TopicDetailPage> createState() => _TopicDetailPageState();
}

class _TopicDetailPageState extends ConsumerState<TopicDetailPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  Timer? _pollTimer;
  late Topic _topic;

  @override
  void initState() {
    super.initState();
    _topic = widget.topic;
    _tabController = TabController(length: 3, vsync: this);

    // 투표 통계 폴링 (10초마다)
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      ref.read(activeTopicProvider.notifier).refreshStat();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleVote(bool opinion) async {
    final activeState = ref.read(activeTopicProvider);
    final currentTopic = activeState.topic ?? _topic;

    // 이미 같은 의견에 투표한 경우 무시
    if (currentTopic.myVote == opinion) return;

    // 투표 변경 시 댓글 확인
    if (currentTopic.hasVoted) {
      final confirmed = await _showVoteChangeDialog(opinion);
      if (confirmed != true) return;
      await ref
          .read(activeTopicProvider.notifier)
          .vote(opinion, confirmDelete: true);
    } else {
      await ref.read(activeTopicProvider.notifier).vote(opinion);
    }
  }

  Future<bool?> _showVoteChangeDialog(bool newOpinion) {
    final label = newOpinion ? _topic.opinion1 : _topic.opinion2;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('투표 변경', style: TextStyle(fontSize: 16)),
        content: Text(
          '"$label" 쪽으로 투표를 변경하시겠습니까?\n\n⚠️ 이전 의견에 작성한 댓글이 삭제됩니다.',
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('취소', style: TextStyle(color: Colors.grey.shade600)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.deepPurple,
            ),
            child: const Text('변경'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeState = ref.watch(activeTopicProvider);
    final currentTopic = activeState.topic ?? _topic;
    final voteStat = activeState.voteStat;
    final isActive = currentTopic.isActive;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: buildAppBar('밸런스 게임', Colors.deepPurple),
      body: Column(
        children: [
          // 비활성 토픽 배너
          if (!isActive)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border(
                  bottom: BorderSide(color: Colors.orange.shade200),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 18, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Text(
                    '종료된 토픽입니다',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ],
              ),
            ),

          // 토픽 헤더
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.deepPurple.shade600,
                  Colors.deepPurple.shade800,
                ],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentTopic.formattedDate,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  currentTopic.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),
                // 투표 패널
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      VotePanel(
                        topic: currentTopic,
                        voteStat: voteStat,
                        isActive: isActive,
                        onVote: _handleVote,
                        onChangeVote1: () => _handleVote(true),
                        onChangeVote2: () => _handleVote(false),
                      ),
                      if (voteStat != null) ...[
                        const SizedBox(height: 12),
                        VoteCountBadge(count: voteStat.totalCount),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 탭바
          OpinionTabBar(
            controller: _tabController,
            opinion1: currentTopic.opinion1,
            opinion2: currentTopic.opinion2,
          ),

          // 탭 콘텐츠
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Opinion 1 탭
                CommentList(
                  topicId: currentTopic.topicId,
                  opinion: true,
                  isActive: isActive,
                  isMyOpinion: currentTopic.myVote == true,
                ),
                // Opinion 2 탭
                CommentList(
                  topicId: currentTopic.topicId,
                  opinion: false,
                  isActive: isActive,
                  isMyOpinion: currentTopic.myVote == false,
                ),
                // 통계 탭
                _buildStatisticsTab(currentTopic),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab(Topic currentTopic) {
    // 두 의견의 댓글을 모두 가져와서 분석
    final key1 = '${currentTopic.topicId}_true';
    final key2 = '${currentTopic.topicId}_false';
    final state1 = ref.watch(topicCommentProvider(key1));
    final state2 = ref.watch(topicCommentProvider(key2));

    final allComments = [
      ...state1.comments.map((c) => c.comment),
      ...state2.comments.map((c) => c.comment),
    ];

    final totalCount = state1.comments.length + state2.comments.length;

    if (totalCount < 10) {
      return const WordFrequencyChart(frequencies: {});
    }

    final frequencies = WordFrequencyAnalyzer.analyze(allComments);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 의견별 키워드 분석
          WordFrequencyChart(frequencies: frequencies),
          const SizedBox(height: 24),
          // 의견1 키워드
          _buildOpinionWordCloud(
            '${currentTopic.opinion1} 키워드',
            state1.comments.map((c) => c.comment).toList(),
            Colors.deepPurple,
          ),
          const SizedBox(height: 20),
          // 의견2 키워드
          _buildOpinionWordCloud(
            '${currentTopic.opinion2} 키워드',
            state2.comments.map((c) => c.comment).toList(),
            Colors.amber.shade700,
          ),
        ],
      ),
    );
  }

  Widget _buildOpinionWordCloud(
      String title, List<String> comments, Color color) {
    if (comments.length < 5) {
      return const SizedBox.shrink();
    }

    final freq = WordFrequencyAnalyzer.analyze(comments, topN: 10);
    if (freq.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: freq.entries.map((entry) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: color.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                '${entry.key} (${entry.value})',
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
