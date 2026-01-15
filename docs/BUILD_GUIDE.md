# Android APK 빌드 가이드

이 문서는 Commitime 앱을 Android APK로 빌드하는 과정과 트러블슈팅을 다룹니다.

## 사전 요구사항

| 항목 | 버전 | 확인 명령어 |
|------|------|------------|
| Flutter SDK | >=3.0.0 | `flutter --version` |
| Android SDK | - | `flutter doctor` |
| Java | 17+ | `java --version` |

## 빌드 명령어

```bash
# Debug APK 빌드
flutter build apk --debug

# Release APK 빌드
flutter build apk --release
```

### 빌드 결과물 위치

```
build/app/outputs/flutter-apk/
├── app-debug.apk      # Debug 빌드
└── app-release.apk    # Release 빌드
```

### Finder에서 열기 (macOS)

```bash
open build/app/outputs/flutter-apk/
```

---

## 트러블슈팅

### 1. Android SDK를 찾을 수 없음

**에러 메시지:**
```
[!] No Android SDK found. Try setting the ANDROID_HOME environment variable.
```

**해결 방법:**

#### 방법 A: Android Studio 설치 (권장)
1. [Android Studio 다운로드](https://developer.android.com/studio)
2. 설치 후 실행하면 SDK 자동 설치
3. 터미널 재시작

#### 방법 B: Command Line Tools만 설치
```bash
# Homebrew로 설치
brew install --cask android-commandlinetools

# 환경 변수 설정 (~/.zshrc에 추가)
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools

# 필수 SDK 설치
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

# 라이센스 동의
flutter doctor --android-licenses
```

---

### 2. Core Library Desugaring 오류

**에러 메시지:**
```
Execution failed for task ':app:checkDebugAarMetadata'.
> Dependency ':flutter_local_notifications' requires core library desugaring to be enabled for :app.
```

**원인:**
- `flutter_local_notifications` 등 일부 라이브러리가 Java 8 API를 사용
- 구형 Android 기기 호환을 위해 desugaring 필요

**해결 방법:**

`android/app/build.gradle.kts` 파일 수정:

```kotlin
android {
    // ...

    compileOptions {
        isCoreLibraryDesugaringEnabled = true  // 이 줄 추가
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // ...
}

// dependencies 블록 추가 (버전 2.1.4 이상 권장)
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```

---

### 3. Desugaring 라이브러리 버전 오류

**에러 메시지:**
```
Dependency ':flutter_local_notifications' requires desugar_jdk_libs version to be
2.1.4 or above for :app, which is currently 2.0.4
```

**원인:**
- `flutter_local_notifications` v19+는 더 높은 버전의 desugaring 라이브러리 필요

**해결 방법:**

`android/app/build.gradle.kts`에서 버전 업그레이드:

```kotlin
dependencies {
    // 2.0.4 → 2.1.4로 변경
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```

---

### 4. flutter_local_notifications 컴파일 오류

**에러 메시지:**
```
error: reference to bigLargeIcon is ambiguous
    bigPictureStyle.bigLargeIcon(null);
    both method bigLargeIcon(Bitmap) and method bigLargeIcon(Icon) match
```

**원인:**
- `flutter_local_notifications` 16.x 버전이 최신 Android SDK와 호환되지 않음

**해결 방법:**

`pubspec.yaml`에서 라이브러리 버전 업그레이드:

```yaml
dependencies:
  # 16.x → 19.x로 업그레이드
  flutter_local_notifications: ^19.0.0
  timezone: ^0.10.0
```

그 후 의존성 업데이트:
```bash
flutter pub get
```

---

### 5. Gradle 빌드가 너무 오래 걸림

**첫 번째 빌드 예상 시간:**

| 단계 | 시간 |
|------|------|
| Gradle 다운로드 | 1~3분 |
| 의존성 다운로드 | 2~5분 |
| 컴파일 | 2~5분 |
| **총합** | **5~15분** |

**두 번째 빌드부터:**
- 코드 변경 후: 30초 ~ 2분
- 클린 빌드 (`flutter clean` 후): 3~5분

**빌드 속도 개선:**
```bash
# 불필요한 캐시 정리
flutter clean

# 의존성 다시 받기
flutter pub get

# 빌드
flutter build apk --debug
```

---

## USB 없이 APK 설치하기

USB 연결이 불가능한 경우:

### Google Drive 사용
1. `app-debug.apk` 파일을 Google Drive에 업로드
2. 폰에서 Google Drive 앱으로 다운로드
3. APK 파일 탭하여 설치

### 폰 설정 (필수)
APK 설치 전 폰에서 허용 필요:
```
설정 → 보안 → "출처를 알 수 없는 앱 설치" 허용
(또는: 설정 → 앱 → 특별한 앱 액세스 → 출처를 알 수 없는 앱 설치)
```

---

## Java 버전 이해하기

### Android의 Java 버전 구조

| 구분 | 버전 | 설명 |
|------|------|------|
| 컴파일러 | Java 17 | 코드를 빌드할 때 사용 |
| 런타임 | Java 8 수준 | Android 기기에서 실행되는 API |

### Desugaring이란?

```
Java 8+ 문법/API  →  Desugaring 변환  →  구형 Android 호환 코드
```

- `LocalDateTime`, `Stream API` 같은 Java 8 기능을
- Android 7 이하 기기에서도 사용 가능하게 변환

---

## 유용한 명령어

```bash
# Flutter 환경 진단
flutter doctor

# 연결된 디바이스 확인
flutter devices

# 캐시 정리
flutter clean

# 의존성 재설치
flutter pub get

# 오래된 패키지 확인
flutter pub outdated

# 디버그 빌드
flutter build apk --debug

# 릴리즈 빌드
flutter build apk --release
```

---

## 버전 호환성 참고

이 프로젝트에서 확인된 호환 버전:

| 패키지 | 권장 버전 | 비고 |
|--------|----------|------|
| flutter_local_notifications | ^19.0.0 | v16은 Android SDK 호환 문제 |
| timezone | ^0.10.0 | notifications와 함께 업그레이드 |
| desugar_jdk_libs | 2.1.4+ | v19 notifications 요구사항 |
