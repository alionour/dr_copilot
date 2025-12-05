# Google Cloud Setup Script for Dr. Copilot
# Usage: ./setup_gcp.ps1 [PROJECT_ID]

param (
    [string]$ProjectId = "drcopilot-bfc9e"
)

Write-Host "Setting up Google Cloud Project: $ProjectId" -ForegroundColor Cyan

# 1. Create Project (Skip if exists)
Write-Host "1. Checking Project..."
$projectExists = cmd /c "gcloud projects describe $ProjectId 2>&1"
if ($LASTEXITCODE -eq 0) {
    Write-Host "Project $ProjectId already exists. Using it." -ForegroundColor Green
} else {
    Write-Host "Creating Project $ProjectId..."
    cmd /c "gcloud projects create $ProjectId --name='Dr Copilot Docs'"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to create project. Please ensure you are logged in and the ID is unique." -ForegroundColor Red
        exit 1
    }
}

# 2. Set Current Project
Write-Host "2. Setting current project..."
cmd /c "gcloud config set project $ProjectId"

# 3. Enable APIs
Write-Host "3. Enabling APIs (this may take a minute)..."
cmd /c "gcloud services enable docs.googleapis.com drive.googleapis.com"

# 4. Create Service Account
Write-Host "4. Creating Service Account..."
$ServiceAccountName = "dr-copilot-sa"
cmd /c "gcloud iam service-accounts create $ServiceAccountName --display-name='Dr Copilot Service Account'"

# 5. Generate Key
Write-Host "5. Generating Key..."
$KeyPath = "assets/google_credentials.json"
$ServiceAccountEmail = "$ServiceAccountName@$ProjectId.iam.gserviceaccount.com"

# Ensure assets directory exists
if (-not (Test-Path "assets")) {
    New-Item -ItemType Directory -Force -Path "assets"
}

cmd /c "gcloud iam service-accounts keys create $KeyPath --iam-account=$ServiceAccountEmail"

if (Test-Path $KeyPath) {
    Write-Host "Success! Credentials saved to $KeyPath" -ForegroundColor Green
    Write-Host "Project ID: $ProjectId" -ForegroundColor Green
    Write-Host "Service Account: $ServiceAccountEmail" -ForegroundColor Green
} else {
    Write-Host "Failed to save credentials." -ForegroundColor Red
}
