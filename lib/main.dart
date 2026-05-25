// ════════════════════════════════════════════════════════════
//  pubspec.yaml dependencies:
//    image_picker: ^1.1.2
//    url_launcher: ^6.3.0
// ════════════════════════════════════════════════════════════

import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
  ));
  runApp(const MyApp());
}

// ══════════════════════════════════════════════════════════════
// 데이터 모델
// ══════════════════════════════════════════════════════════════

class UserProfile {
  String name, department, studentId, grade;
  UserProfile({this.name='홍길동', this.department='컴퓨터공학과', this.studentId='202220222', this.grade='3학년'});
  UserProfile copyWith({String? name, String? department, String? studentId, String? grade}) =>
      UserProfile(name: name??this.name, department: department??this.department,
          studentId: studentId??this.studentId, grade: grade??this.grade);
}

// 캠퍼스 길찾기
class Building {
  final String name, alias;
  final double lat, lng;
  const Building({required this.name, required this.alias, required this.lat, required this.lng});
}
class WaypointResult { final String from, to; final double distanceM; final List<String> path;
const WaypointResult({required this.from, required this.to, required this.distanceM, required this.path}); }
class RouteResult { final List<String> orderedStops; final double totalDistanceM; final List<WaypointResult> segments;
const RouteResult({required this.orderedStops, required this.totalDistanceM, required this.segments}); }

// 강의 검색
enum SearchType { name, professor, content }
class Course {
  final String id, name, professor, department, credit, classTime;
  final String? syllabusUrl, planSummary;
  const Course({required this.id, required this.name, required this.professor,
    required this.department, required this.credit, required this.classTime,
    this.syllabusUrl, this.planSummary});
}

// 스터디룸
class StudyRoom {
  final String id, name, location;
  final int capacity;
  final List<String> facilities;
  const StudyRoom({required this.id, required this.name, required this.location,
    required this.capacity, required this.facilities});
}
class RoomRecommendation {
  final StudyRoom room;
  final double score;
  final bool isSplitBooking;
  final List<Map<String,int>> splitSlots; // [{room:'A', start:10, end:11}]
  const RoomRecommendation({required this.room, required this.score, this.isSplitBooking=false, this.splitSlots=const []});
}

// 스터디룸 예약 내역
class StudyRoomReservation {
  final String id, roomName, location, date;
  final int startHour, endHour;
  const StudyRoomReservation({required this.id, required this.roomName,
    required this.location, required this.date,
    required this.startHour, required this.endHour});
}

// 분실물 작성 게시물
class LostFoundPost {
  final String id, itemName, description, location, contact, date;
  final bool isAnonymous;
  final String? imagePath; // 첨부 사진 경로 (없으면 null)
  const LostFoundPost({required this.id, required this.itemName,
    required this.description, required this.location,
    required this.contact, required this.date,
    this.isAnonymous = false, this.imagePath});
  LostFoundPost copyWith({String? itemName, String? description,
    String? location, String? contact, bool? isAnonymous,
    String? imagePath, bool clearImage = false}) =>
      LostFoundPost(id: id,
          itemName:    itemName    ?? this.itemName,
          description: description ?? this.description,
          location:    location    ?? this.location,
          contact:     contact     ?? this.contact,
          date:        date,
          isAnonymous: isAnonymous ?? this.isAnonymous,
          imagePath:   clearImage  ? null : (imagePath ?? this.imagePath));
}

// 분실물
class LostItem {
  final String id, itemName, description, location, foundDate, status;
  final int similarity; // 0~100
  const LostItem({required this.id, required this.itemName, required this.description,
    required this.location, required this.foundDate, required this.status, this.similarity=100});
}

// 장학금
class Scholarship {
  final String id, title, organization, amount, deadline;
  final double? requiredGpa;
  final int? requiredIncomeLevel; // 1~10 분위
  final int score; // 0~100
  final String? detail, applyUrl;
  const Scholarship({required this.id, required this.title, required this.organization,
    required this.amount, required this.deadline, this.score = 0,
    this.requiredGpa, this.requiredIncomeLevel, this.detail, this.applyUrl});
}

// ══════════════════════════════════════════════════════════════
// 서비스 클래스 (백엔드 연결 포인트)
// ══════════════════════════════════════════════════════════════

class CampusNavigationService {
  // ─────────────────────────────────────────────────────────
  // 실제 건물 목록: 백엔드 API 또는 로컬 JSON에서 로드
  // TODO: GET /api/campus/buildings → List<Building>
  // ─────────────────────────────────────────────────────────
  static const buildings = <Building>[
    Building(name:'가천관',          alias:'가천관',     lat:37.4491, lng:127.1273),
    Building(name:'비전타워',         alias:'비전',      lat:37.4499, lng:127.1281),
    Building(name:'공과대학1관',      alias:'공대1',     lat:37.4483, lng:127.1265),
    Building(name:'공과대학2관',      alias:'공대2',     lat:37.4480, lng:127.1270),
    Building(name:'AI도서관',         alias:'도서관',    lat:37.4496, lng:127.1278),
    Building(name:'제1학생생활관',    alias:'기숙사1',   lat:37.4473, lng:127.1255),
    Building(name:'제3학생생활관',    alias:'기숙사3',   lat:37.4469, lng:127.1260),
    Building(name:'교육대학원',       alias:'교육대학원', lat:37.4487, lng:127.1290),
    Building(name:'학생회관',         alias:'학생회관',  lat:37.4492, lng:127.1262),
    Building(name:'의과대학',         alias:'의대',      lat:37.4502, lng:127.1295),
    Building(name:'약학대학',         alias:'약대',      lat:37.4497, lng:127.1268),
    Building(name:'IT대학',           alias:'IT관',      lat:37.4485, lng:127.1285),
  ];

  static List<String> get buildingNames => buildings.map((b) => b.name).toList();

  // ─────────────────────────────────────────────────────────
  // 경로 탐색 (A* + 순열 최적화)
  // TODO: POST /api/campus/route
  //   Body: { departure, waypoints:[], destination }
  //   Response: RouteResult JSON
  // ─────────────────────────────────────────────────────────
  static Future<RouteResult> findRoute(
      String departure, List<String> waypoints, String destination) async {
    await Future.delayed(const Duration(milliseconds: 800)); // 네트워크 시뮬레이션

    // MOCK: 실제 A* 알고리즘 결과 대체
    final allStops = [departure, ...waypoints, destination];
    final segments = <WaypointResult>[];
    double total = 0;
    for (int i = 0; i < allStops.length - 1; i++) {
      final dist = (_mockDistance(allStops[i], allStops[i+1]) * 1000).roundToDouble();
      total += dist;
      segments.add(WaypointResult(from: allStops[i], to: allStops[i+1],
          distanceM: dist, path: [allStops[i], '경유지점 A', '경유지점 B', allStops[i+1]]));
    }
    return RouteResult(orderedStops: allStops, totalDistanceM: total, segments: segments);
  }

  static double _mockDistance(String a, String b) {
    final ba = buildings.firstWhere((x) => x.name==a, orElse: () => buildings[0]);
    final bb = buildings.firstWhere((x) => x.name==b, orElse: () => buildings[1]);
    final dlat = ba.lat - bb.lat, dlng = ba.lng - bb.lng;
    return sqrt(dlat*dlat + dlng*dlng) * 111; // 대략적 km
  }
}

class CourseService {
  // ─────────────────────────────────────────────────────────
  // TODO: GET /api/courses/autocomplete?q=&type=name|professor|content
  //   Response: List<String> (자동완성 후보)
  // ─────────────────────────────────────────────────────────
  static Future<List<String>> autocomplete(String query, SearchType type) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (query.isEmpty) return [];
    return _mockCourses
        .map((c) => type == SearchType.professor ? c.professor : c.name)
        .where((s) => s.contains(query))
        .toSet().take(5).toList();
  }

  // ─────────────────────────────────────────────────────────
  // TODO: GET /api/courses/search?q=&type=name|professor|content&choseong=true
  //   Response: List<Course>
  //   서버에서 Trie + Rabin-Karp + 초성검색 처리
  // ─────────────────────────────────────────────────────────
  static Future<List<Course>> search(String query, SearchType type, bool isChoseong) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (query.isEmpty) return [];
    return _mockCourses.where((c) {
      switch (type) {
        case SearchType.name:      return c.name.contains(query);
        case SearchType.professor: return c.professor.contains(query);
        case SearchType.content:   return (c.planSummary ?? '').contains(query);
      }
    }).take(10).toList();
  }

  static final _mockCourses = <Course>[
    const Course(id:'CS001', name:'자료구조', professor:'김민준', department:'컴퓨터공학과', credit:'3', classTime:'월수 10:00',
        planSummary:'스택, 큐, 트리, 그래프 등 핵심 자료구조의 원리와 구현을 학습합니다.'),
    const Course(id:'CS002', name:'알고리즘', professor:'이지은', department:'컴퓨터공학과', credit:'3', classTime:'화목 13:00',
        planSummary:'정렬, 탐색, 동적 프로그래밍, 그리디 알고리즘을 다룹니다.'),
    const Course(id:'CS003', name:'운영체제', professor:'박현우', department:'컴퓨터공학과', credit:'3', classTime:'월수금 09:00',
        planSummary:'프로세스, 메모리 관리, 파일 시스템, 동기화를 학습합니다.'),
    const Course(id:'CS004', name:'컴퓨터네트워크', professor:'최서연', department:'컴퓨터공학과', credit:'3', classTime:'화목 10:30',
        planSummary:'TCP/IP, OSI 7계층, 라우팅 프로토콜을 학습합니다.'),
    const Course(id:'CS005', name:'데이터베이스', professor:'김민준', department:'컴퓨터공학과', credit:'3', classTime:'수금 14:00',
        planSummary:'관계형 데이터베이스, SQL, 정규화를 학습합니다.'),
    const Course(id:'CS006', name:'소프트웨어공학', professor:'이지은', department:'소프트웨어학과', credit:'3', classTime:'월수 14:00',
        planSummary:'애자일, UML, 소프트웨어 설계 원칙을 학습합니다.'),
    const Course(id:'CS007', name:'인공지능', professor:'박현우', department:'컴퓨터공학과', credit:'3', classTime:'화목 15:00',
        planSummary:'머신러닝, 딥러닝 기초, 신경망 구조를 다룹니다.'),
    const Course(id:'CS008', name:'컴파일러', professor:'정다은', department:'컴퓨터공학과', credit:'3', classTime:'금 10:00',
        planSummary:'렉서, 파서, 코드 생성 등 컴파일러 구현 원리를 학습합니다.'),
  ];

  // 외부 접근용 getter (찜목록 페이지에서 사용)
  static List<Course> get allCourses => _mockCourses;
}

