@echo off
echo ===========OooO=============================OooO===========
echo =======                                             =======
echo =====                                                 =====
echo ====          GOWIN Floating License Server            ====
echo ====        Copyright (C) 2014-2021 GOWINSEMI          ====
echo =====                                                 =====
echo =======                                             =======
echo ===========OooO=============================OooO===========
echo.

::-------------------------------------::
::set current path
set pa=%~dp0

::set license file path
set licenseFile="%pa%\gowin.lic"

::set TCP/IP service port number
set port="10559"

::-------------------------------------::

set licName=gowinLicensingService
echo Gowin Floating License Server name is %licName%.
echo.

%pa%\instsrv.exe %licName% %pa%\srvany.exe>nul 2>nul
echo Windows service has added successfully!
echo.

echo Add registry key Parameters to HKLM.
reg add HKLM\SYSTEM\CurrentControlSet\services\%licName%\Parameters
echo.

echo Add Gowin Floating License Server application to Services.
reg add HKLM\SYSTEM\CurrentControlSet\services\%licName%\Parameters /v Application /t REG_SZ /d "%pa%\license_server.exe -s %licenseFile% -p %port%"
echo.

pause