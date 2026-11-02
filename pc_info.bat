@echo off
chcp 65001 >nul

set "REPORT=%~dp0pc_report.txt"
set "APPS_TMP=%TEMP%\apps_list.txt"

echo Сбор данных и аудит системы, подождите... > "%REPORT%"

for /f "tokens=1-3 delims=. " %%a in ("%date%") do set "curr_date=%%c-%%b-%%a"
set "curr_time=%time:~0,8%"

call :log "=================================================="
call :log "   Диагностика и audit компьютера"
call :log "   Дата: %curr_date%  Время: %curr_time%"
call :log "=================================================="
call :log ""

call :log "Операционная система"
call :log "--------------------------------------------------"
set "OS_NAME="
set "OS_VER="
for /f "usebackq delims=" %%b in (`powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).Caption" 2^nul`) do set "OS_NAME=%%b"
for /f "usebackq delims=" %%b in (`powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).Version" 2^nul`) do set "OS_VER=%%b"

if defined OS_NAME (call :log "Название: %OS_NAME%") else (call :log "Название: Не удалось получить данные")
if defined OS_VER (call :log "Версия: %OS_VER%") else (call :log "Версия: Не удалось получить данные")
call :log ""

call :log "Процессор"
call :log "--------------------------------------------------"
set "CPU_NAME="
for /f "usebackq delims=" %%b in (`powershell -NoProfile -Command "(Get-CimInstance Win32_Processor | Select-Object -First 1).Name" 2^nul`) do set "CPU_NAME=%%b"

if defined CPU_NAME (call :log "%CPU_NAME%") else (call :log "Данные о процессоре недоступны")
call :log ""

call :log "Оперативная память"
call :log "--------------------------------------------------"
set "MEM_TOTAL="
set "MEM_FREE="
for /f "usebackq delims=" %%b in (`powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).TotalVisibleMemorySize" 2^nul`) do set /a MEM_TOTAL=%%b/1048576
for /f "usebackq delims=" %%b in (`powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory" 2^nul`) do set /a MEM_FREE=%%b/1048576

if defined MEM_TOTAL (call :log "Всего памяти: %MEM_TOTAL% ГБ") else (call :log "Всего памяти: Не удалось рассчитать")
if defined MEM_FREE (call :log "Свободно памяти: %MEM_FREE% ГБ") else (call :log "Свободно памяти: Не удалось рассчитать")
call :log ""

call :log "Диск C"
call :log "--------------------------------------------------"
set "DISK_SIZE_GB="
set "DISK_FREE_GB="
for /f "usebackq delims=" %%b in (`powershell -NoProfile -Command "[math]::Floor((Get-CimInstance Win32_LogicalDisk | Where-Object DeviceID -eq 'C:').Size/1GB)" 2^nul`) do set "DISK_SIZE_GB=%%b"
for /f "usebackq delims=" %%b in (`powershell -NoProfile -Command "[math]::Floor((Get-CimInstance Win32_LogicalDisk | Where-Object DeviceID -eq 'C:').FreeSpace/1GB)" 2^nul`) do set "DISK_FREE_GB=%%b"

if defined DISK_SIZE_GB (call :log "Размер диска: %DISK_SIZE_GB% ГБ") else (call :log "Размер диска: Данные отсутствуют")
if defined DISK_FREE_GB (call :log "Свободно: %DISK_FREE_GB% ГБ") else (call :log "Свободно: Данные отсутствуют")
call :log ""

echo Идет опрос реестра установленных программ (это займет время)...

if exist "%APPS_TMP%" del "%APPS_TMP%"

for /f "tokens=2*" %%a in ('reg query "HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall" /s /v DisplayName 2^>nul ^| findstr /i "DisplayName"') do (
    echo %%b>>"%APPS_TMP%"
)
for /f "tokens=2*" %%a in ('reg query "HKLM\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" /s /v DisplayName 2^>nul ^| findstr /i "DisplayName"') do (
    echo %%b>>"%APPS_TMP%"
)

call :log "=================================================="
call :log "   АНАЛИЗ БАЗОВОГО ОФИСНОГО ПО"
call :log "=================================================="

set "FOUND_APP="
if exist "%APPS_TMP%" for /f "delims=" %%i in ('findstr /i "Office LibreOffice OpenOffice МойОфис" "%APPS_TMP%" 2^nul') do set "FOUND_APP=%%i"
if defined FOUND_APP (
    call :log "[ОК] Офисный пакет обнаружен: %FOUND_APP%"
) else (
    call :log "[⚠️ РЕКОМЕНДАЦИЯ] Не обнаружен офисный пакет! Для работы с документами рекомендуется установить LibreOffice или МойОфис."
)

