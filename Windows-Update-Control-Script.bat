@echo off
REM ==========================================================
REM  windows_update_enable_disable_script.bat
REM  Menu to Enable/Disable Windows Update services + tasks
REM  Controls:
REM      wuauserv    - Windows Update
REM      UsoSvc      - Update Orchestrator Service
REM      WaaSMedicSvc- Windows Update Medic Service (via registry + kill)
REM      UpdateOrchestrator Scheduled Tasks - disabled/enabled automatically
REM ==========================================================

:MENU
cls
echo ===========================================
echo   Windows Update Control Script
echo ===========================================
echo 1. Enable Windows Update (all services + tasks)
echo 2. Disable Windows Update (all services + tasks)
echo 3. Help
echo.
set /p choice=Choose an option [1-3]: 

if "%choice%"=="1" goto ENABLE
if "%choice%"=="2" goto DISABLE
if "%choice%"=="3" goto HELP

echo.
echo Invalid choice. Exiting...
pause >nul
goto END

:ENABLE
echo.
echo Enabling Windows Update services...
REM Enable wuauserv and UsoSvc
sc config wuauserv start= demand
sc start wuauserv
sc config UsoSvc start= demand
sc start UsoSvc

REM Enable WaaSMedicSvc via registry (Start=3 Manual)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" /v Start /t REG_DWORD /d 3 /f

REM Enable UpdateOrchestrator scheduled tasks
echo Enabling UpdateOrchestrator tasks...
schtasks /Change /TN "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan" /ENABLE >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\UpdateOrchestrator\USO_UxBroker" /ENABLE >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\UpdateOrchestrator\Reboot" /ENABLE >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\UpdateOrchestrator\UpdateModel" /ENABLE >nul 2>&1

echo Windows Update has been ENABLED (including Medic + scheduled tasks).
pause
goto MENU

:DISABLE
echo.
echo Disabling Windows Update services...
REM Stop and disable UsoSvc + wuauserv
sc stop UsoSvc
sc config UsoSvc start= disabled
sc stop wuauserv
sc config wuauserv start= disabled

REM Disable WaaSMedicSvc via registry (Start=4 Disabled)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" /v Start /t REG_DWORD /d 4 /f

REM Kill WaaSMedicSvc process immediately
taskkill /f /im WaaSMedicSvc.exe >nul 2>&1

REM Disable UpdateOrchestrator scheduled tasks
echo Disabling UpdateOrchestrator tasks...
schtasks /Change /TN "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan" /DISABLE >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\UpdateOrchestrator\USO_UxBroker" /DISABLE >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\UpdateOrchestrator\Reboot" /DISABLE >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\UpdateOrchestrator\UpdateModel" /DISABLE >nul 2>&1

echo Windows Update has been DISABLED (including Medic + scheduled tasks).
echo Note: WaaSMedicSvc may require reboot to stop completely.
pause
goto MENU

:HELP
cls
echo ===========================================================
echo  HELP
echo -----------------------------------------------------------
echo  This script lets you enable or disable ALL key
echo  Windows Update services + scheduled tasks with one click.
echo.
echo  SERVICES HANDLED:
echo    - wuauserv      (Windows Update)
echo    - UsoSvc        (Update Orchestrator Service)
echo    - WaaSMedicSvc  (Windows Update Medic Service)
echo.
echo  TASKS HANDLED:
echo    - Schedule Scan
echo    - USO_UxBroker
echo    - Reboot
echo    - UpdateModel
echo.
echo  HOW IT WORKS:
echo    - "Enable" sets services to Manual/started and enables tasks
echo    - "Disable" stops/disables services, disables tasks, kills Medic
echo.
echo  WHY USE IT:
echo    - Stop background CPU/disk/network use by updates
echo    - Prevent forced reboots
echo    - Avoid update-related crashes until YOU choose
echo.
echo  NOTE:
echo    - Must run as Administrator
echo    - Registry ownership of WaaSMedicSvc key must be fixed once
echo ===========================================================
pause
goto MENU

:END
exit