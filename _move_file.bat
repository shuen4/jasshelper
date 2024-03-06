@echo off
@REM move compiled file to output folder
move /y cons\consolejasser.exe output
move /y grimoire\clijasshelper.exe output
move /y grimoire\grimoirejasshelper.exe output\jasshelper.exe
move /y grimoire\grimoirecaller.exe output
move /y wehelper\jasshelperdll.dll output\jasshelper.dll
move /y wehelper\jasshelperdll.rsm output\jasshelper.rsm
move /y wehelper\jasshelperinstaller.exe output
copy /y jasshelper.cgt output
@REM create zip file
cd output
del output.zip
del debug_symbol.zip
7z a -mx9 -x!jasshelper.rsm output.zip *
7z a -mx9 debug_symbol.zip jasshelper.rsm