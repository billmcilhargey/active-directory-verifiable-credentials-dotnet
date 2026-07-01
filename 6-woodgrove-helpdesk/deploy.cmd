@echo off
setlocal

echo [deploy.cmd] Starting publish for Woodgrove Helpdesk...

if "%DEPLOYMENT_TARGET%"=="" (
  echo [deploy.cmd] DEPLOYMENT_TARGET is not set.
  exit /b 1
)

dotnet publish "WoodgroveHelpdesk.csproj" -c Release -o "%DEPLOYMENT_TARGET%"
if errorlevel 1 (
  echo [deploy.cmd] dotnet publish failed.
  exit /b 1
)

echo [deploy.cmd] Publish completed successfully.
exit /b 0
