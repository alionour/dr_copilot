# PowerShell script to automate OAuth credential setup
# This script fetches OAuth credentials from Google Cloud and adds them to Doppler

$PROJECT_ID = "drcopilot-bfc9e"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "OAuth Credential Setup Automation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if gcloud is installed
Write-Host "Checking for gcloud CLI..." -ForegroundColor Yellow
if (-not (Get-Command gcloud -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: gcloud CLI not found!" -ForegroundColor Red
    Write-Host "Please install: https://cloud.google.com/sdk/docs/install" -ForegroundColor Red
    Write-Host ""
    Write-Host "Quick install (Windows):" -ForegroundColor Yellow
    Write-Host "  (New-Object Net.WebClient).DownloadFile('https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe', '.\GoogleCloudSDKInstaller.exe')" -ForegroundColor Gray
    Write-Host "  .\GoogleCloudSDKInstaller.exe" -ForegroundColor Gray
    exit 1
}

Write-Host "✓ gcloud CLI found" -ForegroundColor Green
Write-Host ""

# Set project
Write-Host "Setting project to $PROJECT_ID..." -ForegroundColor Yellow
gcloud config set project $PROJECT_ID

# Check if user is authenticated
Write-Host ""
Write-Host "Checking authentication..." -ForegroundColor Yellow
$authCheck = gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Not authenticated. Running gcloud auth login..." -ForegroundColor Yellow
    gcloud auth login
}

Write-Host "✓ Authenticated" -ForegroundColor Green
Write-Host ""

# List existing OAuth clients
Write-Host "Fetching OAuth clients..." -ForegroundColor Yellow
Write-Host ""
Write-Host "Looking for existing Web application OAuth clients..." -ForegroundColor Cyan

# Get OAuth client credentials
# Note: gcloud doesn't directly expose OAuth client secrets via CLI
# We need to use the credentials file if it exists

$CREDENTIALS_DIR = "$env:USERPROFILE\.config\gcloud\legacy_credentials"

Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "MANUAL STEP REQUIRED" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "Unfortunately, Google Cloud CLI doesn't support retrieving OAuth client secrets." -ForegroundColor Red
Write-Host "You need to download the credentials manually:" -ForegroundColor Yellow
Write-Host ""
Write-Host "Option 1: Download from Console" -ForegroundColor Cyan
Write-Host "  1. Go to: https://console.cloud.google.com/apis/credentials?project=$PROJECT_ID" -ForegroundColor Gray
Write-Host "  2. Click on an existing Web client" -ForegroundColor Gray
Write-Host "  3. Click 'Download JSON' (⬇️ icon)" -ForegroundColor Gray
Write-Host "  4. Save as 'google_oauth_credentials.json' in this directory" -ForegroundColor Gray
Write-Host ""
Write-Host "Option 2: Paste Credentials Manually" -ForegroundColor Cyan
Write-Host "  Just paste the Client ID and Secret when prompted below" -ForegroundColor Gray
Write-Host ""

# Prompt for credentials
$choice = Read-Host "Do you have the credentials? (1=Downloaded JSON, 2=Will paste manually)"

if ($choice -eq "1") {
    # Look for downloaded JSON file
    $jsonPath = ".\google_oauth_credentials.json"
    if (-not (Test-Path $jsonPath)) {
        $jsonPath = Read-Host "Enter path to downloaded JSON file"
    }
    
    if (Test-Path $jsonPath) {
        $creds = Get-Content $jsonPath | ConvertFrom-Json
        $clientId = $creds.web.client_id
        $clientSecret = $creds.web.client_secret
        
        Write-Host ""
        Write-Host "✓ Loaded credentials from JSON" -ForegroundColor Green
    } else {
        Write-Host "File not found!" -ForegroundColor Red
        exit 1
    }
} elseif ($choice -eq "2") {
    Write-Host ""
    $clientId = Read-Host "Paste Client ID"
    $clientSecret = Read-Host "Paste Client Secret" -AsSecureString
    $clientSecret = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($clientSecret)
    )
} else {
    Write-Host "Invalid choice!" -ForegroundColor Red
    exit 1
}

# Validate credentials
if ([string]::IsNullOrWhiteSpace($clientId) -or [string]::IsNullOrWhiteSpace($clientSecret)) {
    Write-Host "ERROR: Invalid credentials!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Client ID: $clientId" -ForegroundColor Cyan
Write-Host "Client Secret: $($clientSecret.Substring(0, 10))..." -ForegroundColor Cyan
Write-Host ""

# Check if Doppler is installed
Write-Host "Checking for Doppler CLI..." -ForegroundColor Yellow
if (-not (Get-Command doppler -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Doppler CLI not found!" -ForegroundColor Red
    Write-Host "Please install: https://docs.doppler.com/docs/install-cli" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Doppler CLI found" -ForegroundColor Green
Write-Host ""

# Add to Doppler
Write-Host "Adding credentials to Doppler..." -ForegroundColor Yellow
Write-Host ""

doppler secrets set GOOGLE_OAUTH_CLIENT_ID="$clientId" --silent
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ GOOGLE_OAUTH_CLIENT_ID added to Doppler" -ForegroundColor Green
} else {
    Write-Host "✗ Failed to add Client ID" -ForegroundColor Red
    exit 1
}

doppler secrets set GOOGLE_OAUTH_CLIENT_SECRET="$clientSecret" --silent
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ GOOGLE_OAUTH_CLIENT_SECRET added to Doppler" -ForegroundColor Green
} else {
    Write-Host "✗ Failed to add Client Secret" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "✓ OAuth credentials configured!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next step: Run the OAuth setup tool to get refresh token" -ForegroundColor Cyan
Write-Host "  doppler run -- dart run tools/oauth_setup.dart" -ForegroundColor Gray
Write-Host ""
