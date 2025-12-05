# Smart Clean Script for Dr. Copilot
# Cleans build artifacts but PRESERVES downloaded dependencies to save time

$buildDir = "build\windows"
$x64Dir = "$buildDir\x64"
$extractedDir = "$x64Dir\extracted"
$zipFile = "firebase_cpp_sdk_windows_12.7.0.zip"

Write-Host "🧹 Starting Smart Clean..." -ForegroundColor Cyan

if (Test-Path $buildDir) {
    # 1. Check if we have valuable downloads to save
    if (Test-Path $extractedDir) {
        Write-Host "📦 Found 'extracted' folder (dependencies). Preserving it..." -ForegroundColor Green
        
        # Move extracted folder to a temp location
        $tempDir = "temp_dependencies_backup"
        if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
        New-Item -ItemType Directory -Path $tempDir | Out-Null
        
        Move-Item -Path $extractedDir -Destination $tempDir
        
        # Check for the zip file too
        if (Test-Path "$x64Dir\$zipFile") {
            Move-Item -Path "$x64Dir\$zipFile" -Destination $tempDir
        }
        
        # 2. DELETE the build folder
        Write-Host "🗑️  Deleting corrupt build folder..." -ForegroundColor Yellow
        Remove-Item -Path $buildDir -Recurse -Force
        
        # 3. Restore dependencies
        Write-Host "♻️  Restoring dependencies..." -ForegroundColor Green
        New-Item -ItemType Directory -Path $x64Dir -Force | Out-Null
        
        Move-Item -Path "$tempDir\extracted" -Destination $x64Dir
        if (Test-Path "$tempDir\$zipFile") {
            Move-Item -Path "$tempDir\$zipFile" -Destination $x64Dir
        }
        
        Remove-Item $tempDir -Recurse -Force
        Write-Host "✅ Smart Clean Complete! Dependencies preserved." -ForegroundColor Cyan
    } else {
        Write-Host "⚠️  'extracted' folder not found. Doing normal clean." -ForegroundColor Yellow
        Remove-Item -Path $buildDir -Recurse -Force
    }
} else {
    Write-Host "Build folder already clean."
}

Write-Host "🚀 Starting Build..." -ForegroundColor Cyan
doppler run -- flutter run -d windows
