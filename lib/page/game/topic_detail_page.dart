import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../component/common_widgets.dart';
import '../../model/topic_model.dart';
import '../../provider/topic_provider.dart';
import 'widget/comment_list.dart';
import 'widget/opinion_tab_bar.dart';
import 'widget/vote_count_badge.dart';
import 'widget/vote_panel.dart';
import 'widget/word_frequency_analyzer.dart';
import 'widget/word_frequency_chart.dart';

class TopicDetailPage extends ConsumerStatefulWidget {
  final Topic topic;
  const TopicDetailPage({super.key, required this.topic});

  @override
  ConsumerState<TopicDetailPage> createState() => _TopicDetailPageState();
}

class _TopicDetailPageState extends ConsumerState<TopicDetailPage> with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _outerScrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _textController = TextEditingController();
  Timer? _pollTimer;
  late Topic _topic;
  bool _isPastTopic = false;
  VoteStat? _pastTopicVoteStat;

  @override
  void initState() {
    super.initState();
    _topic = widget.topic;
    _isPastTopic = !_topic.isActive;
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _focusNode.unfocus();
      }
      setState(() {});
    });

    if (!_isPastTopic) {
      // 투표 통계 폴링 (10초마다)
      _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        ref.read(activeTopicProvider.notifier).refreshStat();
      });
    } else {
      _fetchPastTopicStat();
    }
  }

  Future<void> _fetchPastTopicStat() async {
    try {
      final stat = await ref.read(topicListProvider.notifier).fetchVoteStatForPastTopic(_topic.topicId);
      if (mounted) {
        setState(() {
          _pastTopicVoteStat = stat;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _tabController.dispose();
    _outerScrollController.dispose();
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _handleVote(bool opinion) async {
    final activeState = ref.read(activeTopicProvider);
    final currentTopic = _topic.isActive ? (activeState.topic ?? _topic) : _topic;

    if (!currentTopic.isActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('이전 밸런스 게임에는 참여하실 수 없습니다.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    // 이미 같은 의견에 투표한 경우 무시
    if (currentTopic.myVote == opinion) return;

    // 투표 변경 시 댓글 확인
    if (currentTopic.hasVoted) {
      final confirmed = await _showVoteChangeDialog(opinion);
      if (confirmed != true) return;
      await ref.read(activeTopicProvider.notifier).vote(opinion, confirmDelete: true);
      
      // 기존/새 의견 댓글 모두 새로고침
      final key1 = '${currentTopic.topicId}_true';
      final key2 = '${currentTopic.topicId}_false';
      ref.read(topicCommentProvider(key1).notifier).fetchComments();
      ref.read(topicCommentProvider(key2).notifier).fetchComments();
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
        content: Text('"$label" 쪽으로 투표를 변경하시겠습니까?\n\n⚠️ 이전 의견에 작성한 댓글이 삭제됩니다.', style: const TextStyle(fontSize: 14, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('취소', style: TextStyle(color: Colors.grey.shade600)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.deepPurple),
            child: const Text('변경'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeState = ref.watch(activeTopicProvider);
    final currentTopic = _isPastTopic ? _topic : (activeState.topic ?? _topic);
    final voteStat = _isPastTopic ? _pastTopicVoteStat : activeState.voteStat;
    final isActive = currentTopic.isActive;

    final tabIndex = _tabController.index;
    final headerHeight = tabIndex > 1 ? 62.0 : 108.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: buildAppBar('밸런스 게임', Colors.deepPurple),
      bottomNavigationBar: _buildBottomNav(currentTopic, isActive),
      body: NestedScrollView(
        controller: _outerScrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  // 비활성 토픽 배너
                  if (!isActive)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        border: Border(bottom: BorderSide(color: Colors.orange.shade200)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 18, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          Text(
                            '종료된 토픽입니다',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.orange.shade800),
                          ),
                        ],
                      ),
                    ),

                  // 토픽 헤더
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.deepPurple.shade600, Colors.deepPurple.shade800]),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(currentTopic.formattedDate, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
                        const SizedBox(height: 6),
                        Text(
                          currentTopic.title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, height: 1.3),
                        ),
                        const SizedBox(height: 16),
                        // 투표 패널
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4))],
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
                              if (voteStat != null) ...[const SizedBox(height: 12), VoteCountBadge(count: voteStat.totalCount)],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(
                  height: headerHeight,
                  child: Column(
                    children: [
                      OpinionTabBar(controller: _tabController, opinion1: currentTopic.opinion1, opinion2: currentTopic.opinion2),
                      AnimatedBuilder(
                        animation: _tabController,
                        builder: (context, child) {
                          if (_tabController.index > 1) return const SizedBox.shrink();

                          final opinion = _tabController.index == 0;
                          final providerKey = '${currentTopic.topicId}_$opinion';
                          final isMyVote = currentTopic.myVote == opinion;
                          final showInputBox = isActive && isMyVote;

                          return Consumer(
                            builder: (context, ref, _) {
                              final state = ref.watch(topicCommentProvider(providerKey));
                              return Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: Row(
                                      children: [
                                        Text(
                                          '총 ${state.totalCount}',
                                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                                        ),
                                        const Spacer(),
                                        _buildSortChip(ref, '최신순', 'latest', state.sort, providerKey),
                                        const SizedBox(width: 6),
                                        _buildSortChip(ref, '추천순', 'like', state.sort, providerKey),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // Opinion 1 탭
            CommentList(topicId: currentTopic.topicId, opinion: true, isActive: isActive, isMyOpinion: currentTopic.myVote == true),
            // Opinion 2 탭
            CommentList(topicId: currentTopic.topicId, opinion: false, isActive: isActive, isMyOpinion: currentTopic.myVote == false),
            // 통계 탭
            _buildStatisticsTab(currentTopic),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsTab(Topic currentTopic) {
    // 두 의견의 댓글을 모두 가져와서 분석
    final key1 = '${currentTopic.topicId}_true';
    final key2 = '${currentTopic.topicId}_false';
    final state1 = ref.watch(topicCommentProvider(key1));
    final state2 = ref.watch(topicCommentProvider(key2));

    final allComments = [...state1.comments.map((c) => c.comment), ...state2.comments.map((c) => c.comment)];

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
          _buildOpinionWordCloud('${currentTopic.opinion1} 키워드', state1.comments.map((c) => c.comment).toList(), Colors.deepPurple),
          const SizedBox(height: 20),
          // 의견2 키워드
          _buildOpinionWordCloud('${currentTopic.opinion2} 키워드', state2.comments.map((c) => c.comment).toList(), Colors.amber.shade700),
        ],
      ),
    );
  }

  Widget _buildOpinionWordCloud(String title, List<String> comments, Color color) {
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
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color),
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
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Text(
                '${entry.key} (${entry.value})',
                style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _submitComment(String providerKey) async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final success = await ref.read(topicCommentProvider(providerKey).notifier).addComment(text);

    if (success) {
      _textController.clear();
      _focusNode.unfocus();
      final primaryController = PrimaryScrollController.of(context);
      if (primaryController.hasClients) {
        primaryController.animateTo(_outerScrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    }
  }

  Widget _buildCommentInput(String providerKey) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                scrollPadding: EdgeInsets.zero,
                decoration: InputDecoration(
                  hintText: '댓글을 입력해 주세요',
                  hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Colors.deepPurple),
                  ),
                ),
                style: const TextStyle(fontSize: 14),
                minLines: 1,
                maxLines: 4,
                onTap: () {
                  if (_outerScrollController.hasClients) {
                    _outerScrollController.animateTo(_outerScrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => _submitComment(providerKey),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(color: Colors.deepPurple, shape: BoxShape.circle),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(Topic currentTopic, bool isActive) {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        final tabIndex = _tabController.index;
        if (tabIndex > 1) return const SizedBox.shrink();

        final opinion = tabIndex == 0;
        final isMyVote = currentTopic.myVote == opinion;
        final showInputBox = isActive && isMyVote;
        final providerKey = '${currentTopic.topicId}_$opinion';

        if (!showInputBox) return const SizedBox.shrink();

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: _buildCommentInput(providerKey),
        );
      },
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;
  _TabBarDelegate({required this.child, required this.height});

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: const Color(0xFFF5F7FA), child: child);
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => oldDelegate.height != height;
}

Widget _buildSortChip(WidgetRef ref, String label, String sortValue, String currentSort, String providerKey) {
  final selected = currentSort == sortValue;
  return ChoiceChip(
    label: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : Colors.grey.shade600)),
    selected: selected,
    selectedColor: Colors.deepPurple,
    backgroundColor: Colors.grey.shade100,
    side: BorderSide.none,
    padding: const EdgeInsets.symmetric(horizontal: 4),
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    visualDensity: VisualDensity.compact,
    onSelected: (v) {
      if (v && currentSort != sortValue) {
        ref.read(topicCommentProvider(providerKey).notifier).changeSort(sortValue);
      }
    },
  );
}