class StudyRoomService {
  // ─────────────────────────────────────────────────────────
  // TODO: GET /api/studyrooms
  //   Response: List<StudyRoom>
  // ─────────────────────────────────────────────────────────
  static Future<List<StudyRoom>> fetchRooms() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockRooms;
  }

  // ─────────────────────────────────────────────────────────
  // TODO: POST /api/studyrooms/recommend
  //   Body: { date, startHour, endHour, capacity, facilities[] }
  //   Response: { recommendations: List<RoomRecommendation>, isSplit: bool }
  //   서버: Bitset 충돌검사 → PriorityQueue 점수화 → Backtracking 분할
  // ─────────────────────────────────────────────────────────
  static Future<List<RoomRecommendation>> recommend(
      DateTime date, int startHour, int endHour, int capacity, List<String> facilities) async {
    await Future.delayed(const Duration(milliseconds: 600));
    // MOCK: 적합도 점수 계산 (실제: Bitset + PriorityQueue)
    final results = <RoomRecommendation>[];
    for (final room in _mockRooms) {
      double score = 100;
      score -= (room.capacity - capacity).abs() * 5.0; // 인원 패널티
      for (final f in facilities) {
        if (room.facilities.contains(f)) score += 10; // 시설 가산점
      }
      if (score > 0) results.add(RoomRecommendation(room: room, score: score.clamp(0,100)));
    }
    results.sort((a,b) => b.score.compareTo(a.score));
    return results.take(3).toList();
  }

  // ─────────────────────────────────────────────────────────
  // TODO: POST /api/studyrooms/reserve
  //   Body: { roomId, date, startHour, endHour, userId }
  //   Response: { success, reservationId }
  //   서버: Bitset OR 연산으로 예약 확정
  // ─────────────────────────────────────────────────────────
  static Future<bool> reserve(String roomId, DateTime date, int startHour, int endHour) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return true; // MOCK
  }

  static final _mockRooms = <StudyRoom>[
    const StudyRoom(id:'R01', name:'스터디룸 A', location:'비전타워 3층', capacity:6, facilities:['TV','화이트보드','HDMI']),
    const StudyRoom(id:'R02', name:'스터디룸 B', location:'비전타워 3층', capacity:4, facilities:['화이트보드']),
    const StudyRoom(id:'R03', name:'스터디룸 C', location:'AI도서관 2층', capacity:10, facilities:['TV','빔프로젝터','화이트보드']),
    const StudyRoom(id:'R04', name:'스터디룸 D', location:'AI도서관 2층', capacity:4, facilities:['화이트보드','HDMI']),
    const StudyRoom(id:'R05', name:'스터디룸 E', location:'가천관 5층',   capacity:8, facilities:['TV','화이트보드']),
  ];
}

class LostFoundService {
  // ─────────────────────────────────────────────────────────
  // TODO: GET /api/lostfound/search?q=&mode=kmp|levenshtein
  //   Response: List<LostItem>
  //   서버: KMP(정확검색) 또는 Levenshtein(유사검색) 처리
  // ─────────────────────────────────────────────────────────
  static Future<List<LostItem>> search(String query, bool isFuzzy) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (query.isEmpty) return _mockItems;
    // MOCK: 실제 KMP / Levenshtein은 서버에서 처리
    return _mockItems.where((i) {
      final target = '${i.itemName} ${i.description}';
      return isFuzzy ? _levenshtein(query, i.itemName) <= 5 : target.contains(query);
    }).toList()..sort((a,b) => b.similarity.compareTo(a.similarity));
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
    final dp = List.generate(m+1, (i) => List.filled(n+1, 0));
    for (int i=0;i<=m;i++) dp[i][0]=i;
    for (int j=0;j<=n;j++) dp[0][j]=j;
    for (int i=1;i<=m;i++) for (int j=1;j<=n;j++) {
      dp[i][j] = s[i-1]==t[j-1] ? dp[i-1][j-1]
          : 1 + [dp[i-1][j], dp[i][j-1], dp[i-1][j-1]].reduce(min);
    }
    return dp[m][n];
  }

  static final _mockItems = <LostItem>[
    const LostItem(id:'L001', itemName:'에어팟 프로', description:'흰색 케이스, 이름 스티커 있음', location:'비전타워 3층', foundDate:'2026.05.24', status:'보관중', similarity:100),
    const LostItem(id:'L002', itemName:'지갑', description:'검정 가죽 반지갑, 카드 여러 장', location:'학생회관 1층', foundDate:'2026.05.23', status:'보관중', similarity:90),
    const LostItem(id:'L003', itemName:'텀블러', description:'스탠리 초록색 500ml', location:'AI도서관 열람실', foundDate:'2026.05.22', status:'보관중', similarity:85),
    const LostItem(id:'L004', itemName:'우산', description:'자동 접이식 남색 우산', location:'가천관 1층', foundDate:'2026.05.21', status:'보관중', similarity:80),
    const LostItem(id:'L005', itemName:'아이패드', description:'iPad Pro 11인치, 케이스 있음', location:'AI도서관 2층', foundDate:'2026.05.20', status:'주인 찾음', similarity:95),
    const LostItem(id:'L006', itemName:'학생증', description:'가천대학교 학생증', location:'교육대학원 지하', foundDate:'2026.05.19', status:'보관중', similarity:88),
  ];
}

class ScholarshipService {
  // ─────────────────────────────────────────────────────────
  // TODO: GET /api/scholarships?gpa=&grade=&income=
  //   Response: List<Scholarship> (점수순 정렬)
  //   서버: 크롤링 DB에서 조건 매칭 + 점수 계산
  // ─────────────────────────────────────────────────────────
  static Future<List<Scholarship>> fetch(double gpa, int grade, int incomeLevel) async {
    await Future.delayed(const Duration(milliseconds: 600));
    // MOCK: 적합도 점수 계산 (실제: DB 쿼리 + 서버 스코어링)
    return _mockScholarships.map((s) {
      int score = 40;
      if (s.requiredGpa == null || gpa >= s.requiredGpa!) score += 30;
      if (s.requiredIncomeLevel == null || incomeLevel <= s.requiredIncomeLevel!) score += 20;
      if (gpa >= 3.5) score += 10;
      return Scholarship(id:s.id, title:s.title, organization:s.organization, amount:s.amount,
          deadline:s.deadline, requiredGpa:s.requiredGpa, requiredIncomeLevel:s.requiredIncomeLevel,
          detail:s.detail, applyUrl:s.applyUrl, score:score.clamp(0,100));
    }).toList()..sort((a,b) => b.score.compareTo(a.score));
  }

  // ─────────────────────────────────────────────────────────
  // TODO: POST /api/scholarships/apply
  //   Body: { scholarshipId, userId }
  //   서버: 외부 신청 URL 반환 또는 내부 신청 처리
  // ─────────────────────────────────────────────────────────
  static Future<String?> getApplyUrl(String scholarshipId) async {
    final s = _mockScholarships.firstWhere((x) => x.id == scholarshipId, orElse: () => _mockScholarships[0]);
    return s.applyUrl;
  }

  static int daysLeft(String deadline) {
    try {
      final parts = deadline.split('.');
      final d = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      return d.difference(DateTime.now()).inDays;
    } catch (_) { return 0; }
  }

  static final _mockScholarships = <Scholarship>[
    const Scholarship(id:'S001', title:'교내 성적우수 장학금', organization:'가천대학교', amount:'수업료 전액',
        deadline:'2026.06.15', requiredGpa:3.5, requiredIncomeLevel:null,
        detail:'직전 학기 성적 3.5 이상인 학생 대상. 학과별 선발 인원 상이.', applyUrl:'https://www.gachon.ac.kr'),
    const Scholarship(id:'S002', title:'국가장학금 I유형', organization:'한국장학재단', amount:'최대 520만원/학기',
        deadline:'2026.06.30', requiredGpa:null, requiredIncomeLevel:8,
        detail:'소득분위 8분위 이하 학생 대상. 성적 유지 기준 C학점 이상.', applyUrl:'https://www.kosaf.go.kr'),
    const Scholarship(id:'S003', title:'근로장학금', organization:'한국장학재단', amount:'시급 11,000원',
        deadline:'2026.06.20', requiredGpa:null, requiredIncomeLevel:9,
        detail:'교내 근로 장학금. 주당 최대 20시간 근무 가능.', applyUrl:'https://www.kosaf.go.kr'),
    const Scholarship(id:'S004', title:'[장학공지] SW인재 장학금', organization:'가천대 SW중심대학', amount:'100만원/학기',
        deadline:'2026.06.10', requiredGpa:3.0, requiredIncomeLevel:null,
        detail:'SW 관련 학과 재학생 중 성적 3.0 이상. 포트폴리오 제출 필요.', applyUrl:'https://www.gachon.ac.kr'),
    const Scholarship(id:'S005', title:'가천나눔 장학금', organization:'가천대학교', amount:'수업료 50%',
        deadline:'2026.07.01', requiredGpa:null, requiredIncomeLevel:4,
        detail:'소득분위 4분위 이하 가정 형편이 어려운 학생 우선 선발.', applyUrl:'https://www.gachon.ac.kr'),
    const Scholarship(id:'S006', title:'글로벌 리더 장학금', organization:'가천대학교', amount:'200만원/학기',
        deadline:'2026.05.31', requiredGpa:3.8, requiredIncomeLevel:null,
        detail:'어학 성적 우수자 및 해외 교환학생 파견 예정자 대상.', applyUrl:'https://www.gachon.ac.kr'),
  ];
}

// ══════════════════════════════════════════════════════════════
// 전역 데이터 저장소 (MOCK: 실제 앱에서는 DB 또는 상태관리로 교체)
// ══════════════════════════════════════════════════════════════
final List<StudyRoomReservation> _myReservations = [];
final List<LostFoundPost> _myPosts = [];
final Set<String> _wishlistCourseIds = {}; // 찜한 강의 ID Set

// ══════════════════════════════════════════════════════════════
// APP
// ══════════════════════════════════════════════════════════════
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo), useMaterial3: true),
    home: const MainDashboardPage(),
  );
}

// ══════════════════════════════════════════════════════════════
// 메인 대시보드
// ══════════════════════════════════════════════════════════════
class MainDashboardPage extends StatefulWidget {
  const MainDashboardPage({super.key});
  @override
  State<MainDashboardPage> createState() => _MainDashboardPageState();
}

class _MainDashboardPageState extends State<MainDashboardPage> {
  UserProfile _profile = UserProfile();
  XFile? _profileImage;

  @override
  void initState() { super.initState(); }
  @override
  void dispose() { super.dispose(); }

