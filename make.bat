@echo off

echo "start build windows exe"

if not exist bin mkdir bin

set port=8081
set curpath=%CD%
set outpath=%CD%\bin
set luavm=luacore.exe
set cmdtitle=mycat_proxy
set main=%luavm% main.lua  %port% 
set pack_exe="F:\Program Files (x86)\Inno Setup 5\Compil32.exe"

cd util\luajit

luajit204 -e "print(jit.version)"

for /R %%s in ( ..\..\src\*.lua ) do (
   echo  Compile %%s
   luajit204 -b %%s %outpath%\%%~nxs
)

echo "Compile success,copy %luavm%"

if not exist %outpath%\web mkdir %outpath%\web

copy  %curpath%\make.iss     %outpath%
copy  %curpath%\%luavm%      %outpath%
copy  %curpath%\sqlite3.dll  %outpath%
xcopy /e /y %curpath%\web\*  %outpath%\web

set dircmd=if not exist data  mkdir data 
set runcmd=start "%cmdtitle%" %main% 
set httpcmd=start http:\\127.0.0.1:%port%
set exitcmd=exit

@rem >> is append ^ is escape char

echo ^@echo off >%outpath%\run.bat
echo ^cd ^%%~dp0 >> %outpath%\run.bat
echo %dircmd%  >> %outpath%\run.bat
echo %runcmd%  >> %outpath%\run.bat
echo %httpcmd% >> %outpath%\run.bat

echo "copy success ,next will package"

call %pack_exe% /cc %curpath%\make.iss

    
cd %outpath%
del /a /f /s /q %outpath%\web
del /a /f /s /q %outpath%\*.lua
del /a /f /s /q %outpath%\*.bat
del /a /f /s /q %outpath%\*.dll
del /a /f /s /q %outpath%\*.iss
del /a /f /s /q %outpath%\%luavm%
rd /s/q         %outpath%\web

set BIT_FLAG=64
if /i "%PROCESSOR_IDENTIFIER:~0,3%"=="X86" set BIT_FLAG=32 
echo "os is %BIT_FLAG% bit"

cd %curpath%
