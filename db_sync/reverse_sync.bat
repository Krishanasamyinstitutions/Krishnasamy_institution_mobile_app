@echo off
echo ============================================================
echo   TBS School - REVERSE SYNC
echo   Supabase  -^>  Local PostgreSQL
echo ============================================================
echo.

cd /d "%~dp0"

echo Starting reverse sync...
echo.

node Reverse_sync.js %*

echo.
echo ============================================================
echo   Reverse Sync Process Completed
echo ============================================================
pause