  void _goTo(Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  void _openSettings() => _goTo(ProfileSettingsPage(profile: _profile, profileImage: _profileImage,
      onProfileChanged: (p) => setState(() => _profile = p),
      onImageChanged: (img) => setState(() => _profileImage = img)));

  static const _cards = [
    {'title':'캠퍼스 길찾기',    'sub':'A* 알고리즘 최적 경로',   'icon':Icons.explore_rounded,      'color':Colors.blueAccent},
    {'title':'강의 계획서 검색', 'sub':'초성·Trie 자동완성 검색', 'icon':Icons.find_in_page_rounded, 'color':null},
    {'title':'스터디룸 예약',    'sub':'실시간 공석·최적 매칭',   'icon':Icons.meeting_room_rounded,  'color':null},
    {'title':'분실물 통합 센터', 'sub':'KMP + 유사도 검색',      'icon':Icons.inventory_2_rounded,   'color':Colors.redAccent},
    {'title':'장학 제도 탐색',   'sub':'맞춤형 장학금 매칭',      'icon':Icons.monetization_on_rounded,'color':null},
  ];

  Color _cardColor(int i) {
    final colors = [Colors.blueAccent, Colors.amber.shade800, Colors.green.shade600, Colors.redAccent, Colors.teal.shade600];
    return colors[i];
  }

  Widget _getPage(int i) {
    switch(i) {
      case 0: return const CampusNavigationPage();
      case 1: return const CourseSearchPage();
      case 2: return const StudyRoomPage();
      case 3: return const LostFoundPage();
      case 4: return const ScholarshipPage();
      default: return const CampusNavigationPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      extendBody: true,
      appBar: AppBar(
        title: const Text('AlphaKit', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20)),
        backgroundColor: Colors.indigo, centerTitle: true, elevation: 0,
        actions: [IconButton(icon: const Icon(Icons.settings_outlined, color: Colors.white), onPressed: _openSettings)],
      ),
      body: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // 웰컴 배너 (정적)
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(color: Colors.indigo,
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24))),
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 28),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('안녕하세요, ${_profile.name}님! 👋',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 6),
              const Text('성공적인 대학 생활을 위한 핵심 서비스를 이용해 보세요.',
                  style: TextStyle(fontSize: 13, color: Colors.white70)),
            ]),
          ),

          // 서비스 카드
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('캠퍼스 종합 서비스', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _serviceCard(0)),
                const SizedBox(width: 16),
                Expanded(child: _serviceCard(1)),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _serviceCard(2)),
                const SizedBox(width: 16),
                Expanded(child: _serviceCard(3)),
              ]),
              const SizedBox(height: 16),
              _wideCard(4),
            ]),
          ),
          SizedBox(height: bottom + 28),
        ]),
      ),
    );
  }

  Widget _serviceCard(int i) {
    final color = _cardColor(i);
    final card = _cards[i];
    return AspectRatio(aspectRatio: 1.15, child: Card(
      elevation: 0, color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      child: InkWell(
        onTap: () => _goTo(_getPage(i)), borderRadius: BorderRadius.circular(16),
        child: Padding(padding: const EdgeInsets.all(16), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha:0.1), shape: BoxShape.circle), child: Icon(card['icon'] as IconData, color: color, size: 28)),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(card['title'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 2),
              Text(card['sub'] as String, style: TextStyle(fontSize: 10, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ],
        )),
      ),
    ));
  }

  Widget _wideCard(int i) {
    final color = _cardColor(i); final card = _cards[i];
    return Card(
      elevation: 0, color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      child: InkWell(
        onTap: () => _goTo(_getPage(i)), borderRadius: BorderRadius.circular(16),
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18), child: Row(children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha:0.1), borderRadius: BorderRadius.circular(12)), child: Icon(card['icon'] as IconData, color: color, size: 32)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(card['title'] as String, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 4),
            Text(card['sub'] as String, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ])),
          Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey.shade400, size: 16),
        ])),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// 1. 캠퍼스 길찾기 페이지
// ══════════════════════════════════════════════════════════════
class CampusNavigationPage extends StatefulWidget {
  const CampusNavigationPage({super.key});
  @override
  State<CampusNavigationPage> createState() => _CampusNavigationPageState();
}

class _CampusNavigationPageState extends State<CampusNavigationPage> {
  final _departCtrl = TextEditingController();
  final _destCtrl   = TextEditingController();
  final _waypointCtrls = <TextEditingController>[];
  RouteResult? _result;
  bool _isLoading = false;
  String? _error;

  final _buildings = CampusNavigationService.buildingNames;

  @override
  void dispose() {
    _departCtrl.dispose(); _destCtrl.dispose();
    for (final c in _waypointCtrls) c.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_departCtrl.text.isEmpty || _destCtrl.text.isEmpty) {
      setState(() => _error = '출발지와 도착지를 입력해주세요.');
      return;
    }
    setState(() { _isLoading = true; _error = null; _result = null; });
    try {
      // TODO: CampusNavigationService.findRoute 호출 → 백엔드 연결
      final r = await CampusNavigationService.findRoute(
          _departCtrl.text, _waypointCtrls.map((c) => c.text).where((s) => s.isNotEmpty).toList(), _destCtrl.text);
      setState(() => _result = r);
    } catch (e) {
      setState(() => _error = '경로를 찾을 수 없습니다. 다시 시도해주세요.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _appBar('캠퍼스 길찾기', Colors.blueAccent),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // 입력 카드
          _card(child: Column(children: [
            _buildingField(_departCtrl, '출발지', Icons.radio_button_checked, Colors.green),
            ..._waypointCtrls.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(children: [
                Expanded(child: _buildingField(e.value, '경유지 ${e.key+1}', Icons.add_location_alt, Colors.orange)),
                IconButton(icon: Icon(Icons.close, color: Colors.grey.shade400), onPressed: () => setState(() { _waypointCtrls[e.key].dispose(); _waypointCtrls.removeAt(e.key); })),
              ]),
            )),
            const SizedBox(height: 10),
            _buildingField(_destCtrl, '도착지', Icons.location_on, Colors.red),
            const SizedBox(height: 10),
            Row(children: [
              OutlinedButton.icon(
                onPressed: _waypointCtrls.length < 3 ? () => setState(() => _waypointCtrls.add(TextEditingController())) : null,
                icon: const Icon(Icons.add, size: 16), label: const Text('경유지 추가', style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.blueAccent, side: const BorderSide(color: Colors.blueAccent)),
              ),
              const SizedBox(width: 10),
              Expanded(child: FilledButton.icon(
                onPressed: _isLoading ? null : _search,
                icon: _isLoading ? const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)) : const Icon(Icons.route, size:18),
                label: Text(_isLoading ? '계산 중...' : '최적 경로 탐색'),
                style: FilledButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              )),
            ]),
          ])),

          if (_error != null) _errorBanner(_error!),

          // 결과
          if (_result != null) ...[
            const SizedBox(height: 16),
            _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                const Text('최적 경로', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const Spacer(),
                Container(padding: const EdgeInsets.symmetric(horizontal:10,vertical:4),
                    decoration: BoxDecoration(color: Colors.blueAccent.withValues(alpha:0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text('총 ${(_result!.totalDistanceM).round()}m', style: const TextStyle(fontSize: 13, color: Colors.blueAccent, fontWeight: FontWeight.bold))),
              ]),
              const SizedBox(height: 14),
              ..._result!.segments.asMap().entries.map((e) => _segmentTile(e.key, e.value)),
            ])),
            const SizedBox(height: 16),
            // 지도 영역 (네이버 지도 API 연결 자리)
            Container(height: 220,
              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300)),
              child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.map_outlined, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text('지도 영역', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                const SizedBox(height: 4),
                // TODO: flutter_naver_map 패키지 연결 후 NaverMap 위젯으로 교체
                Text('TODO: 네이버 지도 API 연결', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
              ])),
            ),
          ],
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _buildingField(TextEditingController ctrl, String hint, IconData icon, Color color) {
    return Autocomplete<String>(
      optionsBuilder: (v) => v.text.isEmpty ? const [] : _buildings.where((b) => b.contains(v.text)),
      onSelected: (s) => ctrl.text = s,
      fieldViewBuilder: (ctx, ctrl2, fn, onSubmit) {
        ctrl.addListener(() { if (ctrl2.text != ctrl.text) ctrl2.text = ctrl.text; });
        return TextField(controller: ctrl2, focusNode: fn,
            decoration: InputDecoration(labelText: hint, prefixIcon: Icon(icon, color: color, size: 20),
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: color, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(horizontal:14,vertical:12)));
      },
    );
  }

  Widget _segmentTile(int idx, WaypointResult seg) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(children: [
        Container(width:24,height:24, decoration: BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
            alignment: Alignment.center, child: Text('${idx+1}', style: const TextStyle(color:Colors.white,fontSize:11,fontWeight:FontWeight.bold))),
        if (idx < _result!.segments.length - 1) Container(width:2, height:32, color: Colors.blueAccent.withValues(alpha:0.3)),
      ]),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${seg.from} → ${seg.to}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        Text('${seg.distanceM.round()}m | ${seg.path.join(' → ')}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ])),
    ]),
  );
}

// ══════════════════════════════════════════════════════════════
// 2. 강의 계획서 검색 페이지
// ══════════════════════════════════════════════════════════════
class CourseSearchPage extends StatefulWidget {
  const CourseSearchPage({super.key});
  @override
  State<CourseSearchPage> createState() => _CourseSearchPageState();
}

class _CourseSearchPageState extends State<CourseSearchPage> {
  SearchType _type = SearchType.name;
  bool _isChoseong = false;
  final _ctrl = TextEditingController();
  List<Course> _results = [];
  bool _isLoading = false, _searched = false;

  Future<void> _search() async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() { _isLoading = true; _searched = true; });
    try {
      // TODO: CourseService.search → 백엔드 Trie + Rabin-Karp + 초성 검색
      final r = await CourseService.search(_ctrl.text.trim(), _type, _isChoseong);
      setState(() => _results = r);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('강의 계획서 검색',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
        backgroundColor: Colors.amber.shade800, centerTitle: true, elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Stack(alignment: Alignment.center, children: [
            IconButton(
              icon: const Icon(Icons.favorite_rounded, color: Colors.white),
              tooltip: '찜 목록',
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(
                  builder: (_) => CourseWishlistPage(
                    wishlistIds: _wishlistCourseIds,
                    onToggle: (id) => setState(() {
                      if (_wishlistCourseIds.contains(id)) _wishlistCourseIds.remove(id);
                      else _wishlistCourseIds.add(id);
                    }),
                  ),
                ));
                setState(() {});
              },
            ),
            if (_wishlistCourseIds.isNotEmpty)
              Positioned(
                top: 8, right: 8,
                child: Container(
                  width: 16, height: 16,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text('\${_wishlistCourseIds.length}',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold,
                          color: Colors.amber.shade800)),
                ),
              ),
          ]),
        ],
      ),
      body: Column(children: [
        // 검색 영역
        Container(color: Colors.white, padding: const EdgeInsets.fromLTRB(16,12,16,16),
          child: Column(children: [
            // 검색 타입 탭
            SegmentedButton<SearchType>(
              segments: const [
                ButtonSegment(value: SearchType.name,      label: Text('강의명'),  icon: Icon(Icons.book_outlined, size:16)),
                ButtonSegment(value: SearchType.professor, label: Text('교수명'),  icon: Icon(Icons.person_outline, size:16)),
                ButtonSegment(value: SearchType.content,   label: Text('강의내용'), icon: Icon(Icons.description_outlined, size:16)),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() { _type = s.first; _results = []; _searched = false; }),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.amber.shade800 : null),
                foregroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : null),
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextField(controller: _ctrl,
                decoration: InputDecoration(
                  hintText: _type == SearchType.name ? '강의명 또는 초성 입력 (예: ㅈㄹㄱㅈ)' :
                  _type == SearchType.professor ? '교수명 입력' : '강의 내용 키워드 입력',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true, fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.amber.shade800, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal:14,vertical:12),
                  suffixIcon: _ctrl.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _ctrl.clear(); setState(() { _results=[]; _searched=false; }); }) : null,
                ),
                onSubmitted: (_) => _search(),
                onChanged: (_) => setState(() {}),
              )),
              const SizedBox(width: 8),
              FilledButton(onPressed: _search,
                  style: FilledButton.styleFrom(backgroundColor: Colors.amber.shade800, minimumSize: const Size(52,52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Icon(Icons.search)),
            ]),         // Row 닫기
          ]),           // Column 닫기
        ),              // Container 닫기

        // 결과
        Expanded(child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : !_searched ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.school_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('강의명, 교수명, 또는 강의내용을 검색하세요', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
        ]))
            : _results.isEmpty ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('검색 결과가 없습니다', style: TextStyle(color: Colors.grey.shade500)),
        ]))
            : ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _results.length,
          separatorBuilder: (_,__) => const SizedBox(height: 10),
          itemBuilder: (_,i) => _courseCard(_results[i]),
        )),
      ]),
    );
  }

  Widget _courseCard(Course c) {
    final isWished = _wishlistCourseIds.contains(c.id);
    return Card(elevation:0, color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.grey.shade200)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal:16,vertical:4),
        childrenPadding: const EdgeInsets.fromLTRB(16,0,16,16),
        leading: Container(width:40,height:40, decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(10)),
            alignment: Alignment.center, child: Text(c.credit, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade800, fontSize: 13))),
        title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text('\${c.professor} | \${c.department} | \${c.classTime}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        trailing: GestureDetector(
          onTap: () => setState(() {
            if (isWished) _wishlistCourseIds.remove(c.id);
            else _wishlistCourseIds.add(c.id);
          }),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              isWished ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              key: ValueKey(isWished),
              color: isWished ? Colors.redAccent : Colors.grey.shade400,
              size: 22,
            ),
          ),
        ),
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),
          if (c.planSummary != null) ...[
            Text('강의 계획 요약', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey.shade700)),
            const SizedBox(height: 6),
            Text(c.planSummary!, style: const TextStyle(fontSize: 13, height: 1.5)),
          ],
          // TODO: c.syllabusUrl → 강의계획서 PDF 열기
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// 2-B. 강의 계획서 찜 목록 페이지
// ══════════════════════════════════════════════════════════════
class CourseWishlistPage extends StatefulWidget {
  final Set<String> wishlistIds;
  final ValueChanged<String> onToggle;
  const CourseWishlistPage({super.key, required this.wishlistIds, required this.onToggle});
  @override
  State<CourseWishlistPage> createState() => _CourseWishlistPageState();
}

