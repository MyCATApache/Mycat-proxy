@echo off

set port=8080
set arch=_x86_64
set curpath=%CD%
set main=main.lua
set outpath=%CD%\bin
set luavm=luacore_x84_64
set dest=centos_%arch%_mycat_proxy

cd util\luajit

luajit204 -e "print(jit.version)"

for /R %%s in ( ..\..\src\*.lua ) do (
   echo  Compile %%s
   luajit204 -b %%s %outpath%\%%~nxs
)
copy /y %curpath%\%luavm%  %outpath%\
xcopy /e /y %curpath%\web\*    %outpath%\web\

echo chmod 777 ./%luavm%;./%luavm% %main% %port%>%outpath%\run.sh

cd %outpath%
tar -cvf %dest%.tar.gz ./*
@rem copy %dest%.tar.gz  I:\vm_win7_share

del /a /f /s /q    %outpath%\web
del /a /f /s /q    %outpath%\*.sh
del /a /f /s /q    %outpath%\*.lua
del /a /f /s /q    %outpath%\%luavm%
rd /s/q  %outpath%\web

cd %curpath%
echo "finished"