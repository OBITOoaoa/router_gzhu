@echo off
mode con cols=72 lines=24
title K1 K2 刷机、刷入Breed 辅助工具 (v2.2)   by tianbaoha
CD /D "%~DP0" >nul 2>nul
if not exist "%~DP0base64.exe" goto error
if not exist "%~DP0curl.exe" goto error
if not exist "%~DP0tianbaoha.dat" goto error
if not exist "%~DP0dat.dat" goto error
echo.
echo   支持的版本：
echo.
echo   K1： V22.4.XX.XX
echo   K1S：V22.3.XX.XX
echo   K2： V22.2.XX.XX
echo        V22.3.XX.XX
echo        V22.4.XX.XX
echo        V22.5.XX.XX
echo        V22.6.XX.XX
echo   K2P：V22.8.5.189 V22.10.2.24
echo.
echo      (V21.4.6.12版本需要升级到以上版本)
echo      (V21.4.6.12以下版本需要先升级到V21.4.6.12版本)
echo.
for /f "tokens=3" %%o in ('route print^|findstr 0.0.0.0.*0.0.0.0') do SET "IP=%%o"
if "%IP%"=="" SET "IP=p.to"
SET /p IP=请输入 路由器IP(回车默认%IP%)：
echo IP：%IP%
echo.
del passwd.tmp >nul 2>nul
SET password=admin
SET /p password=登陆密码(回车默认admin)：
(SET/p="%PASSWORD%"|base64.exe)<nul>passwd.tmp 2>nul
SET /p "PASSWORD="<passwd.tmp
ping -n 2 %IP% | find "TTL=" >nul
if errorlevel 1 (
color fc
echo.
echo   连接超时 ...
@ping -n 2 127.1>nul
goto tb
) else (
curl -s "http://%IP%/cgi-bin" 2>nul|findstr "<title>K2P</title>" >nul && SET "ID=K2P" || SET "ID=K2"
)
:222
del tianbaoha >nul 2>nul
if "%ID%"=="K2P" (
curl -s -o tianbaoha -X POST -H "Content-Type: application/json" -d "{\"method\":\"set\",\"module\":{\"security\":{\"login\":{\"username\":\"admin\",\"password\":\"%PASSWORD%\"}}},\"_deviceType\":\"pc\"}" "http://%IP%/cgi-bin/" >nul 2>nul
) else (
curl -D tianbaoha "http://%IP%/cgi-bin/luci/admin/login?action_mode=apply&action_url=http://%IP%/cgi-bin/luci&username=admin&password=%PASSWORD%" >nul 2>nul
)
echo.
echo.
echo   登陆 ...
@ping -n 2 127.1>nul
if "%ID%"=="K2P" (
SET "str1=stok"
) else (
SET "str1=Location"
)
for /f "delims=" %%j in ('findstr "%str1%" tianbaoha') do SET "stok=%%j"
echo "%stok%" |find "stok" >nul && echo. || goto error1
SET "EXP=`sed%%20-i%%20's*encryconfig%%20decrypt%%20/tmp/restore_encode%%20/tmp/restore_decode*openssl%%20aes-128-cbc%%20-d%%20-k%%20PHICOMM%%20-base64%%20-in%%20/tmp/restore_encode%%20-out%%20/tmp/restore_decode%%3Bsed%%201%%2C10d%%20/tmp/restore_decode%%7Ctar%%20xz%%20tmp/tb.tb%%20tmp/tb.ts%%20tmp/tb.bin%%20-C%%20/%%3B/tmp/tb.tb*%%3Bs*%%22tar%%20-xzC/%%20-f%%20/tmp/restore_rm_header*%%22%%5B%%20-f%%20/tmp/ok_tb%%20%%5D%%7C%%7Ctar%%20-xzC/%%20-f%%20/tmp/restore_rm_header*'%%20/usr/lib/lua/luci/controller/admin/backuprestore.lua``rm%%20-rf%%20/permanent_config/etc%%20/etc/tb.tb%%20/tmp/luci-indexcache%%20/tmp/luci-modulecache`"
if "%ID%"=="K2P" (
@ping -n 2 127.1>nul
curl -s -X POST -H "Content-Type: application/json" -d "{\"method\":\"set\",\"module\":{\"safe_set\":{\"arp_bind_list\":{\"ip\":\"1.1.1.1%%60sed%%20-i%%20%%27s*%%22encryconfig%%20decrypt%%20/tmp/backupFile_tmp%%20/tmp/backupFile*%%22openssl%%20aes-128-cbc%%20-d%%20-k%%20PHICOMM%%20-base64%%20-in%%20/tmp/backupFile_tmp%%20-out%%20/tmp/backupFile%%3Bsed%%201%%2C10d%%20/tmp/backupFile%%7Ctar%%20xz%%20tmp/tb.tb%%20tmp/tb.ts%%20tmp/tb.bin%%20-C%%20/%%3B/tmp/tb.tb*%%3Bs*%%22tar%%20-xzC/%%20-f%%20/tmp/restore_rm_header*%%22%%5B%%20-f%%20/tmp/ok_tb%%20%%5D%%7C%%7Ctar%%20-xzC/%%20-f%%20/tmp/restore_rm_header*%%27%%20/usr/lib/lua/luci/controller/admin/backup_reset_plt.lua%%3Brm%%20-rf%%20/tmp/luci-dataindexcache%%20/tmp/luci-indexcache%%20/tmp/luci-modulecache%%60\",\"mac\":\"00%%3A11%%3A22%%3A33%%3A44%%3A55\",\"bind_flag\":\"0\"}}},\"_deviceType\":\"pc\"}" "http://%IP%/cgi-bin/stok=%stok:~40,32%/data" >nul 2>nul
) else (
@ping -n 2 127.1>nul
curl -b tianbaoha "http://%IP%/cgi-bin/luci/;stok=%stok:~-44,32%/admin/timereboot?timeRebootEnablestatus=off%EXP%&timeRebootrange=&cururl=" >nul 2>nul
@ping -n 2 127.1>nul
curl -b tianbaoha "http://%IP%/cgi-bin/luci/;stok=%stok:~-44,32%/admin/networkset?cbid.network.wan.dns1=1.1.1.1&cbid.network.wan.dns2=%EXP%&cbi.submit=1" >nul 2>nul
@ping -n 2 127.1>nul
curl -b tianbaoha "http://%IP%/cgi-bin/luci/;stok=%stok:~-44,32%/admin/more_sysset/autoupgrade/save?mode=1&autoUpTime=03%%3A03%EXP%" >nul 2>nul
@ping -n 2 127.1>nul
curl -b tianbaoha "http://%IP%/cgi-bin/luci/;stok=%stok:~-44,32%/admin/more_sysset/autoupgrade/save?mode=0&autoUpTime=03%%3A03" >nul 2>nul
@ping -n 2 127.1>nul
curl -b tianbaoha "http://%IP%/cgi-bin/luci/;stok=%stok:~-44,32%/admin/more_sysset/autoupgrade/save?mode=1&autoUpTime=03%%3A03%%3A03%EXP%" >nul 2>nul
@ping -n 2 127.1>nul
curl -b tianbaoha "http://%IP%/cgi-bin/luci/;stok=%stok:~-44,32%/admin/more_sysset/autoupgrade/save?mode=0&autoUpTime=03%%3A03%%3A03" >nul 2>nul
)
@ping -n 4 127.1>nul
cls
echo.
echo.
echo   稍等 ...
if "%ID%"=="K2P" (
curl -F "file=@dat.dat" "http://%IP%/cgi-bin/stok=%stok:~40,32%/system/backup_upload" >nul 2>nul
) else (
curl -b tianbaoha -H "Expect:" -F "restore=@tianbaoha.dat" "http://%IP%/cgi-bin/luci/;stok=%stok:~-44,32%/admin/more_sysset/backuprecovery" >nul 2>nul
)
@ping -n 10 127.1>nul
cls
echo.
echo.
echo   路由器重启中(等待1分钟) ...
@ping -n 60 127.1>nul
:reboot
ping -n 2 %IP% | find "TTL=" >nul
if errorlevel 1 (
@ping -n 10 127.1>nul
goto reboot
) else goto 333
:333
@ping -n 15 127.1>nul
cls
color a
echo.
echo.
echo   完成 ！如果"自动登录成功"或者"手动升级页面有变化"就说明成功了。
echo.
echo   Breed 版本：r1237 [2018-10-14] 
echo   Breed 发布帖：https://www.right.com.cn/forum/thread-161906-1-1.html
echo.
echo.
echo.
echo.
echo   如果觉得不错可以扫码打赏支持
echo.
echo   注意事项、更多信息 访问：https://tbvv.net
echo.
echo.
echo [InternetShortcut]>login.url 2>nul
if "%ID%"=="K2P" (
echo URL="http://%IP%/cgi-bin/">>login.url 2>nul
) else (
echo URL="http://%IP%/cgi-bin/luci/admin/login?action_mode=apply&action_url=http://%IP%/cgi-bin/luci&username=admin&password=dGJ2di5uZXQ=">>login.url 2>nul
)
start login.url >nul 2>nul
del login.url >nul 2>nul
goto tb
:error
color fc
echo.
echo.
echo   缺少文件，请把所有文件解压到任意目录后再运行。
goto tb
:error1
if "%RESET%"=="RESET" goto error2
cls
color fc
echo.
echo.
echo   密码错误，或者尚未设置过路由。
echo.
echo.
echo.
SET /p a=输入 Y 尝试配置路由...其他键退出：
if /i "%a%"=="Y" (goto Y) else goto tb
goto tb
:Y
cls
color 7
echo.
echo.
echo   尝试配置路由 ...
@ping -n 2 127.1>nul
del RESET >nul 2>nul
if "%ID%"=="K2P" (
curl -s -X POST -H "Content-Type: application/json" -d "{\"agreement\":1,\"_deviceType\":\"pc\"}" "http://%IP%/cgi-bin/welcome/config" >nul 2>nul
@ping -n 2 127.1>nul
curl -s -X POST -H "Content-Type: application/json" -d "{\"method\":\"set\",\"module\":{\"security\":{\"register\":{\"username\":\"admin\",\"password\":\"YWRtaW4%%3D\"}}},\"_deviceType\":\"pc\"}" "http://%IP%/cgi-bin/" >nul 2>nul
@ping -n 2 127.1>nul
curl -s -o RESET -X POST -H "Content-Type: application/json" -d "{\"method\":\"set\",\"module\":{\"security\":{\"login\":{\"username\":\"admin\",\"password\":\"YWRtaW4%%3D\"}}},\"_deviceType\":\"pc\"}" "http://%IP%/cgi-bin/" >nul 2>nul
) else (
curl -D RESET "http://%IP%/cgi-bin/luci/admin/quickguide/welcome?userprotocol=1&configclick=click" >nul 2>nul
@ping -n 2 127.1>nul
curl -b RESET "http://%IP%/cgi-bin/luci/admin/quickguide/internet_setting?connectionType=DHCP&autodetect=0&pppoeUser=+&pppoePass=&staticIp=&staticNetmask=&staticGateway=&staticPriDns=" >nul 2>nul
@ping -n 2 127.1>nul
curl -b RESET "http://%IP%/cgi-bin/luci/admin/quickguide/wireless_setting?savevalidate=1&username=admin&ssid=@PHICOMM_2G&key=&inic_ssid=@PHICOMM_5G&inic_key=&password=YWRtaW4=" >nul 2>nul
)
SET /p "stokk="<RESET
if "%ID%"=="K2P" (
@ping -n 2 127.1>nul
curl -s -X POST -H "Content-Type: application/json" -d "{\"method\":\"set\",\"module\":{\"network\":{\"wan\":{\"protocol\":\"dhcp\"},\"dhcp\":{}}},\"_deviceType\":\"pc\"}" "http://%IP%/cgi-bin/stok=%stokk:~40,32%/data/network" >nul 2>nul
@ping -n 2 127.1>nul
curl -s -X POST -H "Content-Type: application/json" -d "{\"method\":\"set\",\"module\":{\"welcome\":{\"config\":{\"guide\":\"0\"}},\"wireless\":{\"wifi_2g_config\":{\"ssid\":\"%%40PHICOMM_2G\",\"password\":\"\"},\"wifi_5g_config\":{\"ssid\":\"%%40PHICOMM_5G\",\"password\":\"\"}}},\"_deviceType\":\"pc\"}" "http://%IP%/cgi-bin/stok=%stokk:~40,32%/data/wireless" >nul 2>nul
)
@ping -n 40 127.1>nul
del RESET >nul 2>nul
echo.
echo.
echo   配置完成，准备开始 ...
SET "password=YWRtaW4="
SET "RESET=RESET"
@ping -n 10 127.1>nul
goto 222
:error2
color fc
echo.
echo.
echo   密码或IP错误，请重新输入。
goto tb
:tb
del tianbaoha passwd.tmp >nul 2>nul
echo.
echo.
echo   按任意键退出. . .
pause >nul
:: Copyright (C) 2017 tianbaoha