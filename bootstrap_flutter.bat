@echo off
SETLOCAL EnableDelayedExpansion
SET SCRIPTPATH=%~dp0
SET FLUTTER_ROOT=%SCRIPTPATH%..
SET DART_SDK_PATH=%FLUTTER_ROOT%\bin\cache\dart-sdk
SET DART=%DART_SDK_PATH%\bin\dart.exe

ECHO Checking Dart SDK at %DART% ...

IF NOT EXIST "%DART%" (
  ECHO Dart SDK not found. Downloading...
  Powershell.exe -ExecutionPolicy Bypass -Command "$env:FLUTTER_ROOT='%FLUTTER_ROOT%'; & '%SCRIPTPATH%internal\update_dart_sdk.ps1'"
)

IF EXIST "%DART%" (
  ECHO Dart SDK found. Running Flutter...
  "%DART%" "%FLUTTER_ROOT%\bin\cache\flutter_tools.snapshot" %*
) ELSE (
  ECHO Failed to install Dart SDK. Check internet connection or permissions.
  EXIT /B 1
)