class _CourseWishlistPageState extends State<CourseWishlistPage> {
  // 모든 강의 목록에서 찜한 것만 필터
  List<Course> get _wished => CourseService.allCourses
      .where((c) => widget.wishlistIds.contains(c.id))
      .toList();

  void _toggle(String id) {
    widget.onToggle(id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final wished = _wished;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('찜한 강의 (\${wished.length})',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
        backgroundColor: Colors.amber.shade800, centerTitle: true, elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: wished.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.favorite_border_rounded, size: 72, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text('찜한 강의가 없습니다', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
        const SizedBox(height: 6),
        Text('강의 검색 후 ♥ 버튼을 눌러 찜하세요', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
      ]))
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: wished.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final c = wished[i];
          return Card(
            elevation: 0, color: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.amber.shade200, width: 1.2)),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: Text(c.credit,
                    style: TextStyle(fontWeight: FontWeight.bold,
                        color: Colors.amber.shade800, fontSize: 13)),
              ),
              title: Text(c.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text(
                  '\${c.professor} | \${c.department} | \${c.classTime}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              trailing: GestureDetector(
                onTap: () => _toggle(c.id),
                child: const Icon(Icons.favorite_rounded,
                    color: Colors.redAccent, size: 22),
              ),
              children: [
                const Divider(height: 1),
                const SizedBox(height: 12),
                if (c.planSummary != null) ...[
                  Text('강의 계획 요약',
                      style: TextStyle(fontWeight: FontWeight.w600,
                          fontSize: 12, color: Colors.grey.shade700)),
                  const SizedBox(height: 6),
                  Text(c.planSummary!,
                      style: const TextStyle(fontSize: 13, height: 1.5)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// 3. 스터디룸 예약 페이지
// ══════════════════════════════════════════════════════════════
class StudyRoomPage extends StatefulWidget {
  const StudyRoomPage({super.key});
  @override
  State<StudyRoomPage> createState() => _StudyRoomPageState();
}

class _StudyRoomPageState extends State<StudyRoomPage> {
  DateTime _date = DateTime.now();
  int _startHour = 10, _endHour = 12, _capacity = 4;
  final _allFacilities = ['TV', '화이트보드', '빔프로젝터', 'HDMI'];
  final _selectedFacilities = <String>[];
  List<RoomRecommendation> _results = [];
  bool _isLoading = false, _searched = false;
  String? _reservedRoom;

  Future<void> _search() async {
    if (_startHour >= _endHour) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('종료 시간은 시작 시간보다 이후여야 합니다.')));
      return;
    }
    if (_endHour - _startHour > 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('최대 이용 시간은 4시간입니다.')));
      return;
    }
    setState(() { _isLoading = true; _searched = true; _results = []; });
    try {
      // TODO: StudyRoomService.recommend → Bitset + PriorityQueue + Backtracking 처리
      final r = await StudyRoomService.recommend(_date, _startHour, _endHour, _capacity, _selectedFacilities);
      setState(() => _results = r);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _reserve(RoomRecommendation rec) async {
    // TODO: StudyRoomService.reserve → Bitset OR 예약 확정
    final ok = await StudyRoomService.reserve(rec.room.id, _date, _startHour, _endHour);
    if (ok && mounted) {
      setState(() => _reservedRoom = rec.room.name);
      // 예약 내역 저장
      _myReservations.add(StudyRoomReservation(
        id: 'R${DateTime.now().millisecondsSinceEpoch}',
        roomName: rec.room.name,
        location: rec.room.location,
        date: "${_date.year}.${_date.month.toString().padLeft(2,"0")}.${_date.day.toString().padLeft(2,"0")}",
        startHour: _startHour,
        endHour: _endHour,
      ));
      showDialog(context: context, builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [Icon(Icons.check_circle, color: Colors.green), SizedBox(width:8), Text('예약 완료', style: TextStyle(fontWeight: FontWeight.bold))]),
        content: Text('${rec.room.name} 예약이 완료되었습니다.\n$_startHour:00 ~ $_endHour:00'),
        actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('확인'))],
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('스터디룸 예약', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
        backgroundColor: Colors.green.shade600, centerTitle: true, elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: Colors.white),
            tooltip: '예약 내역',
            onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => StudyRoomReservationHistoryPage(reservations: _myReservations))),
          ),
        ],
      ),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
        // 조건 설정 카드
        _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // 날짜
          _sectionLabel('날짜'),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 30)));
              if (picked != null) setState(() => _date = picked);
            },
            child: Container(padding: const EdgeInsets.symmetric(horizontal:14,vertical:12),
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                child: Row(children: [
                  Icon(Icons.calendar_today_outlined, color: Colors.green.shade600, size: 18),
                  const SizedBox(width: 10),
                  Text("${_date.year}.${_date.month.toString().padLeft(2,"0")}.${_date.day.toString().padLeft(2,"0")}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 18),
                ])),
          ),
          const SizedBox(height: 14),

          // 시간
          _sectionLabel('이용 시간'),
          Row(children: [
            _hourSelector('시작', _startHour, (v) => setState(() => _startHour = v), 8, 20),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('~', style: TextStyle(fontSize: 18, color: Colors.grey.shade600))),
            _hourSelector('종료', _endHour, (v) => setState(() => _endHour = v), 9, 22),
            const Spacer(),
            Container(padding: const EdgeInsets.symmetric(horizontal:10,vertical:5),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                child: Text('${_endHour-_startHour}시간', style: TextStyle(fontSize: 13, color: Colors.green.shade700, fontWeight: FontWeight.bold))),
          ]),
          const SizedBox(height: 14),

          // 인원
          _sectionLabel('인원'),
          Row(children: [
            IconButton(onPressed: _capacity>1 ? () => setState(()=>_capacity--) : null,
                icon: const Icon(Icons.remove_circle_outline), color: Colors.green.shade600),
            Text('$_capacity명', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            IconButton(onPressed: _capacity<20 ? () => setState(()=>_capacity++) : null,
                icon: const Icon(Icons.add_circle_outline), color: Colors.green.shade600),
          ]),
          const SizedBox(height: 14),

          // 시설 선택
          _sectionLabel('희망 시설 (선택)'),
          Wrap(spacing: 8, children: _allFacilities.map((f) {
            final selected = _selectedFacilities.contains(f);
            return FilterChip(
              label: Text(f), selected: selected,
              onSelected: (v) => setState(() => v ? _selectedFacilities.add(f) : _selectedFacilities.remove(f)),
              selectedColor: Colors.green.shade100,
              checkmarkColor: Colors.green.shade700,
              labelStyle: TextStyle(color: selected ? Colors.green.shade700 : Colors.grey.shade700, fontSize: 13),
            );
          }).toList()),
          const SizedBox(height: 16),

          // 검색
          SizedBox(width: double.infinity, child: FilledButton.icon(
            onPressed: _isLoading ? null : _search,
            icon: _isLoading ? const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)) : const Icon(Icons.search),
            label: Text(_isLoading ? '검색 중...' : '공실 검색 (Bitset 처리)'),
            style: FilledButton.styleFrom(backgroundColor: Colors.green.shade600, minimumSize: const Size(double.infinity,48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          )),
        ])),

        // 결과
        if (_searched && !_isLoading) ...[
          const SizedBox(height: 16),
          if (_results.isEmpty) _card(child: Center(child: Padding(padding: const EdgeInsets.all(24),
              child: Column(children: [Icon(Icons.event_busy, size:48, color:Colors.grey.shade300), const SizedBox(height:8),
                Text('해당 조건의 스터디룸이 없습니다.\n시간 분할 매칭(백트래킹)을 시도해보세요.', textAlign: TextAlign.center, style: TextStyle(color:Colors.grey.shade500, fontSize:13))]))))
          else ...[
            Row(children: [
              const Text('추천 스터디룸', style: TextStyle(fontSize:15, fontWeight:FontWeight.bold)),
              const SizedBox(width:8),
              // TODO: 백엔드에서 우선순위 큐 결과 Top 3 반환
              Container(padding: const EdgeInsets.symmetric(horizontal:8,vertical:3), decoration: BoxDecoration(color:Colors.green.shade50, borderRadius: BorderRadius.circular(6)),
                  child: Text('PriorityQueue 결과', style: TextStyle(fontSize:10, color:Colors.green.shade700))),
            ]),
            const SizedBox(height: 10),
            ..._results.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _roomCard(e.value, e.key == 0),
            )),
          ],
        ],
        const SizedBox(height: 24),
      ])),
    );
  }

  Widget _hourSelector(String label, int value, ValueChanged<int> onChanged, int min, int max) =>
      Column(children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Row(children: [
          GestureDetector(onTap: value>min ? () => onChanged(value-1) : null,
              child: Icon(Icons.chevron_left, color: value>min ? Colors.green.shade600 : Colors.grey.shade300)),
          Padding(padding: const EdgeInsets.symmetric(horizontal:4),
              child: Text('$value:00', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
          GestureDetector(onTap: value<max ? () => onChanged(value+1) : null,
              child: Icon(Icons.chevron_right, color: value<max ? Colors.green.shade600 : Colors.grey.shade300)),
        ]),
      ]);

  Widget _roomCard(RoomRecommendation rec, bool isTop) => Card(
    elevation: 0, color: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: isTop ? Colors.green.shade300 : Colors.grey.shade200, width: isTop ? 1.5 : 1)),
    child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
      Container(width:48,height:48, decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
          alignment: Alignment.center, child: Text('${rec.score.round()}', style: TextStyle(fontWeight:FontWeight.bold, color:Colors.green.shade700, fontSize:15))),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(rec.room.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          if (isTop) ...[const SizedBox(width:6), Container(padding: const EdgeInsets.symmetric(horizontal:6,vertical:2),
              decoration: BoxDecoration(color: Colors.green.shade600, borderRadius: BorderRadius.circular(4)),
              child: const Text('추천 1위', style: TextStyle(fontSize:10, color:Colors.white, fontWeight:FontWeight.bold)))],
        ]),
        const SizedBox(height: 4),
        Text('${rec.room.location} · ${rec.room.capacity}인실', style: TextStyle(fontSize:12, color:Colors.grey.shade600)),
        const SizedBox(height: 6),
        Wrap(spacing:4, children: rec.room.facilities.map((f) => Chip(
            label: Text(f, style: const TextStyle(fontSize:10)), padding: EdgeInsets.zero,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            backgroundColor: Colors.grey.shade100)).toList()),
      ])),
      const SizedBox(width: 8),
      FilledButton(onPressed: () => _reserve(rec),
          style: FilledButton.styleFrom(backgroundColor: Colors.green.shade600, minimumSize: const Size(60,36), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          child: const Text('예약', style: TextStyle(fontSize:13))),
    ])),
  );
}

