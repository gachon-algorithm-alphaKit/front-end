// ════════════════════════════════════════════════════════════
//  pubspec.yaml dependencies:
//    image_picker: ^1.1.2
//    http: ^1.2.1
//    html: ^0.15.4
//    url_launcher: ^6.3.0
// ════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:html/parser.dart' as htmlParser;
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 안드로이드 하단 네비게이션 바 투명 처리 (edge-to-edge)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
  ));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      useMaterial3: true,
    ),
    home: const MainDashboardPage(),
  );
}

// ──────────────────────────────────────────────
// 사용자 정보 모델
// ──────────────────────────────────────────────
class UserProfile {
  String name, department, studentId, grade;
  UserProfile({this.name='홍길동', this.department='컴퓨터공학과', this.studentId='202220222', this.grade='3학년'});
  UserProfile copyWith({String? name, String? department, String? studentId, String? grade}) =>
      UserProfile(name: name??this.name, department: department??this.department, studentId: studentId??this.studentId, grade: grade??this.grade);
}

class CalendarEvent {
  final String date, title;
  CalendarEvent({required this.date, required this.title});
}

// ──────────────────────────────────────────────
// 날짜 유틸
// ──────────────────────────────────────────────
String _dayLabel(DateTime d) => ['월','화','수','목','금','토','일'][d.weekday - 1];
String _dateStr(DateTime d) => '${d.month}월 ${d.day}일 (${_dayLabel(d)})';
String _monthStr(DateTime d) => '${d.year}년 ${d.month}월';

List<String> _datePatterns(DateTime d) {
  final m = d.month.toString().padLeft(2,'0'), day = d.day.toString().padLeft(2,'0');
  return ['${d.year}.$m.$day','${d.year}-$m-$day','${d.month}월 ${d.day}일','$m.$day','$m/$day'];
}

// ──────────────────────────────────────────────
// 가천대 데이터 서비스
// ──────────────────────────────────────────────
// [HTML 구조 분석 결과]
// 페이지: 단일 <table>, 주간 식단표
// 3칸 행: td[0]=날짜("2026.05.25 ( 월 )"), td[1]=식단구분("점심 A메뉴"), td[2]=메뉴내용
// 2칸 행: td[0]=식단구분, td[1]=메뉴내용 (같은 날짜 rowspan 연속)
// 빈 메뉴: "등록된 식단내용이(가) 없습니다."
class GachonDataService {
  static const _headers = {
    'User-Agent': 'Mozilla/5.0 (Linux; Android 11; Pixel 5) '
        'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
    'Accept-Language': 'ko-KR,ko;q=0.9',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Connection': 'keep-alive',
  };

  // dart:io HttpClient 직접 사용 → SSL 레거시 서버 호환
  static Future<String> _fetchHtml(String url) async {
    final httpClient = HttpClient();
    httpClient.badCertificateCallback = (_, __, ___) => true;
    httpClient.connectionTimeout = const Duration(seconds: 15);

    final request = await httpClient.getUrl(Uri.parse(url));
    _headers.forEach((k, v) => request.headers.set(k, v));

    final response = await request.close().timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      httpClient.close();
      throw Exception('HTTP ${response.statusCode}');
    }

    final bytes = <int>[];
    await for (final chunk in response) bytes.addAll(chunk);
    httpClient.close();

