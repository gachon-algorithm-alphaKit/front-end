# AlphaKit Frontend (App)

AlphaKit 프로젝트의 모바일 클라이언트 어플리케이션입니다. **Flutter** 프레임워크를 기반으로 작성되었으며, Android 플랫폼을 주 타겟으로 개발되었습니다 (iOS 빌드 지원 가능).

---

## 📐 프로젝트 설정 (구조)

| 항목 | 내용 |
|------|------|
| **프레임워크** | Flutter (Material 3) |
| **언어** | Dart |
| **SDK 버전** | `^3.12.0` |
| **패키지 이름** | `alpha_kit` |
| **Application ID** | `com.example.alpha_kit` |
| **상태 관리** | Riverpod (`flutter_riverpod ^3.3.1`) |
| **디자인 시스템** | Material Design 3 (seed color: `Colors.indigo`) |
| **백엔드 통신** | REST API (`http` 패키지) / Base URL: `http://10.0.2.2:8000` |
| **인증 방식** | JWT (Access + Refresh Token, `shared_preferences`에 저장) |

---

## 🚀 실행 방법 (Android 기준)

### 사전 준비

1. **Flutter SDK 설치**
   - [Flutter 공식 설치 가이드](https://docs.flutter.dev/get-started/install)를 참고하여 SDK를 설치합니다.
   - `flutter doctor` 명령어로 개발 환경 상태를 점검합니다.

2. **Android 개발 환경**
   - Android Studio 설치 및 Android SDK 설정
   - Android 에뮬레이터 생성 또는 실기기의 USB 디버깅 활성화

### 빌드 & 실행

```bash
# 1. 프로젝트 루트로 이동
cd front-end

# 2. 의존성 패키지 설치
flutter pub get

# 3. 연결된 디바이스 확인
flutter devices

# 4. 앱 실행 (debug 모드)
flutter run

# 5. 릴리즈 APK 빌드 (선택)
flutter build apk --release
```

> **참고**: 에뮬레이터 환경에서는 백엔드 서버(`localhost:8000`)에 접근하기 위해 `10.0.2.2:8000`을 사용합니다. 실기기에서 테스트할 경우 각 API 서비스 파일의 `baseUrl`을 서버 IP로 변경해야 합니다.

### 앱 아이콘 설정

```bash
# flutter_launcher_icons를 사용하여 앱 아이콘 생성
dart run flutter_launcher_icons
```

---

## 📦 패키지 (의존성)

### 프로덕션 의존성

| 패키지 | 버전 | 용도 |
|--------|------|------|
| `flutter` (SDK) | — | 프레임워크 코어 |
| `flutter_riverpod` | `^3.3.1` | 상태 관리 (Provider + StateNotifier/Notifier) |
| `http` | `^1.6.0` | 백엔드 REST API 통신 |
| `shared_preferences` | `^2.5.5` | JWT 토큰 등 로컬 키-값 저장 |
| `image_picker` | `^1.1.2` | 분실물 게시판 이미지 업로드 |
| `url_launcher` | `^6.3.0` | 장학금 지원 등 외부 URL 열기 |
| `html` | `^0.15.4` | HTML 파싱 처리 |
| `cupertino_icons` | `^1.0.8` | iOS 스타일 아이콘 |

### 개발 의존성

| 패키지 | 버전 | 용도 |
|--------|------|------|
| `flutter_test` (SDK) | — | 위젯 테스트 |
| `flutter_lints` | `^6.0.0` | 정적 분석 린트 규칙 |
| `flutter_launcher_icons` | `^0.14.1` | 앱 런처 아이콘 생성 |

---

## 🗂 파일 트리

```
front-end/
├── android/                         # Android 네이티브 설정
├── ios/                             # iOS 네이티브 설정
├── assets/
│   └── icon/
│       └── alphakit.png             # 앱 아이콘 원본 이미지
├── lib/
│   ├── main.dart                    # 앱 엔트리포인트 (ProviderScope, 자동 로그인 분기)
│   │
│   ├── api/                         # 📡 백엔드 API 서비스 레이어
│   │   ├── auth_api.dart            #   - 로그인 / 회원정보 등록·수정 / 토큰 관리
│   │   ├── course_service.dart      #   - 강의 검색 / 자동완성
│   │   ├── wishlist_service.dart    #   - 강의 찜 토글 / 목록 조회 / 삭제
│   │   ├── scholarship_service.dart #   - 장학금 목록 조회 (조건 필터)
│   │   ├── study_room_service.dart  #   - 스터디룸 추천 / 예약 / 예약내역 / 취소
│   │   ├── lost_found_service.dart  #   - 분실물 CRUD / 검색 / 댓글 CRUD
│   │   └── campus_navigation_service.dart  # - 캠퍼스 경로 탐색 (A* + Nearest Neighbor)
│   │
│   ├── model/                       # 📋 데이터 모델 (JSON 파싱 포함)
│   │   ├── user_profile.dart        #   - Student, UserProfile
│   │   ├── course_model.dart        #   - Course, Professor, StudentCourse, SearchType
│   │   ├── scholarship_model.dart   #   - Scholarship
│   │   ├── study_room_model.dart    #   - StudyRoom, StudyRoomReservation, RoomRecommendation
│   │   ├── lost_found_model.dart    #   - LostItemPost, Comment
│   │   └── route_model.dart         #   - School, Place, WaypointResult, RouteResult
│   │
│   ├── provider/                    # 🔄 Riverpod 상태 관리
│   │   ├── auth_provider.dart       #   - 인증 상태 (AuthState + AuthNotifier)
│   │   ├── wishlist_provider.dart   #   - 찜 목록 (Optimistic UI 적용)
│   │   ├── comment_provider.dart    #   - 댓글 목록 (게시글별 Family Provider)
│   │   ├── my_lost_items_provider.dart  # - 내 분실물 신고 내역 (페이지네이션)
│   │   └── reservation_provider.dart    # - 스터디룸 예약 상태
│   │
│   ├── page/                        # 📱 화면 (페이지)
│   │   ├── dashboard_page.dart      #   - 메인 대시보드 (하단 탭 네비게이션)
│   │   ├── profile_settings_page.dart   # - 프로필 설정·수정
│   │   ├── login/
│   │   │   ├── login_page.dart          # - 로그인 화면
│   │   │   └── additional_info_page.dart # - 추가 정보 입력 (회원가입 후)
│   │   ├── course/
│   │   │   ├── course_search_page.dart  # - 강의 검색
│   │   │   └── course_wishlist_page.dart # - 찜한 강의 목록
│   │   ├── campus_navigation/
│   │   │   ├── campus_navigation_page.dart  # - 캠퍼스 길찾기
│   │   │   └── widgets/
│   │   │       ├── route_input_card.dart     #   - 출발지/경유지/도착지 입력
│   │   │       ├── route_result_card.dart    #   - 경로 탐색 결과 표시
│   │   │       └── map_visualization_card.dart # - 네이버 지도 오버레이 시각화
│   │   ├── scholarship/
│   │   │   ├── scholarship_page.dart         # - 장학금 목록
│   │   │   └── widgets/
│   │   │       ├── scholarship_card.dart     #   - 장학금 카드
│   │   │       ├── scholarship_info_card.dart #  - 장학금 상세 정보
│   │   │       └── scholarship_edit_dialog.dart # - 조건 편집 다이얼로그
│   │   ├── study_room/
│   │   │   ├── study_room_page.dart               # - 스터디룸 추천·예약
│   │   │   └── study_room_reservation_history_page.dart # - 예약 내역
│   │   └── lostitem/
│   │       ├── lost_found_page.dart           # - 분실물 게시판 (검색)
│   │       ├── lost_found_write_page.dart      # - 분실물 글 작성
│   │       ├── lost_found_post_detail_page.dart # - 게시글 상세 (댓글 포함)
│   │       └── lost_found_history_page.dart    # - 내 신고 내역
│   │
│   └── component/                   # 🧩 재사용 위젯
│       ├── common_widgets.dart      #   - 공통 위젯 (InfoRow 등)
│       ├── picker_option.dart       #   - 선택 옵션 UI
│       └── profile_row.dart         #   - 프로필 행 표시
│
├── pubspec.yaml                     # 프로젝트 메타데이터·의존성 정의
├── analysis_options.yaml            # 린트 규칙 설정
└── README.md                        # 이 문서
```

---

## 🌐 API

모든 API 서비스는 `lib/api/` 디렉터리에 위치하며, `http` 패키지를 통해 백엔드(`http://10.0.2.2:8000`)와 REST 통신합니다.
인증이 필요한 요청에는 `SharedPreferences`에 저장된 JWT 토큰을 `Authorization: Bearer <token>` 헤더로 포함합니다.

### 인증 (`auth_api.dart`)

| 메서드 | HTTP | 엔드포인트 | 설명 |
|--------|------|-----------|------|
| `login()` | `POST` | `/api/students/login` | 학번·비밀번호·학교ID로 로그인 |
| `submitAdditionalInfo()` | `POST` | `/api/students/info` | 회원가입 후 추가 정보 등록 (Multipart) |
| `updateUserInfo()` | `PUT` | `/api/students/info` | 프로필 정보 수정 (Multipart) 🔒 |
| `fetchUserInfo()` | `GET` | `/api/students/info` | 내 정보 조회 🔒 |
| `saveTokens()` | — | 로컬 | JWT 토큰 로컬 저장 |
| `isLoggedIn()` | — | 로컬 | 토큰 존재 여부 확인 |
| `logout()` | — | 로컬 | 토큰 삭제 |

### 강의 (`course_service.dart`)

| 메서드 | HTTP | 엔드포인트 | 설명 |
|--------|------|-----------|------|
| `search()` | `GET` | `/api/courses/?school_id=&search_type=&keyword=` | 강의 검색 (이름/교수/내용) |
| `autocomplete()` | — | *(mock — TODO 서버 연동)* | 검색 자동완성 |

### 찜 목록 (`wishlist_service.dart`)

| 메서드 | HTTP | 엔드포인트 | 설명 |
|--------|------|-----------|------|
| `toggleWishlist()` | `POST` | `/api/wishlist/toggle/` | 찜 추가/삭제 토글 🔒 |
| `fetchWishlist()` | `GET` | `/api/wishlist/` | 찜 강의 목록 조회 🔒 |
| `fetchWishlistIds()` | `GET` | `/api/wishlist/?limit=1000` | 찜 ID Set 동기화 🔒 |
| `removeFromWishlist()` | `DELETE` | `/api/wishlist/remove/<courseId>/` | 찜 삭제 🔒 |

### 장학금 (`scholarship_service.dart`)

| 메서드 | HTTP | 엔드포인트 | 설명 |
|--------|------|-----------|------|
| `fetch()` | `GET` | `/api/scholarships/?gpa=&income_bracket=&awarded_last_semester=` | 조건별 장학금 목록 조회 🔒 |

### 스터디룸 (`study_room_service.dart`)

| 메서드 | HTTP | 엔드포인트 | 설명 |
|--------|------|-----------|------|
| `recommend()` | `POST` | `/api/rooms/recommend/` | 조건 기반 스터디룸 추천 🔒 |
| `reserve()` | `POST` | `/api/rooms/reserve/` | 스터디룸 예약 🔒 |
| `fetchMyReservations()` | `GET` | `/api/rooms/reservations/` | 내 예약 내역 조회 🔒 |
| `cancelReservation()` | `DELETE` | `/api/rooms/reservations/<id>/` | 예약 취소 🔒 |

### 분실물 (`lost_found_service.dart`)

| 메서드 | HTTP | 엔드포인트 | 설명 |
|--------|------|-----------|------|
| `createPost()` | `POST` | `/api/lost-items` | 분실물 게시글 작성 (Multipart) 🔒 |
| `editItem()` | `PUT` | `/api/students/me/lost-items/<id>` | 게시글 수정 (Multipart) 🔒 |
| `search()` | `POST` | `/api/lost-items/search/` | 분실물 검색 🔒 |
| `nameSuggestions()` | `POST` | `/api/lost-items/suggestions/` | 검색어 자동완성 🔒 |
| `deletePost()` | `DELETE` | `/api/students/me/lost-items/<id>` | 게시글 삭제 🔒 |
| `getComments()` | `GET` | `/api/lost-items/<id>/comments/` | 댓글 목록 조회 🔒 |
| `createComment()` | `POST` | `/api/lost-items/<id>/comments/` | 댓글 작성 🔒 |
| `updateComment()` | `PUT` | `/api/comments/<id>/` | 댓글 수정 🔒 |
| `deleteComment()` | `DELETE` | `/api/comments/<id>/` | 댓글 삭제 🔒 |

### 캠퍼스 네비게이션 (`campus_navigation_service.dart`)

| 메서드 | HTTP | 엔드포인트 | 설명 |
|--------|------|-----------|------|
| `initialize()` | `GET` | `/api/campus/graph/` | 맵 데이터(노드·엣지·별칭) 초기화 |
| `findRoute()` | — | 클라이언트 로컬 | A* + Nearest Neighbor 경로 탐색 |
| `fetchNaverStaticMap()` | `GET` | Naver Static Maps API | 경로 시각화용 지도 이미지 |

> 🔒 = 인증 필요 (JWT Bearer Token)

---

## 📱 페이지 정의

### 앱 진입 흐름

```
main.dart
  └─ JWT 토큰 확인 (FutureBuilder)
       ├─ 토큰 유효 → MainDashboardPage (프로필 전달)
       ├─ 토큰 있으나 만료 → LoginPage (sessionExpired: true)
       └─ 토큰 없음 → LoginPage
```

### 주요 화면 목록

| 화면 | 파일 | 설명 |
|------|------|------|
| **로그인** | `page/login/login_page.dart` | 학번 + 비밀번호 로그인 (세션 만료 안내 지원) |
| **추가 정보 입력** | `page/login/additional_info_page.dart` | 회원가입 후 학과·학점·소득분위 등 추가 정보 및 프로필 사진 등록 |
| **메인 대시보드** | `page/dashboard_page.dart` | 하단 탭 네비게이션 허브 — 각 기능별 페이지 진입점 |
| **프로필 설정** | `page/profile_settings_page.dart` | 프로필 사진·학점·소득분위 등 개인정보 수정 |
| **강의 검색** | `page/course/course_search_page.dart` | 과목명·교수명·내용 검색 + 자동완성, 찜 토글 |
| **찜한 강의** | `page/course/course_wishlist_page.dart` | 내가 찜한 강의 목록 보기 및 관리 |
| **캠퍼스 길찾기** | `page/campus_navigation/campus_navigation_page.dart` | 출발지·경유지·도착지 입력 → 최적 경로 탐색 → 지도 시각화 |
| **장학금 조회** | `page/scholarship/scholarship_page.dart` | 내 조건(학점·소득분위 등)에 맞는 장학금 목록 필터링 및 조회 |
| **스터디룸 예약** | `page/study_room/study_room_page.dart` | 날짜·시간·인원·시설 조건으로 스터디룸 추천 및 예약 |
| **예약 내역** | `page/study_room/study_room_reservation_history_page.dart` | 내 스터디룸 예약 이력 확인 및 취소 |
| **분실물 게시판** | `page/lostitem/lost_found_page.dart` | 분실물 검색 (키워드 + 자동완성 + 유사도 표시) |
| **분실물 글 작성** | `page/lostitem/lost_found_write_page.dart` | 분실물 신고 (제목·카테고리·설명·사진 첨부) |
| **게시글 상세** | `page/lostitem/lost_found_post_detail_page.dart` | 게시글 상세보기 + 댓글 CRUD + 수정·삭제 |
| **내 신고 내역** | `page/lostitem/lost_found_history_page.dart` | 내가 작성한 분실물 게시글 목록 (페이지네이션) |

---

## 🔄 상태 관리 방법

**Riverpod** (`flutter_riverpod ^3.3.1`)을 사용하며, 앱 전체를 `ProviderScope`로 감쌉니다.

```dart
// main.dart
runApp(const ProviderScope(child: MyApp()));
```

### Provider 구조

| Provider | 파일 | 타입 | 역할 |
|----------|------|------|------|
| `authProvider` | `auth_provider.dart` | `StateNotifierProvider<AuthNotifier, AuthState>` | 로그인 상태 · 사용자 프로필 관리, 자동 로그인 체크 |
| `wishlistProvider` | `wishlist_provider.dart` | `StateNotifierProvider<WishlistNotifier, Set<int>>` | 찜한 강의 ID Set — Optimistic UI 적용 |
| `commentListProvider` | `comment_provider.dart` | `StateNotifierProvider.family<..., int>` | 게시글(itemId)별 독립 댓글 상태 관리 |
| `myLostItemsProvider` | `my_lost_items_provider.dart` | `NotifierProvider<MyLostItemsNotifier, MyLostItemsState>` | 내 분실물 신고 내역 (페이지네이션 + Optimistic CRUD) |
| `myLostItemsCountProvider` | `my_lost_items_provider.dart` | `NotifierProvider<MyLostItemsCountNotifier, int>` | 분실물 신고 총 개수 |
| `reservationProvider` | `reservation_provider.dart` | `StateNotifierProvider<ReservationNotifier, List<StudyRoomReservation>>` | 스터디룸 예약 목록 동기화·추가·취소 |

### 상태 관리 패턴

1. **StateNotifier / Notifier 기반**: 각 Provider는 불변 상태 객체를 관리하며 `copyWith` 패턴으로 상태를 갱신합니다.
2. **Optimistic UI**: `wishlistProvider`, `myLostItemsProvider` 등은 API 호출 전에 UI를 먼저 업데이트하고, 실패 시 롤백합니다.
3. **Family Provider**: `commentListProvider`는 `.family`를 사용하여 게시글 ID별로 독립된 상태를 관리합니다.
4. **자동 초기화**: Provider 최초 접근 시 `Future.microtask()`로 비동기 데이터를 자동 로드합니다.

---

## 🗃 데이터 모델

| 모델 | 파일 | 주요 필드 |
|------|------|-----------|
| `Student` | `user_profile.dart` | studentId, schoolId, loginId, name, major, gpa, incomeBracket, profileImg |
| `UserProfile` | `user_profile.dart` | name, department, studentId, grade, gpa?, incomeBracket?, profileImgUrl? |
| `Course` | `course_model.dart` | courseId, courseCode, courseName, professorId, dayOfWeek, startTime, endTime, majorTerm |
| `Professor` | `course_model.dart` | professorId, schoolId, name |
| `Scholarship` | `scholarship_model.dart` | scholarshipId, name, amount, requiredGpa, requiredIncomeBracket, deadline, applyUrl |
| `StudyRoom` | `study_room_model.dart` | roomId, placeId, name, capacity, facilities |
| `StudyRoomReservation` | `study_room_model.dart` | id, roomName, location, date, startHour, endHour |
| `RoomRecommendation` | `study_room_model.dart` | room, score, isAvailable, isMyReservation, bookedSlots |
| `LostItemPost` | `lost_found_model.dart` | itemId, title, category, description, imgFilePath, createTime, similarity, status |
| `Comment` | `lost_found_model.dart` | commentId, comment, isAnonymous |
| `School` | `route_model.dart` | schoolId, name |
| `Place` | `route_model.dart` | placeId, name, placeType, latitude, longitude |
| `RouteResult` | `route_model.dart` | orderedStops, totalDistanceM, segments |
| `WaypointResult` | `route_model.dart` | from, to, distanceM, path |

---

## 🧩 재사용 컴포넌트

| 위젯 | 파일 | 용도 |
|------|------|------|
| `CommonWidgets` | `component/common_widgets.dart` | 공통 InfoRow 등 범용 UI |
| `PickerOption` | `component/picker_option.dart` | 선택 옵션 UI |
| `ProfileRow` | `component/profile_row.dart` | 프로필 정보 행 표시 |
| `RouteInputCard` | `page/campus_navigation/widgets/route_input_card.dart` | 출발지·경유지·도착지 입력 폼 |
| `RouteResultCard` | `page/campus_navigation/widgets/route_result_card.dart` | 경로 결과 요약 카드 |
| `MapVisualizationCard` | `page/campus_navigation/widgets/map_visualization_card.dart` | 네이버 지도 위 경로 오버레이 |
| `ScholarshipCard` | `page/scholarship/widgets/scholarship_card.dart` | 장학금 리스트 항목 |
| `ScholarshipInfoCard` | `page/scholarship/widgets/scholarship_info_card.dart` | 장학금 상세 정보 |
| `ScholarshipEditDialog` | `page/scholarship/widgets/scholarship_edit_dialog.dart` | 장학금 필터 조건 편집 |

---

## ⚙️ 기타

### 캠퍼스 길찾기 알고리즘

`CampusNavigationService`는 Python(`campus_route.py`)에서 Dart로 이식한 경로 탐색 엔진입니다.

- **A\* 알고리즘**: SplayTreeSet 기반 우선순위 큐 + Haversine 거리 휴리스틱으로 최단 경로 탐색
- **Nearest Neighbor**: 경유지가 있을 때 탐욕 알고리즘으로 방문 순서를 최적화한 후 각 구간을 A*로 연결
- **네이버 Static Maps API**: 탐색 결과를 지도 이미지 위에 오버레이하여 시각화 (Mercator 투영 좌표 변환)

### 네트워크 설정

- 에뮬레이터 기본: `http://10.0.2.2:8000` (호스트 머신의 `localhost` 포워딩)
- 실기기 테스트 시: 각 Service 파일의 `baseUrl`을 서버 IP로 수정 필요

### 인증 플로우

```
앱 시작 → 토큰 존재 확인
  ├─ 토큰 있음 → fetchUserInfo() 호출
  │     ├─ 성공 → MainDashboardPage (프로필 주입)
  │     └─ 실패 → 토큰 삭제 → LoginPage (세션 만료 안내)
  └─ 토큰 없음 → LoginPage
```

### 코드 스타일 & 린트

- `analysis_options.yaml`에 정의된 `flutter_lints` 규칙을 따릅니다.
- 정적 분석: `flutter analyze`