// ══════════════════════════════════════════════════════════════
// 3-B. 스터디룸 예약 내역 페이지
// ══════════════════════════════════════════════════════════════
class StudyRoomReservationHistoryPage extends StatelessWidget {
  final List<StudyRoomReservation> reservations;
  const StudyRoomReservationHistoryPage({super.key, required this.reservations});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('예약 내역', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
        backgroundColor: Colors.green.shade600, centerTitle: true, elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: reservations.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.event_note_outlined, size: 72, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text('예약 내역이 없습니다', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
        const SizedBox(height: 6),
        Text('스터디룸을 예약하면 여기에 표시됩니다', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
      ]))
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: reservations.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final res = reservations[reservations.length - 1 - i]; // 최신순
          return Card(
            elevation: 0, color: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.green.shade200, width: 1.2)),
            child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.center,
                child: Icon(Icons.meeting_room_rounded, color: Colors.green.shade600, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(res.roomName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(res.location, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 6),
                Row(children: [
                  Icon(Icons.calendar_today_outlined, size: 13, color: Colors.green.shade500),
                  const SizedBox(width: 4),
                  Text(res.date, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                  const SizedBox(width: 10),
                  Icon(Icons.access_time_rounded, size: 13, color: Colors.green.shade500),
                  const SizedBox(width: 4),
                  Text('${res.startHour}:00 ~ ${res.endHour}:00',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                ]),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                child: Text('예약완료', style: TextStyle(fontSize: 11, color: Colors.green.shade700, fontWeight: FontWeight.bold)),
              ),
            ])),
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// 4. 분실물 통합 센터 페이지
// ══════════════════════════════════════════════════════════════
class LostFoundPage extends StatefulWidget {
  const LostFoundPage({super.key});
  @override
  State<LostFoundPage> createState() => _LostFoundPageState();
}

class _LostFoundPageState extends State<LostFoundPage> {
  final _ctrl = TextEditingController();
  bool _isFuzzy = false;
  List<LostItem> _results = [];
  bool _isLoading = false, _searched = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    // TODO: 전체 분실물 목록 로드 (BST 순회 결과)
    final r = await LostFoundService.search('', false);
    setState(() { _results = r; _isLoading = false; _searched = true; });
  }

  Future<void> _search() async {
    setState(() { _isLoading = true; _searched = true; });
    try {
      // TODO: KMP 또는 Levenshtein 검색 → 백엔드 처리
      final r = await LostFoundService.search(_ctrl.text.trim(), _isFuzzy);
      setState(() => _results = r);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('분실물 통합 센터', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
        backgroundColor: Colors.redAccent, centerTitle: true, elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded, color: Colors.white),
            tooltip: '작성 내역',
            onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => LostFoundHistoryPage(posts: _myPosts))),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.redAccent,
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(
              builder: (_) => LostFoundWritePage(onSubmit: (post) {
                setState(() => _myPosts.add(post));
              })));
        },
        icon: const Icon(Icons.edit_rounded, color: Colors.white),
        label: const Text('작성하기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Column(children: [
        // 검색 영역
        Container(color: Colors.white, padding: const EdgeInsets.all(16), child: Column(children: [
          Row(children: [
            Expanded(child: TextField(controller: _ctrl,
              decoration: InputDecoration(
                hintText: '물건 이름이나 특징을 입력하세요 (예: 검정 지갑)',
                prefixIcon: const Icon(Icons.search),
                filled: true, fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(horizontal:14,vertical:12),
                suffixIcon: _ctrl.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _ctrl.clear(); _loadAll(); setState((){}); }) : null,
              ),
              onSubmitted: (_) => _search(), onChanged: (_) => setState((){}),
            )),
            const SizedBox(width: 8),
            FilledButton(onPressed: _search,
                style: FilledButton.styleFrom(backgroundColor: Colors.redAccent, minimumSize: const Size(52,52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Icon(Icons.search)),
          ]),
        ])),

        // 결과
        Expanded(child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.redAccent))
            : _results.isEmpty ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.search_off, size:64, color:Colors.grey.shade300), const SizedBox(height:12),
          Text('검색 결과가 없습니다', style: TextStyle(color:Colors.grey.shade500)),
        ]))
            : ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _results.length,
          separatorBuilder: (_,__) => const SizedBox(height: 10),
          itemBuilder: (_,i) => _lostItemCard(_results[i]),
        )),
      ]),
    );
  }

  Widget _lostItemCard(LostItem item) {
    final isAvailable = item.status == '보관중';
    final simColor = item.similarity >= 90 ? Colors.green : item.similarity >= 70 ? Colors.orange : Colors.grey;
    return Card(elevation:0, color:Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(item.itemName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
          Container(padding: const EdgeInsets.symmetric(horizontal:8,vertical:3), decoration: BoxDecoration(color: simColor.withValues(alpha:0.12), borderRadius: BorderRadius.circular(6)),
              child: Text('유사도 ${item.similarity}%', style: TextStyle(fontSize:11, color:simColor, fontWeight:FontWeight.bold))),
          const SizedBox(width: 6),
          Container(padding: const EdgeInsets.symmetric(horizontal:8,vertical:3), decoration: BoxDecoration(color: isAvailable ? Colors.blue.shade50 : Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
              child: Text(item.status, style: TextStyle(fontSize:11, color: isAvailable ? Colors.blue.shade700 : Colors.grey.shade600, fontWeight:FontWeight.bold))),
        ]),
        const SizedBox(height: 6),
        Text(item.description, style: TextStyle(fontSize:13, color:Colors.grey.shade700)),
        const SizedBox(height: 8),
        Row(children: [
          Icon(Icons.location_on_outlined, size:14, color:Colors.grey.shade500),
          const SizedBox(width:4),
          Text(item.location, style: TextStyle(fontSize:12, color:Colors.grey.shade600)),
          const SizedBox(width:12),
          Icon(Icons.access_time, size:14, color:Colors.grey.shade500),
          const SizedBox(width:4),
          Text(item.foundDate, style: TextStyle(fontSize:12, color:Colors.grey.shade600)),
          const Spacer(),
          if (isAvailable) TextButton(onPressed: () async {
            // TODO: LostFoundService.claimItem → 분실물 수령 신청
            await LostFoundService.claimItem(item.id);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${item.itemName} 수령 신청이 완료되었습니다.')));
          }, style: TextButton.styleFrom(foregroundColor: Colors.redAccent, padding: const EdgeInsets.symmetric(horizontal:8,vertical:4)),
              child: const Text('수령 신청', style: TextStyle(fontSize:12, fontWeight:FontWeight.bold))),
        ]),
      ])),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// 4-B. 분실물 작성 페이지
// ══════════════════════════════════════════════════════════════
class LostFoundWritePage extends StatefulWidget {
  final ValueChanged<LostFoundPost> onSubmit;
  final LostFoundPost? initialPost; // null이면 신규 작성, not-null이면 수정 모드
  const LostFoundWritePage({super.key, required this.onSubmit, this.initialPost});
  @override
  State<LostFoundWritePage> createState() => _LostFoundWritePageState();
}

class _LostFoundWritePageState extends State<LostFoundWritePage> {
  late final TextEditingController _itemNameCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _contactCtrl;
  final _formKey    = GlobalKey<FormState>();
  final _picker     = ImagePicker();
  XFile? _imageFile;
  bool _isSubmitting = false;
  bool _isAnonymous  = false;

  bool get _isEditMode => widget.initialPost != null;

  @override
  void initState() {
    super.initState();
    final p = widget.initialPost;
    _itemNameCtrl    = TextEditingController(text: p?.itemName    ?? '');
    _descriptionCtrl = TextEditingController(text: p?.description ?? '');
    _locationCtrl    = TextEditingController(text: p?.location    ?? '');
    _contactCtrl     = TextEditingController(text: p?.contact     ?? '');
    _isAnonymous     = p?.isAnonymous ?? false;
    if (p?.imagePath != null) _imageFile = XFile(p!.imagePath!);
  }