set "FOUND_APP="
if exist "%APPS_TMP%" for /f "delims=" %%i in ('findstr /i "7-Zip WinRAR WinZip" "%APPS_TMP%" 2^nul') do set "FOUND_APP=%%i"
if defined FOUND_APP (
    call :log "[ОК] Архиватор обнаружен: %FOUND_APP%"
) else (
    call :log "[⚠️ РЕКОМЕНДАЦИЯ] Не обнаружен архиватор. Для работы с вложениями и zip/rar архивами в почте рекомендуется установить 7-Zip или WinRAR."
)

set "FOUND_APP="
if exist "%APPS_TMP%" for /f "delims=" %%i in ('findstr /i "Acrobat Foxit SumatraPDF" "%APPS_TMP%" 2^nul') do set "FOUND_APP=%%i"
if defined FOUND_APP (
    call :log "[ОК] Программа чтения PDF обнаружена: %FOUND_APP%"
) else (
    call :log "[⚠️ РЕКОМЕНДАЦИЯ] Не обнаружено ПО для PDF. Для работы с инструкциями и договорами рекомендуется установить Foxit Reader или SumatraPDF."
)

set "FOUND_APP="
if exist "%APPS_TMP%" for /f "delims=" %%i in ('findstr /i "Chrome Firefox Yandex" "%APPS_TMP%" 2^nul') do set "FOUND_APP=%%i"
if defined FOUND_APP (
    call :log "[ОК] Сторонний рабочий браузер обнаружен: %FOUND_APP%"
) else (
    call :log "[i] Сторонние браузеры не найдены. Используется встроенный системный компонент Microsoft Edge."
)

set "FOUND_APP="
if exist "%APPS_TMP%" for /f "delims=" %%i in ('findstr /i "Kaspersky ESET Dr.Web Defender" "%APPS_TMP%" 2^nul') do set "FOUND_APP=%%i"
if defined FOUND_APP (
    call :log "[ОК] Средства антивирусной защиты: %FOUND_APP%"
) else (
    call :log "[⚠️ РЕКОМЕНДАЦИЯ] Не найдена активная коммерческая антивирусная защита. Убедитесь, что системный Windows Defender включен."
)
call :log ""

call :log "=================================================="
call :log "   АНАЛИЗ ИЗЛИШНЕГО И НЕПРОФИЛЬНОГО ПО"
call :log "=================================================="
call :log "Внимание: данный раздел содержит рекомендации к проверке администратором,"
call :log "программы не относятся к базовым офисным задачам и подлежат верификации."
call :log "--------------------------------------------------"

call :log "Группа 1: Игровое ПО и платформы:"
set "GAME_FOUND=0"
if exist "%APPS_TMP%" (
    for /f "delims=" %%i in ('findstr /i "Steam Epic GOG Origin Ubisoft Battle.net Riot game gaming" "%APPS_TMP%" 2^nul') do (
        call :log "  -> Найдено: %%i"
        set "GAME_FOUND=1"
    )
)
if "%GAME_FOUND%"=="0" call :log "  Игровое ПО не обнаружено."

call :log "Группа 2: Торрент-клиенты и файлообменники (нагрузка на сеть):"
set "TORRENT_FOUND=0"
if exist "%APPS_TMP%" (
    for /f "delims=" %%i in ('findstr /i "torrent uTorrent BitTorrent qBittorrent Vuze" "%APPS_TMP%" 2^nul') do (
        call :log "  -> Найдено: %%i"
        set "TORRENT_FOUND=1"
    )
)
if "%TORRENT_FOUND%"=="0" call :log "  Торрент-клиенты не обнаружены."

call :log "Группа 3: Мессенджеры и личное общение (требует сверки со стандартом):"
set "MSG_FOUND=0"
if exist "%APPS_TMP%" (
    for /f "delims=" %%i in ('findstr /i "Discord Telegram WhatsApp Viber Skype" "%APPS_TMP%" 2^nul') do (
        call :log "  -> Найдено: %%i"
        set "MSG_FOUND=1"
    )
)
if "%MSG_FOUND%"=="0" call :log "  Мессенджеры не обнаружены."

call :log "Группа 4: Мультимедиа и инструменты кастомизации:"
set "ENT_FOUND=0"
if exist "%APPS_TMP%" (
    for /f "delims=" %%i in ('findstr /i "Wallpaper OBS Soundpad Player Winamp VLC" "%APPS_TMP%" 2^nul') do (
        call :log "  -> Найдено: %%i"
        set "ENT_FOUND=1"
    )
)
if "%ENT_FOUND%"=="0" call :log "  Излишнее мультимедиа ПО не обнаружено."
call :log ""

if exist "%APPS_TMP%" del "%APPS_TMP%"

echo ==================================================
echo Аудит успешно завершен!
echo Полный отчет сохранен по пути:
echo %REPORT%
echo ==================================================
echo.
pause
exit /b

:log
set "txt=%~1"
echo(%txt%
echo(%txt% >> "%REPORT%"
exit /b
