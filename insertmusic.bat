@echo off

copy emw.smc AddmusicK /y
cd AddmusicK
AddmusicK.exe emw.smc
move /y emw.smc ..
move /y emw.msc ..
if exist emw.smc~ del (emw.smc~)