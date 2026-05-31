import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../model/topic_model.dart';
import '../../provider/topic_provider.dart';
import '../../component/common_widgets.dart';

import 'topic_detail_page.dart';
import 'widget/topic_card.dart';

class GameDashboardPage extends ConsumerStatefulWidget {
  const GameDashboardPage({super.key});

  @override
  ConsumerState<GameDashboardPage> createState() => _GameDashboardPageState();
}

class _GameDashboardPageState extends ConsumerState<GameDashboardPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(topicListProvider.notifier).fetchMore();
    }
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      ref.read(activeTopicProvider.notifier).fetch(),
      ref.read(topicListProvider.notifier).fetch(),
    ]);
  }

  void _openTopicDetail(Topic topic) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TopicDetailPage(topic: topic),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeState = ref.watch(activeTopicProvider);
    final listState = ref.watch(topicListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: buildAppBar('밸런스 게임', Colors.deepPurple),
      body: RefreshIndicator(
        color: Colors.deepPurple,
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 활성 토픽 히어로 카드 ──
              _buildActiveTopicSection(activeState),

              // ── 지난 토픽 리스트 ──
              _buildPastTopicsSection(listState),

              SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTopicSection(ActiveTopicState state) {
    if (state.isLoading && state.topic == null) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(color: Colors.deepPurple),
        ),
      );
    }

    if (state.topic == null) {
      return _buildNoActiveTopicCard();
    }

    final topic = state.topic!;
    final voteStat = state.voteStat;

    return GestureDetector(
      onTap: () => _openTopicDetail(topic),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade500,
              Colors.deepPurple.shade800,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // 장식 원
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              bottom: -30,
              left: -15,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),
            // 콘텐츠
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상단 라벨
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_fire_department_rounded,
                              size: 14,
                              color: Colors.amber.shade300,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              '오늘의 토픽',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // 제목
                  Text(
                    topic.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  // 의견 카드
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            topic.opinion1,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          'VS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            topic.opinion2,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // 투표 후 미니 비율 바
                  if (topic.hasVoted && voteStat != null) ...[
                    const SizedBox(height: 14),
                    _buildMiniRatioBar(voteStat),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniRatioBar(VoteStat stat) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 6,
            child: Row(
              children: [
                Expanded(
                  flex: stat.opinion1Percent.clamp(1, 100),
                  child: Container(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                Expanded(
                  flex: stat.opinion2Percent.clamp(1, 100),
                  child: Container(
                    color: Colors.amber.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${stat.opinion1Percent}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            Text(
              '${stat.totalCount}명 참여',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
            Text(
              '${stat.opinion2Percent}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.amber.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNoActiveTopicCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.how_to_vote_outlined,
            size: 48,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            '오늘의 주제가 아직 준비되지 않았습니다 ⏰',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPastTopicsSection(TopicListState state) {
    // 지난 토픽만 필터 (활성 토픽 제외)
    final pastTopics =
        state.topics.where((t) => !t.isActive).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.history_rounded,
                size: 18,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Text(
                '지난 토픽',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (state.isLoading && pastTopics.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: CircularProgressIndicator(color: Colors.deepPurple),
              ),
            )
          else if (pastTopics.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  '아직 지난 토픽이 없습니다',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
            )
          else ...[
            ...pastTopics.map(
              (topic) => TopicCard(
                topic: topic,
                onTap: () => _openTopicDetail(topic),
              ),
            ),
            if (state.isLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