    try { return utf8.decode(bytes); }
    catch (_) { return latin1.decode(bytes); }
  }

  // ── 학식 메뉴 파싱 ─────────────────────────────────────────
  // 구조: 주간 식단 테이블에서 특정 날짜의 점심 메뉴 추출
  static Future<List<String>> fetchCafeteriaMenu(String url, DateTime date) async {
    final html = await _fetchHtml(url);
    return _parseWeeklyTable(html, date);
  }

  static List<String> _parseWeeklyTable(String html, DateTime date) {
    final doc = htmlParser.parse(html);
    // 페이지에 테이블 1개 (주간 식단표)
    final table = doc.querySelector('table');
    if (table == null) return ['메뉴 테이블을 찾을 수 없습니다.'];

    final dateKey =
        '${date.year}.${date.month.toString().padLeft(2,'0')}.${date.day.toString().padLeft(2,'0')}';

    bool inTarget = false;
    final results = <String>[];

    for (final row in table.querySelectorAll('tr')) {
      final cells = row.querySelectorAll('td');
      if (cells.isEmpty) continue; // 헤더(th)만 있는 행 스킵

      String mealType;
      String menuHtml;

      if (cells.length >= 3) {
        // 날짜 시작 행: td[0]=날짜, td[1]=식단구분, td[2]=메뉴
        final rawDate = cells[0].text.trim();
        if (rawDate.contains(dateKey)) {
          inTarget = true;
        } else if (RegExp(r'\d{4}\.\d{2}\.\d{2}').hasMatch(rawDate)) {
          if (inTarget) break; // 다음 날짜로 넘어감 → 탐색 종료
          inTarget = false;
        }
        mealType = cells[1].text.trim();
        menuHtml = cells[2].innerHtml;
      } else if (cells.length == 2 && inTarget) {
        // 동일 날짜 연속 행 (rowspan): td[0]=식단구분, td[1]=메뉴
        mealType = cells[0].text.trim();
        menuHtml = cells[1].innerHtml;
      } else {
        continue;
      }

      // 점심 행만 추출 ("점심" 키워드 포함)
      if (inTarget && mealType.contains('점심')) {
        final items = _extractMenuItems(menuHtml);
        results.addAll(items);
      }
    }

    if (results.isEmpty) {
      return ['점심 식단 정보가 없거나 아직 등록되지 않았습니다.'];
    }
    return results;
  }

  // <br> 태그를 줄바꿈으로 변환 후 메뉴 항목 리스트 반환
  static List<String> _extractMenuItems(String rawHtml) {
    final text = rawHtml
        .replaceAll(RegExp(r'<br\s*/?>'), '\n')   // <br> → 줄바꿈
        .replaceAll(RegExp(r'<[^>]+>'), '')         // 나머지 태그 제거
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&');

    return text
        .split('\n')
        .map((e) => e.trim())
        .where((e) =>
    e.isNotEmpty &&
        e != '등록된 식단내용이(가) 없습니다.' &&
        !RegExp(r'^[\s\-–—]+$').hasMatch(e))
        .toList();
  }

  // ── 학사일정 파싱 ──────────────────────────────────────────
  static Future<List<CalendarEvent>> fetchCalendar(DateTime month) async {
    const url = 'https://www.gachon.ac.kr/kor/1075/subview.do';
    final html = await _fetchHtml(url);
    final doc = htmlParser.parse(html);
    final events = <CalendarEvent>[];

    for (final row in doc.querySelectorAll('tr')) {
      final cells = row.querySelectorAll('td');
      if (cells.length >= 2) {
        final dt = cells[0].text.trim(), title = cells[1].text.trim();
        if (_isTargetMonth(dt, month) && title.isNotEmpty) {
          events.add(CalendarEvent(date: _normDate(dt, month), title: title));
        }
      }
    }
    if (events.isNotEmpty) return events;

    for (final li in doc.querySelectorAll('li')) {
      final m = RegExp(r'(\d{1,2})[./-](\d{1,2})').firstMatch(li.text);
      if (m != null && (int.tryParse(m.group(1)??'')??0) == month.month) {
        final title = li.text.replaceAll(m.group(0)!,'').trim();
        if (title.isNotEmpty) events.add(CalendarEvent(
            date: '${month.month.toString().padLeft(2,'0')}.${m.group(2)}', title: title));
      }
    }
    return events;
  }

  static bool _isTargetMonth(String t, DateTime m) =>
      t.contains('${m.month}월') ||
          t.startsWith('${m.month}.') ||
          t.startsWith('${m.month.toString().padLeft(2,'0')}.');

  static String _normDate(String raw, DateTime m) {
    final match = RegExp(r'(\d{1,2})[./-](\d{1,2})').firstMatch(raw);
    if (match != null) return '${match.group(1)!.padLeft(2,'0')}.${match.group(2)!.padLeft(2,'0')}';
    final d = RegExp(r'(\d{1,2})일').firstMatch(raw);
    if (d != null) return '${m.month.toString().padLeft(2,'0')}.${d.group(1)!.padLeft(2,'0')}';
    return raw;
  }
}

Future<void> openUrl(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
}

