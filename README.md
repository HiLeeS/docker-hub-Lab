# Docker 이미지 최적화 데모

Spring Boot REST API 앱을 기반으로, Docker 이미지 최적화 단계를 5가지 Dockerfile로 비교합니다.

## 프로젝트 구조

```
docker-optimization-demo/
├── src/main/java/com/example/demo/
│   ├── DemoApplication.java
│   └── controller/
│       └── HelloController.java
├── src/main/resources/
│   └── application.properties
├── build.gradle
├── settings.gradle
├── .dockerignore
├── Dockerfile.1-basic          # 기본형: JDK 단일 스테이지
├── Dockerfile.2-multistage     # 멀티스테이지: builder + runtime 분리
├── Dockerfile.3-jre            # JRE 경량화: JRE slim 교체
├── Dockerfile.4-distroless     # distroless: 운영 최소 이미지
├── Dockerfile.5-buildkit       # BuildKit 캐시: 빌드 속도 최적화
├── build-all.sh                # 전체 빌드 & 비교 스크립트
└── README.md
```

## 최적화 흐름 요약

| 단계 | Dockerfile | 핵심 변경 | 예상 크기 | 감소율 |
|------|------------|-----------|-----------|--------|
| 1 | basic | JDK + 소스 + 캐시 전부 포함 | ~700MB | - |
| 2 | multistage | builder/runtime 분리, 빌드 산출물만 복사 | ~450MB | ~35% |
| 3 | jre | 런타임을 JDK → JRE로 교체 | ~300MB | ~57% |
| 4 | distroless | 셸/패키지매니저 없는 최소 이미지 | ~230MB | ~67% |
| 5 | buildkit | 4번 + Gradle 캐시 마운트로 빌드 속도 개선 | ~230MB | ~67% |

## 초기 세팅 (필수)

프로젝트에는 Gradle Wrapper 바이너리(`gradle-wrapper.jar`)가 포함되어 있지 않습니다.
로컬에 Gradle이 설치되어 있다면 아래 명령으로 Wrapper를 생성하세요:

```bash
# 프로젝트 루트에서 실행
gradle wrapper --gradle-version 8.10
```

Gradle이 없다면 [SDKMAN](https://sdkman.io/)으로 설치할 수 있습니다:
```bash
sdk install gradle 8.10
gradle wrapper --gradle-version 8.10
```

이후 `gradlew`, `gradlew.bat`, `gradle/wrapper/gradle-wrapper.jar`가 생성됩니다.

## 빌드 방법

### 전체 빌드 & 비교
```bash
chmod +x build-all.sh
./build-all.sh
```

### 개별 빌드
```bash
# 기본형
docker build -f Dockerfile.1-basic -t demo-1-basic .

# 멀티스테이지
docker build -f Dockerfile.2-multistage -t demo-2-multistage .

# JRE 경량화
docker build -f Dockerfile.3-jre -t demo-3-jre .

# distroless
docker build -f Dockerfile.4-distroless -t demo-4-distroless .

# BuildKit 캐시 (BuildKit 필수)
DOCKER_BUILDKIT=1 docker build -f Dockerfile.5-buildkit -t demo-5-buildkit .
```

## 실행 & 테스트

```bash
docker run -p 8080:8080 demo-5-buildkit
```

```bash
# 헬스체크 (JVM 정보, 메모리 등 확인 가능)
curl http://localhost:8080/api/health

# 인사
curl http://localhost:8080/api/hello?name=Docker

# 메시지 등록
curl -X POST http://localhost:8080/api/messages \
  -H 'Content-Type: application/json' \
  -d '{"content":"hello"}'

# 메시지 조회
curl http://localhost:8080/api/messages
```

## API 목록

| Method | Path | 설명 |
|--------|------|------|
| GET | `/api/health` | 헬스체크 (Java 버전, OS, 메모리 정보) |
| GET | `/api/hello?name=xxx` | 인사 메시지 |
| POST | `/api/messages` | 메시지 등록 (`{"content":"..."}`) |
| GET | `/api/messages` | 메시지 전체 조회 |

## 각 단계별 트레이드오프

### 1. 기본형
- **장점**: 단순함, 디버깅 편리 (JDK 도구 모두 사용 가능)
- **단점**: 이미지 크기 최대, 소스코드/빌드캐시 노출

### 2. 멀티스테이지
- **장점**: 소스코드 제거, 빌드 도구 분리
- **단점**: Dockerfile 복잡도 약간 증가

### 3. JRE 경량화
- **장점**: 컴파일러/개발도구 제거로 크기 감소
- **단점**: jmap, jstack 등 JDK 진단 도구 사용 불가

### 4. distroless
- **장점**: 최소 공격 표면, 비root 기본 실행, glibc 호환
- **단점**: 셸 없음 → docker exec 디버깅 불가, 환경변수 치환 불가

### 5. BuildKit 캐시
- **장점**: 재빌드 시 의존성 다운로드 스킵, 빌드 시간 대폭 단축
- **단점**: BuildKit 필수, 로컬/CI 캐시 설정 필요
