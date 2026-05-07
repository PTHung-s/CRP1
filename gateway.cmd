@echo off
rem OpenClaw Gateway (v2026.4.2)
set "HOME=%USERPROFILE%"
set "OPENCLAW_GATEWAY_PORT=18789"
set "OPENCLAW_SYSTEMD_UNIT=openclaw-gateway.service"
set "OPENCLAW_WINDOWS_TASK_NAME=OpenClaw Gateway"
set "OPENCLAW_SERVICE_MARKER=openclaw"
set "OPENCLAW_SERVICE_KIND=gateway"
set "OPENCLAW_SERVICE_VERSION=2026.4.2"
set "OPENCLAW_CONFIG_PATH=%~dp0openclaw.json"
set "OPENCLAW_STATE_DIR=%~dp0"
cd /d "%~dp0"
npx openclaw gateway --port 18789 --allow-unconfigured