// ══════════════════════════════════════════════
// 설정 페이지 (카톡 프로필 스타일)
// ══════════════════════════════════════════════
class ProfileSettingsPage extends StatefulWidget {
  final UserProfile profile;
  final XFile? profileImage;
  final ValueChanged<UserProfile> onProfileChanged;
  final ValueChanged<XFile?> onImageChanged;
  const ProfileSettingsPage({super.key, required this.profile, required this.profileImage, required this.onProfileChanged, required this.onImageChanged});
  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  final _picker = ImagePicker();
  late UserProfile _profile;
  XFile? _image;

  @override
  void initState() { super.initState(); _profile = widget.profile; _image = widget.profileImage; }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context);
    final p = await _picker.pickImage(source: source, imageQuality: 90);
    if (p != null) { setState(() => _image = p); widget.onImageChanged(p); }
  }

  void _showImagePicker() => showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
    builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(margin: const EdgeInsets.symmetric(vertical: 12), width: 36, height: 4,
          decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
      const Text('프로필 사진 변경', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      _PickerOption(icon: Icons.photo_library_rounded, label: '갤러리에서 선택', color: Colors.indigo,
          onTap: () => _pickImage(ImageSource.gallery)),
      _PickerOption(icon: Icons.camera_alt_rounded, label: '카메라로 촬영', color: Colors.blueAccent,
          onTap: () => _pickImage(ImageSource.camera)),
      if (_image != null)
        _PickerOption(icon: Icons.delete_outline_rounded, label: '현재 사진 삭제', color: Colors.redAccent,
            onTap: () { Navigator.pop(context); setState(() => _image = null); widget.onImageChanged(null); }),
      const SizedBox(height: 12),
    ])),
  );

  void _showEditDialog() {
    final n = TextEditingController(text: _profile.name);
    final d = TextEditingController(text: _profile.department);
    final id = TextEditingController(text: _profile.studentId);
    final g = TextEditingController(text: _profile.grade);
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Text('내 정보 수정', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        _editField('이름', n, Icons.person_outline),      const SizedBox(height: 12),
        _editField('학과', d, Icons.school_outlined),     const SizedBox(height: 12),
        _editField('학번', id, Icons.badge_outlined),     const SizedBox(height: 12),
        _editField('학년', g, Icons.bar_chart_outlined),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text('취소', style: TextStyle(color: Colors.grey.shade600))),
        FilledButton(
          onPressed: () {
            final updated = _profile.copyWith(name: n.text.trim(), department: d.text.trim(), studentId: id.text.trim(), grade: g.text.trim());
            setState(() => _profile = updated);
            widget.onProfileChanged(updated);
            Navigator.pop(ctx);
          },
          style: FilledButton.styleFrom(backgroundColor: Colors.indigo, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('저장'),
        ),
      ],
    ));
  }

  Widget _editField(String label, TextEditingController ctrl, IconData icon) => TextField(
    controller: ctrl,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: Colors.indigo),
      filled: true, fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.indigo, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      extendBody: true,
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: Stack(clipBehavior: Clip.none, children: [
          Container(height: 220, decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF3949AB), Color(0xFF1565C0)], begin: Alignment.topLeft, end: Alignment.bottomRight))),
          Positioned(top: MediaQuery.of(context).padding.top + 8, left: 8,
              child: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white), onPressed: () => Navigator.pop(context))),
          Positioned(top: MediaQuery.of(context).padding.top + 16, left: 0, right: 0,
              child: const Center(child: Text('설정', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)))),
          Positioned(bottom: -44, left: 0, right: 0,
              child: Center(child: GestureDetector(onTap: _showImagePicker, child: Stack(children: [
                Container(width: 88, height: 88,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.indigo.shade200,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0,4))],
                        image: _image != null ? DecorationImage(image: FileImage(File(_image!.path)), fit: BoxFit.cover) : null),
                    child: _image == null ? const Icon(Icons.person_rounded, size: 52, color: Colors.white) : null),
                Positioned(bottom: 0, right: 0, child: Container(width: 28, height: 28,
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle,
                        border: Border.all(color: Colors.indigo.shade100, width: 1.5),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 4)]),
                    child: Icon(Icons.camera_alt_rounded, size: 16, color: Colors.indigo.shade600))),
              ])))),
        ])),

        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.only(top: 56, bottom: 4), child: Column(children: [
          Text(_profile.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 4),
          Text('${_profile.department} · ${_profile.grade}', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        ]))),

        // 내 정보 블록
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Card(elevation: 0, color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
                child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
                  Row(children: [
                    const Text('내 정보', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const Spacer(),
                    GestureDetector(onTap: _showEditDialog,
                        child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(color: Colors.indigo.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.edit_outlined, size: 13, color: Colors.indigo.shade600),
                              const SizedBox(width: 4),
                              Text('수정', style: TextStyle(fontSize: 12, color: Colors.indigo.shade600, fontWeight: FontWeight.w600)),
                            ]))),
                  ]),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  _infoRow(Icons.person_outline,    '이름', _profile.name),
                  _infoRow(Icons.school_outlined,   '학과', _profile.department),
                  _infoRow(Icons.badge_outlined,    '학번', _profile.studentId),
                  _infoRow(Icons.bar_chart_outlined,'학년', _profile.grade, isLast: true),
                ]))))),

        // 로그아웃 / 앱 설정
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(children: [
              Expanded(child: _actionButton(Icons.settings_outlined, '앱 설정', Colors.indigo,
                      () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('앱 설정 준비 중입니다.'), duration: Duration(seconds: 1))))),
              const SizedBox(width: 12),
              Expanded(child: _actionButton(Icons.logout_rounded, '로그아웃', Colors.redAccent, () =>
                  showDialog(context: context, builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Text('로그아웃', style: TextStyle(fontWeight: FontWeight.bold)),
                    content: const Text('정말 로그아웃 하시겠습니까?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: Text('취소', style: TextStyle(color: Colors.grey.shade600))),
                      FilledButton(onPressed: () { Navigator.pop(ctx); Navigator.pop(context); },
                          style: FilledButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          child: const Text('로그아웃')),
                    ],
                  )))),
            ]))),

        SliverToBoxAdapter(child: SizedBox(height: MediaQuery.of(context).padding.bottom + 40)),
      ]),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {bool isLast = false}) =>
      Padding(padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
          child: Row(children: [
            Icon(icon, size: 18, color: Colors.grey.shade400),
            const SizedBox(width: 12),
            SizedBox(width: 44, child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade500))),
            Expanded(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87))),
          ]));

  Widget _actionButton(IconData icon, String label, Color color, VoidCallback onTap) =>
      GestureDetector(onTap: onTap,
          child: Container(padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
              child: Column(children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 6),
                Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
              ])));
}

