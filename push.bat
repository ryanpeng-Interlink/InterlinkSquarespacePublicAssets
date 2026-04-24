@echo off
REM ============================================================
REM  Push InterlinkSquarespacePublicAssets to GitHub
REM  Double-click this file, or run it from a terminal in this
REM  folder.  It stages every change, commits with a message
REM  you type, and pushes to origin/main.
REM ============================================================

setlocal enableextensions enabledelayedexpansion

REM Always operate from the folder this script lives in.
cd /d "%~dp0"

echo.
echo ============================================================
echo   Interlink Squarespace Public Assets - Push to GitHub
echo ============================================================
echo Working directory: %CD%
echo.

REM --- Sanity check: is git installed? ---------------------------
where git >nul 2>nul
if errorlevel 1 (
    echo [ERROR] git was not found on your PATH.
    echo         Install Git for Windows from https://git-scm.com/
    goto :end
)

REM --- Sanity check: are we inside a git repo? -------------------
git rev-parse --is-inside-work-tree >nul 2>nul
if errorlevel 1 (
    echo [ERROR] This folder is not a git repository.
    echo         Expected a .git directory in: %CD%
    goto :end
)

REM --- Show what's about to change -------------------------------
echo --- Current status ------------------------------------------
git status --short
echo -------------------------------------------------------------
echo.

REM --- Anything to do? -------------------------------------------
set CHANGE_COUNT=0
for /f %%A in ('git status --porcelain ^| find /c /v ""') do set CHANGE_COUNT=%%A

if "!CHANGE_COUNT!"=="0" (
    echo No local changes detected.  Checking whether the branch
    echo is ahead of origin anyway...
    echo.
    git fetch origin >nul 2>nul
    set AHEAD=0
    for /f %%A in ('git rev-list --count "@{u}..HEAD" 2^>nul') do set AHEAD=%%A
    if "!AHEAD!"=="0" (
        echo Nothing to push.  You're already in sync with origin.
        goto :end
    )
    echo Branch is !AHEAD! commit^(s^) ahead of origin.  Pushing...
    goto :push_only
)

REM --- Build a timestamped default message (locale-independent) --
for /f %%T in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HH:mm"') do set STAMP=%%T
set DEFAULT_MSG=Update assets !STAMP!

echo Enter a commit message, or press ENTER to use the default:
echo   "!DEFAULT_MSG!"
set "MSG="
set /p MSG=Message: 
if "!MSG!"=="" set "MSG=!DEFAULT_MSG!"

echo.
echo Commit message:  !MSG!
echo.

REM --- Stage, commit, push ---------------------------------------
echo --- Staging changes -----------------------------------------
git add -A
if errorlevel 1 goto :fail

echo --- Committing ----------------------------------------------
git commit -m "!MSG!"
if errorlevel 1 (
    echo [WARN] git commit returned a non-zero exit code.
    echo        Usually means nothing to commit.  Trying push anyway.
)

:push_only
echo --- Pushing to origin ---------------------------------------
git push origin HEAD
if errorlevel 1 goto :fail

echo.
echo ============================================================
echo   SUCCESS - changes pushed to GitHub.
echo ============================================================
goto :end

:fail
echo.
echo ============================================================
echo   FAILED - see messages above for the error.
echo ============================================================

:end
echo.
pause
endlocal