  @override
  void dispose() {
    _itemNameCtrl.dispose(); _descriptionCtrl.dispose();
    _locationCtrl.dispose(); _contactCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked != null) setState(() => _imageFile = picked);
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(margin: const EdgeInsets.symmetric(vertical: 12), width: 36, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
        const Text('사진 첨부', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ListTile(
          leading: Container(width: 44, height: 44,
              decoration: BoxDecoration(color: Colors.indigo.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.photo_library_rounded, color: Colors.indigo)),
          title: const Text('갤러리에서 선택', style: TextStyle(fontWeight: FontWeight.w500)),
          onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
        ),
        ListTile(
          leading: Container(width: 44, height: 44,
              decoration: BoxDecoration(color: Colors.blueAccent.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.camera_alt_rounded, color: Colors.blueAccent)),
          title: const Text('카메라로 촬영', style: TextStyle(fontWeight: FontWeight.w500)),
          onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
        ),
        if (_imageFile != null)
          ListTile(
            leading: Container(width: 44, height: 44,
                decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent)),
            title: const Text('사진 삭제', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.redAccent)),
            onTap: () { Navigator.pop(context); setState(() => _imageFile = null); },
          ),
        const SizedBox(height: 12),
      ])),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 400)); // MOCK
    final post = _isEditMode
        ? widget.initialPost!.copyWith(
        itemName:    _itemNameCtrl.text.trim(),
        description: _descriptionCtrl.text.trim(),
        location:    _locationCtrl.text.trim(),
        contact:     _isAnonymous ? '' : _contactCtrl.text.trim(),
        isAnonymous: _isAnonymous,
        imagePath:   _imageFile?.path,
        clearImage:  _imageFile == null)
        : LostFoundPost(
        id: 'P\${DateTime.now().millisecondsSinceEpoch}',
        itemName:    _itemNameCtrl.text.trim(),
        description: _descriptionCtrl.text.trim(),
        location:    _locationCtrl.text.trim(),
        contact:     _isAnonymous ? '' : _contactCtrl.text.trim(),
        isAnonymous: _isAnonymous,
        imagePath:   _imageFile?.path,
        date: () {
          final now = DateTime.now();
          return "${now.year}.${now.month.toString().padLeft(2,"0")}.${now.day.toString().padLeft(2,"0")}";
        }());
    widget.onSubmit(post);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEditMode ? '신고 내용이 수정되었습니다.' : '분실물 신고가 접수되었습니다.')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(_isEditMode ? '신고 내용 수정' : '분실물 신고 작성',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
        backgroundColor: Colors.redAccent, centerTitle: true, elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Card(
              elevation: 0, color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
              child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _sectionLabel('물건 이름 *'),
                TextFormField(
                  controller: _itemNameCtrl,
                  decoration: _inputDeco('예: 에어팟 프로, 검정 지갑', Icons.inventory_2_outlined),
                  validator: (v) => v == null || v.trim().isEmpty ? '물건 이름을 입력해주세요' : null,
                ),
                const SizedBox(height: 16),
                _sectionLabel('물건 특징 *'),
                TextFormField(
                  controller: _descriptionCtrl,
                  maxLines: 3,
                  decoration: _inputDeco('색상, 브랜드, 특이사항 등을 입력해주세요', Icons.description_outlined),
                  validator: (v) => v == null || v.trim().isEmpty ? '특징을 입력해주세요' : null,
                ),
                const SizedBox(height: 16),
                _sectionLabel('분실 장소 *'),
                TextFormField(
                  controller: _locationCtrl,
                  decoration: _inputDeco('예: 비전타워 3층 스터디룸', Icons.location_on_outlined),
                  validator: (v) => v == null || v.trim().isEmpty ? '분실 장소를 입력해주세요' : null,
                ),
                const SizedBox(height: 16),
                _sectionLabel('연락처'),
                TextFormField(
                  controller: _contactCtrl,
                  keyboardType: TextInputType.phone,
                  enabled: !_isAnonymous,
                  decoration: _inputDeco(
                    _isAnonymous ? '익명 선택 시 연락처가 숨겨집니다' : '010-0000-0000',
                    Icons.phone_outlined,
                    disabled: _isAnonymous,
                  ),
                ),
                const SizedBox(height: 16),
                // ── 사진 첨부 ──────────────────────────────────────
                _sectionLabel('사진 첨부 (선택, 1장)'),
                GestureDetector(
                  onTap: _showImagePicker,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    height: _imageFile == null ? 100 : 220,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _imageFile != null ? Colors.redAccent : Colors.grey.shade300,
                          width: _imageFile != null ? 1.5 : 1,
                          style: _imageFile == null ? BorderStyle.solid : BorderStyle.solid),
                    ),
                    child: _imageFile == null
                        ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.add_photo_alternate_outlined, size: 36, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text('탭하여 사진 추가', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                    ])
                        : Stack(fit: StackFit.expand, children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image.file(File(_imageFile!.path), fit: BoxFit.cover),
                      ),
                      Positioned(top: 8, right: 8,
                        child: GestureDetector(
                          onTap: () => setState(() => _imageFile = null),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                                color: Colors.black54, shape: BoxShape.circle),
                            child: const Icon(Icons.close, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                      Positioned(bottom: 8, right: 8,
                        child: GestureDetector(
                          onTap: _showImagePicker,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(8)),
                            child: const Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text('변경', style: TextStyle(color: Colors.white, fontSize: 12)),
                            ]),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 16),
                // ── 익명 설정 ──────────────────────────────────────
                GestureDetector(
                  onTap: () => setState(() {
                    _isAnonymous = !_isAnonymous;
                    if (_isAnonymous) _contactCtrl.clear();
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: _isAnonymous ? Colors.red.shade50 : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isAnonymous ? Colors.redAccent : Colors.grey.shade300,
                        width: _isAnonymous ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 22, height: 22,
                        decoration: BoxDecoration(
                          color: _isAnonymous ? Colors.redAccent : Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: _isAnonymous ? Colors.redAccent : Colors.grey.shade400,
                              width: 1.5),
                        ),
                        child: _isAnonymous
                            ? const Icon(Icons.check_rounded, color: Colors.white, size: 15)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('익명으로 작성하기',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _isAnonymous ? Colors.redAccent : Colors.black87,
                            )),
                        const SizedBox(height: 2),
                        Text('선택 시 이름과 연락처가 공개되지 않습니다',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                      ]),
                      const Spacer(),
                      if (_isAnonymous)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(6)),
                          child: const Text('익명',
                              style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                    ]),
                  ),
                ),
              ])),
            ),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: FilledButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded),
              label: Text(_isSubmitting ? (_isEditMode ? '수정 중...' : '접수 중...') : (_isEditMode ? '수정 완료' : '신고 접수하기')),
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            )),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon, {bool disabled = false}) => InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon, size: 20, color: disabled ? Colors.grey.shade400 : Colors.redAccent),
    filled: true,
    fillColor: disabled ? Colors.grey.shade100 : Colors.grey.shade50,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
    disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red.shade300)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );
}

// ══════════════════════════════════════════════════════════════
// 4-C. 분실물 작성 내역 페이지
// ══════════════════════════════════════════════════════════════
class LostFoundHistoryPage extends StatefulWidget {
  final List<LostFoundPost> posts;
  const LostFoundHistoryPage({super.key, required this.posts});
  @override
  State<LostFoundHistoryPage> createState() => _LostFoundHistoryPageState();
}

class _LostFoundHistoryPageState extends State<LostFoundHistoryPage> {
  // 전역 _myPosts 와 동기화: widget.posts 는 동일 참조이므로 setState만으로 갱신됨

  void _openDetail(LostFoundPost post) async {
    await Navigator.push(context, MaterialPageRoute(
      builder: (_) => LostFoundPostDetailPage(
        post: post,
        onEdit: (updated) {
          final idx = widget.posts.indexWhere((p) => p.id == updated.id);
          if (idx != -1) setState(() => widget.posts[idx] = updated);
        },
        onDelete: (id) {
          setState(() => widget.posts.removeWhere((p) => p.id == id));
          Navigator.pop(context); // 상세 페이지 닫기
        },
      ),
    ));
    // 상세에서 돌아올 때 목록 갱신
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final posts = widget.posts;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('작성 내역 (${posts.length}건)',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
        backgroundColor: Colors.redAccent, centerTitle: true, elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: posts.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.receipt_long_outlined, size: 72, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text('작성한 신고 내역이 없습니다', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
        const SizedBox(height: 6),
        Text('분실물을 신고하면 여기에 표시됩니다', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
      ]))
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: posts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final post = posts[posts.length - 1 - i]; // 최신순
          return Card(
            elevation: 0, color: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.grey.shade200)),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _openDetail(post),
              borderRadius: BorderRadius.circular(14),
              child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                    child: Icon(Icons.inventory_2_outlined, color: Colors.redAccent, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(post.itemName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(6)),
                    child: Text('접수완료',
                        style: TextStyle(fontSize: 11, color: Colors.orange.shade700, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
                ]),
                const SizedBox(height: 8),
                Text(post.description,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Row(children: [
                  Icon(Icons.location_on_outlined, size: 13, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(post.location, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(width: 10),
                  Icon(Icons.access_time, size: 13, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(post.date, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  if (post.contact.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    Icon(Icons.phone_outlined, size: 13, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(post.contact, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ]),
              ])),
            ),
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// 4-D. 분실물 신고 상세 페이지 (수정 / 삭제)
// ══════════════════════════════════════════════════════════════
class LostFoundPostDetailPage extends StatefulWidget {
  final LostFoundPost post;
  final ValueChanged<LostFoundPost> onEdit;
  final ValueChanged<String> onDelete;
  const LostFoundPostDetailPage({super.key,
    required this.post, required this.onEdit, required this.onDelete});
  @override
  State<LostFoundPostDetailPage> createState() => _LostFoundPostDetailPageState();
}

class _LostFoundPostDetailPageState extends State<LostFoundPostDetailPage> {
  late LostFoundPost _post;

  @override
  void initState() { super.initState(); _post = widget.post; }

  void _goEdit() async {
    await Navigator.push(context, MaterialPageRoute(
      builder: (_) => LostFoundWritePage(
        initialPost: _post,
        onSubmit: (updated) {
          setState(() => _post = updated);
          widget.onEdit(updated);
        },
      ),
    ));
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
          SizedBox(width: 8),
          Text('신고 삭제', style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
        content: const Text('이 신고 내역을 삭제하시겠습니까?\n삭제 후에는 복구할 수 없습니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: Text('취소', style: TextStyle(color: Colors.grey.shade600))),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);        // 다이얼로그 닫기
              widget.onDelete(_post.id); // 목록에서 제거 + 상세 페이지 닫기
            },
            style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 18, color: Colors.redAccent),
      const SizedBox(width: 12),
      SizedBox(width: 60,
          child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w500))),
      Expanded(child: Text(value,
          style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w600, height: 1.4))),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('신고 상세',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
        backgroundColor: Colors.redAccent, centerTitle: true, elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            tooltip: '수정',
            onPressed: _goEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
            tooltip: '삭제',
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // 상태 배지 + 제목 카드
          Card(
            elevation: 0, color: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFFFCDD2), width: 1.2)),
            child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200)),
                    child: Text('접수완료',
                        style: TextStyle(fontSize: 12, color: Colors.orange.shade700, fontWeight: FontWeight.bold)),
                  ),
                  if (_post.isAnonymous) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.visibility_off_outlined, size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text('익명', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                      ]),
                    ),
                  ],
                ]),
                Text(_post.date, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ]),
              const SizedBox(height: 14),
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const Icon(Icons.inventory_2_rounded, color: Colors.redAccent, size: 36),
              ),
              const SizedBox(height: 14),
              Text(_post.itemName,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                  textAlign: TextAlign.center),
            ])),
          ),
          const SizedBox(height: 14),
          // 첨부 이미지
          if (_post.imagePath != null) ...[
            const SizedBox(height: 0),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(_post.imagePath!),
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 80,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16)),
                  child: Center(child: Icon(Icons.broken_image_outlined,
                      color: Colors.grey.shade400, size: 36)),
                ),
              ),
            ),
          ],
          // 세부 정보 카드
          Card(
            elevation: 0, color: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200)),
            child: Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 8), child: Column(children: [
              _detailRow(Icons.description_outlined, '특징', _post.description),
              _detailRow(Icons.location_on_outlined, '분실 장소', _post.location),
              if (_post.isAnonymous)
                _detailRow(Icons.visibility_off_outlined, '공개 여부', '익명 게시글')
              else if (_post.contact.isNotEmpty)
                _detailRow(Icons.phone_outlined, '연락처', _post.contact),
            ])),
          ),
          const SizedBox(height: 24),
          // 액션 버튼 행
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: _goEdit,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('수정하기', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            )),
            const SizedBox(width: 12),
            Expanded(child: FilledButton.icon(
              onPressed: _confirmDelete,
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('삭제하기', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            )),
          ]),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// 5. 장학 제도 탐색 페이지
// ══════════════════════════════════════════════════════════════
class ScholarshipPage extends StatefulWidget {
  const ScholarshipPage({super.key});
  @override
  State<ScholarshipPage> createState() => _ScholarshipPageState();
}

