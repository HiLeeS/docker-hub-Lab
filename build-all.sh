#!/bin/bash
# =============================================================
# Docker 이미지 최적화 단계별 빌드 & 비교 스크립트
# =============================================================
# 사용법: chmod +x build-all.sh && ./build-all.sh
# =============================================================

set -e

echo "============================================="
echo " Docker 이미지 최적화 단계별 빌드"
echo "============================================="
echo ""

DOCKERFILES=(
    "Dockerfile.1-basic:demo-1-basic:1. 기본형 (JDK 단일 스테이지)"
    "Dockerfile.2-multistage:demo-2-multistage:2. 멀티스테이지 (builder+runtime 분리)"
    "Dockerfile.3-jre:demo-3-jre:3. JRE 경량화 (JRE slim)"
    "Dockerfile.4-distroless:demo-4-distroless:4. distroless (운영 최소 이미지)"
    "Dockerfile.5-buildkit:demo-5-buildkit:5. BuildKit 캐시 (빌드 속도 최적화)"
)

for entry in "${DOCKERFILES[@]}"; do
    IFS=':' read -r dockerfile tag description <<< "$entry"

    echo "---------------------------------------------"
    echo " $description"
    echo " 파일: $dockerfile"
    echo "---------------------------------------------"

    SECONDS=0
    DOCKER_BUILDKIT=1 docker build -f "$dockerfile" -t "$tag" . 2>&1
    elapsed=$SECONDS

    echo ""
    echo "  → 빌드 시간: ${elapsed}초"
    echo ""
done

echo ""
echo "============================================="
echo " 이미지 크기 비교"
echo "============================================="
echo ""

printf "%-40s %s\n" "이미지" "크기"
printf "%-40s %s\n" "----------------------------------------" "----------"

for entry in "${DOCKERFILES[@]}"; do
    IFS=':' read -r dockerfile tag description <<< "$entry"
    size=$(docker images "$tag" --format "{{.Size}}" 2>/dev/null || echo "빌드 안됨")
    printf "%-40s %s\n" "$tag" "$size"
done

echo ""
echo "============================================="
echo " 실행 방법"
echo "============================================="
echo ""
echo "  docker run -p 8080:8080 demo-5-buildkit"
echo ""
echo "  테스트:"
echo "    curl http://localhost:8080/api/health"
echo "    curl http://localhost:8080/api/hello?name=Docker"
echo "    curl -X POST http://localhost:8080/api/messages -H 'Content-Type: application/json' -d '{\"content\":\"hello\"}'"
echo "    curl http://localhost:8080/api/messages"
echo ""
