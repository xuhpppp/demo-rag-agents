#!/usr/bin/env bash
set -euo pipefail

CONTAINER_NAME="synthea_generator"
IMAGE="eclipse-temurin:17-jdk"
OUTPUT_DIR="$(cd "$(dirname "$0")/.." && pwd)/output"

echo "=== Starting Java container ==="
docker run -d --name "$CONTAINER_NAME" "$IMAGE" tail -f /dev/null

echo "=== Installing dependencies ==="
docker exec "$CONTAINER_NAME" bash -c "
  apt-get update && \
  apt-get install -y git libcommons-io-java
"

echo "=== Cloning Synthea ==="
docker exec "$CONTAINER_NAME" bash -c "
  git clone https://github.com/synthetichealth/synthea.git /synthea
"

echo "=== Enabling CSV export ==="
docker exec "$CONTAINER_NAME" bash -c "
  sed -i 's/^exporter\.csv\.export.*/exporter.csv.export = true/' /synthea/src/main/resources/synthea.properties
"

echo "=== Building Synthea ==="
docker exec "$CONTAINER_NAME" bash -c "
  cd /synthea && ./gradlew build check test
"

echo "=== Generating 1000 patients for New York ==="
docker exec "$CONTAINER_NAME" bash -c "
  cd /synthea && ./run_synthea -p 1000 'New York'
"

echo "=== Copying CSV output to host ==="
mkdir -p "$OUTPUT_DIR"
docker cp "$CONTAINER_NAME":/synthea/output/csv/. "$OUTPUT_DIR/"

echo "=== Destroying container ==="
docker rm -f "$CONTAINER_NAME"

echo "=== Done! CSV files are in: $OUTPUT_DIR ==="