class _ScholarshipPageState extends State<ScholarshipPage> {
  // TODO: 학생 정보는 로그인된 사용자의 실제 데이터로 교체
  double _gpa = 3.8;
  int _grade = 3, _incomeLevel = 5;
  bool _awardedLastSemester = false; // 직전 학기 수여 여부
  List<Scholarship> _scholarships = [];
  bool _isLoading = false;
  String _filter = '전체';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    // TODO: ScholarshipService.fetch → 크롤링 DB + 서버 스코어링
    final r = await ScholarshipService.fetch(_gpa, _grade, _incomeLevel);
    setState(() { _scholarships = r; _isLoading = false; });
  }

  List<Scholarship> get _filtered {
    switch (_filter) {
      case '적합': return _scholarships.where((s) => s.score >= 80).toList();
      case '확인필요': return _scholarships.where((s) => s.score >= 60 && s.score < 80).toList();
      case '마감임박': return _scholarships.where((s) { final d = ScholarshipService.daysLeft(s.deadline); return d >= 0 && d <= 7; }).toList();
      default: return _scholarships;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _appBar('장학 제도 탐색', Colors.teal.shade600),
      body: Column(children: [
        // 내 정보 카드 + 필터 탭 (하나의 흰 블록, 하단 둥근 마감)
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              bottomLeft:  Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // 내 정보 행
            Row(children: [
              const Text('내 정보', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(width: 6),
              Container(padding: const EdgeInsets.symmetric(horizontal:6,vertical:2),
                  decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(4)),
                  child: Text('직접 입력 (향후 학생 DB 자동 연동)', style: TextStyle(fontSize:9, color:Colors.teal.shade700))),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _infoChip('학점', '\${(_gpa * 10).floor() / 10}점', Colors.teal),
              const SizedBox(width: 8),
              _infoChip('학년', '\$_grade학년', Colors.indigo),
              const SizedBox(width: 8),
              _infoChip('소득분위', '\$_incomeLevel분위', Colors.orange),
              const Spacer(),
              TextButton(onPressed: () => _showInfoEdit(), child: const Text('수정', style: TextStyle(fontSize:13))),
            ]),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            // 필터 탭
            SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(
              children: ['전체','적합','확인필요','마감임박'].map((f) =>
                  Padding(padding: const EdgeInsets.only(right:8), child: GestureDetector(
                    onTap: () => setState(() => _filter = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal:14, vertical:7),
                      decoration: BoxDecoration(
                        color: _filter==f ? Colors.teal.shade600 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(f, style: TextStyle(
                          fontSize:13,
                          color: _filter==f ? Colors.white : Colors.grey.shade700,
                          fontWeight: _filter==f ? FontWeight.bold : FontWeight.normal)),
                    ),
                  )),
              ).toList(),
            )),
          ]),
        ),

        // 장학금 목록
        Expanded(child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _filtered.isEmpty ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.money_off, size:64, color:Colors.grey.shade300), const SizedBox(height:12),
          Text('해당 조건의 장학금이 없습니다', style: TextStyle(color:Colors.grey.shade500)),
        ]))
            : ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _filtered.length,
          separatorBuilder: (_,__) => const SizedBox(height: 10),
          itemBuilder: (_,i) => _scholarshipCard(_filtered[i]),
        )),
      ]),
    );
  }

  Widget _infoChip(String label, String value, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal:12,vertical:6),
      decoration: BoxDecoration(color: color.withValues(alpha:0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha:0.2))),
      child: Column(children: [
        Text(label, style: TextStyle(fontSize:10, color: color)),
        Text(value, style: TextStyle(fontSize:13, fontWeight: FontWeight.bold, color: color)),
      ]));

  Widget _scholarshipCard(Scholarship s) {
    final days = ScholarshipService.daysLeft(s.deadline);
    final scoreColor = s.score >= 80 ? Colors.green : s.score >= 60 ? Colors.orange : Colors.grey;
    final isUrgent = days >= 0 && days <= 7;

    return Card(elevation:0, color:Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: s.score >= 80 ? Colors.teal.shade200 : Colors.grey.shade200, width: s.score >= 80 ? 1.5 : 1)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal:16,vertical:4),
        childrenPadding: const EdgeInsets.fromLTRB(16,0,16,16),
        leading: Container(width:44,height:44, decoration: BoxDecoration(
            color: scoreColor.withValues(alpha:0.12), borderRadius: BorderRadius.circular(10)),
            alignment: Alignment.center,
            child: Text('${s.score}', style: TextStyle(fontWeight:FontWeight.bold, color:scoreColor, fontSize:15))),
        title: Row(children: [
          Expanded(child: Text(s.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
          if (isUrgent) Container(margin: const EdgeInsets.only(left:6), padding: const EdgeInsets.symmetric(horizontal:6,vertical:2),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
              child: Text('D-$days', style: const TextStyle(fontSize:10, color:Colors.red, fontWeight:FontWeight.bold))),
        ]),
        subtitle: Padding(padding: const EdgeInsets.only(top:4), child: Row(children: [
          Text(s.organization, style: TextStyle(fontSize:11, color:Colors.grey.shade600)),
          const SizedBox(width:8),
          Text(s.amount, style: TextStyle(fontSize:11, color:Colors.teal.shade700, fontWeight:FontWeight.w600)),
        ])),
        children: [
          const Divider(height:1),
          const SizedBox(height:12),
          // 지원 조건
          if (s.requiredGpa != null) _condRow(Icons.grade_outlined, '학점 조건', '${s.requiredGpa} 이상', _gpa >= s.requiredGpa! ? Colors.green : Colors.red),
          if (s.requiredIncomeLevel != null) _condRow(Icons.account_balance_outlined, '소득분위', '${ s.requiredIncomeLevel}분위 이하', _incomeLevel <= s.requiredIncomeLevel! ? Colors.green : Colors.red),
          _condRow(Icons.event_outlined, '마감일', s.deadline, days >= 0 ? Colors.black87 : Colors.grey),
          if (s.detail != null) ...[const SizedBox(height:8),
            Text(s.detail!, style: TextStyle(fontSize:12, color:Colors.grey.shade700, height:1.5))],
          const SizedBox(height:12),
          // 신청 버튼
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: () async {
              // TODO: 공유 기능 연결
            }, icon: const Icon(Icons.share_outlined, size:16), label: const Text('공유', style:TextStyle(fontSize:13)),
                style: OutlinedButton.styleFrom(foregroundColor:Colors.teal.shade600, side:BorderSide(color:Colors.teal.shade200)))),
            const SizedBox(width:8),
            Expanded(child: FilledButton.icon(onPressed: () async {
              // TODO: ScholarshipService.getApplyUrl → 외부 신청 페이지
              final url = await ScholarshipService.getApplyUrl(s.id);
              if (url != null) openUrl(url);
            }, icon: const Icon(Icons.open_in_new, size:16), label: const Text('신청하기', style:TextStyle(fontSize:13)),
                style: FilledButton.styleFrom(backgroundColor:Colors.teal.shade600, shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(8))))),
          ]),
        ],
      ),
    );
  }

  Widget _condRow(IconData icon, String label, String value, Color statusColor) => Padding(
      padding: const EdgeInsets.only(bottom:8),
      child: Row(children: [
        Icon(icon, size:16, color:Colors.grey.shade500),
        const SizedBox(width:8),
        SizedBox(width:70, child: Text(label, style: TextStyle(fontSize:12, color:Colors.grey.shade600))),
        Expanded(child: Text(value, style: TextStyle(fontSize:12, fontWeight:FontWeight.w600, color:statusColor))),
      ]));

  void _showInfoEdit() {
    double gpa = _gpa; int grade = _grade, income = _incomeLevel;
    bool awarded = _awardedLastSemester;
    final gpaCtrl = TextEditingController(text: gpa.toStringAsFixed(1));

    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (_,set) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('내 정보 수정', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          // GPA — up/down 버튼 + 직접 입력
          Row(children: [
            const Text('학점', style: TextStyle(fontSize:13, fontWeight: FontWeight.w500)),
            const Spacer(),
            IconButton(
              onPressed: gpa > 0.0 ? () { gpa = (((gpa - 0.1).clamp(0.0,4.5) * 10).floor() / 10); gpaCtrl.text = gpa.toStringAsFixed(1); set((){}); } : null,
              icon: const Icon(Icons.remove_circle_outline, size: 20), color: Colors.teal,
              constraints: const BoxConstraints(), padding: const EdgeInsets.all(4),
            ),
            SizedBox(width: 64, child: TextField(
              controller: gpaCtrl,
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.teal.shade600, width: 1.5)),
              ),
              onChanged: (v) {
                final parsed = double.tryParse(v);
                if (parsed != null) { gpa = ((parsed.clamp(0.0,4.5) * 10).floor() / 10); set((){}); }
              },
            )),
            IconButton(
              onPressed: gpa < 4.5 ? () { gpa = (((gpa + 0.1).clamp(0.0,4.5) * 10).floor() / 10); gpaCtrl.text = gpa.toStringAsFixed(1); set((){}); } : null,
              icon: const Icon(Icons.add_circle_outline, size: 20), color: Colors.teal,
              constraints: const BoxConstraints(), padding: const EdgeInsets.all(4),
            ),
          ]),
          const SizedBox(height: 12),
          // 학년
          Row(children: [const Text('학년', style: TextStyle(fontSize:13, fontWeight: FontWeight.w500)), const Spacer(),
            DropdownButton<int>(value:grade, items:List.generate(4,(i)=>DropdownMenuItem(value:i+1, child:Text('${i+1}학년'))),
                onChanged:(v)=>set(()=>grade=v!))]),
          const SizedBox(height: 8),
          // 소득분위
          Row(children: [const Text('소득분위', style: TextStyle(fontSize:13, fontWeight: FontWeight.w500)), const Spacer(),
            DropdownButton<int>(value:income, items:List.generate(10,(i)=>DropdownMenuItem(value:i+1, child:Text('${i+1}분위'))),
                onChanged:(v)=>set(()=>income=v!))]),
          const SizedBox(height: 12),
          // 직전 학기 수여 여부
          Row(children: [
            const Expanded(child: Text('직전 학기 수여 여부', style: TextStyle(fontSize:13, fontWeight: FontWeight.w500))),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => set(() => awarded = true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: awarded ? Colors.teal.shade600 : Colors.grey.shade100,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                  border: Border.all(color: awarded ? Colors.teal.shade600 : Colors.grey.shade300),
                ),
                child: Text('예', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: awarded ? Colors.white : Colors.grey.shade600)),
              ),
            ),
            GestureDetector(
              onTap: () => set(() => awarded = false),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: !awarded ? Colors.teal.shade600 : Colors.grey.shade100,
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                  border: Border.all(color: !awarded ? Colors.teal.shade600 : Colors.grey.shade300),
                ),
                child: Text('아니요', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: !awarded ? Colors.white : Colors.grey.shade600)),
              ),
            ),
          ]),
        ])),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text('취소')),
          FilledButton(onPressed: () {
            setState(() { _gpa=gpa; _grade=grade; _incomeLevel=income; _awardedLastSemester=awarded; });
            Navigator.pop(ctx);
            _load();
          }, style: FilledButton.styleFrom(backgroundColor:Colors.teal.shade600), child: const Text('저장 및 재조회')),
        ],
      ),
    ));
  }
}

