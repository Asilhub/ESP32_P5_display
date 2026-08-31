@echo off
REM ============================================================
REM  P5 Carwash Display - firmware flasher
REM  Ishlatish:  flash.bat            (COM3 default)
REM              flash.bat COM7       (boshqa port)
REM ============================================================
setlocal

set PORT=%1
if "%PORT%"=="" set PORT=COM3

echo.
echo  P5 Carwash Display v1.0.0
echo  Port: %PORT%
echo.

where esptool >nul 2>&1
if errorlevel 1 goto NOTOOL

esptool --chip esp32 -p %PORT% -b 921600 write_flash 0x0 "%~dp0p5_carwash_v1.0.0_FULL.bin"
if errorlevel 1 goto FAILED

echo.
echo  TAYYOR. Panelda MECANUZ yozuvi chiqishi kerak.
echo.
pause
exit /b 0

:NOTOOL
echo  XATO: esptool topilmadi.
echo.
echo  O'rnatish:  pip install esptool
echo  Yoki Espressif Flash Download Tool dan foydalaning:
echo    - Chip: ESP32
echo    - Fayl: p5_carwash_v1.0.0_FULL.bin
echo    - Manzil (address): 0x0
echo.
pause
exit /b 1

:FAILED
echo.
echo  XATO: flash qilinmadi.
echo  - Arduino IDE Serial Monitor ochiq bo'lsa, yoping.
echo  - Port raqamini tekshiring (Device Manager).
echo  - USB kabel ma'lumot uzatuvchi (data) kabel ekaniga ishonch hosil qiling.
echo.
pause
exit /b 1