// ══════════════════════════════════════════════
// 플레이스홀더 페이지
// ══════════════════════════════════════════════
class PlaceholderPage extends StatelessWidget {
  final String title; final IconData icon; final Color iconColor;
  const PlaceholderPage({super.key, required this.title, required this.icon, required this.iconColor});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F7FA),
    appBar: AppBar(title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
        backgroundColor: Colors.indigo, centerTitle: true, elevation: 0, iconTheme: const IconThemeData(color: Colors.white)),
    body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(padding: const EdgeInsets.all(28), decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, size: 64, color: iconColor)),
      const SizedBox(height: 24),
      Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
      const SizedBox(height: 10),
      Text('해당 기능은 준비 중입니다.', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
      const SizedBox(height: 32),
      FilledButton.icon(onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded), label: const Text('돌아가기'),
          style: FilledButton.styleFrom(backgroundColor: Colors.indigo,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
    ])),
  );
}

// ══════════════════════════════════════════════
// 메인 대시보드
// ══════════════════════════════════════════════
class MainDashboardPage extends StatefulWidget {
  const MainDashboardPage({super.key});
  @override
  State<MainDashboardPage> createState() => _MainDashboardPageState();
}

class _MainDashboardPageState extends State<MainDashboardPage> with SingleTickerProviderStateMixin {
  // 프로필 드래그
  bool _isProfileExpanded = false;
  late AnimationController _animController;
  late Animation<double> _expandAnim;

  // 사용자 정보
  UserProfile _userProfile = UserProfile();
  XFile? _profileImage;

