# PowerShell script to set up Firestore data for tester account
# Prerequisites: Firebase CLI installed (npm install -g firebase-tools)
# Run: ./setup_tester_data.ps1

Write-Host "Setting up Firestore data for tester account..." -ForegroundColor Cyan

$TESTER_UID = "6QEq5hMazPaegl2rGwulSgGdXPw1"
$CLINIC_ID = "test_clinic_001"

# Check if Firebase CLI is installed
if (!(Get-Command firebase -ErrorAction SilentlyContinue)) {
    Write-Host "Error: Firebase CLI not found. Install with: npm install -g firebase-tools" -ForegroundColor Red
    exit 1
}

Write-Host "Creating Firestore documents..." -ForegroundColor Yellow

# Note: You'll need to run these commands manually in Firebase Console or use firestore-import tool
# This script generates the JSON structure for manual import

$userData = @{
    uid = $TESTER_UID
    email = "drcopilot.test@gmail.com"
    displayName = "Dr. Copilot Tester"
    primaryClinicId = $CLINIC_ID
    clinicIds = @($CLINIC_ID)
    clinics = @(
        @{
            clinicId = $CLINIC_ID
            role = "admin"
        }
    )
    ownerId = $TESTER_UID
} | ConvertTo-Json -Depth 10

$clinicData = @{
    name = "Dr. Copilot Test Clinic"
    ownerId = $TESTER_UID
    address = "Cairo, Egypt"
    phone = "+201234567890"
} | ConvertTo-Json -Depth 10

$memberData = @{
    role = "admin"
    permissions = @("viewAllPatients", "editPatients", "deletePatients", "addPatients")
    uid = $TESTER_UID
    email = "drcopilot.test@gmail.com"
   displayName = "Dr. Copilot Tester"
} | ConvertTo-Json -Depth 10

Write-Host "`nUser Document (users/$TESTER_UID):" -ForegroundColor Green
Write-Host $userData

Write-Host "`nClinic Document (clinics/$CLINIC_ID):" -ForegroundColor Green
Write-Host $clinicData

Write-Host "`nMember Document (clinics/$CLINIC_ID/members/$TESTER_UID):" -ForegroundColor Green
Write-Host $memberData

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "MANUAL STEPS:" -ForegroundColor Yellow
Write-Host "1. Go to Firebase Console > Firestore Database"
Write-Host "2. Create the above documents manually, or"
Write-Host "3. Use the Node.js setup script: node setup_tester_firestore.js"
Write-Host "==================================================" -ForegroundColor Cyan
