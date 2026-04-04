$ErrorActionPreference = "Stop"

$ContainerName = "synthea_generator"
$Image = "eclipse-temurin:17-jdk"
$OutputDir = Join-Path (Split-Path $PSScriptRoot) "output"

Write-Host "=== Starting Java container ==="
docker run -d --name $ContainerName $Image tail -f /dev/null

Write-Host "=== Installing dependencies ==="
docker exec $ContainerName bash -c @"
apt-get update && apt-get install -y git libcommons-io-java
"@

Write-Host "=== Cloning Synthea ==="
docker exec $ContainerName bash -c @"
git clone https://github.com/synthetichealth/synthea.git /synthea
"@

Write-Host "=== Enabling CSV export ==="
docker exec $ContainerName bash -c @"
sed -i 's/^exporter\.csv\.export.*/exporter.csv.export = true/' /synthea/src/main/resources/synthea.properties
"@

Write-Host "=== Building Synthea ==="
docker exec $ContainerName bash -c @"
cd /synthea && ./gradlew build check test
"@

Write-Host "=== Generating 1000 patients for New York ==="
docker exec $ContainerName bash -c @"
cd /synthea && ./run_synthea -p 1000 'New York'
"@

Write-Host "=== Copying CSV output to host ==="
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}
docker cp "${ContainerName}:/synthea/output/csv/." "$OutputDir/"

Write-Host "=== Destroying container ==="
docker rm -f $ContainerName

Write-Host "=== Done! CSV files are in: $OutputDir ==="
