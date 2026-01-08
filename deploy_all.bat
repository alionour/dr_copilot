@echo off
echo ===================================================
echo Dr. Copilot - Automated Deployment ^& Migration
echo ===================================================

echo [1/3] Deploying Firestore Security Rules...
call firebase deploy --only firestore:rules
if %errorlevel% neq 0 (
    echo [ERROR] Firestore rules deployment failed.
    exit /b %errorlevel%
)

echo.
echo [2/3] Running Permissions Migration Script...
cd backend
echo Running migration script...
call node migrate-kiosk-permissions.js
if %errorlevel% neq 0 (
  echo [WARNING] Migration script failed. This might be due to missing credentials.
  echo Please ensure 'FIREBASE_SERVICE_ACCOUNT' is set or key file exists.
  echo Continuing...
)

echo.
echo [3/3] Deploying Backend Server...
echo This requires environment variables (FIREBASE_SERVICE_ACCOUNT, etc.) to be set.
echo If this fails, try running with your secrets manager (e.g., doppler run -- deploy_all.bat)
call npx sls deploy
if %errorlevel% neq 0 (
    echo [ERROR] Backend deployment failed.
    exit /b %errorlevel%
)

echo.
echo ===================================================
echo   Deployment Complete!
echo ===================================================
pause
