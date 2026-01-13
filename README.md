# Commitime

캐릭터 기반 잔소리 메시지로 목표 달성을 돕는 알람 앱

## 환경 설정

### 요구 사항

- Flutter SDK: `>=3.0.0 <4.0.0`
- Dart SDK: `>=3.0.0`

### Flutter 설치

1. [Flutter 공식 문서](https://docs.flutter.dev/get-started/install)에서 OS에 맞는 Flutter SDK 다운로드
2. 환경 변수 설정
3. 설치 확인:
   ```bash
   flutter doctor
   ```

### 프로젝트 설정

```bash
# 저장소 클론
git clone https://github.com/koo-ys/commitime.git
cd commitime

# 의존성 설치
flutter pub get

# 앱 실행
flutter run
```

### 실행 가능 플랫폼

| 플랫폼 | 명령어 | 비고 |
|-------|--------|------|
| Android | `flutter run -d android` | Android Studio 또는 에뮬레이터 필요 |
| iOS | `flutter run -d ios` | Xcode 필요 (macOS만) |
| Web | `flutter run -d chrome` | Chrome 브라우저 필요 |
| macOS | `flutter run -d macos` | Xcode 필요 |
| Windows | `flutter run -d windows` | Visual Studio 필요 |
| Linux | `flutter run -d linux` | - |

### 주요 의존성

| 패키지 | 용도 |
|--------|------|
| provider | 상태 관리 |
| sqflite | 로컬 데이터베이스 |
| flutter_local_notifications | 로컬 알림 |
| table_calendar | 캘린더 UI |
| google_fonts | 폰트 |

## 프로젝트 구조

```
lib/
├── main.dart              # 앱 진입점
├── models/                # 데이터 모델
├── providers/             # 상태 관리
├── screens/               # 화면 UI
├── services/              # 비즈니스 로직
├── utils/                 # 유틸리티
└── widgets/               # 재사용 위젯
```
