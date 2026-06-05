import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../model/study_room_model.dart';
import '../../api/study_room_service.dart';
import '../../provider/reservation_provider.dart';

class StudyRoomReservationHistoryPage extends ConsumerStatefulWidget {
  const StudyRoomReservationHistoryPage({super.key});

  @override
  ConsumerState<StudyRoomReservationHistoryPage> createState() =>
      _StudyRoomReservationHistoryPageState();
}

class _StudyRoomReservationHistoryPageState
    extends ConsumerState<StudyRoomReservationHistoryPage> {
  final Set<String> _editingGroups = {};

  Future<void> _confirmCancel(StudyRoomReservation res) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 22),
            SizedBox(width: 8),
            Text(
              '예약 취소',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('다음 예약을 취소하시겠습니까?'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    res.roomName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    res.location,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              size: 12, color: Colors.red.shade400),
                          const SizedBox(width: 4),
                          Text(
                            res.date,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded,
                              size: 12, color: Colors.red.shade400),
                          const SizedBox(width: 4),
                          Text(
                            '${res.startHour}:00 ~ ${res.endHour}:00',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '취소 후에는 되돌릴 수 없습니다.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                Text('돌아가기', style: TextStyle(color: Colors.grey.shade600)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('예약 취소'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await StudyRoomService.cancelReservation(res.id);
      if (success) {
        ref.read(reservationProvider.notifier).cancelReservation(res.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_outline,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${res.roomName} 예약이 취소되었습니다.',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('예약 취소에 실패했습니다. 다시 시도해주세요.'),
              backgroundColor: Colors.grey.shade800,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _confirmBatchCancel(List<StudyRoomReservation> comboRes) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 22),
            SizedBox(width: 8),
            Text('일괄 예약 취소', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('공실 조합으로 예약된 ${comboRes.length}개의 방을 모두 취소하시겠습니까?'),
            const SizedBox(height: 10),
            Text('취소 후에는 되돌릴 수 없습니다.', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('돌아가기', style: TextStyle(color: Colors.grey.shade600)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('일괄 취소'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      bool allSuccess = true;
      for (final res in comboRes) {
        final success = await StudyRoomService.cancelReservation(res.id);
        if (success) {
          ref.read(reservationProvider.notifier).cancelReservation(res.id);
        } else {
          allSuccess = false;
        }
      }
      if (mounted) {
        if (allSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('공실 조합 예약이 일괄 취소되었습니다.'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('일부 예약 취소에 실패했습니다.'),
              backgroundColor: Colors.orange.shade800,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Widget _buildSingleCard(StudyRoomReservation res, {bool isSubItem = false}) {
    return Card(
      elevation: 0,
      margin: isSubItem ? const EdgeInsets.only(top: 8) : EdgeInsets.zero,
      color: isSubItem ? Colors.grey.shade50 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: isSubItem ? Colors.grey.shade300 : Colors.green.shade200, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 방 아이콘
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.meeting_room_rounded,
                color: Colors.green.shade600,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            // 예약 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    res.roomName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    res.location,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 13,
                            color: Colors.green.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            res.date,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 13,
                            color: Colors.green.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${res.startHour}:00 ~ ${res.endHour}:00',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // 상태 배지 + 취소 버튼
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '예약완료',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _confirmCancel(res),
                  icon: const Icon(Icons.cancel_outlined, size: 14),
                  label: const Text(
                    '취소',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(
                        color: Colors.redAccent, width: 1),
                    minimumSize: const Size(72, 32),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComboCard(String groupId, List<StudyRoomReservation> comboResList) {
    final isEditing = _editingGroups.contains(groupId);

    return Card(
      elevation: 0,
      color: Colors.amber.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.amber.shade300, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.link, color: Colors.amber.shade800),
                const SizedBox(width: 8),
                Text(
                  '공실 조합 예약 (${comboResList.length}건)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.amber.shade900),
                ),
                const Spacer(),
                if (isEditing)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _editingGroups.remove(groupId);
                      });
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.amber.shade900,
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('완료', style: TextStyle(fontWeight: FontWeight.bold)),
                  )
                else
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _editingGroups.add(groupId);
                      });
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('편집', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                if (!isEditing) ...[
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => _confirmBatchCancel(comboResList),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      minimumSize: const Size(60, 30),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    child: const Text('일괄 취소', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            ...comboResList.map((res) {
              if (isEditing) {
                return _buildSingleCard(res, isSubItem: true);
              }
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(6)),
                      child: Text(
                        '${res.startHour}:00 ~ ${res.endHour}:00',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('${res.roomName} (${res.location})', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reservations = ref.watch(reservationProvider);
    
    final groupedReservations = <String, List<StudyRoomReservation>>{};
    final displayItems = <dynamic>[];

    for (final res in reservations.reversed) {
      if (res.reservationGroupId != null) {
        if (!groupedReservations.containsKey(res.reservationGroupId!)) {
          groupedReservations[res.reservationGroupId!] = [];
          displayItems.add({'type': 'combo', 'groupId': res.reservationGroupId!});
        }
        groupedReservations[res.reservationGroupId!]!.add(res);
      } else {
        displayItems.add({'type': 'single', 'res': res});
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '예약 내역',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            if (reservations.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${reservations.length}건',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: Colors.green.shade600,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: reservations.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_note_outlined,
                    size: 72,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '예약 내역이 없습니다',
                    style:
                        TextStyle(fontSize: 16, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '스터디룸을 예약하면 여기에 표시됩니다',
                    style:
                        TextStyle(fontSize: 13, color: Colors.grey.shade400),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: displayItems.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final item = displayItems[i];
                if (item['type'] == 'single') {
                  return _buildSingleCard(item['res'] as StudyRoomReservation);
                } else {
                  final groupId = item['groupId'] as String;
                  final comboResList = groupedReservations[groupId]!;
                  return _buildComboCard(groupId, comboResList);
                }
              },
            ),
    );
  }
}
