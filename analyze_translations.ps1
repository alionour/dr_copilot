# Extract all translation keys used in code and compare with en.json
$dartFiles = Get-ChildItem -Path "f:\Ali\Projects\alionour33\dr_copilot\lib" -Filter "*.dart" -Recurse
$keysUsed = @{}

foreach ($file in $dartFiles) {
    $content = Get-Content $file.FullName -Raw
    # Match 'key'.tr() and "key".tr()
    $matches = [regex]::Matches($content, "['`"]([^'`"]+)['`"]\.tr\(\)")
    foreach ($match in $matches) {
        $key = $match.Groups[1].Value
        if (-not $keysUsed.ContainsKey($key)) {
            $keysUsed[$key] = @()
        }
        $keysUsed[$key] += $file.FullName
    }
}

# Load en.json
$enJson = Get-Content "f:\Ali\Projects\alionour33\dr_copilot\assets\translations\en.json" -Raw | ConvertFrom-Json
$enKeys = $enJson.PSObject.Properties.Name

# Find missing keys
$missingKeys = @()
foreach ($key in $keysUsed.Keys) {
    if ($key -notin $enKeys) {
        $missingKeys += [PSCustomObject]@{
            Key = $key
            Files = $keysUsed[$key]
        }
    }
}

Write-Host "=== Translation Key Analysis ===" -ForegroundColor Cyan
Write-Host "Total unique keys used in code: $($keysUsed.Count)" -ForegroundColor Yellow
Write-Host "Total keys in en.json: $($enKeys.Count)" -ForegroundColor Yellow
Write-Host "Missing keys: $($missingKeys.Count)" -ForegroundColor $(if ($missingKeys.Count -gt 0) { 'Red' } else { 'Green' })

if ($missingKeys.Count -gt 0) {
    Write-Host "`nMissing Translation Keys:" -ForegroundColor Red
    $missingKeys | Sort-Object Key | ForEach-Object {
        Write-Host "  - $($_.Key)" -ForegroundColor Yellow
        Write-Host "    Used in: $($_.Files[0] | Split-Path -Leaf)" -ForegroundColor Gray
    }
    
    # Save to file
    $output = "# Missing Translation Keys`n`n"
    $output += "Total missing: $($missingKeys.Count)`n`n"
    $missingKeys | Sort-Object Key | ForEach-Object {
        $output += "- ``$($_.Key)```n"
        $output += "  - File: ``$($_.Files[0] | Split-Path -Leaf)```n`n"
    }
    $output | Out-File "C:\Users\Ali Nour\.gemini\antigravity\brain\a14ffafd-f8a7-4c96-bc64-0c0915950cbb\missing_keys.md" -Encoding UTF8
    Write-Host "`nReport saved to missing_keys.md" -ForegroundColor Green
}
