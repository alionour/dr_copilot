#!/usr/bin/env pwsh
# Script to extract secrets from Doppler and prepare for GitHub Secrets
# Run this locally where Doppler is authenticated

Write-Host "`n📦 Extracting Secrets from Doppler" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan

# Required secrets for GitHub Actions
$secrets = @(
    "ANDROID_KEYSTORE_BASE64",
    "ANDROID_KEYSTORE_PASSWORD",
    "ANDROID_KEY_PASSWORD",
    "ANDROID_KEY_ALIAS",
    "GOOGLE_PLAY_SERVICE_ACCOUNT_JSON"
)

Write-Host "`nExtracting secrets..." -ForegroundColor Yellow

foreach ($secret in $secrets) {
    try {
        $value = doppler secrets get $secret --plain 2>$null
        if ($LASTEXITCODE -eq 0) {
            $length = $value.Length
            if ($length -gt 50) {
                $preview = "$($value.Substring(0, 30))...(truncated)"
            } else {
                $preview = $value
            }
            Write-Host "  ✅ $secret ($length chars)" -ForegroundColor Green
            
            # Save to temp file for easier copying
            $value | Out-File -FilePath "temp_$secret.txt" -NoNewline -Encoding UTF8
        } else {
            Write-Host "  ❌ $secret not found" -ForegroundColor Red
        }
    } catch {
        Write-Host "  ❌ $secret failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n" + ("=" * 60) -ForegroundColor Cyan
Write-Host "✅ Secrets extracted to temp files!" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. Go to: https://github.com/alionour/dr_copilot/settings/secrets/actions" -ForegroundColor White
Write-Host "2. Click 'New repository secret' for each:" -ForegroundColor White

foreach ($secret in $secrets) {
    if (Test-Path "temp_$secret.txt") {
        Write-Host "   - $secret (value in temp_$secret.txt)" -ForegroundColor Yellow
    }
}

Write-Host "`n⚠️  Remember to delete temp_*.txt files after adding to GitHub!" -ForegroundColor Yellow
Write-Host ""