  // 학식 — 날짜 탐색
  int _cafeteriaTab = 0;
  DateTime _cafeteriaDate = DateTime.now();
  static const _cafeterias = [
    {'name': '제1학생회관', 'url': 'https://www.gachon.ac.kr/kor/7347/subview.do'},
    {'name': '제2학생회관', 'url': 'https://www.gachon.ac.kr/kor/7349/subview.do'},
    {'name': '교직원식당',  'url': 'https://www.gachon.ac.kr/kor/7350/subview.do'},
  ];
  // [cafeteriaIndex][dateOffset] → menu
  final Map<String, List<String>?> _menuCache = {};
  final Map<String, bool> _menuErrorCache = {};

  // 학사일정 — 월 탐색
  DateTime _calendarMonth = DateTime(DateTime.now().year, DateTime.now().month);
  final Map<String, List<CalendarEvent>?> _calendarCache = {};
  final Map<String, bool> _calendarErrorCache = {};

  String get _menuKey => '${_cafeteriaTab}_${_cafeteriaDate.year}${_cafeteriaDate.month}${_cafeteriaDate.day}';
  String get _calKey   => '${_calendarMonth.year}_${_calendarMonth.month}';

  List<String>? get _currentMenu      => _menuCache[_menuKey];
  bool           get _currentMenuErr  => _menuErrorCache[_menuKey] ?? false;
  List<CalendarEvent>? get _currentCal   => _calendarCache[_calKey];
  bool                  get _currentCalErr => _calendarErrorCache[_calKey] ?? false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
    _expandAnim = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _fetchAllMenus();
    _fetchCalendar();
  }

  @override
  void dispose() { _animController.dispose(); super.dispose(); }

  Future<void> _fetchAllMenus() async {
    for (int i = 0; i < 3; i++) {
      final key = '${i}_${_cafeteriaDate.year}${_cafeteriaDate.month}${_cafeteriaDate.day}';
      if (_menuCache.containsKey(key)) continue;
      _fetchSingleMenu(i, _cafeteriaDate);
    }
  }

  Future<void> _fetchSingleMenu(int idx, DateTime date) async {
    final key = '${idx}_${date.year}${date.month}${date.day}';
    if (_menuCache.containsKey(key)) return;
    setState(() { _menuCache[key] = null; _menuErrorCache[key] = false; });
    try {
      final items = await GachonDataService.fetchCafeteriaMenu(_cafeterias[idx]['url']!, date);
      if (mounted) setState(() => _menuCache[key] = items);
    } catch (_) {
      if (mounted) setState(() { _menuCache[key] = []; _menuErrorCache[key] = true; });
    }
  }

  Future<void> _fetchCalendar() async {
    final key = _calKey;
    if (_calendarCache.containsKey(key)) return;
    setState(() { _calendarCache[key] = null; _calendarErrorCache[key] = false; });
    try {
      final events = await GachonDataService.fetchCalendar(_calendarMonth);
      if (mounted) setState(() => _calendarCache[key] = events);
    } catch (_) {
      if (mounted) setState(() { _calendarCache[key] = []; _calendarErrorCache[key] = true; });
    }
  }

  // 학식 날짜 이동
  void _shiftCafeteriaDate(int days) {
    setState(() => _cafeteriaDate = _cafeteriaDate.add(Duration(days: days)));
    _fetchAllMenus();
  }

  // 학사일정 월 이동
  void _shiftCalendarMonth(int months) {
    setState(() => _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month + months));
    _fetchCalendar();
  }

  void _toggleProfile() {
    setState(() { _isProfileExpanded = !_isProfileExpanded; _isProfileExpanded ? _animController.forward() : _animController.reverse(); });
  }
  void _handleDrag(DragUpdateDetails d) {
    if (d.delta.dy > 4 && !_isProfileExpanded) _toggleProfile();
    else if (d.delta.dy < -4 && _isProfileExpanded) _toggleProfile();
  }

  void _navigate(String title, IconData icon, Color color) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => PlaceholderPage(title: title, icon: icon, iconColor: color)));

  void _openSettings() => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileSettingsPage(
    profile: _userProfile, profileImage: _profileImage,
    onProfileChanged: (p) => setState(() => _userProfile = p),
    onImageChanged: (img) => setState(() => _profileImage = img),
  )));

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      // extendBody: true → 콘텐츠가 안드로이드 하단 네비게이션 바 뒤까지 확장
      extendBody: true,
      appBar: AppBar(
        title: const Text('스마트 e캠퍼스', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20)),
        backgroundColor: Colors.indigo, centerTitle: true, elevation: 0,
        actions: [IconButton(icon: const Icon(Icons.settings_outlined, color: Colors.white), onPressed: _openSettings)],
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── 웰컴 배너 ──────────────────────────
            GestureDetector(
              onTap: _toggleProfile,
              onVerticalDragUpdate: _handleDrag,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(color: Colors.indigo,
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24))),
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('안녕하세요, ${_userProfile.name}님! 👋',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 6),
                      const Text('성공적인 대학 생활을 위한 핵심 서비스를 이용해 보세요.',
                          style: TextStyle(fontSize: 13, color: Colors.white70)),
                    ])),
                    AnimatedRotation(turns: _isProfileExpanded ? 0.5 : 0.0, duration: const Duration(milliseconds: 320),
                        child: const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 28)),
                  ]),
                  SizeTransition(
                    sizeFactor: _expandAnim, axisAlignment: -1,
                    child: Column(children: [
                      const SizedBox(height: 18),
                      const Divider(color: Colors.white24, thickness: 1),
                      const SizedBox(height: 18),
                      Row(children: [
                        GestureDetector(onTap: _openSettings, child: Stack(children: [
                          Container(width: 78, height: 78,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.15),
                                  border: Border.all(color: Colors.white54, width: 2.5),
                                  image: _profileImage != null ? DecorationImage(image: FileImage(File(_profileImage!.path)), fit: BoxFit.cover) : null),
                              child: _profileImage == null ? const Icon(Icons.person_rounded, size: 44, color: Colors.white70) : null),
                          Positioned(bottom: 0, right: 0, child: Container(width: 26, height: 26,
                              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle,
                                  border: Border.all(color: Colors.indigo.shade100, width: 1.5),
                                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0,2))]),
                              child: Icon(Icons.settings_outlined, size: 14, color: Colors.indigo.shade600))),
                          Positioned(top: 2, right: 2, child: Container(width: 14, height: 14,
                              decoration: BoxDecoration(color: Colors.greenAccent.shade400, shape: BoxShape.circle,
                                  border: Border.all(color: Colors.indigo, width: 2)))),
                        ])),
                        const SizedBox(width: 20),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _ProfileRow(label: '이름', value: _userProfile.name),
                          const SizedBox(height: 7),
                          _ProfileRow(label: '학과', value: _userProfile.department),
                          const SizedBox(height: 7),
                          _ProfileRow(label: '학번', value: _userProfile.studentId),
                          const SizedBox(height: 7),
                          _ProfileRow(label: '학년', value: _userProfile.grade),
                        ])),
                      ]),
                      const SizedBox(height: 14),
                    ]),
                  ),
                  const SizedBox(height: 10),
                  Center(child: Container(width: 36, height: 4,
                      decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(4)))),
                  const SizedBox(height: 4),
                ]),
              ),
            ),

            // ── 캠퍼스 종합 서비스 ─────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('캠퍼스 종합 서비스',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 16),

                // 그리드 2×2 — Column+Row 로 간격 완전 통일
                Row(children: [
                  Expanded(child: _buildMenuCard(title: '캠퍼스 길찾기',    subtitle: '강의실 최단 경로',   icon: Icons.explore_rounded,      iconColor: Colors.blueAccent)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildMenuCard(title: '강의 계획서 검색', subtitle: '초성 자동완성 엔진', icon: Icons.find_in_page_rounded, iconColor: Colors.amber.shade800)),
                ]),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: _buildMenuCard(title: '스터디룸 예약',    subtitle: '공석 확인 및 대여',   icon: Icons.meeting_room_rounded,  iconColor: Colors.green.shade600)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildMenuCard(title: '분실물 통합 센터', subtitle: '유실물 실시간 조회', icon: Icons.inventory_2_rounded,   iconColor: Colors.redAccent)),
                ]),
                // 장학 카드 — 그리드와 완전히 동일한 16px 간격
                const SizedBox(height: 16),
                _buildWideMenuCard(
                  title: '장학 제도 탐색 시스템',
                  subtitle: '나에게 꼭 맞는 교내외 맞춤형 장학금 매칭',
                  icon: Icons.monetization_on_rounded, iconColor: Colors.teal.shade600,
                ),
              ]),
            ),

            // ── 오늘의 점심 ──────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _buildCafeteriaCard(),
            ),

            // ── 학사일정 ─────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPad + 28),
              child: _buildCalendarCard(),
            ),
          ],
        ),
      ),
    );
  }

  // ── 학식 카드 ─────────────────────────────────
  Widget _buildCafeteriaCard() {
    final isToday = _isSameDay(_cafeteriaDate, DateTime.now());
    final dateLabel = isToday ? '오늘 · ${_dateStr(_cafeteriaDate)}' : _dateStr(_cafeteriaDate);
    final menus = _currentMenu;
    final hasErr = _currentMenuErr;

    return Card(
      elevation: 0, color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // 헤더
        Row(children: [
          Container(padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: const Icon(Icons.restaurant_rounded, color: Colors.orange, size: 20)),
          const SizedBox(width: 10),
          const Expanded(child: Text('오늘의 점심', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87))),
          TextButton.icon(
            onPressed: () => openUrl(_cafeterias[_cafeteriaTab]['url']!),
            icon: const Icon(Icons.open_in_new, size: 13), label: const Text('전체보기', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(foregroundColor: Colors.indigo, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
          ),
        ]),

        const SizedBox(height: 10),

        // 날짜 탐색 바
        Row(children: [
          _navBtn(Icons.chevron_left, () => _shiftCafeteriaDate(-1)),
          Expanded(child: Center(child: Text(dateLabel,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: isToday ? Colors.indigo : Colors.black54)))),
          _navBtn(Icons.chevron_right, () => _shiftCafeteriaDate(1)),
        ]),

        const SizedBox(height: 10),

        // 식당 탭
        Container(
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
          child: Row(children: List.generate(3, (i) {
            final sel = _cafeteriaTab == i;
            return Expanded(child: GestureDetector(
              onTap: () {
                setState(() => _cafeteriaTab = i);
                _fetchSingleMenu(i, _cafeteriaDate);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(3), padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(color: sel ? Colors.indigo : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                alignment: Alignment.center,
                child: Text(_cafeterias[i]['name']!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                    color: sel ? Colors.white : Colors.grey.shade600)),
              ),
            ));
          })),
        ),

        const SizedBox(height: 14),
        _buildMenuContent(menus, hasErr),
      ])),
    );
  }

  Widget _buildMenuContent(List<String>? menus, bool hasErr) {
    if (menus == null) return const Padding(padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: Column(children: [
          SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.indigo)),
          SizedBox(height: 10),
          Text('식단 불러오는 중...', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ])));
    if (hasErr || menus.isEmpty) return Padding(padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(children: [
          Icon(Icons.wifi_off_rounded, color: Colors.grey.shade300, size: 34),
          const SizedBox(height: 8),
          Text('식단 정보를 불러올 수 없습니다.', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          TextButton(onPressed: () => _fetchSingleMenu(_cafeteriaTab, _cafeteriaDate),
              child: const Text('다시 시도', style: TextStyle(color: Colors.indigo))),
        ]));
    return Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: menus.take(8).map((item) => Padding(padding: const EdgeInsets.only(bottom: 7),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(margin: const EdgeInsets.only(top: 6), width: 5, height: 5,
                  decoration: BoxDecoration(color: Colors.orange.shade400, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Expanded(child: Text(item, style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4))),
            ]))).toList());
  }

  // ── 학사일정 카드 ──────────────────────────────
  Widget _buildCalendarCard() {
    final now = DateTime.now();
    final events = _currentCal;
    final hasErr = _currentCalErr;

    return Card(
      elevation: 0, color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // 헤더
        Row(children: [
          Container(padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.indigo.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.calendar_month_rounded, color: Colors.indigo, size: 20)),
          const SizedBox(width: 10),
          const Expanded(child: Text('학사일정', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87))),
          TextButton.icon(
            onPressed: () => openUrl('https://www.gachon.ac.kr/kor/1075/subview.do'),
            icon: const Icon(Icons.open_in_new, size: 13), label: const Text('전체보기', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(foregroundColor: Colors.indigo, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
          ),
        ]),

        const SizedBox(height: 10),

        // 월 탐색 바
        Row(children: [
          _navBtn(Icons.chevron_left, () => _shiftCalendarMonth(-1)),
          Expanded(child: Center(child: Text(_monthStr(_calendarMonth),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: _calendarMonth.month == now.month && _calendarMonth.year == now.year ? Colors.indigo : Colors.black54)))),
          _navBtn(Icons.chevron_right, () => _shiftCalendarMonth(1)),
        ]),

        const SizedBox(height: 10),
        const Divider(height: 1),
        const SizedBox(height: 10),

        if (events == null) const Padding(padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: Column(children: [
              SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.indigo)),
              SizedBox(height: 10),
              Text('학사일정 불러오는 중...', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ])))
        else if (hasErr || events.isEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(children: [
              Icon(hasErr ? Icons.wifi_off_rounded : Icons.event_busy_rounded, color: Colors.grey.shade300, size: 34),
              const SizedBox(height: 8),
              Text(hasErr ? '학사일정을 불러올 수 없습니다.' : '해당 월의 일정이 없습니다.', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
              if (hasErr) TextButton(onPressed: _fetchCalendar, child: const Text('다시 시도', style: TextStyle(color: Colors.indigo))),
            ]))
        else Column(children: events.take(12).map((event) {
            final parts = event.date.split('.');
            bool isToday = false, isPast = false;
            if (parts.length == 2) {
              final m = int.tryParse(parts[0])??0, d = int.tryParse(parts[1])??0;
              isToday = m == now.month && d == now.day && _calendarMonth.year == now.year;
              isPast  = _calendarMonth.year < now.year || (_calendarMonth.year == now.year &&
                  (m < now.month || (m == now.month && d < now.day)));
            }
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isToday ? Colors.indigo.withValues(alpha: 0.06) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isToday ? Colors.indigo.withValues(alpha: 0.25) : Colors.grey.shade100),
              ),
              child: Row(children: [
                Container(width: 44, padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                        color: isToday ? Colors.indigo : (isPast ? Colors.grey.shade200 : Colors.indigo.withValues(alpha: 0.08)),
                        borderRadius: BorderRadius.circular(6)),
                    alignment: Alignment.center,
                    child: Text(event.date, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                        color: isToday ? Colors.white : (isPast ? Colors.grey.shade400 : Colors.indigo)))),
                const SizedBox(width: 12),
                Expanded(child: Text(event.title, style: TextStyle(fontSize: 13,
                    fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                    color: isPast ? Colors.grey.shade400 : Colors.black87))),
                if (isToday) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.indigo, borderRadius: BorderRadius.circular(4)),
                    child: const Text('오늘', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold))),
              ]),
            );
          }).toList()),
      ])),
    );
  }

  // ── 공용 위젯 ─────────────────────────────────
  Widget _navBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Icon(icon, size: 20, color: Colors.grey.shade600),
    ),
  );

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _buildMenuCard({required String title, required String subtitle, required IconData icon, required Color iconColor}) {
    return AspectRatio(
      aspectRatio: 1.15,
      child: Card(
        elevation: 0, color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200, width: 1)),
        child: InkWell(
          onTap: () => _navigate(title, icon, iconColor), borderRadius: BorderRadius.circular(16),
          child: Padding(padding: const EdgeInsets.all(16), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: iconColor, size: 28)),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            ],
          )),
        ),
      ),
    );
  }

  Widget _buildWideMenuCard({required String title, required String subtitle, required IconData icon, required Color iconColor}) {
    return Card(
      elevation: 0, color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200, width: 1)),
      child: InkWell(
        onTap: () => _navigate(title, icon, iconColor), borderRadius: BorderRadius.circular(16),
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18), child: Row(children: [
          Container(padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 32)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ])),
          Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey.shade400, size: 16),
        ])),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// 공용 위젯
// ──────────────────────────────────────────────
class _ProfileRow extends StatelessWidget {
  final String label, value;
  const _ProfileRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 36, padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
        child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.white60), textAlign: TextAlign.center)),
    const SizedBox(width: 10),
    Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
  ]);
}

class _PickerOption extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _PickerOption({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), child: Row(children: [
      Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 22)),
      const SizedBox(width: 16),
      Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: color == Colors.redAccent ? Colors.redAccent : Colors.black87)),
    ])),
  );
}