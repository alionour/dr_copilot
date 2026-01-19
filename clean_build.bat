@echo off
echo ==========================================
echo      Deep Cleaning Build Environment
echo ==========================================
echo.

echo 1. Removing 'build' directory...
if exist build (
    rmdir /s /q build
    if exist build (
        echo [ERROR] Failed to delete build directory. Files might be locked.
        echo Please close VS Code or any running Flutter processes and try again.
        pause
        exit /b 1
    ) else (
        echo [OK] Build directory removed.
    )
) else (
    echo [OK] Build directory already missing.
)

echo.
echo 2. Running flutter clean...
call flutter clean

echo.
echo 3. Getting dependencies...
call flutter pub get

echo.
echo ==========================================
echo      Clean Complete
echo ==========================================
echo.
echo You can now run: flutter run -d windows
echo.
pause
