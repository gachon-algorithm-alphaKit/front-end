import 'package:flutter/material.dart';
import '../../../model/topic_model.dart';

class VotePanel extends StatelessWidget {
  final Topic topic;
  final VoteStat? voteStat;
  final bool isActive;
  final void Function(bool opinion) onVote;
  final VoidCallback? onChangeVote1;
  final VoidCallback? onChangeVote2;

  const VotePanel({
    super.key,
    required this.topic,
    this.voteStat,
    this.isActive = true,
    required this.onVote,
    this.onChangeVote1,
    this.onChangeVote2,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: topic.hasVoted
          ? _buildPostVote(context)
          : _buildPreVote(context),
    );
  }

  Widget _buildPreVote(BuildContext context) {
    return Column(
      key: const ValueKey('pre_vote'),
      children: [
        // 제목
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            '어느 쪽에 투표하시겠어요?',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        // 두 선택지 카드
        Row(
          children: [
            Expanded(child: _choiceCard(context, true)),
            const SizedBox(width: 12),
            Expanded(child: _choiceCard(context, false)),
          ],
        ),
      ],
    );
  }

  Widget _choiceCard(BuildContext context, bool isOpinion1) {
    final label = isOpinion1 ? topic.opinion1 : topic.opinion2;
    final color = isOpinion1 ? Colors.deepPurple : Colors.amber;
    final bgColor =
        isOpinion1 ? Colors.deepPurple.shade50 : Colors.amber.shade50;
    final borderColor =
        isOpinion1 ? Colors.deepPurple.shade100 : Colors.amber.shade100;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isActive ? () => onVote(isOpinion1) : null,
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withValues(alpha: 0.1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Column(
            children: [
              Icon(
                isOpinion1
                    ? Icons.looks_one_rounded
                    : Icons.looks_two_rounded,
                size: 36,
                color: color.shade600,
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: color.shade800,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostVote(BuildContext context) {
    if (voteStat == null) {
      return const SizedBox(key: ValueKey('loading'));
    }

    return Column(
      key: const ValueKey('post_vote'),
      children: [
        // 바 차트
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (topic.myVote == true)
                      Container(
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'MY',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple.shade700,
                          ),
                        ),
                      ),
                    Flexible(
                      child: Text(
                        topic.opinion1,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.deepPurple.shade700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        topic.opinion2,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber.shade800,
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),
                    if (topic.myVote == false)
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'MY',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade800,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 40,
            child: Row(
              children: [
                Expanded(
                  flex: voteStat!.opinion1Percent.clamp(1, 100),
                  child: GestureDetector(
                    onTap: isActive ? onChangeVote1 : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.deepPurple.shade400,
                            Colors.deepPurple.shade600,
                          ],
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${voteStat!.opinion1Percent}%',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: voteStat!.opinion2Percent.clamp(1, 100),
                  child: GestureDetector(
                    onTap: isActive ? onChangeVote2 : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.amber.shade400,
                            Colors.amber.shade700,
                          ],
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${voteStat!.opinion2Percent}%',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isActive && topic.hasVoted)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '바를 탭하여 투표를 변경할 수 있습니다',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ),
      ],
    );
  }
}
