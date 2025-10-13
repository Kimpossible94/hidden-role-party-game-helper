# 히든 역할 파티 게임 도우미

히든 역할 파티 게임을 위한 Flutter 모바일 애플리케이션입니다. 플레이어 관리, 역할 배정, 라운드 타이머 등을 통해 게임 진행을 도와줍니다.

> **면책조항**: 이 앱은 히든 역할 파티 게임을 위한 도구입니다. 개인적인 학습 및 게임 진행 편의를 위해 제작되었습니다.

## 주요 기능

- **게임 생성 및 관리**: 진행자가 라운드별 시간을 커스터마이징하여 게임 생성
- **실시간 플레이어 관리**: 게임 ID로 플레이어 참여, 자동 방 균형 배치
- **역할 배정 시스템**: 자동 팀 및 역할 분배 (기본/확장 모드)
- **라운드 타이머 관리**: 라운드별 시간 설정 및 자동 진행
- **드래그 앤 드롭 인터페이스**: 진행자가 플레이어를 방 간 이동
- **리더 선출 시스템**: 투표 기반 리더십 및 탄핵 메커니즘
- **프라이버시 우선 설계**: 참가자 화면에서 역할 정보 보호

## 게임 진행 과정

1. **진행자가 게임 생성** → 라운드별 시간 설정으로 게임 ID 생성
2. **플레이어 참여** → 균형 잡힌 방에 자동 배치
3. **게임 시작** → 팀과 역할 무작위 배정
4. **라운드 관리** → 진행자가 타이밍 제어, 플레이어 이동 관리
5. **승리 조건 판정** → 폭탄범과 대통령의 최종 위치에 따른 승부 결정

## 설치 방법

### 필요한 준비물

- Flutter SDK (3.0+)
- Firebase 프로젝트
- Dart SDK

### Firebase 설정

이 앱은 실시간 멀티플레이어 기능을 위해 Firebase가 필요합니다:

1. **Firebase 프로젝트 생성**: [Firebase Console](https://console.firebase.google.com/)에서 프로젝트 생성

2. **Firestore Database 활성화**: Firebase 프로젝트에서 Firestore 데이터베이스 활성화

3. **Firebase 설정 파일 추가**:
   - `lib/firebase_options.dart`를 생성된 설정으로 교체
   - `android/app/google-services.json`을 Android 설정으로 교체
   - `ios/Runner/GoogleService-Info.plist`를 iOS 설정으로 교체

4. **Firebase 설정 생성**:
   ```bash
   # FlutterFire CLI 설치
   dart pub global activate flutterfire_cli

   # Firebase 프로젝트 설정
   flutterfire configure
   ```

**중요**: 현재 Firebase 파일들은 데모/플레이스홀더 키를 포함하고 있습니다. 실제 프로젝트 설정으로 교체해주세요.

**참고**: 실제 사용 시에는 자신만의 Firebase 프로젝트를 생성하여 설정 파일을 교체해야 합니다.

### 설치

```bash
# 저장소 클론
git clone <repository-url>
cd two_room_one_bomb

# 의존성 설치
flutter pub get

# 앱 실행
flutter run -d macos --debug  # macOS용
flutter run -d chrome --debug # 웹용
```

### 개발 명령어

```bash
# 정리 및 재빌드
flutter clean
flutter pub get

# 코드 분석
flutter analyze
flutter test

# 핫 리로드 (Flutter 터미널에서 'r' 키)
# 핫 리스타트 (Flutter 터미널에서 'R' 키)
```

## 아키텍처

### 핵심 컴포넌트

- **GameService**: Firebase 동기화를 통한 게임 상태 관리 싱글톤
- **게임 모델**: JSON 직렬화를 지원하는 Settings, Game, Player
- **화면 흐름**: 홈 → 진행자/참가자 → 게임 관리
- **실시간 업데이트**: 상태 동기화를 위한 Firebase 리스너

### 주요 게임 규칙

- **기본 모드** (6명 미만): 폭탄범 vs 대통령
- **확장 모드** (6명 이상): 특수 능력을 가진 전체 역할 세트
- **리더 제한**: 진행자가 리더를 방 간 이동시킬 수 없음
- **라운드 타이밍**: 라운드별 시간 설정 가능
- **승리 조건**: 폭탄범 + 대통령 같은 방 = 빨간팀 승리

## 테스트

개발 테스트를 위해서는 여러 기기나 브라우저 탭을 사용하여 실제 멀티플레이어 시나리오를 시뮬레이션해야 합니다. 앱의 실시간 Firebase 동기화는 실제 여러 클라이언트가 있어야 제대로 테스트할 수 있습니다.

## 기여하기

1. 저장소 포크
2. 기능 브랜치 생성
3. 변경사항 커밋
4. 브랜치에 푸시
5. Pull Request 생성

## 라이선스

이 프로젝트는 [MIT License](LICENSE) 하에 오픈소스로 제공됩니다.

## 게임 크레딧

이 앱은 히든 역할 파티 게임을 위한 도구입니다.
- 상업적 목적이 아닌 개인 학습 및 게임 진행 편의를 위해 제작되었습니다