// ══════════════════════════════════════════════════════════════
// 설정 페이지
// ══════════════════════════════════════════════════════════════
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
  late UserProfile _profile; XFile? _image;

  @override
  void initState() { super.initState(); _profile = widget.profile; _image = widget.profileImage; }

  Future<void> _pickImage(ImageSource src) async {
    Navigator.pop(context);
    final p = await _picker.pickImage(source:src, imageQuality:90);
    if (p!=null) { setState(()=>_image=p); widget.onImageChanged(p); }
  }

  void _showPicker() => showModalBottomSheet(context:context, backgroundColor:Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top:Radius.circular(22))),
      builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(margin:const EdgeInsets.symmetric(vertical:12), width:36, height:4, decoration:BoxDecoration(color:Colors.grey.shade300, borderRadius:BorderRadius.circular(4))),
        const Text('프로필 사진 변경', style:TextStyle(fontSize:16, fontWeight:FontWeight.bold)),
        const SizedBox(height:8),
        _PickerOption(icon:Icons.photo_library_rounded, label:'갤러리에서 선택', color:Colors.indigo, onTap:()=>_pickImage(ImageSource.gallery)),
        _PickerOption(icon:Icons.camera_alt_rounded, label:'카메라로 촬영', color:Colors.blueAccent, onTap:()=>_pickImage(ImageSource.camera)),
        if (_image!=null) _PickerOption(icon:Icons.delete_outline_rounded, label:'현재 사진 삭제', color:Colors.redAccent, onTap:(){Navigator.pop(context);setState(()=>_image=null);widget.onImageChanged(null);}),
        const SizedBox(height:12),
      ])));

  void _showEdit() {
    final n=TextEditingController(text:_profile.name), d=TextEditingController(text:_profile.department),
        id=TextEditingController(text:_profile.studentId), g=TextEditingController(text:_profile.grade);
    showDialog(context:context, builder:(ctx)=>AlertDialog(
      shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(18)),
      title:const Text('내 정보 수정', style:TextStyle(fontWeight:FontWeight.bold,fontSize:17)),
      content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min, children:[
        _editF('이름',n,Icons.person_outline), const SizedBox(height:12),
        _editF('학과',d,Icons.school_outlined), const SizedBox(height:12),
        _editF('학번',id,Icons.badge_outlined), const SizedBox(height:12),
        _editF('학년',g,Icons.bar_chart_outlined),
      ])),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(ctx), child:Text('취소',style:TextStyle(color:Colors.grey.shade600))),
        FilledButton(onPressed:(){
          final u=_profile.copyWith(name:n.text.trim(),department:d.text.trim(),studentId:id.text.trim(),grade:g.text.trim());
          setState(()=>_profile=u); widget.onProfileChanged(u); Navigator.pop(ctx);
        }, style:FilledButton.styleFrom(backgroundColor:Colors.indigo,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(10))), child:const Text('저장')),
      ],
    ));
  }

  Widget _editF(String label, TextEditingController ctrl, IconData icon) => TextField(controller:ctrl,
      decoration:InputDecoration(labelText:label, prefixIcon:Icon(icon,size:20,color:Colors.indigo), filled:true, fillColor:Colors.grey.shade50,
          border:OutlineInputBorder(borderRadius:BorderRadius.circular(12),borderSide:BorderSide(color:Colors.grey.shade200)),
          enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(12),borderSide:BorderSide(color:Colors.grey.shade200)),
          focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(12),borderSide:const BorderSide(color:Colors.indigo,width:1.5)),
          contentPadding:const EdgeInsets.symmetric(horizontal:14,vertical:12)));

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F7FA),
    body: CustomScrollView(slivers:[
      SliverToBoxAdapter(child:Stack(clipBehavior:Clip.none, children:[
        Container(height:220, decoration:const BoxDecoration(gradient:LinearGradient(colors:[Color(0xFF3949AB),Color(0xFF1565C0)],begin:Alignment.topLeft,end:Alignment.bottomRight))),
        Positioned(top:MediaQuery.of(context).padding.top+8,left:8, child:IconButton(icon:const Icon(Icons.arrow_back_ios_new,color:Colors.white),onPressed:()=>Navigator.pop(context))),
        Positioned(top:MediaQuery.of(context).padding.top+16,left:0,right:0, child:const Center(child:Text('설정',style:TextStyle(color:Colors.white,fontSize:18,fontWeight:FontWeight.bold)))),
        Positioned(bottom:-44,left:0,right:0, child:Center(child:GestureDetector(onTap:_showPicker, child:Stack(children:[
          Container(width:88,height:88, decoration:BoxDecoration(shape:BoxShape.circle,color:Colors.indigo.shade200,border:Border.all(color:Colors.white,width:3),
              boxShadow:[BoxShadow(color:Colors.black.withValues(alpha:0.15),blurRadius:12,offset:const Offset(0,4))],
              image:_image!=null?DecorationImage(image:FileImage(File(_image!.path)),fit:BoxFit.cover):null),
              child:_image==null?const Icon(Icons.person_rounded,size:52,color:Colors.white):null),
          Positioned(bottom:0,right:0,child:Container(width:28,height:28, decoration:BoxDecoration(color:Colors.white,shape:BoxShape.circle,border:Border.all(color:Colors.indigo.shade100,width:1.5),boxShadow:[BoxShadow(color:Colors.black.withValues(alpha:0.12),blurRadius:4)]),
              child:Icon(Icons.camera_alt_rounded,size:16,color:Colors.indigo.shade600))),
        ])))),
      ])),
      SliverToBoxAdapter(child:Padding(padding:const EdgeInsets.only(top:56,bottom:4), child:Column(children:[
        Text(_profile.name, style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold,color:Colors.black87)),
        const SizedBox(height:4),
        Text('${_profile.department} · ${_profile.grade}', style:TextStyle(fontSize:13,color:Colors.grey.shade600)),
      ]))),
      SliverToBoxAdapter(child:Padding(padding:const EdgeInsets.fromLTRB(20,16,20,0), child:Card(elevation:0,color:Colors.white,
          shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16),side:BorderSide(color:Colors.grey.shade200)),
          child:Padding(padding:const EdgeInsets.all(20), child:Column(children:[
            Row(children:[const Text('내 정보',style:TextStyle(fontSize:15,fontWeight:FontWeight.bold,color:Colors.black87)),const Spacer(),
              GestureDetector(onTap:_showEdit, child:Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:5),
                  decoration:BoxDecoration(color:Colors.indigo.withValues(alpha:0.08),borderRadius:BorderRadius.circular(8)),
                  child:Row(mainAxisSize:MainAxisSize.min,children:[Icon(Icons.edit_outlined,size:13,color:Colors.indigo.shade600),const SizedBox(width:4),
                    Text('수정',style:TextStyle(fontSize:12,color:Colors.indigo.shade600,fontWeight:FontWeight.w600))])))],
            ),
            const SizedBox(height:16), const Divider(height:1), const SizedBox(height:16),
            _infoR(Icons.person_outline,'이름',_profile.name),
            _infoR(Icons.school_outlined,'학과',_profile.department),
            _infoR(Icons.badge_outlined,'학번',_profile.studentId),
            _infoR(Icons.bar_chart_outlined,'학년',_profile.grade,isLast:true),
          ]))))),
      SliverToBoxAdapter(child:Padding(padding:const EdgeInsets.fromLTRB(20,16,20,0), child:Row(children:[
        Expanded(child:_actBtn(Icons.settings_outlined,'앱 설정',Colors.indigo,
                ()=>ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('앱 설정 준비 중입니다.'))))),
        const SizedBox(width:12),
        Expanded(child:_actBtn(Icons.logout_rounded,'로그아웃',Colors.redAccent,()=>showDialog(context:context,
            builder:(ctx)=>AlertDialog(shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16)),
                title:const Text('로그아웃',style:TextStyle(fontWeight:FontWeight.bold)), content:const Text('정말 로그아웃 하시겠습니까?'),
                actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:Text('취소',style:TextStyle(color:Colors.grey.shade600))),
                  FilledButton(onPressed:(){Navigator.pop(ctx);Navigator.pop(context);},
                      style:FilledButton.styleFrom(backgroundColor:Colors.redAccent,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(10))),child:const Text('로그아웃'))])))),
      ]))),
      SliverToBoxAdapter(child:SizedBox(height:MediaQuery.of(context).padding.bottom+40)),
    ]),
  );

  Widget _infoR(IconData icon,String label,String value,{bool isLast=false})=>Padding(padding:EdgeInsets.only(bottom:isLast?0:14),
      child:Row(children:[Icon(icon,size:18,color:Colors.grey.shade400),const SizedBox(width:12),SizedBox(width:44,child:Text(label,style:TextStyle(fontSize:13,color:Colors.grey.shade500))),Expanded(child:Text(value,style:const TextStyle(fontSize:14,fontWeight:FontWeight.w600,color:Colors.black87)))]));
  Widget _actBtn(IconData icon,String label,Color color,VoidCallback onTap)=>GestureDetector(onTap:onTap,child:Container(padding:const EdgeInsets.symmetric(vertical:16),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(14),border:Border.all(color:Colors.grey.shade200)),child:Column(children:[Icon(icon,color:color,size:24),const SizedBox(height:6),Text(label,style:TextStyle(fontSize:13,fontWeight:FontWeight.w600,color:color))])));
}

// ══════════════════════════════════════════════════════════════
// 공용 헬퍼
// ══════════════════════════════════════════════════════════════
Future<void> openUrl(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
}

AppBar _appBar(String title, Color color) => AppBar(
  title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
  backgroundColor: color, centerTitle: true, elevation: 0,
  iconTheme: const IconThemeData(color: Colors.white),
);

Widget _card({required Widget child}) => Card(elevation:0, color:Colors.white,
    shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16), side:BorderSide(color:Colors.grey.shade200)),
    child:Padding(padding:const EdgeInsets.all(16), child:child));

Widget _sectionLabel(String t) => Padding(padding:const EdgeInsets.only(bottom:8),
    child:Text(t, style:TextStyle(fontSize:13, fontWeight:FontWeight.w600, color:Colors.grey.shade700)));

Widget _errorBanner(String msg) => Padding(padding:const EdgeInsets.only(top:12), child:Container(padding:const EdgeInsets.all(12),
    decoration:BoxDecoration(color:Colors.red.shade50, borderRadius:BorderRadius.circular(10), border:Border.all(color:Colors.red.shade200)),
    child:Row(children:[Icon(Icons.error_outline, color:Colors.red.shade400, size:18),const SizedBox(width:8),Expanded(child:Text(msg,style:TextStyle(fontSize:13,color:Colors.red.shade700)))])));

class _ProfileRow extends StatelessWidget {
  final String label, value;
  const _ProfileRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Row(children:[
    Container(width:36, padding:const EdgeInsets.symmetric(horizontal:6,vertical:2),
        decoration:BoxDecoration(color:Colors.white.withValues(alpha:0.15),borderRadius:BorderRadius.circular(4)),
        child:Text(label,style:const TextStyle(fontSize:11,color:Colors.white60),textAlign:TextAlign.center)),
    const SizedBox(width:10),
    Text(value,style:const TextStyle(fontSize:14,fontWeight:FontWeight.w600,color:Colors.white)),
  ]);
}

class _PickerOption extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _PickerOption({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(onTap:onTap, child:Padding(padding:const EdgeInsets.symmetric(horizontal:20,vertical:10),
      child:Row(children:[Container(width:44,height:44,decoration:BoxDecoration(color:color.withValues(alpha:0.1),shape:BoxShape.circle),child:Icon(icon,color:color,size:22)),const SizedBox(width:16),
        Text(label,style:TextStyle(fontSize:15,fontWeight:FontWeight.w500,color:color==Colors.redAccent?Colors.redAccent:Colors.black87))])));
}