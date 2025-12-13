#!/usr/bin/env pwsh
# Google Play Auto-Deploy Verification Script
# Automates Part 4: Verify Configuration

Write-Host "`n🔍 Google Play Auto-Deploy Configuration Verification" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan

$allPassed = $true

# Step 15: Check Package Name
Write-Host "`n📦 Step 15: Checking Package Name..." -ForegroundColor Yellow
$buildGradle = "android\app\build.gradle"
if (Test-Path $buildGradle) {
    $packageName = Select-String -Path $buildGradle -Pattern 'applicationId\s+"([^"]+)"' | 
                   ForEach-Object { $_.Matches.Groups[1].Value }
    
    if ($packageName) {
        Write-Host "   ✅ Package name found: $packageName" -ForegroundColor Green
        
        # Check if it matches expected
        $expectedPackage = "com.alionour.drcopilot"
        if ($packageName -eq $expectedPackage) {
            Write-Host "   ✅ Package name matches workflow: $expectedPackage" -ForegroundColor Green
        } else {
            Write-Host "   ⚠️  Package name mismatch!" -ForegroundColor Red
            Write-Host "   Found: $packageName" -ForegroundColor Red
            Write-Host "   Expected: $expectedPackage" -ForegroundColor Red
            Write-Host "   Action: Update .github/workflows/deploy-android-dev.yaml" -ForegroundColor Yellow
            $allPassed = $false
        }
    } else {
        Write-Host "   ❌ Could not find applicationId in build.gradle" -ForegroundColor Red
        $allPassed = $false
    }
} else {
    Write-Host "   ❌ File not found: $buildGradle" -ForegroundColor Red
    $allPassed = $false
}

# Step 16: Verify Workflow File Exists
Write-Host "`n📄 Step 16: Checking Workflow File..." -ForegroundColor Yellow
$workflowFile = ".github\workflows\deploy-android-dev.yaml"
if (Test-Path $workflowFile) {
    Write-Host "   ✅ Workflow file exists: $workflowFile" -ForegroundColor Green
    
    # Check if package name in workflow matches
    $workflowContent = Get-Content $workflowFile -Raw
    if ($workflowContent -match 'packageName:\s+(\S+)') {
        $workflowPackage = $matches[1]
        Write-Host "   ✅ Workflow package name: $workflowPackage" -ForegroundColor Green
    }
} else {
    Write-Host "   ❌ Workflow file not found!" -ForegroundColor Red
    Write-Host "   Action: Workflow should have been created. Check previous steps." -ForegroundColor Yellow
    $allPassed = $false
}

# Step 17: Ensure Dev Branch Exists
Write-Host "`n🌿 Step 17: Checking Dev Branch..." -ForegroundColor Yellow
try {
    $branches = git branch -a 2>$null
    $devBranchLocal = $branches | Select-String "^\s*dev$"
    $devBranchRemote = $branches | Select-String "remotes/origin/dev"
    
    if ($devBranchLocal) {
        Write-Host "   ✅ Local dev branch exists" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Local dev branch not found" -ForegroundColor Yellow
    }
    
    if ($devBranchRemote) {
        Write-Host "   ✅ Remote dev branch exists (origin/dev)" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Remote dev branch not found" -ForegroundColor Yellow
        Write-Host "   Action: Create and push dev branch:" -ForegroundColor Yellow
        Write-Host "   git checkout -b dev" -ForegroundColor Cyan
        Write-Host "   git push origin dev" -ForegroundColor Cyan
        $allPassed = $false
    }
} catch {
    Write-Host "   ❌ Could not check git branches" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
    $allPassed = $false
}

# Check Doppler Secret
Write-Host "`n🔐 Bonus: Checking Doppler Secret..." -ForegroundColor Yellow
try {
    $dopplerCheck = doppler secrets get GOOGLE_PLAY_SERVICE_ACCOUNT_JSON --plain 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ GOOGLE_PLAY_SERVICE_ACCOUNT_JSON exists in Doppler" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Could not verify Doppler secret (might need to authenticate)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   ⚠️  Doppler CLI not available or not authenticated" -ForegroundColor Yellow
}

# Summary
Write-Host "`n" + ("=" * 60) -ForegroundColor Cyan
if ($allPassed) {
    Write-Host "✅ All verification checks passed!" -ForegroundColor Green
    Write-Host "`nNext Steps:" -ForegroundColor Cyan
    Write-Host "1. Wait 24-48 hours for Google Play permissions to propagate" -ForegroundColor White
    Write-Host "2. Then push to dev branch to trigger deployment:" -ForegroundColor White
    Write-Host "   git checkout dev" -ForegroundColor Cyan
    Write-Host "   git push origin dev" -ForegroundColor Cyan
} else {
    Write-Host "⚠️  Some verification checks failed" -ForegroundColor Yellow
    Write-Host "Please review the warnings and errors above" -ForegroundColor Yellow
}
Write-Host ""
