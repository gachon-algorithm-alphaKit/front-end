import 'package:flutter/material.dart';

import '../../api/scholarship_service.dart';
import '../../component/common_widgets.dart';
import '../../model/scholarship_model.dart';
import '../../model/user_profile.dart';
import 'widgets/scholarship_card.dart';
import 'widgets/scholarship_edit_dialog.dart';
import 'widgets/scholarship_info_card.dart';

class ScholarshipPage extends StatefulWidget {
  final UserProfile profile;
  const ScholarshipPage({super.key, required this.profile});
  @override
  State<ScholarshipPage> createState() => _ScholarshipPageState();
}

class _ScholarshipPageState extends State<ScholarshipPage> {
  late double _gpa;
  late int _grade;
  late int _incomeLevel;
  bool _awardedLastSemester = false; // 직전 학기 수여 여부
  int _minAmount = 0; // 최소 장학금 금액 필터 (0 = 제한없음)
  int _personalTuition = 0; // 개인 등록금
  int _minPercentage = 0; // 장학금 비율 (0, 10, 30, 50, 100)
  List<Scholarship> _scholarships = [];
  bool _isLoading = false;
  String _filter = '매칭순';
  bool _isError = false;

  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _gpa = widget.profile.gpa ?? 3.0;
    _grade = int.tryParse(widget.profile.grade.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
    _incomeLevel = widget.profile.incomeBracket ?? 5;
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _isError = false;
      _currentPage = 1;
      _hasMore = true;
    });
    try {
      final r = await ScholarshipService.fetch(_gpa, _grade, _incomeLevel, _awardedLastSemester, page: 1, limit: 20);
      if (mounted) {
        setState(() {
          _scholarships = r;
          _hasMore = r.length == 20;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isError = true;
        });
        if (e.toString().contains('UNAUTHORIZED')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('인증이 만료되었습니다. 로그인 페이지로 이동합니다.')),
          );
          Navigator.of(context).pushReplacementNamed('/login'); // assuming /login is the route
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('장학금 데이터를 불러오는데 실패했습니다.')),
          );
        }
      }
    }
  }

  Future<void> _loadMore() async {
    setState(() {
      _isLoadingMore = true;
    });
    try {
      final nextPage = _currentPage + 1;
      final r = await ScholarshipService.fetch(_gpa, _grade, _incomeLevel, _awardedLastSemester, page: nextPage, limit: 20);
      if (mounted) {
        setState(() {
          _currentPage = nextPage;
          _scholarships.addAll(r);
          _hasMore = r.length == 20;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('장학금 데이터를 추가로 불러오는데 실패했습니다.')),
        );
      }
    }
  }

  List<Scholarship> get _filtered {
    // 최소 금액 필터 & 비율 필터 동시 적용
    final byAmount = _scholarships.where((s) {
      if (_minAmount > 0 && s.amount < _minAmount) return false;
      if (_personalTuition > 0 && _minPercentage > 0) {
        final requiredAmount = _personalTuition * (_minPercentage / 100.0);
        if (s.amount < requiredAmount) return false;
      }
      return true;
    }).toList();
    final result = List<Scholarship>.from(byAmount);
    switch (_filter) {
      case '매칭순':
        result.sort((a, b) => b.matchScore.compareTo(a.matchScore));
        break;
      case '마감순':
        result.sort((a, b) {
          final da = ScholarshipService.daysLeft(a.deadline);
          final db = ScholarshipService.daysLeft(b.deadline);
          if (da < 0) return 1;
          if (db < 0) return -1;
          return da.compareTo(db);
        });
        break;
      case '금액순':
        result.sort((a, b) => b.amount.compareTo(a.amount));
        break;
    }
    return result;
  }

  void _showInfoEdit() {
    showDialog(
      context: context,
      builder: (ctx) => ScholarshipEditDialog(
        initialGpa: _gpa,
        initialGrade: _grade,
        initialIncomeLevel: _incomeLevel,
        initialAwardedLastSemester: _awardedLastSemester,
        initialMinAmount: _minAmount,
        initialPersonalTuition: _personalTuition,
        initialMinPercentage: _minPercentage,
        onSave: (gpa, grade, income, awarded, minAmount, personalTuition, minPercentage) {
          setState(() {
            _gpa = gpa;
            _grade = grade;
            _incomeLevel = income;
            _awardedLastSemester = awarded;
            _minAmount = minAmount;
            _personalTuition = personalTuition;
            _minPercentage = minPercentage;
          });
          _load();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: buildAppBar('장학 제도 탐색', Colors.teal.shade600),
      body: Column(
        children: [
          // 내 정보 카드 + 필터 탭
          ScholarshipInfoCard(
            gpa: _gpa,
            grade: _grade,
            incomeLevel: _incomeLevel,
            minAmount: _minAmount,
            personalTuition: _personalTuition,
            minPercentage: _minPercentage,
            awardedLastSemester: _awardedLastSemester,
            filter: _filter,
            onEditTap: _showInfoEdit,
            onFilterChanged: (f) => setState(() => _filter = f),
          ),

          // 장학금 목록
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.money_off,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '현재 학생분의 정보와 일치하는 장학금이 없습니다',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _filtered.length + (_isLoadingMore ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      if (i == _filtered.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return ScholarshipCard(
                        scholarship: _filtered[i],
                        userGpa: _gpa,
                        userIncomeLevel: _incomeLevel,
                        userAwardedLastSemester: _awardedLastSemester,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
