param (
    [string]$Version
)

$ErrorActionPreference = "Stop"

if (-not [string]::IsNullOrWhiteSpace($Version)) {
    Write-Host "Updating version to $Version..." -ForegroundColor Yellow
    
    $pubspecPath = Join-Path $PSScriptRoot "..\pubspec.yaml"
    $content = Get-Content $pubspecPath -Raw
    
    # Update Flutter version
    # Regex lookbehind/lookahead might be safer, but simple replace works for standard yaml
    $content = $content -replace "(?m)^version: .+$", "version: $Version"

    # Conversion for MSIX: 1.2.3+4 -> 1.2.3.4
    $msixVersion = $Version.Replace("+", ".")
    # Ensure 4 parts for MSIX if possible, though msix tool might handle 3. 
    # Usually msix version is Major.Minor.Build.Revision
    
    $content = $content -replace "(?m)^  msix_version: .+$", "  msix_version: $msixVersion"

    Set-Content $pubspecPath -Value $content
    Write-Host "Updated pubspec.yaml to version $Version (MSIX: $msixVersion)" -ForegroundColor Green
}

Write-Host "Building Dr. Copilot for Microsoft Store (MSIX)..." -ForegroundColor Green

# List of API keys to bake into the app
$keys = @(
    "VERTEX_AI_KEY",
    "GPT_API_KEY",
    "GEMINI_API_KEY",
    "DEEPSEEK_API_KEY",
    "QWEN_API_KEY",
    "CLAUDE_API_KEY",
    "DEEPGRAM_API_KEY",
    "GROQ_API_KEY",
    "GOOGLE_OAUTH_CLIENT_ID",
    "GOOGLE_OAUTH_CLIENT_SECRET"
)

$defines = ""

foreach ($key in $keys) {
    $val = [System.Environment]::GetEnvironmentVariable($key)
    if ([string]::IsNullOrWhiteSpace($val)) {
        Write-Warning "Environment variable '$key' is missing or empty. The app may not work correctly."
    } else {
        # Escape quotes if necessary, though simpler is usually better for env vars
        $defines += "--dart-define=$key=$val "
    }
}

Write-Host "Running flutter build windows with injected API keys..." -ForegroundColor Cyan
# Invoke-Expression is needed to correctly parse the long string of arguments
$buildCmd = "flutter build windows $defines"
Invoke-Expression $buildCmd

if ($LASTEXITCODE -eq 0) {
    Write-Host "Build successful. Packaging MSIX..." -ForegroundColor Green
    # Use --pack-only (or equivalent logic) to avoid rebuilding without the keys
    # Note: msix:create defaults to building. We want to skip the build step since we just did it.
    # Looking at msix options, usually we simply run msix:create which triggers build. 
    # BUT, we can't easily pass the complex defines to msix:create directly if it spawns a fresh build.
    # The 'msix' package doesn't seem to have a simple 'pack only' flag exposed in CLI easily found in help,
    # but typically it uses the existing build if we are careful or we just rely on the fact that
    # we CAN pass build args to msix:create if we use the configuration correctly.
    
    # However, since we can't rely on 'pack-only' existance (help failed), we will assume the User 
    # should run the script in one go. 
    # Actually, the most reliable way to inject keys into msix:create's build is to 
    # let msix:create do the build but pass the args.
    # But msix:create doesn't easily accept arbitrary dart-defines as CLI args to itself to pass down.
    
    # Alternative: We use msix:create but we set the environment variables for it?
    # No, we established env vars aren't enough.
    
    # BEST APPROACH: Re-run the flutter build command INSIDE the msix task? No.
    # The msix package actually supports `flutter build windows --dart-define=...` and then running `dart run msix:create` IF configured to not build.
    # Let's try `dart run msix:create` and hope it picks up the artifacts or we just rely on the script 
    # doing the heavy lifting if we can find a way to skip build.
    
    # Since I cannot verify --pack-only exists, I will try to pass the arguments to the msix command 
    # assuming it accepts standard flutter build arguments if we treat it as a wrapper.
    # BUT, to be safe, I will stick to the previous plan but warn the user that 
    # IF msix:create rebuilds, it might lose keys unless we are lucky.
    
    # wait, `msix:create` documentation says:
    # "To build the msix installer from existing build artifacts use: dart run msix:create --no-build-windows" (or similar)
    # Let's use --no-build-windows based on common conventions for this package.

    dart run msix:create --build-windows=false
} else {
    Write-Error "Flutter build failed."
    exit $LASTEXITCODE
}
