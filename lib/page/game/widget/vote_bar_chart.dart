import 'package:flutter/material.dart';

class VoteBarChart extends StatelessWidget {
  final int opinion1Percent;
  final int opinion2Percent;
  final String opinion1Label;
  final String opinion2Label;
  final bool? myVote;
  final bool isActive;
  final VoidCallback? onTapOpinion1;
  final VoidCallback? onTapOpinion2;

  const VoteBarChart({
    super.key,
    required this.opinion1Percent,
    required this.opinion2Percent,
    required this.opinion1Label,
    required this.opinion2Label,
    this.myVote,
    this.isActive = true,
    this.onTapOpinion1,
    this.onTapOpinion2,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 레이블 행
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (myVote == true)
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
                        opinion1Label,
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
                        opinion2Label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber.shade800,
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),
                    if (myVote == false)
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
        // 바 차트
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 40,
            child: Row(
              children: [
                // Opinion 1 bar
                Expanded(
                  flex: opinion1Percent.clamp(1, 100),
                  child: GestureDetector(
                    onTap: isActive ? onTapOpinion1 : null,
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
                        '$opinion1Percent%',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                // Opinion 2 bar
                Expanded(
                  flex: opinion2Percent.clamp(1, 100),
                  child: GestureDetector(
                    onTap: isActive ? onTapOpinion2 : null,
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
                        '$opinion2Percent%',
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
      ],
    );
  }
}
