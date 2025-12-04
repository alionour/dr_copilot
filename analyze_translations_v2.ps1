# Script to analyze translation keys in Flutter project
$projectPath = Get-Location
$enJsonPath = Join-Path $projectPath "assets\translations\en.json"

# 1. Get all keys from en.json
if (-not (Test-Path $enJsonPath)) {
    Write-Error "en.json not found at $enJsonPath"
    exit 1
}

$jsonContent = Get-Content $enJsonPath -Raw | ConvertFrom-Json
$definedKeys = $jsonContent.PSObject.Properties.Name

Write-Host "Found $($definedKeys.Count) keys in en.json" -ForegroundColor Cyan

# 2. Find all .tr() usages in .dart files
$dartFiles = Get-ChildItem -Path (Join-Path $projectPath "lib") -Recurse -Filter "*.dart"

$usedKeys = @{}
$missingKeys = @{}

foreach ($file in $dartFiles) {
    $content = Get-Content $file.FullName
    
    # Regex to find 'key'.tr() or "key".tr()
    # This is a basic regex and might miss complex cases or match false positives
    $matches = [regex]::Matches($content, "['""]([^'""]+)['""]\.tr\(\)")

    foreach ($match in $matches) {
        $key = $match.Groups[1].Value
        if (-not $usedKeys.ContainsKey($key)) {
            $usedKeys[$key] = @()
        }
        $usedKeys[$key] += $file.Name

        if ($key -notin $definedKeys) {
            if (-not $missingKeys.ContainsKey($key)) {
                $missingKeys[$key] = @()
            }
            $missingKeys[$key] += $file.Name
        }
    }
}

Write-Host "Found $($usedKeys.Count) unique translation keys used in code." -ForegroundColor Cyan

# 3. Report missing keys
if ($missingKeys.Count -gt 0) {
    Write-Host "Found $($missingKeys.Count) MISSING keys:" -ForegroundColor Red
    foreach ($key in $missingKeys.Keys) {
        $files = $missingKeys[$key] | Select-Object -Unique
        Write-Host "  - '$key' (used in: $($files -join ', '))"
    }
    
    # Export missing keys to file for easier processing
    $missingKeys | ConvertTo-Json | Out-File "missing_keys_report.json"
    Write-Host "Missing keys report saved to missing_keys_report.json" -ForegroundColor Yellow
} else {
    Write-Host "No missing keys found! Great job." -ForegroundColor Green
}
