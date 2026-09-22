@echo off
REM Launch Codenotch (build first if missing)
setlocal
cd /d "%~dp0"

if not exist "target\release\codenotch.exe" (
  echo Building release...
  call "%ProgramFiles(x86)%\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" >nul
  cargo build --release --locked
)

start "" "target\release\codenotch.exe"
